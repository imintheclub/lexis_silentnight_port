local data = require("ShillenSilent_core.features.heists.apartment.data")
local state = require("ShillenSilent_core.features.heists.apartment.state")
local actions = require("ShillenSilent_core.features.heists.apartment.actions")

local core_state = require("ShillenSilent_core.shared.runtime_state")
local presets = {}

local function collect_player(player_key)
	return {
		enabled = state.cut_enabled[player_key] and true or false,
		cut = data.clamp_cut(state.cuts[player_key]),
	}
end

function presets.collect()
	return {
		solo_launch = core_state.solo_launch.apartment and true or false,
		bonus_12mil = state.flags.bonus_enabled and true or false,
		double_rewards_week = state.flags.double_rewards_week and true or false,
		max_payout = state.flags.max_payout_enabled and true or false,
		auto_force_cuts = state.flags.auto_force_cuts and true or false,
		cut_preset = state.flags.cut_preset_index,
		player1 = collect_player("player1"),
		player2 = collect_player("player2"),
		player3 = collect_player("player3"),
		player4 = collect_player("player4"),
	}
end

function presets.apply(payload)
	if type(payload) ~= "table" then
		return false
	end

	if type(payload.solo_launch) == "boolean" then
		core_state.solo_launch.apartment = payload.solo_launch
	end
	if type(payload.bonus_12mil) == "boolean" then
		actions.set_12mil_bonus(payload.bonus_12mil, true)
	end
	if type(payload.double_rewards_week) == "boolean" then
		actions.set_double_rewards(payload.double_rewards_week, true)
	end
	if type(payload.max_payout) == "boolean" then
		actions.set_max_payout(payload.max_payout, true)
	end
	if type(payload.auto_force_cuts) == "boolean" then
		state.flags.auto_force_cuts = payload.auto_force_cuts
	end
	if payload.cut_preset ~= nil then
		state.set_cut_preset_index(payload.cut_preset)
	end

	for i = 1, #data.player_keys do
		local key = data.player_keys[i]
		local player = payload[key]
		if type(player) == "table" then
			if type(player.enabled) == "boolean" then
				state.set_cut_enabled(key, player.enabled)
			end
			if player.cut ~= nil then
				state.set_cut(key, player.cut)
			end
		end
	end

	if state.flags.max_payout_enabled then
		actions.refresh_max_payout(true)
	end
	return true
end

return presets
