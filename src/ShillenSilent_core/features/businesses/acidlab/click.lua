local ui = require("ShillenSilent_core.ui.click.widgets")
local i18n = require("ShillenSilent_core.i18n")
local state = require("ShillenSilent_core.features.businesses.acidlab.state")
local actions = require("ShillenSilent_core.features.businesses.acidlab.actions")

local click = {}
local refs = {}
local config = require("ShillenSilent_core.ui.click.config")

local t = i18n.t

function click.refresh()
	if refs.fast_status_label then
		refs.fast_status_label.text = t("acidlab.status.fast_loop", { status = actions.get_fast_prod_status() })
	end
	if refs.fast_toggle then
		refs.fast_toggle.state = state.fast_production.active == true
	end
	return true
end

function click.register(heist_tab)
	if type(heist_tab) ~= "table" then
		return nil
	end

	local info = ui.group(heist_tab, t("acidlab.group.info"), nil, nil, nil, nil, "acidlab")
	ui.label(info, t("feature.acidlab.name"), config.colors.accent)
	ui.info(info, t("acidlab.tip.fast_loop"), config.colors.text_sec)
	ui.info(info, t("acidlab.tip.tick"), config.colors.text_sec)
	ui.info(info, t("acidlab.tip.refill"), config.colors.text_sec)
	ui.info(info, t("acidlab.tip.instant_sell"), config.colors.text_sec)
	ui.spacer(info, config.space.x2)

	local production = ui.group(heist_tab, t("acidlab.group.production"), nil, nil, nil, nil, "acidlab")
	ui.label(production, t("feature.acidlab.name"), config.colors.accent)
	refs.fast_status_label = ui.label(
		production,
		t("acidlab.status.fast_loop", { status = actions.get_fast_prod_status() }),
		config.colors.text_sec
	)
	refs.fast_toggle = ui.toggle(
		production,
		"acidlab_fast_prod",
		t("acidlab.action.production_tick_loop"),
		actions.get_fast_prod_active(),
		function(enabled)
			actions.set_fast_production(enabled)
			click.refresh()
		end
	)
	ui.button(production, "acidlab_tick", t("acidlab.action.production_tick"), actions.production_tick)
	ui.button(production, "acidlab_refill", t("acidlab.action.refill_supplies"), actions.refill_supplies)
	ui.button(production, "acidlab_sell", t("acidlab.action.instant_sell"), actions.instant_sell)

	local teleport = ui.group(heist_tab, t("acidlab.group.teleport"), nil, nil, nil, nil, "acidlab")
	ui.button(teleport, "acidlab_teleport", t("acidlab.action.teleport"), actions.teleport)

	click.refresh()
	return heist_tab
end

return click
