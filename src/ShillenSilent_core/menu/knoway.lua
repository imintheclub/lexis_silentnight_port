local knoway_module = require("ShillenSilent_core.heists.knoway.all")
local common = require("ShillenSilent_core.menu.common")

local knoway_menu = {}

function knoway_menu.refresh_controls()
	return true
end

function knoway_menu.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local root = parent_menu:submenu("KnoWay")
	local tools = root:submenu("Tools")
	common.add_button(tools, "Instant Finish", function()
		knoway_module.knoway_instant_finish()
	end)
	return root
end

return knoway_menu
