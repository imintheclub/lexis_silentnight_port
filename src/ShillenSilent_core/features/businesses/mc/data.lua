local data = {
	feature_id = "mc",
}

data.status = {
	stopped = "stopped",
	running = "running",
	no_owned = "no_owned",
	full = "full",
	not_owned = "not_owned",
}

-- MC sub-businesses. Runtime stat/blip identifiers are resolved through
-- data.offsets.current; this table only keeps labels and gameplay limits.
data.subs = {
	{ key = "meth", label_key = "mc.business.meth", cap = 20 },
	{ key = "weed", label_key = "mc.business.weed", cap = 80 },
	{ key = "cocaine", label_key = "mc.business.cocaine", cap = 10 },
	{
		key = "counterfeit",
		label_key = "mc.business.counterfeit",
		cap = 40,
	},
	{ key = "forgery", label_key = "mc.business.forgery", cap = 60 },
}

-- Coord-table fallback per sub, indexed by location tier (1..4).
-- Tier is derived from prop_id: math.floor((prop_id - 1) / 5) + 1.
data.locations = {
	meth = {
		{ x = -58.0, y = 6465.0, z = 31.0 },
		{ x = 1381.0, y = -2106.0, z = 52.0 },
		{ x = 1443.0, y = -1846.0, z = 52.0 },
		{ x = 1009.0, y = -3196.0, z = -38.0 },
	},
	weed = {
		{ x = 2861.0, y = 4555.0, z = 48.0 },
		{ x = 115.0, y = -2553.0, z = 6.0 },
		{ x = -53.0, y = 183.0, z = 72.0 },
		{ x = 712.0, y = 5895.0, z = 18.0 },
	},
	cocaine = {
		{ x = -153.0, y = 6435.0, z = 31.0 },
		{ x = 91.0, y = -2491.0, z = 6.0 },
		{ x = -1169.0, y = -287.0, z = 37.0 },
		{ x = 1088.0, y = -3187.0, z = -39.0 },
	},
	counterfeit = {
		{ x = -132.0, y = 6256.0, z = 31.0 },
		{ x = 853.0, y = -2336.0, z = 30.0 },
		{ x = -1109.0, y = -1361.0, z = 5.0 },
		{ x = 1163.0, y = 2712.0, z = 38.0 },
	},
	forgery = {
		{ x = -32.0, y = 6281.0, z = 31.0 },
		{ x = 111.0, y = -2528.0, z = 6.0 },
		{ x = 711.0, y = -921.0, z = 25.0 },
		{ x = 1910.0, y = 4773.0, z = 41.0 },
	},
}

-- Property IDs come in groups of 5 across 4 location tiers.
data.prop_id_to_key = {}
for n = 0, 3 do
	data.prop_id_to_key[1 + n * 5] = "meth"
	data.prop_id_to_key[2 + n * 5] = "weed"
	data.prop_id_to_key[3 + n * 5] = "cocaine"
	data.prop_id_to_key[4 + n * 5] = "counterfeit"
	data.prop_id_to_key[5 + n * 5] = "forgery"
end

data.sub_by_key = {}
for i = 1, #data.subs do
	data.sub_by_key[data.subs[i].key] = data.subs[i]
end

function data.find_sub(sub_key)
	return data.sub_by_key[sub_key]
end

function data.status_label_key(status)
	return "mc.status." .. tostring(status or data.status.stopped)
end

function data.normalize_status(status)
	local value = tostring(status or data.status.stopped)
	return data.status[value] or data.status.stopped
end

return data
