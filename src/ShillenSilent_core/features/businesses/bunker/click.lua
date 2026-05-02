local ui = require("ShillenSilent_core.ui.click.widgets")
local i18n = require("ShillenSilent_core.i18n")
local state = require("ShillenSilent_core.features.businesses.bunker.state")
local actions = require("ShillenSilent_core.features.businesses.bunker.actions")

local click = {}
local refs = {}
local config = require("ShillenSilent_core.ui.click.config")

local t = i18n.t

function click.refresh()
	if refs.fast_status_label then
		refs.fast_status_label.text = t("bunker.status.fast_loop", { status = actions.get_fast_prod_status() })
	end
	if refs.fast_toggle then
		refs.fast_toggle.state = state.fast_production.active == true
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
	if refs.raids_toggle then
		refs.raids_toggle.state = state.protections.raids_active == true
	end
	if refs.reminders_toggle then
		refs.reminders_toggle.state = state.protections.reminders_active == true
	end
	return true
end

function click.register(heist_tab)
	if type(heist_tab) ~= "table" then
		return nil
	end

	local info = ui.group(heist_tab, t("bunker.group.info"), nil, nil, nil, nil, "bunker")
	ui.label(info, t("feature.bunker.name"), config.colors.accent)
	ui.info(info, t("bunker.tip.tick_loop"), config.colors.text_sec)
	ui.info(info, t("bunker.tip.tick"), config.colors.text_sec)
	ui.info(info, t("bunker.tip.supplier"), config.colors.text_sec)
	ui.info(info, t("bunker.tip.max_price"), config.colors.text_sec)
	ui.info(info, t("bunker.tip.no_xp"), config.colors.text_sec)
	ui.spacer(info, config.space.x2)

	local production = ui.group(heist_tab, t("bunker.group.production"), nil, nil, nil, nil, "bunker")
	ui.label(production, t("feature.bunker.name"), config.colors.accent)
	refs.fast_status_label = ui.label(
		production,
		t("bunker.status.fast_loop", { status = actions.get_fast_prod_status() }),
		config.colors.text_sec
	)
	refs.fast_toggle = ui.toggle(
		production,
		"bunker_fast_prod",
		t("bunker.action.production_tick_loop"),
		actions.get_fast_prod_active(),
		function(enabled)
			actions.set_fast_production(enabled)
			click.refresh()
		end
	)
	ui.button(production, "bunker_tick", t("bunker.action.production_tick"), actions.production_tick)
	ui.button(production, "bunker_refill", t("bunker.action.refill_supplies"), actions.refill_supplies)
	refs.supplier_toggle = ui.toggle(
		production,
		"bunker_supplier",
		t("bunker.action.supplier_loop"),
		actions.get_supplier_loop_active(),
		function(enabled)
			actions.set_supplier_loop(enabled)
			click.refresh()
		end
	)

	local sale = ui.group(heist_tab, t("bunker.group.sale"), nil, nil, nil, nil, "bunker")
	refs.sale_price_toggle = ui.toggle(
		sale,
		"bunker_sale_price",
		t("bunker.action.sale_price_loop"),
		actions.get_sale_price_loop_active(),
		function(enabled)
			actions.set_sale_price_loop(enabled)
			click.refresh()
		end
	)
	refs.no_xp_toggle = ui.toggle(sale, "bunker_no_xp", t("bunker.action.no_xp"), actions.get_no_xp(), function(enabled)
		actions.set_no_xp(enabled)
		click.refresh()
	end)
	ui.button(production, "bunker_sell", t("bunker.action.instant_sell"), actions.instant_sell)

	local protect = ui.group(heist_tab, t("bunker.group.protections"), nil, nil, nil, nil, "bunker")
	refs.raids_toggle = ui.toggle(
		protect,
		"bunker_raids",
		t("bunker.action.disable_raids"),
		actions.get_raids_active(),
		function(enabled)
			actions.set_disable_raids(enabled)
			click.refresh()
		end
	)
	refs.reminders_toggle = ui.toggle(
		protect,
		"bunker_reminders",
		t("bunker.action.disable_reminders"),
		actions.get_reminders_active(),
		function(enabled)
			actions.set_disable_reminders(enabled)
			click.refresh()
		end
	)

	local teleport = ui.group(heist_tab, t("bunker.group.teleport"), nil, nil, nil, nil, "bunker")
	ui.button(teleport, "bunker_teleport", t("bunker.action.teleport"), actions.teleport)
	ui.button(teleport, "bunker_laptop_tp", t("bunker.action.teleport_laptop"), actions.teleport_laptop)

	local tools = ui.group(heist_tab, t("bunker.group.tools"), nil, nil, nil, nil, "bunker")
	ui.button(tools, "bunker_laptop_open", t("bunker.action.open_laptop"), actions.open_laptop)

	click.refresh()
	return heist_tab
end

return click
