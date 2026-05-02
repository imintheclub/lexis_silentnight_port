local common = require("ShillenSilent_core.ui.controller.widgets")
local i18n = require("ShillenSilent_core.i18n")
local actions = require("ShillenSilent_core.features.heists.cluckin.actions")

local controller = {}

local t = i18n.t

function controller.refresh_controls()
	return true
end

function controller.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local root = parent_menu:submenu(t("feature.cluckin.name"))
	root:breaker(t("cluckin.info.title"))
	root:breaker(t("cluckin.info.subtitle"))
	root:breaker(t("cluckin.info.max_transaction"))
	root:breaker(t("cluckin.info.cooldown"))

	local tools = root:submenu(t("cluckin.group.tools"))
	common.add_button(tools, t("cluckin.action.skip_finale"), actions.skip_to_finale)
	common.add_button(tools, t("cluckin.action.reset_progress"), actions.reset_progress)
	common.add_button(tools, t("cluckin.action.instant_finish"), actions.instant_finish)
	common.add_button(tools, t("cluckin.action.skip_cutscene"), actions.skip_cutscene)

	local danger = root:submenu(t("cluckin.group.danger"))
	danger:breaker(t("cluckin.warning.use_with_caution"))
	common.add_button(danger, t("cluckin.action.skip_cooldown"), actions.remove_cooldown)

	return root
end

return controller
