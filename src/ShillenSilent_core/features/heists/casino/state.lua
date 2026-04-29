local data = require("ShillenSilent_core.features.heists.casino.data")

local state = {
	config = {
		difficulty = 0,
		approach = 1,
		crew_weapon = 1,
		loadout_slot = 1,
		crew_driver = 1,
		vehicle_slot = 1,
		crew_hacker = 1,
		masks = 4,
		disrupt_shipments = 3,
		key_levels = 2,
		target = 3,
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
		remove_crew_cuts_enabled = false,
		autograbber_enabled = false,
		max_payout_enabled = false,
	},
	runtime = {
		crew_cut_backup = {},
		max_payout_cache = {
			target = nil,
			difficulty = nil,
			buyer = nil,
			gunman = nil,
			driver = nil,
			hacker = nil,
			solo = nil,
			host_cut = nil,
			crew_cut = nil,
		},
		solo_launch_prev = false,
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

function state.clamp_loadout_slot()
	local range = data.loadout_range(state.config.approach, state.config.crew_weapon)
	local max_slot = math.max(1, range[2] - range[1] + 1)
	state.config.loadout_slot = data.clamp_int(state.config.loadout_slot, 1, max_slot, 1)
	return state.config.loadout_slot
end

function state.clamp_vehicle_slot()
	local range = data.vehicle_range(state.config.crew_driver)
	local max_slot = math.max(1, range[2] - range[1] + 1)
	state.config.vehicle_slot = data.clamp_int(state.config.vehicle_slot, 1, max_slot, 1)
	return state.config.vehicle_slot
end

function state.reset_max_payout_cache()
	local cache = state.runtime.max_payout_cache
	cache.target = nil
	cache.difficulty = nil
	cache.buyer = nil
	cache.gunman = nil
	cache.driver = nil
	cache.hacker = nil
	cache.solo = nil
	cache.host_cut = nil
	cache.crew_cut = nil
end

return state
