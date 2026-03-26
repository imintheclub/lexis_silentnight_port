local core = require("ShillenSilent_noclick_core.core.bootstrap")
local safe_access = require("ShillenSilent_noclick_core.core.safe_access")

local run_guarded_job = core.run_guarded_job

local MISSION_CONTROLLER_SCRIPT = "fm_mission_controller_2020"

local function apply_mission_controller_finish()
	if not safe_access.is_script_running(MISSION_CONTROLLER_SCRIPT) then
		return false
	end

	local base = 48794
	local ok1 = safe_access.set_local_int(MISSION_CONTROLLER_SCRIPT, base + 1777, 999999)
	local ok2 = safe_access.set_local_int(MISSION_CONTROLLER_SCRIPT, base + 1778, 999999)
	local ok3 = safe_access.set_local_int(MISSION_CONTROLLER_SCRIPT, base + 1062, 5)

	local flags = safe_access.get_local_int(MISSION_CONTROLLER_SCRIPT, 48794, 0) | (1 << 7)
	local ok4 = safe_access.set_local_int(MISSION_CONTROLLER_SCRIPT, 48794, flags)

	local win_flags = (1 << 9) | (1 << 10) | (1 << 11) | (1 << 12) | (1 << 16)
	local current = safe_access.get_local_int(MISSION_CONTROLLER_SCRIPT, base + 1, 0)
	local ok5 = safe_access.set_local_int(MISSION_CONTROLLER_SCRIPT, base + 1, current | win_flags)

	return ok1 and ok2 and ok3 and ok4 and ok5
end

local function knoway_instant_finish()
	return run_guarded_job("knoway_instant_finish", function()
		local action_taken = safe_access.is_script_running(MISSION_CONTROLLER_SCRIPT)
		local writes_ok = action_taken and apply_mission_controller_finish() or true

		if notify then
			if not action_taken then
				notify.push("KnoWay", "No supported script is running", 2200)
			elseif writes_ok then
				notify.push("KnoWay", "Instant finish triggered", 2000)
			else
				notify.push("KnoWay", "Instant finish write incomplete", 2200)
			end
		end
	end, function()
		if notify then
			notify.push("KnoWay", "Instant finish already running", 1500)
		end
	end)
end

local knoway_module = {
	knoway_instant_finish = knoway_instant_finish,
}

return knoway_module
