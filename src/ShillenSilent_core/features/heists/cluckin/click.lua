local ui = require("ShillenSilent_core.ui.click.widgets")
local i18n = require("ShillenSilent_core.i18n")
local data = require("ShillenSilent_core.features.heists.cluckin.data")
local actions = require("ShillenSilent_core.features.heists.cluckin.actions")

local config = require("ShillenSilent_core.ui.click.config")

local click = {}

local t = i18n.t

function click.refresh()
	return true
end

local function register(heistTab)
	if type(heistTab) ~= "table" then
		return nil
	end

	local info = ui.group(heistTab, t("cluckin.group.info"), nil, nil, nil, 140, data.feature_id)
	ui.label(info, t("cluckin.info.title"), config.colors.accent)
	ui.label(info, t("cluckin.info.subtitle"), config.colors.text_main)
	ui.label(info, t("cluckin.info.max_transaction"), config.colors.text_main)
	ui.label(info, t("cluckin.info.cooldown"), config.colors.text_sec)
	ui.spacer(info, config.space.x2)

	local tools = ui.group(heistTab, t("cluckin.group.tools"), nil, nil, nil, nil, data.feature_id)
	ui.button(tools, "cluckin_skip_finale", t("cluckin.action.skip_finale"), actions.skip_to_finale)
	ui.button(tools, "cluckin_reset_progress", t("cluckin.action.reset_progress"), actions.reset_progress)
	ui.button(tools, "cluckin_instant_finish", t("cluckin.action.instant_finish"), actions.instant_finish)
	ui.button(tools, "cluckin_skip_cutscene", t("cluckin.action.skip_cutscene"), actions.skip_cutscene)

	local danger = ui.group(heistTab, t("cluckin.group.danger"), nil, nil, nil, nil, data.feature_id)
	ui.label(danger, t("cluckin.warning.use_with_caution"), config.colors.danger_text)
	ui.button(
		danger,
		"cluckin_remove_cooldown",
		t("cluckin.action.skip_cooldown"),
		actions.remove_cooldown,
		nil,
		false,
		"danger"
	)
	return heistTab
end

click.register = register

return click
