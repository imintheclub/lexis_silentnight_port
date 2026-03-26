local ui = require("ShillenSilent_core.core.ui")
local knoway_module = require("ShillenSilent_core.heists.knoway.all")

local function register(heistTab)
	if type(heistTab) ~= "table" then
		return nil
	end

	local tools_group = ui.group(heistTab, "Tools", nil, nil, nil, nil, "knoway")
	ui.button(tools_group, "knoway_instant_finish", "Instant Finish", function()
		knoway_module.knoway_instant_finish()
	end)

	return heistTab
end

local knoway_tabs = {
	register = register,
}

return knoway_tabs
