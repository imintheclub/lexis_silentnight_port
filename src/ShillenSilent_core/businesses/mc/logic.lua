local biz = require("ShillenSilent_core.businesses.shared")

-- MC sub-business slot mapping.
local MC_SUBS = {
	{ key = "meth", name = "Meth Lab", slot = 1 },
	{ key = "weed", name = "Weed Farm", slot = 2 },
	{ key = "cocaine", name = "Cocaine Lockup", slot = 3 },
	{ key = "counterfeit", name = "Counterfeit Cash", slot = 4 },
	{ key = "forgery", name = "Forgery Office", slot = 5 },
}

-- Instant sell uses gb_biker_contraband_sell script locals (EE offsets).
local SELL_SCRIPT = "gb_biker_contraband_sell"
local SELL_BASE = 731
local SELL_OFF = 122
local SELL_VALUE = 15

-- Production time tunables per sub-business.
local PROD_TUNABLES = {
	meth = "BIKER_METH_PRODUCTION_TIME",
	weed = "BIKER_WEED_PRODUCTION_TIME",
	cocaine = "BIKER_CRACK_PRODUCTION_TIME",
	counterfeit = "BIKER_FAKEIDS_PRODUCTION_TIME",
	forgery = "BIKER_COUNTERCASH_PRODUCTION_TIME",
}

local TUNABLE_REMINDERS = "BIKER_PRODUCT_REMINDER_COOLDOWN"
local REMINDER_COOLDOWN_DISABLED = 86400000
local REMINDER_COOLDOWN_DEFAULT = 300000

local _fast_prod_defaults = {}
local _fast_prod_active = false
local _reminders_default = nil
local _reminders_active = false

local function get_subs()
	return MC_SUBS
end

local function production_tick(sub_key)
	local sub = nil
	for _, s in ipairs(MC_SUBS) do
		if s.key == sub_key then
			sub = s
			break
		end
	end
	if not sub then
		return
	end
	biz.production_tick(sub.slot)
	if notify then
		notify.push("MC: " .. sub.name, "Production tick applied", 2000)
	end
end

local function refill_supplies(sub_key)
	local sub = nil
	for _, s in ipairs(MC_SUBS) do
		if s.key == sub_key then
			sub = s
			break
		end
	end
	if not sub then
		return
	end
	local slot = sub.slot
	local name = sub.name
	biz.run_guarded_job("mc_refill_" .. sub_key, function()
		biz.fill_supply_slot(slot)
		if notify then
			notify.push("MC: " .. name, "Supplies refilled", 2000)
		end
	end, function()
		if notify then
			notify.push("MC: " .. name, "Refill already in progress", 1500)
		end
	end)
end

local function refill_all_supplies()
	biz.run_guarded_job("mc_refill_all", function()
		for _, sub in ipairs(MC_SUBS) do
			biz.fill_supply_slot(sub.slot)
			util.yield(20)
		end
		if notify then
			notify.push("Moto Club", "All supplies refilled", 2000)
		end
	end, function()
		if notify then
			notify.push("Moto Club", "Refill already in progress", 1500)
		end
	end)
end

local function instant_sell()
	biz.run_guarded_job("mc_sell", function()
		if not biz.is_script_running(SELL_SCRIPT) then
			if notify then
				notify.push("Moto Club", "Start your MC sell mission first", 2200)
			end
			return
		end
		local ok = biz.set_local_int(SELL_SCRIPT, SELL_BASE + SELL_OFF, SELL_VALUE)
		if notify then
			notify.push("Moto Club", ok and "Instant sell triggered" or "Sell write failed", 2200)
		end
	end, function()
		if notify then
			notify.push("Moto Club", "Sell already running", 1500)
		end
	end)
end

local function set_fast_production(enabled)
	for sub_key, tunable in pairs(PROD_TUNABLES) do
		if enabled then
			if _fast_prod_defaults[sub_key] == nil then
				_fast_prod_defaults[sub_key] = biz.get_tunable_int(tunable, 10000)
			end
			local def = _fast_prod_defaults[sub_key] or 10000
			local target = math.max(1, math.floor(def / 2))
			biz.set_tunable_int(tunable, target)
		else
			local def = _fast_prod_defaults[sub_key]
			if def ~= nil then
				biz.set_tunable_int(tunable, def)
			end
		end
	end
	_fast_prod_active = enabled
	if notify then
		notify.push("Moto Club", enabled and "Fast production enabled" or "Fast production disabled", 2000)
	end
end

local function get_fast_prod_active()
	return _fast_prod_active
end

local function set_disable_reminders(enabled)
	if enabled then
		if _reminders_default == nil then
			_reminders_default = biz.get_tunable_int(TUNABLE_REMINDERS, REMINDER_COOLDOWN_DEFAULT)
		end
		biz.set_tunable_int(TUNABLE_REMINDERS, REMINDER_COOLDOWN_DISABLED)
		_reminders_active = true
	else
		biz.set_tunable_int(TUNABLE_REMINDERS, _reminders_default or REMINDER_COOLDOWN_DEFAULT)
		_reminders_active = false
	end
	if notify then
		notify.push("Moto Club", enabled and "Reminders disabled" or "Reminders restored", 2000)
	end
end

local function get_reminders_active()
	return _reminders_active
end

local mc_logic = {
	get_subs = get_subs,
	production_tick = production_tick,
	refill_supplies = refill_supplies,
	refill_all_supplies = refill_all_supplies,
	instant_sell = instant_sell,
	set_fast_production = set_fast_production,
	get_fast_prod_active = get_fast_prod_active,
	set_disable_reminders = set_disable_reminders,
	get_reminders_active = get_reminders_active,
}

return mc_logic
