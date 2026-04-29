local data = require("ShillenSilent_core.features.businesses.speccargo.data")

local state = {
	config = {
		location_index = 1,
	},
	fill = {
		active = false,
	},
	protections = {
		raids_default = nil,
		raids_active = false,
		reminders_default = nil,
		reminders_active = false,
	},
}

function state.set_location_index(value, count)
	state.config.location_index = data.clamp_location_index(value, count)
end

function state.set_fill_active(enabled)
	state.fill.active = enabled == true
end

function state.set_raids_active(enabled)
	state.protections.raids_active = enabled == true
end

function state.set_reminders_active(enabled)
	state.protections.reminders_active = enabled == true
end

return state
