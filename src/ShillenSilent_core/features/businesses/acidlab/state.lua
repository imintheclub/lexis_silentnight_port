local data = require("ShillenSilent_core.features.businesses.acidlab.data")

local state = {
	fast_production = {
		active = false,
		status = data.status.stopped,
	},
}

function state.set_fast_production(enabled)
	state.fast_production.active = enabled == true
	state.fast_production.status = state.fast_production.active and data.status.running or data.status.stopped
end

function state.set_fast_status(status)
	state.fast_production.status = data.normalize_status(status)
end

return state
