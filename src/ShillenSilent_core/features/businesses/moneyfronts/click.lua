local ui = require("ShillenSilent_core.ui.click.widgets")
local i18n = require("ShillenSilent_core.i18n")
local data = require("ShillenSilent_core.features.businesses.moneyfronts.data")
local state = require("ShillenSilent_core.features.businesses.moneyfronts.state")
local actions = require("ShillenSilent_core.features.businesses.moneyfronts.actions")

local click = {}
local refs = {}
local config = require("ShillenSilent_core.ui.click.config")

local t = i18n.t

function click.refresh()
	if refs.location_dropdown then
		refs.location_dropdown.value = state.config.location_index
	end
	if refs.heat_slider then
		refs.heat_slider.value = state.config.heat_editor_value
	end
	if refs.heat_lock_toggle then
		refs.heat_lock_toggle.state = state.flags.heat_lock_active == true
	end
	return true
end

function click.register(heist_tab, manifest)
	if type(heist_tab) ~= "table" then
		return nil
	end

	local subtab = (manifest and manifest.display_group) or data.feature_id

	local group = ui.group(heist_tab, t("feature.moneyfronts.name"), nil, nil, nil, nil, subtab)
	ui.label(group, t("feature.moneyfronts.name"), config.colors.accent)
	local locations = data.localized_locations(t)
	refs.location_dropdown = ui.dropdown(
		group,
		"mf_loc",
		t("moneyfronts.field.location"),
		data.option_names(locations),
		state.config.location_index,
		function(opt)
			state.set_location_index(data.option_value_by_name(locations, opt, state.config.location_index))
			click.refresh()
		end
	)
	ui.button(group, "mf_teleport", t("moneyfronts.action.teleport"), actions.teleport)
	refs.heat_slider = ui.slider(
		group,
		"mf_heat_value",
		t("moneyfronts.field.heat"),
		data.heat.min,
		data.heat.max,
		state.config.heat_editor_value,
		function(value)
			actions.set_heat_editor_value(value)
			click.refresh()
		end,
		t("moneyfronts.tooltip.heat"),
		data.heat.step
	)
	ui.button(group, "mf_heat_apply", t("moneyfronts.action.apply_heat"), actions.apply_heat_editor_value)
	ui.button(group, "mf_heat_reset", t("moneyfronts.action.set_heat_zero"), function()
		actions.reset_heat()
		click.refresh()
	end)
	refs.heat_lock_toggle = ui.toggle(
		group,
		"mf_heat_lock",
		t("moneyfronts.action.lock_heat_zero"),
		actions.get_heat_lock_active(),
		function(enabled)
			actions.set_heat_lock_active(enabled)
			click.refresh()
		end
	)
	ui.button(
		group,
		"mf_reset_safe_prod",
		t("moneyfronts.action.reset_safe_production"),
		actions.reset_safe_production_state
	)
	ui.button(
		group,
		"mf_carwash_safe_collect",
		t("moneyfronts.action.collect_car_wash_safe"),
		actions.car_wash_collect_safe
	)

	click.refresh()
	return heist_tab
end

return click
