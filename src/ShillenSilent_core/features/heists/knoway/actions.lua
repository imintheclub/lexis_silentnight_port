local jobs = require("ShillenSilent_core.core.jobs")
local safe_access = require("ShillenSilent_core.core.safe_access")
local notify_core = require("ShillenSilent_core.core.notify")
local offsets = require("ShillenSilent_core.data.offsets.current")
local data = require("ShillenSilent_core.features.heists.knoway.data")
local native = require("natives")

local run_guarded_job = jobs.run_guarded_job

local actions = {}

local function config()
	return offsets[data.feature_id] or {}
end

local push = notify_core.feature(data.label_key)

local function apply_script_local(script_name, offset, value)
	if not safe_access.is_script_running(script_name) then
		return false, true
	end
	return true, safe_access.set_local_int(script_name, offset, value)
end

local function apply_hack_completions(cfg)
	local action_taken = false
	local writes_ok = true

	local circuit = cfg.hacks and cfg.hacks.circuit or {}
	local circuit_running, circuit_ok =
		apply_script_local(circuit.script, circuit.result_offset, data.values.circuit_hack_complete)
	action_taken = action_taken or circuit_running
	writes_ok = writes_ok and circuit_ok

	local word = cfg.hacks and cfg.hacks.word or {}
	local word_running, word_ok = apply_script_local(word.script, word.result_offset, data.values.word_hack_complete)
	action_taken = action_taken or word_running
	writes_ok = writes_ok and word_ok

	return action_taken, writes_ok
end

local function apply_mission_controller_finish(cfg)
	local finish = cfg.finish or {}
	local script_name = finish.script
	if not safe_access.is_script_running(script_name) then
		return false, true
	end

	local base = math.floor(tonumber(finish.base) or 0)
	local ok1 = safe_access.set_local_int(script_name, base + finish.cash_take_offset_1, data.values.mission_cash_take)
	local ok2 = safe_access.set_local_int(script_name, base + finish.cash_take_offset_2, data.values.mission_cash_take)
	local ok3 = safe_access.set_local_int(script_name, base + finish.status_offset, data.values.mission_status)

	local flags_offset = base + finish.flags_offset
	local flags = safe_access.get_local_int(script_name, flags_offset, 0) | data.flags.mission_complete
	local ok4 = safe_access.set_local_int(script_name, flags_offset, flags)

	local win_flags_offset = base + finish.win_flags_offset
	local current = safe_access.get_local_int(script_name, win_flags_offset, 0)
	local ok5 = safe_access.set_local_int(script_name, win_flags_offset, current | data.flags.mission_win)

	return true, ok1 and ok2 and ok3 and ok4 and ok5
end

function actions.instant_finish()
	return run_guarded_job("knoway_instant_finish", function()
		local cfg = config()
		local hack_taken, hack_ok = apply_hack_completions(cfg)
		local finish_taken, finish_ok = apply_mission_controller_finish(cfg)
		local action_taken = hack_taken or finish_taken
		local writes_ok = hack_ok and finish_ok

		if not action_taken then
			push("knoway.notify.finish_no_script", 2200)
		elseif writes_ok then
			push("knoway.notify.finish_ok", 2000)
		else
			push("knoway.notify.finish_failed", 2200)
		end
	end, function()
		push("knoway.notify.finish_running", 1500)
	end)
end

function actions.skip_cutscene()
	local ok = pcall(function()
		native.stop_cutscene_immediately()
	end)
	push(ok and "knoway.notify.cutscene_ok" or "knoway.notify.cutscene_failed", 2000)
	return ok
end

return actions
