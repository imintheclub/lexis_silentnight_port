local option_helpers = require("ShillenSilent_core.core.options")
local number_helpers = require("ShillenSilent_core.core.numbers")
local data = {
	feature_id = "hangar",
}

data.locations = {
	{ id = 1, label_key = "hangar.location.lsia_a17", x = -1266.0, y = -3014.0, z = 13.0 },
	{ id = 2, label_key = "hangar.location.lsia_1", x = -1143.0, y = -2867.0, z = 13.0 },
	{ id = 3, label_key = "hangar.location.zancudo_a2", x = -2107.0, y = 3290.0, z = 32.0 },
	{ id = 4, label_key = "hangar.location.zancudo_3497", x = -2023.0, y = 3195.0, z = 32.0 },
	{ id = 5, label_key = "hangar.location.zancudo_3499", x = -1889.0, y = 2979.0, z = 32.0 },
}

function data.clamp_location_index(value)
	return number_helpers.clamp_int(value, 1, #data.locations, 1)
end

function data.location_by_id(id)
	local target = tonumber(id)
	if not target then
		return nil
	end
	for i = 1, #data.locations do
		if data.locations[i].id == target then
			return data.locations[i], i
		end
	end
	return nil
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
