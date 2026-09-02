local jobs = require("ShillenSilent_core.core.jobs")
local safe_access = require("ShillenSilent_core.core.safe_access")
local notify_core = require("ShillenSilent_core.core.notify")
local native_api = require("ShillenSilent_core.core.native_api")
local i18n = require("ShillenSilent_core.i18n")
local offsets = require("ShillenSilent_core.data.offsets.current")
local data = require("ShillenSilent_core.features.heists.salvageyard.data")
local state = require("ShillenSilent_core.features.heists.salvageyard.state")
local coords_teleport = require("ShillenSilent_core.shared.coords_teleport")
local blip_teleport = require("ShillenSilent_core.shared.blip_teleport")
local native = require("natives")

local run_guarded_job = jobs.run_guarded_job
local run_coords_teleport = coords_teleport.run_coords_teleport
local teleport_to_blip_with_job = blip_teleport.teleport_to_blip_with_job

local actions = {}

local function config()
	return offsets.salvageyard or {}
end

local text = i18n.t

local push = notify_core.feature("feature.salvageyard.name")

local function set_heading(coords)
	local me = players and players.me and players.me() or nil
	local entity = me and ((me.vehicle and me.vehicle ~= 0) and me.vehicle or me.ped) or nil
	if entity then
		native.set_entity_heading(entity, coords.heading)
	end
end

local function read_packed_int(idx, slot)
	if type(idx) ~= "number" then
		return nil
	end

	local ok, value = pcall(native.get_packed_stat_int, idx, slot or 0)
	return ok and tonumber(value) or nil
end

local function write_packed_int(idx, value, slot)
	if type(idx) ~= "number" then
		return false
	end

	local ok, result = pcall(function()
		local stat_key = native.get_packed_int_stat_key(idx, false, true, slot or 0)
		return type(stat_key) == "number"
			and stat_key ~= 0
			and native.stat_set_int(stat_key, math.floor(tonumber(value) or 0), true)
	end)
	return ok and result == true
end

local function apply_slot_tunables(slot)
	local cfg = config()
	local slot_cfg = state.slot(slot)
	local tunables = cfg.slot_tunables[slot]
	if not slot_cfg or not tunables then
		return false
	end

	local robbery = math.floor(tonumber(slot_cfg.robbery) or 0)
	local vehicle = math.floor(tonumber(slot_cfg.vehicle) or 1)
	local mod = math.floor(tonumber(slot_cfg.modification) or 0)
	local keep = math.floor(tonumber(slot_cfg.keep) or 0)

	local ok1 = safe_access.set_tunable_int(tunables.robbery, robbery)
	local ok2 = safe_access.set_tunable_int(tunables.vehicle, vehicle + (mod * 100))
	local ok3 = safe_access.set_tunable_int(tunables.keep, keep)
	return ok1 and ok2 and ok3
end

function actions.reload_screen()
	local cfg = config()
	if not safe_access.is_script_running(cfg.scripts.planning) then
		push("salvageyard.notify.planning_inactive", 2000)
		return false
	end

	local wrote_any = false
	for i = 1, #cfg.scripts.planning_reload_offsets do
		local offset = cfg.scripts.planning_reload_offsets[i]
		local ok = safe_access.set_local_int(cfg.scripts.planning, offset, 2)
		if offset == 537 then
			state.flags.planning_reload_offset_537_supported = ok and true or false
		elseif offset == 535 then
			state.flags.planning_reload_offset_535_supported = ok and true or false
		end
		wrote_any = wrote_any or ok
	end

	push(wrote_any and "salvageyard.notify.reload_ok" or "salvageyard.notify.reload_failed", 2000)
	return wrote_any
end

function actions.apply_slot(slot)
	local ok = apply_slot_tunables(slot)
	local reload_ok = actions.reload_screen()
	push(
		(ok and reload_ok) and "salvageyard.notify.slot_ok" or "salvageyard.notify.slot_failed",
		2200,
		{ slot = tostring(slot) }
	)
	return ok and reload_ok
end

function actions.apply_all_changes()
	local ok = true
	for slot = 1, 3 do
		ok = apply_slot_tunables(slot) and ok
	end
	local reload_ok = actions.reload_screen()
	push((ok and reload_ok) and "salvageyard.notify.all_slots_ok" or "salvageyard.notify.all_slots_failed", 2200)
	return ok and reload_ok
end

function actions.make_slot_available(slot)
	local cfg = config()
	local tunables = cfg.slot_tunables[slot]
	if not tunables then
		return false
	end

	local ok = safe_access.set_mp_stat_int(tunables.status_stat, 0)
	local reload_ok = actions.reload_screen()
	push(
		(ok and reload_ok) and "salvageyard.notify.available_ok" or "salvageyard.notify.available_failed",
		2200,
		{ slot = tostring(slot) }
	)
	return ok and reload_ok
end

function actions.complete_preps()
	local cfg = config()
	local ok = true
	ok = safe_access.set_mp_stat_int(cfg.stats.gen_bs, -1) and ok
	ok = safe_access.set_mp_stat_int(cfg.stats.scope_bs, -1) and ok
	ok = safe_access.set_mp_stat_int(cfg.stats.fm_prog, -1) and ok
	ok = safe_access.set_mp_stat_int(cfg.stats.inst_prog, -1) and ok

	local reload_ok = actions.reload_screen()
	push((ok and reload_ok) and "salvageyard.notify.preps_ok" or "salvageyard.notify.preps_failed", 2200)
	return ok and reload_ok
end

function actions.reset_preps()
	local cfg = config()
	local ok = true
	ok = safe_access.set_mp_stat_int(cfg.stats.gen_bs, 0) and ok
	ok = safe_access.set_mp_stat_int(cfg.stats.scope_bs, 0) and ok
	ok = safe_access.set_mp_stat_int(cfg.stats.fm_prog, 0) and ok
	ok = safe_access.set_mp_stat_int(cfg.stats.inst_prog, 0) and ok

	local reload_ok = actions.reload_screen()
	push((ok and reload_ok) and "salvageyard.notify.reset_ok" or "salvageyard.notify.reset_failed", 2200)
	return ok and reload_ok
end

function actions.set_free_setup(enable, silent)
	local cfg = config()
	state.set_free_setup(enable)
	local setup_price = state.flags.free_setup and 0 or cfg.defaults.setup_price
	local ok = safe_access.set_tunable_int(cfg.tunables.setup_price, setup_price)
	if not silent then
		local key = state.flags.free_setup and "salvageyard.notify.free_setup_on" or "salvageyard.notify.free_setup_off"
		push(ok and key or "salvageyard.notify.free_setup_failed", 2000)
	end
	return ok
end

function actions.set_free_claim(enable, silent)
	local cfg = config()
	state.set_free_claim(enable)
	local standard = state.flags.free_claim and 0 or cfg.defaults.claim_price_standard
	local discounted = state.flags.free_claim and 0 or cfg.defaults.claim_price_discounted
	local ok1 = safe_access.set_tunable_int(cfg.tunables.claim_price_standard, standard)
	local ok2 = safe_access.set_tunable_int(cfg.tunables.claim_price_discounted, discounted)
	if not silent then
		local key = state.flags.free_claim and "salvageyard.notify.free_claim_on" or "salvageyard.notify.free_claim_off"
		push((ok1 and ok2) and key or "salvageyard.notify.free_claim_failed", 2000)
	end
	return ok1 and ok2
end

function actions.enforce_heist_toggles()
	local cfg = config()
	if state.flags.free_setup then
		safe_access.set_tunable_int(cfg.tunables.setup_price, 0)
	end
	if state.flags.free_claim then
		safe_access.set_tunable_int(cfg.tunables.claim_price_standard, 0)
		safe_access.set_tunable_int(cfg.tunables.claim_price_discounted, 0)
	end
end

function actions.teleport_entrance()
	local cfg = config()
	return teleport_to_blip_with_job(
		cfg.blips.entrance,
		text("feature.salvageyard.name"),
		text("salvageyard.notify.teleported_entrance"),
		text("salvageyard.notify.entrance_missing"),
		{ relay_if_interior = true }
	)
end

function actions.teleport_board()
	local cfg = config()
	if not safe_access.is_script_running(cfg.scripts.interior) then
		push("salvageyard.notify.must_be_inside", 2200)
		return false
	end

	local board = cfg.coords.board
	return run_coords_teleport(
		text("feature.salvageyard.name"),
		text("salvageyard.notify.teleported_board"),
		board.x,
		board.y,
		board.z,
		false,
		function()
			set_heading(board)
		end
	)
end

function actions.instant_sell()
	local sell = config().coords.sell
	return run_coords_teleport(
		text("feature.salvageyard.name"),
		text("salvageyard.notify.teleported_terminal"),
		sell.x,
		sell.y,
		sell.z,
		false,
		function()
			set_heading(sell)
		end
	)
end

function actions.instant_finish()
	return run_guarded_job("salvage_instant_finish", function()
		local cfg = config()
		local mission = nil
		for i = 1, #cfg.scripts.missions do
			local candidate = cfg.scripts.missions[i]
			if safe_access.is_script_running(candidate.script) then
				mission = candidate
				break
			end
		end

		if not mission then
			push("salvageyard.notify.no_mission", 2200)
			return
		end

		local selected = mission.offsets[1]
		for i = 1, #mission.offsets do
			local candidate_offsets = mission.offsets[i]
			if safe_access.get_local_int(mission.script, candidate_offsets.step1, nil) ~= nil then
				selected = candidate_offsets
				break
			end
		end

		local step1_value = safe_access.get_local_int(mission.script, selected.step1, 0)
		local ok1 = safe_access.set_local_int(mission.script, selected.step1, step1_value | (1 << 11))
		local ok2 = safe_access.set_local_int(mission.script, selected.step2, 2)

		local used_fallback = false
		local success = ok1 and ok2
		if not success then
			used_fallback = true
			local fallback1 = safe_access.set_local_int(mission.script, selected.step1, 4)
			local fallback2 = safe_access.set_local_int(mission.script, selected.step2, 5)
			success = fallback1 and fallback2
		end

		if success then
			push(used_fallback and "salvageyard.notify.finish_ok_fallback" or "salvageyard.notify.finish_ok", 2200)
		else
			push("salvageyard.notify.finish_failed", 2200)
		end
	end, function()
		push("salvageyard.notify.finish_running", 1500)
	end)
end

function actions.force_through_error()
	return run_guarded_job("salvage_force_through_error", function()
		local cfg = config()
		if not safe_access.is_script_running(cfg.scripts.planning) then
			push("salvageyard.notify.planning_inactive", 2200)
			return
		end

		local wrote_any = false
		for i = 1, #cfg.scripts.planning_force_offsets do
			local offset = cfg.scripts.planning_force_offsets[i]
			local ok = safe_access.set_local_int(cfg.scripts.planning, offset, 1)
			if offset == 418 then
				state.flags.planning_force_offset_418_supported = ok and true or false
			elseif offset == 416 then
				state.flags.planning_force_offset_416_supported = ok and true or false
			end
			wrote_any = wrote_any or ok
		end

		push(wrote_any and "salvageyard.notify.force_ok" or "salvageyard.notify.force_failed", 2200)
	end, function()
		push("salvageyard.notify.force_running", 1500)
	end)
end

function actions.skip_weekly_cooldown()
	local cfg = config()
	local week_sync = safe_access.get_mp_stat_int(cfg.stats.week_sync, 0) or 0
	local ok = safe_access.set_tunable_int(cfg.tunables.weekly_cooldown, week_sync + 1)
	local reload_ok = actions.reload_screen()
	push((ok and reload_ok) and "salvageyard.notify.weekly_ok" or "salvageyard.notify.weekly_failed", 2200)
	return ok and reload_ok
end

function actions.refresh_collect_safe_state()
	local cfg = config()
	state.flags.collect_safe_ee_only = safe_access.global_bool_supported(cfg.globals.safe_collect_bool)
	return state.flags.collect_safe_ee_only
end

function actions.collect_safe()
	local cfg = config()
	actions.refresh_collect_safe_state()
	if not state.flags.collect_safe_ee_only then
		push("salvageyard.notify.collect_safe_ee_only", 2200)
		return false
	end

	local value = safe_access.get_mp_stat_int(cfg.stats.safe_cash_value, 0) or 0
	if value <= 0 then
		push("salvageyard.notify.safe_empty", 2000)
		return false
	end

	local ok = safe_access.set_global_bool(cfg.globals.safe_collect_bool, true)
	push(ok and "salvageyard.notify.safe_collect_ok" or "salvageyard.notify.safe_collect_failed", 2000)
	return ok
end

function actions.set_popularity(value, silent)
	local cfg = config()
	local target = data.clamp_int(value, data.popularity.min, data.popularity.max, data.popularity.default)
	local ok0 = write_packed_int(cfg.packed_stats.popularity, target, 0)
	local ok1 = write_packed_int(cfg.packed_stats.popularity, target, 1)
	state.runtime.popularity_editor_value = target
	local ok = ok0 or ok1
	if not silent then
		push(ok and "salvageyard.notify.popularity_ok" or "salvageyard.notify.popularity_failed", 2200, {
			value = tostring(target),
		})
	end
	return ok
end

function actions.get_popularity_editor_value()
	return state.runtime.popularity_editor_value
end

function actions.set_popularity_editor_value(value)
	state.runtime.popularity_editor_value =
		data.clamp_int(value, data.popularity.min, data.popularity.max, data.popularity.default)
end

function actions.apply_popularity_editor_value()
	return actions.set_popularity(state.runtime.popularity_editor_value, false)
end

function actions.set_popularity_lock_active(enabled)
	state.set_popularity_lock(enabled)
	if state.flags.popularity_lock then
		actions.set_popularity(state.runtime.popularity_editor_value, true)
	end
	push(
		state.flags.popularity_lock and "salvageyard.notify.popularity_lock_on"
			or "salvageyard.notify.popularity_lock_off",
		2200
	)
end

function actions.get_popularity_lock_active()
	return state.flags.popularity_lock
end

function actions.popularity_lock_tick()
	if not state.flags.popularity_lock then
		return
	end

	local cfg = config()
	local current = read_packed_int(cfg.packed_stats.popularity, 0)
	local target = data.clamp_int(
		state.runtime.popularity_editor_value,
		data.popularity.min,
		data.popularity.max,
		data.popularity.default
	)
	local min_allowed = math.max(data.popularity.min, target - 10)
	if current and current < min_allowed then
		actions.set_popularity(target, true)
	end
end

function actions.tow_truck_instant_finish()
	return run_guarded_job("salvage_tow_truck_instant_finish", function()
		local tow_truck = config().scripts.tow_truck
		if not safe_access.is_script_running(tow_truck.script) then
			push("salvageyard.notify.tow_inactive", 2200)
			return
		end

		local ok = false
		for i = 1, #tow_truck.veh_bases do
			ok = safe_access.set_local_int(tow_truck.script, tow_truck.veh_bases[i] + 1, 1) or ok
		end
		for i = 1, #tow_truck.mission_bases do
			ok = safe_access.set_local_int(tow_truck.script, tow_truck.mission_bases[i] + 95, 6) or ok
		end

		push(ok and "salvageyard.notify.tow_ok" or "salvageyard.notify.tow_failed", 2200)
	end, function()
		push("salvageyard.notify.tow_running", 1500)
	end)
end

function actions.apply_sell_values()
	local cfg = config()
	local multiplier = data.clamp_number(
		state.config.salvage_multiplier,
		data.multiplier.min,
		data.multiplier.max,
		data.multiplier.default
	)
	state.set_multiplier(multiplier)

	local ok = true
	ok = safe_access.set_tunable_float(cfg.tunables.salvage_multiplier, multiplier) and ok
	for slot = 1, 3 do
		local tunables = cfg.slot_tunables[slot]
		state.set_sell_value(slot, state.sell_value(slot))
		ok = safe_access.set_tunable_int(tunables.value, state.sell_value(slot)) and ok
	end

	local reload_ok = actions.reload_screen()
	push((ok and reload_ok) and "salvageyard.notify.sell_values_ok" or "salvageyard.notify.sell_values_failed", 2200)
	return ok and reload_ok
end

function actions.skip_cutscene()
	return native_api.heist_skip_cutscene(text("feature.salvageyard.name"))
end

return actions
