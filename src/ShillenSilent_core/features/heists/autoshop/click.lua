local ui = require("ShillenSilent_core.ui.click.widgets")
local i18n = require("ShillenSilent_core.i18n")
local notify_core = require("ShillenSilent_core.core.notify")
local preset_ui = require("ShillenSilent_core.presets.ui")
local data = require("ShillenSilent_core.features.heists.autoshop.data")
local state = require("ShillenSilent_core.features.heists.autoshop.state")
local actions = require("ShillenSilent_core.features.heists.autoshop.actions")
local autoshop_presets = require("ShillenSilent_core.features.heists.autoshop.presets")

local click = {}
local refs = {}
local config = require("ShillenSilent_core.ui.click.config")

local t = i18n.t

function click.refresh()
	if refs.contract_dropdown then
		refs.contract_dropdown.value = state.contract_index()
	end
	if refs.payout_slider then
		refs.payout_slider.value = state.config.payout
	end
end

function click.register(heist_tab)
	if type(heist_tab) ~= "table" then
		return nil
	end

	local info = ui.group(heist_tab, t("autoshop.group.info"), nil, nil, nil, nil, "autoshop")
	ui.label(info, t("feature.autoshop.name"), config.colors.accent)
	ui.label(info, t("autoshop.info.max_transaction"), config.colors.text_main)
	ui.label(info, t("autoshop.info.cooldown"), config.colors.text_sec)
	ui.spacer(info, config.space.x2)
	preset_ui.click_group(heist_tab, {
		feature_id = "autoshop",
		id_prefix = "autoshop",
		subtab = "autoshop",
		collect = autoshop_presets.collect,
		apply = autoshop_presets.apply,
		refresh = click.refresh,
	})

	local preps = ui.group(heist_tab, t("autoshop.group.preps"), nil, nil, nil, nil, "autoshop")
	refs.contract_dropdown = ui.dropdown(
		preps,
		"autoshop_contract",
		t("autoshop.field.contract"),
		data.option_names(data.contracts),
		state.contract_index(),
		function(opt)
			state.set_contract(data.option_value_by_name(data.contracts, opt, state.config.contract))
			click.refresh()
		end
	)
	ui.button(preps, "autoshop_apply_preps", t("autoshop.action.apply_preps"), actions.apply_and_complete_preps)
	ui.button(preps, "autoshop_reset_preps", t("autoshop.action.reset_preps"), actions.reset_preps)
	ui.button(preps, "autoshop_redraw_board", t("autoshop.action.redraw_board"), actions.redraw_board)

	local teleport = ui.group(heist_tab, t("autoshop.group.teleport"), nil, nil, nil, nil, "autoshop")
	ui.button(teleport, "autoshop_tp_entrance", t("autoshop.action.teleport_entrance"), actions.teleport_entrance)
	ui.button(teleport, "autoshop_tp_board", t("autoshop.action.teleport_board"), actions.teleport_board)

	local tools = ui.group(heist_tab, t("autoshop.group.tools"), nil, nil, nil, nil, "autoshop")
	ui.button(tools, "autoshop_instant_finish", t("autoshop.action.instant_finish"), actions.instant_finish_new)
	ui.button(tools, "autoshop_skip_cutscene", t("autoshop.action.skip_cutscene"), actions.skip_cutscene)

	local danger = ui.group(heist_tab, t("autoshop.group.danger"), nil, nil, nil, nil, "autoshop")
	ui.label(danger, t("autoshop.warning.use_with_caution"), config.colors.danger_text)
	ui.button(danger, "autoshop_kill_cooldown", t("autoshop.action.skip_cooldowns"), actions.kill_cooldowns)

	local payout = ui.group(heist_tab, t("autoshop.group.payout"), nil, nil, nil, nil, "autoshop")
	refs.payout_slider = ui.slider(
		payout,
		"autoshop_payout",
		t("autoshop.field.payout"),
		0,
		data.payout.max,
		state.config.payout,
		function(val)
			state.set_payout(val)
		end,
		nil,
		data.payout.step
	)
	ui.button(payout, "autoshop_payout_max", t("autoshop.action.max"), function()
		state.set_payout(data.payout.max)
		click.refresh()
		notify_core.raw(t("feature.autoshop.name"), t("autoshop.notify.payout_max"), 2000)
	end)
	ui.button(payout, "autoshop_payout_apply", t("autoshop.action.apply_payout"), actions.apply_payout)

	return heist_tab
end

return click
