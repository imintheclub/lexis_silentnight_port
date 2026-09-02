local jobs = require("ShillenSilent_core.core.jobs")
local safe_access = require("ShillenSilent_core.core.safe_access")
local notify_core = require("ShillenSilent_core.core.notify")
local native_api = require("ShillenSilent_core.core.native_api")
local i18n = require("ShillenSilent_core.i18n")
local offsets = require("ShillenSilent_core.data.offsets.current")
local data = require("ShillenSilent_core.features.heists.agency.data")
local state = require("ShillenSilent_core.features.heists.agency.state")
local coords_teleport = require("ShillenSilent_core.shared.coords_teleport")
local blip_teleport = require("ShillenSilent_core.shared.blip_teleport")
local native = require("natives")

local run_guarded_job = jobs.run_guarded_job
local run_coords_teleport = coords_teleport.run_coords_teleport
local teleport_to_blip_with_job = blip_teleport.teleport_to_blip_with_job

local actions = {}

local function config()
	return offsets.agency or {}
end

local text = i18n.t

local push = notify_core.feature("feature.agency.name")

local function get_interior_from_entity(entity)
	if not (entity and entity ~= 0) then
		return 0
	end
	return native.get_interior_from_entity(entity) or 0
end

local function resolve_computer_interior_id()
	if state.runtime.computer_interior_id and state.runtime.computer_interior_id ~= 0 then
		return state.runtime.computer_interior_id
	end
	local computer = config().computer.coords
	local result = native.get_interior_at_coords(computer.x, computer.y, computer.z)
	if result and result ~= 0 then
		state.runtime.computer_interior_id = result
		return state.runtime.computer_interior_id
	end
	return 0
end

local function is_in_agency_interior()
	local cfg = config()
	local me = players and players.me and players.me() or nil
	if not (me and me.in_interior and me.ped and me.ped ~= 0) then
		return false
	end

	local player_interior = get_interior_from_entity(me.ped)
	local agency_interior = resolve_computer_interior_id()
	if player_interior ~= 0 and agency_interior ~= 0 then
		return player_interior == agency_interior
	end

	local coords = me.coords
	if not coords then
		return false
	end

	local computer = cfg.computer.coords
	local dx = (coords.x or 0.0) - computer.x
	local dy = (coords.y or 0.0) - computer.y
	local dz = (coords.z or 0.0) - computer.z
	local radius = cfg.computer.fallback_radius
	return ((dx * dx) + (dy * dy) + (dz * dz)) <= (radius * radius)
end

local function find_finish_script()
	if safe_access.is_script_running("fm_mission_controller") then
		return "fm_mission_controller"
	end
	if safe_access.is_script_running("fm_mission_controller_2020") then
		return "fm_mission_controller_2020"
	end
	return nil
end

function actions.apply_and_complete_preps()
	local cfg = config()
	local contract = math.floor(tonumber(state.config.contract) or 3)

	local ok = true
	ok = safe_access.set_mp_stat_int(cfg.stats.story_bs, contract) and ok
	ok = safe_access.set_mp_stat_int(cfg.stats.story_strand, data.story_strand_from_contract(contract)) and ok
	ok = safe_access.set_mp_stat_int(cfg.stats.general_bs, -1) and ok
	ok = safe_access.set_mp_stat_int(cfg.stats.completed_bs, -1) and ok

	push(ok and "agency.notify.preps_ok" or "agency.notify.preps_failed", 2000)
	return ok
end

function actions.kill_cooldowns()
	local cfg = config()
	local ok = true
	ok = safe_access.set_tunable_int(cfg.tunables.story_cooldown_posix, 0) and ok
	ok = safe_access.set_tunable_int(cfg.tunables.security_contract_cooldown, 0) and ok
	ok = safe_access.set_tunable_int(cfg.tunables.payphone_cooldown, 0) and ok
	ok = safe_access.set_mp_stat_int(cfg.stats.story_cooldown, -1) and ok

	push(ok and "agency.notify.cooldowns_removed" or "agency.notify.cooldowns_failed", 2000)
	return ok
end

function actions.apply_payout()
	local cfg = config()
	local payout = data.clamp_payout(state.config.payout)
	state.set_payout(payout)

	local ok = safe_access.set_tunable_int(cfg.tunables.payout, payout)
	push(ok and "agency.notify.payout_ok" or "agency.notify.payout_failed", 2000)
	return ok
end

function actions.teleport_entrance()
	local cfg = config()
	return teleport_to_blip_with_job(
		cfg.blips.entrance,
		text("feature.agency.name"),
		text("agency.notify.teleported_entrance"),
		text("agency.notify.entrance_missing"),
		{ relay_if_interior = true }
	)
end

function actions.teleport_computer()
	local cfg = config()
	if not is_in_agency_interior() then
		push("agency.notify.must_be_inside", 2200)
		return false
	end

	local computer = cfg.computer.coords
	return run_coords_teleport(
		text("feature.agency.name"),
		text("agency.notify.teleported_computer"),
		computer.x,
		computer.y,
		computer.z,
		false,
		function()
			local me = players and players.me and players.me() or nil
			local entity = me and ((me.vehicle and me.vehicle ~= 0) and me.vehicle or me.ped) or nil
			if entity then
				native.set_entity_heading(entity, computer.heading)
			end
		end
	)
end

function actions.teleport_mission()
	local cfg = config()
	return teleport_to_blip_with_job(
		cfg.blips.franklin,
		text("feature.agency.name"),
		text("agency.notify.teleported_mission"),
		text("agency.notify.mission_missing")
	)
end

function actions.collect_safe()
	local cfg = config()
	actions.refresh_collect_safe_state()
	if not state.flags.collect_safe_ee_only then
		push("agency.notify.collect_safe_ee_only", 2200)
		return false
	end

	local value = safe_access.get_mp_stat_int(cfg.stats.safe_cash_value, 0) or 0
	if value <= 0 then
		push("agency.notify.safe_empty", 2000)
		return false
	end

	local ok = safe_access.set_global_bool(cfg.globals.safe_collect_bool, true)
	push(ok and "agency.notify.safe_collect_ok" or "agency.notify.safe_collect_failed", 2000)
	return ok
end

function actions.instant_finish_new()
	return run_guarded_job("agency_instant_finish_new", function()
		local cfg = config()
		local script_name = find_finish_script()
		if not script_name then
			push("agency.notify.no_controller", 2000)
			return
		end

		local finish = cfg.finish[script_name]
		if not finish then
			push("agency.notify.unsupported_controller", 2000)
			return
		end

		if not safe_access.force_host(script_name) then
			push("agency.notify.host_failed", 2200)
			return
		end
		util.yield(1000)

		local flags = safe_access.get_local_int_variants(script_name, finish.step3_offset, 0)
		flags = flags | (1 << 9)
		flags = flags | (1 << 16)

		local ok1 = safe_access.set_local_int_variants(script_name, finish.step1_offset, 5)
		local ok2 = safe_access.set_local_int_variants(script_name, finish.step2_offset, 999999)
		local ok3 = safe_access.set_local_int_variants(script_name, finish.step3_offset, flags)

		push((ok1 and ok2 and ok3) and "agency.notify.finish_ok" or "agency.notify.finish_failed", 2200)
	end, function()
		push("agency.notify.finish_running", 1500)
	end)
end

function actions.refresh_collect_safe_state()
	local cfg = config()
	state.flags.collect_safe_ee_only = safe_access.global_bool_supported(cfg.globals.safe_collect_bool)
	return state.flags.collect_safe_ee_only
end

function actions.skip_cutscene()
	return native_api.heist_skip_cutscene(text("feature.agency.name"))
end

return actions
