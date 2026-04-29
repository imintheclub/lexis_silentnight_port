local core_state = require("ShillenSilent_core.shared.runtime_state")
local data = require("ShillenSilent_core.features.heists.casino.data")
local state = require("ShillenSilent_core.features.heists.casino.state")
local actions = require("ShillenSilent_core.features.heists.casino.actions")

local presets = {}

local function legacy_value(options, index, fallback)
	local legacy_index = tonumber(index)
	if legacy_index == nil then
		return fallback
	end
	local option = options[math.floor(legacy_index) + 1]
	return option and option.value or fallback
end

local function collect_player(player_key)
	return {
		enabled = state.cut_enabled[player_key] and true or false,
		cut = data.clamp_cut(state.cuts[player_key]),
	}
end

function presets.collect()
	state.clamp_loadout_slot()
	state.clamp_vehicle_slot()
	return {
		difficulty = state.config.difficulty,
		approach = state.config.approach,
		gunman = state.config.crew_weapon,
		driver = state.config.crew_driver,
		hacker = state.config.crew_hacker,
		masks = state.config.masks,
		guards = state.config.disrupt_shipments,
		keycards = state.config.key_levels,
		target = state.config.target,
		loadout = state.config.loadout_slot,
		vehicles = state.config.vehicle_slot,
		unlock_all_poi = state.config.unlock_all_poi and true or false,
		solo_launch = core_state.solo_launch.casino and true or false,
		remove_crew_cuts = state.flags.remove_crew_cuts_enabled and true or false,
		autograbber = state.flags.autograbber_enabled and true or false,
		max_payout = state.flags.max_payout_enabled and true or false,
		player1 = collect_player("host"),
		player2 = collect_player("player2"),
		player3 = collect_player("player3"),
		player4 = collect_player("player4"),
	}
end

function presets.apply(payload)
	if type(payload) ~= "table" then
		return false
	end

	local options = data.options
	state.config.difficulty =
		data.resolve_option_value(options.difficulties, payload.difficulty, state.config.difficulty)
	state.config.approach = data.resolve_option_value(options.approaches, payload.approach, state.config.approach)
	state.config.crew_weapon = data.resolve_option_value(options.gunmen, payload.gunman, state.config.crew_weapon)
	state.config.crew_driver = data.resolve_option_value(options.drivers, payload.driver, state.config.crew_driver)
	state.config.crew_hacker = data.resolve_option_value(options.hackers, payload.hacker, state.config.crew_hacker)
	state.config.masks = data.resolve_option_value(options.masks, payload.masks, state.config.masks)
	state.config.disrupt_shipments =
		data.resolve_option_value(options.guards, payload.guards, state.config.disrupt_shipments)
	state.config.key_levels = data.resolve_option_value(options.keycards, payload.keycards, state.config.key_levels)
	state.config.target = data.resolve_option_value(options.targets, payload.target, state.config.target)

	if payload.presets ~= nil then
		state.config.difficulty = legacy_value(options.difficulties, payload.difficulty, state.config.difficulty)
		state.config.approach = legacy_value(options.approaches, payload.approach, state.config.approach)
		state.config.crew_weapon = legacy_value(options.gunmen, payload.gunman, state.config.crew_weapon)
		state.config.crew_driver = legacy_value(options.drivers, payload.driver, state.config.crew_driver)
		state.config.crew_hacker = legacy_value(options.hackers, payload.hacker, state.config.crew_hacker)
		state.config.masks = legacy_value(options.masks, payload.masks, state.config.masks)
		state.config.disrupt_shipments = legacy_value(options.guards, payload.guards, state.config.disrupt_shipments)
		state.config.key_levels = legacy_value(options.keycards, payload.keycards, state.config.key_levels)
		state.config.target = legacy_value(options.targets, payload.target, state.config.target)
	end

	if payload.loadout ~= nil then
		state.config.loadout_slot = data.clamp_int(payload.loadout, 1, 6, state.config.loadout_slot)
	end
	if payload.vehicles ~= nil then
		state.config.vehicle_slot = data.clamp_int(payload.vehicles, 1, 4, state.config.vehicle_slot)
	end
	if payload.presets ~= nil then
		if payload.loadout ~= nil then
			state.config.loadout_slot =
				data.clamp_int((tonumber(payload.loadout) or 0) + 1, 1, 6, state.config.loadout_slot)
		end
		if payload.vehicles ~= nil then
			state.config.vehicle_slot =
				data.clamp_int((tonumber(payload.vehicles) or 0) + 1, 1, 4, state.config.vehicle_slot)
		end
	end
	state.clamp_loadout_slot()
	state.clamp_vehicle_slot()

	if type(payload.unlock_all_poi) == "boolean" then
		state.config.unlock_all_poi = payload.unlock_all_poi
	end
	if type(payload.solo_launch) == "boolean" then
		core_state.solo_launch.casino = payload.solo_launch
	end
	if type(payload.remove_crew_cuts) == "boolean" then
		actions.set_remove_crew_cuts(payload.remove_crew_cuts, true)
	end
	if type(payload.autograbber) == "boolean" then
		actions.set_autograbber(payload.autograbber, true)
	end
	if type(payload.max_payout) == "boolean" then
		actions.set_max_payout(payload.max_payout, true)
	end

	local player_map = {
		player1 = "host",
		player2 = "player2",
		player3 = "player3",
		player4 = "player4",
	}
	for preset_key, state_key in pairs(player_map) do
		local player = payload[preset_key]
		if type(player) == "table" then
			if type(player.enabled) == "boolean" then
				state.set_cut_enabled(state_key, player.enabled)
			end
			if player.cut ~= nil then
				state.set_cut(state_key, player.cut)
			end
		end
	end

	if state.flags.max_payout_enabled then
		actions.refresh_max_payout(true)
	end
	return true
end

return presets
