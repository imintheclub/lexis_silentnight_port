local config = require("ShillenSilent_core.ui.click.config")
local ui = require("ShillenSilent_core.ui.click.widgets")
local i18n = require("ShillenSilent_core.i18n")
local data = require("ShillenSilent_core.features.businesses.garment.data")
local actions = require("ShillenSilent_core.features.businesses.garment.actions")

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

	local group = ui.group(heist_tab, t("feature.garment.name"), nil, nil, nil, nil, subtab)
	ui.label(group, t("feature.garment.name"), config.colors.accent)
	ui.button(group, "garment_teleport", t("garment.action.teleport_entrance"), actions.teleport)
	ui.button(group, "garment_computer", t("garment.action.teleport_computer"), actions.teleport_computer)
	ui.button(group, "garment_unbrick", t("garment.action.unbrick_computer"), actions.unbrick_computer)
	ui.button(group, "garment_safe_collect", t("garment.action.collect_safe"), actions.collect_safe)
	return heist_tab
end

return click
