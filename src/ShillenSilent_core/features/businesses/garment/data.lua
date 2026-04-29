local option_helpers = require("ShillenSilent_core.core.options")
local number_helpers = require("ShillenSilent_core.core.numbers")
local data = {
	feature_id = "garment",
}

data.locations = {
	{ label_key = "garment.location.entrance", x = -770.8, y = -102.0, z = 37.0 },
}

function data.clamp_location_index(value)
	return number_helpers.clamp_int(value, 1, #data.locations, 1)
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
