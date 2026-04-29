local safe_access = require("ShillenSilent_core.core.safe_access")
local notify_core = require("ShillenSilent_core.core.notify")
local i18n = require("ShillenSilent_core.i18n")
local offsets = require("ShillenSilent_core.data.offsets.resolver")
local blip_teleport = require("ShillenSilent_core.shared.blip_teleport")
local data = require("ShillenSilent_core.features.businesses.hangar.data")
local state = require("ShillenSilent_core.features.businesses.hangar.state")

local actions = {}

local function cfg()
	return offsets.feature(data.feature_id)
end

local t = i18n.t

local push = notify_core.feature("feature.hangar.name")

local function get_stock_units()
	local stats = cfg().stats or {}
	return safe_access.get_mp_stat_int(stats.stock, 0) or 0
end

local function is_full()
	local limits = cfg().limits or {}
	return get_stock_units() >= (tonumber(limits.max_cargo) or 0)
end

local function owned_location()
	local stats = cfg().stats or {}
	local id = safe_access.get_mp_stat_int(stats.owned, 0)
	local loc = data.location_by_id(id)
	return loc
end

local function supplier_tick()
	local packed = cfg().packed_stats or {}
	local natives = cfg().natives or {}
	local ok = false
	if invoker and invoker.call and packed.cargo_available and natives.stat_set_packed_bool then
		for _, slot in ipairs(packed.character_slots or {}) do
			local call_ok = pcall(function()
				invoker.call(natives.stat_set_packed_bool, packed.cargo_available, true, slot)
			end)
			ok = call_ok or ok
		end
	end
	return ok
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
	local loc = owned_location() or data.locations[state.config.location_index]
	if not loc then
		return false
	end

	local offsets_cfg = cfg()
	return blip_teleport.teleport_to_blip_with_job(
		offsets_cfg.blips and offsets_cfg.blips.entrance,
		t("feature.hangar.name"),
		t("hangar.notify.teleported"),
		t("hangar.notify.entrance_missing"),
		{
			fallback_coords = loc,
			fallback_message = t("hangar.notify.teleported"),
		}
	)
end

function actions.fill_cargo()
	if state.fill.active then
		push("hangar.notify.fill_running", 1500)
		return false
	end
	if is_full() then
		push("hangar.notify.cargo_full", 2000)
		return false
	end
	state.set_fill_active(true)
	push("hangar.notify.fill_started", 2000)
	return true
end

function actions.set_fill_loop(enabled, silent)
	enabled = enabled == true
	if enabled then
		if state.fill.active then
			if not silent then
				push("hangar.notify.fill_running", 1500)
			end
			return true
		end
		if is_full() then
			state.set_fill_active(false)
			if not silent then
				push("hangar.notify.cargo_full", 2000)
			end
			return false
		end
		state.set_fill_active(true)
		if not silent then
			push("hangar.notify.fill_started", 2000)
		end
	else
		if not state.fill.active then
			if not silent then
				push("hangar.notify.fill_not_running", 1500)
			end
			return false
		end
		state.set_fill_active(false)
		if not silent then
			push("hangar.notify.fill_stopped", 2000)
		end
	end
	return state.fill.active
end

function actions.stop_fill()
	if not state.fill.active then
		push("hangar.notify.fill_not_running", 1500)
		return false
	end
	state.set_fill_active(false)
	push("hangar.notify.fill_stopped", 2000)
	return true
end

function actions.get_fill_active()
	return state.fill.active == true
end

function actions.fill_tick_once()
	if is_full() then
		push("hangar.notify.cargo_full", 2000)
		return false
	end
	local ok = supplier_tick()
	push(ok and "hangar.notify.fill_tick_ok" or "hangar.notify.fill_tick_failed", 2000)
	return ok
end

function actions.tick_fill_cargo()
	if not state.fill.active then
		return false
	end

	if is_full() then
		state.set_fill_active(false)
		push("hangar.notify.fill_complete", 2000)
		return false
	end

	return supplier_tick()
end

function actions.apply_current_state(silent)
	state.set_location_index(state.config.location_index)
	if state.fill.active and is_full() then
		state.set_fill_active(false)
	end
	if not silent then
		push("hangar.notify.preset_state_applied", 2000)
	end
	return true
end

return actions
