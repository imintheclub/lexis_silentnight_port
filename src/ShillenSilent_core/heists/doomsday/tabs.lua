local core = require("ShillenSilent_core.core.bootstrap")
local ui = require("ShillenSilent_core.core.ui")
local native_api = require("ShillenSilent_core.core.native_api")
local presets = require("ShillenSilent_core.shared.presets_and_shared")
local doomsday_module = require("ShillenSilent_core.heists.doomsday.all")

local config = core.config
local state = core.state
local heist_skip_cutscene = native_api.heist_skip_cutscene
local hp_options_to_names = presets.hp_options_to_names
local hp_find_option_index = presets.hp_find_option_index
local APARTMENT_CUT_PRESET_OPTIONS = presets.APARTMENT_CUT_PRESET_OPTIONS
local hp_build_heist_preset_group = presets.hp_build_heist_preset_group

local DoomsdayConfig = doomsday_module.DoomsdayConfig
local DoomsdayCutsValues = doomsday_module.DoomsdayCutsValues
local doomsday_flags = doomsday_module.doomsday_flags
local doomsday_cut_enabled = doomsday_module.doomsday_cut_enabled
local doomsday_refs = doomsday_module.doomsday_refs
local DOOMSDAY_ACT_OPTIONS = doomsday_module.DOOMSDAY_ACT_OPTIONS

local function register(heistTab)
	if type(heistTab) ~= "table" then
		return nil
	end

	local gDoomsdayInfo = ui.group(heistTab, "Info", nil, nil, nil, 170, "doomsday")
	ui.label(gDoomsdayInfo, "Doomsday Heist", config.colors.accent)
	ui.label(gDoomsdayInfo, "Max transaction: $2,550,000", config.colors.text_main)
	ui.label(gDoomsdayInfo, "Transaction cooldown: 30 min", config.colors.text_sec)
	ui.label(gDoomsdayInfo, "2 transactions in 30 min possible", config.colors.text_sec)
	ui.label(gDoomsdayInfo, "Heist cooldown: unknown", config.colors.text_sec)

	doomsday_refs.presets_group = hp_build_heist_preset_group(heistTab, "doomsday", "doomsday", "doomsday")

	local gDoomsdayPreps = ui.group(heistTab, "Prep Presets", nil, nil, nil, nil, "doomsday")
	doomsday_refs.act_dropdown = ui.dropdown(
		gDoomsdayPreps,
		"doomsday_act",
		"Act",
		hp_options_to_names(DOOMSDAY_ACT_OPTIONS),
		DoomsdayConfig.act,
		function(opt)
			local selected = hp_find_option_index(hp_options_to_names(DOOMSDAY_ACT_OPTIONS), opt, DoomsdayConfig.act)
			doomsday_module.doomsday_set_selected_act(selected, true)
		end
	)
	ui.button_pair(
		gDoomsdayPreps,
		"doomsday_apply_selected_act",
		"Apply Selected Act",
		function()
			doomsday_module.doomsday_complete_preps(DoomsdayConfig.act)
		end,
		"doomsday_reload_board",
		"Reload Planning Board",
		function()
			if doomsday_module.doomsday_reload_board(true) and notify then
				notify.push("Doomsday", "Planning board reloaded", 2000)
			end
		end
	)
	ui.button_pair(
		gDoomsdayPreps,
		"doomsday_reset",
		"Reset to Act I Start",
		function()
			doomsday_module.doomsday_reset_progress()
		end,
		"doomsday_reset_preps",
		"Clear All Prep Progress",
		function()
			doomsday_module.doomsday_reset_preps()
		end
	)

	local gDoomsdayLaunch = ui.group(heistTab, "Launch", nil, nil, nil, nil, "doomsday")
	doomsday_refs.solo_launch_toggle = ui.toggle(
		gDoomsdayLaunch,
		"doomsday_launch_solo",
		"Solo Launch",
		state.solo_launch.doomsday,
		function(val)
			state.solo_launch.doomsday = val
		end
	)
	ui.button_pair(
		gDoomsdayLaunch,
		"doomsday_launch_force_ready",
		"Force Ready",
		function()
			doomsday_module.doomsday_force_ready()
		end,
		"doomsday_launch_reset_manual",
		"Reset Solo Launch Overrides",
		function()
			doomsday_module.doomsday_manual_launch_reset()
		end
	)

	local gDoomsdayTeleport = ui.group(heistTab, "Teleport", nil, nil, nil, nil, "doomsday")
	ui.button_pair(
		gDoomsdayTeleport,
		"doomsday_teleport_entrance",
		"Teleport to Entrance",
		function()
			doomsday_module.doomsday_teleport_to_entrance()
		end,
		"doomsday_teleport_screen",
		"Teleport to Screen",
		function()
			doomsday_module.doomsday_teleport_to_screen()
		end
	)

	local gDoomsdayCuts = ui.group(heistTab, "Cuts", nil, nil, nil, nil, "doomsday")
	doomsday_refs.max_payout_toggle = ui.toggle(
		gDoomsdayCuts,
		"doomsday_max_payout",
		"2.55mil Payout (Max)",
		doomsday_flags.max_payout_enabled,
		function(val)
			doomsday_module.doomsday_set_max_payout(val)
		end
	)
	doomsday_refs.cut_preset_dropdown = ui.dropdown(
		gDoomsdayCuts,
		"doomsday_cut_preset",
		"Presets",
		hp_options_to_names(APARTMENT_CUT_PRESET_OPTIONS),
		doomsday_flags.cut_preset_index,
		function(opt)
			doomsday_flags.cut_preset_index = hp_find_option_index(
				hp_options_to_names(APARTMENT_CUT_PRESET_OPTIONS),
				opt,
				doomsday_flags.cut_preset_index
			)
		end
	)
	ui.button_pair(
		gDoomsdayCuts,
		"doomsday_preset_apply",
		"Apply Selected Preset",
		function()
			doomsday_module.apply_selected_doomsday_cut_preset(false, false)
		end,
		"doomsday_cuts_apply",
		"Apply Cuts",
		function()
			doomsday_module.apply_doomsday_cuts()
		end
	)

	doomsday_refs.p1_toggle = ui.toggle(
		gDoomsdayCuts,
		"doomsday_cut_p1_enabled",
		"Enable Player 1",
		doomsday_cut_enabled.player1,
		function(val)
			doomsday_cut_enabled.player1 = val and true or false
		end
	)
	doomsday_refs.p1_slider = ui.slider(
		gDoomsdayCuts,
		"doomsday_cut_p1",
		"Player 1",
		0,
		999,
		DoomsdayCutsValues.player1,
		function(val)
			DoomsdayCutsValues.player1 = presets.hp_clamp_doomsday_cut_percent(val)
		end,
		nil,
		1
	)

	doomsday_refs.p2_toggle = ui.toggle(
		gDoomsdayCuts,
		"doomsday_cut_p2_enabled",
		"Enable Player 2",
		doomsday_cut_enabled.player2,
		function(val)
			doomsday_cut_enabled.player2 = val and true or false
		end
	)
	doomsday_refs.p2_slider = ui.slider(
		gDoomsdayCuts,
		"doomsday_cut_p2",
		"Player 2",
		0,
		999,
		DoomsdayCutsValues.player2,
		function(val)
			DoomsdayCutsValues.player2 = presets.hp_clamp_doomsday_cut_percent(val)
		end,
		nil,
		1
	)

	doomsday_refs.p3_toggle = ui.toggle(
		gDoomsdayCuts,
		"doomsday_cut_p3_enabled",
		"Enable Player 3",
		doomsday_cut_enabled.player3,
		function(val)
			doomsday_cut_enabled.player3 = val and true or false
		end
	)
	doomsday_refs.p3_slider = ui.slider(
		gDoomsdayCuts,
		"doomsday_cut_p3",
		"Player 3",
		0,
		999,
		DoomsdayCutsValues.player3,
		function(val)
			DoomsdayCutsValues.player3 = presets.hp_clamp_doomsday_cut_percent(val)
		end,
		nil,
		1
	)

	doomsday_refs.p4_toggle = ui.toggle(
		gDoomsdayCuts,
		"doomsday_cut_p4_enabled",
		"Enable Player 4",
		doomsday_cut_enabled.player4,
		function(val)
			doomsday_cut_enabled.player4 = val and true or false
		end
	)
	doomsday_refs.p4_slider = ui.slider(
		gDoomsdayCuts,
		"doomsday_cut_p4",
		"Player 4",
		0,
		999,
		DoomsdayCutsValues.player4,
		function(val)
			DoomsdayCutsValues.player4 = presets.hp_clamp_doomsday_cut_percent(val)
		end,
		nil,
		1
	)

	local gDoomsdayTools = ui.group(heistTab, "Tools", nil, nil, nil, nil, "doomsday")
	ui.button_pair(
		gDoomsdayTools,
		"doomsday_data_hack",
		"Data Hack",
		function()
			doomsday_module.doomsday_data_hack()
		end,
		"doomsday_doomsday_hack",
		"Doomsday Hack",
		function()
			doomsday_module.doomsday_doomsday_hack()
		end
	)
	ui.button_pair(
		gDoomsdayTools,
		"doomsday_instant_finish",
		"Instant Finish",
		function()
			doomsday_module.doomsday_instant_finish_new()
		end,
		"doomsday_skip_cutscene",
		"Skip Cutscene",
		function()
			heist_skip_cutscene("Doomsday")
		end
	)

	if doomsday_flags.max_payout_enabled then
		doomsday_module.doomsday_refresh_max_payout(true, false)
	end

	return heistTab
end

local doomsday_tabs = {
	register = register,
}

return doomsday_tabs
