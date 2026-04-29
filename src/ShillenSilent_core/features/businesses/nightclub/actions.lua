local safe_access = require("ShillenSilent_core.core.safe_access")
local business_runtime = require("ShillenSilent_core.core.business_runtime")
local notify_core = require("ShillenSilent_core.core.notify")
local i18n = require("ShillenSilent_core.i18n")
local offsets = require("ShillenSilent_core.data.offsets.resolver")
local blip_teleport = require("ShillenSilent_core.shared.blip_teleport")
local coords_teleport = require("ShillenSilent_core.shared.coords_teleport")
local data = require("ShillenSilent_core.features.businesses.nightclub.data")
local state = require("ShillenSilent_core.features.businesses.nightclub.state")

local actions = {}

local function cfg()
	return offsets.feature(data.feature_id)
end

local t = i18n.t

local push = notify_core.feature("feature.nightclub.name")

local function owned_location()
	local stats = cfg().stats or {}
	local id = safe_access.get_mp_stat_int(stats.owned, 0)
	local loc = data.location_by_id(id)
	return loc
end

local function product_stat(slot)
	local stats = cfg().stats or {}
	return tostring(stats.product_base or "") .. tostring(slot)
end

local function product_by_key(key)
	for i = 1, #data.product_slots do
		local product = data.product_slots[i]
		if product.key == key then
			return product
		end
	end
	return nil
end

local function selected_tunables()
	local tunables = cfg().tunables or {}
	local target = state.config.fast_prod_target
	if target == "all" then
		return tunables.accrue_times or {}
	end
	local name = tunables.accrue_by_target and tunables.accrue_by_target[target]
	for i = 1, #(tunables.accrue_times or {}) do
		local entry = tunables.accrue_times[i]
		if entry.name == name then
			return { entry }
		end
	end
	return {}
end

local function restore_selected_tunables()
	local ok = true
	for _, tunable in ipairs(selected_tunables()) do
		ok = safe_access.set_tunable_int(tunable.name, tunable.default) and ok
	end
	return ok
end

local function apply_sale_price()
	local offsets_cfg = cfg()
	local tunables = offsets_cfg.tunables or {}
	local price_tunables = tunables.price or {}
	local price = 4000000
	local ok = true
	for _, product in ipairs(data.product_slots) do
		local stock = safe_access.get_mp_stat_int(product_stat(product.slot), 0) or 0
		if stock > 0 and price_tunables[product.key] then
			ok = safe_access.set_tunable_int(price_tunables[product.key], math.floor(price / stock)) and ok
		end
	end
	return ok
end

local function restore_sale_price()
	local tunables = cfg().tunables or {}
	local defaults = {
		weapons = 5000,
		coke = 27000,
		meth = 11475,
		weed = 2025,
		docs = 1350,
		cash = 4725,
		cargo = 10000,
	}
	local ok = true
	for key, name in pairs(tunables.price or {}) do
		ok = safe_access.set_tunable_int(name, defaults[key]) and ok
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
	local cfg_data = cfg()
	return blip_teleport.teleport_to_blip_with_job(
		cfg_data.blips and cfg_data.blips.entrance,
		t("feature.nightclub.name"),
		t("nightclub.notify.teleported"),
		t("nightclub.notify.entrance_missing"),
		{ fallback_coords = loc, fallback_message = t("nightclub.notify.teleported") }
	)
end

function actions.production_tick_all()
	local any_ok = false
	for i = 1, #data.product_slots do
		local product = data.product_slots[i]
		local cur = safe_access.get_mp_stat_int(product_stat(product.slot), 0) or 0
		if cur < product.cap then
			any_ok = safe_access.set_mp_stat_int(product_stat(product.slot), math.min(cur + 1, product.cap)) or any_ok
		end
	end
	push(any_ok and "nightclub.notify.production_tick_ok" or "nightclub.notify.production_tick_full", 2000)
	return any_ok
end

function actions.production_tick()
	local target = state.config.fast_prod_target
	if target == "all" then
		return actions.production_tick_all()
	end

	local product = product_by_key(target)
	if not product then
		return actions.production_tick_all()
	end

	local cur = safe_access.get_mp_stat_int(product_stat(product.slot), 0) or 0
	if cur >= product.cap then
		push("nightclub.notify.production_tick_target_full", 2000, { target = t(product.label_key) })
		return false
	end

	local ok = safe_access.set_mp_stat_int(product_stat(product.slot), math.min(cur + 1, product.cap))
	push(
		ok and "nightclub.notify.production_tick_target_ok" or "nightclub.notify.production_tick_failed",
		2000,
		{ target = t(product.label_key) }
	)
	return ok
end

function actions.set_sale_price_loop(enabled, silent)
	state.set_sale_price_active(enabled == true)
	local ok = state.config.sale_price_active and apply_sale_price() or restore_sale_price()
	if not silent then
		push(
			ok
					and (state.config.sale_price_active and "nightclub.notify.sale_price_on" or "nightclub.notify.sale_price_off")
				or "nightclub.notify.sale_price_failed",
			2200
		)
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

function actions.set_fast_production(enabled, silent)
	enabled = enabled == true
	if not enabled then
		restore_selected_tunables()
	end
	state.set_fast_production(enabled)
	if not silent then
		push(enabled and "nightclub.notify.fast_enabled" or "nightclub.notify.fast_disabled", 2000)
	end
	return state.fast_production.active
end

function actions.tick_fast_production()
	if not state.fast_production.active then
		if state.fast_production.status == data.status.running then
			state.set_fast_status(data.status.stopped)
		end
		return false
	end
	local defaults = cfg().defaults or {}
	for _, tunable in ipairs(selected_tunables()) do
		safe_access.set_tunable_int(tunable.name, defaults.fast_accrue_time)
	end
	state.set_fast_status(data.status.running)
	return true
end

function actions.get_fast_prod_active()
	return state.fast_production.active == true
end

function actions.get_fast_prod_status()
	if state.fast_production.active then
		return t(
			"nightclub.status.running_target",
			{ target = t("nightclub.product." .. state.config.fast_prod_target) }
		)
	end
	return t(data.status_label_key(state.fast_production.status))
end

function actions.get_fast_product_options()
	return data.localized_options(data.fast_product_options, t)
end

function actions.get_fast_prod_target()
	return state.config.fast_prod_target
end

function actions.set_fast_prod_target(target)
	local was_active = state.fast_production.active
	if was_active then
		actions.set_fast_production(false, true)
	end
	state.set_fast_prod_target(target)
	if was_active then
		actions.set_fast_production(true, true)
	end
	return state.config.fast_prod_target
end

function actions.safe_collect()
	local offsets_cfg = cfg()
	local stats = offsets_cfg.stats or {}
	local value = safe_access.get_mp_stat_int(stats.safe_cash_value, 0) or 0
	if value <= 0 then
		push("nightclub.notify.safe_empty", 2000)
		return false
	end

	local globals = offsets_cfg.globals or {}
	local ok = safe_access.set_global_bool(globals.safe_collect, true)
	push(ok and "nightclub.notify.safe_collect_ok" or "nightclub.notify.safe_collect_failed", 2000)
	return ok
end

function actions.safe_fill()
	local offsets_cfg = cfg()
	local stats = offsets_cfg.stats or {}
	local limits = offsets_cfg.limits or {}
	local globals = offsets_cfg.globals or {}
	local max_value = tonumber(limits.safe_max) or 250000
	local ok = safe_access.set_mp_stat_int(stats.safe_cash_value, max_value)
	if globals.safe_top_range then
		for idx = globals.safe_top_range.first, globals.safe_top_range.last do
			ok = safe_access.set_global_int(idx, max_value) and ok
		end
	end
	push(ok and "nightclub.notify.safe_fill_ok" or "nightclub.notify.safe_fill_failed", 2000)
	return ok
end

function actions.set_popularity_max()
	state.set_popularity_editor_value(data.popularity.max)
	local stats = cfg().stats or {}
	local ok = safe_access.set_mp_stat_int(stats.popularity, data.popularity.max)
	push(ok and "nightclub.notify.popularity_max_ok" or "nightclub.notify.popularity_failed", 2000)
	return ok
end

function actions.set_popularity_min()
	state.set_popularity_editor_value(data.popularity.min)
	local stats = cfg().stats or {}
	local ok = safe_access.set_mp_stat_int(stats.popularity, data.popularity.min)
	push(ok and "nightclub.notify.popularity_min_ok" or "nightclub.notify.popularity_failed", 2000)
	return ok
end

function actions.set_popularity(value, silent)
	local target = data.clamp_popularity(value)
	state.set_popularity_editor_value(target)
	local stats = cfg().stats or {}
	local ok = safe_access.set_mp_stat_int(stats.popularity, target)
	if not silent then
		push(ok and "nightclub.notify.popularity_ok" or "nightclub.notify.popularity_failed", 2000, {
			value = tostring(target),
		})
	end
	return ok
end

function actions.get_popularity_editor_value()
	return state.config.popularity_editor_value
end

function actions.set_popularity_editor_value(value)
	state.set_popularity_editor_value(value)
end

function actions.apply_popularity_editor_value()
	return actions.set_popularity(state.config.popularity_editor_value, false)
end

function actions.set_popularity_lock_active(enabled, silent)
	state.set_popularity_lock_active(enabled == true)
	if state.popularity.lock_active then
		actions.set_popularity(state.config.popularity_editor_value, true)
	end
	if not silent then
		push(
			state.popularity.lock_active and "nightclub.notify.popularity_lock_on"
				or "nightclub.notify.popularity_lock_off",
			2000
		)
	end
	return state.popularity.lock_active
end

function actions.get_popularity_lock_active()
	return state.popularity.lock_active == true
end

function actions.popularity_lock_tick()
	if not state.popularity.lock_active then
		return false
	end
	local stats = cfg().stats or {}
	local cur = safe_access.get_mp_stat_int(stats.popularity, 0) or 0
	local target = data.clamp_popularity(state.config.popularity_editor_value)
	local min_allowed = math.max(data.popularity.min, target - data.popularity.lock_tolerance)
	if cur < min_allowed then
		return actions.set_popularity(target, true)
	end
	return false
end

function actions.safe_unbrick()
	local globals = cfg().globals or {}
	local stats = cfg().stats or {}
	local any_ok = false
	for idx = globals.safe_top_range.first, globals.safe_top_range.last do
		any_ok = safe_access.set_global_int(idx, 1) or any_ok
	end
	safe_access.set_mp_stat_int(stats.safe_pay_time_left, -1)
	util.yield(3000)
	any_ok = safe_access.set_global_int(globals.safe_collect, 1) or any_ok
	push(any_ok and "nightclub.notify.safe_unbrick_ok" or "nightclub.notify.safe_unbrick_failed", 2200)
	return any_ok
end

function actions.skip_setup()
	local offsets_cfg = cfg()
	local packed = offsets_cfg.packed_stats or {}
	local setup = packed.setup or {}
	local natives = offsets_cfg.natives or {}
	local ok = true
	for _, idx in pairs(setup) do
		ok = business_runtime.write_packed_bool(idx, true, packed.character_slots, natives.stat_set_packed_bool) and ok
	end
	push(ok and "nightclub.notify.setup_ok" or "nightclub.notify.setup_failed", 2200)
	return ok
end

function actions.teleport_computer()
	local coords = cfg().coords and cfg().coords.computer
	if not coords then
		return false
	end
	return coords_teleport.run_coords_teleport(
		t("feature.nightclub.name"),
		t("nightclub.notify.teleported_computer"),
		coords.x,
		coords.y,
		coords.z,
		false,
		nil
	)
end

function actions.open_computer()
	local ok = business_runtime.start_script(cfg().scripts and cfg().scripts.laptop)
	push(ok and "nightclub.notify.open_computer_ok" or "nightclub.notify.open_computer_failed", 2000)
	return ok
end

function actions.set_cooldowns(enabled, silent)
	state.set_cooldowns_active(enabled == true)
	local tunables = cfg().tunables or {}
	local ok = state.config.cooldowns_active and business_runtime.apply_tunables(tunables.cooldowns, 0)
		or business_runtime.restore_tunables(tunables.cooldowns)
	if not silent then
		push(
			ok
					and (state.config.cooldowns_active and "nightclub.notify.cooldowns_on" or "nightclub.notify.cooldowns_off")
				or "nightclub.notify.cooldowns_failed",
			2000
		)
	end
	return state.config.cooldowns_active
end

function actions.get_cooldowns_active()
	return state.config.cooldowns_active == true
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
		push(enabled and "nightclub.notify.raids_disabled" or "nightclub.notify.raids_restored", 2000)
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
		push(enabled and "nightclub.notify.reminders_disabled" or "nightclub.notify.reminders_restored", 2000)
	end
	return state.protections.reminders_active
end

function actions.get_reminders_active()
	return state.protections.reminders_active == true
end

function actions.apply_current_state(silent)
	state.set_location_index(state.config.location_index)
	state.set_fast_prod_target(state.config.fast_prod_target)
	actions.set_sale_price_loop(state.config.sale_price_active, true)
	actions.set_cooldowns(state.config.cooldowns_active, true)
	actions.set_fast_production(state.fast_production.active, true)
	actions.set_popularity_lock_active(state.popularity.lock_active, true)
	actions.set_disable_raids(state.protections.raids_active, true)
	actions.set_disable_reminders(state.protections.reminders_active, true)
	if not silent then
		push("nightclub.notify.preset_state_applied", 2000)
	end
	return true
end

return actions
