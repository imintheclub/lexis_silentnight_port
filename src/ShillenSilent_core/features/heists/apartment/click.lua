local ui = require("ShillenSilent_core.ui.click.widgets")
local i18n = require("ShillenSilent_core.i18n")
local preset_ui = require("ShillenSilent_core.presets.ui")
local data = require("ShillenSilent_core.features.heists.apartment.data")
local state = require("ShillenSilent_core.features.heists.apartment.state")
local actions = require("ShillenSilent_core.features.heists.apartment.actions")
local apartment_presets = require("ShillenSilent_core.features.heists.apartment.presets")

local click = {}
local refs = {}
local config = require("ShillenSilent_core.ui.click.config")
local core_state = require("ShillenSilent_core.shared.runtime_state")

local t = i18n.t

local function localized_options(options)
	return data.localized_options(options, t)
end

function click.refresh()
	if refs.solo_launch_toggle then
		refs.solo_launch_toggle.state = core_state.solo_launch.apartment and true or false
	end
	if refs.bonus_toggle then
		refs.bonus_toggle.state = state.flags.bonus_enabled and true or false
	end
	if refs.double_toggle then
		refs.double_toggle.state = state.flags.double_rewards_week and true or false
	end
	if refs.max_payout_toggle then
		refs.max_payout_toggle.state = state.flags.max_payout_enabled and true or false
	end
	if refs.auto_force_toggle then
		refs.auto_force_toggle.state = state.flags.auto_force_cuts and true or false
	end
	if refs.preset_dropdown then
		refs.preset_dropdown.value = data.clamp_cut_preset_index(state.flags.cut_preset_index)
	end

	for i = 1, #data.player_keys do
		local key = data.player_keys[i]
		local slider = refs[key .. "_slider"]
		local toggle = refs[key .. "_toggle"]
		if slider then
			slider.value = data.clamp_cut(state.cuts[key])
		end
		if toggle then
			toggle.state = state.cut_enabled[key] and true or false
		end
	end
	return true
end

local function bind_cut_controls(group, player_key, slider_id, toggle_id, slider_label, toggle_label)
	refs[player_key .. "_slider"] = ui.slider(
		group,
		slider_id,
		t(slider_label),
		data.cuts.min,
		data.cuts.max,
		state.cuts[player_key],
		function(value)
			state.set_cut(player_key, value)
		end,
		nil,
		data.cuts.step
	)
	refs[player_key .. "_toggle"] = ui.toggle(
		group,
		toggle_id,
		t(toggle_label),
		state.cut_enabled[player_key],
		function(enabled)
			state.set_cut_enabled(player_key, enabled)
		end
	)
end

function click.register(heist_tab)
	if type(heist_tab) ~= "table" then
		return nil
	end

	local info = ui.group(heist_tab, t("apartment.group.info"), nil, nil, nil, 160, "apartment")
	ui.label(info, t("apartment.info.title"), config.colors.accent)
	ui.label(info, t("apartment.info.max_transaction"), config.colors.text_main)
	ui.label(info, t("apartment.info.transaction_cooldown"), config.colors.text_sec)
	ui.label(info, t("apartment.info.criminal_mastermind"), config.colors.text_sec)
	ui.label(info, t("apartment.info.heist_cooldown"), config.colors.text_sec)

	local launch = ui.group(heist_tab, t("apartment.group.launch"), nil, nil, nil, nil, "apartment")
	ui.button(
		launch,
		"apartment_tp_entrance_launch",
		t("apartment.action.teleport_entrance"),
		actions.teleport_entrance
	)
	refs.solo_launch_toggle = ui.toggle(
		launch,
		"apartment_launch_solo",
		t("apartment.action.solo_launch"),
		core_state.solo_launch.apartment,
		function(enabled)
			core_state.solo_launch.apartment = enabled and true or false
		end
	)
	ui.button(launch, "apartment_force_ready", t("apartment.action.force_ready"), actions.force_ready)
	ui.button(launch, "apartment_redraw_board", t("apartment.action.redraw_board"), actions.redraw_board)

	local preps = ui.group(heist_tab, t("apartment.group.preps"), nil, nil, nil, nil, "apartment")
	ui.button(preps, "apartment_complete_preps", t("apartment.action.complete_preps"), actions.complete_preps)
	ui.button(preps, "apartment_change_session", t("apartment.action.change_session"), actions.change_session)

	preset_ui.click_group(heist_tab, {
		feature_id = "apartment",
		id_prefix = "apartment",
		subtab = "apartment",
		collect = apartment_presets.collect,
		apply = apartment_presets.apply,
		refresh = click.refresh,
	})

	local tools = ui.group(heist_tab, t("apartment.group.tools"), nil, nil, nil, nil, "apartment")
	ui.button(tools, "apartment_fleeca_hack", t("apartment.action.fleeca_hack"), actions.fleeca_hack)
	ui.button(tools, "apartment_fleeca_drill", t("apartment.action.fleeca_drill"), actions.fleeca_drill)
	ui.button(tools, "apartment_pacific_hack", t("apartment.action.pacific_hack"), actions.pacific_hack)
	ui.button(tools, "apartment_play_unavailable", t("apartment.action.play_unavailable"), actions.play_unavailable)
	ui.button(
		tools,
		"apartment_instant_finish_pacific",
		t("apartment.action.instant_finish_pacific"),
		actions.instant_finish_pacific
	)
	ui.button(
		tools,
		"apartment_instant_finish_other",
		t("apartment.action.instant_finish_other"),
		actions.instant_finish_other
	)
	ui.button(tools, "apartment_unlock_all", t("apartment.action.unlock_all_jobs"), actions.unlock_all_jobs)
	ui.button(tools, "apartment_skip_cutscene", t("apartment.action.skip_cutscene"), actions.skip_cutscene)

	local teleport = ui.group(heist_tab, t("apartment.group.teleport"), nil, nil, nil, nil, "apartment")
	ui.button(teleport, "apartment_tp_heist_board", t("apartment.action.teleport_board"), actions.teleport_heist_board)

	local danger = ui.group(heist_tab, t("apartment.group.danger"), nil, nil, nil, nil, "apartment")
	ui.label(danger, t("apartment.warning.use_with_caution"), config.colors.danger_text)
	ui.button(danger, "apartment_skip_heist_cooldown", t("apartment.action.skip_cooldown"), actions.kill_cooldown)

	local cuts = ui.group(heist_tab, t("apartment.group.cuts"), nil, nil, nil, nil, "apartment")
	bind_cut_controls(
		cuts,
		"player1",
		"apartment_cut_p1",
		"apartment_cut_p1_enabled",
		"apartment.field.host_cut",
		"apartment.field.host_enabled"
	)
	bind_cut_controls(
		cuts,
		"player2",
		"apartment_cut_p2",
		"apartment_cut_p2_enabled",
		"apartment.field.p2_cut",
		"apartment.field.p2_enabled"
	)
	bind_cut_controls(
		cuts,
		"player3",
		"apartment_cut_p3",
		"apartment_cut_p3_enabled",
		"apartment.field.p3_cut",
		"apartment.field.p3_enabled"
	)
	bind_cut_controls(
		cuts,
		"player4",
		"apartment_cut_p4",
		"apartment_cut_p4_enabled",
		"apartment.field.p4_cut",
		"apartment.field.p4_enabled"
	)

	local cut_presets = localized_options(data.cut_preset_options)
	refs.preset_dropdown = ui.dropdown(
		cuts,
		"apartment_cut_preset",
		t("apartment.field.preset"),
		data.option_names(cut_presets),
		state.flags.cut_preset_index,
		function(opt)
			state.set_cut_preset_index(
				data.option_index_by_value(
					cut_presets,
					data.option_value_by_name(cut_presets, opt, 100),
					state.flags.cut_preset_index
				)
			)
		end
	)

	refs.max_payout_toggle = ui.toggle(
		cuts,
		"apartment_max_payout",
		t("apartment.action.max_payout"),
		state.flags.max_payout_enabled,
		function(enabled)
			actions.set_max_payout(enabled)
			click.refresh()
		end
	)
	refs.double_toggle = ui.toggle(
		cuts,
		"apartment_double_rewards",
		t("apartment.action.double_rewards"),
		state.flags.double_rewards_week,
		function(enabled)
			actions.set_double_rewards(enabled)
			click.refresh()
		end
	)
	refs.bonus_toggle = ui.toggle(
		cuts,
		"apartment_12m_bonus",
		t("apartment.action.bonus_12m"),
		state.flags.bonus_enabled,
		function(enabled)
			actions.set_12mil_bonus(enabled)
			click.refresh()
		end
	)
	refs.auto_force_toggle = ui.toggle(
		cuts,
		"apartment_auto_force_cuts",
		t("apartment.action.auto_force_cuts"),
		state.flags.auto_force_cuts,
		function(enabled)
			state.flags.auto_force_cuts = enabled and true or false
		end
	)

	ui.button(cuts, "apartment_apply_selected_preset", t("apartment.action.apply_selected_preset"), function()
		actions.apply_selected_cut_preset()
		click.refresh()
	end)
	ui.button(cuts, "apartment_cuts_apply", t("apartment.action.apply_cuts"), actions.apply_state_cuts)

	click.refresh()
	return heist_tab
end

return click
