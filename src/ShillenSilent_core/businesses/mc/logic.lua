local biz = require("ShillenSilent_core.businesses.shared")

-- MC sub-businesses. `stock_stat` is fixed by business type (PRODTOTALFORFACTORY{N}
-- where N identifies the business, not the player's slot). The factoryslot the
-- player owns each business in is resolved dynamically — see find_factoryslot_for_key.
-- `blip` is the map blip sprite for primary teleport (sylocore BLIP_SPRITES).
local MC_SUBS = {
	{ key = "meth", name = "Meth Lab", stock_stat = "PRODTOTALFORFACTORY3", cap = 20, blip = 499 },
	{ key = "weed", name = "Weed Farm", stock_stat = "PRODTOTALFORFACTORY1", cap = 80, blip = 496 },
	{ key = "cocaine", name = "Cocaine Lockup", stock_stat = "PRODTOTALFORFACTORY4", cap = 10, blip = 497 },
	{ key = "counterfeit", name = "Counterfeit Cash", stock_stat = "PRODTOTALFORFACTORY2", cap = 40, blip = 500 },
	{ key = "forgery", name = "Forgery Office", stock_stat = "PRODTOTALFORFACTORY0", cap = 60, blip = 498 },
}

-- Coord-table fallback per sub, indexed by location tier (1..4).
-- Tier is derived from prop_id: math.floor((prop_id - 1) / 5) + 1.
-- Source: sylocore/bm_downloaded.lua Teleport.MC_* tables.
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

local SUB_BY_KEY = {}
for _, sub in ipairs(MC_SUBS) do
	SUB_BY_KEY[sub.key] = sub
end

-- Property ID → MC sub key. Property IDs come in groups of 5 across 4 location tiers.
-- Reference: sylocore/bm_downloaded.lua MC_BUSINESSES (~line 4210) — the table used
-- by the actual refill code path. (A second table at ~8454 used by teleport scanning
-- has the opposite ordering; trust the refill table here.)
local PROP_ID_TO_KEY = {}
for n = 0, 3 do
	PROP_ID_TO_KEY[1 + n * 5] = "meth"
	PROP_ID_TO_KEY[2 + n * 5] = "weed"
	PROP_ID_TO_KEY[3 + n * 5] = "cocaine"
	PROP_ID_TO_KEY[4 + n * 5] = "counterfeit"
	PROP_ID_TO_KEY[5 + n * 5] = "forgery"
end

local function find_factoryslot_for_key(sub_key)
	local mp = biz.GetMP()
	for i = 0, 4 do
		local prop_id = biz.get_stat_int(mp .. "FACTORYSLOT" .. tostring(i), 0)
		if prop_id and prop_id > 0 and PROP_ID_TO_KEY[prop_id] == sub_key then
			return i
		end
	end
	return nil
end

-- Instant sell uses gb_biker_contraband_sell script locals (EE offsets).
local SELL_SCRIPT = "gb_biker_contraband_sell"
local SELL_BASE = 731
local SELL_OFF = 122
local SELL_VALUE = 15

local FAST_LOOP_INTERVAL_MS = 150

local TUNABLE_REMINDERS = "BIKER_PRODUCT_REMINDER_COOLDOWN"
local TUNABLE_DISABLE_RAIDS = "BIKER_DEFEND_MISSIONS_RAND"
local REMINDER_COOLDOWN_DISABLED = 86400000
local REMINDER_COOLDOWN_DEFAULT = 300000

local _fast_prod_active = false
local _fast_prod_thread_started = false
local _fast_prod_status = "Stopped"
local _sub_prod_active = {}
local _sub_prod_status = {}
local _sub_prod_thread_started = false
local _raids_default = nil
local _raids_active = false
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
	local factoryslot = find_factoryslot_for_key(sub_key)
	if factoryslot == nil then
		if notify then
			notify.push("MC: " .. sub.name, "Not owned in any factory slot", 2000)
		end
		return
	end
	biz.production_tick(factoryslot + 1)
	if notify then
		notify.push("MC: " .. sub.name, "Production tick completed", 2000)
	end
end

local function teleport(sub_key)
	local sub = find_sub(sub_key)
	if not sub then
		return
	end
	local label = "MC: " .. sub.name
	local x, y, z
	if sub.blip then
		x, y, z = biz.get_blip_coords(sub.blip)
	end
	if not x then
		local mp = biz.GetMP()
		for i = 0, 4 do
			local prop_id = biz.get_stat_int(mp .. "FACTORYSLOT" .. tostring(i), 0)
			if prop_id and prop_id > 0 and PROP_ID_TO_KEY[prop_id] == sub_key then
				local tier = math.floor((prop_id - 1) / 5) + 1
				local locs = MC_LOCATIONS[sub_key]
				local loc = locs and locs[tier]
				if loc then
					x, y, z = loc.x, loc.y, loc.z
				end
				break
			end
		end
	end
	if not x then
		if notify then
			notify.push(label, "Not owned in any factory slot", 2000)
		end
		return
	end
	biz.run_coords_teleport(label, "Teleported to " .. sub.name, x, y, z, false, nil)
end

local function refill_supplies(sub_key)
	local sub = find_sub(sub_key)
	if not sub then
		return
	end
	local name = sub.name
	biz.run_guarded_job("mc_refill_" .. sub_key, function()
		local factoryslot = find_factoryslot_for_key(sub_key)
		if factoryslot == nil then
			if notify then
				notify.push("MC: " .. name, "Not owned in any factory slot", 2000)
			end
			return
		end
		biz.fill_supply_slot(factoryslot + 1)
		if notify then
			notify.push("MC: " .. name, "Supplies refill completed", 2000)
		end
	end, function()
		if notify then
			notify.push("MC: " .. name, "Supplies refill failed (already in progress)", 1500)
		end
	end)
end

local function refill_all_supplies()
	biz.run_guarded_job("mc_refill_all", function()
		local mp = biz.GetMP()
		local any_owned = false
		for i = 0, 4 do
			local prop_id = biz.get_stat_int(mp .. "FACTORYSLOT" .. tostring(i), 0)
			if prop_id and prop_id > 0 then
				any_owned = true
				biz.fill_supply_slot(i + 1)
				util.yield(20)
			end
		end
		if notify then
			notify.push("Moto Club", any_owned and "All supplies refill completed" or "No owned MC businesses", 2000)
		end
	end, function()
		if notify then
			notify.push("Moto Club", "Supplies refill failed (already in progress)", 1500)
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
			notify.push("Moto Club", ok and "Instant sell completed" or "Instant sell failed to apply", 2200)
		end
	end, function()
		if notify then
			notify.push("Moto Club", "Instant sell failed (already running)", 1500)
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

						for i = 0, 4 do
							local prop_id = biz.get_stat_int(mp .. "FACTORYSLOT" .. tostring(i), 0)
							if prop_id and prop_id > 0 then
								any_owned = true
								local sub_key = PROP_ID_TO_KEY[prop_id]
								local sub = sub_key and SUB_BY_KEY[sub_key]
								if sub then
									local stock = biz.get_stat_int(mp .. sub.stock_stat, 0) or 0
									if stock < sub.cap then
										_fast_prod_status = "Running"
										biz.production_tick(i + 1)
										all_owned_full = false
									end
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
					local factoryslot = find_factoryslot_for_key(sub.key)
					if factoryslot == nil then
						_sub_prod_active[sub.key] = false
						_sub_prod_status[sub.key] = "Not Owned"
					else
						local stock = biz.get_stat_int(mp .. sub.stock_stat, 0) or 0
						if stock >= sub.cap then
							_sub_prod_active[sub.key] = false
							_sub_prod_status[sub.key] = "Full"
						else
							_sub_prod_status[sub.key] = "Running"
							biz.production_tick(factoryslot + 1)
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

local function set_disable_raids(enabled)
	if enabled then
		if _raids_default == nil then
			_raids_default = biz.get_tunable_int(TUNABLE_DISABLE_RAIDS, 5)
		end
		biz.set_tunable_int(TUNABLE_DISABLE_RAIDS, 0)
		_raids_active = true
	else
		biz.set_tunable_int(TUNABLE_DISABLE_RAIDS, _raids_default or 5)
		_raids_active = false
	end
	if notify then
		notify.push("Moto Club", enabled and "Raids disabled" or "Raids restored", 2000)
	end
end

local function get_raids_active()
	return _raids_active
end

local function kill_black_screen()
	local any_ok = false
	pcall(function()
		invoker.call(0xD4E8E24955024033, 0) -- DO_SCREEN_FADE_IN
		any_ok = true
	end)
	pcall(function()
		invoker.call(0xA6294919E56FF02A, true) -- DISPLAY_HUD
		any_ok = true
	end)
	pcall(function()
		invoker.call(0xA0EBB943C300E693, true) -- DISPLAY_RADAR
		any_ok = true
	end)
	if notify then
		notify.push("Moto Club", any_ok and "Black screen reset attempted" or "Black screen reset failed", 2200)
	end
	return any_ok
end

local mc_logic = {
	get_subs = get_subs,
	production_tick = production_tick,
	teleport = teleport,
	refill_supplies = refill_supplies,
	refill_all_supplies = refill_all_supplies,
	instant_sell = instant_sell,
	set_fast_production = set_fast_production,
	get_fast_prod_active = get_fast_prod_active,
	get_fast_prod_status = get_fast_prod_status,
	set_sub_production_loop = set_sub_production_loop,
	get_sub_production_loop_active = get_sub_production_loop_active,
	get_sub_production_loop_status = get_sub_production_loop_status,
	set_disable_raids = set_disable_raids,
	get_raids_active = get_raids_active,
	set_disable_reminders = set_disable_reminders,
	get_reminders_active = get_reminders_active,
	kill_black_screen = kill_black_screen,
}

return mc_logic
