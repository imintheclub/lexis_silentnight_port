local jobs = require("ShillenSilent_core.core.jobs")
local safe_access = require("ShillenSilent_core.core.safe_access")
local business_runtime = require("ShillenSilent_core.core.business_runtime")
local notify_core = require("ShillenSilent_core.core.notify")
local i18n = require("ShillenSilent_core.i18n")
local offsets = require("ShillenSilent_core.data.offsets.resolver")
local coords_teleport = require("ShillenSilent_core.shared.coords_teleport")
local blip_teleport = require("ShillenSilent_core.shared.blip_teleport")
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
	return business_runtime.write_packed_bool_range(
		packed.supply_first,
		packed.supply_last,
		true,
		packed.character_slots,
		natives.stat_set_packed_bool
	)
end

local function threshold_value(base_price, i)
	local denominators = { 1, 2, 3, 5, 7, 9, 14, 19, 24, 29, 34, 39, 44, 49, 59, 69, 79, 89, 99, 110, 111 }
	return math.floor(base_price / (denominators[i] or 1))
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

function actions.teleport_office()
	local blips = cfg().blips or {}
	return blip_teleport.teleport_to_blip_with_job(
		blips.office,
		t("feature.speccargo.name"),
		t("speccargo.notify.teleported_office"),
		t("speccargo.notify.office_missing")
	)
end

function actions.teleport_computer()
	local coords = cfg().coords and cfg().coords.computer
	if not coords then
		return false
	end
	return coords_teleport.run_coords_teleport(
		t("feature.speccargo.name"),
		t("speccargo.notify.teleported_computer"),
		coords.x,
		coords.y,
		coords.z,
		false,
		nil
	)
end

function actions.teleport_warehouse_blip()
	local blips = cfg().blips or {}
	return blip_teleport.teleport_to_blip_with_job(
		blips.warehouse,
		t("feature.speccargo.name"),
		t("speccargo.notify.teleported_warehouse"),
		t("speccargo.notify.warehouse_missing")
	)
end

function actions.instant_sell()
	return jobs.run_guarded_job("sc_sell", function()
		local sell = cfg().scripts and cfg().scripts.sell or {}
		if not safe_access.is_script_running(sell.name) then
			push("speccargo.notify.sell_start_first", 2200)
			return
		end

		local tunables = cfg().tunables or {}
		if not state.config.no_crateback then
			supplier_pulse_once()
		end
		business_runtime.set_xp_multiplier(state.config.no_xp, tunables.xp_multiplier)
		local ok1 = safe_access.set_local_int(sell.name, sell.timer_offset, sell.timer_value)
		local ok2 = safe_access.set_local_int(sell.name, sell.state_offset, sell.state_value)
		util.yield(2000)
		ok1 = safe_access.set_local_int(sell.name, sell.timer_offset, sell.timer_value) and ok1
		push((ok1 and ok2) and "speccargo.notify.sell_ok" or "speccargo.notify.sell_failed", 2200)
	end, function()
		push("speccargo.notify.sell_running", 1500)
	end)
end

function actions.set_sale_price_loop(enabled, silent)
	state.set_sale_price_active(enabled == true)
	local tunables = cfg().tunables or {}
	local ok = true
	if state.config.sale_price_active then
		for i, entry in ipairs(tunables.price_thresholds or {}) do
			ok = safe_access.set_tunable_int(entry.name, threshold_value(6000000, i)) and ok
		end
	else
		ok = business_runtime.restore_tunables(tunables.price_thresholds)
	end
	if not silent then
		push(
			ok
					and (state.config.sale_price_active and "speccargo.notify.sale_price_on" or "speccargo.notify.sale_price_off")
				or "speccargo.notify.sale_price_failed",
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
	local tunables = cfg().tunables or {}
	local ok = true
	for i, entry in ipairs(tunables.price_thresholds or {}) do
		ok = safe_access.set_tunable_int(entry.name, threshold_value(6000000, i)) and ok
	end
	return ok
end

function actions.set_no_xp(enabled, silent)
	state.set_no_xp(enabled == true)
	if not silent then
		push(state.config.no_xp and "speccargo.notify.no_xp_on" or "speccargo.notify.no_xp_off", 2000)
	end
	return state.config.no_xp
end

function actions.get_no_xp()
	return state.config.no_xp == true
end

function actions.set_no_crateback(enabled, silent)
	state.set_no_crateback(enabled == true)
	if not silent then
		push(
			state.config.no_crateback and "speccargo.notify.no_crateback_on" or "speccargo.notify.no_crateback_off",
			2000
		)
	end
	return state.config.no_crateback
end

function actions.get_no_crateback()
	return state.config.no_crateback == true
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

function actions.supply_crates()
	local ok = supplier_pulse_once()
	push(ok and "speccargo.notify.supply_ok" or "speccargo.notify.supply_failed", 2000)
	return ok
end

function actions.set_supplier_loop(enabled, silent)
	state.set_supplier_active(enabled == true)
	if not silent then
		push(state.config.supplier_active and "speccargo.notify.supplier_on" or "speccargo.notify.supplier_off", 2000)
	end
	return state.config.supplier_active
end

function actions.get_supplier_loop_active()
	return state.config.supplier_active == true
end

function actions.tick_supplier()
	if not state.config.supplier_active then
		return false
	end
	return supplier_pulse_once()
end

function actions.set_crate_amount(value)
	state.set_crate_amount(value)
	return state.config.crate_amount
end

function actions.get_crate_amount()
	return state.config.crate_amount
end

function actions.max_crate_amount()
	state.set_crate_amount(data.crates.max)
	push("speccargo.notify.crate_amount_max", 2000)
	return true
end

function actions.instant_buy()
	return jobs.run_guarded_job("sc_buy", function()
		local buy = cfg().scripts and cfg().scripts.buy or {}
		if not safe_access.is_script_running(buy.name) then
			push("speccargo.notify.buy_start_first", 2200)
			return
		end
		local amount = data.clamp_crate_amount(state.config.crate_amount)
		local ok = true
		ok = safe_access.set_local_int(buy.name, buy.amount_offset, amount) and ok
		ok = safe_access.set_local_int(buy.name, buy.finish1_offset, 1) and ok
		ok = safe_access.set_local_int(buy.name, buy.finish2_offset, 6) and ok
		ok = safe_access.set_local_int(buy.name, buy.finish3_offset, 4) and ok
		push(ok and "speccargo.notify.buy_ok" or "speccargo.notify.buy_failed", 2200)
	end, function()
		push("speccargo.notify.buy_running", 1500)
	end)
end

function actions.set_cooldowns(enabled, silent)
	state.set_cooldowns_active(enabled == true)
	local tunables = cfg().tunables or {}
	local ok = state.config.cooldowns_active and business_runtime.apply_tunables(tunables.cooldowns, 0)
		or business_runtime.restore_tunables(tunables.cooldowns)
	if not silent then
		push(
			ok
					and (state.config.cooldowns_active and "speccargo.notify.cooldowns_on" or "speccargo.notify.cooldowns_off")
				or "speccargo.notify.cooldowns_failed",
			2000
		)
	end
	return state.config.cooldowns_active
end

function actions.get_cooldowns_active()
	return state.config.cooldowns_active == true
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
	actions.set_sale_price_loop(state.config.sale_price_active, true)
	actions.set_supplier_loop(state.config.supplier_active, true)
	actions.set_cooldowns(state.config.cooldowns_active, true)
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
