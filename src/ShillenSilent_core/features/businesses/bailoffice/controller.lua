local common = require("ShillenSilent_core.ui.controller.widgets")
local i18n = require("ShillenSilent_core.i18n")
local actions = require("ShillenSilent_core.features.businesses.bailoffice.actions")

local controller = {}

local t = i18n.t

function controller.refresh_controls()
	return true
end

function controller.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local root = parent_menu:submenu(t("feature.bailoffice.name"))
	root:breaker(t("feature.bailoffice.name"))

	local teleport = root:submenu(t("bailoffice.group.teleport"))
	common.add_button(teleport, t("bailoffice.action.teleport"), actions.teleport)
	common.add_button(teleport, t("bailoffice.action.teleport_computer"), actions.teleport_computer)

	local tools = root:submenu(t("bailoffice.group.tools"))
	common.add_button(tools, t("bailoffice.action.collect_safe"), actions.collect_safe)

	controller.refresh_controls()
	return root
end

return controller
