local common = require("ShillenSilent_core.ui.controller.widgets")
local i18n = require("ShillenSilent_core.i18n")
local actions = require("ShillenSilent_core.features.businesses.garment.actions")

local controller = {}

local t = i18n.t

function controller.refresh_controls()
	return true
end

function controller.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local root = parent_menu:submenu(t("feature.garment.name"))
	root:breaker(t("feature.garment.name"))

	local teleport = root:submenu(t("garment.group.teleport"))
	common.add_button(teleport, t("garment.action.teleport_entrance"), actions.teleport)
	common.add_button(teleport, t("garment.action.teleport_computer"), actions.teleport_computer)

	local tools = root:submenu(t("garment.group.tools"))
	common.add_button(tools, t("garment.action.unbrick_computer"), actions.unbrick_computer)
	common.add_button(tools, t("garment.action.collect_safe"), actions.collect_safe)

	controller.refresh_controls()
	return root
end

return controller
