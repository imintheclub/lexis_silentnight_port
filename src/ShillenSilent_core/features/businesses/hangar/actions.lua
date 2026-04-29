local jobs = require("ShillenSilent_core.core.jobs")
local safe_access = require("ShillenSilent_core.core.safe_access")
local business_runtime = require("ShillenSilent_core.core.business_runtime")
local notify_core = require("ShillenSilent_core.core.notify")
local i18n = require("ShillenSilent_core.i18n")
local offsets = require("ShillenSilent_core.data.offsets.resolver")
local blip_teleport = require("ShillenSilent_core.shared.blip_teleport")
local coords_teleport = require("ShillenSilent_core.shared.coords_teleport")
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
	return business_runtime.write_packed_bool(
		packed.cargo_available,
		true,
		packed.character_slots,
		natives.stat_set_packed_bool
	)
end

local function cargo_limit_global()
	local globals = cfg().globals or {}
	local base = tonumber(globals.cargo_limit_base)
	local stride = tonumber(globals.cargo_limit_stride) or 0
	if not base then
		return nil
	end
	return base + (business_runtime.player_id() * stride)
end

local function set_cargo_limit(value)
	local offset = cargo_limit_global()
	return offset ~= nil and safe_access.set_global_int(offset, math.floor(tonumber(value) or 0)) or false
end

local function apply_sale_price()
	local offsets_cfg = cfg()
	local tunables = offsets_cfg.tunables or {}
	local defaults = offsets_cfg.defaults or {}
	if
		safe_access.is_script_running(
			offsets_cfg.scripts and offsets_cfg.scripts.sell and offsets_cfg.scripts.sell.name
		)
	then
		return true
	end

	local stock = get_stock_units()
	if stock < 4 then
		supplier_tick()
		util.yield(1000)
		stock = get_stock_units()
	end
	if stock <= 0 then
		return false
	end

	local ok1 = safe_access.set_tunable_int(tunables.price, math.floor(4000000 / stock))
	local ok2 = safe_access.set_tunable_float(tunables.rons_cut, 0.0)
	return ok1 and ok2 and defaults.price ~= nil
end

local function restore_sale_price()
	local tunables = cfg().tunables or {}
	local defaults = cfg().defaults or {}
	local ok1 = safe_access.set_tunable_int(tunables.price, defaults.price)
	local ok2 = safe_access.set_tunable_float(tunables.rons_cut, defaults.rons_cut)
	return ok1 and ok2
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

function actions.set_sale_price_loop(enabled, silent)
	state.set_sale_price_active(enabled == true)
	if not state.config.sale_price_active then
		local ok = restore_sale_price()
		if not silent then
			push(ok and "hangar.notify.sale_price_off" or "hangar.notify.sale_price_failed", 2000)
		end
		return false
	end
	local ok = apply_sale_price()
	if not silent then
		push(ok and "hangar.notify.sale_price_on" or "hangar.notify.sale_price_failed", 2200)
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
		push(state.config.no_xp and "hangar.notify.no_xp_on" or "hangar.notify.no_xp_off", 2000)
	end
	return state.config.no_xp
end

function actions.get_no_xp()
	return state.config.no_xp == true
end

function actions.set_supplier_loop(enabled, silent)
	state.set_supplier_active(enabled == true)
	if not silent then
		push(state.config.supplier_active and "hangar.notify.supplier_on" or "hangar.notify.supplier_off", 2000)
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
	local laptop = cfg().scripts and cfg().scripts.laptop or {}
	if safe_access.is_script_running(laptop.name) or is_full() then
		return false
	end
	return supplier_tick()
end

function actions.set_pocket_active(enabled, silent)
	state.set_pocket_active(enabled == true)
	if not state.config.pocket_active then
		state.set_fill_active(false)
	end
	if not silent then
		push(state.config.pocket_active and "hangar.notify.pocket_on" or "hangar.notify.pocket_off", 2000)
	end
	return state.config.pocket_active
end

function actions.get_pocket_active()
	return state.config.pocket_active == true
end

function actions.set_pocket_stop_at(value)
	state.set_pocket_stop_at(value)
	return state.config.pocket_stop_at
end

function actions.get_pocket_stop_at()
	return state.config.pocket_stop_at
end

function actions.set_pocket_delay(value)
	state.set_pocket_delay(value)
	return state.config.pocket_delay
end

function actions.get_pocket_delay()
	return state.config.pocket_delay
end

function actions.set_cooldowns(enabled, silent)
	state.set_cooldowns_active(enabled == true)
	local tunables = cfg().tunables or {}
	local ok = state.config.cooldowns_active and business_runtime.apply_tunables(tunables.cooldowns, 0)
		or business_runtime.restore_tunables(tunables.cooldowns)
	if not silent then
		push(
			ok and (state.config.cooldowns_active and "hangar.notify.cooldowns_on" or "hangar.notify.cooldowns_off")
				or "hangar.notify.cooldowns_failed",
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

	if state.config.pocket_active then
		local stop_at = tonumber(state.config.pocket_stop_at) or 0
		local stock = get_stock_units()
		if stop_at > 0 and stock >= stop_at then
			set_cargo_limit(stock)
			state.set_fill_active(false)
			push("hangar.notify.fill_complete", 2000)
			return false
		end
		set_cargo_limit(0)
		local ok = supplier_tick()
		util.yield(math.floor((tonumber(state.config.pocket_delay) or 1.0) * 1000))
		return ok
	end

	if is_full() then
		state.set_fill_active(false)
		push("hangar.notify.fill_complete", 2000)
		return false
	end

	return supplier_tick()
end

function actions.instant_sell()
	return jobs.run_guarded_job("hangar_sell", function()
		local sell = cfg().scripts and cfg().scripts.sell or {}
		if not safe_access.is_script_running(sell.name) then
			push("hangar.notify.sell_start_first", 2200)
			return
		end

		local tunables = cfg().tunables or {}
		business_runtime.set_xp_multiplier(state.config.no_xp, tunables.xp_multiplier)
		local delivered = safe_access.get_local_int(sell.name, sell.delivered_offset, nil)
		local ok = delivered ~= nil and safe_access.set_local_int(sell.name, sell.to_deliver_offset, delivered)
		push(ok and "hangar.notify.sell_ok" or "hangar.notify.sell_failed", 2200)
	end, function()
		push("hangar.notify.sell_running", 1500)
	end)
end

function actions.teleport_laptop()
	local coords = cfg().coords and cfg().coords.laptop
	if not coords then
		return false
	end
	return coords_teleport.run_coords_teleport(
		t("feature.hangar.name"),
		t("hangar.notify.teleported_laptop"),
		coords.x,
		coords.y,
		coords.z,
		false,
		nil
	)
end

function actions.open_laptop()
	local ok = business_runtime.start_script(cfg().scripts and cfg().scripts.laptop)
	push(ok and "hangar.notify.open_laptop_ok" or "hangar.notify.open_laptop_failed", 2000)
	return ok
end

function actions.apply_current_state(silent)
	state.set_location_index(state.config.location_index)
	actions.set_sale_price_loop(state.config.sale_price_active, true)
	actions.set_supplier_loop(state.config.supplier_active, true)
	actions.set_cooldowns(state.config.cooldowns_active, true)
	if state.fill.active and is_full() then
		state.set_fill_active(false)
	end
	if not silent then
		push("hangar.notify.preset_state_applied", 2000)
	end
	return true
end

return actions
