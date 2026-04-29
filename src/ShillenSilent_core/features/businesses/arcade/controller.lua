local common = require("ShillenSilent_core.ui.controller.widgets")
local i18n = require("ShillenSilent_core.i18n")
local actions = require("ShillenSilent_core.features.businesses.arcade.actions")

local controller = {}

local t = i18n.t

function controller.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local root = parent_menu:submenu(t("feature.arcade.name"))
	root:breaker(t("feature.arcade.name"))
	common.add_button(root, t("arcade.action.collect_safe"), actions.collect_safe)
	return root
end

return controller
