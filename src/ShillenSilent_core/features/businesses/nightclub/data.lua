local option_helpers = require("ShillenSilent_core.core.options")
local number_helpers = require("ShillenSilent_core.core.numbers")
local data = {
	feature_id = "nightclub",
}

data.status = {
	stopped = "stopped",
	running = "running",
}

data.product_slots = {
	{ slot = 0, key = "cargo", label_key = "nightclub.product.cargo", cap = 50 },
	{ slot = 1, key = "weapons", label_key = "nightclub.product.weapons", cap = 100 },
	{ slot = 2, key = "coke", label_key = "nightclub.product.coke", cap = 10 },
	{ slot = 3, key = "meth", label_key = "nightclub.product.meth", cap = 20 },
	{ slot = 4, key = "weed", label_key = "nightclub.product.weed", cap = 80 },
	{ slot = 5, key = "docs", label_key = "nightclub.product.docs", cap = 60 },
	{ slot = 6, key = "cash", label_key = "nightclub.product.cash", cap = 40 },
}

data.fast_product_options = {
	{ label_key = "nightclub.product.all", value = "all" },
	{ label_key = "nightclub.product.cargo", value = "cargo" },
	{ label_key = "nightclub.product.weapons", value = "weapons" },
	{ label_key = "nightclub.product.coke", value = "coke" },
	{ label_key = "nightclub.product.meth", value = "meth" },
	{ label_key = "nightclub.product.weed", value = "weed" },
	{ label_key = "nightclub.product.docs", value = "docs" },
	{ label_key = "nightclub.product.cash", value = "cash" },
}

data.locations = {
	{ id = 1, label_key = "nightclub.location.downtown_vinewood", x = 15.0, y = 220.0, z = 107.0 },
	{ id = 2, label_key = "nightclub.location.west_vinewood", x = -565.0, y = 276.0, z = 83.0 },
	{ id = 3, label_key = "nightclub.location.strawberry", x = 97.0, y = -1292.0, z = 29.0 },
	{ id = 4, label_key = "nightclub.location.mission_row", x = 356.0, y = -1012.0, z = 29.0 },
	{ id = 5, label_key = "nightclub.location.la_mesa", x = 831.0, y = -1675.0, z = 29.0 },
	{ id = 6, label_key = "nightclub.location.cypress_flats", x = 728.0, y = -2165.0, z = 29.0 },
	{ id = 7, label_key = "nightclub.location.lsia", x = -993.0, y = -2535.0, z = 20.0 },
	{ id = 8, label_key = "nightclub.location.elysian_island", x = -146.0, y = -2640.0, z = 6.0 },
	{ id = 9, label_key = "nightclub.location.del_perro", x = -1389.0, y = -588.0, z = 30.0 },
	{ id = 10, label_key = "nightclub.location.vespucci_canals", x = -1172.0, y = -1152.0, z = 5.0 },
}

data.popularity = {
	min = 0,
	max = 1000,
	default = 1000,
	step = 10,
	lock_tolerance = 50,
}

function data.status_label_key(status)
	return "nightclub.status." .. tostring(status or data.status.stopped)
end

function data.normalize_status(status)
	local value = tostring(status or data.status.stopped)
	return data.status[value] or data.status.stopped
end

function data.valid_fast_target(value)
	local target = tostring(value or "all")
	for i = 1, #data.fast_product_options do
		if data.fast_product_options[i].value == target then
			return target
		end
	end
	return "all"
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

function data.clamp_popularity(value)
	return number_helpers.clamp_int(value, data.popularity.min, data.popularity.max, data.popularity.default)
end

function data.localized_options(options, t)
	local out = {}
	for i = 1, #options do
		local opt = options[i]
		out[i] = { name = t(opt.label_key), value = opt.value }
	end
	return out
end

function data.localized_locations(t)
	local out = {}
	for i = 1, #data.locations do
		local loc = data.locations[i]
		out[i] = { name = t(loc.label_key), value = i, x = loc.x, y = loc.y, z = loc.z }
	end
	return out
end

data.option_names = option_helpers.names

data.option_index_by_value = option_helpers.index_by_value

data.option_value_by_name = option_helpers.value_by_name

return data
