local jobs = require("ShillenSilent_core.core.jobs")
local safe_access = require("ShillenSilent_core.core.safe_access")
local notify_core = require("ShillenSilent_core.core.notify")
local i18n = require("ShillenSilent_core.i18n")
local offsets = require("ShillenSilent_core.data.offsets.resolver")
local blip_teleport = require("ShillenSilent_core.shared.blip_teleport")
local data = require("ShillenSilent_core.features.businesses.bunker.data")
local state = require("ShillenSilent_core.features.businesses.bunker.state")

local actions = {}

local function cfg()
	return offsets.feature(data.feature_id)
end

local t = i18n.t

local push = notify_core.feature("feature.bunker.name")

local function fill_supply_slot()
	local supply = cfg().supply or {}
	local base = supply.base
	local slot = supply.slot
	if type(base) ~= "number" or type(slot) ~= "number" then
		return false
	end

	local ok = true
	for _ = 1, tonumber(supply.fill_repeats) or 7 do
		ok = safe_access.set_global_int(base + slot, 1) and ok
		util.yield(tonumber(supply.fill_yield_ms) or 5)
	end
	return ok
end

local function apply_production_tick()
	local supply = cfg().supply or {}
	local production = cfg().production or {}
	local base = supply.base
	local slot = supply.slot
	local timer_root = production.timer_root
	if type(base) ~= "number" or type(slot) ~= "number" or type(timer_root) ~= "number" then
		return false
	end

	local trig1 = timer_root + 1 + (slot - 1) * 2
	local trig2 = trig1 + 1
	local ok = true
	ok = safe_access.set_global_int(base + slot, 1) and ok
	ok = safe_access.set_global_int(trig1, 0) and ok
	ok = safe_access.set_global_int(trig2, 1) and ok
	return ok
end

local function get_stock_units()
	local stats = cfg().stats or {}
	return safe_access.get_mp_stat_int(stats.stock, 0) or 0
end

local function is_full()
	local limits = cfg().limits or {}
	return get_stock_units() >= (tonumber(limits.max_capacity) or 0)
end

local function owned_location()
	local stats = cfg().stats or {}
	local id = safe_access.get_mp_stat_int(stats.owned, 0)
	local loc = data.location_by_id(id)
	return loc
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
		t("feature.bunker.name"),
		t("bunker.notify.teleported"),
		t("bunker.notify.entrance_missing"),
		{
			fallback_coords = loc,
			fallback_message = t("bunker.notify.teleported"),
		}
	)
end

function actions.production_tick()
	local ok = apply_production_tick()
	push(ok and "bunker.notify.production_tick_ok" or "bunker.notify.production_tick_failed", 2000)
	return ok
end

function actions.refill_supplies()
	return jobs.run_guarded_job("bunker_refill", function()
		local ok = fill_supply_slot()
		push(ok and "bunker.notify.supplies_refill_ok" or "bunker.notify.supplies_refill_failed", 2000)
	end, function()
		push("bunker.notify.supplies_refill_running", 1500)
	end)
end

function actions.instant_sell()
	return jobs.run_guarded_job("bunker_sell", function()
		local sell = cfg().scripts and cfg().scripts.sell or {}
		if not safe_access.is_script_running(sell.name) then
			push("bunker.notify.sell_start_first", 2200)
			return
		end

		local ok = safe_access.set_local_int(sell.name, sell.offset, sell.value)
		push(ok and "bunker.notify.sell_ok" or "bunker.notify.sell_failed", 2200)
	end, function()
		push("bunker.notify.sell_running", 1500)
	end)
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
		push(enabled and "bunker.notify.raids_disabled" or "bunker.notify.raids_restored", 2000)
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
		push(enabled and "bunker.notify.reminders_disabled" or "bunker.notify.reminders_restored", 2000)
	end
	return state.protections.reminders_active
end

function actions.get_reminders_active()
	return state.protections.reminders_active == true
end

function actions.set_fast_production(enabled, silent)
	enabled = enabled == true
	if enabled and is_full() then
		state.set_fast_production(false)
		state.set_fast_status(data.status.full)
		if not silent then
			push("bunker.notify.stock_full", 2000)
		end
		return false
	end

	state.set_fast_production(enabled)
	if not silent then
		push(state.fast_production.active and "bunker.notify.fast_enabled" or "bunker.notify.fast_disabled", 2000)
	end
	return state.fast_production.active
end

function actions.get_fast_prod_active()
	return state.fast_production.active == true
end

function actions.get_fast_prod_status()
	return t(data.status_label_key(state.fast_production.status))
end

function actions.tick_fast_production()
	if not state.fast_production.active then
		if state.fast_production.status == data.status.running then
			state.set_fast_status(data.status.stopped)
		end
		return false
	end

	if is_full() then
		state.set_fast_production(false)
		state.set_fast_status(data.status.full)
		push("bunker.notify.fast_stopped_full", 2200)
		return false
	end

	state.set_fast_status(data.status.running)
	apply_production_tick()
	return true
end

function actions.apply_current_state(silent)
	state.set_location_index(state.config.location_index)
	actions.set_disable_raids(state.protections.raids_active, true)
	actions.set_disable_reminders(state.protections.reminders_active, true)
	actions.set_fast_production(state.fast_production.active, true)
	if not silent then
		push("bunker.notify.preset_state_applied", 2000)
	end
	return true
end

return actions
