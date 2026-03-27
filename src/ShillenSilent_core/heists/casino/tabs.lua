local core = require("ShillenSilent_core.core.bootstrap")
local ui = require("ShillenSilent_core.core.ui")
local native_api = require("ShillenSilent_core.core.native_api")
local presets = require("ShillenSilent_core.shared.presets_and_shared")
local heist_state = require("ShillenSilent_core.shared.heist_state")
local danger_groups = require("ShillenSilent_core.shared.danger_groups")
local coords_teleport = require("ShillenSilent_core.shared.coords_teleport")
local blip_teleport = require("ShillenSilent_core.shared.blip_teleport")
local casino_logic = require("ShillenSilent_core.heists.casino.logic")

local config = core.config
local state = core.state
local heist_skip_cutscene = native_api.heist_skip_cutscene
local hp_set_uniform_cuts = presets.hp_set_uniform_cuts
local hp_apply_casino_manual_preps = presets.hp_apply_casino_manual_preps
local hp_build_heist_preset_group = presets.hp_build_heist_preset_group
local hp_option_names_range = presets.hp_option_names_range
local hp_options_to_names = presets.hp_options_to_names
local hp_option_index_by_value = presets.hp_option_index_by_value
local hp_option_value_by_name = presets.hp_option_value_by_name
local CutsValues = presets.CutsValues
local build_skip_cooldown_danger_group = danger_groups.build_skip_cooldown_danger_group
local cooldown_danger_warning_lines = danger_groups.cooldown_danger_warning_lines
local reset_heist_preps = casino_logic.reset_heist_preps
local casino_set_autograbber = casino_logic.casino_set_autograbber
local casino_force_ready = casino_logic.casino_force_ready
local apply_casino_cuts = casino_logic.apply_casino_cuts
local casino_set_remove_crew_cuts = casino_logic.casino_set_remove_crew_cuts
local casino_set_max_payout = casino_logic.casino_set_max_payout
local casino_refresh_max_payout = casino_logic.casino_refresh_max_payout
local casino_fingerprint_hack = casino_logic.casino_fingerprint_hack
local casino_instant_keypad_hack = casino_logic.casino_instant_keypad_hack
local casino_instant_vault_drill = casino_logic.casino_instant_vault_drill
local casino_skip_arcade_setup = casino_logic.casino_skip_arcade_setup
local casino_skip_objective = casino_logic.casino_skip_objective
local casino_fix_stuck_keycards = casino_logic.casino_fix_stuck_keycards
local casino_remove_cooldown = casino_logic.casino_remove_cooldown
local casino_set_team_lives = casino_logic.casino_set_team_lives
local casino_instant_finish = casino_logic.casino_instant_finish
local run_coords_teleport = coords_teleport.run_coords_teleport
local teleport_to_blip_with_job = blip_teleport.teleport_to_blip_with_job

local casino_state = heist_state.casino
local CasinoPrepOptions = casino_state.prep_options
local CasinoLoadoutRangesByApproach = casino_state.loadout_ranges_by_approach
local CasinoLoadoutRangesByGunmanAndApproach = casino_state.loadout_ranges_by_gunman_and_approach
local CasinoVehicleRangesByDriver = casino_state.vehicle_ranges_by_driver
local CasinoManualPreps = casino_state.manual_preps
local casino_flags = casino_state.flags
local casino_refs = casino_state.refs
local casino_callbacks = casino_state.callbacks

local function hp_get_casino_loadout_range(approach, gunman)
	local gunman_ranges = CasinoLoadoutRangesByGunmanAndApproach[gunman]
	if gunman_ranges and gunman_ranges[approach] then
		return gunman_ranges[approach]
	end
	return CasinoLoadoutRangesByApproach[approach] or { 1, 2 }
end

local function hp_update_casino_loadout_dropdown(reset_selection)
	local range = hp_get_casino_loadout_range(CasinoManualPreps.approach, CasinoManualPreps.crew_weapon)
	local names = hp_option_names_range(CasinoPrepOptions.loadouts, range[1], range[2])

	if reset_selection then
		CasinoManualPreps.loadout_slot = 1
	end
	if CasinoManualPreps.loadout_slot < 1 or CasinoManualPreps.loadout_slot > #names then
		CasinoManualPreps.loadout_slot = 1
	end

	if casino_refs.manual_loadout_dropdown then
		casino_refs.manual_loadout_dropdown.options = names
		casino_refs.manual_loadout_dropdown.value = CasinoManualPreps.loadout_slot
	end
end

local function hp_update_casino_vehicle_dropdown(reset_selection)
	local range = CasinoVehicleRangesByDriver[CasinoManualPreps.crew_driver] or { 1, 4 }
	local names = hp_option_names_range(CasinoPrepOptions.vehicles, range[1], range[2])

	if reset_selection then
		CasinoManualPreps.vehicle_slot = 1
	end
	if CasinoManualPreps.vehicle_slot < 1 or CasinoManualPreps.vehicle_slot > #names then
		CasinoManualPreps.vehicle_slot = 1
	end

	if casino_refs.manual_vehicles_dropdown then
		casino_refs.manual_vehicles_dropdown.options = names
		casino_refs.manual_vehicles_dropdown.value = CasinoManualPreps.vehicle_slot
	end
end

casino_callbacks.update_loadout_dropdown = hp_update_casino_loadout_dropdown
casino_callbacks.update_vehicle_dropdown = hp_update_casino_vehicle_dropdown

-- Function to apply manual preps
local function apply_casino_manual_preps()
	hp_apply_casino_manual_preps(CasinoManualPreps)
end

local function register(heistTab)
	if type(heistTab) ~= "table" then
		return nil
	end

	local gCasinoInfo = ui.group(heistTab, "Info", nil, nil, nil, 140, "casino")
	ui.label(gCasinoInfo, "Diamond Casino Heist", config.colors.accent)
	ui.label(gCasinoInfo, "Max transaction: $3,619,000", config.colors.text_main)
	ui.label(gCasinoInfo, "Transaction cooldown: 30 min", config.colors.text_sec)
	ui.label(gCasinoInfo, "Heist cooldown: ~45 min (skip)", config.colors.text_sec)

	casino_refs.presets_group = hp_build_heist_preset_group(heistTab, "casino", "casino", "casino")

	local gTools = ui.group(heistTab, "Tools", nil, nil, nil, nil, "casino")
	ui.button_pair(
		gTools,
		"tool_finger",
		"Fingerprint Hack",
		function()
			casino_fingerprint_hack()
		end,
		"tool_keypad",
		"Keypad Hack",
		function()
			casino_instant_keypad_hack()
		end
	)
	ui.button_pair(
		gTools,
		"tool_vault",
		"Vault Drill",
		function()
			casino_instant_vault_drill()
		end,
		"tool_finish",
		"Instant Finish",
		function()
			casino_instant_finish()
		end
	)
	ui.button_pair(
		gTools,
		"tool_keycards",
		"Fix Keycards",
		function()
			casino_fix_stuck_keycards()
		end,
		"tool_objective",
		"Skip Objective",
		function()
			casino_skip_objective()
		end
	)
	ui.button_pair(
		gTools,
		"casino_skip_cutscene",
		"Skip Cutscene",
		function()
			heist_skip_cutscene("Casino")
		end,
		"tool_lives",
		"Set Team Lives",
		function()
			casino_set_team_lives()
		end
	)
	casino_refs.autograbber_toggle = ui.toggle(
		gTools,
		"casino_autograbber",
		"Autograbber",
		casino_flags.autograbber_enabled,
		function(val)
			casino_set_autograbber(val)
		end
	)

	build_skip_cooldown_danger_group(heistTab, "casino", "casino_skip_heist_cooldown", function()
		casino_remove_cooldown()
	end)

	-- Launch group
	local ARCADE_BLIP_ENTRANCE = 740
	local function casino_teleport_arcade()
		teleport_to_blip_with_job(
			ARCADE_BLIP_ENTRANCE,
			"Casino Teleport",
			"Teleported to Arcade",
			"Arcade blip not found",
			{ relay_if_interior = true }
		)
	end

	local gLaunch = ui.group(heistTab, "Launch", nil, nil, nil, nil, "casino")
	ui.button(gLaunch, "casino_tp_arcade_launch", "Teleport to Arcade", function()
		casino_teleport_arcade()
	end)
	casino_refs.solo_launch_toggle = ui.toggle(
		gLaunch,
		"launch_solo",
		"Solo Launch",
		state.solo_launch.casino,
		function(val)
			state.solo_launch.casino = val
		end
	)
	ui.button_pair(
		gLaunch,
		"launch_force_ready",
		"Force Ready",
		function()
			casino_force_ready()
		end,
		"launch_skip_setup",
		"Skip Setup",
		function()
			casino_skip_arcade_setup()
		end
	)

	-- Manual Preps group
	local gManualPreps = ui.group(heistTab, "Preps", nil, nil, nil, nil, "casino")
	casino_refs.manual_unlock_poi_toggle = ui.toggle(
		gManualPreps,
		"manual_unlock_poi",
		"Unlock All POI on Apply",
		CasinoManualPreps.unlock_all_poi,
		function(val)
			CasinoManualPreps.unlock_all_poi = val
		end
	)
	casino_refs.manual_difficulty_dropdown = ui.dropdown(
		gManualPreps,
		"manual_difficulty",
		"Difficulty",
		hp_options_to_names(CasinoPrepOptions.difficulties),
		hp_option_index_by_value(CasinoPrepOptions.difficulties, CasinoManualPreps.difficulty, 1),
		function(opt)
			CasinoManualPreps.difficulty = hp_option_value_by_name(CasinoPrepOptions.difficulties, opt, 0)
		end
	)
	casino_refs.manual_approach_dropdown = ui.dropdown(
		gManualPreps,
		"manual_approach",
		"Approach",
		hp_options_to_names(CasinoPrepOptions.approaches),
		hp_option_index_by_value(CasinoPrepOptions.approaches, CasinoManualPreps.approach, 1),
		function(opt)
			CasinoManualPreps.approach = hp_option_value_by_name(CasinoPrepOptions.approaches, opt, 1)
			CasinoManualPreps.crew_weapon = CasinoPrepOptions.gunmen[1].value
			if casino_refs.manual_gunman_dropdown then
				casino_refs.manual_gunman_dropdown.value = 1
			end
			hp_update_casino_loadout_dropdown(true)
		end
	)
	casino_refs.manual_gunman_dropdown = ui.dropdown(
		gManualPreps,
		"manual_crew_weapon",
		"Crew Gunman",
		hp_options_to_names(CasinoPrepOptions.gunmen),
		hp_option_index_by_value(CasinoPrepOptions.gunmen, CasinoManualPreps.crew_weapon, 1),
		function(opt)
			CasinoManualPreps.crew_weapon = hp_option_value_by_name(CasinoPrepOptions.gunmen, opt, 1)
			hp_update_casino_loadout_dropdown(true)
		end
	)
	casino_refs.manual_loadout_dropdown = ui.dropdown(
		gManualPreps,
		"manual_weapons",
		"Loadout",
		{ "Micro SMG (S)", "Machine Pistol (S)" },
		1,
		function(opt)
			for i = 1, #casino_refs.manual_loadout_dropdown.options do
				if casino_refs.manual_loadout_dropdown.options[i] == opt then
					CasinoManualPreps.loadout_slot = i
					break
				end
			end
		end
	)
	casino_refs.manual_driver_dropdown = ui.dropdown(
		gManualPreps,
		"manual_crew_driver",
		"Crew Driver",
		hp_options_to_names(CasinoPrepOptions.drivers),
		hp_option_index_by_value(CasinoPrepOptions.drivers, CasinoManualPreps.crew_driver, 1),
		function(opt)
			CasinoManualPreps.crew_driver = hp_option_value_by_name(CasinoPrepOptions.drivers, opt, 1)
			hp_update_casino_vehicle_dropdown(true)
		end
	)
	casino_refs.manual_vehicles_dropdown = ui.dropdown(
		gManualPreps,
		"manual_vehicles",
		"Vehicles",
		{ "Issi Classic", "Asbo", "Blista Kanjo", "Sentinel Classic" },
		1,
		function(opt)
			for i = 1, #casino_refs.manual_vehicles_dropdown.options do
				if casino_refs.manual_vehicles_dropdown.options[i] == opt then
					CasinoManualPreps.vehicle_slot = i
					break
				end
			end
		end
	)
	casino_refs.manual_hacker_dropdown = ui.dropdown(
		gManualPreps,
		"manual_crew_hacker",
		"Crew Hacker",
		hp_options_to_names(CasinoPrepOptions.hackers),
		hp_option_index_by_value(CasinoPrepOptions.hackers, CasinoManualPreps.crew_hacker, 1),
		function(opt)
			CasinoManualPreps.crew_hacker = hp_option_value_by_name(CasinoPrepOptions.hackers, opt, 1)
		end
	)
	casino_refs.manual_masks_dropdown = ui.dropdown(
		gManualPreps,
		"manual_masks",
		"Masks",
		hp_options_to_names(CasinoPrepOptions.masks),
		hp_option_index_by_value(CasinoPrepOptions.masks, CasinoManualPreps.masks, 1),
		function(opt)
			CasinoManualPreps.masks = hp_option_value_by_name(CasinoPrepOptions.masks, opt, 4)
		end
	)
	casino_refs.manual_guards_dropdown = ui.dropdown(
		gManualPreps,
		"manual_disrupt",
		"Guards Strength",
		hp_options_to_names(CasinoPrepOptions.guards),
		hp_option_index_by_value(CasinoPrepOptions.guards, CasinoManualPreps.disrupt_shipments, 1),
		function(opt)
			CasinoManualPreps.disrupt_shipments = hp_option_value_by_name(CasinoPrepOptions.guards, opt, 3)
		end
	)
	casino_refs.manual_keycards_dropdown = ui.dropdown(
		gManualPreps,
		"manual_key_levels",
		"Keycards",
		hp_options_to_names(CasinoPrepOptions.keycards),
		hp_option_index_by_value(CasinoPrepOptions.keycards, CasinoManualPreps.key_levels, 1),
		function(opt)
			CasinoManualPreps.key_levels = hp_option_value_by_name(CasinoPrepOptions.keycards, opt, 2)
		end
	)
	casino_refs.manual_target_dropdown = ui.dropdown(
		gManualPreps,
		"manual_target",
		"Target",
		hp_options_to_names(CasinoPrepOptions.targets),
		hp_option_index_by_value(CasinoPrepOptions.targets, CasinoManualPreps.target, 1),
		function(opt)
			CasinoManualPreps.target = hp_option_value_by_name(CasinoPrepOptions.targets, opt, 3)
		end
	)
	ui.button_pair(
		gManualPreps,
		"manual_reset_preps",
		"Reset Preps",
		function()
			reset_heist_preps()
		end,
		"manual_apply",
		"Apply Preps",
		function()
			apply_casino_manual_preps()
		end
	)
	hp_update_casino_loadout_dropdown(true)
	hp_update_casino_vehicle_dropdown(true)

	local gCuts = ui.group(heistTab, "Cuts", nil, nil, nil, nil, "casino")
	casino_refs.remove_crew_cuts_toggle = ui.toggle(
		gCuts,
		"casino_remove_crew_cuts",
		"Remove Crew Cuts",
		casino_flags.remove_crew_cuts_enabled,
		function(val)
			casino_set_remove_crew_cuts(val)
		end
	)
	casino_refs.max_payout_toggle = ui.toggle(
		gCuts,
		"casino_max_payout",
		"3.619mil Payout (Max)",
		casino_flags.max_payout_enabled,
		function(val)
			casino_set_max_payout(val)
		end
	)
	casino_refs.host_slider = ui.slider(gCuts, "cut_host", "Host Cut %", 0, 300, 100, function(val)
		CutsValues.host = math.floor(val)
	end, nil, 5)
	casino_refs.p2_slider = ui.slider(gCuts, "cut_p2", "Player 2 Cut %", 0, 300, 0, function(val)
		CutsValues.player2 = math.floor(val)
	end, nil, 5)
	casino_refs.p3_slider = ui.slider(gCuts, "cut_p3", "Player 3 Cut %", 0, 300, 0, function(val)
		CutsValues.player3 = math.floor(val)
	end, nil, 5)
	casino_refs.p4_slider = ui.slider(gCuts, "cut_p4", "Player 4 Cut %", 0, 300, 0, function(val)
		CutsValues.player4 = math.floor(val)
	end, nil, 5)
	ui.button(gCuts, "cuts_max", "Apply Preset (100%)", function()
		hp_set_uniform_cuts(
			CutsValues,
			{ "host", "player2", "player3", "player4" },
			{ casino_refs.host_slider, casino_refs.p2_slider, casino_refs.p3_slider, casino_refs.p4_slider },
			100,
			apply_casino_cuts
		)
	end)
	ui.button(gCuts, "cuts_apply", "Apply Cuts", function()
		apply_casino_cuts()
	end)
	if casino_flags.max_payout_enabled then
		casino_refresh_max_payout(true, true)
	else
		casino_set_remove_crew_cuts(casino_flags.remove_crew_cuts_enabled, true)
	end

	-- Casino Teleport functions
	local function casino_teleport_tunnel()
		-- Tunnel coordinates (Casino Heist - Outside Casino)
		-- Coordinates: 968, -73, 75
		run_coords_teleport("Casino Teleport", "Teleported to Tunnel", 968.0, -73.0, 75.0)
	end

	local function casino_teleport_staff_lobby()
		-- Staff Lobby coordinates (Casino Heist - Outside Casino)
		-- Coordinates: 982, 16, 82
		run_coords_teleport("Casino Teleport", "Teleported to Staff Lobby", 982.0, 16.0, 82.0)
	end

	local function casino_teleport_staff_lobby_inside()
		-- Staff Lobby coordinates (Casino Heist - In Casino)
		-- Coordinates: 2547, -270, -58
		run_coords_teleport("Casino Teleport", "Teleported to Staff Lobby", 2547.0, -270.0, -58.0)
	end

	local function casino_teleport_side_safe()
		-- Side Safe coordinates (Casino Heist - In Casino)
		-- Coordinates: 2522, -287, -58
		run_coords_teleport("Casino Teleport", "Teleported to Side Safe", 2522.0, -287.0, -58.0)
	end

	local function casino_teleport_tunnel_door()
		-- Tunnel Door coordinates (Casino Heist - In Casino)
		-- Coordinates: 2469, -279, -70
		run_coords_teleport("Casino Teleport", "Teleported to Tunnel Door", 2469.0, -279.0, -70.0)
	end

	-- Teleport section - Outside Casino
	local gCasinoTeleportOutside = ui.group(heistTab, "Teleport - Outside Casino", nil, nil, nil, nil, "casino")
	ui.button_pair(
		gCasinoTeleportOutside,
		"casino_tp_tunnel",
		"Tunnel",
		function()
			casino_teleport_tunnel()
		end,
		"casino_tp_staff_lobby",
		"Staff Lobby",
		function()
			casino_teleport_staff_lobby()
		end
	)

	-- Teleport section - In Casino (moved below Outside Casino)
	local gCasinoTeleportInside = ui.group(heistTab, "Teleport - In Casino", nil, nil, nil, nil, "casino")
	ui.button_pair(
		gCasinoTeleportInside,
		"casino_tp_staff_lobby_inside",
		"Staff Lobby",
		function()
			casino_teleport_staff_lobby_inside()
		end,
		"casino_tp_side_safe",
		"Side Safe",
		function()
			casino_teleport_side_safe()
		end
	)
	ui.button(gCasinoTeleportInside, "casino_tp_tunnel_door", "Tunnel Door", function()
		casino_teleport_tunnel_door()
	end)

	return heistTab
end

local casino_tabs = {
	heistTab = nil,
	build_skip_cooldown_danger_group = build_skip_cooldown_danger_group,
	cooldown_danger_warning_lines = cooldown_danger_warning_lines,
	CasinoPrepOptions = CasinoPrepOptions,
	CasinoManualPreps = CasinoManualPreps,
	register = register,
}

return casino_tabs
