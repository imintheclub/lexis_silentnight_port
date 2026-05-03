local data = require("ShillenSilent_core.features.heists.cayo.data")
local state = require("ShillenSilent_core.features.heists.cayo.state")
local actions = require("ShillenSilent_core.features.heists.cayo.actions")

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
	return {
		diff = state.config.diff,
		app = state.config.app,
		wep = state.config.wep,
		tgt = state.config.tgt,
		sec_comp = state.config.sec_comp,
		sec_isl = state.config.sec_isl,
		amt_comp = state.config.amt_comp,
		amt_isl = state.config.amt_isl,
		paint = state.config.paint,
		val_cash = data.clamp_value(state.config.val_cash),
		val_weed = data.clamp_value(state.config.val_weed),
		val_coke = data.clamp_value(state.config.val_coke),
		val_gold = data.clamp_value(state.config.val_gold),
		val_art = data.clamp_value(state.config.val_art),
		unlock_all_poi = state.config.unlock_all_poi and true or false,
		womans_bag = state.flags.womans_bag_enabled and true or false,
		remove_crew_cuts = state.flags.remove_crew_cuts_enabled and true or false,
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

	state.config.diff = data.resolve_option_value(data.difficulties, payload.diff, state.config.diff)
	state.config.app = data.resolve_option_value(data.approaches, payload.app, state.config.app)
	state.config.wep = data.resolve_option_value(data.loadouts, payload.wep, state.config.wep)
	state.config.tgt = data.resolve_option_value(data.primary_targets, payload.tgt, state.config.tgt)
	state.config.sec_comp = data.resolve_option_value(data.secondary_targets, payload.sec_comp, state.config.sec_comp)
	state.config.sec_isl = data.resolve_option_value(data.secondary_targets, payload.sec_isl, state.config.sec_isl)
	state.config.amt_comp = data.resolve_option_value(data.compound_amounts, payload.amt_comp, state.config.amt_comp)
	state.config.amt_isl = data.resolve_option_value(data.island_amounts, payload.amt_isl, state.config.amt_isl)
	state.config.paint = data.resolve_option_value(data.arts_amounts, payload.paint, state.config.paint)

	if payload.difficulty ~= nil and payload.diff == nil then
		state.config.diff = legacy_value(data.difficulties, payload.difficulty, state.config.diff)
	end
	if payload.approach ~= nil and payload.app == nil then
		state.config.app = legacy_value(data.approaches, payload.approach, state.config.app)
	end
	if payload.loadout ~= nil and payload.wep == nil then
		state.config.wep = legacy_value(data.loadouts, payload.loadout, state.config.wep)
	end
	if payload.primary_target ~= nil and payload.tgt == nil then
		state.config.tgt = legacy_value(data.primary_targets, payload.primary_target, state.config.tgt)
	end
	if payload.compound_target ~= nil and payload.sec_comp == nil then
		state.config.sec_comp = legacy_value(data.secondary_targets, payload.compound_target, state.config.sec_comp)
	end
	if payload.compound_amount ~= nil and payload.amt_comp == nil then
		state.config.amt_comp = legacy_value(data.compound_amounts, payload.compound_amount, state.config.amt_comp)
	end
	if payload.arts_amount ~= nil and payload.paint == nil then
		state.config.paint = legacy_value(data.arts_amounts, payload.arts_amount, state.config.paint)
	end
	if payload.island_target ~= nil and payload.sec_isl == nil then
		state.config.sec_isl = legacy_value(data.secondary_targets, payload.island_target, state.config.sec_isl)
	end
	if payload.island_amount ~= nil and payload.amt_isl == nil then
		state.config.amt_isl = legacy_value(data.island_amounts, payload.island_amount, state.config.amt_isl)
	end

	if payload.val_cash ~= nil then
		state.config.val_cash = data.clamp_value(payload.val_cash)
	elseif payload.cash_value ~= nil then
		state.config.val_cash = data.clamp_value(payload.cash_value)
	end
	if payload.val_weed ~= nil then
		state.config.val_weed = data.clamp_value(payload.val_weed)
	elseif payload.weed_value ~= nil then
		state.config.val_weed = data.clamp_value(payload.weed_value)
	end
	if payload.val_coke ~= nil then
		state.config.val_coke = data.clamp_value(payload.val_coke)
	elseif payload.coke_value ~= nil then
		state.config.val_coke = data.clamp_value(payload.coke_value)
	end
	if payload.val_gold ~= nil then
		state.config.val_gold = data.clamp_value(payload.val_gold)
	elseif payload.gold_value ~= nil then
		state.config.val_gold = data.clamp_value(payload.gold_value)
	end
	if payload.val_art ~= nil then
		state.config.val_art = data.clamp_value(payload.val_art)
	elseif payload.arts_value ~= nil then
		state.config.val_art = data.clamp_value(payload.arts_value)
	end
	if type(payload.unlock_all_poi) == "boolean" then
		state.config.unlock_all_poi = payload.unlock_all_poi
	end
	if type(payload.womans_bag) == "boolean" then
		actions.set_womans_bag(payload.womans_bag, true)
	end
	if type(payload.remove_crew_cuts) == "boolean" then
		actions.set_remove_crew_cuts(payload.remove_crew_cuts, true)
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
