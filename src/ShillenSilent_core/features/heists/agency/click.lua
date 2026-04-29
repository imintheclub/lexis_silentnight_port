local ui = require("ShillenSilent_core.ui.click.widgets")
local i18n = require("ShillenSilent_core.i18n")
local notify_core = require("ShillenSilent_core.core.notify")
local preset_ui = require("ShillenSilent_core.presets.ui")
local data = require("ShillenSilent_core.features.heists.agency.data")
local state = require("ShillenSilent_core.features.heists.agency.state")
local actions = require("ShillenSilent_core.features.heists.agency.actions")
local agency_presets = require("ShillenSilent_core.features.heists.agency.presets")

local click = {}
local refs = {}
local config = require("ShillenSilent_core.ui.click.config")

local t = i18n.t

local push = notify_core.feature("feature.agency.name")

function click.refresh()
	if refs.contract_dropdown then
		refs.contract_dropdown.value = state.contract_index()
	end
	if refs.payout_slider then
		refs.payout_slider.value = state.config.payout
	end
	if refs.collect_safe_button then
		refs.collect_safe_button.disabled = not state.flags.collect_safe_ee_only
	end
	return true
end

function click.register(heist_tab)
	if type(heist_tab) ~= "table" then
		return nil
	end

	actions.refresh_collect_safe_state()

	local info = ui.group(heist_tab, t("agency.group.info"), nil, nil, nil, 140, "agency")
	ui.label(info, t("feature.agency.name"), config.colors.accent)
	ui.label(info, t("agency.info.max_transaction"), config.colors.text_main)
	ui.label(info, t("agency.info.cooldown"), config.colors.text_sec)

	preset_ui.click_group(heist_tab, {
		feature_id = "agency",
		id_prefix = "agency",
		subtab = "agency",
		collect = agency_presets.collect,
		apply = agency_presets.apply,
		refresh = click.refresh,
	})

	local preps = ui.group(heist_tab, t("agency.group.preps"), nil, nil, nil, nil, "agency")
	local contract_options = data.localized_options(data.contracts, t)
	ui.button(preps, "agency_tp_entrance", t("agency.action.teleport_entrance"), actions.teleport_entrance)
	refs.contract_dropdown = ui.dropdown(
		preps,
		"agency_contract",
		t("agency.field.contract"),
		data.option_names(contract_options),
		state.contract_index(),
		function(opt)
			state.set_contract(data.option_value_by_name(contract_options, opt, state.config.contract))
			click.refresh()
		end
	)
	ui.button(preps, "agency_apply_preps", t("agency.action.apply_preps"), actions.apply_and_complete_preps)

	local tools = ui.group(heist_tab, t("agency.group.tools"), nil, nil, nil, nil, "agency")
	ui.button(tools, "agency_tp_computer", t("agency.action.teleport_computer"), actions.teleport_computer)
	ui.button(tools, "agency_tp_mission", t("agency.action.teleport_mission"), actions.teleport_mission)
	refs.collect_safe_button =
		ui.button(tools, "agency_collect_safe", t("agency.action.collect_safe"), actions.collect_safe)
	ui.button(tools, "agency_instant_finish", t("agency.action.instant_finish"), actions.instant_finish_new)
	ui.button(tools, "agency_skip_cutscene", t("agency.action.skip_cutscene"), actions.skip_cutscene)

	local danger = ui.group(heist_tab, t("agency.group.danger"), nil, nil, nil, nil, "agency")
	ui.label(danger, t("agency.warning.use_with_caution"), config.colors.danger_text)
	ui.button(danger, "agency_kill_cooldowns", t("agency.action.skip_cooldowns"), actions.kill_cooldowns)

	local payout = ui.group(heist_tab, t("agency.group.payout"), nil, nil, nil, nil, "agency")
	refs.payout_slider = ui.slider(
		payout,
		"agency_payout",
		t("agency.field.payout"),
		0,
		data.payout.max,
		state.config.payout,
		function(val)
			state.set_payout(val)
		end,
		nil,
		data.payout.step
	)
	ui.button(payout, "agency_payout_max", t("agency.action.max"), function()
		state.set_payout(data.payout.max)
		click.refresh()
		push("agency.notify.payout_max", 2000)
	end)
	ui.button(payout, "agency_payout_apply", t("agency.action.apply_payout"), actions.apply_payout)

	click.refresh()
	if not state.flags.collect_safe_ee_only then
		push("agency.notify.collect_safe_disabled", 2200)
	end

	return heist_tab
end

return click
