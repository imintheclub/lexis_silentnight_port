local core = require("ShillenSilent_core.core.bootstrap")
local native_api = require("ShillenSilent_core.core.native_api")
local presets = require("ShillenSilent_core.shared.presets_and_shared")
local heist_state = require("ShillenSilent_core.shared.heist_state")
local coords_teleport = require("ShillenSilent_core.shared.coords_teleport")
local blip_teleport = require("ShillenSilent_core.shared.blip_teleport")
local casino_logic = require("ShillenSilent_core.heists.casino.logic")
local common = require("ShillenSilent_core.menu.common")

local state = core.state
local run_coords_teleport = coords_teleport.run_coords_teleport
local teleport_to_blip_with_job = blip_teleport.teleport_to_blip_with_job
local heist_skip_cutscene = native_api.heist_skip_cutscene
local hp_set_uniform_cuts = presets.hp_set_uniform_cuts
local hp_apply_casino_manual_preps = presets.hp_apply_casino_manual_preps
local CutsValues = presets.CutsValues

local casino_state = heist_state.casino
local CasinoPrepOptions = casino_state.prep_options
local CasinoManualPreps = casino_state.manual_preps
local casino_flags = casino_state.flags

local casino_menu = {
	ctx = { syncing = false },
	controls = {},
}

local function apply_casino_manual_preps()
	hp_apply_casino_manual_preps(CasinoManualPreps)
end

function casino_menu.refresh_controls()
	local ctx = casino_menu.ctx
	local controls = casino_menu.controls

	common.set_control_value(ctx, controls.autograbber_toggle, casino_flags.autograbber_enabled and true or false)
	common.set_control_value(ctx, controls.solo_launch_toggle, state.solo_launch.casino and true or false)
	common.set_control_value(ctx, controls.unlock_poi_toggle, CasinoManualPreps.unlock_all_poi and true or false)
	common.set_control_value(
		ctx,
		controls.diff_combo,
		common.find_index_by_value(CasinoPrepOptions.difficulties, CasinoManualPreps.difficulty, 1)
	)
	common.set_control_value(
		ctx,
		controls.approach_combo,
		common.find_index_by_value(CasinoPrepOptions.approaches, CasinoManualPreps.approach, 1)
	)
	common.set_control_value(
		ctx,
		controls.gunman_combo,
		common.find_index_by_value(CasinoPrepOptions.gunmen, CasinoManualPreps.crew_weapon, 1)
	)
	common.set_control_value(
		ctx,
		controls.driver_combo,
		common.find_index_by_value(CasinoPrepOptions.drivers, CasinoManualPreps.crew_driver, 1)
	)
	common.set_control_value(
		ctx,
		controls.hacker_combo,
		common.find_index_by_value(CasinoPrepOptions.hackers, CasinoManualPreps.crew_hacker, 1)
	)
	common.set_control_value(
		ctx,
		controls.masks_combo,
		common.find_index_by_value(CasinoPrepOptions.masks, CasinoManualPreps.masks, 1)
	)
	common.set_control_value(
		ctx,
		controls.guards_combo,
		common.find_index_by_value(CasinoPrepOptions.guards, CasinoManualPreps.disrupt_shipments, 1)
	)
	common.set_control_value(
		ctx,
		controls.keycards_combo,
		common.find_index_by_value(CasinoPrepOptions.keycards, CasinoManualPreps.key_levels, 1)
	)
	common.set_control_value(
		ctx,
		controls.target_combo,
		common.find_index_by_value(CasinoPrepOptions.targets, CasinoManualPreps.target, 1)
	)
	common.set_control_value(ctx, controls.loadout_slot, common.clamp_int(CasinoManualPreps.loadout_slot, 1, 2))
	common.set_control_value(ctx, controls.vehicle_slot, common.clamp_int(CasinoManualPreps.vehicle_slot, 1, 4))

	common.set_control_value(ctx, controls.remove_crew_toggle, casino_flags.remove_crew_cuts_enabled and true or false)
	common.set_control_value(ctx, controls.max_payout_toggle, casino_flags.max_payout_enabled and true or false)
	common.set_control_value(ctx, controls.host_cut, common.clamp_int(CutsValues.host, 0, 300))
	common.set_control_value(ctx, controls.p2_cut, common.clamp_int(CutsValues.player2, 0, 300))
	common.set_control_value(ctx, controls.p3_cut, common.clamp_int(CutsValues.player3, 0, 300))
	common.set_control_value(ctx, controls.p4_cut, common.clamp_int(CutsValues.player4, 0, 300))
	return true
end

function casino_menu.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local ctx = casino_menu.ctx
	local controls = casino_menu.controls
	local root = parent_menu:submenu("Diamond Casino")

	root:breaker("Diamond Casino Heist")
	root:breaker("Max transaction: $3,619,000")
	root:breaker("Transaction cooldown: 30 min")
	root:breaker("Heist cooldown: ~45 min (skip)")

	local tools = root:submenu("Tools")
	common.add_button(tools, "Fingerprint Hack", function()
		casino_logic.casino_fingerprint_hack()
	end)
	common.add_button(tools, "Keypad Hack", function()
		casino_logic.casino_instant_keypad_hack()
	end)
	common.add_button(tools, "Vault Drill", function()
		casino_logic.casino_instant_vault_drill()
	end)
	common.add_button(tools, "Instant Finish", function()
		casino_logic.casino_instant_finish()
	end)
	common.add_button(tools, "Fix Keycards", function()
		casino_logic.casino_fix_stuck_keycards()
	end)
	common.add_button(tools, "Skip Objective", function()
		casino_logic.casino_skip_objective()
	end)
	common.add_button(tools, "Skip Cutscene", function()
		heist_skip_cutscene("Casino")
	end)
	common.add_button(tools, "Set Team Lives", function()
		casino_logic.casino_set_team_lives()
	end)
	controls.autograbber_toggle = common.add_toggle(ctx, tools, "Autograbber", function()
		return casino_flags.autograbber_enabled
	end, function(enabled)
		casino_logic.casino_set_autograbber(enabled)
	end)

	local launch = root:submenu("Launch")
	controls.solo_launch_toggle = common.add_toggle(ctx, launch, "Solo Launch", function()
		return state.solo_launch.casino
	end, function(enabled)
		state.solo_launch.casino = enabled
	end)
	common.add_button(launch, "Force Ready", function()
		casino_logic.casino_force_ready()
	end)
	common.add_button(launch, "Skip Setup", function()
		casino_logic.casino_skip_arcade_setup()
	end)

	local preps = root:submenu("Preps")
	controls.unlock_poi_toggle = common.add_toggle(ctx, preps, "Unlock All POI on Apply", function()
		return CasinoManualPreps.unlock_all_poi
	end, function(enabled)
		CasinoManualPreps.unlock_all_poi = enabled and true or false
	end)
	controls.diff_combo = common.add_combo_options(ctx, preps, "Difficulty", CasinoPrepOptions.difficulties, function()
		return CasinoManualPreps.difficulty
	end, function(value)
		CasinoManualPreps.difficulty = value
	end)
	controls.approach_combo = common.add_combo_options(ctx, preps, "Approach", CasinoPrepOptions.approaches, function()
		return CasinoManualPreps.approach
	end, function(value)
		CasinoManualPreps.approach = value
	end)
	controls.gunman_combo = common.add_combo_options(ctx, preps, "Crew Gunman", CasinoPrepOptions.gunmen, function()
		return CasinoManualPreps.crew_weapon
	end, function(value)
		CasinoManualPreps.crew_weapon = value
	end)
	controls.loadout_slot = common.add_number_int(ctx, preps, "Loadout Slot", 1, 2, 1, function()
		return CasinoManualPreps.loadout_slot
	end, function(value)
		CasinoManualPreps.loadout_slot = value
	end)
	controls.driver_combo = common.add_combo_options(ctx, preps, "Crew Driver", CasinoPrepOptions.drivers, function()
		return CasinoManualPreps.crew_driver
	end, function(value)
		CasinoManualPreps.crew_driver = value
	end)
	controls.vehicle_slot = common.add_number_int(ctx, preps, "Vehicle Slot", 1, 4, 1, function()
		return CasinoManualPreps.vehicle_slot
	end, function(value)
		CasinoManualPreps.vehicle_slot = value
	end)
	controls.hacker_combo = common.add_combo_options(ctx, preps, "Crew Hacker", CasinoPrepOptions.hackers, function()
		return CasinoManualPreps.crew_hacker
	end, function(value)
		CasinoManualPreps.crew_hacker = value
	end)
	controls.masks_combo = common.add_combo_options(ctx, preps, "Masks", CasinoPrepOptions.masks, function()
		return CasinoManualPreps.masks
	end, function(value)
		CasinoManualPreps.masks = value
	end)
	controls.guards_combo = common.add_combo_options(ctx, preps, "Guards Strength", CasinoPrepOptions.guards, function()
		return CasinoManualPreps.disrupt_shipments
	end, function(value)
		CasinoManualPreps.disrupt_shipments = value
	end)
	controls.keycards_combo = common.add_combo_options(ctx, preps, "Keycards", CasinoPrepOptions.keycards, function()
		return CasinoManualPreps.key_levels
	end, function(value)
		CasinoManualPreps.key_levels = value
	end)
	controls.target_combo = common.add_combo_options(ctx, preps, "Target", CasinoPrepOptions.targets, function()
		return CasinoManualPreps.target
	end, function(value)
		CasinoManualPreps.target = value
	end)
	common.add_button(preps, "Reset Preps", function()
		casino_logic.reset_heist_preps()
	end)
	common.add_button(preps, "Apply Preps", function()
		apply_casino_manual_preps()
	end)

	local cuts = root:submenu("Cuts")
	controls.remove_crew_toggle = common.add_toggle(ctx, cuts, "Remove Crew Cuts", function()
		return casino_flags.remove_crew_cuts_enabled
	end, function(enabled)
		casino_logic.casino_set_remove_crew_cuts(enabled)
		casino_menu.refresh_controls()
	end)
	controls.max_payout_toggle = common.add_toggle(ctx, cuts, "3.619mil Payout (Max)", function()
		return casino_flags.max_payout_enabled
	end, function(enabled)
		casino_logic.casino_set_max_payout(enabled)
		casino_logic.casino_refresh_max_payout(true, false)
		casino_menu.refresh_controls()
	end)
	controls.host_cut = common.add_number_int(ctx, cuts, "Host Cut %", 0, 300, 5, function()
		return CutsValues.host
	end, function(value)
		CutsValues.host = value
	end)
	controls.p2_cut = common.add_number_int(ctx, cuts, "Player 2 Cut %", 0, 300, 5, function()
		return CutsValues.player2
	end, function(value)
		CutsValues.player2 = value
	end)
	controls.p3_cut = common.add_number_int(ctx, cuts, "Player 3 Cut %", 0, 300, 5, function()
		return CutsValues.player3
	end, function(value)
		CutsValues.player3 = value
	end)
	controls.p4_cut = common.add_number_int(ctx, cuts, "Player 4 Cut %", 0, 300, 5, function()
		return CutsValues.player4
	end, function(value)
		CutsValues.player4 = value
	end)
	common.add_button(cuts, "Apply Preset (100%)", function()
		hp_set_uniform_cuts(
			CutsValues,
			{ "host", "player2", "player3", "player4" },
			{ controls.host_cut, controls.p2_cut, controls.p3_cut, controls.p4_cut },
			100,
			casino_logic.apply_casino_cuts
		)
	end)
	common.add_button(cuts, "Apply Cuts", function()
		casino_logic.apply_casino_cuts()
	end)

	local tp = root:submenu("Teleport")
	common.add_button(tp, "Teleport to Arcade", function()
		teleport_to_blip_with_job(
			740,
			"Casino Teleport",
			"Teleported to Arcade",
			"Arcade blip not found",
			{ relay_if_interior = true }
		)
	end)
	common.add_button(tp, "Tunnel", function()
		run_coords_teleport("Casino Teleport", "Teleported to Tunnel", 968.0, -73.0, 75.0)
	end)
	common.add_button(tp, "Staff Lobby (Outside)", function()
		run_coords_teleport("Casino Teleport", "Teleported to Staff Lobby", 982.0, 16.0, 82.0)
	end)
	common.add_button(tp, "Staff Lobby (Inside)", function()
		run_coords_teleport("Casino Teleport", "Teleported to Staff Lobby", 2547.0, -270.0, -58.0)
	end)
	common.add_button(tp, "Side Safe", function()
		run_coords_teleport("Casino Teleport", "Teleported to Side Safe", 2522.0, -287.0, -58.0)
	end)
	common.add_button(tp, "Tunnel Door", function()
		run_coords_teleport("Casino Teleport", "Teleported to Tunnel Door", 2469.0, -279.0, -70.0)
	end)

	local danger = root:submenu("Danger")
	danger:breaker("Warning: use with caution")
	common.add_button(danger, "Skip Heist Cooldown", function()
		casino_logic.casino_remove_cooldown()
	end)

	casino_menu.refresh_controls()
	if casino_flags.max_payout_enabled then
		casino_logic.casino_refresh_max_payout(true, false)
	end
	return root
end

return casino_menu
