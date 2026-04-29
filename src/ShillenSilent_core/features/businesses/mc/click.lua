local ui = require("ShillenSilent_core.ui.click.widgets")
local i18n = require("ShillenSilent_core.i18n")
local data = require("ShillenSilent_core.features.businesses.mc.data")
local state = require("ShillenSilent_core.features.businesses.mc.state")
local actions = require("ShillenSilent_core.features.businesses.mc.actions")

local click = {}
local refs = {
	sub_toggles = {},
	sub_status = {},
}
local config = require("ShillenSilent_core.ui.click.config")

local t = i18n.t

function click.refresh()
	if refs.fast_status_label then
		refs.fast_status_label.text = t("mc.status.fast_loop", { status = actions.get_fast_prod_status() })
	end
	if refs.fast_toggle then
		refs.fast_toggle.state = state.fast_production.active == true
	end
	if refs.reminders_toggle then
		refs.reminders_toggle.state = state.protections.reminders_active == true
	end
	if refs.raids_toggle then
		refs.raids_toggle.state = state.protections.raids_active == true
	end
	for i = 1, #data.subs do
		local key = data.subs[i].key
		if refs.sub_status[key] then
			refs.sub_status[key].text = t("mc.status.loop", { status = actions.get_sub_production_loop_status(key) })
		end
		if refs.sub_toggles[key] then
			refs.sub_toggles[key].state = state.sub_production.active[key] == true
		end
	end
	return true
end

function click.register(heist_tab)
	if type(heist_tab) ~= "table" then
		return nil
	end

	local info = ui.group(heist_tab, t("mc.group.info"), nil, nil, nil, nil, "mc")
	ui.label(info, t("feature.mc.name"), config.colors.accent)
	ui.info(info, t("mc.tip.global_loop"), config.colors.text_sec)
	ui.info(info, t("mc.tip.sub_loop"), config.colors.text_sec)
	ui.info(info, t("mc.tip.black_screen"), config.colors.text_sec)
	ui.spacer(info, config.space.x2)

	local global = ui.group(heist_tab, t("mc.group.all_businesses"), nil, nil, nil, nil, "mc")
	ui.label(global, t("feature.mc.name"), config.colors.accent)
	refs.fast_status_label =
		ui.label(global, t("mc.status.fast_loop", { status = actions.get_fast_prod_status() }), config.colors.text_sec)
	ui.button(global, "mc_refill_all", t("mc.action.refill_all"), actions.refill_all_supplies)
	ui.button(global, "mc_sell", t("mc.action.instant_sell"), actions.instant_sell)
	refs.fast_toggle = ui.toggle(
		global,
		"mc_fast_prod",
		t("mc.action.production_tick_loop"),
		actions.get_fast_prod_active(),
		function(enabled)
			actions.set_fast_production(enabled)
			click.refresh()
		end
	)
	refs.reminders_toggle = ui.toggle(
		global,
		"mc_reminders",
		t("mc.action.disable_reminders"),
		actions.get_reminders_active(),
		function(enabled)
			actions.set_disable_reminders(enabled)
			click.refresh()
		end
	)
	refs.raids_toggle = ui.toggle(
		global,
		"mc_raids",
		t("mc.action.disable_raids"),
		actions.get_raids_active(),
		function(enabled)
			actions.set_disable_raids(enabled)
			click.refresh()
		end
	)
	ui.button(global, "mc_black_screen", t("mc.action.kill_black_screen"), actions.kill_black_screen)

	for i = 1, #data.subs do
		local sub = data.subs[i]
		local group = ui.group(heist_tab, t(sub.label_key), nil, nil, nil, nil, "mc")
		ui.label(group, t(sub.label_key), config.colors.text_sec)
		refs.sub_status[sub.key] = ui.label(
			group,
			t("mc.status.loop", { status = actions.get_sub_production_loop_status(sub.key) }),
			config.colors.text_sec
		)
		refs.sub_toggles[sub.key] = ui.toggle(
			group,
			"mc_tick_" .. sub.key,
			t("mc.action.production_tick_loop"),
			actions.get_sub_production_loop_active(sub.key),
			function(enabled)
				actions.set_sub_production_loop(sub.key, enabled)
				click.refresh()
			end
		)
		ui.button(group, "mc_tick_once_" .. sub.key, t("mc.action.production_tick"), function()
			actions.production_tick(sub.key)
			click.refresh()
		end)
		ui.button(group, "mc_refill_" .. sub.key, t("mc.action.refill_supplies"), function()
			actions.refill_supplies(sub.key)
		end)
		ui.button(group, "mc_teleport_" .. sub.key, t("mc.action.teleport"), function()
			actions.teleport(sub.key)
		end)
	end

	click.refresh()
	return heist_tab
end

return click
