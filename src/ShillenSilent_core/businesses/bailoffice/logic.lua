local biz = require("ShillenSilent_core.businesses.shared")

-- Blip sprite ID for bail office map icon — used for primary teleport.
local BLIP_SPRITE = 893

-- Fallback locations.
local BAILOFFICE_LOCATIONS = {
	{ name = "Bail Office (Strawberry)", x = 97.8, y = -1286.7, z = 29.2 },
	{ name = "Bail Office (La Mesa)", x = 817.8, y = -1296.5, z = 26.3 },
	{ name = "Bail Office (Rockford)", x = -616.1, y = 53.6, z = 47.8 },
}

local selected_loc = 1

local function get_locations()
	return BAILOFFICE_LOCATIONS
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
		local loc = BAILOFFICE_LOCATIONS[selected_loc]
		if not loc then
			return
		end
		x, y, z = loc.x, loc.y, loc.z
	end
	biz.run_coords_teleport("Bail Office", "Teleported to Bail Office", x, y, z, false, nil)
end

local bailoffice_logic = {
	get_locations = get_locations,
	get_selected_loc = get_selected_loc,
	set_selected_loc = set_selected_loc,
	teleport = teleport,
}

return bailoffice_logic
