local jobs = require("ShillenSilent_core.core.jobs")
local safe_access = require("ShillenSilent_core.core.safe_access")
local business_runtime = require("ShillenSilent_core.core.business_runtime")
local notify_core = require("ShillenSilent_core.core.notify")
local i18n = require("ShillenSilent_core.i18n")
local offsets = require("ShillenSilent_core.data.offsets.current")
local coords_teleport = require("ShillenSilent_core.shared.coords_teleport")
local data = require("ShillenSilent_core.features.businesses.mc.data")
local state = require("ShillenSilent_core.features.businesses.mc.state")
local native = require("natives")

local actions = {}

local function cfg()
	return offsets[data.feature_id] or {}
end

local t = i18n.t

local push_feature = notify_core.feature("feature.mc.name")

local function push_sub(sub, message_key, duration, vars)
	vars = vars or {}
	vars.business = t(sub.label_key)
	return notify_core.raw(t("mc.notify.title_sub", vars), t(message_key, vars), duration or 2200)
end

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

local function find_factoryslot_for_key(sub_key)
	local stats = cfg().stats or {}
	local prefix = stats.factory_slot_prefix
	if type(prefix) ~= "string" then
		return nil
	end
	for i = 0, 4 do
		local prop_id = safe_access.get_mp_stat_int(prefix .. tostring(i), 0)
		if prop_id and prop_id > 0 and data.prop_id_to_key[prop_id] == sub_key then
			return i, prop_id
		end
	end
	return nil
end

local function get_blip_coords(sprite_id)
	local natives = cfg().natives or {}
	if not sprite_id then
		return nil
	end

	local ok_blip, blip = pcall(function()
		return native.get_first_blip_info_id(sprite_id)
	end)
	if not ok_blip or not blip or blip == 0 then
		return nil
	end

	local ok_exists, exists = pcall(function()
		return native.does_blip_exist(blip)
	end)
	if not ok_exists or not exists then
		return nil
	end

	local ok_vec, vec = pcall(function()
		-- TODO(Lexis API): current native wrappers do not expose GET_BLIP_COORDS.
		-- GET_BLIP_COORDS 0x586AFE3FF72D996E(blipHandle:int) -> scr_vec3.
		return invoker.call(natives.get_blip_coords, blip).scr_vec3
	end)
	if not ok_vec or not vec then
		return nil
	end

	local x, y, z = vec.x, vec.y, vec.z
	if not x or not y or not z or (x == 0 and y == 0 and z == 0) then
		return nil
	end
	return x, y, z
end

local function fill_supply_slot(slot)
	local supply = cfg().supply or {}
	local base = supply.base
	local offset = offset_with_delta(base, slot)
	if not offset then
		return false
	end

	local ok = true
	for _ = 1, tonumber(supply.fill_repeats) or 7 do
		ok = safe_access.set_global_int_variants(offset, 1) and ok
		util.yield(tonumber(supply.fill_yield_ms) or 5)
	end
	return ok
end

local function apply_production_tick(slot)
	local supply = cfg().supply or {}
	local production = cfg().production or {}
	local base = supply.base
	local timer_root = production.timer_root
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

function actions.production_tick(sub_key)
	local sub = data.find_sub(sub_key)
	if not sub then
		return false
	end

	local factoryslot = find_factoryslot_for_key(sub_key)
	if factoryslot == nil then
		push_sub(sub, "mc.notify.not_owned", 2000)
		return false
	end

	local ok = apply_production_tick(factoryslot + 1)
	push_sub(sub, ok and "mc.notify.production_tick_ok" or "mc.notify.production_tick_failed", 2000)
	return ok
end

function actions.teleport(sub_key)
	local sub = data.find_sub(sub_key)
	if not sub then
		return false
	end

	local x, y, z
	local blip = cfg().blips and cfg().blips[sub_key] or nil
	if blip then
		x, y, z = get_blip_coords(blip)
	end

	if not x then
		local _, prop_id = find_factoryslot_for_key(sub_key)
		if prop_id then
			local tier = math.floor((prop_id - 1) / 5) + 1
			local locs = data.locations[sub_key]
			local loc = locs and locs[tier]
			if loc then
				x, y, z = loc.x, loc.y, loc.z
			end
		end
	end

	if not x then
		push_sub(sub, "mc.notify.not_owned", 2000)
		return false
	end

	return coords_teleport.run_coords_teleport(
		t("mc.notify.title_sub", { business = t(sub.label_key) }),
		t("mc.notify.teleported", { business = t(sub.label_key) }),
		x,
		y,
		z,
		false,
		nil
	)
end

function actions.refill_supplies(sub_key)
	local sub = data.find_sub(sub_key)
	if not sub then
		return false
	end

	return jobs.run_guarded_job("mc_refill_" .. sub_key, function()
		local factoryslot = find_factoryslot_for_key(sub_key)
		if factoryslot == nil then
			push_sub(sub, "mc.notify.not_owned", 2000)
			return
		end
		local ok = fill_supply_slot(factoryslot + 1)
		push_sub(sub, ok and "mc.notify.supplies_refill_ok" or "mc.notify.supplies_refill_failed", 2000)
	end, function()
		push_sub(sub, "mc.notify.supplies_refill_running", 1500)
	end)
end

function actions.refill_all_supplies()
	return jobs.run_guarded_job("mc_refill_all", function()
		local any_owned = false
		local ok = true
		local stats = cfg().stats or {}
		local prefix = stats.factory_slot_prefix
		if type(prefix) ~= "string" then
			push_feature("mc.notify.all_supplies_refill_failed", 2000)
			return
		end
		for i = 0, 4 do
			local prop_id = safe_access.get_mp_stat_int(prefix .. tostring(i), 0)
			if prop_id and prop_id > 0 then
				any_owned = true
				ok = fill_supply_slot(i + 1) and ok
				util.yield(20)
			end
		end
		if any_owned then
			push_feature(ok and "mc.notify.all_supplies_refill_ok" or "mc.notify.all_supplies_refill_failed", 2000)
		else
			push_feature("mc.notify.no_owned_businesses", 2000)
		end
	end, function()
		push_feature("mc.notify.supplies_refill_running", 1500)
	end)
end

function actions.instant_sell()
	return jobs.run_guarded_job("mc_sell", function()
		local sell = cfg().scripts and cfg().scripts.sell or {}
		if not safe_access.is_script_running(sell.name) then
			push_feature("mc.notify.sell_start_first", 2200)
			return
		end
		local ok = safe_access.set_local_int_variants(sell.name, sell.offset, sell.value)
		push_feature(ok and "mc.notify.sell_ok" or "mc.notify.sell_failed", 2200)
	end, function()
		push_feature("mc.notify.sell_running", 1500)
	end)
end

function actions.set_fast_production(enabled, silent)
	state.set_fast_production(enabled == true)
	if not silent then
		push_feature(state.fast_production.active and "mc.notify.fast_enabled" or "mc.notify.fast_disabled", 2000)
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

	local all_owned_full = true
	local any_owned = false
	local stats = cfg().stats or {}
	local prefix = stats.factory_slot_prefix
	local sub_stock_stats = stats.sub_stock or {}
	if type(prefix) ~= "string" then
		state.set_fast_production(false)
		state.set_fast_status(data.status.stopped)
		return false
	end

	for i = 0, 4 do
		local prop_id = safe_access.get_mp_stat_int(prefix .. tostring(i), 0)
		if prop_id and prop_id > 0 then
			any_owned = true
			local sub_key = data.prop_id_to_key[prop_id]
			local sub = sub_key and data.find_sub(sub_key)
			if sub then
				local stock = safe_access.get_mp_stat_int(sub_stock_stats[sub.key], 0) or 0
				if stock < sub.cap then
					state.set_fast_status(data.status.running)
					apply_production_tick(i + 1)
					all_owned_full = false
				end
			end
		end
	end

	if not any_owned then
		state.set_fast_production(false)
		state.set_fast_status(data.status.no_owned)
		push_feature("mc.notify.fast_stopped_no_owned", 2200)
	elseif all_owned_full then
		state.set_fast_production(false)
		state.set_fast_status(data.status.full)
		push_feature("mc.notify.fast_stopped_full", 2200)
	end

	return true
end

function actions.set_sub_production_loop(sub_key, enabled, silent)
	local sub = data.find_sub(sub_key)
	if not sub then
		return false
	end

	state.set_sub_production(sub_key, enabled == true)
	if not silent then
		push_sub(
			sub,
			state.sub_production.active[sub_key] and "mc.notify.loop_enabled" or "mc.notify.loop_disabled",
			2000
		)
	end
	return state.sub_production.active[sub_key]
end

function actions.get_sub_production_loop_active(sub_key)
	return state.sub_production.active[sub_key] == true
end

function actions.get_sub_production_loop_status(sub_key)
	return t(data.status_label_key(state.sub_production.status[sub_key]))
end

function actions.tick_sub_production()
	local any_active = false
	local stats = cfg().stats or {}
	local sub_stock_stats = stats.sub_stock or {}
	for i = 1, #data.subs do
		local sub = data.subs[i]
		if state.sub_production.active[sub.key] then
			any_active = true
			local factoryslot = find_factoryslot_for_key(sub.key)
			if factoryslot == nil then
				state.sub_production.active[sub.key] = false
				state.set_sub_status(sub.key, data.status.not_owned)
			else
				local stock = safe_access.get_mp_stat_int(sub_stock_stats[sub.key], 0) or 0
				if stock >= sub.cap then
					state.sub_production.active[sub.key] = false
					state.set_sub_status(sub.key, data.status.full)
				else
					state.set_sub_status(sub.key, data.status.running)
					apply_production_tick(factoryslot + 1)
				end
			end
		end
	end
	return any_active
end

function actions.set_disable_reminders(enabled, silent)
	local tunables = cfg().tunables or {}
	local defaults = cfg().defaults or {}
	local active = business_runtime.set_cached_tunable_toggle({
		enabled = enabled,
		cache = state.protections,
		cache_key = "reminders_default",
		tunable = tunables.reminders,
		default = defaults.reminder_cooldown_default,
		disabled_value = defaults.reminder_cooldown_disabled,
		is_active = actions.get_reminders_active,
		set_active = state.set_reminders_active,
	})
	if not silent then
		push_feature(active and "mc.notify.reminders_disabled" or "mc.notify.reminders_restored", 2000)
	end
	return active
end

function actions.get_reminders_active()
	return state.protections.reminders_active == true
end

function actions.set_disable_raids(enabled, silent)
	local tunables = cfg().tunables or {}
	local defaults = cfg().defaults or {}
	local active = business_runtime.set_cached_tunable_toggle({
		enabled = enabled,
		cache = state.protections,
		cache_key = "raids_default",
		tunable = tunables.disable_raids,
		default = defaults.raids_default,
		disabled_value = 0,
		is_active = actions.get_raids_active,
		set_active = state.set_raids_active,
	})
	if not silent then
		push_feature(active and "mc.notify.raids_disabled" or "mc.notify.raids_restored", 2000)
	end
	return active
end

function actions.get_raids_active()
	return state.protections.raids_active == true
end

function actions.apply_current_state(silent)
	actions.set_fast_production(state.fast_production.active, true)
	for i = 1, #data.subs do
		local key = data.subs[i].key
		actions.set_sub_production_loop(key, state.sub_production.active[key], true)
	end
	actions.set_disable_reminders(state.protections.reminders_active, true)
	actions.set_disable_raids(state.protections.raids_active, true)
	if not silent then
		push_feature("mc.notify.preset_state_applied", 2000)
	end
	return true
end

function actions.kill_black_screen()
	local any_ok = false
	pcall(function()
		native.do_screen_fade_in(0)
		any_ok = true
	end)
	pcall(function()
		native.display_hud(true)
		any_ok = true
	end)
	pcall(function()
		native.display_radar(true)
		any_ok = true
	end)
	push_feature(any_ok and "mc.notify.black_screen_ok" or "mc.notify.black_screen_failed", 2200)
	return any_ok
end

return actions
