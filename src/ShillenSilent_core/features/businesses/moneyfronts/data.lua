local number_helpers = require("ShillenSilent_core.core.numbers")
local data = {
	feature_id = "moneyfronts",
}

data.locations = {
	{
		key = "car_wash",
		label_key = "moneyfronts.location.car_wash",
		heat_label_key = "moneyfronts.front.car_wash",
		x = -3.0,
		y = -1396.5,
		z = 29.3,
	},
	{
		key = "heli_tours",
		label_key = "moneyfronts.location.heli_tours",
		heat_label_key = "moneyfronts.front.heli_tours",
		x = -749.3,
		y = -1510.2,
		z = 5.0,
	},
	{
		key = "weed_shop",
		label_key = "moneyfronts.location.weed_shop",
		heat_label_key = "moneyfronts.front.weed_shop",
		x = -1162.9,
		y = -1566.8,
		z = 4.4,
	},
}

data.front_keys = { "car_wash", "weed_shop", "heli_tours" }

data.heat = {
	min = 0,
	max = 100,
	default = 0,
	step = 5,
	lock_threshold = 10,
}

function data.clamp_heat(value)
	return number_helpers.clamp_int(value, data.heat.min, data.heat.max, data.heat.default)
end

function data.location_by_key(key)
	for i = 1, #data.locations do
		if data.locations[i].key == key then
			return data.locations[i], i
		end
	end
	return nil
end

return data
