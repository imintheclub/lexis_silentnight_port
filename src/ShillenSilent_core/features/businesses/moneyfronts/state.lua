local data = require("ShillenSilent_core.features.businesses.moneyfronts.data")

local state = {
	config = {
		front_heat = {
			car_wash = data.heat.default,
			weed_shop = data.heat.default,
			heli_tours = data.heat.default,
		},
		overall_heat = data.heat.default,
	},
	flags = {
		front_heat_lock = {
			car_wash = false,
			weed_shop = false,
			heli_tours = false,
		},
		overall_heat_lock = false,
	},
}

function state.set_front_heat_value(key, value)
	if state.config.front_heat[key] ~= nil then
		state.config.front_heat[key] = data.clamp_heat(value)
	end
end

function state.set_front_heat_lock_active(key, enabled)
	if state.flags.front_heat_lock[key] ~= nil then
		state.flags.front_heat_lock[key] = enabled == true
	end
end

function state.set_overall_heat_value(value)
	state.config.overall_heat = data.clamp_heat(value)
end

function state.set_overall_heat_lock_active(enabled)
	state.flags.overall_heat_lock = enabled == true
end

return state
