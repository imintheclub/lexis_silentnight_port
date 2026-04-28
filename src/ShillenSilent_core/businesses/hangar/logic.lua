local biz = require("ShillenSilent_core.businesses.shared")

-- Blip sprite ID for hangar map icon — used for primary teleport.
local BLIP_SPRITE = 569
-- Ownership stat fallback: MP0_HANGAR_OWNED stores the hangar property ID.
local OWNED_STAT = "HANGAR_OWNED"

-- Teleport locations (5 options). `id` matches the game's property ID.
local HANGAR_LOCATIONS = {
	{ id = 1, name = "LSIA - Hangar A17", x = -1266.0, y = -3014.0, z = 13.0 },
	{ id = 2, name = "LSIA - Hangar 1", x = -1143.0, y = -2867.0, z = 13.0 },
	{ id = 3, name = "Fort Zancudo - A2", x = -2107.0, y = 3290.0, z = 32.0 },
	{ id = 4, name = "Fort Zancudo - 3497", x = -2023.0, y = 3195.0, z = 32.0 },
	{ id = 5, name = "Fort Zancudo - 3499", x = -1889.0, y = 2979.0, z = 32.0 },
}
local selected_loc = 1

-- Hangar cargo is set via packed bool stat, not a plain stat write.
-- STAT_SET_PACKED_BOOL native + index 36828, char slots 0 and 1.
-- Stock level is read from HANGAR_CONTRABAND_TOTAL (max 50 units).
local STAT_SET_PACKED_BOOL = 0xDB8A58AEAA67CD07
local CARGO_PACKED_IDX = 36828
local CARGO_STOCK_STAT = "HANGAR_CONTRABAND_TOTAL"
local CARGO_MAX = 50
local FILL_TICK_INTERVAL_MS = 1000

local _fill_active = false
local _fill_thread_started = false

local function get_locations()
	return HANGAR_LOCATIONS
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
		local loc = biz.find_owned_location(OWNED_STAT, HANGAR_LOCATIONS) or HANGAR_LOCATIONS[selected_loc]
		if not loc then
			return
		end
		x, y, z = loc.x, loc.y, loc.z
	end
	biz.run_coords_teleport("Hangar", "Teleported to Hangar", x, y, z, false, nil)
end

local function supplier_tick()
	pcall(function()
		invoker.call(STAT_SET_PACKED_BOOL, CARGO_PACKED_IDX, true, 0)
		invoker.call(STAT_SET_PACKED_BOOL, CARGO_PACKED_IDX, true, 1)
	end)
end

local function ensure_fill_thread()
	if _fill_thread_started then
		return true
	end
	if not util or not util.create_thread then
		return false
	end

	_fill_thread_started = true
	util.create_thread(function()
		while true do
			if _fill_active then
				local mp = biz.GetMP()
				local current = biz.get_stat_int(mp .. CARGO_STOCK_STAT, 0) or 0
				if current >= CARGO_MAX then
					_fill_active = false
					if notify then
						notify.push("Hangar", "Cargo filled to max", 2000)
					end
				else
					supplier_tick()
					util.yield(FILL_TICK_INTERVAL_MS)
				end
			else
				util.yield(200)
			end
		end
	end)

	return true
end

local function fill_cargo()
	if _fill_active then
		if notify then
			notify.push("Hangar", "Fill already in progress", 1500)
		end
		return
	end
	if not ensure_fill_thread() then
		if notify then
			notify.push("Hangar", "Fill cargo unavailable on this runtime", 2200)
		end
		return
	end
	local mp = biz.GetMP()
	if (biz.get_stat_int(mp .. CARGO_STOCK_STAT, 0) or 0) >= CARGO_MAX then
		if notify then
			notify.push("Hangar", "Cargo already full", 2000)
		end
		return
	end
	_fill_active = true
end

local function stop_fill()
	if not _fill_active then
		if notify then
			notify.push("Hangar", "Fill not running", 1500)
		end
		return
	end
	_fill_active = false
	if notify then
		notify.push("Hangar", "Fill stopped", 2000)
	end
end

local function get_fill_active()
	return _fill_active
end

local hangar_logic = {
	get_locations = get_locations,
	get_selected_loc = get_selected_loc,
	set_selected_loc = set_selected_loc,
	teleport = teleport,
	fill_cargo = fill_cargo,
	stop_fill = stop_fill,
	get_fill_active = get_fill_active,
}

return hangar_logic
