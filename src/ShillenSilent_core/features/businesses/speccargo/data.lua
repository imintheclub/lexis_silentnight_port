local option_helpers = require("ShillenSilent_core.core.options")
local number_helpers = require("ShillenSilent_core.core.numbers")
local data = {
	feature_id = "speccargo",
}

data.locations = {
	{ id = 1, label_key = "speccargo.location.pacific_bait", x = 51.31, y = -2568.47, z = 6.00 },
	{ id = 2, label_key = "speccargo.location.white_widow", x = -1081.08, y = -1261.01, z = 5.65 },
	{ id = 3, label_key = "speccargo.location.celltowa", x = 898.48, y = -1031.88, z = 34.97 },
	{ id = 4, label_key = "speccargo.location.convenience_lockup", x = 249.25, y = -1955.65, z = 23.16 },
	{ id = 5, label_key = "speccargo.location.foreclosed_garage", x = -424.77, y = 184.15, z = 80.75 },
	{ id = 6, label_key = "speccargo.location.xero_gas", x = -1045.00, y = -2023.15, z = 13.16 },
	{ id = 7, label_key = "speccargo.location.derriere", x = -1269.29, y = -813.22, z = 17.11 },
	{ id = 8, label_key = "speccargo.location.bilgeco", x = -876.11, y = -2734.50, z = 13.84 },
	{ id = 9, label_key = "speccargo.location.pier_400", x = 272.41, y = -3015.27, z = 5.71 },
	{ id = 10, label_key = "speccargo.location.gee", x = 1563.83, y = -2135.11, z = 77.62 },
	{ id = 11, label_key = "speccargo.location.ls_marine", x = -308.77, y = -2698.39, z = 6.00 },
	{ id = 12, label_key = "speccargo.location.railyard", x = 503.74, y = -653.08, z = 24.75 },
	{ id = 13, label_key = "speccargo.location.fridgit", x = -528.07, y = -1782.70, z = 21.48 },
	{ id = 14, label_key = "speccargo.location.disused_factory", x = -328.01, y = -1354.76, z = 31.30 },
	{ id = 15, label_key = "speccargo.location.discount_retail", x = 349.90, y = 327.98, z = 104.30 },
	{ id = 16, label_key = "speccargo.location.logistics", x = 922.56, y = -1560.05, z = 30.76 },
	{ id = 17, label_key = "speccargo.location.darnell", x = 762.67, y = -909.19, z = 25.25 },
	{ id = 18, label_key = "speccargo.location.wholesale", x = 1041.06, y = -2172.65, z = 31.49 },
	{ id = 19, label_key = "speccargo.location.cypress", x = 1015.36, y = -2510.99, z = 28.30 },
	{ id = 20, label_key = "speccargo.location.west_vinewood", x = -245.65, y = 202.50, z = 83.79 },
	{ id = 21, label_key = "speccargo.location.old_power", x = 541.59, y = -1944.36, z = 24.99 },
	{ id = 22, label_key = "speccargo.location.walker_sons", x = 93.28, y = -2216.14, z = 6.03 },
}

data.warehouse_cap_by_id = {
	[1] = 16,
	[2] = 16,
	[3] = 16,
	[4] = 16,
	[5] = 16,
	[6] = 111,
	[7] = 42,
	[8] = 111,
	[9] = 16,
	[10] = 42,
	[11] = 42,
	[12] = 42,
	[13] = 42,
	[14] = 42,
	[15] = 42,
	[16] = 111,
	[17] = 111,
	[18] = 111,
	[19] = 111,
	[20] = 111,
	[21] = 42,
	[22] = 111,
}

function data.infer_warehouse_cap(warehouse_id, crates)
	local cap = data.warehouse_cap_by_id[warehouse_id]
	if cap then
		return cap
	end
	if crates > 42 then
		return 111
	end
	if crates > 16 then
		return 42
	end
	return 16
end

function data.clamp_location_index(value, count)
	local max_count = math.max(tonumber(count) or #data.locations, 1)
	return number_helpers.clamp_int(value, 1, max_count, 1)
end

function data.localized_locations(locations, t)
	local out = {}
	for i = 1, #(locations or {}) do
		local loc = locations[i]
		out[i] = { name = t(loc.label_key), value = i, x = loc.x, y = loc.y, z = loc.z }
	end
	return out
end

data.option_names = option_helpers.names

data.option_value_by_name = option_helpers.value_by_name

return data
