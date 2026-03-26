local bailoffice_logic = require("ShillenSilent_core.businesses.bailoffice.logic")
local common = require("ShillenSilent_core.menu.common")

local biz_bailoffice = {}

function biz_bailoffice.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local root = parent_menu:submenu("Bail Office")
	root:breaker("Bail Office")

	local teleport = root:submenu("Teleport")
	local locations = bailoffice_logic.get_locations()
	for i = 1, #locations do
		local idx = i
		local loc = locations[idx]
		common.add_button(teleport, loc.name, function()
			bailoffice_logic.set_selected_loc(idx)
			bailoffice_logic.teleport()
		end)
	end

	return root
end

return biz_bailoffice
