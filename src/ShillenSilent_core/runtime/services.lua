local jobs = require("ShillenSilent_core.core.jobs")
local preset_ui = require("ShillenSilent_core.presets.ui")

local runtime_services = {
	started_gen = nil,
}

function runtime_services.start()
	local my_gen = _G.ShillenSilent_Generation or 0
	if runtime_services.started_gen == my_gen then
		return false
	end
	runtime_services.started_gen = my_gen

	pcall(jobs.start)
	pcall(preset_ui.start_keyboard_watcher)

	return true
end

return runtime_services
