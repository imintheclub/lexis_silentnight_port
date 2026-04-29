local option_helpers = require("ShillenSilent_core.core.options")
local number_helpers = require("ShillenSilent_core.core.numbers")
local data = {}

data.payout = {
	default = 1000000,
	max = 2000000,
	step = 50000,
}

data.contracts = {
	{ name = "None", value = -1 },
	{ name = "Union Depository", value = 0 },
	{ name = "Superdollar Deal", value = 1 },
	{ name = "Bank Contract", value = 2 },
	{ name = "ECU Job", value = 3 },
	{ name = "Prison Contract", value = 4 },
	{ name = "Agency Deal", value = 5 },
	{ name = "Lost Contract", value = 6 },
	{ name = "Data Contract", value = 7 },
}

data.option_names = option_helpers.names

data.option_index_by_value = option_helpers.index_by_value

data.option_value_by_name = option_helpers.value_by_name

function data.clamp_payout(value)
	return number_helpers.clamp_int(value, 0, data.payout.max, data.payout.default)
end

return data
