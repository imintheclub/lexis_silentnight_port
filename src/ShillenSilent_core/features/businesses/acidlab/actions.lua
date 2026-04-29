local jobs = require("ShillenSilent_core.core.jobs")
local safe_access = require("ShillenSilent_core.core.safe_access")
local notify_core = require("ShillenSilent_core.core.notify")
local i18n = require("ShillenSilent_core.i18n")
local offsets = require("ShillenSilent_core.data.offsets.current")
local data = require("ShillenSilent_core.features.businesses.acidlab.data")
local state = require("ShillenSilent_core.features.businesses.acidlab.state")

local actions = {}

local function cfg()
	return offsets[data.feature_id] or {}
end

local t = i18n.t

local push = notify_core.feature("feature.acidlab.name")

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

function actions.production_tick()
	local scripts = cfg().scripts or {}
	if not safe_access.is_script_running(scripts.freemode) then
		push("acidlab.notify.must_be_freemode", 2000)
		return false
	end

	local ok = apply_production_tick()
	push(ok and "acidlab.notify.production_tick_ok" or "acidlab.notify.production_tick_failed", 2000)
	return ok
end

function actions.refill_supplies()
	return jobs.run_guarded_job("acidlab_refill", function()
		local ok = fill_supply_slot()
		push(ok and "acidlab.notify.supplies_refill_ok" or "acidlab.notify.supplies_refill_failed", 2000)
	end, function()
		push("acidlab.notify.supplies_refill_running", 1500)
	end)
end

function actions.instant_sell()
	return jobs.run_guarded_job("acidlab_sell", function()
		local sell = cfg().scripts and cfg().scripts.sell or {}
		if not safe_access.is_script_running(sell.name) then
			push("acidlab.notify.sell_start_first", 2200)
			return
		end

		local flags = safe_access.get_local_int(sell.name, sell.flags_offset, 0) or 0
		flags = flags | (1 << sell.win_bit)
		local ok1 = safe_access.set_local_int(sell.name, sell.state_offset, sell.state_value)
		local ok2 = safe_access.set_local_int(sell.name, sell.flags_offset, flags)

		push((ok1 and ok2) and "acidlab.notify.sell_ok" or "acidlab.notify.sell_failed", 2200)
	end, function()
		push("acidlab.notify.sell_running", 1500)
	end)
end

function actions.set_fast_production(enabled, silent)
	state.set_fast_production(enabled == true)
	if not silent then
		push(state.fast_production.active and "acidlab.notify.fast_enabled" or "acidlab.notify.fast_disabled", 2000)
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

	local stats = cfg().stats or {}
	local limits = cfg().limits or {}
	local units = safe_access.get_mp_stat_int(stats.stock, 0) or 0
	if units >= (tonumber(limits.max_capacity) or 0) then
		state.set_fast_production(false)
		state.set_fast_status(data.status.full)
		push("acidlab.notify.fast_stopped_full", 2200)
		return false
	end

	local scripts = cfg().scripts or {}
	if safe_access.is_script_running(scripts.freemode) then
		state.set_fast_status(data.status.running)
		apply_production_tick()
	end

	return true
end

function actions.apply_current_state(silent)
	actions.set_fast_production(state.fast_production.active, true)
	if not silent then
		push("acidlab.notify.preset_state_applied", 2000)
	end
	return true
end

return actions
