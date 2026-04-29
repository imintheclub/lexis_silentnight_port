local ui = require("ShillenSilent_core.ui.click.widgets")
local i18n = require("ShillenSilent_core.i18n")
local data = require("ShillenSilent_core.features.businesses.speccargo.data")
local state = require("ShillenSilent_core.features.businesses.speccargo.state")
local actions = require("ShillenSilent_core.features.businesses.speccargo.actions")

local click = {}
local refs = {}
local config = require("ShillenSilent_core.ui.click.config")

local t = i18n.t

function click.refresh()
	if refs.fill_status_label then
		refs.fill_status_label.text =
			t(state.fill.active and "speccargo.status.fill_running" or "speccargo.status.fill_stopped")
	end
	if refs.fill_toggle then
		refs.fill_toggle.state = state.fill.active == true
	end
	if refs.raids_toggle then
		refs.raids_toggle.state = state.protections.raids_active == true
	end
	if refs.reminders_toggle then
		refs.reminders_toggle.state = state.protections.reminders_active == true
	end
	if refs.location_dropdown then
		refs.location_dropdown.value = state.config.location_index
	end
	return true
end

function click.register(heist_tab)
	if type(heist_tab) ~= "table" then
		return nil
	end

	local stock = ui.group(heist_tab, t("speccargo.group.stock"), nil, nil, nil, nil, "speccargo")
	ui.label(stock, t("feature.speccargo.name"), config.colors.accent)
	refs.fill_status_label = ui.label(
		stock,
		t(state.fill.active and "speccargo.status.fill_running" or "speccargo.status.fill_stopped"),
		config.colors.text_sec
	)
	ui.button(stock, "sc_instant_sell", t("speccargo.action.instant_sell"), actions.instant_sell)
	refs.fill_toggle = ui.toggle(
		stock,
		"sc_fill_loop",
		t("speccargo.action.fill_loop"),
		actions.get_fill_active(),
		function(enabled)
			actions.set_fill_loop(enabled)
			click.refresh()
		end
	)
	ui.button(stock, "sc_fill_tick", t("speccargo.action.fill_tick"), function()
		actions.fill_tick_once()
		click.refresh()
	end)

	local protect = ui.group(heist_tab, t("speccargo.group.protections"), nil, nil, nil, nil, "speccargo")
	refs.raids_toggle = ui.toggle(
		protect,
		"sc_raids",
		t("speccargo.action.disable_raids"),
		actions.get_raids_active(),
		function(enabled)
			actions.set_disable_raids(enabled)
			click.refresh()
		end
	)
	refs.reminders_toggle = ui.toggle(
		protect,
		"sc_reminders",
		t("speccargo.action.disable_reminders"),
		actions.get_reminders_active(),
		function(enabled)
			actions.set_disable_reminders(enabled)
			click.refresh()
		end
	)

	local teleport = ui.group(heist_tab, t("speccargo.group.teleport"), nil, nil, nil, nil, "speccargo")
	local locations = actions.get_locations()
	local localized_locations = data.localized_locations(locations, t)
	if #localized_locations > 0 then
		refs.location_dropdown = ui.dropdown(
			teleport,
			"sc_loc",
			t("speccargo.field.location"),
			data.option_names(localized_locations),
			state.config.location_index,
			function(opt)
				state.set_location_index(
					data.option_value_by_name(localized_locations, opt, state.config.location_index),
					#localized_locations
				)
				click.refresh()
			end
		)
		ui.button(teleport, "sc_teleport", t("speccargo.action.teleport"), actions.teleport)
	else
		ui.label(teleport, t("speccargo.notify.no_owned_warehouses"), config.colors.muted_text)
	end

	click.refresh()
	return heist_tab
end

return click
