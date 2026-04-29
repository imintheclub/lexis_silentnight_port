local safe_access = require("ShillenSilent_core.core.safe_access")
local business_runtime = require("ShillenSilent_core.core.business_runtime")
local notify_core = require("ShillenSilent_core.core.notify")
local i18n = require("ShillenSilent_core.i18n")
local offsets = require("ShillenSilent_core.data.offsets.current")
local coords_teleport = require("ShillenSilent_core.shared.coords_teleport")
local blip_teleport = require("ShillenSilent_core.shared.blip_teleport")
local data = require("ShillenSilent_core.features.businesses.moneyfronts.data")
local state = require("ShillenSilent_core.features.businesses.moneyfronts.state")

local actions = {}

local function cfg()
	return offsets[data.feature_id] or {}
end

local t = i18n.t

local push = notify_core.feature("feature.moneyfronts.name")

local function read_packed_int(idx, slot)
	local natives = cfg().natives or {}
	return business_runtime.read_packed_int(idx, slot, natives.stat_get_packed_int)
end

local function set_heat_for_key(key, value, silent)
	local packed = cfg().packed_stats or {}
	local natives = cfg().natives or {}
	local idx = packed.heat_indices and packed.heat_indices[key]
	local heat = data.clamp_heat(value)
	local ok = business_runtime.write_packed_int(idx, heat, packed.character_slots, natives.stat_set_packed_int)
	state.set_front_heat_value(key, heat)
	if not silent then
		push(ok and "moneyfronts.notify.heat_set" or "moneyfronts.notify.heat_failed", 2000, {
			value = tostring(heat),
		})
	end
	return ok
end

local function current_heat_for_key(key)
	local packed = cfg().packed_stats or {}
	local idx = packed.heat_indices and packed.heat_indices[key]
	if type(idx) ~= "number" then
		return state.config.front_heat[key] or 0
	end
	return read_packed_int(idx, 0) or state.config.front_heat[key] or 0
end

function actions.teleport_front(key)
	local loc = data.location_by_key(key)
	if not loc then
		return false
	end
	local blips = cfg().blips or {}
	local heat = current_heat_for_key(key)
	local blip = heat >= data.heat.max and blips[key .. "_hot"] or blips[key]
	return blip_teleport.teleport_to_blip_with_job(
		blip,
		t("feature.moneyfronts.name"),
		t("moneyfronts.notify.teleported", { location = t(loc.label_key) }),
		t("moneyfronts.notify.entrance_missing"),
		{
			fallback_coords = loc,
			fallback_message = t("moneyfronts.notify.teleported", { location = t(loc.label_key) }),
		}
	)
end

function actions.teleport_laptop(key)
	local loc = data.location_by_key(key)
	local coords = cfg().coords and cfg().coords[key]
	if not (loc and coords) then
		return false
	end
	return coords_teleport.run_coords_teleport(
		t("feature.moneyfronts.name"),
		t("moneyfronts.notify.teleported_laptop", { location = t(loc.heat_label_key or loc.label_key) }),
		coords.x,
		coords.y,
		coords.z,
		false,
		nil
	)
end

function actions.get_front_heat_value(key)
	return state.config.front_heat[key] or data.heat.default
end

function actions.set_front_heat_value(key, value)
	state.set_front_heat_value(key, value)
	return state.config.front_heat[key] or data.heat.default
end

function actions.apply_front_heat_value(key)
	return set_heat_for_key(key, state.config.front_heat[key] or data.heat.default, false)
end

function actions.max_front_heat(key)
	state.set_front_heat_value(key, data.heat.max)
	return set_heat_for_key(key, data.heat.max, false)
end

function actions.min_front_heat(key)
	state.set_front_heat_value(key, data.heat.min)
	return set_heat_for_key(key, data.heat.min, false)
end

function actions.set_front_heat_lock_active(key, enabled, silent)
	state.set_front_heat_lock_active(key, enabled == true)
	if state.flags.front_heat_lock[key] then
		state.set_front_heat_value(key, current_heat_for_key(key))
	end
	if not silent then
		push(
			state.flags.front_heat_lock[key] and "moneyfronts.notify.heat_lock_on" or "moneyfronts.notify.heat_lock_off",
			2000
		)
	end
	return state.flags.front_heat_lock[key]
end

function actions.get_front_heat_lock_active(key)
	return state.flags.front_heat_lock[key] == true
end

function actions.tick_front_heat_locks()
	local packed = cfg().packed_stats or {}
	local did_write = false
	for _, key in ipairs(data.front_keys) do
		if state.flags.front_heat_lock[key] then
			local idx = packed.heat_indices and packed.heat_indices[key]
			local value = state.config.front_heat[key] or data.heat.default
			if type(idx) == "number" then
				did_write = set_heat_for_key(key, value, true) or did_write
			end
		end
	end
	return did_write
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

return actions
