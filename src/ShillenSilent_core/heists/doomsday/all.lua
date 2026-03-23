-- -------------------------------------------------------------------------
-- [Doomsday Functions]
-- -------------------------------------------------------------------------

local core = require("ShillenSilent_core.core.bootstrap")
local ui = require("ShillenSilent_core.core.ui")
local native_api = require("ShillenSilent_core.core.native_api")
local safe_access = require("ShillenSilent_core.core.safe_access")
local presets = require("ShillenSilent_core.shared.presets_and_shared")
local heist_state = require("ShillenSilent_core.shared.heist_state")
local blip_teleport = require("ShillenSilent_core.shared.blip_teleport")
local solo_launch_runtime = require("ShillenSilent_core.runtime.solo_launch")

local config = core.config
local state = core.state
local run_guarded_job = core.run_guarded_job
local heist_skip_cutscene = native_api.heist_skip_cutscene
local GetMP = presets.GetMP
local SAFE_PAYOUT_TARGETS = presets.SAFE_PAYOUT_TARGETS
local hp_set_stat_for_all_characters = presets.hp_set_stat_for_all_characters
local hp_set_uniform_cuts = presets.hp_set_uniform_cuts
local hp_options_to_names = presets.hp_options_to_names
local hp_find_option_index = presets.hp_find_option_index
local hp_clamp_doomsday_cut_percent = presets.hp_clamp_doomsday_cut_percent
local APARTMENT_CUT_PRESET_OPTIONS = presets.APARTMENT_CUT_PRESET_OPTIONS
local hp_build_heist_preset_group = presets.hp_build_heist_preset_group
local BLIP_SPRITES_FACILITY = blip_teleport.BLIP_SPRITES_FACILITY
local BLIP_SPRITES_HEIST = blip_teleport.BLIP_SPRITES_HEIST
local teleport_to_blip_with_job = blip_teleport.teleport_to_blip_with_job

local doomsday_state = heist_state.doomsday
local DoomsdayConfig = doomsday_state.config
local DoomsdayCutsValues = doomsday_state.cuts
local doomsday_cut_enabled = doomsday_state.cut_enabled
local doomsday_flags = doomsday_state.flags
local doomsday_refs = doomsday_state.refs
local doomsday_callbacks = doomsday_state.callbacks

local DOOMSDAY_ACT_OPTIONS = {
	{ name = "Act I: The Data Breaches", value = 1 },
	{ name = "Act II: The Bogdan Problem", value = 2 },
	{ name = "Act III: The Doomsday Scenario", value = 3 },
}

local DOOMSDAY_ACT_PRESETS = {
	[1] = { flow = 503, status = -229383 },
	[2] = { flow = 240, status = -229378 },
	[3] = { flow = 16368, status = -229380 },
}

local DOOMSDAY_FINISH_NEW_OFFSETS = {
	["fm_mission_controller"] = {
		step1 = 20395 + 1062,
		step2 = 20395 + 1232 + 1,
		step3 = 20395 + 1,
	},
	["fm_mission_controller_2020"] = {
		step1 = 56223 + 1589,
		step2 = 56223 + 1776 + 1,
		step3 = 56223 + 1,
	},
}

local function doomsday_reload_board(show_missing_notice)
	if safe_access.is_script_running("gb_gang_ops_planning") then
		return safe_access.set_local_int("gb_gang_ops_planning", 211, 6)
	end

	if show_missing_notice and notify then
		notify.push("Doomsday", "Board not active (enter Facility first)", 2000)
	end
	return false
end

local function doomsday_set_selected_act(act, silent)
	local numeric_act = tonumber(act)
	if not numeric_act then
		return false
	end

	local selected_act = math.floor(numeric_act)
	if selected_act < 1 or selected_act > #DOOMSDAY_ACT_OPTIONS then
		return false
	end

	DoomsdayConfig.act = selected_act
	if doomsday_refs.act_dropdown then
		doomsday_refs.act_dropdown.value = selected_act
	end

	if not silent and notify then
		notify.push("Doomsday", "Selected " .. DOOMSDAY_ACT_OPTIONS[selected_act].name, 2000)
	end

	return true
end

local function doomsday_complete_preps(act)
	if not doomsday_set_selected_act(act, true) then
		if notify then
			notify.push("Doomsday", "Invalid act selected", 2000)
		end
		return false
	end

	local selected = DOOMSDAY_ACT_PRESETS[DoomsdayConfig.act]
	if not selected then
		return false
	end

	hp_set_stat_for_all_characters("GANGOPS_FLOW_MISSION_PROG", selected.flow)
	hp_set_stat_for_all_characters("GANGOPS_HEIST_STATUS", selected.status)
	hp_set_stat_for_all_characters("GANGOPS_FLOW_NOTIFICATIONS", 1557)

	doomsday_reload_board(false)

	if notify then
		notify.push("Doomsday", "Preps applied", 2000)
	end
	return true
end

local function doomsday_reset_progress()
	hp_set_stat_for_all_characters("GANGOPS_FLOW_MISSION_PROG", 503)
	hp_set_stat_for_all_characters("GANGOPS_HEIST_STATUS", 0)
	hp_set_stat_for_all_characters("GANGOPS_FLOW_NOTIFICATIONS", 1557)

	doomsday_reload_board(false)

	if notify then
		notify.push("Doomsday", "Progress reset", 2000)
	end
	return true
end

local function doomsday_reset_preps()
	hp_set_stat_for_all_characters("GANGOPS_FLOW_MISSION_PROG", 0)
	hp_set_stat_for_all_characters("GANGOPS_HEIST_STATUS", 0)
	hp_set_stat_for_all_characters("GANGOPS_FLOW_NOTIFICATIONS", 0)

	doomsday_reload_board(false)

	if notify then
		notify.push("Doomsday", "Preps reset", 2000)
	end
	return true
end

local function doomsday_force_ready()
	return run_guarded_job("doomsday_force_ready", function()
		safe_access.force_host("fm_mission_controller")
		util.yield(1000)

		local ok1 = safe_access.set_global_int(1883089, 1)
		local ok2 = safe_access.set_global_int(1883405, 1)
		local ok3 = safe_access.set_global_int(1883721, 1)

		if notify then
			if ok1 and ok2 and ok3 then
				notify.push("Doomsday Launch", "All players ready", 2000)
			else
				notify.push("Doomsday Launch", "Could not set ready state", 2000)
			end
		end
	end, function()
		if notify then
			notify.push("Doomsday Launch", "Force ready already running", 1500)
		end
	end)
end

local function doomsday_teleport_to_entrance()
	return teleport_to_blip_with_job(
		BLIP_SPRITES_FACILITY,
		"Teleport",
		"Teleported to Facility",
		"Facility blip not found",
		{ relay_if_interior = true }
	)
end

local function doomsday_teleport_to_screen()
	return teleport_to_blip_with_job(
		BLIP_SPRITES_HEIST,
		"Teleport",
		"Teleported to Doomsday Screen",
		"Heist board blip not found (enter Facility first)",
		{ heading = 325.726 }
	)
end

local function hp_get_doomsday_max_payout_cut()
	local p = GetMP()
	local heist = safe_access.get_stat_int(p .. "GANGOPS_FLOW_MISSION_PROG", nil)
	if not DOOMSDAY_ACT_PRESETS[DoomsdayConfig.act] then
		DoomsdayConfig.act = 1
	end
	if not heist or not (heist == 503 or heist == 240 or heist == 16368) then
		heist = DOOMSDAY_ACT_PRESETS[DoomsdayConfig.act].flow
	end

	local difficulty_raw = safe_access.get_global_int(4718592 + 3538, 0)
	local difficulty = 1
	if difficulty_raw ~= nil then
		if difficulty_raw <= 1 then
			difficulty = difficulty_raw + 1
		else
			difficulty = difficulty_raw
		end
	end
	if difficulty < 1 then
		difficulty = 1
	end
	if difficulty > 2 then
		difficulty = 2
	end

	local payouts = {
		[503] = { 975000, 1218750 },
		[240] = { 1425000, 1771250 },
		[16368] = { 1800000, 2250000 },
	}

	local payout_by_heist = payouts[heist] or payouts[503]
	local payout = payout_by_heist[difficulty] or payout_by_heist[1]
	local cut = math.floor(SAFE_PAYOUT_TARGETS.doomsday / (payout / 100))
	return hp_clamp_doomsday_cut_percent(cut)
end

local function apply_doomsday_cuts(cuts)
	if type(cuts) == "table" then
		DoomsdayCutsValues.player1 = hp_clamp_doomsday_cut_percent(cuts[1] or DoomsdayCutsValues.player1)
		DoomsdayCutsValues.player2 = hp_clamp_doomsday_cut_percent(cuts[2] or DoomsdayCutsValues.player2)
		DoomsdayCutsValues.player3 = hp_clamp_doomsday_cut_percent(cuts[3] or DoomsdayCutsValues.player3)
		DoomsdayCutsValues.player4 = hp_clamp_doomsday_cut_percent(cuts[4] or DoomsdayCutsValues.player4)
	end

	if doomsday_flags.max_payout_enabled then
		local max_cut = hp_get_doomsday_max_payout_cut()
		hp_set_uniform_cuts(
			DoomsdayCutsValues,
			{ "player1", "player2", "player3", "player4" },
			{ doomsday_refs.p1_slider, doomsday_refs.p2_slider, doomsday_refs.p3_slider, doomsday_refs.p4_slider },
			max_cut
		)
	end

	local p1 = doomsday_cut_enabled.player1 and hp_clamp_doomsday_cut_percent(DoomsdayCutsValues.player1) or 0
	local p2 = doomsday_cut_enabled.player2 and hp_clamp_doomsday_cut_percent(DoomsdayCutsValues.player2) or 0
	local p3 = doomsday_cut_enabled.player3 and hp_clamp_doomsday_cut_percent(DoomsdayCutsValues.player3) or 0
	local p4 = doomsday_cut_enabled.player4 and hp_clamp_doomsday_cut_percent(DoomsdayCutsValues.player4) or 0

	local ok1 = safe_access.set_global_int(1969406, p1)
	local ok2 = safe_access.set_global_int(1969407, p2)
	local ok3 = safe_access.set_global_int(1969408, p3)
	local ok4 = safe_access.set_global_int(1969409, p4)

	if notify then
		if ok1 and ok2 and ok3 and ok4 then
			notify.push("Doomsday Cuts", "Cuts applied", 2000)
		else
			notify.push("Doomsday Cuts", "Could not apply cuts (memory write failed)", 2200)
		end
	end
	return ok1 and ok2 and ok3 and ok4
end

local function apply_selected_doomsday_cut_preset(apply_now, silent)
	local selected = APARTMENT_CUT_PRESET_OPTIONS[doomsday_flags.cut_preset_index]
		or APARTMENT_CUT_PRESET_OPTIONS[#APARTMENT_CUT_PRESET_OPTIONS]

	local selected_cut = selected and selected.value or 100
	if doomsday_flags.max_payout_enabled then
		selected_cut = hp_get_doomsday_max_payout_cut()
	end

	local apply_fn = nil
	if apply_now then
		apply_fn = apply_doomsday_cuts
	end

	hp_set_uniform_cuts(
		DoomsdayCutsValues,
		{ "player1", "player2", "player3", "player4" },
		{ doomsday_refs.p1_slider, doomsday_refs.p2_slider, doomsday_refs.p3_slider, doomsday_refs.p4_slider },
		selected_cut,
		apply_fn
	)

	if not silent and notify then
		notify.push("Doomsday Cuts", "Cut preset loaded", 2000)
	end
	return selected_cut
end

local function doomsday_set_max_payout(enable, silent)
	local enabled = enable and true or false
	local changed = doomsday_flags.max_payout_enabled ~= enabled

	doomsday_flags.max_payout_enabled = enabled
	if doomsday_refs.max_payout_toggle then
		doomsday_refs.max_payout_toggle.state = enabled
	end

	if enabled then
		apply_selected_doomsday_cut_preset(false, true)
	end

	if changed and not silent and notify then
		notify.push("Doomsday Cuts", enabled and "Max payout enabled" or "Max payout disabled", 2000)
	end

	return true
end

local function doomsday_data_hack()
	if safe_access.is_script_running("fm_mission_controller") then
		local ok = safe_access.set_local_int("fm_mission_controller", 1541, 2)
		if notify then
			notify.push("Doomsday Tools", ok and "Data hack completed" or "Data hack write failed", 2000)
		end
		return ok
	end

	if notify then
		notify.push("Doomsday Tools", "Hack not active", 2000)
	end
	return false
end

local function doomsday_doomsday_hack()
	if safe_access.is_script_running("fm_mission_controller") then
		local ok = safe_access.set_local_int("fm_mission_controller", 1298 + 135, 3)
		if notify then
			notify.push("Doomsday Tools", ok and "Doomsday hack completed" or "Doomsday hack write failed", 2000)
		end
		return ok
	end

	if notify then
		notify.push("Doomsday Tools", "Hack not active", 2000)
	end
	return false
end

local function doomsday_instant_finish_old()
	return run_guarded_job("doomsday_instant_finish_old", function()
		if not safe_access.is_script_running("fm_mission_controller") then
			if notify then
				notify.push("Doomsday Tools", "Old method requires fm_mission_controller", 2000)
			end
			return
		end

		if safe_access.force_host("fm_mission_controller") then
			util.yield(1000)
			local ok1 = safe_access.set_local_int("fm_mission_controller", 20395, 12)
			local ok2 = safe_access.set_local_int("fm_mission_controller", 22136, 150)
			local ok3 = safe_access.set_local_int("fm_mission_controller", 29017, 99999)
			local ok4 = safe_access.set_local_int("fm_mission_controller", 32541, 99999)
			local ok5 = safe_access.set_local_int("fm_mission_controller", 32569, 80)
			if notify then
				if ok1 and ok2 and ok3 and ok4 and ok5 then
					notify.push("Doomsday Tools", "Instant finish triggered (Old)", 2000)
				else
					notify.push("Doomsday Tools", "Old finish write failed", 2200)
				end
			end
		elseif notify then
			notify.push("Doomsday Tools", "Could not force host", 2000)
		end
	end, function()
		if notify then
			notify.push("Doomsday Tools", "Old finish already running", 1500)
		end
	end)
end

local function doomsday_instant_finish_new()
	return run_guarded_job("doomsday_instant_finish_new", function()
		local script_name = nil
		if safe_access.is_script_running("fm_mission_controller") then
			script_name = "fm_mission_controller"
		elseif safe_access.is_script_running("fm_mission_controller_2020") then
			script_name = "fm_mission_controller_2020"
		end

		if not script_name then
			if notify then
				notify.push("Doomsday Tools", "No heist mission controller is running", 2000)
			end
			return
		end

		safe_access.force_host(script_name)
		util.yield(1000)

		local offsets = DOOMSDAY_FINISH_NEW_OFFSETS[script_name]
		if not offsets then
			if notify then
				notify.push("Doomsday Tools", "Unsupported mission controller", 2000)
			end
			return
		end

		local bits = safe_access.get_local_int(script_name, offsets.step3, 0)
		bits = bits | (1 << 9)
		bits = bits | (1 << 16)

		local ok1 = safe_access.set_local_int(script_name, offsets.step1, 5)
		local ok2 = safe_access.set_local_int(script_name, offsets.step2, 999999)
		local ok3 = safe_access.set_local_int(script_name, offsets.step3, bits)

		if notify then
			if ok1 and ok2 and ok3 then
				notify.push("Doomsday Tools", "Instant finish triggered (New)", 2000)
			else
				notify.push("Doomsday Tools", "New finish write failed", 2200)
			end
		end
	end, function()
		if notify then
			notify.push("Doomsday Tools", "New finish already running", 1500)
		end
	end)
end

local function doomsday_manual_launch_reset()
	return run_guarded_job("doomsday_manual_launch_reset", function()
		state.solo_launch.doomsday = false
		if doomsday_refs.solo_launch_toggle then
			doomsday_refs.solo_launch_toggle.state = false
		end

		local reset_fn = solo_launch_runtime.manual_reset_doomsday_launch
		if type(reset_fn) ~= "function" then
			reset_fn = solo_launch_runtime.solo_launch_reset_doomsday
		end

		local ok = false
		if type(reset_fn) == "function" then
			ok = reset_fn() and true or false
		end

		if notify then
			if ok then
				notify.push("Doomsday Launch", "Launch settings reset", 2000)
			else
				notify.push("Doomsday Launch", "Launch reset unavailable right now", 2000)
			end
		end
	end, function()
		if notify then
			notify.push("Doomsday Launch", "Launch reset already running", 1500)
		end
	end)
end

local function register(heistTab)
	if type(heistTab) ~= "table" then
		return nil
	end

	if not DoomsdayConfig.act or not DOOMSDAY_ACT_PRESETS[DoomsdayConfig.act] then
		DoomsdayConfig.act = 1
	end
	if
		not doomsday_flags.cut_preset_index
		or doomsday_flags.cut_preset_index < 1
		or doomsday_flags.cut_preset_index > #APARTMENT_CUT_PRESET_OPTIONS
	then
		doomsday_flags.cut_preset_index = #APARTMENT_CUT_PRESET_OPTIONS
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
			doomsday_set_selected_act(selected, true)
		end
	)
	ui.button(gDoomsdayPreps, "doomsday_apply_selected_act", "Apply Selected Act", function()
		doomsday_complete_preps(DoomsdayConfig.act)
	end)
	ui.button_pair(
		gDoomsdayPreps,
		"doomsday_reset",
		"Reset to Act I Start",
		function()
			doomsday_reset_progress()
		end,
		"doomsday_reset_preps",
		"Clear All Prep Progress",
		function()
			doomsday_reset_preps()
		end
	)
	ui.button(gDoomsdayPreps, "doomsday_reload_board", "Reload Planning Board", function()
		if doomsday_reload_board(true) and notify then
			notify.push("Doomsday", "Planning board reloaded", 2000)
		end
	end)

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
			doomsday_force_ready()
		end,
		"doomsday_launch_reset_manual",
		"Reset Solo Launch Overrides",
		function()
			doomsday_manual_launch_reset()
		end
	)

	local gDoomsdayTeleport = ui.group(heistTab, "Teleport", nil, nil, nil, nil, "doomsday")
	ui.button_pair(
		gDoomsdayTeleport,
		"doomsday_teleport_entrance",
		"Teleport to Entrance",
		function()
			doomsday_teleport_to_entrance()
		end,
		"doomsday_teleport_screen",
		"Teleport to Screen",
		function()
			doomsday_teleport_to_screen()
		end
	)

	local gDoomsdayCuts = ui.group(heistTab, "Cuts", nil, nil, nil, nil, "doomsday")
	doomsday_refs.max_payout_toggle = ui.toggle(
		gDoomsdayCuts,
		"doomsday_max_payout",
		"2.55mil Payout (Max)",
		doomsday_flags.max_payout_enabled,
		function(val)
			doomsday_set_max_payout(val)
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
			apply_selected_doomsday_cut_preset(false, false)
		end,
		"doomsday_preset_max_instant",
		"Apply Preset (Max Payout)",
		function()
			hp_set_uniform_cuts(
				DoomsdayCutsValues,
				{ "player1", "player2", "player3", "player4" },
				{ doomsday_refs.p1_slider, doomsday_refs.p2_slider, doomsday_refs.p3_slider, doomsday_refs.p4_slider },
				hp_get_doomsday_max_payout_cut()
			)
			if notify then
				notify.push("Doomsday Cuts", "Max payout cut preset loaded", 2000)
			end
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
			DoomsdayCutsValues.player1 = hp_clamp_doomsday_cut_percent(val)
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
			DoomsdayCutsValues.player2 = hp_clamp_doomsday_cut_percent(val)
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
			DoomsdayCutsValues.player3 = hp_clamp_doomsday_cut_percent(val)
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
			DoomsdayCutsValues.player4 = hp_clamp_doomsday_cut_percent(val)
		end,
		nil,
		1
	)

	ui.button(gDoomsdayCuts, "doomsday_cuts_apply", "Apply Cuts", function()
		apply_doomsday_cuts()
	end)

	local gDoomsdayTools = ui.group(heistTab, "Tools", nil, nil, nil, nil, "doomsday")
	ui.button_pair(
		gDoomsdayTools,
		"doomsday_data_hack",
		"Data Hack",
		function()
			doomsday_data_hack()
		end,
		"doomsday_doomsday_hack",
		"Doomsday Hack",
		function()
			doomsday_doomsday_hack()
		end
	)
	ui.button_pair(
		gDoomsdayTools,
		"doomsday_instant_finish_old",
		"Instant Finish (Old)",
		function()
			doomsday_instant_finish_old()
		end,
		"doomsday_instant_finish_new",
		"Instant Finish (New)",
		function()
			doomsday_instant_finish_new()
		end
	)
	ui.button(gDoomsdayTools, "doomsday_skip_cutscene", "Skip Cutscene", function()
		heist_skip_cutscene("Doomsday")
	end)

	doomsday_callbacks.apply_cuts = apply_doomsday_cuts
	doomsday_callbacks.set_max_payout = doomsday_set_max_payout
	doomsday_callbacks.apply_cut_preset = apply_selected_doomsday_cut_preset
	doomsday_callbacks.set_selected_act = doomsday_set_selected_act

	return heistTab
end

local doomsday_module = {
	DoomsdayCutsValues = DoomsdayCutsValues,
	register = register,
}

return doomsday_module
