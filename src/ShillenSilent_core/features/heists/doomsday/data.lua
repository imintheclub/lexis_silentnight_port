local option_helpers = require("ShillenSilent_core.core.options")
local number_helpers = require("ShillenSilent_core.core.numbers")
local data = {}

data.feature_id = "doomsday"
data.label_key = "feature.doomsday.name"

data.safe_payout_target = 2550000

data.cuts = {
	min = 0,
	max = 999,
	step = 1,
	defaults = {
		player1 = 100,
		player2 = 0,
		player3 = 0,
		player4 = 0,
	},
}

data.player_keys = { "player1", "player2", "player3", "player4" }

data.act_options = {
	{ label_key = "doomsday.act.data_breaches", value = 1 },
	{ label_key = "doomsday.act.bogdan", value = 2 },
	{ label_key = "doomsday.act.scenario", value = 3 },
}

data.act_presets = {
	[1] = { flow = 503, status = -229383 },
	[2] = { flow = 240, status = -229378 },
	[3] = { flow = 16368, status = -229380 },
}

data.cut_preset_options = {
	{ label_key = "doomsday.cut_preset.all_0", value = 0 },
	{ label_key = "doomsday.cut_preset.all_25", value = 25 },
	{ label_key = "doomsday.cut_preset.all_85", value = 85 },
	{ label_key = "doomsday.cut_preset.all_100", value = 100 },
}

data.values = {
	board_reload = 6,
	flow_notifications = 1557,
	reset_act_flow = 503,
	reset_status = 0,
	reset_preps_flow = 503,
	reset_preps_notifications = 1557,
	force_ready = 1,
	data_hack_complete = 2,
	doomsday_hack_complete = 3,
	finish_status = 5,
	finish_cash_take = 999999,
}

data.flags = {
	finish_win = (1 << 9) | (1 << 16),
}

data.natives = {
	stop_cutscene_immediately = 0xD220BDD222AC4A1E,
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
			value = option.value,
		}
	end
	return out
end

data.option_names = option_helpers.names

data.option_index_by_value = option_helpers.index_by_value

data.option_index_by_name = option_helpers.index_by_name

function data.resolve_act(value, default_value)
	local number = math.floor(tonumber(value) or 0)
	if data.act_presets[number] then
		return number
	end
	return default_value or 1
end

function data.clamp_cut(value)
	return number_helpers.clamp_int(value, data.cuts.min, data.cuts.max, data.cuts.min)
end

function data.clamp_cut_preset_index(value)
	return number_helpers.clamp_int(value, 1, #data.cut_preset_options, #data.cut_preset_options)
end

return data
