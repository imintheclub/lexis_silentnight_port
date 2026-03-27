local biz = require("ShillenSilent_core.businesses.shared")

-- Bunker uses slot 6 in the shared production timer system.
local BUNKER_SLOT = 6

-- Instant sell: manipulate gb_gunrunning script locals (EE offsets).
local SELL_SCRIPT = "gb_gunrunning"
local SELL_BASE = 1268
local SELL_COMPLETE_OFFSET = 774

-- Tunables.
local TUNABLE_DISABLE_RAIDS = "BIKER_DISABLE_DEFEND_POLICE_RAID"
local TUNABLE_REMINDERS = "BIKER_PRODUCT_REMINDER_COOLDOWN"
local REMINDER_COOLDOWN_DISABLED = 86400000
local REMINDER_COOLDOWN_DEFAULT = 300000
local BUNKER_STOCK_STAT = "PRODTOTALFORFACTORY5"
local BUNKER_MAX_CAPACITY = 100
local FAST_LOOP_INTERVAL_MS = 150

local _raids_default = nil
local _raids_active = false
local _reminders_default = nil
local _reminders_active = false
local _fast_prod_active = false
local _fast_prod_thread_started = false
local _fast_prod_status = "Stopped"

-- Blip sprite ID for bunker map icon — used for primary teleport.
local BLIP_SPRITE = 557
-- Ownership stat fallback: MP0_FACTORYSLOT5 stores the bunker property ID.
local OWNED_STAT = "FACTORYSLOT5"

-- Teleport locations (11 bunker options). `id` matches the game's property ID
-- stored in MP0_FACTORYSLOT5 so ownership can be auto-detected.
local BUNKER_LOCATIONS = {
	{ id = 21, name = "Grand Senora Oilfields", x = 494.68, y = 3015.90, z = 41.04 },
	{ id = 22, name = "Grand Senora Desert", x = 849.62, y = 3024.43, z = 41.27 },
	{ id = 23, name = "Route 68", x = 40.42, y = 2929.00, z = 55.75 },
	{ id = 24, name = "Farmhouse", x = 1571.95, y = 2224.60, z = 78.35 },
	{ id = 25, name = "Smoke Tree Road", x = 2107.14, y = 3324.63, z = 45.37 },
	{ id = 26, name = "Thomson Scrapyard", x = 2488.71, y = 3164.62, z = 49.08 },
	{ id = 27, name = "Grapeseed", x = 1798.50, y = 4704.96, z = 39.99 },
	{ id = 28, name = "Paleto Forest", x = -754.23, y = 5944.17, z = 19.84 },
	{ id = 29, name = "Raton Canyon", x = -388.33, y = 4338.32, z = 56.10 },
	{ id = 30, name = "Lago Zancudo", x = -3030.34, y = 3334.57, z = 10.11 },
	{ id = 31, name = "Chumash", x = -3156.14, y = 1376.71, z = 17.07 },
}
local selected_loc = 1

local function get_locations()
	return BUNKER_LOCATIONS
end

local function get_selected_loc()
	return selected_loc
end

local function set_selected_loc(idx)
	selected_loc = idx
end

local function teleport()
	local x, y, z = biz.get_blip_coords(BLIP_SPRITE)
	if not x then
		local loc = biz.find_owned_location(OWNED_STAT, BUNKER_LOCATIONS) or BUNKER_LOCATIONS[selected_loc]
		if not loc then
			return
		end
		x, y, z = loc.x, loc.y, loc.z
	end
	biz.run_coords_teleport("Bunker", "Teleported to Bunker", x, y, z, false, nil)
end

local function production_tick()
	biz.production_tick(BUNKER_SLOT)
	if notify then
		notify.push("Bunker", "Production tick completed", 2000)
	end
end

local function get_stock_units()
	local mp = biz.GetMP()
	return biz.get_stat_int(mp .. BUNKER_STOCK_STAT, 0) or 0
end

local function is_full()
	return get_stock_units() >= BUNKER_MAX_CAPACITY
end

local function ensure_fast_loop_thread()
	if _fast_prod_thread_started then
		return true
	end
	if not util or not util.create_thread then
		return false
	end

	_fast_prod_thread_started = true
	util.create_thread(function()
		while true do
			if _fast_prod_active then
				if is_full() then
					_fast_prod_active = false
					_fast_prod_status = "Full"
					if notify then
						notify.push("Bunker", "Fast production stopped: stock is full", 2200)
					end
				else
					_fast_prod_status = "Running"
					biz.production_tick(BUNKER_SLOT)
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

	return true
end

local function refill_supplies()
	biz.run_guarded_job("bunker_refill", function()
		biz.fill_supply_slot(BUNKER_SLOT)
		if notify then
			notify.push("Bunker", "Supplies refill completed", 2000)
		end
	end, function()
		if notify then
			notify.push("Bunker", "Supplies refill failed (already in progress)", 1500)
		end
	end)
end

local function instant_sell()
	biz.run_guarded_job("bunker_sell", function()
		if not biz.is_script_running(SELL_SCRIPT) then
			if notify then
				notify.push("Bunker", "Start your Bunker sell mission first", 2200)
			end
			return
		end

		local ok = biz.set_local_int(SELL_SCRIPT, SELL_BASE + SELL_COMPLETE_OFFSET, 0)
		if notify then
			notify.push("Bunker", ok and "Instant sell completed" or "Instant sell failed to apply", 2200)
		end
	end, function()
		if notify then
			notify.push("Bunker", "Instant sell failed (already running)", 1500)
		end
	end)
end

local function set_disable_raids(enabled)
	if enabled then
		if _raids_default == nil then
			_raids_default = biz.get_tunable_int(TUNABLE_DISABLE_RAIDS, 0)
		end
		biz.set_tunable_int(TUNABLE_DISABLE_RAIDS, 1)
		_raids_active = true
	else
		biz.set_tunable_int(TUNABLE_DISABLE_RAIDS, _raids_default or 0)
		_raids_active = false
	end
	if notify then
		notify.push("Bunker", enabled and "Raids disabled" or "Raids restored", 2000)
	end
end

local function get_raids_active()
	return _raids_active
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
		notify.push("Bunker", enabled and "Reminders disabled" or "Reminders restored", 2000)
	end
end

local function get_reminders_active()
	return _reminders_active
end

local function set_fast_production(enabled)
	enabled = enabled == true
	if enabled then
		if not ensure_fast_loop_thread() then
			if notify then
				notify.push("Bunker", "Fast production unavailable on this runtime", 2200)
			end
			return
		end
		if is_full() then
			_fast_prod_active = false
			_fast_prod_status = "Full"
			if notify then
				notify.push("Bunker", "Stock already full", 2000)
			end
			return
		end
		_fast_prod_active = true
		_fast_prod_status = "Running"
	else
		_fast_prod_active = false
		_fast_prod_status = "Stopped"
	end
	if notify then
		notify.push("Bunker", enabled and "Fast production enabled" or "Fast production disabled", 2000)
	end
end

local function get_fast_prod_active()
	return _fast_prod_active
end

local function get_fast_prod_status()
	return _fast_prod_status
end

local bunker_logic = {
	get_locations = get_locations,
	get_selected_loc = get_selected_loc,
	set_selected_loc = set_selected_loc,
	teleport = teleport,
	production_tick = production_tick,
	refill_supplies = refill_supplies,
	instant_sell = instant_sell,
	set_disable_raids = set_disable_raids,
	get_raids_active = get_raids_active,
	set_disable_reminders = set_disable_reminders,
	get_reminders_active = get_reminders_active,
	set_fast_production = set_fast_production,
	get_fast_prod_active = get_fast_prod_active,
	get_fast_prod_status = get_fast_prod_status,
}

return bunker_logic
