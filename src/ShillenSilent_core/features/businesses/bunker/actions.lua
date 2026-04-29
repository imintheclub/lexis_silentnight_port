local jobs = require("ShillenSilent_core.core.jobs")
local safe_access = require("ShillenSilent_core.core.safe_access")
local business_runtime = require("ShillenSilent_core.core.business_runtime")
local notify_core = require("ShillenSilent_core.core.notify")
local i18n = require("ShillenSilent_core.i18n")
local offsets = require("ShillenSilent_core.data.offsets.current")
local blip_teleport = require("ShillenSilent_core.shared.blip_teleport")
local coords_teleport = require("ShillenSilent_core.shared.coords_teleport")
local data = require("ShillenSilent_core.features.businesses.bunker.data")
local state = require("ShillenSilent_core.features.businesses.bunker.state")

local actions = {}

local function cfg()
	return offsets[data.feature_id] or {}
end

local t = i18n.t

local push = notify_core.feature("feature.bunker.name")

local function offset_with_delta(field, delta)
	delta = tonumber(delta) or 0
	if type(field) == "number" then
		return field + delta
	end
	if type(field) == "table" then
		return { ee = field.ee + delta, legacy = field.legacy + delta }
	end
	return nil
end

local function fill_supply_slot()
	local supply = cfg().supply or {}
	local base = supply.base
	local slot = supply.slot
	local offset = offset_with_delta(base, slot)
	if not offset or type(slot) ~= "number" then
		return false
	end

	local ok = true
	for _ = 1, tonumber(supply.fill_repeats) or 7 do
		ok = safe_access.set_global_int_variants(offset, 1) and ok
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
	if type(slot) ~= "number" then
		return false
	end

	local supply_offset = offset_with_delta(base, slot)
	local trig1 = offset_with_delta(timer_root, 1 + (slot - 1) * 2)
	local trig2 = offset_with_delta(trig1, 1)
	if not supply_offset or not trig1 or not trig2 then
		return false
	end
	local ok = true
	ok = safe_access.set_global_int_variants(supply_offset, 1) and ok
	ok = safe_access.set_global_int_variants(trig1, 0) and ok
	ok = safe_access.set_global_int_variants(trig2, 1) and ok
	return ok
end

local function apply_sale_price()
	local offsets_cfg = cfg()
	local stats = offsets_cfg.stats or {}
	local tunables = offsets_cfg.tunables or {}
	local sale = tunables.sale_price or {}
	local stock = safe_access.get_mp_stat_int(stats.stock, 0) or 0
	if stock <= 0 then
		apply_production_tick()
		util.yield(1000)
		stock = safe_access.get_mp_stat_int(stats.stock, 0) or 0
	end
	if stock <= 0 then
		return false
	end

	local target = math.floor((2500000 / 1.5) / stock)
	local ok = true
	ok = safe_access.set_tunable_int(sale.product_value, target) and ok
	ok = safe_access.set_tunable_int(sale.staff_upgraded, 0) and ok
	ok = safe_access.set_tunable_int(sale.equipment_upgraded, 0) and ok
	return ok and stats.stock ~= nil
end

local function restore_sale_price()
	local offsets_cfg = cfg()
	local tunables = offsets_cfg.tunables or {}
	local sale = tunables.sale_price or {}
	local defaults = offsets_cfg.defaults or {}
	local ok = true
	ok = safe_access.set_tunable_int(sale.product_value, defaults.product_value) and ok
	ok = safe_access.set_tunable_int(sale.staff_upgraded, defaults.staff_upgraded) and ok
	ok = safe_access.set_tunable_int(sale.equipment_upgraded, defaults.equipment_upgraded) and ok
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

function actions.set_sale_price_loop(enabled, silent)
	state.set_sale_price_active(enabled == true)
	if not state.config.sale_price_active then
		local ok = restore_sale_price()
		if not silent then
			push(ok and "bunker.notify.sale_price_off" or "bunker.notify.sale_price_failed", 2000)
		end
		return false
	end
	local ok = apply_sale_price()
	if not silent then
		push(ok and "bunker.notify.sale_price_on" or "bunker.notify.sale_price_failed", 2200)
	end
	return state.config.sale_price_active
end

function actions.get_sale_price_loop_active()
	return state.config.sale_price_active == true
end

function actions.tick_sale_price()
	if not state.config.sale_price_active then
		return false
	end
	return apply_sale_price()
end

function actions.set_no_xp(enabled, silent)
	state.set_no_xp(enabled == true)
	if not silent then
		push(state.config.no_xp and "bunker.notify.no_xp_on" or "bunker.notify.no_xp_off", 2000)
	end
	return state.config.no_xp
end

function actions.get_no_xp()
	return state.config.no_xp == true
end

function actions.set_supplier_loop(enabled, silent)
	state.set_supplier_active(enabled == true)
	if not state.config.supplier_active then
		local supply = cfg().supply or {}
		local offset = offset_with_delta(supply.base, supply.slot)
		if offset and type(supply.slot) == "number" then
			safe_access.set_global_int_variants(offset, 0)
		end
		if not silent then
			push("bunker.notify.supplier_off", 2000)
		end
		return false
	end
	if not silent then
		push("bunker.notify.supplier_on", 2000)
	end
	return true
end

function actions.get_supplier_loop_active()
	return state.config.supplier_active == true
end

function actions.tick_supplier()
	if not state.config.supplier_active then
		return false
	end
	local laptop = cfg().scripts and cfg().scripts.laptop or {}
	if safe_access.is_script_running(laptop.name) then
		return false
	end
	return apply_production_tick()
end

function actions.instant_sell()
	return jobs.run_guarded_job("bunker_sell", function()
		local sell = cfg().scripts and cfg().scripts.sell or {}
		if not safe_access.is_script_running(sell.name) then
			push("bunker.notify.sell_start_first", 2200)
			return
		end

		local tunables = cfg().tunables or {}
		business_runtime.set_xp_multiplier(state.config.no_xp, tunables.xp_multiplier)
		local ok = safe_access.set_local_int_variants(sell.name, sell.offset, sell.value)
		push(ok and "bunker.notify.sell_ok" or "bunker.notify.sell_failed", 2200)
	end, function()
		push("bunker.notify.sell_running", 1500)
	end)
end

function actions.teleport_laptop()
	local coords = cfg().coords and cfg().coords.laptop
	if not coords then
		return false
	end
	return coords_teleport.run_coords_teleport(
		t("feature.bunker.name"),
		t("bunker.notify.teleported_laptop"),
		coords.x,
		coords.y,
		coords.z,
		false,
		nil
	)
end

function actions.open_laptop()
	local ok = business_runtime.start_script(cfg().scripts and cfg().scripts.laptop)
	push(ok and "bunker.notify.open_laptop_ok" or "bunker.notify.open_laptop_failed", 2000)
	return ok
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
	actions.set_sale_price_loop(state.config.sale_price_active, true)
	actions.set_supplier_loop(state.config.supplier_active, true)
	actions.set_disable_raids(state.protections.raids_active, true)
	actions.set_disable_reminders(state.protections.reminders_active, true)
	actions.set_fast_production(state.fast_production.active, true)
	if not silent then
		push("bunker.notify.preset_state_applied", 2000)
	end
	return true
end

return actions
