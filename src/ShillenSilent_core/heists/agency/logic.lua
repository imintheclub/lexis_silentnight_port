local core = require("ShillenSilent_core.core.bootstrap")
local safe_access = require("ShillenSilent_core.core.safe_access")
local presets = require("ShillenSilent_core.shared.presets_and_shared")
local heist_state = require("ShillenSilent_core.shared.heist_state")
local coords_teleport = require("ShillenSilent_core.shared.coords_teleport")
local blip_teleport = require("ShillenSilent_core.shared.blip_teleport")

local run_guarded_job = core.run_guarded_job
local run_coords_teleport = coords_teleport.run_coords_teleport
local teleport_to_blip_with_job = blip_teleport.teleport_to_blip_with_job
local GetMP = presets.GetMP

local agency_state = heist_state.agency
local AgencyPrepOptions = agency_state.prep_options
local AgencyConfig = agency_state.config
local agency_flags = agency_state.flags
local agency_refs = agency_state.refs
local agency_callbacks = agency_state.callbacks

local AGENCY_BLIP_ENTRANCE = 826
local AGENCY_BLIP_FRANKLIN = 88
local AGENCY_COMPUTER_COORDS = { x = -578.981, y = -711.381, z = 116.805, heading = 123.687 }

local AGENCY_TUNABLES = {
	PAYOUT = "FIXER_FINALE_LEADER_CASH_REWARD",
	STORY_COOLDOWN = "FIXER_STORY_COOLDOWN_POSIX",
	SECURITY_COOLDOWN = "FIXER_SECURITY_CONTRACT_COOLDOWN_TIME",
	PAYPHONE_COOLDOWN = "REQUEST_FRANKLIN_PAYPHONE_HIT_COOLDOWN",
}

local AGENCY_STATS = {
	STORY_BS = "FIXER_STORY_BS",
	STORY_STRAND = "FIXER_STORY_STRAND",
	GENERAL_BS = "FIXER_GENERAL_BS",
	COMPLETED_BS = "FIXER_COMPLETED_BS",
	STORY_COOLDOWN = "FIXER_STORY_COOLDOWN_POSIX",
	SECURITY_COOLDOWN = "FIXER_SECURITY_CONTRACT_COOLDOWN_TIME",
	PAYPHONE_COOLDOWN = "REQUEST_FRANKLIN_PAYPHONE_HIT_COOLDOWN",
	SAFE_CASH_VALUE = "FIXER_SAFE_CASH_VALUE",
}

local AGENCY_GLOBALS = {
	PAYOUT_COMPAT = 262145 + 31249,
	PAYPHONE_COOLDOWN = 262145 + 31283,
	PAYPHONE_SECURITY_COOLDOWN = 262145 + 31203,
	SAFE_COLLECT_BOOL = 2708850,
}

local AGENCY_FINISH_OLD = {
	script = "fm_mission_controller_2020",
	step1_offset = 56223 + 1,
	step2_offset = 56223 + 1776 + 1,
	step1_value = 51338752,
	step2_value = 50,
}

local AGENCY_FINISH_NEW = {
	["fm_mission_controller"] = {
		step1_offset = 20395 + 1062,
		step2_offset = 20395 + 1232 + 1,
		step3_offset = 20395 + 1,
	},
	["fm_mission_controller_2020"] = {
		step1_offset = 56223 + 1589,
		step2_offset = 56223 + 1776 + 1,
		step3_offset = 56223 + 1,
	},
}

local function agency_story_strand_from_contract(contract)
	if contract < 18 then
		return 0
	end
	if contract < 128 then
		return 1
	end
	if contract < 2044 then
		return 2
	end
	return -1
end

local function agency_apply_and_complete_preps()
	local p = GetMP()
	safe_access.set_stat_int(p .. AGENCY_STATS.STORY_BS, AgencyConfig.contract)
	safe_access.set_stat_int(p .. AGENCY_STATS.STORY_STRAND, agency_story_strand_from_contract(AgencyConfig.contract))
	safe_access.set_stat_int(p .. AGENCY_STATS.GENERAL_BS, -1)
	safe_access.set_stat_int(p .. AGENCY_STATS.COMPLETED_BS, -1)
	if notify then
		notify.push("Agency", "Preps applied", 2000)
	end
	return true
end

local function agency_kill_cooldowns()
	local p = GetMP()
	safe_access.set_tunable_int(AGENCY_TUNABLES.STORY_COOLDOWN, 0)
	safe_access.set_tunable_int(AGENCY_TUNABLES.SECURITY_COOLDOWN, 0)
	safe_access.set_tunable_int(AGENCY_TUNABLES.PAYPHONE_COOLDOWN, 0)

	safe_access.set_stat_int(p .. AGENCY_STATS.STORY_COOLDOWN, -1)
	safe_access.set_stat_int(p .. AGENCY_STATS.SECURITY_COOLDOWN, -1)
	safe_access.set_stat_int(p .. AGENCY_STATS.PAYPHONE_COOLDOWN, 0)

	safe_access.set_global_int(AGENCY_GLOBALS.PAYPHONE_COOLDOWN, 0)
	safe_access.set_global_int(AGENCY_GLOBALS.PAYPHONE_SECURITY_COOLDOWN, 0)

	if notify then
		notify.push("Agency", "Cooldowns removed", 2000)
	end
	return true
end

local function agency_apply_payout()
	safe_access.set_tunable_int(AGENCY_TUNABLES.PAYOUT, AgencyConfig.payout)

	local compat_exists = safe_access.get_global_int(AGENCY_GLOBALS.PAYOUT_COMPAT, nil) ~= nil
	if compat_exists then
		safe_access.set_global_int(AGENCY_GLOBALS.PAYOUT_COMPAT, AgencyConfig.payout)
	end

	if notify then
		notify.push("Agency", "Payout applied", 2000)
	end
	return true
end

local function agency_teleport_entrance()
	return teleport_to_blip_with_job(
		AGENCY_BLIP_ENTRANCE,
		"Agency Teleport",
		"Teleported to Entrance",
		"Agency entrance blip not found",
		{ relay_if_interior = true }
	)
end

local function agency_teleport_computer()
	return run_coords_teleport(
		"Agency Teleport",
		"Teleported to Computer",
		AGENCY_COMPUTER_COORDS.x,
		AGENCY_COMPUTER_COORDS.y,
		AGENCY_COMPUTER_COORDS.z,
		false,
		function()
			local me = players and players.me and players.me() or nil
			local entity = me and ((me.vehicle and me.vehicle ~= 0) and me.vehicle or me.ped) or nil
			if entity and invoker and invoker.call then
				invoker.call(0x8E2530AA8ADA980E, entity, AGENCY_COMPUTER_COORDS.heading) -- SET_ENTITY_HEADING
			end
		end
	)
end

local function agency_teleport_mission()
	return teleport_to_blip_with_job(
		AGENCY_BLIP_FRANKLIN,
		"Agency Teleport",
		"Teleported to Mission",
		"Franklin mission blip not found"
	)
end

local function agency_collect_safe()
	if not agency_flags.collect_safe_ee_only then
		if notify then
			notify.push("Agency", "Collect Safe is only supported on EE", 2200)
		end
		return false
	end

	local p = GetMP()
	local value = safe_access.get_stat_int(p .. AGENCY_STATS.SAFE_CASH_VALUE, 0) or 0
	if value <= 0 then
		if notify then
			notify.push("Agency", "Safe is empty", 2000)
		end
		return false
	end

	local ok = safe_access.set_global_bool(AGENCY_GLOBALS.SAFE_COLLECT_BOOL, true)
	if notify then
		notify.push("Agency", ok and "Safe collected" or "Collect failed", 2000)
	end
	return ok
end

local function agency_find_new_finish_script()
	if safe_access.is_script_running("fm_mission_controller") then
		return "fm_mission_controller"
	end
	if safe_access.is_script_running("fm_mission_controller_2020") then
		return "fm_mission_controller_2020"
	end
	return nil
end

local function agency_instant_finish_old()
	return run_guarded_job("agency_instant_finish_old", function()
		if not safe_access.is_script_running(AGENCY_FINISH_OLD.script) then
			if notify then
				notify.push("Agency", "Old finish requires fm_mission_controller_2020", 2200)
			end
			return
		end

		safe_access.force_host(AGENCY_FINISH_OLD.script)
		util.yield(1000)
		local ok1 = safe_access.set_local_int(
			AGENCY_FINISH_OLD.script,
			AGENCY_FINISH_OLD.step1_offset,
			AGENCY_FINISH_OLD.step1_value
		)
		local ok2 = safe_access.set_local_int(
			AGENCY_FINISH_OLD.script,
			AGENCY_FINISH_OLD.step2_offset,
			AGENCY_FINISH_OLD.step2_value
		)

		if notify then
			notify.push("Agency", (ok1 and ok2) and "Instant finish triggered (Old)" or "Old finish write failed", 2200)
		end
	end, function()
		if notify then
			notify.push("Agency", "Old finish already running", 1500)
		end
	end)
end

local function agency_instant_finish_new()
	return run_guarded_job("agency_instant_finish_new", function()
		local script_name = agency_find_new_finish_script()
		if not script_name then
			if notify then
				notify.push("Agency", "No mission controller is running", 2000)
			end
			return
		end

		local offsets = AGENCY_FINISH_NEW[script_name]
		if not offsets then
			if notify then
				notify.push("Agency", "Unsupported mission controller", 2000)
			end
			return
		end

		safe_access.force_host(script_name)
		util.yield(1000)

		local flags = safe_access.get_local_int(script_name, offsets.step3_offset, 0)
		flags = flags | (1 << 9)
		flags = flags | (1 << 16)

		local ok1 = safe_access.set_local_int(script_name, offsets.step1_offset, 5)
		local ok2 = safe_access.set_local_int(script_name, offsets.step2_offset, 999999)
		local ok3 = safe_access.set_local_int(script_name, offsets.step3_offset, flags)

		if notify then
			notify.push(
				"Agency",
				(ok1 and ok2 and ok3) and "Instant finish triggered (New)" or "New finish write failed",
				2200
			)
		end
	end, function()
		if notify then
			notify.push("Agency", "New finish already running", 1500)
		end
	end)
end

local function agency_refresh_collect_safe_state()
	agency_flags.collect_safe_ee_only = safe_access.get_global_bool(AGENCY_GLOBALS.SAFE_COLLECT_BOOL, nil) ~= nil
	if agency_refs.collect_safe_button then
		agency_refs.collect_safe_button.disabled = not agency_flags.collect_safe_ee_only
	end
	return agency_flags.collect_safe_ee_only
end

agency_callbacks.apply_preps = agency_apply_and_complete_preps
agency_callbacks.kill_cooldowns = agency_kill_cooldowns
agency_callbacks.apply_payout = agency_apply_payout
agency_callbacks.instant_finish = agency_instant_finish_old

local agency_logic = {
	AgencyConfig = AgencyConfig,
	AgencyPrepOptions = AgencyPrepOptions,
	agency_flags = agency_flags,
	agency_refs = agency_refs,
	agency_callbacks = agency_callbacks,
	agency_apply_and_complete_preps = agency_apply_and_complete_preps,
	agency_kill_cooldowns = agency_kill_cooldowns,
	agency_apply_payout = agency_apply_payout,
	agency_teleport_entrance = agency_teleport_entrance,
	agency_teleport_computer = agency_teleport_computer,
	agency_teleport_mission = agency_teleport_mission,
	agency_collect_safe = agency_collect_safe,
	agency_instant_finish = agency_instant_finish_old,
	agency_instant_finish_old = agency_instant_finish_old,
	agency_instant_finish_new = agency_instant_finish_new,
	agency_refresh_collect_safe_state = agency_refresh_collect_safe_state,
}

return agency_logic
