local core = require("ShillenSilent_core.core.bootstrap")
local native_api = require("ShillenSilent_core.core.native_api")
local presets = require("ShillenSilent_core.shared.presets_and_shared")
local doomsday_module = require("ShillenSilent_core.heists.doomsday.all")
local common = require("ShillenSilent_core.menu.common")

local state = core.state
local APARTMENT_CUT_PRESET_OPTIONS = presets.APARTMENT_CUT_PRESET_OPTIONS

local DoomsdayConfig = doomsday_module.DoomsdayConfig
local DoomsdayCutsValues = doomsday_module.DoomsdayCutsValues
local doomsday_flags = doomsday_module.doomsday_flags
local doomsday_cut_enabled = doomsday_module.doomsday_cut_enabled
local DOOMSDAY_ACT_OPTIONS = doomsday_module.DOOMSDAY_ACT_OPTIONS

local doomsday_menu = {
	ctx = { syncing = false },
	controls = {},
}

function doomsday_menu.refresh_controls()
	local ctx = doomsday_menu.ctx
	local controls = doomsday_menu.controls

	common.set_control_value(ctx, controls.act_combo, common.clamp_int(DoomsdayConfig.act, 1, #DOOMSDAY_ACT_OPTIONS))
	common.set_control_value(ctx, controls.solo_launch_toggle, state.solo_launch.doomsday and true or false)
	common.set_control_value(ctx, controls.max_payout_toggle, doomsday_flags.max_payout_enabled and true or false)
	common.set_control_value(
		ctx,
		controls.preset_combo,
		common.clamp_int(doomsday_flags.cut_preset_index, 1, #APARTMENT_CUT_PRESET_OPTIONS)
	)
	common.set_control_value(ctx, controls.p1_enable, doomsday_cut_enabled.player1 and true or false)
	common.set_control_value(ctx, controls.p2_enable, doomsday_cut_enabled.player2 and true or false)
	common.set_control_value(ctx, controls.p3_enable, doomsday_cut_enabled.player3 and true or false)
	common.set_control_value(ctx, controls.p4_enable, doomsday_cut_enabled.player4 and true or false)
	common.set_control_value(ctx, controls.p1_cut, common.clamp_int(DoomsdayCutsValues.player1, 0, 999))
	common.set_control_value(ctx, controls.p2_cut, common.clamp_int(DoomsdayCutsValues.player2, 0, 999))
	common.set_control_value(ctx, controls.p3_cut, common.clamp_int(DoomsdayCutsValues.player3, 0, 999))
	common.set_control_value(ctx, controls.p4_cut, common.clamp_int(DoomsdayCutsValues.player4, 0, 999))
	return true
end

function doomsday_menu.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local ctx = doomsday_menu.ctx
	local controls = doomsday_menu.controls
	local root = parent_menu:submenu("Doomsday")

	root:breaker("Doomsday Heist")
	root:breaker("Max transaction: $2,550,000")
	root:breaker("Transaction cooldown: 30 min")
	root:breaker("2 transactions in 30 min possible")
	root:breaker("Heist cooldown: unknown")

	local preps = root:submenu("Prep Presets")
	controls.act_combo = common.add_combo_options(ctx, preps, "Act", DOOMSDAY_ACT_OPTIONS, function()
		return DoomsdayConfig.act
	end, function(_, idx)
		doomsday_module.doomsday_set_selected_act(idx, true)
	end)
	common.add_button(preps, "Apply Selected Act", function()
		doomsday_module.doomsday_complete_preps(DoomsdayConfig.act)
	end)
	common.add_button(preps, "Reset to Act I Start", function()
		doomsday_module.doomsday_reset_progress()
	end)
	common.add_button(preps, "Clear All Prep Progress", function()
		doomsday_module.doomsday_reset_preps()
	end)
	common.add_button(preps, "Reload Planning Board", function()
		doomsday_module.doomsday_reload_board(true)
	end)

	local launch = root:submenu("Launch")
	controls.solo_launch_toggle = common.add_toggle(ctx, launch, "Solo Launch", function()
		return state.solo_launch.doomsday
	end, function(enabled)
		state.solo_launch.doomsday = enabled
	end)
	common.add_button(launch, "Force Ready", function()
		doomsday_module.doomsday_force_ready()
	end)
	common.add_button(launch, "Reset Solo Launch Overrides", function()
		doomsday_module.doomsday_manual_launch_reset()
	end)

	local tp = root:submenu("Teleport")
	common.add_button(tp, "Teleport to Entrance", function()
		doomsday_module.doomsday_teleport_to_entrance()
	end)
	common.add_button(tp, "Teleport to Screen", function()
		doomsday_module.doomsday_teleport_to_screen()
	end)

	local cuts = root:submenu("Cuts")
	controls.max_payout_toggle = common.add_toggle(ctx, cuts, "2.55mil Payout (Max)", function()
		return doomsday_flags.max_payout_enabled
	end, function(enabled)
		doomsday_module.doomsday_set_max_payout(enabled)
		doomsday_module.doomsday_refresh_max_payout(true, false)
		doomsday_menu.refresh_controls()
	end)

	local preset_entries = {}
	for i = 1, #APARTMENT_CUT_PRESET_OPTIONS do
		preset_entries[i] = { APARTMENT_CUT_PRESET_OPTIONS[i].name, i }
	end
	controls.preset_combo = common.add_combo_entries(ctx, cuts, "Presets", preset_entries, function()
		return common.clamp_int(doomsday_flags.cut_preset_index, 1, #APARTMENT_CUT_PRESET_OPTIONS)
	end, function(idx)
		doomsday_flags.cut_preset_index = idx
	end)
	common.add_button(cuts, "Apply Selected Preset", function()
		doomsday_module.apply_selected_doomsday_cut_preset(false, false)
		doomsday_menu.refresh_controls()
	end)

	controls.p1_enable = common.add_toggle(ctx, cuts, "Enable Player 1", function()
		return doomsday_cut_enabled.player1
	end, function(enabled)
		doomsday_cut_enabled.player1 = enabled and true or false
	end)
	controls.p1_cut = common.add_number_int(ctx, cuts, "Player 1", 0, 999, 1, function()
		return DoomsdayCutsValues.player1
	end, function(value)
		DoomsdayCutsValues.player1 = value
	end)
	controls.p2_enable = common.add_toggle(ctx, cuts, "Enable Player 2", function()
		return doomsday_cut_enabled.player2
	end, function(enabled)
		doomsday_cut_enabled.player2 = enabled and true or false
	end)
	controls.p2_cut = common.add_number_int(ctx, cuts, "Player 2", 0, 999, 1, function()
		return DoomsdayCutsValues.player2
	end, function(value)
		DoomsdayCutsValues.player2 = value
	end)
	controls.p3_enable = common.add_toggle(ctx, cuts, "Enable Player 3", function()
		return doomsday_cut_enabled.player3
	end, function(enabled)
		doomsday_cut_enabled.player3 = enabled and true or false
	end)
	controls.p3_cut = common.add_number_int(ctx, cuts, "Player 3", 0, 999, 1, function()
		return DoomsdayCutsValues.player3
	end, function(value)
		DoomsdayCutsValues.player3 = value
	end)
	controls.p4_enable = common.add_toggle(ctx, cuts, "Enable Player 4", function()
		return doomsday_cut_enabled.player4
	end, function(enabled)
		doomsday_cut_enabled.player4 = enabled and true or false
	end)
	controls.p4_cut = common.add_number_int(ctx, cuts, "Player 4", 0, 999, 1, function()
		return DoomsdayCutsValues.player4
	end, function(value)
		DoomsdayCutsValues.player4 = value
	end)
	common.add_button(cuts, "Apply Cuts", function()
		doomsday_module.apply_doomsday_cuts()
	end)

	local tools = root:submenu("Tools")
	common.add_button(tools, "Data Hack", function()
		doomsday_module.doomsday_data_hack()
	end)
	common.add_button(tools, "Doomsday Hack", function()
		doomsday_module.doomsday_doomsday_hack()
	end)
	common.add_button(tools, "Instant Finish", function()
		doomsday_module.doomsday_instant_finish_new()
	end)
	common.add_button(tools, "Skip Cutscene", function()
		native_api.heist_skip_cutscene("Doomsday")
	end)

	doomsday_menu.refresh_controls()
	return root
end

return doomsday_menu
