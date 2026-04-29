-- luacheck: globals invoker
local jobs = require("ShillenSilent_core.core.jobs")
local safe_access = require("ShillenSilent_core.core.safe_access")
local notify_core = require("ShillenSilent_core.core.notify")
local offsets = require("ShillenSilent_core.data.offsets.current")
local data = require("ShillenSilent_core.features.heists.cluckin.data")

local run_guarded_job = jobs.run_guarded_job

local actions = {}

local function config()
	return offsets[data.feature_id] or {}
end

local push = notify_core.feature(data.label_key)

function actions.skip_to_finale()
	return run_guarded_job("cluckin_skip_to_finale", function()
		local cfg = config()
		local stats = cfg.stats or {}
		local ok = safe_access.set_stat_for_all_characters(stats.instance_progress, data.values.finale_progress)
		local completion_stats = stats.completion_bitsets or {}
		for i = 1, #completion_stats do
			ok = safe_access.set_stat_for_all_characters(completion_stats[i], data.values.complete_bitset) and ok
		end
		push(ok and "cluckin.notify.skip_finale_ok" or "cluckin.notify.skip_finale_failed", 2000)
	end, function()
		push("cluckin.notify.action_running", 1500)
	end)
end

function actions.remove_cooldown()
	return run_guarded_job("cluckin_remove_cooldown", function()
		local cfg = config()
		local ok =
			safe_access.set_stat_for_all_characters(cfg.stats and cfg.stats.cooldown, data.values.complete_bitset)
		push(ok and "cluckin.notify.cooldown_ok" or "cluckin.notify.cooldown_failed", 2000)
	end, function()
		push("cluckin.notify.action_running", 1500)
	end)
end

function actions.reset_progress()
	return run_guarded_job("cluckin_reset_progress", function()
		local cfg = config()
		local ok = safe_access.set_stat_for_all_characters(
			cfg.stats and cfg.stats.instance_progress,
			data.values.reset_progress
		)
		push(ok and "cluckin.notify.reset_ok" or "cluckin.notify.reset_failed", 2000)
	end, function()
		push("cluckin.notify.action_running", 1500)
	end)
end

local function apply_mission_controller_finish(cfg)
	local finish = cfg.finish or {}
	local script_name = finish.script
	if not script_name or not safe_access.is_script_running(script_name) then
		return false, true
	end

	local base = math.floor(tonumber(finish.base) or 0)
	local ok1 = safe_access.set_local_int(script_name, finish.cash_take_offset, data.values.cash_take)
	local ok2 =
		safe_access.set_local_int(script_name, base + finish.mission_cash_take_offset, data.values.mission_cash_take)
	local ok3 = safe_access.set_local_int(script_name, base + finish.status_offset, data.values.mission_status)

	local flags = safe_access.get_local_int(script_name, finish.flags_offset, 0) | data.flags.mission_complete
	local ok4 = safe_access.set_local_int(script_name, finish.flags_offset, flags)

	local win_flags_offset = base + finish.win_flags_offset
	local current = safe_access.get_local_int(script_name, win_flags_offset, 0)
	local ok5 = safe_access.set_local_int(script_name, win_flags_offset, current | data.flags.mission_win)

	return true, ok1 and ok2 and ok3 and ok4 and ok5
end

function actions.instant_finish()
	return run_guarded_job("cluckin_instant_finish", function()
		local action_taken, writes_ok = apply_mission_controller_finish(config())
		if not action_taken then
			push("cluckin.notify.finish_no_script", 2000)
		elseif writes_ok then
			push("cluckin.notify.finish_ok", 2000)
		else
			push("cluckin.notify.finish_failed", 2200)
		end
	end, function()
		push("cluckin.notify.finish_running", 1500)
	end)
end

function actions.skip_cutscene()
	local ok = pcall(function()
		if invoker and invoker.call then
			invoker.call(data.natives.stop_cutscene_immediately)
		else
			error("invoker unavailable")
		end
	end)
	push(ok and "cluckin.notify.cutscene_ok" or "cluckin.notify.cutscene_failed", 2000)
	return ok
end

actions.cluckin_skip_to_finale = actions.skip_to_finale
actions.cluckin_remove_cooldown = actions.remove_cooldown
actions.cluckin_reset_progress = actions.reset_progress
actions.cluckin_instant_finish = actions.instant_finish

return actions
