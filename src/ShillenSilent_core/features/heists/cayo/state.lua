local data = require("ShillenSilent_core.features.heists.cayo.data")

local state = {
	config = {
		diff = 131055,
		app = 65535,
		wep = 1,
		tgt = 5,
		sec_comp = "GOLD",
		sec_isl = "GOLD",
		amt_comp = 255,
		amt_isl = 16777215,
		paint = 127,
		val_cash = data.default_values.cash,
		val_weed = data.default_values.weed,
		val_coke = data.default_values.coke,
		val_gold = data.default_values.gold,
		val_art = data.default_values.art,
		unlock_all_poi = true,
	},
	cuts = {
		host = data.cuts.defaults.host,
		player2 = data.cuts.defaults.player2,
		player3 = data.cuts.defaults.player3,
		player4 = data.cuts.defaults.player4,
	},
	cut_enabled = {
		host = true,
		player2 = false,
		player3 = false,
		player4 = false,
	},
	flags = {
		womans_bag_enabled = false,
		remove_crew_cuts_enabled = false,
		max_payout_enabled = false,
	},
	runtime = {
		tunable_backup = {
			bag_max_capacity = nil,
			pavel_cut = nil,
			fencing_fee = nil,
		},
		max_payout_cache = {
			target = nil,
			difficulty = nil,
			cut = nil,
		},
		teleport_in_progress = false,
	},
}

function state.set_config(key, value)
	if state.config[key] == nil then
		return false
	end
	state.config[key] = value
	return true
end

function state.set_cut(player_key, value)
	if state.cuts[player_key] == nil then
		return false
	end
	state.cuts[player_key] = data.clamp_cut(value)
	return true
end

function state.set_cut_enabled(player_key, enabled)
	if state.cut_enabled[player_key] == nil then
		return false
	end
	state.cut_enabled[player_key] = enabled and true or false
	return true
end

function state.set_uniform_cuts(value)
	local cut = data.clamp_cut(value)
	for i = 1, #data.player_keys do
		state.cuts[data.player_keys[i]] = cut
	end
	return cut
end

function state.reset_value_defaults()
	state.config.val_cash = data.default_values.cash
	state.config.val_weed = data.default_values.weed
	state.config.val_coke = data.default_values.coke
	state.config.val_gold = data.default_values.gold
	state.config.val_art = data.default_values.art
	return true
end

function state.reset_max_payout_cache()
	state.runtime.max_payout_cache.target = nil
	state.runtime.max_payout_cache.difficulty = nil
	state.runtime.max_payout_cache.cut = nil
end

return state
