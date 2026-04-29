local data = require("ShillenSilent_core.features.heists.apartment.data")

local state = {
	config = {
		selected_heist = data.heist_options[1].value,
	},
	cuts = {
		player1 = data.cuts.defaults.player1,
		player2 = data.cuts.defaults.player2,
		player3 = data.cuts.defaults.player3,
		player4 = data.cuts.defaults.player4,
	},
	cut_enabled = {
		player1 = data.cut_enabled_defaults.player1,
		player2 = data.cut_enabled_defaults.player2,
		player3 = data.cut_enabled_defaults.player3,
		player4 = data.cut_enabled_defaults.player4,
	},
	flags = {
		bonus_enabled = false,
		double_rewards_week = false,
		max_payout_enabled = false,
		cut_preset_index = 4,
		auto_force_cuts = true,
	},
	runtime = {
		max_payout_cache = {},
	},
}

function state.set_selected_heist(value)
	state.config.selected_heist = data.resolve_heist_key(value, state.config.selected_heist)
	return state.config.selected_heist
end

function state.set_cut(player_key, value)
	if not state.cuts[player_key] then
		return false
	end
	state.cuts[player_key] = data.clamp_cut(value)
	return true
end

function state.set_cut_enabled(player_key, value)
	if state.cut_enabled[player_key] == nil then
		return false
	end
	state.cut_enabled[player_key] = value and true or false
	return true
end

function state.set_cut_preset_index(value)
	state.flags.cut_preset_index = data.clamp_cut_preset_index(value)
	return true
end

function state.selected_cut_preset()
	local idx = data.clamp_cut_preset_index(state.flags.cut_preset_index)
	state.flags.cut_preset_index = idx
	return data.cut_preset_options[idx] or data.cut_preset_options[#data.cut_preset_options]
end

function state.apply_uniform_cut(value)
	local cut = data.clamp_cut(value)
	for i = 1, #data.player_keys do
		state.cuts[data.player_keys[i]] = cut
	end
	return cut
end

function state.enabled_cuts()
	local out = {}
	for i = 1, #data.player_keys do
		local key = data.player_keys[i]
		out[key] = state.cut_enabled[key] and data.clamp_cut(state.cuts[key]) or 0
	end
	return out
end

return state
