local safe_access = require("ShillenSilent_core.core.safe_access")
local notify_core = require("ShillenSilent_core.core.notify")
local i18n = require("ShillenSilent_core.i18n")
local offsets = require("ShillenSilent_core.data.offsets.resolver")
local coords_teleport = require("ShillenSilent_core.shared.coords_teleport")
local data = require("ShillenSilent_core.features.businesses.moneyfronts.data")
local state = require("ShillenSilent_core.features.businesses.moneyfronts.state")

local actions = {}

local function cfg()
	return offsets.feature(data.feature_id)
end

local t = i18n.t

local push = notify_core.feature("feature.moneyfronts.name")

local function is_location_owned(loc)
	local owned_stats = cfg().stats and cfg().stats.owned or {}
	local owned_stat = loc and owned_stats[loc.key] or nil
	if not owned_stat then
		return false
	end
	local candidates = {
		safe_access.stat_name(owned_stat),
		"MPX_" .. owned_stat,
		owned_stat,
	}
	for i = 1, #candidates do
		local value = safe_access.get_stat_int(candidates[i], 0)
		if value and value > 0 then
			return true
		end
	end
	return false
end

local function pick_owned_location()
	local selected = data.locations[state.config.location_index]
	if selected and is_location_owned(selected) then
		return selected
	end
	for i = 1, #data.locations do
		if is_location_owned(data.locations[i]) then
			return data.locations[i]
		end
	end
	return nil
end

local function set_front_heat(value, silent)
	local heat = data.clamp_heat(value)
	local packed = cfg().packed_stats or {}
	local natives = cfg().natives or {}
	local any_ok = false

	if invoker and invoker.call and natives.stat_set_packed_int then
		for _, idx in ipairs(packed.heat_indices or {}) do
			if type(idx) == "number" and idx >= 0 then
				for _, slot in ipairs(packed.character_slots or {}) do
					local ok = pcall(function()
						invoker.call(natives.stat_set_packed_int, idx, heat, slot)
					end)
					any_ok = ok or any_ok
				end
			end
		end
	end

	state.set_heat_editor_value(heat)
	if not silent then
		push(any_ok and "moneyfronts.notify.heat_set" or "moneyfronts.notify.heat_failed", 2000, {
			value = tostring(heat),
		})
	end
	return any_ok
end

local function read_packed_int(idx, slot)
	local natives = cfg().natives or {}
	if not (memory and invoker and invoker.call and memory.alloc_int and memory.read_int) then
		return nil
	end

	local buf = memory.alloc_int()
	if not buf then
		return nil
	end

	local value = nil
	local ok_call = pcall(function()
		invoker.call(natives.stat_get_packed_int, idx, buf, slot or 0)
	end)
	if ok_call then
		local ok_read, read_value = pcall(memory.read_int, buf)
		if ok_read then
			value = tonumber(read_value)
		end
	end

	if memory.free then
		pcall(memory.free, buf)
	elseif memory.free_int then
		pcall(memory.free_int, buf)
	end

	return value
end

function actions.get_locations()
	return data.locations
end

function actions.get_selected_loc()
	return state.config.location_index
end

function actions.set_selected_loc(idx)
	state.set_location_index(idx)
end

function actions.teleport()
	local loc = pick_owned_location() or data.locations[state.config.location_index]
	if not loc then
		return false
	end
	return coords_teleport.run_coords_teleport(
		t("feature.moneyfronts.name"),
		t("moneyfronts.notify.teleported", { location = t(loc.label_key) }),
		loc.x,
		loc.y,
		loc.z,
		false,
		nil
	)
end

function actions.get_heat_editor_value()
	return state.config.heat_editor_value
end

function actions.set_heat_editor_value(value)
	state.set_heat_editor_value(value)
end

function actions.apply_heat_editor_value()
	return set_front_heat(state.config.heat_editor_value, false)
end

function actions.reset_heat()
	return set_front_heat(0, false)
end

function actions.reset_safe_production_state()
	local ok = set_front_heat(0, true)
	push(
		ok and "moneyfronts.notify.safe_production_reset_ok" or "moneyfronts.notify.safe_production_reset_failed",
		2200
	)
	return ok
end

function actions.set_heat_lock_active(enabled, silent)
	state.set_heat_lock_active(enabled == true)
	if state.flags.heat_lock_active then
		set_front_heat(0, true)
	end
	if not silent then
		push(
			state.flags.heat_lock_active and "moneyfronts.notify.heat_lock_on" or "moneyfronts.notify.heat_lock_off",
			2000
		)
	end
	return state.flags.heat_lock_active
end

function actions.get_heat_lock_active()
	return state.flags.heat_lock_active == true
end

function actions.tick_heat_lock()
	if not state.flags.heat_lock_active then
		return false
	end

	local packed = cfg().packed_stats or {}
	for _, idx in ipairs(packed.heat_indices or {}) do
		if type(idx) == "number" and idx >= 0 then
			for _, slot in ipairs(packed.character_slots or {}) do
				local value = read_packed_int(idx, slot)
				if value and value > data.heat.lock_threshold then
					set_front_heat(0, true)
					return true
				end
			end
		end
	end
	return false
end

function actions.car_wash_collect_safe()
	local offsets_cfg = cfg()
	local stats = offsets_cfg.stats or {}
	local value = safe_access.get_mp_stat_int(stats.car_wash_safe_cash_value, 0) or 0
	if value <= 0 then
		push("moneyfronts.notify.car_wash_safe_empty", 2000)
		return false
	end

	local globals = offsets_cfg.globals or {}
	local ok = safe_access.set_global_bool(globals.car_wash_safe_collect, true)
	push(ok and "moneyfronts.notify.car_wash_safe_ok" or "moneyfronts.notify.car_wash_safe_failed", 2000)
	return ok
end

function actions.apply_current_state(silent)
	state.set_location_index(state.config.location_index)
	state.set_heat_editor_value(state.config.heat_editor_value)
	actions.set_heat_lock_active(state.flags.heat_lock_active, true)
	if not silent then
		push("moneyfronts.notify.preset_state_applied", 2000)
	end
	return true
end

return actions
