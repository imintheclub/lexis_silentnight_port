local option_helpers = require("ShillenSilent_core.core.options")
local number_helpers = require("ShillenSilent_core.core.numbers")
local data = {
	feature_id = "moneyfronts",
}

data.locations = {
	{
		key = "car_wash",
		label_key = "moneyfronts.location.car_wash",
		x = -3.0,
		y = -1396.5,
		z = 29.3,
	},
	{
		key = "heli_tours",
		label_key = "moneyfronts.location.heli_tours",
		x = -749.3,
		y = -1510.2,
		z = 5.0,
	},
	{
		key = "weed_shop",
		label_key = "moneyfronts.location.weed_shop",
		x = -1162.9,
		y = -1566.8,
		z = 4.4,
	},
}

data.heat = {
	min = 0,
	max = 100,
	default = 0,
	step = 5,
	lock_threshold = 10,
}

function data.clamp_location_index(value)
	return number_helpers.clamp_int(value, 1, #data.locations, 1)
end

function data.clamp_heat(value)
	return number_helpers.clamp_int(value, data.heat.min, data.heat.max, data.heat.default)
end

function data.localized_locations(t)
	local out = {}
	for i = 1, #data.locations do
		local loc = data.locations[i]
		out[i] = {
			name = t(loc.label_key),
			value = i,
			x = loc.x,
			y = loc.y,
			z = loc.z,
		}
	end
	return out
end

data.option_names = option_helpers.names

data.option_value_by_name = option_helpers.value_by_name

return data
