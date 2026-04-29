local data = require("ShillenSilent_core.features.heists.salvageyard.data")

local state = {
	config = {
		slot1 = { robbery = 0, vehicle = 1, modification = 0, keep = 1 },
		slot2 = { robbery = 1, vehicle = 2, modification = 0, keep = 1 },
		slot3 = { robbery = 2, vehicle = 3, modification = 0, keep = 1 },
		salvage_multiplier = data.multiplier.default,
		sell_value_slot1 = data.sell_value.default,
		sell_value_slot2 = data.sell_value.default,
		sell_value_slot3 = data.sell_value.default,
		popularity = data.popularity.default,
	},
	flags = {
		free_setup = false,
		free_claim = false,
		popularity_lock = false,
		collect_safe_ee_only = true,
		planning_force_offset_418_supported = true,
		planning_force_offset_416_supported = true,
		planning_reload_offset_537_supported = true,
		planning_reload_offset_535_supported = true,
	},
	runtime = {
		popularity_editor_value = data.popularity.default,
	},
}

local function slot_key(slot)
	return "slot" .. tostring(slot)
end

function state.slot(slot)
	return state.config[slot_key(slot)]
end

function state.set_slot_value(slot, field, value)
	local slot_cfg = state.slot(slot)
	if not slot_cfg then
		return false
	end
	slot_cfg[field] = math.floor(tonumber(value) or slot_cfg[field] or 0)
	return true
end

function state.sell_value(slot)
	return state.config["sell_value_slot" .. tostring(slot)] or data.sell_value.default
end

function state.option_index(slot, field, options, default_index)
	local slot_cfg = state.slot(slot)
	return data.option_index_by_value(options, slot_cfg and slot_cfg[field], default_index or 1)
end

function state.set_multiplier(value)
	state.config.salvage_multiplier =
		data.clamp_number(value, data.multiplier.min, data.multiplier.max, data.multiplier.default)
end

function state.set_sell_value(slot, value)
	local key = "sell_value_slot" .. tostring(slot)
	state.config[key] = data.clamp_int(value, data.sell_value.min, data.sell_value.max, data.sell_value.default)
end

function state.set_popularity(value)
	state.config.popularity = data.clamp_int(value, data.popularity.min, data.popularity.max, data.popularity.default)
end

function state.set_free_setup(enabled)
	state.flags.free_setup = enabled and true or false
end

function state.set_free_claim(enabled)
	state.flags.free_claim = enabled and true or false
end

function state.set_popularity_lock(enabled)
	state.flags.popularity_lock = enabled and true or false
end

return state
