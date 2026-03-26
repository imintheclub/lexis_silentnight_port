-- -------------------------------------------------------------------------
-- [Doomsday Functions]
-- -------------------------------------------------------------------------

local core = require("ShillenSilent_noclick_core.core.bootstrap")
local safe_access = require("ShillenSilent_noclick_core.core.safe_access")
local presets = require("ShillenSilent_noclick_core.shared.presets_and_shared")
local heist_state = require("ShillenSilent_noclick_core.shared.heist_state")
local blip_teleport = require("ShillenSilent_noclick_core.shared.blip_teleport")
local solo_launch_runtime = require("ShillenSilent_noclick_core.runtime.solo_launch")

local state = core.state
local run_guarded_job = core.run_guarded_job
local GetMP = presets.GetMP
local SAFE_PAYOUT_TARGETS = presets.SAFE_PAYOUT_TARGETS
local hp_set_stat_for_all_characters = presets.hp_set_stat_for_all_characters
local hp_set_uniform_cuts = presets.hp_set_uniform_cuts
local hp_clamp_doomsday_cut_percent = presets.hp_clamp_doomsday_cut_percent
local APARTMENT_CUT_PRESET_OPTIONS = presets.APARTMENT_CUT_PRESET_OPTIONS
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
local apply_doomsday_cuts

local doomsday_max_payout_cache = {
	heist = nil,
	difficulty = nil,
	cut = nil,
}

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
	local difficulty = safe_access.get_global_int(4718592 + 3538, 1) or 1
	if difficulty == 0 then
		difficulty = 1
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

	local payout_by_heist = payouts[heist]
	if not payout_by_heist then
		return nil, heist, difficulty
	end
	local payout = payout_by_heist[difficulty]
	if not payout then
		return nil, heist, difficulty
	end
	local cut = math.floor(SAFE_PAYOUT_TARGETS.doomsday / (payout / 100))
	return hp_clamp_doomsday_cut_percent(cut), heist, difficulty
end

local function doomsday_refresh_max_payout(force_update, apply_now)
	if not doomsday_flags.max_payout_enabled then
		doomsday_max_payout_cache.heist = nil
		doomsday_max_payout_cache.difficulty = nil
		doomsday_max_payout_cache.cut = nil
		return false
	end

	local cut, heist, difficulty = hp_get_doomsday_max_payout_cut()
	if not cut then
		return false
	end

	local changed = force_update
		or doomsday_max_payout_cache.heist ~= heist
		or doomsday_max_payout_cache.difficulty ~= difficulty
		or doomsday_max_payout_cache.cut ~= cut

	if changed then
		hp_set_uniform_cuts(
			DoomsdayCutsValues,
			{ "player1", "player2", "player3", "player4" },
			{ doomsday_refs.p1_slider, doomsday_refs.p2_slider, doomsday_refs.p3_slider, doomsday_refs.p4_slider },
			cut
		)

		if apply_now then
			apply_doomsday_cuts()
		end

		doomsday_max_payout_cache.heist = heist
		doomsday_max_payout_cache.difficulty = difficulty
		doomsday_max_payout_cache.cut = cut
	end

	return changed
end

apply_doomsday_cuts = function(cuts)
	if type(cuts) == "table" then
		DoomsdayCutsValues.player1 = hp_clamp_doomsday_cut_percent(cuts[1] or DoomsdayCutsValues.player1)
		DoomsdayCutsValues.player2 = hp_clamp_doomsday_cut_percent(cuts[2] or DoomsdayCutsValues.player2)
		DoomsdayCutsValues.player3 = hp_clamp_doomsday_cut_percent(cuts[3] or DoomsdayCutsValues.player3)
		DoomsdayCutsValues.player4 = hp_clamp_doomsday_cut_percent(cuts[4] or DoomsdayCutsValues.player4)
	end

	if doomsday_flags.max_payout_enabled then
		local max_cut = hp_get_doomsday_max_payout_cut()
		if max_cut then
			hp_set_uniform_cuts(
				DoomsdayCutsValues,
				{ "player1", "player2", "player3", "player4" },
				{ doomsday_refs.p1_slider, doomsday_refs.p2_slider, doomsday_refs.p3_slider, doomsday_refs.p4_slider },
				max_cut
			)
		end
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
		selected_cut = hp_get_doomsday_max_payout_cut() or selected_cut
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
		doomsday_refresh_max_payout(true, false)
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

local function bind_doomsday_callbacks()
	doomsday_callbacks.apply_cuts = apply_doomsday_cuts
	doomsday_callbacks.set_max_payout = doomsday_set_max_payout
	doomsday_callbacks.refresh_max_payout = doomsday_refresh_max_payout
	doomsday_callbacks.apply_cut_preset = apply_selected_doomsday_cut_preset
	doomsday_callbacks.set_selected_act = doomsday_set_selected_act
end

bind_doomsday_callbacks()
if doomsday_flags.max_payout_enabled then
	doomsday_refresh_max_payout(true, false)
end

local doomsday_module = {
	DoomsdayConfig = DoomsdayConfig,
	DoomsdayCutsValues = DoomsdayCutsValues,
	doomsday_flags = doomsday_flags,
	doomsday_cut_enabled = doomsday_cut_enabled,
	doomsday_refs = doomsday_refs,
	DOOMSDAY_ACT_OPTIONS = DOOMSDAY_ACT_OPTIONS,
	doomsday_reload_board = doomsday_reload_board,
	doomsday_set_selected_act = doomsday_set_selected_act,
	doomsday_complete_preps = doomsday_complete_preps,
	doomsday_reset_progress = doomsday_reset_progress,
	doomsday_reset_preps = doomsday_reset_preps,
	doomsday_force_ready = doomsday_force_ready,
	doomsday_teleport_to_entrance = doomsday_teleport_to_entrance,
	doomsday_teleport_to_screen = doomsday_teleport_to_screen,
	hp_get_doomsday_max_payout_cut = hp_get_doomsday_max_payout_cut,
	doomsday_refresh_max_payout = doomsday_refresh_max_payout,
	apply_doomsday_cuts = apply_doomsday_cuts,
	apply_selected_doomsday_cut_preset = apply_selected_doomsday_cut_preset,
	doomsday_set_max_payout = doomsday_set_max_payout,
	doomsday_data_hack = doomsday_data_hack,
	doomsday_doomsday_hack = doomsday_doomsday_hack,
	doomsday_instant_finish_new = doomsday_instant_finish_new,
	doomsday_manual_launch_reset = doomsday_manual_launch_reset,
}

return doomsday_module
