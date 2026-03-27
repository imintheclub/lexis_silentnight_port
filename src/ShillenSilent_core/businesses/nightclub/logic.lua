local biz = require("ShillenSilent_core.businesses.shared")

-- Nightclub product stats (MP prefix + stat name).
-- Slot 0-6: Cargo, Sporting, Pharmaceutical, Cash, Organic, South American, Printing.
local PROD_STAT_BASE = "HUB_PROD_TOTAL_"
local PROD_SLOT_COUNT = 7
local PROD_MAX_UNITS = 360

-- SyloCore nightclub fast-production method:
-- repeatedly force accrue-time tunables down to 1000ms.
local NC_FAST_ACCRUE_TIME = 1000
local NC_ACCRUE_TUNABLES = {
	{ name = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_CARGO", default = 8400000 },
	{ name = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_WEAPONS", default = 4800000 },
	{ name = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_COKE", default = 14400000 },
	{ name = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_METH", default = 7200000 },
	{ name = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_WEED", default = 2400000 },
	{ name = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_FORGED_DOCUMENTS", default = 1800000 },
	{ name = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_COUNTERFEIT_CASH", default = 3600000 },
}
local NC_TUNABLE_MAP = {
	all = nil,
	cargo = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_CARGO",
	weapons = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_WEAPONS",
	coke = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_COKE",
	meth = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_METH",
	weed = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_WEED",
	docs = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_FORGED_DOCUMENTS",
	cash = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_COUNTERFEIT_CASH",
}
local NC_FAST_PRODUCT_OPTIONS = {
	{ name = "All Products", value = "all" },
	{ name = "Cargo & Shipments", value = "cargo" },
	{ name = "Sporting Goods", value = "weapons" },
	{ name = "South American Imports", value = "coke" },
	{ name = "Pharmaceutical Research", value = "meth" },
	{ name = "Organic Produce", value = "weed" },
	{ name = "Printing & Copying", value = "docs" },
	{ name = "Cash Creation", value = "cash" },
}

-- Safe collect global flag (EE).
local NC_SAFE_COLLECT = 2708832

-- Stats.
local POPULARITY_STAT = "CLUB_POPULARITY"
local POPULARITY_MAX = 1000
local POPULARITY_MIN = 0
local SAFE_STAT = "CLUB_SAFE_CASH_VALUE"
local SAFE_MAX = 250000
local SAFE_PAY_TIME_STAT = "CLUB_PAY_TIME_LEFT"
local NC_SAFE_TOP5 = 262145 + 23750
local NC_SAFE_TOP100 = 262145 + 23769

-- Tunables for raids/reminders.
local TUNABLE_DISABLE_RAIDS = "BIKER_DISABLE_DEFEND_POLICE_RAID"
local TUNABLE_REMINDERS = "BIKER_PRODUCT_REMINDER_COOLDOWN"
local REMINDER_COOLDOWN_DISABLED = 86400000
local REMINDER_COOLDOWN_DEFAULT = 300000

local _raids_default = nil
local _raids_active = false
local _reminders_default = nil
local _reminders_active = false
local _fast_prod_active = false
local _fast_prod_thread_started = false
local _fast_prod_status = "Stopped"
local _fast_prod_target = "all"
local _popularity_editor_value = POPULARITY_MAX
local _popularity_lock_active = false

-- Blip sprite ID for nightclub map icon — used for primary teleport.
local BLIP_SPRITE = 614
-- Ownership stat fallback: MP0_NIGHTCLUB_OWNED stores the nightclub property ID.
local OWNED_STAT = "NIGHTCLUB_OWNED"

-- Teleport locations (10 nightclub options). `id` matches the game's property ID.
local NC_LOCATIONS = {
	{ id = 1, name = "Downtown Vinewood", x = 15.0, y = 220.0, z = 107.0 },
	{ id = 2, name = "West Vinewood", x = -565.0, y = 276.0, z = 83.0 },
	{ id = 3, name = "Strawberry", x = 97.0, y = -1292.0, z = 29.0 },
	{ id = 4, name = "Mission Row", x = 356.0, y = -1012.0, z = 29.0 },
	{ id = 5, name = "La Mesa", x = 831.0, y = -1675.0, z = 29.0 },
	{ id = 6, name = "Cypress Flats", x = 728.0, y = -2165.0, z = 29.0 },
	{ id = 7, name = "LSIA", x = -993.0, y = -2535.0, z = 20.0 },
	{ id = 8, name = "Elysian Island", x = -146.0, y = -2640.0, z = 6.0 },
	{ id = 9, name = "Del Perro", x = -1389.0, y = -588.0, z = 30.0 },
	{ id = 10, name = "Vespucci Canals", x = -1172.0, y = -1152.0, z = 5.0 },
}
local selected_loc = 1

local function get_locations()
	return NC_LOCATIONS
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
		local loc = biz.find_owned_location(OWNED_STAT, NC_LOCATIONS) or NC_LOCATIONS[selected_loc]
		if not loc then
			return
		end
		x, y, z = loc.x, loc.y, loc.z
	end
	biz.run_coords_teleport("Nightclub", "Teleported to Nightclub", x, y, z, false, nil)
end

local function production_tick_all()
	local mp = biz.GetMP()
	local any_ok = false
	for i = 0, PROD_SLOT_COUNT - 1 do
		local stat_name = mp .. PROD_STAT_BASE .. tostring(i)
		local cur = biz.get_stat_int(stat_name, 0)
		if cur < PROD_MAX_UNITS then
			local ok = biz.set_stat_int(stat_name, math.min(cur + 1, PROD_MAX_UNITS))
			if ok then
				any_ok = true
			end
		end
	end
	if notify then
		notify.push(
			"Nightclub",
			any_ok and "Production tick completed" or "Production tick failed (all products at max)",
			2000
		)
	end
end

local function ensure_fast_production_loop_thread()
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
				local target = _fast_prod_target or "all"
				if target == "all" then
					for _, tun in ipairs(NC_ACCRUE_TUNABLES) do
						biz.set_tunable_int(tun.name, NC_FAST_ACCRUE_TIME)
					end
				else
					local tun_name = NC_TUNABLE_MAP[target]
					if tun_name then
						biz.set_tunable_int(tun_name, NC_FAST_ACCRUE_TIME)
					end
				end
				_fast_prod_status = "Running (" .. tostring(target) .. ")"
				util.yield(0)
			else
				if string.find(_fast_prod_status, "Running", 1, true) == 1 then
					_fast_prod_status = "Stopped"
				end
				util.yield(200)
			end
		end
	end)

	return true
end

local function set_fast_production(enabled)
	enabled = enabled == true
	if enabled then
		if not ensure_fast_production_loop_thread() then
			if notify then
				notify.push("Nightclub", "Production loop unavailable on this runtime", 2200)
			end
			return
		end
		_fast_prod_active = true
		_fast_prod_status = "Running (" .. tostring(_fast_prod_target) .. ")"
	else
		-- Restore default tunables just like SyloCore when disabling.
		local target = _fast_prod_target or "all"
		if target == "all" then
			for _, tun in ipairs(NC_ACCRUE_TUNABLES) do
				biz.set_tunable_int(tun.name, tun.default)
			end
		else
			local tun_name = NC_TUNABLE_MAP[target]
			if tun_name then
				for _, tun in ipairs(NC_ACCRUE_TUNABLES) do
					if tun.name == tun_name then
						biz.set_tunable_int(tun_name, tun.default)
						break
					end
				end
			end
		end
		_fast_prod_active = false
		_fast_prod_status = "Stopped"
	end
	if notify then
		notify.push("Nightclub", enabled and "Tunables production loop enabled" or "Tunables restored", 2000)
	end
end

local function get_fast_prod_active()
	return _fast_prod_active
end

local function get_fast_prod_status()
	return _fast_prod_status
end

local function get_fast_product_options()
	return NC_FAST_PRODUCT_OPTIONS
end

local function get_fast_prod_target()
	return _fast_prod_target
end

local function set_fast_prod_target(target)
	target = tostring(target or "all")
	if target ~= "all" and not NC_TUNABLE_MAP[target] then
		target = "all"
	end
	_fast_prod_target = target
	if _fast_prod_active then
		-- Re-apply immediately on target change while loop is active.
		set_fast_production(false)
		set_fast_production(true)
	end
end

local function fill_all_products()
	local mp = biz.GetMP()
	local any_ok = false
	for i = 0, PROD_SLOT_COUNT - 1 do
		local stat_name = mp .. PROD_STAT_BASE .. tostring(i)
		local ok = biz.set_stat_int(stat_name, PROD_MAX_UNITS)
		if ok then
			any_ok = true
		end
	end
	if notify then
		notify.push("Nightclub", any_ok and "All products fill completed" or "All products fill failed to apply", 2000)
	end
end

local function safe_collect()
	local ok = biz.set_global_int(NC_SAFE_COLLECT, 1)
	if notify then
		notify.push("Nightclub", ok and "Safe collect completed" or "Safe collect failed to apply", 2000)
	end
end

local function safe_fill()
	local mp = biz.GetMP()
	local ok = biz.set_stat_int(mp .. SAFE_STAT, SAFE_MAX)
	if notify then
		notify.push("Nightclub", ok and "Safe fill completed ($250,000)" or "Safe fill failed to apply", 2000)
	end
end

local function set_popularity_max()
	local mp = biz.GetMP()
	local ok = biz.set_stat_int(mp .. POPULARITY_STAT, POPULARITY_MAX)
	if notify then
		notify.push("Nightclub", ok and "Popularity max completed" or "Popularity max failed to apply", 2000)
	end
end

local function clamp_popularity(v)
	local n = math.floor(tonumber(v) or POPULARITY_MIN)
	if n < POPULARITY_MIN then
		return POPULARITY_MIN
	end
	if n > POPULARITY_MAX then
		return POPULARITY_MAX
	end
	return n
end

local function set_popularity(value, silent)
	local mp = biz.GetMP()
	local target = clamp_popularity(value)
	local ok = biz.set_stat_int(mp .. POPULARITY_STAT, target)
	_popularity_editor_value = target
	if notify and not silent then
		notify.push("Nightclub", ok and ("Popularity set to " .. tostring(target)) or "Popularity apply failed", 2000)
	end
	return ok
end

local function get_popularity_editor_value()
	return _popularity_editor_value
end

local function set_popularity_editor_value(value)
	_popularity_editor_value = clamp_popularity(value)
end

local function apply_popularity_editor_value()
	return set_popularity(_popularity_editor_value, false)
end

local function set_popularity_lock_active(enabled)
	_popularity_lock_active = enabled == true
	if _popularity_lock_active then
		set_popularity(_popularity_editor_value, true)
	end
	if notify then
		notify.push(
			"Nightclub",
			_popularity_lock_active and "Popularity lock enabled" or "Popularity lock disabled",
			2000
		)
	end
end

local function get_popularity_lock_active()
	return _popularity_lock_active
end

local function popularity_lock_tick()
	if not _popularity_lock_active then
		return
	end
	local mp = biz.GetMP()
	local cur = biz.get_stat_int(mp .. POPULARITY_STAT, 0) or 0
	local target = clamp_popularity(_popularity_editor_value)
	local min_allowed = math.max(POPULARITY_MIN, target - 50)
	if cur < min_allowed then
		set_popularity(target, true)
	end
end

local function safe_unbrick()
	local any_ok = false
	for idx = NC_SAFE_TOP5, NC_SAFE_TOP100 do
		if biz.set_global_int(idx, 1) then
			any_ok = true
		end
	end
	local mp = biz.GetMP()
	biz.set_stat_int(mp .. SAFE_PAY_TIME_STAT, -1)
	util.yield(3000)
	if biz.set_global_int(NC_SAFE_COLLECT, 1) then
		any_ok = true
	end
	if notify then
		notify.push("Nightclub", any_ok and "Safe unbrick sequence applied" or "Safe unbrick failed", 2200)
	end
	return any_ok
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
		notify.push("Nightclub", enabled and "Raids disabled" or "Raids restored", 2000)
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
		notify.push("Nightclub", enabled and "Reminders disabled" or "Reminders restored", 2000)
	end
end

local function get_reminders_active()
	return _reminders_active
end

local nightclub_logic = {
	get_locations = get_locations,
	get_selected_loc = get_selected_loc,
	set_selected_loc = set_selected_loc,
	teleport = teleport,
	production_tick_all = production_tick_all,
	set_fast_production = set_fast_production,
	get_fast_prod_active = get_fast_prod_active,
	get_fast_prod_status = get_fast_prod_status,
	get_fast_product_options = get_fast_product_options,
	get_fast_prod_target = get_fast_prod_target,
	set_fast_prod_target = set_fast_prod_target,
	fill_all_products = fill_all_products,
	safe_collect = safe_collect,
	safe_fill = safe_fill,
	safe_unbrick = safe_unbrick,
	set_popularity_max = set_popularity_max,
	get_popularity_editor_value = get_popularity_editor_value,
	set_popularity_editor_value = set_popularity_editor_value,
	apply_popularity_editor_value = apply_popularity_editor_value,
	set_popularity_lock_active = set_popularity_lock_active,
	get_popularity_lock_active = get_popularity_lock_active,
	popularity_lock_tick = popularity_lock_tick,
	set_disable_raids = set_disable_raids,
	get_raids_active = get_raids_active,
	set_disable_reminders = set_disable_reminders,
	get_reminders_active = get_reminders_active,
}

return nightclub_logic
