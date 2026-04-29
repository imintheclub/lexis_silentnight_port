local data = require("ShillenSilent_core.features.businesses.nightclub.data")

local state = {
	config = {
		location_index = 1,
		fast_prod_target = "all",
		popularity_editor_value = data.popularity.default,
	},
	fast_production = {
		active = false,
		status = data.status.stopped,
	},
	popularity = {
		lock_active = false,
	},
	protections = {
		raids_default = nil,
		raids_active = false,
		reminders_default = nil,
		reminders_active = false,
	},
}

function state.set_location_index(value)
	state.config.location_index = data.clamp_location_index(value)
end

function state.set_fast_prod_target(value)
	state.config.fast_prod_target = data.valid_fast_target(value)
end

function state.set_fast_production(enabled)
	state.fast_production.active = enabled == true
	state.fast_production.status = state.fast_production.active and data.status.running or data.status.stopped
end

function state.set_fast_status(status)
	state.fast_production.status = data.normalize_status(status)
end

function state.set_popularity_editor_value(value)
	state.config.popularity_editor_value = data.clamp_popularity(value)
end

function state.set_popularity_lock_active(enabled)
	state.popularity.lock_active = enabled == true
end

function state.set_raids_active(enabled)
	state.protections.raids_active = enabled == true
end

function state.set_reminders_active(enabled)
	state.protections.reminders_active = enabled == true
end

return state
