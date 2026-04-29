local ui = require("ShillenSilent_core.ui.click.widgets")
local i18n = require("ShillenSilent_core.i18n")
local state = require("ShillenSilent_core.features.businesses.hangar.state")
local actions = require("ShillenSilent_core.features.businesses.hangar.actions")

local click = {}
local refs = {}
local config = require("ShillenSilent_core.ui.click.config")

local t = i18n.t

function click.refresh()
	if refs.fill_toggle_label then
		refs.fill_toggle_label.text =
			t(state.fill.active and "hangar.status.fill_running" or "hangar.status.fill_stopped")
	end
	if refs.fill_toggle then
		refs.fill_toggle.state = state.fill.active == true
	end
	return true
end

function click.register(heist_tab)
	if type(heist_tab) ~= "table" then
		return nil
	end

	local stock = ui.group(heist_tab, t("hangar.group.stock"), nil, nil, nil, nil, "hangar")
	ui.label(stock, t("feature.hangar.name"), config.colors.accent)
	refs.fill_toggle_label = ui.label(
		stock,
		t(state.fill.active and "hangar.status.fill_running" or "hangar.status.fill_stopped"),
		config.colors.text_sec
	)
	refs.fill_toggle = ui.toggle(
		stock,
		"hangar_fill_loop",
		t("hangar.action.fill_loop"),
		actions.get_fill_active(),
		function(enabled)
			actions.set_fill_loop(enabled)
			click.refresh()
		end
	)
	ui.button(stock, "hangar_fill_tick", t("hangar.action.fill_tick"), function()
		actions.fill_tick_once()
		click.refresh()
	end)

	local teleport = ui.group(heist_tab, t("hangar.group.teleport"), nil, nil, nil, nil, "hangar")
	ui.button(teleport, "hangar_teleport", t("hangar.action.teleport"), actions.teleport)

	click.refresh()
	return heist_tab
end

return click
