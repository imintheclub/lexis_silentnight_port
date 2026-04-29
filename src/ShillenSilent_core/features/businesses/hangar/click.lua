local ui = require("ShillenSilent_core.ui.click.widgets")
local i18n = require("ShillenSilent_core.i18n")
local data = require("ShillenSilent_core.features.businesses.hangar.data")
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
	if refs.sale_price_toggle then
		refs.sale_price_toggle.state = state.config.sale_price_active == true
	end
	if refs.no_xp_toggle then
		refs.no_xp_toggle.state = state.config.no_xp == true
	end
	if refs.supplier_toggle then
		refs.supplier_toggle.state = state.config.supplier_active == true
	end
	if refs.pocket_toggle then
		refs.pocket_toggle.state = state.config.pocket_active == true
	end
	if refs.stop_slider then
		refs.stop_slider.value = state.config.pocket_stop_at
	end
	if refs.delay_slider then
		refs.delay_slider.value = state.config.pocket_delay
	end
	if refs.cooldowns_toggle then
		refs.cooldowns_toggle.state = state.config.cooldowns_active == true
	end
	return true
end

function click.register(heist_tab)
	if type(heist_tab) ~= "table" then
		return nil
	end

	local info = ui.group(heist_tab, t("hangar.group.info"), nil, nil, nil, nil, "hangar")
	ui.label(info, t("feature.hangar.name"), config.colors.accent)
	ui.info(info, t("hangar.tip.fill_loop"), config.colors.text_sec)
	ui.info(info, t("hangar.tip.fill_tick"), config.colors.text_sec)
	ui.info(info, t("hangar.tip.pocket"), config.colors.text_sec)
	ui.info(info, t("hangar.tip.stop_at"), config.colors.text_sec)
	ui.info(info, t("hangar.tip.delay"), config.colors.text_sec)
	ui.info(info, t("hangar.tip.kill_cooldowns"), config.colors.text_sec)
	ui.info(info, t("hangar.tip.max_price"), config.colors.text_sec)
	ui.info(info, t("hangar.tip.no_xp"), config.colors.text_sec)
	ui.spacer(info, config.space.x2)

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
	refs.supplier_toggle = ui.toggle(
		stock,
		"hangar_supplier",
		t("hangar.action.supplier_loop"),
		actions.get_supplier_loop_active(),
		function(enabled)
			actions.set_supplier_loop(enabled)
			click.refresh()
		end
	)

	local sale = ui.group(heist_tab, t("hangar.group.sale"), nil, nil, nil, nil, "hangar")
	refs.sale_price_toggle = ui.toggle(
		sale,
		"hangar_sale_price",
		t("hangar.action.sale_price_loop"),
		actions.get_sale_price_loop_active(),
		function(enabled)
			actions.set_sale_price_loop(enabled)
			click.refresh()
		end
	)
	refs.no_xp_toggle = ui.toggle(sale, "hangar_no_xp", t("hangar.action.no_xp"), actions.get_no_xp(), function(enabled)
		actions.set_no_xp(enabled)
		click.refresh()
	end)
	ui.button(sale, "hangar_sell", t("hangar.action.instant_sell"), actions.instant_sell)

	local teleport = ui.group(heist_tab, t("hangar.group.teleport"), nil, nil, nil, nil, "hangar")
	ui.button(teleport, "hangar_teleport", t("hangar.action.teleport"), actions.teleport)
	ui.button(teleport, "hangar_laptop_tp", t("hangar.action.teleport_laptop"), actions.teleport_laptop)
	ui.button(teleport, "hangar_laptop_open", t("hangar.action.open_laptop"), actions.open_laptop)

	local danger = ui.group(heist_tab, t("hangar.group.danger"), nil, nil, nil, nil, "hangar")
	ui.label(danger, t("hangar.warning.use_with_caution"), config.colors.danger_text)
	refs.pocket_toggle = ui.toggle(
		danger,
		"hangar_pocket",
		t("hangar.action.pocket_dimension"),
		actions.get_pocket_active(),
		function(enabled)
			actions.set_pocket_active(enabled)
			click.refresh()
		end
	)
	refs.stop_slider = ui.slider(
		danger,
		"hangar_stop_at",
		t("hangar.field.stop_at"),
		0,
		data.supplier.max_stop_at,
		state.config.pocket_stop_at,
		function(value)
			actions.set_pocket_stop_at(value)
			click.refresh()
		end,
		nil,
		data.supplier.stop_step
	)
	refs.delay_slider = ui.slider(
		danger,
		"hangar_delay",
		t("hangar.field.delay"),
		data.supplier.min_delay,
		data.supplier.max_delay,
		state.config.pocket_delay,
		function(value)
			actions.set_pocket_delay(value)
			click.refresh()
		end,
		nil,
		data.supplier.delay_step
	)
	refs.cooldowns_toggle = ui.toggle(
		danger,
		"hangar_cooldowns",
		t("hangar.action.kill_cooldowns"),
		actions.get_cooldowns_active(),
		function(enabled)
			actions.set_cooldowns(enabled)
			click.refresh()
		end
	)

	click.refresh()
	return heist_tab
end

return click
