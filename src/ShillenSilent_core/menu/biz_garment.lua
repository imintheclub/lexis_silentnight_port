local garment_logic = require("ShillenSilent_core.businesses.garment.logic")
local common = require("ShillenSilent_core.menu.common")

local biz_garment = {}

function biz_garment.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local root = parent_menu:submenu("Garment Factory")
	root:breaker("Garment Factory")

	local teleport = root:submenu("Teleport")
	local locations = garment_logic.get_locations()
	for i = 1, #locations do
		local idx = i
		local loc = locations[idx]
		common.add_button(teleport, loc.name, function()
			garment_logic.set_selected_loc(idx)
			garment_logic.teleport()
		end)
	end

	return root
end

return biz_garment
