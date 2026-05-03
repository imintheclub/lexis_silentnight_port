local ui = require("ShillenSilent_core.ui.click.widgets")
local i18n = require("ShillenSilent_core.i18n")
local notify_core = require("ShillenSilent_core.core.notify")
local preset_ui = require("ShillenSilent_core.presets.ui")
local data = require("ShillenSilent_core.features.heists.doomsday.data")
local state = require("ShillenSilent_core.features.heists.doomsday.state")
local actions = require("ShillenSilent_core.features.heists.doomsday.actions")
local doomsday_presets = require("ShillenSilent_core.features.heists.doomsday.presets")

local config = require("ShillenSilent_core.ui.click.config")
local core_state = require("ShillenSilent_core.shared.runtime_state")
local click = {}
local refs = {}

local t = i18n.t

local push = notify_core.feature(data.label_key)

function click.refresh()
	if refs.act_dropdown then
		refs.act_dropdown.value = state.act_index()
	end
	if refs.solo_launch_toggle then
		refs.solo_launch_toggle.state = core_state.solo_launch.doomsday and true or false
	end
	if refs.max_payout_toggle then
		refs.max_payout_toggle.state = state.flags.max_payout_enabled and true or false
	end
	if refs.cut_preset_dropdown then
		refs.cut_preset_dropdown.value = data.clamp_cut_preset_index(state.flags.cut_preset_index)
	end
	for i = 1, #data.player_keys do
		local key = data.player_keys[i]
		local toggle = refs[key .. "_toggle"]
		local slider = refs[key .. "_slider"]
		if toggle then
			toggle.state = state.cut_enabled[key] and true or false
		end
		if slider then
			slider.value = data.clamp_cut(state.cuts[key])
		end
	end
	return true
end

function click.register(heistTab)
	if type(heistTab) ~= "table" then
		return nil
	end

	local info = ui.group(heistTab, t("doomsday.group.info"), nil, nil, nil, 170, data.feature_id)
	ui.label(info, t("doomsday.info.title"), config.colors.accent)
	ui.label(info, t("doomsday.info.max_transaction"), config.colors.text_main)
	ui.label(info, t("doomsday.info.transaction_cooldown"), config.colors.text_sec)
	ui.label(info, t("doomsday.info.heist_cooldown"), config.colors.text_sec)
	ui.info(info, t("doomsday.tip.max_payout"), config.colors.text_sec)
	ui.info(info, t("doomsday.tip.force_ready"), config.colors.text_sec)
	ui.spacer(info, config.space.x2)

	preset_ui.click_group(heistTab, {
		feature_id = data.feature_id,
		id_prefix = "doomsday",
		subtab = data.feature_id,
		collect = doomsday_presets.collect,
		apply = doomsday_presets.apply,
		refresh = click.refresh,
	})

	local teleport = ui.group(heistTab, t("doomsday.group.teleport"), nil, nil, nil, nil, data.feature_id)
	ui.button(
		teleport,
		"doomsday_teleport_entrance",
		t("doomsday.action.teleport_entrance"),
		actions.teleport_to_entrance
	)
	ui.button(teleport, "doomsday_teleport_screen", t("doomsday.action.teleport_screen"), actions.teleport_to_screen)

	local preps = ui.group(heistTab, t("doomsday.group.preps"), nil, nil, nil, nil, data.feature_id)

	local act_options = data.localized_options(data.act_options, t)
	refs.act_dropdown = ui.dropdown(
		preps,
		"doomsday_act",
		t("doomsday.field.act"),
		data.option_names(act_options),
		state.act_index(),
		function(opt)
			local selected = data.option_index_by_name(act_options, opt, state.config.act)
			actions.set_selected_act(selected, true)
			click.refresh()
		end
	)
	ui.button(preps, "doomsday_apply_selected_act", t("doomsday.action.apply_selected_act"), function()
		actions.complete_preps(state.config.act)
	end)
	ui.button(preps, "doomsday_reload_board", t("doomsday.action.reload_board"), function()
		if actions.reload_board(true) then
			push("doomsday.notify.board_reload_ok", 2000)
		end
	end)
	ui.button(preps, "doomsday_reset", t("doomsday.action.reset_progress"), actions.reset_progress)
	ui.button(preps, "doomsday_reset_preps", t("doomsday.action.reset_preps"), actions.reset_preps)

	local launch = ui.group(heistTab, t("doomsday.group.launch"), nil, nil, nil, nil, data.feature_id)
	refs.solo_launch_toggle = ui.toggle(
		launch,
		"doomsday_launch_solo",
		t("doomsday.action.solo_launch"),
		core_state.solo_launch.doomsday,
		function(val)
			core_state.solo_launch.doomsday = val and true or false
			click.refresh()
		end
	)
	ui.button(launch, "doomsday_launch_force_ready", t("doomsday.action.force_ready"), actions.force_ready)

	local cuts = ui.group(heistTab, t("doomsday.group.cuts"), nil, nil, nil, nil, data.feature_id)
	refs.max_payout_toggle = ui.toggle(
		cuts,
		"doomsday_max_payout",
		t("doomsday.action.max_payout"),
		state.flags.max_payout_enabled,
		function(val)
			actions.set_max_payout(val)
			click.refresh()
		end
	)
	local cut_preset_options = data.localized_options(data.cut_preset_options, t)
	refs.cut_preset_dropdown = ui.dropdown(
		cuts,
		"doomsday_cut_preset",
		t("doomsday.field.presets"),
		data.option_names(cut_preset_options),
		state.flags.cut_preset_index,
		function(opt)
			state.set_cut_preset_index(data.option_index_by_name(cut_preset_options, opt, state.flags.cut_preset_index))
			click.refresh()
		end
	)
	ui.button(cuts, "doomsday_preset_apply", t("doomsday.action.apply_selected_preset"), function()
		actions.apply_selected_cut_preset(false)
		click.refresh()
	end)
	ui.button(cuts, "doomsday_cuts_apply", t("doomsday.action.apply_cuts"), actions.apply_cuts)

	for i = 1, #data.player_keys do
		local key = data.player_keys[i]
		refs[key .. "_toggle"] = ui.toggle(
			cuts,
			"doomsday_cut_p" .. tostring(i) .. "_enabled",
			t("doomsday.field.enable_player", { player = i }),
			state.cut_enabled[key],
			function(val)
				state.set_cut_enabled(key, val)
				click.refresh()
			end
		)
		refs[key .. "_slider"] = ui.slider(
			cuts,
			"doomsday_cut_p" .. tostring(i),
			t("doomsday.field.player", { player = i }),
			data.cuts.min,
			data.cuts.max,
			state.cuts[key],
			function(val)
				state.set_cut(key, val)
			end,
			nil,
			data.cuts.step
		)
	end

	local tools = ui.group(heistTab, t("doomsday.group.tools"), nil, nil, nil, nil, data.feature_id)
	ui.button(tools, "doomsday_data_hack", t("doomsday.action.data_hack"), actions.data_hack)
	ui.button(tools, "doomsday_doomsday_hack", t("doomsday.action.doomsday_hack"), actions.doomsday_hack)
	ui.button(tools, "doomsday_instant_finish", t("doomsday.action.instant_finish"), actions.instant_finish_new)
	ui.button(tools, "doomsday_skip_cutscene", t("doomsday.action.skip_cutscene"), actions.skip_cutscene)

	click.refresh()
	return heistTab
end

return click
