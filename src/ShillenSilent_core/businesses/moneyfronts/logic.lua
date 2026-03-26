local biz = require("ShillenSilent_core.businesses.shared")

local MONEYFRONTS_LOCATIONS = {
	{ name = "Car Wash (Hands On)", x = -3.0, y = -1396.5, z = 29.3, owned_stat = "SB_CAR_WASH_OWNED" },
	{ name = "Heli Tours (Higgins)", x = -749.3, y = -1510.2, z = 5.0, owned_stat = "SB_HELI_TOURS_OWNED" },
	{ name = "Weed Shop (Smoke on the Water)", x = -1162.9, y = -1566.8, z = 4.4, owned_stat = "SB_WEED_SHOP_OWNED" },
}
local selected_loc = 1

local function get_locations()
	return MONEYFRONTS_LOCATIONS
end

local function get_selected_loc()
	return selected_loc
end

local function set_selected_loc(idx)
	selected_loc = idx
end

local function is_location_owned(loc)
	if not loc or not loc.owned_stat then
		return false
	end
	local mp = biz.GetMP()
	local candidates = { mp .. loc.owned_stat, "MPX_" .. loc.owned_stat, loc.owned_stat }
	for _, stat_name in ipairs(candidates) do
		local value = biz.get_stat_int(stat_name, 0)
		if value and value > 0 then
			return true
		end
	end
	return false
end

local function pick_owned_location()
	local selected = MONEYFRONTS_LOCATIONS[selected_loc]
	if selected and is_location_owned(selected) then
		return selected
	end
	for _, loc in ipairs(MONEYFRONTS_LOCATIONS) do
		if is_location_owned(loc) then
			return loc
		end
	end
	return nil
end

local function teleport()
	local loc = pick_owned_location() or MONEYFRONTS_LOCATIONS[selected_loc]
	if not loc then
		return
	end
	biz.run_coords_teleport("Money Fronts", "Teleported to " .. loc.name, loc.x, loc.y, loc.z, false, nil)
end

local moneyfronts_logic = {
	get_locations = get_locations,
	get_selected_loc = get_selected_loc,
	set_selected_loc = set_selected_loc,
	teleport = teleport,
}

return moneyfronts_logic
