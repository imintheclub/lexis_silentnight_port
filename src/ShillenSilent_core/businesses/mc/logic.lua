local biz = require("ShillenSilent_core.businesses.shared")

-- MC sub-business slot mapping.
local MC_SUBS = {
	{ key = "meth", name = "Meth Lab", slot = 1, stock_stat = "PRODTOTALFORFACTORY3", cap = 20, factoryslot_idx = 3 },
	{ key = "weed", name = "Weed Farm", slot = 2, stock_stat = "PRODTOTALFORFACTORY1", cap = 80, factoryslot_idx = 1 },
	{
		key = "cocaine",
		name = "Cocaine Lockup",
		slot = 3,
		stock_stat = "PRODTOTALFORFACTORY4",
		cap = 10,
		factoryslot_idx = 4,
	},
	{
		key = "counterfeit",
		name = "Counterfeit Cash",
		slot = 4,
		stock_stat = "PRODTOTALFORFACTORY2",
		cap = 40,
		factoryslot_idx = 2,
	},
	{
		key = "forgery",
		name = "Forgery Office",
		slot = 5,
		stock_stat = "PRODTOTALFORFACTORY0",
		cap = 60,
		factoryslot_idx = 0,
	},
}

-- Instant sell uses gb_biker_contraband_sell script locals (EE offsets).
local SELL_SCRIPT = "gb_biker_contraband_sell"
local SELL_BASE = 731
local SELL_OFF = 122
local SELL_VALUE = 15

local FAST_LOOP_INTERVAL_MS = 150

local TUNABLE_REMINDERS = "BIKER_PRODUCT_REMINDER_COOLDOWN"
local REMINDER_COOLDOWN_DISABLED = 86400000
local REMINDER_COOLDOWN_DEFAULT = 300000

local _fast_prod_active = false
local _fast_prod_thread_started = false
local _fast_prod_status = "Stopped"
local _sub_prod_active = {}
local _sub_prod_status = {}
local _sub_prod_thread_started = false
local _reminders_default = nil
local _reminders_active = false

local function get_subs()
	return MC_SUBS
end

local function find_sub(sub_key)
	for _, sub in ipairs(MC_SUBS) do
		if sub.key == sub_key then
			return sub
		end
	end
	return nil
end

local function production_tick(sub_key)
	local sub = find_sub(sub_key)
	if not sub then
		return
	end
	biz.production_tick(sub.slot)
	if notify then
		notify.push("MC: " .. sub.name, "Production tick applied", 2000)
	end
end

local function refill_supplies(sub_key)
	local sub = find_sub(sub_key)
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
	enabled = enabled == true
	if enabled then
		if not util or not util.create_thread then
			if notify then
				notify.push("Moto Club", "Fast production unavailable on this runtime", 2200)
			end
			return
		end
		if not _fast_prod_thread_started then
			_fast_prod_thread_started = true
			util.create_thread(function()
				while true do
					if _fast_prod_active then
						local all_owned_full = true
						local any_owned = false
						local mp = biz.GetMP()

						for _, sub in ipairs(MC_SUBS) do
							local owned = biz.get_stat_int(mp .. "FACTORYSLOT" .. tostring(sub.factoryslot_idx), 0)
							if owned and owned > 0 then
								any_owned = true
								local stock = biz.get_stat_int(mp .. sub.stock_stat, 0) or 0
								if stock < sub.cap then
									_fast_prod_status = "Running"
									biz.production_tick(sub.slot)
									all_owned_full = false
								end
							end
						end

						if not any_owned then
							_fast_prod_active = false
							_fast_prod_status = "No Owned Businesses"
							if notify then
								notify.push(
									"Moto Club",
									"Fast production stopped: no owned MC businesses detected",
									2200
								)
							end
						elseif all_owned_full then
							_fast_prod_active = false
							_fast_prod_status = "Full"
							if notify then
								notify.push("Moto Club", "Fast production stopped: all owned businesses are full", 2200)
							end
						end

						util.yield(FAST_LOOP_INTERVAL_MS)
					else
						if _fast_prod_status == "Running" then
							_fast_prod_status = "Stopped"
						end
						util.yield(200)
					end
				end
			end)
		end
	end

	_fast_prod_active = enabled
	_fast_prod_status = enabled and "Running" or "Stopped"
	if notify then
		notify.push("Moto Club", enabled and "Fast production enabled" or "Fast production disabled", 2000)
	end
end

local function get_fast_prod_active()
	return _fast_prod_active
end

local function get_fast_prod_status()
	return _fast_prod_status
end

local function ensure_sub_production_loop_thread()
	if _sub_prod_thread_started then
		return true
	end
	if not util or not util.create_thread then
		return false
	end

	_sub_prod_thread_started = true
	util.create_thread(function()
		while true do
			local any_active = false
			local mp = biz.GetMP()
			for _, sub in ipairs(MC_SUBS) do
				if _sub_prod_active[sub.key] then
					any_active = true
					local owned = biz.get_stat_int(mp .. "FACTORYSLOT" .. tostring(sub.factoryslot_idx), 0)
					if not owned or owned <= 0 then
						_sub_prod_active[sub.key] = false
						_sub_prod_status[sub.key] = "Not Owned"
					else
						local stock = biz.get_stat_int(mp .. sub.stock_stat, 0) or 0
						if stock >= sub.cap then
							_sub_prod_active[sub.key] = false
							_sub_prod_status[sub.key] = "Full"
						else
							_sub_prod_status[sub.key] = "Running"
							biz.production_tick(sub.slot)
						end
					end
				elseif _sub_prod_status[sub.key] == nil then
					_sub_prod_status[sub.key] = "Stopped"
				end
			end

			if any_active then
				util.yield(FAST_LOOP_INTERVAL_MS)
			else
				util.yield(200)
			end
		end
	end)

	return true
end

local function set_sub_production_loop(sub_key, enabled)
	local sub = find_sub(sub_key)
	if not sub then
		return
	end

	enabled = enabled == true
	if enabled then
		if not ensure_sub_production_loop_thread() then
			if notify then
				notify.push("MC: " .. sub.name, "Loop production unavailable on this runtime", 2200)
			end
			return
		end
		_sub_prod_active[sub.key] = true
		_sub_prod_status[sub.key] = "Running"
	else
		_sub_prod_active[sub.key] = false
		_sub_prod_status[sub.key] = "Stopped"
	end

	if notify then
		notify.push("MC: " .. sub.name, enabled and "Production loop enabled" or "Production loop disabled", 2000)
	end
end

local function get_sub_production_loop_active(sub_key)
	return _sub_prod_active[sub_key] == true
end

local function get_sub_production_loop_status(sub_key)
	return _sub_prod_status[sub_key] or "Stopped"
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
	get_fast_prod_status = get_fast_prod_status,
	set_sub_production_loop = set_sub_production_loop,
	get_sub_production_loop_active = get_sub_production_loop_active,
	get_sub_production_loop_status = get_sub_production_loop_status,
	set_disable_reminders = set_disable_reminders,
	get_reminders_active = get_reminders_active,
}

return mc_logic
