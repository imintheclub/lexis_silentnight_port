local config = require("ShillenSilent_core.ui.click.config")
local ui = require("ShillenSilent_core.ui.click.widgets")
local i18n = require("ShillenSilent_core.i18n")
local data = require("ShillenSilent_core.features.businesses.bailoffice.data")
local actions = require("ShillenSilent_core.features.businesses.bailoffice.actions")

local click = {}

local t = i18n.t

function click.refresh()
	return true
end

function click.register(heist_tab, manifest)
	if type(heist_tab) ~= "table" then
		return nil
	end

	local subtab = (manifest and manifest.display_group) or data.feature_id

	local group = ui.group(heist_tab, t("feature.bailoffice.name"), nil, nil, nil, nil, subtab)
	ui.label(group, t("feature.bailoffice.name"), config.colors.accent)
	ui.button(group, "bail_teleport", t("bailoffice.action.teleport"), actions.teleport)
	ui.button(group, "bail_computer", t("bailoffice.action.teleport_computer"), actions.teleport_computer)
	ui.button(group, "bail_safe_collect", t("bailoffice.action.collect_safe"), actions.collect_safe)
	return heist_tab
end

return click
