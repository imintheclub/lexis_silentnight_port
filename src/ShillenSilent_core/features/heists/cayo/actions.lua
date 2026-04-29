local jobs = require("ShillenSilent_core.core.jobs")
local safe_access = require("ShillenSilent_core.core.safe_access")
local heist_cuts = require("ShillenSilent_core.core.heist_cuts")
local notify_core = require("ShillenSilent_core.core.notify")
local native_api = require("ShillenSilent_core.core.native_api")
local i18n = require("ShillenSilent_core.i18n")
local offsets = require("ShillenSilent_core.data.offsets.resolver")
local data = require("ShillenSilent_core.features.heists.cayo.data")
local state = require("ShillenSilent_core.features.heists.cayo.state")
local coords_teleport = require("ShillenSilent_core.shared.coords_teleport")

local run_guarded_job = jobs.run_guarded_job
local run_coords_teleport = coords_teleport.run_coords_teleport
local try_begin_teleport_cooldown = coords_teleport.try_begin_teleport_cooldown

local actions = {}

local function cfg()
	return offsets.feature("cayo")
end

local t = i18n.t

local push = notify_core.feature("feature.cayo.name")

local tool_push = notify_core.feature("cayo.group.tools")

local tp_push = notify_core.feature("cayo.group.teleport")

local function set_planning_reload()
	local c = cfg()
	return safe_access.set_local_int(c.scripts.planning, c.locals.planning_reload, 2)
end

local function should_notify(silent)
	return not silent
end

local function write_poi_unlocks()
	local c = cfg()
	return safe_access.set_mp_stat_int_map({
		[c.stats.bs_gen] = -1,
		[c.stats.bs_entr] = 63,
		[c.stats.bs_abil] = 63,
		[c.stats.approach] = -1,
		[c.stats.playthrough_status] = 10,
	})
end

local function write_loot_stats()
	local c = cfg()
	local config = state.config
	local has_secondary_target = (config.sec_comp ~= "NONE") or (config.sec_isl ~= "NONE")
	local value_map = {
		CASH = config.val_cash,
		WEED = config.val_weed,
		COKE = config.val_coke,
		GOLD = config.val_gold,
	}
	local ok = true
	local loots = { "CASH", "WEED", "COKE", "GOLD" }
	for i = 1, #loots do
		local loot = loots[i]
		local compound_value = (config.sec_comp == loot) and config.amt_comp or 0
		local island_value = (config.sec_isl == loot) and config.amt_isl or 0
		local value_stat = has_secondary_target and value_map[loot] or 0

		ok = safe_access.set_mp_stat_int("H4LOOT_" .. loot .. "_C", compound_value) and ok
		ok = safe_access.set_mp_stat_int("H4LOOT_" .. loot .. "_C_SCOPED", compound_value) and ok
		ok = safe_access.set_mp_stat_int("H4LOOT_" .. loot .. "_I", island_value) and ok
		ok = safe_access.set_mp_stat_int("H4LOOT_" .. loot .. "_I_SCOPED", island_value) and ok
		ok = safe_access.set_mp_stat_int("H4LOOT_" .. loot .. "_V", value_stat) and ok
	end

	ok = safe_access.set_mp_stat_int(c.stats.loot_paint, config.paint) and ok
	ok = safe_access.set_mp_stat_int(c.stats.loot_paint_scoped, config.paint) and ok
	ok = safe_access.set_mp_stat_int(c.stats.loot_paint_value, (config.paint ~= 0) and config.val_art or 0) and ok
	return ok
end

function actions.set_womans_bag(enable, silent)
	local c = cfg()
	local enabled = enable and true or false
	local changed = state.flags.womans_bag_enabled ~= enabled
	local backup = state.runtime.tunable_backup
	if enabled and backup.bag_max_capacity == nil then
		backup.bag_max_capacity =
			safe_access.get_tunable_int(c.tunables.bag_max_capacity, data.tunable_defaults.bag_max_capacity)
	end

	local target = enabled and 99999 or (backup.bag_max_capacity or data.tunable_defaults.bag_max_capacity)
	local ok = safe_access.set_tunable_int(c.tunables.bag_max_capacity, target)
	state.flags.womans_bag_enabled = enabled

	if changed and should_notify(silent) then
		push(enabled and "cayo.notify.womans_bag_enabled" or "cayo.notify.womans_bag_disabled", 2000)
	end
	return ok
end

function actions.set_remove_crew_cuts(enable, silent)
	local c = cfg()
	local enabled = enable and true or false
	if state.flags.max_payout_enabled and enabled then
		enabled = false
	end

	local changed = state.flags.remove_crew_cuts_enabled ~= enabled
	local backup = state.runtime.tunable_backup
	local ok = true

	if enabled then
		if backup.pavel_cut == nil then
			backup.pavel_cut = safe_access.get_tunable_float(c.tunables.pavel_cut, data.tunable_defaults.pavel_cut)
		end
		if backup.fencing_fee == nil then
			backup.fencing_fee =
				safe_access.get_tunable_float(c.tunables.fencing_fee, data.tunable_defaults.fencing_fee)
		end
		ok = safe_access.set_tunable_float(c.tunables.pavel_cut, 0.0) and ok
		ok = safe_access.set_tunable_float(c.tunables.fencing_fee, 0.0) and ok
	else
		ok = safe_access.set_tunable_float(c.tunables.pavel_cut, backup.pavel_cut or data.tunable_defaults.pavel_cut)
			and ok
		ok = safe_access.set_tunable_float(
			c.tunables.fencing_fee,
			backup.fencing_fee or data.tunable_defaults.fencing_fee
		) and ok
	end

	state.flags.remove_crew_cuts_enabled = enabled
	if changed and should_notify(silent) then
		push(enabled and "cayo.notify.crew_cuts_removed" or "cayo.notify.crew_cuts_restored", 2000)
	end
	return ok
end

function actions.enforce_heist_toggles()
	local c = cfg()
	if state.flags.womans_bag_enabled then
		safe_access.set_tunable_int(c.tunables.bag_max_capacity, 99999)
	end
	if state.flags.max_payout_enabled and state.flags.remove_crew_cuts_enabled then
		actions.set_remove_crew_cuts(false, true)
	end
	if state.flags.remove_crew_cuts_enabled then
		safe_access.set_tunable_float(c.tunables.pavel_cut, 0.0)
		safe_access.set_tunable_float(c.tunables.fencing_fee, 0.0)
	end
	return true
end

function actions.apply_preps()
	local c = cfg()
	local config = state.config
	local ok = true
	if config.unlock_all_poi then
		ok = write_poi_unlocks() and ok
	end

	ok = safe_access.set_mp_stat_int_map({
		[c.stats.progress] = config.diff,
		[c.stats.missions] = config.app,
		[c.stats.weapons] = config.wep,
		[c.stats.target] = config.tgt,
		[c.stats.uniform] = -1,
		[c.stats.grappel] = -1,
		[c.stats.trojan] = 5,
		[c.stats.weapon_disruption] = 3,
		[c.stats.armor_disruption] = 3,
		[c.stats.heli_disruption] = 3,
	}) and ok
	ok = write_loot_stats() and ok
	ok = set_planning_reload() and ok

	push(ok and "cayo.notify.preps_ok" or "cayo.notify.preps_failed", 2000)
	return ok
end

function actions.get_max_payout_cut()
	local c = cfg()
	local config = state.config
	local target = safe_access.get_active_mp_stat_int(c.stats.target, config.tgt)
	local progress = safe_access.get_active_mp_stat_int(c.stats.progress, config.diff)
	local difficulty = ((progress & 4096) ~= 0) and 2 or 1
	local payout_by_target = data.primary_target_payouts[target]
	if not payout_by_target then
		return 100, target, difficulty
	end

	local payout = payout_by_target[difficulty] or payout_by_target[1]
	local initial_cut = math.floor(data.safe_payout_target / (payout / 100))
	local cut = initial_cut
	local final_payout = math.floor(payout * (cut / 100))
	local difference = 1000

	while true do
		local pavel_fee = math.floor(final_payout * 0.02)
		local fencing_fee = math.floor(final_payout * 0.10)
		local fee_payout = final_payout - (pavel_fee + fencing_fee)

		if fee_payout >= (data.safe_payout_target - difference) and fee_payout <= data.safe_payout_target then
			return data.clamp_cut(cut), target, difficulty
		end

		cut = cut + 1
		final_payout = math.floor(payout * (cut / 100))
		if cut > 500 then
			cut = initial_cut
			final_payout = math.floor(payout * (cut / 100))
			difference = difference + 1000
		end
	end
end

function actions.refresh_max_payout(force_update)
	if not state.flags.max_payout_enabled then
		state.reset_max_payout_cache()
		return false
	end

	actions.set_remove_crew_cuts(false, true)

	local cut, target, difficulty = actions.get_max_payout_cut()
	if not cut then
		return false
	end

	local cache = state.runtime.max_payout_cache
	local changed = force_update or cache.target ~= target or cache.difficulty ~= difficulty or cache.cut ~= cut
	if changed then
		state.set_uniform_cuts(cut)
		cache.target = target
		cache.difficulty = difficulty
		cache.cut = cut
	end
	return changed
end

function actions.set_max_payout(enable, silent)
	local enabled = enable and true or false
	local changed = state.flags.max_payout_enabled ~= enabled
	state.flags.max_payout_enabled = enabled
	if enabled then
		actions.set_remove_crew_cuts(false, true)
		actions.refresh_max_payout(true)
	else
		state.reset_max_payout_cache()
	end
	if changed and should_notify(silent) then
		push(enabled and "cayo.notify.max_payout_enabled" or "cayo.notify.max_payout_disabled", 2000)
	end
	return enabled
end

function actions.apply_cuts()
	local c = cfg()
	local ok = heist_cuts.write_player_globals({
		player_keys = data.player_keys,
		offsets = c.globals.cuts,
		cuts = state.cuts,
		enabled = state.cut_enabled,
		clamp = data.clamp_cut,
	})
	push(ok and "cayo.notify.cuts_ok" or "cayo.notify.cuts_failed", 2000)
	return ok
end

function actions.force_ready()
	return run_guarded_job("cayo_force_ready", function()
		local c = cfg()
		safe_access.force_host(c.scripts.controller)
		util.yield(1000)
		local ok = true
		ok = safe_access.set_global_int(c.globals.ready.player2, 1) and ok
		ok = safe_access.set_global_int(c.globals.ready.player3, 1) and ok
		ok = safe_access.set_global_int(c.globals.ready.player4, 1) and ok
		push(ok and "cayo.notify.ready_ok" or "cayo.notify.ready_failed", 2000)
	end, function()
		push("cayo.notify.ready_running", 1500)
	end)
end

function actions.unlock_all_poi()
	local ok = write_poi_unlocks()
	if safe_access.is_script_running(cfg().scripts.planning) then
		ok = set_planning_reload() and ok
	end
	tool_push(ok and "cayo.notify.poi_ok" or "cayo.notify.poi_failed", 2000)
	return ok
end

function actions.reset_preps()
	local c = cfg()
	local ok = safe_access.set_mp_stat_int_map({
		[c.stats.progress] = 0,
		[c.stats.missions] = 0,
		[c.stats.approach] = 0,
		[c.stats.target] = -1,
		[c.stats.bs_gen] = 0,
		[c.stats.bs_entr] = 0,
		[c.stats.bs_abil] = 0,
		[c.stats.playthrough_status] = 0,
	})
	ok = set_planning_reload() and ok
	tool_push(ok and "cayo.notify.reset_ok" or "cayo.notify.reset_failed", 2000)
	return ok
end

function actions.instant_voltlab_hack()
	local c = cfg()
	if not safe_access.is_script_running(c.scripts.content) then
		tool_push("cayo.notify.mission_not_running", 2000)
		return false
	end
	local ok = safe_access.set_local_int(c.scripts.content, c.locals.voltlab_complete, 5)
	tool_push(ok and "cayo.notify.voltlab_ok" or "cayo.notify.voltlab_failed", 2000)
	return ok
end

function actions.instant_password_hack()
	local c = cfg()
	local ok = safe_access.set_local_int(c.scripts.controller, c.locals.password_complete, 5)
	tool_push(ok and "cayo.notify.password_ok" or "cayo.notify.password_failed", 2000)
	return ok
end

function actions.bypass_plasma_cutter()
	local c = cfg()
	local ok = safe_access.set_local_float(c.scripts.controller, c.locals.plasma_cutter, 100.0)
	tool_push(ok and "cayo.notify.plasma_ok" or "cayo.notify.plasma_failed", 2000)
	return ok
end

function actions.bypass_drainage_pipe()
	local c = cfg()
	local ok = safe_access.set_local_int(c.scripts.controller, c.locals.drainage_pipe, 6)
	tool_push(ok and "cayo.notify.drainage_ok" or "cayo.notify.drainage_failed", 2000)
	return ok
end

function actions.reload_planning_screen()
	local ok = set_planning_reload()
	tool_push(ok and "cayo.notify.planning_ok" or "cayo.notify.planning_failed", 2000)
	return ok
end

local function remove_cooldown(posix)
	local c = cfg()
	local ok = true
	ok = safe_access.set_mp_stat_int(c.stats.target_posix, posix) and ok
	ok = safe_access.set_mp_stat_int(c.stats.cooldown, 0) and ok
	ok = safe_access.set_mp_stat_int(c.stats.cooldown_hard, 0) and ok
	return ok
end

function actions.remove_cooldown()
	local ok = remove_cooldown(data.cooldown_posix.solo)
	tool_push(ok and "cayo.notify.cooldown_solo_ok" or "cayo.notify.cooldown_failed", 2000)
	return ok
end

function actions.remove_cooldown_team()
	local ok = remove_cooldown(data.cooldown_posix.team)
	tool_push(ok and "cayo.notify.cooldown_team_ok" or "cayo.notify.cooldown_failed", 2000)
	return ok
end

function actions.instant_finish()
	return run_guarded_job("cayo_instant_finish", function()
		local c = cfg()
		if not safe_access.force_host(c.scripts.controller) then
			tool_push("cayo.notify.finish_host_failed", 2000)
			return
		end
		util.yield(1000)
		local ok = true
		ok = safe_access.set_local_int(c.scripts.controller, c.locals.finish_status, 9) and ok
		ok = safe_access.set_local_int(c.scripts.controller, c.locals.finish_cash_take, 50) and ok
		tool_push(ok and "cayo.notify.finish_ok" or "cayo.notify.finish_failed", 2000)
	end, function()
		tool_push("cayo.notify.finish_running", 1500)
	end)
end

local function teleport_to_coord(coord_key, message_key)
	local c = cfg()
	local coords = c.coords[coord_key]
	return run_coords_teleport(t("cayo.group.teleport"), t(message_key), coords.x, coords.y, coords.z)
end

function actions.teleport_residence()
	return teleport_to_coord("residence", "cayo.notify.tp_residence")
end

function actions.teleport_main_target()
	return teleport_to_coord("main_target", "cayo.notify.tp_main_target")
end

function actions.teleport_gate()
	return teleport_to_coord("gate", "cayo.notify.tp_gate")
end

function actions.teleport_center()
	return teleport_to_coord("center", "cayo.notify.tp_center")
end

function actions.teleport_loot1()
	return teleport_to_coord("loot1", "cayo.notify.tp_loot1")
end

function actions.teleport_loot2()
	return teleport_to_coord("loot2", "cayo.notify.tp_loot2")
end

function actions.teleport_loot3()
	return teleport_to_coord("loot3", "cayo.notify.tp_loot3")
end

function actions.teleport_gate_outside()
	return teleport_to_coord("gate_outside", "cayo.notify.tp_gate")
end

function actions.teleport_airport()
	return teleport_to_coord("airport", "cayo.notify.tp_airport")
end

function actions.teleport_escape()
	return teleport_to_coord("escape", "cayo.notify.tp_escape")
end

function actions.teleport_kosatka()
	if state.runtime.teleport_in_progress then
		tp_push("cayo.notify.tp_running", 1200)
		return false
	end
	if not try_begin_teleport_cooldown() then
		tp_push("cayo.notify.tp_cooldown", 1000)
		return false
	end

	local c = cfg()
	local function kosatka_blip_exists()
		local result = invoker.call(c.natives.get_first_blip_info_id, c.blips.kosatka)
		return result and result.int and result.int ~= 0
	end

	local function request_kosatka_spawn()
		for i = 1, #c.globals.kosatka_request do
			safe_access.set_global_int(c.globals.kosatka_request[i], 1)
		end
	end

	state.runtime.teleport_in_progress = true
	local me = players and players.me and players.me() or nil
	if not me then
		state.runtime.teleport_in_progress = false
		tp_push("cayo.notify.player_missing", 2000)
		return false
	end

	local entity = me.ped
	local ok, err = pcall(function()
		invoker.call(c.natives.freeze_entity_position, entity, true)

		if me.in_interior then
			local maze = c.coords.mazebank
			invoker.call(c.natives.set_entity_coords_no_offset, entity, maze.x, maze.y, maze.z, false, false, false)
			invoker.call(c.natives.set_entity_heading, entity, maze.heading)
			util.yield(800)
		end

		if not kosatka_blip_exists() then
			tp_push("cayo.notify.kosatka_request", 2000)
			while not kosatka_blip_exists() do
				request_kosatka_spawn()
				util.yield()
			end
			tp_push("cayo.notify.kosatka_spawned", 2000)
		end

		local kosatka = c.coords.kosatka_interior
		invoker.call(
			c.natives.set_entity_coords_no_offset,
			entity,
			kosatka.x,
			kosatka.y,
			kosatka.z,
			false,
			false,
			false
		)
		invoker.call(c.natives.set_entity_heading, entity, kosatka.heading)

		local blip_check = 0
		local attempts = 0
		while blip_check == 0 and attempts < 120 do
			local check_result = invoker.call(c.natives.get_closest_blip_info_id, c.blips.heist)
			if check_result and check_result.int and check_result.int ~= 0 then
				blip_check = check_result.int
			else
				util.yield()
				attempts = attempts + 1
			end
		end

		util.yield(500)
		invoker.call(c.natives.freeze_entity_position, entity, false)
	end)

	state.runtime.teleport_in_progress = false
	if not ok then
		pcall(function()
			invoker.call(c.natives.freeze_entity_position, entity, false)
		end)
		tp_push("cayo.notify.kosatka_failed", 3000, { error = tostring(err) })
		return false
	end

	tp_push("cayo.notify.tp_kosatka", 2000)
	return true
end

function actions.skip_cutscene()
	return native_api.heist_skip_cutscene(t("feature.cayo.name"))
end

actions.cayo_set_womans_bag = actions.set_womans_bag
actions.cayo_set_remove_crew_cuts = actions.set_remove_crew_cuts
actions.cayo_set_max_payout = actions.set_max_payout
actions.cayo_refresh_max_payout = actions.refresh_max_payout
actions.cayo_enforce_heist_toggles = actions.enforce_heist_toggles
actions.cayo_apply_preps = actions.apply_preps
actions.cayo_apply_cuts = actions.apply_cuts
actions.cayo_force_ready = actions.force_ready
actions.cayo_unlock_all_poi = actions.unlock_all_poi
actions.cayo_reset_preps = actions.reset_preps
actions.cayo_instant_voltlab_hack = actions.instant_voltlab_hack
actions.cayo_instant_password_hack = actions.instant_password_hack
actions.cayo_bypass_plasma_cutter = actions.bypass_plasma_cutter
actions.cayo_bypass_drainage_pipe = actions.bypass_drainage_pipe
actions.cayo_reload_planning_screen = actions.reload_planning_screen
actions.cayo_remove_cooldown = actions.remove_cooldown
actions.cayo_remove_cooldown_team = actions.remove_cooldown_team
actions.cayo_instant_finish = actions.instant_finish
actions.cayo_teleport_residence = actions.teleport_residence
actions.cayo_teleport_main_target = actions.teleport_main_target
actions.cayo_teleport_gate = actions.teleport_gate
actions.cayo_teleport_center = actions.teleport_center
actions.cayo_teleport_loot1 = actions.teleport_loot1
actions.cayo_teleport_loot2 = actions.teleport_loot2
actions.cayo_teleport_loot3 = actions.teleport_loot3
actions.cayo_teleport_gate_outside = actions.teleport_gate_outside
actions.cayo_teleport_airport = actions.teleport_airport
actions.cayo_teleport_escape = actions.teleport_escape
actions.cayo_teleport_kosatka = actions.teleport_kosatka
actions.hp_get_cayo_max_payout_cut = actions.get_max_payout_cut

return actions
