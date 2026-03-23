local core = require("ShillenSilent_core.core.bootstrap")
local safe_access = require("ShillenSilent_core.core.safe_access")
local presets = require("ShillenSilent_core.shared.presets_and_shared")
local heist_state = require("ShillenSilent_core.shared.heist_state")
local run_guarded_job = core.run_guarded_job
local GetMP = presets.GetMP
local CasinoGlobals = presets.CasinoGlobals
local CutsValues = presets.CutsValues
local SAFE_PAYOUT_TARGETS = presets.SAFE_PAYOUT_TARGETS
local hp_clamp_cut_percent = presets.hp_clamp_cut_percent
local hp_set_stat_for_all_characters = presets.hp_set_stat_for_all_characters

local casino_state = heist_state.casino
local casino_flags = casino_state.flags
local casino_refs = casino_state.refs
local casino_callbacks = casino_state.callbacks

local CASINO_CREW_CUT_TUNABLES = {
	{ name = "CH_LESTER_CUT", default = 5 },
	{ name = "HEIST3_PREPBOARD_GUNMEN_KARL_CUT", default = 5 },
	{ name = "HEIST3_PREPBOARD_GUNMEN_GUSTAVO_CUT", default = 9 },
	{ name = "HEIST3_PREPBOARD_GUNMEN_CHARLIE_CUT", default = 7 },
	{ name = "HEIST3_PREPBOARD_GUNMEN_CHESTER_CUT", default = 10 },
	{ name = "HEIST3_PREPBOARD_GUNMEN_PATRICK_CUT", default = 8 },
	{ name = "HEIST3_DRIVERS_KARIM_CUT", default = 5 },
	{ name = "HEIST3_DRIVERS_TALIANA_CUT", default = 7 },
	{ name = "HEIST3_DRIVERS_EDDIE_CUT", default = 9 },
	{ name = "HEIST3_DRIVERS_ZACH_CUT", default = 6 },
	{ name = "HEIST3_DRIVERS_CHESTER_CUT", default = 10 },
	{ name = "HEIST3_HACKERS_RICKIE_CUT", default = 3 },
	{ name = "HEIST3_HACKERS_CHRISTIAN_CUT", default = 7 },
	{ name = "HEIST3_HACKERS_YOHAN_CUT", default = 5 },
	{ name = "HEIST3_HACKERS_AVI_CUT", default = 10 },
	{ name = "HEIST3_HACKERS_PAIGE_CUT", default = 9 },
}

-- Enhanced Edition local offsets.
local CASINO_AUTOGRABBER_GRAB_LOCAL = 10295
local CASINO_AUTOGRABBER_SPEED_LOCAL = CASINO_AUTOGRABBER_GRAB_LOCAL + 14

local casino_crew_cut_backup = {}

local function hp_tunable_int(name)
	return script.tunables(name).int32
end

local function hp_set_tunable_int(name, value)
	script.tunables(name).int32 = value
end

local function hp_get_casino_max_payout_cut()
	local p = GetMP()
	local approach = safe_access.get_stat_int(p .. "H3OPT_APPROACH", 1)
	local hard_approach = safe_access.get_stat_int(p .. "H3_HARD_APPROACH", 0)
	local difficulty = (approach ~= 0 and approach == hard_approach) and 2 or 1
	local target = safe_access.get_stat_int(p .. "H3OPT_TARGET", 0)

	local payouts = {
		[0] = { 2115000, 2326500 }, -- Cash
		[2] = { 2350000, 2585000 }, -- Artwork
		[1] = { 2585000, 2843500 }, -- Gold
		[3] = { 3290000, 3619000 }, -- Diamonds
	}

	local payout_by_target = payouts[target]
	if not payout_by_target then
		return 100
	end

	local max_payout = SAFE_PAYOUT_TARGETS.casino
	local payout = (payout_by_target[difficulty] or payout_by_target[1]) + 819000
	local cut = math.floor(max_payout / (payout / 100))

	local buyer = safe_access.get_global_int(1975747, 0) -- DiamondCasino.Board.Buyer
	local gunman = safe_access.get_stat_int(p .. "H3OPT_CREWWEAP", 1)
	local driver = safe_access.get_stat_int(p .. "H3OPT_CREWDRIVER", 1)
	local hacker = safe_access.get_stat_int(p .. "H3OPT_CREWHACKER", 1)

	local buyer_fees = {
		[0] = 0.10,
		[3] = 0.05,
		[6] = 0.00,
	}
	local gunman_cuts = {
		[1] = 0.05,
		[3] = 0.07,
		[5] = 0.08,
		[2] = 0.09,
		[4] = 0.10,
	}
	local driver_cuts = {
		[1] = 0.05,
		[4] = 0.06,
		[2] = 0.07,
		[3] = 0.09,
		[5] = 0.10,
	}
	local hacker_cuts = {
		[1] = 0.03,
		[3] = 0.05,
		[2] = 0.07,
		[5] = 0.09,
		[4] = 0.10,
	}

	if buyer_fees[buyer] and gunman_cuts[gunman] and driver_cuts[driver] and hacker_cuts[hacker] then
		local fee_payout = payout - (payout * buyer_fees[buyer])
		local crew_ratio = 0.05 + gunman_cuts[gunman] + driver_cuts[driver] + hacker_cuts[hacker] -- + Lester
		local payout_after_crew = fee_payout - (fee_payout * crew_ratio)
		if payout_after_crew > 0 then
			cut = math.floor(max_payout / (payout_after_crew / 100))
		end
	end

	return hp_clamp_cut_percent(cut)
end

local function apply_casino_cuts()
	safe_access.set_global_int(CasinoGlobals.Host, CutsValues.host)
	safe_access.set_global_int(CasinoGlobals.P2, CutsValues.player2)
	safe_access.set_global_int(CasinoGlobals.P3, CutsValues.player3)
	safe_access.set_global_int(CasinoGlobals.P4, CutsValues.player4)
	if notify then
		notify.push("Casino Heist", "Cuts applied", 2000)
	end
end

local function casino_set_remove_crew_cuts(enable, silent)
	local enabled = enable and true or false
	local changed = (casino_flags.remove_crew_cuts_enabled ~= enabled)

	for i = 1, #CASINO_CREW_CUT_TUNABLES do
		local item = CASINO_CREW_CUT_TUNABLES[i]
		if enabled then
			if casino_crew_cut_backup[item.name] == nil then
				casino_crew_cut_backup[item.name] = hp_tunable_int(item.name)
			end
			hp_set_tunable_int(item.name, 0)
		else
			local restore = casino_crew_cut_backup[item.name]
			if restore == nil then
				restore = item.default
			end
			hp_set_tunable_int(item.name, restore)
		end
	end

	casino_flags.remove_crew_cuts_enabled = enabled
	if casino_refs.remove_crew_cuts_toggle then
		casino_refs.remove_crew_cuts_toggle.state = enabled
	end
	if changed and not silent and notify then
		notify.push("Casino", enabled and "Crew cuts removed" or "Crew cuts restored", 2000)
	end
end

local function casino_set_autograbber(enable, silent)
	local enabled = enable and true or false
	local changed = (casino_flags.autograbber_enabled ~= enabled)
	casino_flags.autograbber_enabled = enabled
	if casino_refs.autograbber_toggle then
		casino_refs.autograbber_toggle.state = enabled
	end

	if changed and not silent and notify then
		notify.push("Casino", enabled and "Autograbber enabled" or "Autograbber disabled", 2000)
	end
end

local function casino_autograbber_tick()
	if not casino_flags.autograbber_enabled then
		return
	end
	if not safe_access.is_script_running("fm_mission_controller") then
		return
	end

	local grab = safe_access.get_local_int("fm_mission_controller", CASINO_AUTOGRABBER_GRAB_LOCAL, 0)
	if grab == 3 then
		safe_access.set_local_int("fm_mission_controller", CASINO_AUTOGRABBER_GRAB_LOCAL, 4)
	elseif grab == 4 then
		safe_access.set_local_float("fm_mission_controller", CASINO_AUTOGRABBER_SPEED_LOCAL, 2.0)
	end
end

local function casino_enforce_heist_toggles()
	if casino_flags.remove_crew_cuts_enabled then
		for i = 1, #CASINO_CREW_CUT_TUNABLES do
			hp_set_tunable_int(CASINO_CREW_CUT_TUNABLES[i].name, 0)
		end
	end

	casino_autograbber_tick()
end

local function reset_heist_preps()
	local reset_pairs = {
		{ "H3OPT_DISRUPTSHIP", 0 },
		{ "H3OPT_BODYARMORLVL", 0 },
		{ "H3OPT_CREWWEAP", 0 },
		{ "H3OPT_CREWDRIVER", 0 },
		{ "H3OPT_CREWHACKER", 0 },
		{ "H3OPT_KEYLEVELS", 0 },
		{ "H3OPT_MODVEH", 0 },
		{ "H3OPT_MASKS", 0 },
		{ "H3OPT_WEAPS", 0 },
		{ "H3OPT_VEHS", 0 },
		{ "H3OPT_APPROACH", 0 },
		{ "H3OPT_BITSET0", 0 },
		{ "H3OPT_ACCESSPOINTS", 0 },
		{ "H3OPT_TARGET", 0 },
		{ "H3OPT_POI", 0 },
		{ "H3OPT_BITSET1", 0 },
		{ "H3_PARTIALPASS", 0 },
		{ "CAS_HEIST_NOTS", 0 },
		{ "CAS_HEIST_FLOW", -1 },
		{ "H3_LAST_APPROACH", 0 },
		{ "H3_HARD_APPROACH", 0 },
		{ "H3_SKIPCOUNT", 0 },
		{ "H3_MISSIONSKIPPED", 0 },
		{ "H3_BOARD_DIALOGUE0", 0 },
		{ "H3_BOARD_DIALOGUE1", 0 },
		{ "H3_BOARD_DIALOGUE2", 0 },
		{ "H3_VEHICLESUSED", 0 },
		{ "H3_COMPLETEDPOSIX", 0 },
	}

	for i = 1, #reset_pairs do
		hp_set_stat_for_all_characters(reset_pairs[i][1], reset_pairs[i][2])
	end
	safe_access.set_stat_int("MPPLY_H3_COOLDOWN", 0)
	safe_access.set_local_int("gb_casino_heist_planning", 212, 2)
	if notify then
		notify.push("Casino Preps", "Preps reset", 2000)
	end
end

-- Tools functions
local function casino_skip_arcade_setup()
	local success, result = pcall(function()
		return safe_access.set_stat_bool(27227, true, 1)
	end)

	if success and result then
		if notify then
			notify.push("Casino Tools", "Arcade setup skipped", 2000)
		end
	else
		if notify then
			notify.push("Casino Tools", "Could not skip arcade setup", 2000)
		end
	end
end

local function casino_fix_stuck_keycards()
	safe_access.set_local_int("fm_mission_controller", 63638, 5)
	if notify then
		notify.push("Casino Tools", "Keycards fixed", 2000)
	end
end

local function casino_skip_objective()
	local v = safe_access.get_local_int("fm_mission_controller", 20397, 0)
	safe_access.set_local_int("fm_mission_controller", 20397, v | (1 << 17))
	if notify then
		notify.push("Casino Tools", "Objective skipped", 2000)
	end
end

local function casino_fingerprint_hack()
	safe_access.set_local_int("fm_mission_controller", 54042, 5)
	if notify then
		notify.push("Casino Tools", "Fingerprint hack completed", 2000)
	end
end

local function casino_instant_keypad_hack()
	safe_access.set_local_int("fm_mission_controller", 55108, 5)
	if notify then
		notify.push("Casino Tools", "Keypad hack completed", 2000)
	end
end

local function casino_instant_vault_drill()
	safe_access.set_local_int("fm_mission_controller", 10551 + 2, 7)
	local current = safe_access.get_local_int("fm_mission_controller", 10551, 0)
	safe_access.set_local_int("fm_mission_controller", 10551, current | (1 << 12))
	if notify then
		notify.push("Casino Tools", "Vault drill completed", 2000)
	end
end

local function casino_remove_cooldown()
	local p = GetMP()
	safe_access.set_stat_int(p .. "H3_COMPLETEDPOSIX", -1)
	safe_access.set_stat_int("MPPLY_H3_COOLDOWN", -1)
	if notify then
		notify.push("Casino Tools", "Cooldown removed", 2000)
	end
end

local function casino_set_team_lives()
	if safe_access.is_script_running("fm_mission_controller") then
		safe_access.set_local_int("fm_mission_controller", 22126, -100)
		if notify then
			notify.push("Casino Tools", "Team lives set to 100", 2000)
		end
	else
		if notify then
			notify.push("Casino Tools", "Mission controller not running", 2000)
		end
	end
end

local function casino_instant_finish()
	if not safe_access.is_script_running("fm_mission_controller") then
		if notify then
			notify.push("Casino Tools", "Casino mission not running", 2000)
		end
		return false
	end

	return run_guarded_job("casino_instant_finish", function()
		safe_access.force_host("fm_mission_controller")
		util.yield(1000)

		local p = GetMP()
		local approach = safe_access.get_stat_int(p .. "H3OPT_APPROACH", 1)
		-- CASINO_STEP4_MONEY = 10000000
		-- APARTMENT_STEP4_MONEY = 10000000
		-- APARTMENT_STEP5 = 99999
		-- APARTMENT_STEP6 = 99999

		if approach == 3 then
			-- Aggressive approach
			safe_access.set_local_int("fm_mission_controller", 20395, 12) -- APARTMENT_FINISH_STEP1 = CASINO_AGGRESSIVE_STEP1
			safe_access.set_local_int("fm_mission_controller", 20395 + 1740 + 1, 80) -- APARTMENT_FINISH_STEP3 = APARTMENT_STEP3
			safe_access.set_local_int("fm_mission_controller", 20395 + 2686, 10000000) -- APARTMENT_FINISH_STEP4 = CASINO_STEP4_MONEY
			safe_access.set_local_int("fm_mission_controller", 29016 + 1, 99999) -- APARTMENT_FINISH_STEP5 = APARTMENT_STEP5
			safe_access.set_local_int("fm_mission_controller", 32472 + 1 + 68, 99999) -- APARTMENT_FINISH_STEP6 = APARTMENT_STEP6
		else
			-- Silent & Sneaky or Big Con
			safe_access.set_local_int("fm_mission_controller", 20395 + 1062, 5) -- APARTMENT_FINISH_STEP2 = APARTMENT_STEP2
			safe_access.set_local_int("fm_mission_controller", 20395 + 1740 + 1, 80) -- APARTMENT_FINISH_STEP3 = APARTMENT_STEP3
			safe_access.set_local_int("fm_mission_controller", 20395 + 2686, 10000000) -- APARTMENT_FINISH_STEP4 = APARTMENT_STEP4_MONEY
			safe_access.set_local_int("fm_mission_controller", 29016 + 1, 99999) -- APARTMENT_FINISH_STEP5 = APARTMENT_STEP5
			safe_access.set_local_int("fm_mission_controller", 32472 + 1 + 68, 99999) -- APARTMENT_FINISH_STEP6 = APARTMENT_STEP6
		end

		if notify then
			notify.push("Casino Tools", "Instant finish triggered", 2000)
		end
	end, function()
		if notify then
			notify.push("Casino Tools", "Instant finish already running", 1500)
		end
	end)
end

-- Casino Force Ready
local function casino_force_ready()
	return run_guarded_job("casino_force_ready", function()
		safe_access.force_host("fm_mission_controller")
		util.yield(1000)

		-- Set ready states for players 2, 3, 4
		safe_access.set_global_int(1977672, 1) -- CASINO_READY.PLAYER2 = READY_STATE_HEIST (1)
		safe_access.set_global_int(1977740, 1) -- CASINO_READY.PLAYER3 = READY_STATE_HEIST (1)
		safe_access.set_global_int(1977808, 1) -- CASINO_READY.PLAYER4 = READY_STATE_HEIST (1)

		if notify then
			notify.push("Casino Launch", "All players ready", 2000)
		end
	end, function()
		if notify then
			notify.push("Casino Launch", "Force ready already running", 1500)
		end
	end)
end

casino_callbacks.set_remove_crew_cuts = casino_set_remove_crew_cuts
casino_callbacks.set_autograbber = casino_set_autograbber

local casino_logic = {
	casino_flags = casino_flags,
	casino_refs = casino_refs,
	casino_callbacks = casino_callbacks,
	apply_casino_cuts = apply_casino_cuts,
	casino_set_remove_crew_cuts = casino_set_remove_crew_cuts,
	casino_set_autograbber = casino_set_autograbber,
	casino_enforce_heist_toggles = casino_enforce_heist_toggles,
	casino_skip_arcade_setup = casino_skip_arcade_setup,
	casino_fix_stuck_keycards = casino_fix_stuck_keycards,
	casino_skip_objective = casino_skip_objective,
	casino_fingerprint_hack = casino_fingerprint_hack,
	casino_instant_keypad_hack = casino_instant_keypad_hack,
	casino_instant_vault_drill = casino_instant_vault_drill,
	casino_remove_cooldown = casino_remove_cooldown,
	casino_set_team_lives = casino_set_team_lives,
	casino_instant_finish = casino_instant_finish,
	casino_force_ready = casino_force_ready,
	reset_heist_preps = reset_heist_preps,
	hp_get_casino_max_payout_cut = hp_get_casino_max_payout_cut,
}

return casino_logic
