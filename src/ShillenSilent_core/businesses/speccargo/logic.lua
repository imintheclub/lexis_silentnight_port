local biz = require("ShillenSilent_core.businesses.shared")

-- Special Cargo warehouses (22 locations).
local SPECCARGO_LOCATIONS = {
	{ id = 1, name = "Pacific Bait Storage", x = 51.31, y = -2568.47, z = 6.00 },
	{ id = 2, name = "White Widow Garage", x = -1081.08, y = -1261.01, z = 5.65 },
	{ id = 3, name = "Celltowa Unit", x = 898.48, y = -1031.88, z = 34.97 },
	{ id = 4, name = "Convenience Store Lockup", x = 249.25, y = -1955.65, z = 23.16 },
	{ id = 5, name = "Foreclosed Garage", x = -424.77, y = 184.15, z = 80.75 },
	{ id = 6, name = "Xero Gas Factory", x = -1045.00, y = -2023.15, z = 13.16 },
	{ id = 7, name = "Derriere Lingerie Backlot", x = -1269.29, y = -813.22, z = 17.11 },
	{ id = 8, name = "Bilgeco Warehouse", x = -876.11, y = -2734.50, z = 13.84 },
	{ id = 9, name = "Pier 400 Utility Building", x = 272.41, y = -3015.27, z = 5.71 },
	{ id = 10, name = "GEE Warehouse", x = 1563.83, y = -2135.11, z = 77.62 },
	{ id = 11, name = "LS Marine Building 3", x = -308.77, y = -2698.39, z = 6.00 },
	{ id = 12, name = "Railyard Warehouse", x = 503.74, y = -653.08, z = 24.75 },
	{ id = 13, name = "Fridgit Annexe", x = -528.07, y = -1782.70, z = 21.48 },
	{ id = 14, name = "Disused Factory Outlet", x = -328.01, y = -1354.76, z = 31.30 },
	{ id = 15, name = "Discount Retail Unit", x = 349.90, y = 327.98, z = 104.30 },
	{ id = 16, name = "Logistics Depot", x = 922.56, y = -1560.05, z = 30.76 },
	{ id = 17, name = "Darnell Bros Warehouse", x = 762.67, y = -909.19, z = 25.25 },
	{ id = 18, name = "Wholesale Furniture", x = 1041.06, y = -2172.65, z = 31.49 },
	{ id = 19, name = "Cypress Warehouses", x = 1015.36, y = -2510.99, z = 28.30 },
	{ id = 20, name = "West Vinewood Backlot", x = -245.65, y = 202.50, z = 83.79 },
	{ id = 21, name = "Old Power Station", x = 541.59, y = -1944.36, z = 24.99 },
	{ id = 22, name = "Walker & Sons Warehouse", x = 93.28, y = -2216.14, z = 6.03 },
}
local selected_loc = 1

-- Special cargo stock stat.
local CARGO_STAT = "CRATE_WAREHOUSE_CARGO"
local CARGO_MAX = 111

-- Instant sell script locals (EE offsets).
local SELL_SCRIPT = "gb_contraband_sell"
local SELL_BASE = 569
local SELL_TIMER_OFF = 1 -- abs 570, value 67230 (timer)
local SELL_STATE_OFF = 7 -- abs 576, value 7 (state)

-- Tunables.
local TUNABLE_DISABLE_RAIDS = "BIKER_DISABLE_DEFEND_POLICE_RAID"
local TUNABLE_REMINDERS = "BIKER_PRODUCT_REMINDER_COOLDOWN"
local REMINDER_COOLDOWN_DISABLED = 86400000
local REMINDER_COOLDOWN_DEFAULT = 300000

local _raids_default = nil
local _raids_active = false
local _reminders_default = nil
local _reminders_active = false

local function get_owned_warehouse_ids()
	local owned = {}
	local mp = biz.GetMP()
	for slot = 0, 4 do
		local warehouse_id = biz.get_stat_int(mp .. "PROP_WHOUSE_SLOT" .. tostring(slot), 0)
		if warehouse_id and warehouse_id > 0 then
			owned[warehouse_id] = true
		end
	end
	return owned
end

local function get_locations()
	local owned_ids = get_owned_warehouse_ids()
	local owned_locations = {}
	for _, loc in ipairs(SPECCARGO_LOCATIONS) do
		if loc.id and owned_ids[loc.id] then
			table.insert(owned_locations, loc)
		end
	end
	if selected_loc > #owned_locations then
		selected_loc = 1
	end
	return owned_locations
end

local function get_selected_loc()
	return selected_loc
end

local function set_selected_loc(idx)
	selected_loc = idx
end

local function teleport()
	local locs = get_locations()
	local loc = locs[selected_loc]
	if not loc then
		return
	end
	biz.run_coords_teleport("Special Cargo", "Teleported to " .. loc.name, loc.x, loc.y, loc.z, false, nil)
end

local function instant_sell()
	biz.run_guarded_job("sc_sell", function()
		if not biz.is_script_running(SELL_SCRIPT) then
			if notify then
				notify.push("Special Cargo", "Start your Special Cargo sell mission first", 2200)
			end
			return
		end
		local ok1 = biz.set_local_int(SELL_SCRIPT, SELL_BASE + SELL_TIMER_OFF, 67230)
		local ok2 = biz.set_local_int(SELL_SCRIPT, SELL_BASE + SELL_STATE_OFF, 7)
		if notify then
			notify.push(
				"Special Cargo",
				(ok1 and ok2) and "Instant sell completed" or "Instant sell failed to apply",
				2200
			)
		end
	end, function()
		if notify then
			notify.push("Special Cargo", "Instant sell failed (already running)", 1500)
		end
	end)
end

local function fill_cargo()
	local mp = biz.GetMP()
	local ok = biz.set_stat_int(mp .. CARGO_STAT, CARGO_MAX)
	if notify then
		notify.push("Special Cargo", ok and "All cargo fill completed (111)" or "Cargo fill failed to apply", 2000)
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
		notify.push("Special Cargo", enabled and "Raids disabled" or "Raids restored", 2000)
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
		notify.push("Special Cargo", enabled and "Reminders disabled" or "Reminders restored", 2000)
	end
end

local function get_reminders_active()
	return _reminders_active
end

local speccargo_logic = {
	get_locations = get_locations,
	get_selected_loc = get_selected_loc,
	set_selected_loc = set_selected_loc,
	teleport = teleport,
	instant_sell = instant_sell,
	fill_cargo = fill_cargo,
	set_disable_raids = set_disable_raids,
	get_raids_active = get_raids_active,
	set_disable_reminders = set_disable_reminders,
	get_reminders_active = get_reminders_active,
}

return speccargo_logic
