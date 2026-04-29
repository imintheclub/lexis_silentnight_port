local data = {}

data.feature_id = "knoway"
data.label_key = "feature.knoway.name"

data.values = {
	circuit_hack_complete = 2,
	word_hack_complete = 5,
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
