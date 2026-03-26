local biz = require("ShillenSilent_core.businesses.shared")

-- Nightclub product stats (MP prefix + stat name).
-- Slot 0-6: Cargo, Sporting, Pharmaceutical, Cash, Organic, South American, Printing.
local PROD_STAT_BASE = "HUB_PROD_TOTAL_"
local PROD_SLOT_COUNT = 7
local PROD_MAX_UNITS = 360

-- Safe collect global flag (EE).
local NC_SAFE_COLLECT = 2708832

-- Stats.
local POPULARITY_STAT = "CLUB_POPULARITY"
local POPULARITY_MAX = 1000
local SAFE_STAT = "CLUB_SAFE_CASH_VALUE"
local SAFE_MAX = 250000

-- Tunables for raids/reminders.
local TUNABLE_DISABLE_RAIDS = "BIKER_DISABLE_DEFEND_POLICE_RAID"
local TUNABLE_REMINDERS = "BIKER_PRODUCT_REMINDER_COOLDOWN"
local REMINDER_COOLDOWN_DISABLED = 86400000
local REMINDER_COOLDOWN_DEFAULT = 300000

local _raids_default = nil
local _raids_active = false
local _reminders_default = nil
local _reminders_active = false

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
		notify.push("Nightclub", any_ok and "Production tick applied" or "All products at max / stat error", 2000)
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
		notify.push("Nightclub", any_ok and "All products filled" or "Stat write failed", 2000)
	end
end

local function safe_collect()
	local ok = biz.set_global_int(NC_SAFE_COLLECT, 1)
	if notify then
		notify.push("Nightclub", ok and "Safe collect triggered" or "Safe collect failed", 2000)
	end
end

local function safe_fill()
	local mp = biz.GetMP()
	local ok = biz.set_stat_int(mp .. SAFE_STAT, SAFE_MAX)
	if notify then
		notify.push("Nightclub", ok and "Safe filled to $250,000" or "Safe fill failed", 2000)
	end
end

local function set_popularity_max()
	local mp = biz.GetMP()
	local ok = biz.set_stat_int(mp .. POPULARITY_STAT, POPULARITY_MAX)
	if notify then
		notify.push("Nightclub", ok and "Popularity set to max" or "Popularity write failed", 2000)
	end
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
	fill_all_products = fill_all_products,
	safe_collect = safe_collect,
	safe_fill = safe_fill,
	set_popularity_max = set_popularity_max,
	set_disable_raids = set_disable_raids,
	get_raids_active = get_raids_active,
	set_disable_reminders = set_disable_reminders,
	get_reminders_active = get_reminders_active,
}

return nightclub_logic
