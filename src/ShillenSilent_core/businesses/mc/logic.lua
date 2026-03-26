local biz = require("ShillenSilent_core.businesses.shared")

-- MC sub-business slot mapping.
local MC_SUBS = {
	{ key = "meth", name = "Meth Lab", slot = 1 },
	{ key = "weed", name = "Weed Farm", slot = 2 },
	{ key = "cocaine", name = "Cocaine Lockup", slot = 3 },
	{ key = "counterfeit", name = "Counterfeit Cash", slot = 4 },
	{ key = "forgery", name = "Forgery Office", slot = 5 },
}

-- Blip sprite IDs for each MC sub-business map icon.
local MC_BLIP_SPRITES = {
	meth = 499,
	weed = 496,
	cocaine = 497,
	counterfeit = 500,
	forgery = 498,
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

-- Teleport locations per sub-business.
local MC_LOCATIONS = {
	meth = {
		{ name = "Paleto Bay", x = -58.0, y = 6465.0, z = 31.0 },
		{ name = "Terminal", x = 1381.0, y = -2106.0, z = 52.0 },
		{ name = "El Burro Heights", x = 1443.0, y = -1846.0, z = 52.0 },
		{ name = "Grand Senora Desert", x = 1009.0, y = -3196.0, z = -38.0 },
	},
	weed = {
		{ name = "San Chianski", x = 2861.0, y = 4555.0, z = 48.0 },
		{ name = "Elysian Island", x = 115.0, y = -2553.0, z = 6.0 },
		{ name = "Downtown Vinewood", x = -53.0, y = 183.0, z = 72.0 },
		{ name = "Mt Chiliad", x = 712.0, y = 5895.0, z = 18.0 },
	},
	cocaine = {
		{ name = "Paleto Bay", x = -153.0, y = 6435.0, z = 31.0 },
		{ name = "Elysian Island", x = 91.0, y = -2491.0, z = 6.0 },
		{ name = "Morningwood", x = -1169.0, y = -287.0, z = 37.0 },
		{ name = "Alamo Sea", x = 1088.0, y = -3187.0, z = -39.0 },
	},
	counterfeit = {
		{ name = "Paleto Bay", x = -132.0, y = 6256.0, z = 31.0 },
		{ name = "Cypress Flats", x = 853.0, y = -2336.0, z = 30.0 },
		{ name = "Vespucci Canals", x = -1109.0, y = -1361.0, z = 5.0 },
		{ name = "Grand Senora Desert", x = 1163.0, y = 2712.0, z = 38.0 },
	},
	forgery = {
		{ name = "Paleto Bay", x = -32.0, y = 6281.0, z = 31.0 },
		{ name = "Elysian Island", x = 111.0, y = -2528.0, z = 6.0 },
		{ name = "Textile City", x = 711.0, y = -921.0, z = 25.0 },
		{ name = "Grapeseed", x = 1910.0, y = 4773.0, z = 41.0 },
	},
}
local selected_locs = { meth = 1, weed = 1, cocaine = 1, counterfeit = 1, forgery = 1 }
local MC_ID_TO_SUB_KEY = {
	[1] = "forgery",
	[2] = "weed",
	[3] = "counterfeit",
	[4] = "meth",
	[5] = "cocaine",
}

local function get_subs()
	return MC_SUBS
end

local function get_locations(sub_key)
	return MC_LOCATIONS[sub_key] or {}
end

local function get_selected_loc(sub_key)
	return selected_locs[sub_key] or 1
end

local function set_selected_loc(sub_key, idx)
	selected_locs[sub_key] = idx
end

local function get_mc_sub_key_from_id(id)
	if not id or id <= 0 or id > 20 then
		return nil
	end
	local type_idx = ((id - 1) % 5) + 1
	return MC_ID_TO_SUB_KEY[type_idx]
end

local function get_mc_location_index_from_id(id)
	if not id or id <= 0 or id > 20 then
		return nil
	end
	return math.floor((id - 1) / 5) + 1
end

-- MC ownership is not fixed to FACTORYSLOT index per business type.
-- Scan all 5 FACTORYSLOT stats, decode business type from ID, then map to location index.
local function find_owned_mc_location(sub_key, locs)
	local mp = biz.GetMP()
	for slot = 0, 4 do
		local id = biz.get_stat_int(mp .. "FACTORYSLOT" .. tostring(slot), 0)
		if id and id > 0 and id <= 20 and get_mc_sub_key_from_id(id) == sub_key then
			local loc_idx = get_mc_location_index_from_id(id)
			if loc_idx and locs[loc_idx] then
				return locs[loc_idx]
			end
		end
	end
	return nil
end

local function teleport(sub_key)
	local locs = MC_LOCATIONS[sub_key]
	if not locs then
		return
	end
	local x, y, z = biz.get_blip_coords(MC_BLIP_SPRITES[sub_key])
	if not x then
		local loc = find_owned_mc_location(sub_key, locs) or locs[selected_locs[sub_key] or 1]
		if not loc then
			return
		end
		x, y, z = loc.x, loc.y, loc.z
	end
	biz.run_coords_teleport("MC: " .. sub_key, "Teleported to MC business", x, y, z, false, nil)
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
	get_locations = get_locations,
	get_selected_loc = get_selected_loc,
	set_selected_loc = set_selected_loc,
	teleport = teleport,
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
