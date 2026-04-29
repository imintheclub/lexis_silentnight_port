local ui = require("ShillenSilent_core.ui.click.widgets")
local i18n = require("ShillenSilent_core.i18n")
local data = require("ShillenSilent_core.features.businesses.nightclub.data")
local state = require("ShillenSilent_core.features.businesses.nightclub.state")
local actions = require("ShillenSilent_core.features.businesses.nightclub.actions")

local click = {}
local refs = {}
local config = require("ShillenSilent_core.ui.click.config")

local t = i18n.t

function click.refresh()
	if refs.fast_status_label then
		refs.fast_status_label.text = t("nightclub.status.fast_loop", { status = actions.get_fast_prod_status() })
	end
	if refs.fast_target_dropdown then
		refs.fast_target_dropdown.value =
			data.option_index_by_value(data.fast_product_options, state.config.fast_prod_target, 1)
	end
	if refs.fast_toggle then
		refs.fast_toggle.state = state.fast_production.active == true
	end
	if refs.sale_price_toggle then
		refs.sale_price_toggle.state = state.config.sale_price_active == true
	end
	if refs.cooldowns_toggle then
		refs.cooldowns_toggle.state = state.config.cooldowns_active == true
	end
	if refs.popularity_slider then
		refs.popularity_slider.value = state.config.popularity_editor_value
	end
	if refs.popularity_lock_toggle then
		refs.popularity_lock_toggle.state = state.popularity.lock_active == true
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

	local info = ui.group(heist_tab, t("nightclub.group.info"), nil, nil, nil, nil, "nightclub")
	ui.label(info, t("feature.nightclub.name"), config.colors.accent)
	ui.info(info, t("nightclub.tip.fast_target"), config.colors.text_sec)
	ui.info(info, t("nightclub.tip.prod_increase"), config.colors.text_sec)
	ui.info(info, t("nightclub.tip.prod_tick"), config.colors.text_sec)
	ui.info(info, t("nightclub.tip.unbrick"), config.colors.text_sec)
	ui.info(info, t("nightclub.tip.max_price"), config.colors.text_sec)
	ui.info(info, t("nightclub.tip.kill_cooldowns"), config.colors.text_sec)
	ui.info(info, t("nightclub.tip.skip_setup"), config.colors.text_sec)
	ui.info(info, t("nightclub.tip.products"), config.colors.text_sec)
	ui.info(info, t("nightclub.tip.products2"), config.colors.text_sec)
	ui.spacer(info, config.space.x2)

	local prod = ui.group(heist_tab, t("nightclub.group.production"), nil, nil, nil, nil, "nightclub")
	ui.label(prod, t("feature.nightclub.name"), config.colors.accent)
	refs.fast_status_label = ui.label(
		prod,
		t("nightclub.status.fast_loop", { status = actions.get_fast_prod_status() }),
		config.colors.text_sec
	)
	local target_options = actions.get_fast_product_options()
	refs.fast_target_dropdown = ui.dropdown(
		prod,
		"nc_fast_target",
		t("nightclub.field.fast_target"),
		data.option_names(target_options),
		data.option_index_by_value(target_options, state.config.fast_prod_target, 1),
		function(opt)
			actions.set_fast_prod_target(data.option_value_by_name(target_options, opt, state.config.fast_prod_target))
			click.refresh()
		end
	)
	refs.fast_toggle = ui.toggle(
		prod,
		"nc_tick",
		t("nightclub.action.fast_production"),
		actions.get_fast_prod_active(),
		function(enabled)
			actions.set_fast_production(enabled)
			click.refresh()
		end
	)
	ui.button(prod, "nc_tick_once", t("nightclub.action.production_tick"), actions.production_tick)
	refs.sale_price_toggle = ui.toggle(
		prod,
		"nc_sale_price",
		t("nightclub.action.sale_price_loop"),
		actions.get_sale_price_loop_active(),
		function(enabled)
			actions.set_sale_price_loop(enabled)
			click.refresh()
		end
	)

	local safe = ui.group(heist_tab, t("nightclub.group.safe"), nil, nil, nil, nil, "nightclub")
	ui.button(safe, "nc_safe_collect", t("nightclub.action.collect_safe"), actions.safe_collect)
	ui.button(safe, "nc_safe_fill", t("nightclub.action.fill_safe"), actions.safe_fill)
	ui.button(safe, "nc_safe_unbrick", t("nightclub.action.unbrick_safe"), actions.safe_unbrick)

	local pop = ui.group(heist_tab, t("nightclub.group.popularity"), nil, nil, nil, nil, "nightclub")
	refs.popularity_slider = ui.slider(
		pop,
		"nc_popularity_value",
		t("nightclub.field.popularity"),
		data.popularity.min,
		data.popularity.max,
		state.config.popularity_editor_value,
		function(value)
			actions.set_popularity_editor_value(value)
			click.refresh()
		end,
		nil,
		data.popularity.step
	)
	ui.button(pop, "nc_pop_apply", t("nightclub.action.apply_popularity"), actions.apply_popularity_editor_value)
	ui.button(pop, "nc_pop_max", t("nightclub.action.max_popularity"), function()
		actions.set_popularity_max()
		click.refresh()
	end)
	ui.button(pop, "nc_pop_min", t("nightclub.action.min_popularity"), function()
		actions.set_popularity_min()
		click.refresh()
	end)
	refs.popularity_lock_toggle = ui.toggle(
		pop,
		"nc_pop_lock",
		t("nightclub.action.lock_popularity"),
		actions.get_popularity_lock_active(),
		function(enabled)
			actions.set_popularity_lock_active(enabled)
			click.refresh()
		end
	)

	local protect = ui.group(heist_tab, t("nightclub.group.protections"), nil, nil, nil, nil, "nightclub")
	refs.raids_toggle = ui.toggle(
		protect,
		"nc_raids",
		t("nightclub.action.disable_raids"),
		actions.get_raids_active(),
		function(enabled)
			actions.set_disable_raids(enabled)
			click.refresh()
		end
	)
	refs.reminders_toggle = ui.toggle(
		protect,
		"nc_reminders",
		t("nightclub.action.disable_reminders"),
		actions.get_reminders_active(),
		function(enabled)
			actions.set_disable_reminders(enabled)
			click.refresh()
		end
	)

	local teleport = ui.group(heist_tab, t("nightclub.group.teleport"), nil, nil, nil, nil, "nightclub")
	ui.button(teleport, "nc_teleport", t("nightclub.action.teleport"), actions.teleport)
	ui.button(teleport, "nc_computer_tp", t("nightclub.action.teleport_computer"), actions.teleport_computer)
	ui.button(teleport, "nc_computer_open", t("nightclub.action.open_computer"), actions.open_computer)
	ui.button(teleport, "nc_setup", t("nightclub.action.skip_setup"), actions.skip_setup)

	local danger = ui.group(heist_tab, t("nightclub.group.danger"), nil, nil, nil, nil, "nightclub")
	ui.label(danger, t("nightclub.warning.use_with_caution"), config.colors.danger_text)
	refs.cooldowns_toggle = ui.toggle(
		danger,
		"nc_cooldowns",
		t("nightclub.action.kill_cooldowns"),
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
