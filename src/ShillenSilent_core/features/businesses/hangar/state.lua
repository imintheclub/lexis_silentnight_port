local data = require("ShillenSilent_core.features.businesses.hangar.data")

local state = {
	config = {
		location_index = 1,
	},
	fill = {
		active = false,
	},
}

function state.set_location_index(value)
	state.config.location_index = data.clamp_location_index(value)
end

function state.set_fill_active(enabled)
	state.fill.active = enabled == true
end

return state
