local config = require("ShillenSilent_core.ui.click.config")
local ui = require("ShillenSilent_core.ui.click.widgets")
local i18n = require("ShillenSilent_core.i18n")
local data = require("ShillenSilent_core.features.businesses.bailoffice.data")
local state = require("ShillenSilent_core.features.businesses.bailoffice.state")
local actions = require("ShillenSilent_core.features.businesses.bailoffice.actions")

local click = {}
local refs = {}

local t = i18n.t

function click.refresh()
	if refs.location_dropdown then
		refs.location_dropdown.value = state.config.location_index
	end
	return true
end

function click.register(heist_tab, manifest)
	if type(heist_tab) ~= "table" then
		return nil
	end

	local subtab = (manifest and manifest.display_group) or data.feature_id

	local group = ui.group(heist_tab, t("feature.bailoffice.name"), nil, nil, nil, nil, subtab)
	ui.label(group, t("feature.bailoffice.name"), config.colors.accent)
	local locations = data.localized_locations(t)
	refs.location_dropdown = ui.dropdown(
		group,
		"bail_location",
		t("bailoffice.field.location"),
		data.option_names(locations),
		state.config.location_index,
		function(opt)
			state.set_location_index(data.option_value_by_name(locations, opt, state.config.location_index))
			click.refresh()
		end
	)
	ui.button(group, "bail_teleport", t("bailoffice.action.teleport"), actions.teleport)
	ui.button(group, "bail_computer", t("bailoffice.action.teleport_computer"), actions.teleport_computer)
	ui.button(group, "bail_safe_collect", t("bailoffice.action.collect_safe"), actions.collect_safe)
	return heist_tab
end

return click
