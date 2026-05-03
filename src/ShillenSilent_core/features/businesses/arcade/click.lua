local config = require("ShillenSilent_core.ui.click.config")
local ui = require("ShillenSilent_core.ui.click.widgets")
local i18n = require("ShillenSilent_core.i18n")
local actions = require("ShillenSilent_core.features.businesses.arcade.actions")

local click = {}

local t = i18n.t

function click.register(heist_tab, manifest)
	if type(heist_tab) ~= "table" then
		return nil
	end

	local subtab = (manifest and manifest.display_group) or "arcade"

	local group = ui.group(heist_tab, t("feature.arcade.name"), nil, nil, nil, nil, subtab)
	ui.label(group, t("feature.arcade.name"), config.colors.accent)
	ui.button(group, "arcade_teleport", t("arcade.action.teleport"), actions.teleport)
	ui.button(group, "arcade_safe_collect", t("arcade.action.collect_safe"), actions.collect_safe)
	return heist_tab
end

return click
