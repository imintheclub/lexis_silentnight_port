local mf_logic = require("ShillenSilent_core.businesses.moneyfronts.logic")
local common = require("ShillenSilent_core.menu.common")

local biz_moneyfronts = {}

function biz_moneyfronts.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local root = parent_menu:submenu("Money Fronts")
	root:breaker("Money Fronts")

	local teleport = root:submenu("Teleport")
	local locations = mf_logic.get_locations()
	for i = 1, #locations do
		local idx = i
		local loc = locations[idx]
		common.add_button(teleport, loc.name, function()
			mf_logic.set_selected_loc(idx)
			mf_logic.teleport()
		end)
	end

	return root
end

return biz_moneyfronts
