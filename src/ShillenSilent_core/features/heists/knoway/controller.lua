local common = require("ShillenSilent_core.ui.controller.widgets")
local i18n = require("ShillenSilent_core.i18n")
local data = require("ShillenSilent_core.features.heists.knoway.data")
local actions = require("ShillenSilent_core.features.heists.knoway.actions")

local controller = {}

local t = i18n.t

function controller.refresh_controls()
	return true
end

function controller.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local root = parent_menu:submenu(t(data.label_key))
	local tools = root:submenu(t("knoway.group.tools"))
	common.add_button(tools, t("knoway.action.instant_finish"), actions.instant_finish)
	common.add_button(tools, t("knoway.action.skip_cutscene"), actions.skip_cutscene)
	return root
end

return controller
