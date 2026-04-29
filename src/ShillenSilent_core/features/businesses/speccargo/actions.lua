local jobs = require("ShillenSilent_core.core.jobs")
local safe_access = require("ShillenSilent_core.core.safe_access")
local notify_core = require("ShillenSilent_core.core.notify")
local i18n = require("ShillenSilent_core.i18n")
local offsets = require("ShillenSilent_core.data.offsets.resolver")
local coords_teleport = require("ShillenSilent_core.shared.coords_teleport")
local data = require("ShillenSilent_core.features.businesses.speccargo.data")
local state = require("ShillenSilent_core.features.businesses.speccargo.state")

local actions = {}

local function cfg()
	return offsets.feature(data.feature_id)
end

local t = i18n.t

local push = notify_core.feature("feature.speccargo.name")

local function get_owned_warehouse_ids()
	local owned = {}
	local stats = cfg().stats or {}
	for slot = 0, 4 do
		local warehouse_id =
			safe_access.get_mp_stat_int(tostring(stats.warehouse_slot_prefix or "") .. tostring(slot), 0)
		if warehouse_id and warehouse_id > 0 then
			owned[warehouse_id] = true
		end
	end
	return owned
end

local function get_fullness_state()
	local stats = cfg().stats or {}
	local has_owned = false
	for slot = 0, 4 do
		local warehouse_id =
			safe_access.get_mp_stat_int(tostring(stats.warehouse_slot_prefix or "") .. tostring(slot), 0)
		if warehouse_id and warehouse_id > 0 then
			has_owned = true
			local crates = safe_access.get_mp_stat_int(tostring(stats.crate_total_prefix or "") .. tostring(slot), 0)
				or 0
			local cap = data.infer_warehouse_cap(warehouse_id, crates)
			if crates < cap then
				return false, true
			end
		end
	end
	return has_owned, has_owned
end

local function supplier_pulse_once()
	local packed = cfg().packed_stats or {}
	local natives = cfg().natives or {}
	local ok = false
	if invoker and invoker.call and natives.stat_set_packed_bool then
		for idx = packed.supply_first, packed.supply_last do
			for _, slot in ipairs(packed.character_slots or {}) do
				local call_ok = pcall(function()
					invoker.call(natives.stat_set_packed_bool, idx, true, slot)
				end)
				ok = call_ok or ok
			end
		end
	end
	return ok
end

function actions.get_locations()
	local owned_ids = get_owned_warehouse_ids()
	local owned_locations = {}
	for i = 1, #data.locations do
		local loc = data.locations[i]
		if loc.id and owned_ids[loc.id] then
			owned_locations[#owned_locations + 1] = loc
		end
	end
	state.set_location_index(state.config.location_index, #owned_locations)
	return owned_locations
end

function actions.get_selected_loc()
	return state.config.location_index
end

function actions.set_selected_loc(idx)
	state.set_location_index(idx, #actions.get_locations())
end

function actions.teleport()
	local locations = actions.get_locations()
	local loc = locations[state.config.location_index]
	if not loc then
		push("speccargo.notify.no_owned_warehouses", 2200)
		return false
	end
	return coords_teleport.run_coords_teleport(
		t("feature.speccargo.name"),
		t("speccargo.notify.teleported", { location = t(loc.label_key) }),
		loc.x,
		loc.y,
		loc.z,
		false,
		nil
	)
end

function actions.instant_sell()
	return jobs.run_guarded_job("sc_sell", function()
		local sell = cfg().scripts and cfg().scripts.sell or {}
		if not safe_access.is_script_running(sell.name) then
			push("speccargo.notify.sell_start_first", 2200)
			return
		end
		local ok1 = safe_access.set_local_int(sell.name, sell.timer_offset, sell.timer_value)
		local ok2 = safe_access.set_local_int(sell.name, sell.state_offset, sell.state_value)
		push((ok1 and ok2) and "speccargo.notify.sell_ok" or "speccargo.notify.sell_failed", 2200)
	end, function()
		push("speccargo.notify.sell_running", 1500)
	end)
end

function actions.fill_cargo()
	if state.fill.active then
		push("speccargo.notify.fill_running", 1500)
		return false
	end
	local full, has_owned = get_fullness_state()
	if not has_owned then
		push("speccargo.notify.no_owned_warehouses", 2200)
		return false
	end
	if full then
		push("speccargo.notify.cargo_full", 2000)
		return false
	end
	state.set_fill_active(true)
	push("speccargo.notify.fill_started", 2000)
	return true
end

function actions.set_fill_loop(enabled, silent)
	enabled = enabled == true
	if enabled then
		if state.fill.active then
			if not silent then
				push("speccargo.notify.fill_running", 1500)
			end
			return true
		end
		local full, has_owned = get_fullness_state()
		if not has_owned then
			if not silent then
				push("speccargo.notify.no_owned_warehouses", 2200)
			end
			return false
		end
		if full then
			state.set_fill_active(false)
			if not silent then
				push("speccargo.notify.cargo_full", 2000)
			end
			return false
		end
		state.set_fill_active(true)
		if not silent then
			push("speccargo.notify.fill_started", 2000)
		end
	else
		if not state.fill.active then
			if not silent then
				push("speccargo.notify.fill_not_running", 1500)
			end
			return false
		end
		state.set_fill_active(false)
		if not silent then
			push("speccargo.notify.fill_stopped", 2000)
		end
	end
	return state.fill.active
end

function actions.stop_fill()
	if not state.fill.active then
		push("speccargo.notify.fill_not_running", 1500)
		return false
	end
	state.set_fill_active(false)
	push("speccargo.notify.fill_stopped", 2000)
	return true
end

function actions.get_fill_active()
	return state.fill.active == true
end

function actions.fill_tick_once()
	local full, has_owned = get_fullness_state()
	if not has_owned then
		push("speccargo.notify.no_owned_warehouses", 2200)
		return false
	end
	if full then
		push("speccargo.notify.cargo_full", 2000)
		return false
	end
	local ok = supplier_pulse_once()
	push(ok and "speccargo.notify.fill_tick_ok" or "speccargo.notify.fill_tick_failed", 2000)
	return ok
end

function actions.tick_fill_cargo()
	if not state.fill.active then
		return false
	end
	local full, has_owned = get_fullness_state()
	if not has_owned then
		state.set_fill_active(false)
		push("speccargo.notify.no_owned_warehouses", 2200)
		return false
	end
	if full then
		state.set_fill_active(false)
		push("speccargo.notify.fill_complete", 2200)
		return false
	end
	return supplier_pulse_once()
end

function actions.set_disable_raids(enabled, silent)
	local tunables = cfg().tunables or {}
	local defaults = cfg().defaults or {}
	if enabled then
		if state.protections.raids_default == nil then
			state.protections.raids_default =
				safe_access.get_tunable_int(tunables.disable_raids, defaults.raids_default)
		end
		safe_access.set_tunable_int(tunables.disable_raids, defaults.raids_disabled)
		state.set_raids_active(true)
	else
		safe_access.set_tunable_int(tunables.disable_raids, state.protections.raids_default or defaults.raids_default)
		state.set_raids_active(false)
	end
	if not silent then
		push(enabled and "speccargo.notify.raids_disabled" or "speccargo.notify.raids_restored", 2000)
	end
	return state.protections.raids_active
end

function actions.get_raids_active()
	return state.protections.raids_active == true
end

function actions.set_disable_reminders(enabled, silent)
	local tunables = cfg().tunables or {}
	local defaults = cfg().defaults or {}
	if enabled then
		if state.protections.reminders_default == nil then
			state.protections.reminders_default =
				safe_access.get_tunable_int(tunables.reminders, defaults.reminder_cooldown_default)
		end
		safe_access.set_tunable_int(tunables.reminders, defaults.reminder_cooldown_disabled)
		state.set_reminders_active(true)
	else
		safe_access.set_tunable_int(
			tunables.reminders,
			state.protections.reminders_default or defaults.reminder_cooldown_default
		)
		state.set_reminders_active(false)
	end
	if not silent then
		push(enabled and "speccargo.notify.reminders_disabled" or "speccargo.notify.reminders_restored", 2000)
	end
	return state.protections.reminders_active
end

function actions.get_reminders_active()
	return state.protections.reminders_active == true
end

function actions.apply_current_state(silent)
	state.set_location_index(state.config.location_index, #actions.get_locations())
	actions.set_disable_raids(state.protections.raids_active, true)
	actions.set_disable_reminders(state.protections.reminders_active, true)
	if state.fill.active then
		local full, has_owned = get_fullness_state()
		if full or not has_owned then
			state.set_fill_active(false)
		end
	end
	if not silent then
		push("speccargo.notify.preset_state_applied", 2000)
	end
	return true
end

return actions
