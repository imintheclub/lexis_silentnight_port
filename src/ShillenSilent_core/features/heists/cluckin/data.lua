local data = {}

data.feature_id = "cluckin"
data.label_key = "feature.cluckin.name"

data.values = {
	finale_progress = 31,
	reset_progress = 0,
	complete_bitset = -1,
	cash_take = 4000000,
	mission_cash_take = 999999,
	mission_status = 5,
}

data.flags = {
	mission_complete = 1 << 7,
	mission_win = (1 << 9) | (1 << 10) | (1 << 11) | (1 << 12) | (1 << 16),
}

data.natives = {
	stop_cutscene_immediately = 0xD220BDD222AC4A1E,
}

return data
