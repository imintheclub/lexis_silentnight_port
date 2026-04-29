local option_helpers = require("ShillenSilent_core.core.options")
local number_helpers = require("ShillenSilent_core.core.numbers")
local data = {}

data.feature_id = "apartment"
data.label_key = "feature.apartment.name"

data.safe_payout_target = 3000000

data.cuts = {
	min = 0,
	max = 9999,
	step = 1,
	defaults = {
		player1 = 100,
		player2 = 0,
		player3 = 0,
		player4 = 0,
	},
}

data.cut_enabled_defaults = {
	player1 = true,
	player2 = false,
	player3 = false,
	player4 = false,
}

data.player_keys = { "player1", "player2", "player3", "player4" }

data.cut_preset_options = {
	{ label_key = "apartment.cut_preset.all_0", value = 0 },
	{ label_key = "apartment.cut_preset.all_25", value = 25 },
	{ label_key = "apartment.cut_preset.all_85", value = 85 },
	{ label_key = "apartment.cut_preset.all_100", value = 100 },
}

data.values = {
	force_ready = 6,
	board_reload_step1_reset = 0,
	board_reload_step1 = 5,
	board_reload_step2 = 10,
	board_unlock_all = 22,
	cooldown_enabled = 1,
	cooldown_removed = -1,
	cooldown_cleared = 0,
	heist_planning_stage_complete = -1,
	bitset_heist_vs_missions_complete = -17809409,
	heist_session_id_macaddr = 183381814,
	fleeca_hack_complete = 7,
	fleeca_drill_complete = 100.0,
	pacific_hack_complete = 9,
	pacific_finish_status = 5,
	pacific_finish_take = 10000000,
	finish_large_take = 99999,
	other_finish_status = 12,
	unlock_depth = 5,
	launcher_apartment_flow = 1,
	launcher_apartment_extra = 0,
}

data.bonus = {
	enabled_progress = 268435455,
	disabled_progress = 134217727,
}

data.heist_ids = {
	fleeca = "hK5OgJk1BkinXGGXghhTMg",
	prison_break = "7-w96-PU4kSevhtG5YwUHQ",
	humane_labs = "BWsCWtmnvEWXBrprK9hDHA",
	series_a = "20Lu41Px20OJMPdZ6wXG3g",
	pacific_standard = "zCxFg29teE2ReKGnr0L4Bg",
}

data.preps = {
	fleeca = {
		rcont_ids = { -1072870761, "hK5OgJk1BkinXGGXghhTMg", "V7yEdnL6TEyU3i-U1Rv_pQ" },
		depth_lvs = { -1, 0, 1 },
		progress_hash = -836352461,
		reward_cosmetic = 25,
		root_content_id = "33TxqLipLUintwlU_YDzMg",
	},
	prison_break = {
		rcont_ids = {
			979654579,
			"7-w96-PU4kSevhtG5YwUHQ",
			"oSXhVwaHH0KDOzg0rfIj3Q",
			"QS6WYcjJFk2YxqYDMN8mjQ",
			"JJ9OzPbPo02eQbaniO8E3g",
		},
		depth_lvs = { -1, 0, 0, 0, 1 },
		progress_hash = 137052480,
		reward_cosmetic = 22,
		root_content_id = "A6UBSyF61kiveglc58lm2Q",
	},
	humane_labs = {
		rcont_ids = {
			-1096986654,
			"BWsCWtmnvEWXBrprK9hDHA",
			"6k6LOpnf2E-GG38OhjS-TA",
			"nSWwSwAf3EaHZWsk449lBg",
			"ciWN4gwmakid4lW-nSllcA",
			"v-8OOQYzxE-Zvqj5xO03DQ",
		},
		depth_lvs = { -1, 0, 0, 1, 2, 2 },
		progress_hash = 496643418,
		reward_cosmetic = 23,
		root_content_id = "a_hWnpMUz0-7Yd_Rc5pJ4w",
	},
	series_a = {
		rcont_ids = {
			164435858,
			"20Lu41Px20OJMPdZ6wXG3g",
			"6UzZkstFeEeCkvs2lrF_6A",
			"PPnsIR0v2U2COyRbED87gw",
			"z49DSS9db0i_vh6A2e-Q-g",
			"Fo168mMjCUCeN_IKmL4VnA",
		},
		depth_lvs = { -1, 0, 0, 0, 1, 2 },
		progress_hash = 1585746186,
		reward_cosmetic = 24,
		root_content_id = "7r5AKL5aB0qe9HiDy3nW8w",
	},
	pacific_standard = {
		rcont_ids = {
			-231973569,
			"zCxFg29teE2ReKGnr0L4Bg",
			"6ClY8ZA_DkuBUdZ_fPn6Rw",
			"OiSO3Z0YdkCaEqVHhhkj4Q",
			"Cy2OZSwCt0-mSXY00o4SNw",
			"Y4zpRQDfvkawfFDR1Uxi2A",
		},
		depth_lvs = { -1, 0, 1, 2, 2, 2 },
		progress_hash = 911181645,
		reward_cosmetic = 21,
		root_content_id = "hKSf9RCT8UiaZlykyGrMwg",
	},
}

data.heist_key_by_rcont = {}
for key, heist in pairs(data.preps) do
	data.heist_key_by_rcont[heist.rcont_ids[1]] = key
	data.heist_key_by_rcont[heist.rcont_ids[2]] = key
end

data.heist_key_by_progress_hash = {
	[-836352461] = "fleeca",
	[137052480] = "prison_break",
	[496643418] = "humane_labs",
	[1585746186] = "series_a",
	[911181645] = "pacific_standard",
}

data.payouts = {
	[data.heist_ids.fleeca] = { 100625, 201250, 251563 },
	[data.heist_ids.prison_break] = { 350000, 700000, 875000 },
	[data.heist_ids.humane_labs] = { 472500, 945000, 1181250 },
	[data.heist_ids.series_a] = { 353500, 707000, 883750 },
	[data.heist_ids.pacific_standard] = { 750000, 1500000, 1875000 },
}

data.root_defs = {
	{ tunable = "ROOT_ID_HASH_THE_FLECCA_JOB", fallback = "33TxqLipLUintwlU_YDzMg" },
	{ tunable = "ROOT_ID_HASH_THE_PRISON_BREAK", fallback = "A6UBSyF61kiveglc58lm2Q" },
	{ tunable = "ROOT_ID_HASH_THE_HUMANE_LABS_RAID", fallback = "a_hWnpMUz0-7Yd_Rc5pJ4w" },
	{ tunable = "ROOT_ID_HASH_SERIES_A_FUNDING", fallback = "7r5AKL5aB0qe9HiDy3nW8w" },
	{ tunable = "ROOT_ID_HASH_THE_PACIFIC_STANDARD_JOB", fallback = "hKSf9RCT8UiaZlykyGrMwg" },
}

data.natives = {
	network_session_host_closed = 0xED34C0C02C098BB7,
	network_session_host = 0x6F3D4ED9BEE4E61D,
	get_hash_key = 0xD24D37CC275948CC,
	set_cursor_position = 0xFC695459D4D0E219,
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

data.option_value_by_name = option_helpers.value_by_name

function data.clamp_cut(value)
	return number_helpers.clamp_int(value, data.cuts.min, data.cuts.max, data.cuts.min)
end

function data.clamp_cut_preset_index(value)
	return number_helpers.clamp_int(value, 1, #data.cut_preset_options, #data.cut_preset_options)
end

return data
