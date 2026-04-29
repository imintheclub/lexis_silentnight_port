local data = require("ShillenSilent_core.features.businesses.moneyfronts.data")

local state = {
	config = {
		front_heat = {
			car_wash = data.heat.default,
			weed_shop = data.heat.default,
			heli_tours = data.heat.default,
		},
	},
	flags = {
		front_heat_lock = {
			car_wash = false,
			weed_shop = false,
			heli_tours = false,
		},
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

return state
