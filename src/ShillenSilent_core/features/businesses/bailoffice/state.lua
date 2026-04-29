local data = require("ShillenSilent_core.features.businesses.bailoffice.data")

local state = {
	config = {
		location_index = 1,
	},
}

function state.set_location_index(value)
	state.config.location_index = data.clamp_location_index(value)
end

return state
