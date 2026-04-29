local option_helpers = require("ShillenSilent_core.core.options")
local number_helpers = require("ShillenSilent_core.core.numbers")
local data = {
	feature_id = "bunker",
}

data.status = {
	stopped = "stopped",
	running = "running",
	full = "full",
}

data.locations = {
	{ id = 21, label_key = "bunker.location.grand_senora_oilfields", x = 494.68, y = 3015.90, z = 41.04 },
	{ id = 22, label_key = "bunker.location.grand_senora_desert", x = 849.62, y = 3024.43, z = 41.27 },
	{ id = 23, label_key = "bunker.location.route_68", x = 40.42, y = 2929.00, z = 55.75 },
	{ id = 24, label_key = "bunker.location.farmhouse", x = 1571.95, y = 2224.60, z = 78.35 },
	{ id = 25, label_key = "bunker.location.smoke_tree_road", x = 2107.14, y = 3324.63, z = 45.37 },
	{ id = 26, label_key = "bunker.location.thomson_scrapyard", x = 2488.71, y = 3164.62, z = 49.08 },
	{ id = 27, label_key = "bunker.location.grapeseed", x = 1798.50, y = 4704.96, z = 39.99 },
	{ id = 28, label_key = "bunker.location.paleto_forest", x = -754.23, y = 5944.17, z = 19.84 },
	{ id = 29, label_key = "bunker.location.raton_canyon", x = -388.33, y = 4338.32, z = 56.10 },
	{ id = 30, label_key = "bunker.location.lago_zancudo", x = -3030.34, y = 3334.57, z = 10.11 },
	{ id = 31, label_key = "bunker.location.chumash", x = -3156.14, y = 1376.71, z = 17.07 },
}

function data.status_label_key(status)
	return "bunker.status." .. tostring(status or data.status.stopped)
end

function data.normalize_status(status)
	local value = tostring(status or data.status.stopped)
	return data.status[value] or data.status.stopped
end

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
