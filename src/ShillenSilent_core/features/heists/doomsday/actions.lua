-- luacheck: globals invoker util
local jobs = require("ShillenSilent_core.core.jobs")
local safe_access = require("ShillenSilent_core.core.safe_access")
local heist_cuts = require("ShillenSilent_core.core.heist_cuts")
local notify_core = require("ShillenSilent_core.core.notify")
local i18n = require("ShillenSilent_core.i18n")
local offsets = require("ShillenSilent_core.data.offsets.resolver")
local data = require("ShillenSilent_core.features.heists.doomsday.data")
local state = require("ShillenSilent_core.features.heists.doomsday.state")
local blip_teleport = require("ShillenSilent_core.shared.blip_teleport")
local solo_launch_runtime = require("ShillenSilent_core.runtime.solo_launch")

local core_state = require("ShillenSilent_core.shared.runtime_state")
local run_guarded_job = jobs.run_guarded_job
local teleport_to_blip_with_job = blip_teleport.teleport_to_blip_with_job

local actions = {}

local function config()
	return offsets.feature(data.feature_id)
end

local t = i18n.t

local push = notify_core.feature(data.label_key)

function actions.reload_board(show_missing_notice)
	local cfg = config()
	local planning = cfg.scripts and cfg.scripts.planning
	if planning and safe_access.is_script_running(planning) then
		return safe_access.set_local_int(planning, cfg.planning.reload_offset, data.values.board_reload)
	end

	if show_missing_notice then
		push("doomsday.notify.board_inactive", 2000)
	end
	return false
end

function actions.set_selected_act(act, silent)
	local previous = state.config.act
	local selected = state.set_act(act)
	if not data.act_presets[selected] then
		return false
	end

	if not silent and previous ~= selected then
		local option = data.act_options[state.act_index()]
		push("doomsday.notify.act_selected", 2000, { act = t(option.label_key) })
	end

	if state.flags.max_payout_enabled then
		actions.refresh_max_payout(true)
	end
	return true
end

function actions.complete_preps(act)
	if not actions.set_selected_act(act or state.config.act, true) then
		push("doomsday.notify.invalid_act", 2000)
		return false
	end

	local cfg = config()
	local stats = cfg.stats or {}
	local selected = data.act_presets[state.config.act]
	local ok1 = safe_access.set_stat_for_all_characters(stats.flow_mission_prog, selected.flow)
	local ok2 = safe_access.set_stat_for_all_characters(stats.heist_status, selected.status)
	local ok3 = safe_access.set_stat_for_all_characters(stats.flow_notifications, data.values.flow_notifications)
	actions.reload_board(false)

	local ok = ok1 and ok2 and ok3
	push(ok and "doomsday.notify.preps_ok" or "doomsday.notify.preps_failed", 2000)
	return ok
end

function actions.reset_progress()
	local cfg = config()
	local stats = cfg.stats or {}
	local ok1 = safe_access.set_stat_for_all_characters(stats.flow_mission_prog, data.values.reset_act_flow)
	local ok2 = safe_access.set_stat_for_all_characters(stats.heist_status, data.values.reset_status)
	local ok3 = safe_access.set_stat_for_all_characters(stats.flow_notifications, data.values.flow_notifications)
	actions.reload_board(false)

	local ok = ok1 and ok2 and ok3
	push(ok and "doomsday.notify.reset_ok" or "doomsday.notify.reset_failed", 2000)
	return ok
end

function actions.reset_preps()
	local cfg = config()
	local stats = cfg.stats or {}
	local ok1 = safe_access.set_stat_for_all_characters(stats.flow_mission_prog, data.values.reset_preps_flow)
	local ok2 = safe_access.set_stat_for_all_characters(stats.heist_status, data.values.reset_status)
	local ok3 = safe_access.set_stat_for_all_characters(stats.flow_notifications, data.values.reset_preps_notifications)
	actions.reload_board(false)

	local ok = ok1 and ok2 and ok3
	push(ok and "doomsday.notify.reset_preps_ok" or "doomsday.notify.reset_preps_failed", 2000)
	return ok
end

function actions.force_ready()
	return run_guarded_job("doomsday_force_ready", function()
		local cfg = config()
		safe_access.force_host(cfg.scripts and cfg.scripts.mission_controller)
		util.yield(1000)

		local ready = cfg.globals and cfg.globals.ready_players or {}
		local ok = true
		for i = 1, #ready do
			ok = safe_access.set_global_int(ready[i], data.values.force_ready) and ok
		end

		push(ok and "doomsday.notify.force_ready_ok" or "doomsday.notify.force_ready_failed", 2000)
	end, function()
		push("doomsday.notify.force_ready_running", 1500)
	end)
end

function actions.teleport_to_entrance()
	local cfg = config()
	return teleport_to_blip_with_job(
		cfg.blips.facility,
		t(data.label_key),
		t("doomsday.notify.teleported_entrance"),
		t("doomsday.notify.entrance_missing"),
		{ relay_if_interior = true }
	)
end

function actions.teleport_to_screen()
	local cfg = config()
	if not safe_access.is_script_running(cfg.scripts.interior) then
		push("doomsday.notify.must_be_inside", 2200)
		return false
	end

	return teleport_to_blip_with_job(
		cfg.blips.heist_board,
		t(data.label_key),
		t("doomsday.notify.teleported_screen"),
		t("doomsday.notify.screen_missing"),
		{ heading = cfg.screen.heading }
	)
end

function actions.get_max_payout_cut()
	local cfg = config()
	local difficulty = safe_access.get_global_int(cfg.globals.difficulty, 1) or 1
	if difficulty == 0 then
		difficulty = 1
	end
	if difficulty < 1 then
		difficulty = 1
	end
	if difficulty > 2 then
		difficulty = 2
	end

	local heist = safe_access.get_active_mp_stat_int(cfg.stats.flow_mission_prog, nil)
	if not data.act_presets[state.config.act] then
		state.set_act(1)
	end
	if not cfg.payouts[heist] then
		local act_preset = data.act_presets[state.config.act]
		heist = act_preset and act_preset.flow or heist
	end

	local payout_by_heist = cfg.payouts[heist]
	if not payout_by_heist then
		return nil, heist, difficulty
	end

	local payout = payout_by_heist[difficulty]
	if not payout then
		return nil, heist, difficulty
	end

	local cut = math.floor((data.safe_payout_target * 100) / payout)
	return data.clamp_cut(cut), heist, difficulty
end

function actions.refresh_max_payout(force_update)
	if not state.flags.max_payout_enabled then
		state.reset_max_payout_cache()
		return false
	end

	local cut, heist, difficulty = actions.get_max_payout_cut()
	if not cut then
		return false
	end

	local cache = state.runtime.max_payout_cache
	local changed = force_update or cache.heist ~= heist or cache.difficulty ~= difficulty or cache.cut ~= cut
	if changed then
		state.set_uniform_cuts(cut)
		cache.heist = heist
		cache.difficulty = difficulty
		cache.cut = cut
	end
	return changed
end

function actions.apply_cuts(cuts)
	if type(cuts) == "table" then
		for i = 1, #data.player_keys do
			local key = data.player_keys[i]
			state.set_cut(key, cuts[i] or state.cuts[key])
		end
	end

	if state.flags.max_payout_enabled then
		actions.refresh_max_payout(true)
	end

	local cfg = config()
	local cut_globals = cfg.globals and cfg.globals.cuts or {}
	local ok = heist_cuts.write_player_globals({
		player_keys = data.player_keys,
		offsets = cut_globals,
		cuts = state.cuts,
		enabled = state.cut_enabled,
		clamp = data.clamp_cut,
	})

	push(ok and "doomsday.notify.cuts_ok" or "doomsday.notify.cuts_failed", ok and 2000 or 2200)
	return ok
end

function actions.apply_selected_cut_preset(silent)
	local selected = data.cut_preset_options[state.flags.cut_preset_index]
		or data.cut_preset_options[#data.cut_preset_options]
	local selected_cut = selected and selected.value or data.cuts.defaults.player1
	if state.flags.max_payout_enabled then
		selected_cut = actions.get_max_payout_cut() or selected_cut
	end

	state.set_uniform_cuts(selected_cut)
	if not silent then
		push("doomsday.notify.cut_preset_ok", 2000)
	end
	return selected_cut
end

function actions.set_max_payout(enable, silent)
	local enabled = enable and true or false
	local changed = state.flags.max_payout_enabled ~= enabled
	state.set_max_payout(enabled)

	if enabled then
		actions.refresh_max_payout(true)
	end

	if changed and not silent then
		push(enabled and "doomsday.notify.max_payout_on" or "doomsday.notify.max_payout_off", 2000)
	end
	return true
end

function actions.data_hack()
	local cfg = config()
	local hack = cfg.hacks and cfg.hacks.data
	local script_name = cfg.scripts and cfg.scripts.mission_controller
	if script_name and safe_access.is_script_running(script_name) and hack then
		local ok = safe_access.set_local_int(script_name, hack.offset, data.values.data_hack_complete)
		push(ok and "doomsday.notify.data_hack_ok" or "doomsday.notify.data_hack_failed", 2000)
		return ok
	end

	push("doomsday.notify.hack_inactive", 2000)
	return false
end

function actions.doomsday_hack()
	local cfg = config()
	local hack = cfg.hacks and cfg.hacks.doomsday
	local script_name = cfg.scripts and cfg.scripts.mission_controller
	if script_name and safe_access.is_script_running(script_name) and hack then
		local ok = safe_access.set_local_int(script_name, hack.offset, data.values.doomsday_hack_complete)
		push(ok and "doomsday.notify.doomsday_hack_ok" or "doomsday.notify.doomsday_hack_failed", 2000)
		return ok
	end

	push("doomsday.notify.hack_inactive", 2000)
	return false
end

local function running_finish_controller(cfg)
	local controllers = cfg.finish and cfg.finish.controllers or {}
	for script_name in pairs(controllers) do
		if safe_access.is_script_running(script_name) then
			return script_name, controllers[script_name]
		end
	end
	return nil, nil
end

function actions.instant_finish_new()
	return run_guarded_job("doomsday_instant_finish_new", function()
		local cfg = config()
		local script_name, finish = running_finish_controller(cfg)
		if not script_name then
			push("doomsday.notify.no_controller", 2000)
			return
		end

		if not safe_access.force_host(script_name) then
			push("doomsday.notify.host_failed", 2200)
			return
		end
		util.yield(1000)

		local bits = safe_access.get_local_int(script_name, finish.flags_offset, 0) | data.flags.finish_win
		local ok1 = safe_access.set_local_int(script_name, finish.status_offset, data.values.finish_status)
		local ok2 = safe_access.set_local_int(script_name, finish.cash_take_offset, data.values.finish_cash_take)
		local ok3 = safe_access.set_local_int(script_name, finish.flags_offset, bits)

		push((ok1 and ok2 and ok3) and "doomsday.notify.finish_ok" or "doomsday.notify.finish_failed", 2200)
	end, function()
		push("doomsday.notify.finish_running", 1500)
	end)
end

function actions.manual_launch_reset()
	return run_guarded_job("doomsday_manual_launch_reset", function()
		core_state.solo_launch.doomsday = false
		local reset_fn = solo_launch_runtime.manual_reset_doomsday_launch
		if type(reset_fn) ~= "function" then
			reset_fn = solo_launch_runtime.solo_launch_reset_doomsday
		end

		local ok = false
		if type(reset_fn) == "function" then
			ok = reset_fn() and true or false
		end

		push(ok and "doomsday.notify.launch_reset_ok" or "doomsday.notify.launch_reset_failed", 2000)
	end, function()
		push("doomsday.notify.launch_reset_running", 1500)
	end)
end

function actions.maintain_solo_launch()
	local enabled = core_state.solo_launch.doomsday and true or false
	local was_enabled = core_state.solo_launch_prev.doomsday and true or false

	if not enabled and was_enabled then
		pcall(solo_launch_runtime.solo_launch_reset_doomsday)
	end

	core_state.solo_launch_prev.doomsday = enabled
	if enabled and solo_launch_runtime.solo_launch_generic then
		return solo_launch_runtime.solo_launch_generic()
	end
	return true
end

function actions.skip_cutscene()
	local ok = pcall(function()
		if invoker and invoker.call then
			invoker.call(data.natives.stop_cutscene_immediately)
		else
			error("invoker unavailable")
		end
	end)
	push(ok and "doomsday.notify.cutscene_ok" or "doomsday.notify.cutscene_failed", 2000)
	return ok
end

actions.doomsday_reload_board = actions.reload_board
actions.doomsday_set_selected_act = actions.set_selected_act
actions.doomsday_complete_preps = actions.complete_preps
actions.doomsday_reset_progress = actions.reset_progress
actions.doomsday_reset_preps = actions.reset_preps
actions.doomsday_force_ready = actions.force_ready
actions.doomsday_teleport_to_entrance = actions.teleport_to_entrance
actions.doomsday_teleport_to_screen = actions.teleport_to_screen
actions.hp_get_doomsday_max_payout_cut = actions.get_max_payout_cut
actions.doomsday_refresh_max_payout = actions.refresh_max_payout
actions.apply_doomsday_cuts = actions.apply_cuts
actions.apply_selected_doomsday_cut_preset = actions.apply_selected_cut_preset
actions.doomsday_set_max_payout = actions.set_max_payout
actions.doomsday_data_hack = actions.data_hack
actions.doomsday_doomsday_hack = actions.doomsday_hack
actions.doomsday_instant_finish_new = actions.instant_finish_new
actions.doomsday_manual_launch_reset = actions.manual_launch_reset

return actions
