local data = require("ShillenSilent_core.features.businesses.moneyfronts.data")

local state = {
	config = {
		location_index = 1,
		heat_editor_value = data.heat.default,
	},
	flags = {
		heat_lock_active = false,
	},
}

function state.set_location_index(value)
	state.config.location_index = data.clamp_location_index(value)
end

function state.set_heat_editor_value(value)
	state.config.heat_editor_value = data.clamp_heat(value)
end

function state.set_heat_lock_active(enabled)
	state.flags.heat_lock_active = enabled == true
end

return state
