local ui = require("ShillenSilent_core.core.ui")
local knoway_module = require("ShillenSilent_core.heists.knoway.all")
local native_api = require("ShillenSilent_core.core.native_api")

local heist_skip_cutscene = native_api.heist_skip_cutscene

local function register(heistTab)
	if type(heistTab) ~= "table" then
		return nil
	end

	local tools_group = ui.group(heistTab, "Tools", nil, nil, nil, nil, "knoway")
	ui.button_pair(
		tools_group,
		"knoway_instant_finish",
		"Instant Finish",
		function()
			knoway_module.knoway_instant_finish()
		end,
		"knoway_skip_cutscene",
		"Skip Cutscene",
		function()
			heist_skip_cutscene("KnoWay")
		end
	)

	return heistTab
end

local knoway_tabs = {
	register = register,
}

return knoway_tabs
