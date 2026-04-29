local option_helpers = require("ShillenSilent_core.core.options")
local number_helpers = require("ShillenSilent_core.core.numbers")
local data = {}

data.feature_id = "cayo"
data.label_key = "feature.cayo.name"
data.safe_payout_target = 2550000

data.value = {
	min = 0,
	max = 2550000,
	step = 50000,
}

data.cuts = {
	min = 0,
	max = 300,
	step = 5,
	defaults = {
		host = 100,
		player2 = 0,
		player3 = 0,
		player4 = 0,
	},
}

data.player_keys = { "host", "player2", "player3", "player4" }

data.difficulties = {
	{ label_key = "cayo.difficulty.normal", value = 126823 },
	{ label_key = "cayo.difficulty.hard", value = 131055 },
}

data.approaches = {
	{ label_key = "cayo.approach.kosatka", value = 65283 },
	{ label_key = "cayo.approach.alkonost", value = 65413 },
	{ label_key = "cayo.approach.velum", value = 65289 },
	{ label_key = "cayo.approach.annihilator", value = 65425 },
	{ label_key = "cayo.approach.patrol_boat", value = 65313 },
	{ label_key = "cayo.approach.longfin", value = 65345 },
	{ label_key = "cayo.approach.all", value = 65535 },
}

data.loadouts = {
	{ label_key = "cayo.loadout.aggressor", value = 1 },
	{ label_key = "cayo.loadout.conspirator", value = 2 },
	{ label_key = "cayo.loadout.crackshot", value = 3 },
	{ label_key = "cayo.loadout.saboteur", value = 4 },
	{ label_key = "cayo.loadout.marksman", value = 5 },
}

data.primary_targets = {
	{ label_key = "cayo.target.tequila", value = 0 },
	{ label_key = "cayo.target.ruby", value = 1 },
	{ label_key = "cayo.target.bonds", value = 2 },
	{ label_key = "cayo.target.diamond", value = 3 },
	{ label_key = "cayo.target.madrazo", value = 4 },
	{ label_key = "cayo.target.panther", value = 5 },
}

data.secondary_targets = {
	{ label_key = "cayo.secondary.none", value = "NONE" },
	{ label_key = "cayo.secondary.cash", value = "CASH" },
	{ label_key = "cayo.secondary.weed", value = "WEED" },
	{ label_key = "cayo.secondary.coke", value = "COKE" },
	{ label_key = "cayo.secondary.gold", value = "GOLD" },
}

data.compound_amounts = {
	{ label_key = "cayo.amount.empty", value = 0 },
	{ label_key = "cayo.amount.full", value = 255 },
	{ name = "1", value = 128 },
	{ name = "2", value = 64 },
	{ name = "3", value = 196 },
	{ name = "4", value = 204 },
	{ name = "5", value = 220 },
	{ name = "6", value = 252 },
	{ name = "7", value = 253 },
}

data.island_amounts = {
	{ label_key = "cayo.amount.empty", value = 0 },
	{ label_key = "cayo.amount.full", value = 16777215 },
	{ name = "1", value = 8388608 },
	{ name = "2", value = 12582912 },
	{ name = "3", value = 12845056 },
	{ name = "4", value = 12976128 },
	{ name = "5", value = 13500416 },
	{ name = "6", value = 14548992 },
	{ name = "7", value = 16646144 },
	{ name = "8", value = 16711680 },
	{ name = "9", value = 16744448 },
	{ name = "10", value = 16760832 },
	{ name = "11", value = 16769024 },
	{ name = "12", value = 16769536 },
	{ name = "13", value = 16770560 },
	{ name = "14", value = 16770816 },
	{ name = "15", value = 16770880 },
	{ name = "16", value = 16771008 },
	{ name = "17", value = 16773056 },
	{ name = "18", value = 16777152 },
	{ name = "19", value = 16777184 },
	{ name = "20", value = 16777200 },
	{ name = "21", value = 16777202 },
	{ name = "22", value = 16777203 },
	{ name = "23", value = 16777211 },
}

data.arts_amounts = {
	{ label_key = "cayo.amount.empty", value = 0 },
	{ label_key = "cayo.amount.full", value = 127 },
	{ name = "1", value = 64 },
	{ name = "2", value = 96 },
	{ name = "3", value = 112 },
	{ name = "4", value = 120 },
	{ name = "5", value = 122 },
	{ name = "6", value = 126 },
}

data.default_values = {
	cash = 83250,
	weed = 135000,
	coke = 202500,
	gold = 333333,
	art = 180000,
}

data.tunable_defaults = {
	bag_max_capacity = 1800,
	pavel_cut = -0.02,
	fencing_fee = -0.1,
}

data.primary_target_payouts = {
	[0] = { 630000, 693000 },
	[1] = { 700000, 770000 },
	[2] = { 770000, 847000 },
	[3] = { 1300000, 1430000 },
	[4] = { 1100000, 1210000 },
	[5] = { 1900000, 2090000 },
}

data.cooldown_posix = {
	solo = 1659643454,
	team = 1659429119,
}

function data.localized_options(options, translate)
	local out = {}
	for i = 1, #options do
		local option = options[i]
		local label = option.name or option.label_key
		if option.label_key and type(translate) == "function" then
			label = translate(option.label_key)
		end
		out[i] = {
			name = label,
			label_key = option.label_key,
			value = option.value,
		}
	end
	return out
end

data.option_names = option_helpers.names

data.option_index_by_value = option_helpers.index_by_value

data.option_value_by_name = option_helpers.value_by_name

data.resolve_option_value = option_helpers.resolve_value

data.clamp_int = number_helpers.clamp_int

function data.clamp_value(value)
	return data.clamp_int(value, data.value.min, data.value.max, data.value.min)
end

function data.clamp_cut(value)
	return number_helpers.clamp_int(value, data.cuts.min, data.cuts.max, data.cuts.min)
end

return data
