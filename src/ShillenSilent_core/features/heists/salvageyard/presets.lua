local data = require("ShillenSilent_core.features.heists.salvageyard.data")
local state = require("ShillenSilent_core.features.heists.salvageyard.state")
local actions = require("ShillenSilent_core.features.heists.salvageyard.actions")

local presets = {}

local function collect_slot(slot)
	local slot_cfg = state.slot(slot) or {}
	return {
		robbery = slot_cfg.robbery,
		vehicle = slot_cfg.vehicle,
		modification = slot_cfg.modification,
		keep = slot_cfg.keep,
	}
end

local function apply_slot(slot, payload)
	local slot_cfg = state.slot(slot)
	if not slot_cfg or type(payload) ~= "table" then
		return
	end

	slot_cfg.robbery = data.resolve_option_value(data.options.robberies, payload.robbery, slot_cfg.robbery)
	slot_cfg.vehicle = data.resolve_option_value(data.options.vehicles, payload.vehicle, slot_cfg.vehicle)
	slot_cfg.modification =
		data.resolve_option_value(data.options.modifications, payload.modification, slot_cfg.modification)
	slot_cfg.keep = data.resolve_option_value(data.options.keep_statuses, payload.keep, slot_cfg.keep)
end

function presets.collect()
	return {
		slot1 = collect_slot(1),
		slot2 = collect_slot(2),
		slot3 = collect_slot(3),
		free_setup = state.flags.free_setup and true or false,
		free_claim = state.flags.free_claim and true or false,
		salvage_multiplier = tonumber(state.config.salvage_multiplier) or data.multiplier.default,
		sell_value_slot1 = math.floor(tonumber(state.config.sell_value_slot1) or 0),
		sell_value_slot2 = math.floor(tonumber(state.config.sell_value_slot2) or 0),
		sell_value_slot3 = math.floor(tonumber(state.config.sell_value_slot3) or 0),
	}
end

function presets.apply(payload)
	if type(payload) ~= "table" then
		return false
	end

	for slot = 1, 3 do
		apply_slot(slot, payload["slot" .. tostring(slot)])
	end

	if tonumber(payload.salvage_multiplier) then
		state.set_multiplier(payload.salvage_multiplier)
	end
	for slot = 1, 3 do
		local value = payload["sell_value_slot" .. tostring(slot)]
		if tonumber(value) then
			state.set_sell_value(slot, value)
		end
	end

	if type(payload.free_setup) == "boolean" then
		actions.set_free_setup(payload.free_setup, true)
	end
	if type(payload.free_claim) == "boolean" then
		actions.set_free_claim(payload.free_claim, true)
	end

	return true
end

return presets
