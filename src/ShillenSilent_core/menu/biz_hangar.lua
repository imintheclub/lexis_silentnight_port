local hangar_logic = require("ShillenSilent_core.businesses.hangar.logic")
local common = require("ShillenSilent_core.menu.common")

local biz_hangar = {}

function biz_hangar.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local root = parent_menu:submenu("Hangar")
	root:breaker("Hangar")

	local stock = root:submenu("Stock")
	common.add_button(stock, "Fill Cargo (Max)", function()
		hangar_logic.fill_cargo()
	end)

	common.add_button(root, "Teleport", function()
		hangar_logic.teleport()
	end)

	return root
end

return biz_hangar
