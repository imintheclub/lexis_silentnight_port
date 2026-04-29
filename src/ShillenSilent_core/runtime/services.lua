local jobs = require("ShillenSilent_core.core.jobs")

local runtime_services = {
	started = false,
}

function runtime_services.start()
	if runtime_services.started then
		return false
	end
	runtime_services.started = true

	pcall(jobs.start)

	return true
end

return runtime_services
