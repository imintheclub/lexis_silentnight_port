local biz = require("ShillenSilent_core.businesses.shared")

-- Blip sprite ID for garment factory map icon — used for primary teleport.
local BLIP_SPRITE = 900

-- Fallback coordinates.
local GARMENT_LOCATIONS = {
	{ name = "Garment Factory (Entrance)", x = -770.8, y = -102.0, z = 37.0 },
}

local selected_loc = 1

local function get_locations()
	return GARMENT_LOCATIONS
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
		local loc = GARMENT_LOCATIONS[selected_loc]
		if not loc then
			return
		end
		x, y, z = loc.x, loc.y, loc.z
	end
	biz.run_coords_teleport("Garment Factory", "Teleported to Garment Factory", x, y, z, false, nil)
end

local garment_logic = {
	get_locations = get_locations,
	get_selected_loc = get_selected_loc,
	set_selected_loc = set_selected_loc,
	teleport = teleport,
}

return garment_logic
