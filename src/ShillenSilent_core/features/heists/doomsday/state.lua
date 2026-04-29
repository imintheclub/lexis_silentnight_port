local data = require("ShillenSilent_core.features.heists.doomsday.data")

local state = {
	config = {
		act = 1,
	},
	cuts = {
		player1 = data.cuts.defaults.player1,
		player2 = data.cuts.defaults.player2,
		player3 = data.cuts.defaults.player3,
		player4 = data.cuts.defaults.player4,
	},
	cut_enabled = {
		player1 = true,
		player2 = false,
		player3 = false,
		player4 = false,
	},
	flags = {
		max_payout_enabled = false,
		cut_preset_index = #data.cut_preset_options,
	},
	runtime = {
		max_payout_cache = {
			heist = nil,
			difficulty = nil,
			cut = nil,
		},
	},
}

function state.set_act(value)
	state.config.act = data.resolve_act(value, state.config.act)
	return state.config.act
end

function state.act_index()
	return data.option_index_by_value(data.act_options, state.config.act, 1)
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

function state.set_cut_preset_index(value)
	state.flags.cut_preset_index = data.clamp_cut_preset_index(value)
	return state.flags.cut_preset_index
end

function state.set_max_payout(enabled)
	state.flags.max_payout_enabled = enabled and true or false
	return state.flags.max_payout_enabled
end

function state.reset_max_payout_cache()
	state.runtime.max_payout_cache.heist = nil
	state.runtime.max_payout_cache.difficulty = nil
	state.runtime.max_payout_cache.cut = nil
end

return state
