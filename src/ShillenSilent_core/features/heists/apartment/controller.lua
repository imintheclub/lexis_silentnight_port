local common = require("ShillenSilent_core.ui.controller.widgets")
local i18n = require("ShillenSilent_core.i18n")
local preset_ui = require("ShillenSilent_core.presets.ui")
local data = require("ShillenSilent_core.features.heists.apartment.data")
local state = require("ShillenSilent_core.features.heists.apartment.state")
local actions = require("ShillenSilent_core.features.heists.apartment.actions")
local apartment_presets = require("ShillenSilent_core.features.heists.apartment.presets")

local controller = {
	ctx = { syncing = false },
	controls = {},
}

local core_state = require("ShillenSilent_core.shared.runtime_state")

local t = i18n.t

local function localized_options(options)
	return data.localized_options(options, t)
end

function controller.refresh_controls()
	local ctx = controller.ctx
	local controls = controller.controls

	common.set_control_value(ctx, controls.solo_launch_toggle, core_state.solo_launch.apartment and true or false)
	common.set_control_value(ctx, controls.bonus_toggle, state.flags.bonus_enabled and true or false)
	common.set_control_value(ctx, controls.double_toggle, state.flags.double_rewards_week and true or false)
	common.set_control_value(ctx, controls.max_payout_toggle, state.flags.max_payout_enabled and true or false)
	common.set_control_value(ctx, controls.auto_force_toggle, state.flags.auto_force_cuts and true or false)
	common.set_control_value(ctx, controls.preset_combo, data.clamp_cut_preset_index(state.flags.cut_preset_index))
	common.set_control_value(
		ctx,
		controls.heist_combo,
		data.option_index_by_value(data.heist_options, state.config.selected_heist, 1)
	)

	for i = 1, #data.player_keys do
		local key = data.player_keys[i]
		common.set_control_value(ctx, controls[key .. "_cut"], data.clamp_cut(state.cuts[key]))
		common.set_control_value(ctx, controls[key .. "_enabled"], state.cut_enabled[key] and true or false)
	end
	return true
end

local function add_cut_controls(ctx, menu, player_key, cut_label_key, enabled_label_key)
	local controls = controller.controls
	controls[player_key .. "_cut"] = common.add_number_int(
		ctx,
		menu,
		t(cut_label_key),
		data.cuts.min,
		data.cuts.max,
		data.cuts.step,
		function()
			return state.cuts[player_key]
		end,
		function(value)
			state.set_cut(player_key, value)
		end
	)
	controls[player_key .. "_enabled"] = common.add_toggle(ctx, menu, t(enabled_label_key), function()
		return state.cut_enabled[player_key]
	end, function(enabled)
		state.set_cut_enabled(player_key, enabled)
	end)
end

function controller.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local ctx = controller.ctx
	local controls = controller.controls
	local root = parent_menu:submenu(t("feature.apartment.name"))

	root:breaker(t("apartment.info.title"))
	root:breaker(t("apartment.info.max_transaction"))
	root:breaker(t("apartment.info.transaction_cooldown"))
	root:breaker(t("apartment.info.criminal_mastermind"))
	root:breaker(t("apartment.info.heist_cooldown"))
	root:breaker(t("apartment.tip.force_ready"))

	common.add_button(root, t("apartment.action.teleport_entrance"), actions.teleport_entrance)

	local launch = root:submenu(t("apartment.group.launch"))
	controls.solo_launch_toggle = common.add_toggle(ctx, launch, t("apartment.action.solo_launch"), function()
		return core_state.solo_launch.apartment
	end, function(enabled)
		core_state.solo_launch.apartment = enabled and true or false
	end)
	common.add_button(launch, t("apartment.action.force_ready"), actions.force_ready)
	common.add_button(launch, t("apartment.action.redraw_board"), actions.redraw_board)

	local preps = root:submenu(t("apartment.group.preps"))
	local heist_entries = {}
	for i = 1, #data.heist_options do
		heist_entries[i] = { data.heist_options[i].name, i }
	end
	controls.heist_combo = common.add_combo_entries(ctx, preps, t("apartment.group.preps"), heist_entries, function()
		return data.option_index_by_value(data.heist_options, state.config.selected_heist, 1)
	end, function(idx)
		local option = data.heist_options[idx]
		if option then
			state.set_selected_heist(option.value)
		end
	end)
	common.add_button(preps, t("apartment.action.complete_preps"), actions.complete_preps)
	common.add_button(preps, t("apartment.action.change_session"), actions.change_session)

	local cuts = root:submenu(t("apartment.group.cuts"))
	add_cut_controls(ctx, cuts, "player1", "apartment.field.host_cut", "apartment.field.host_enabled")
	add_cut_controls(ctx, cuts, "player2", "apartment.field.p2_cut", "apartment.field.p2_enabled")
	add_cut_controls(ctx, cuts, "player3", "apartment.field.p3_cut", "apartment.field.p3_enabled")
	add_cut_controls(ctx, cuts, "player4", "apartment.field.p4_cut", "apartment.field.p4_enabled")

	local cut_presets = localized_options(data.cut_preset_options)
	local preset_entries = {}
	for i = 1, #cut_presets do
		preset_entries[i] = { cut_presets[i].name, i }
	end
	controls.preset_combo = common.add_combo_entries(ctx, cuts, t("apartment.field.preset"), preset_entries, function()
		return data.clamp_cut_preset_index(state.flags.cut_preset_index)
	end, function(idx)
		state.set_cut_preset_index(idx)
	end)

	controls.max_payout_toggle = common.add_toggle(ctx, cuts, t("apartment.action.max_payout"), function()
		return state.flags.max_payout_enabled
	end, function(enabled)
		actions.set_max_payout(enabled)
		controller.refresh_controls()
	end)
	controls.double_toggle = common.add_toggle(ctx, cuts, t("apartment.action.double_rewards"), function()
		return state.flags.double_rewards_week
	end, function(enabled)
		actions.set_double_rewards(enabled)
		controller.refresh_controls()
	end)
	controls.bonus_toggle = common.add_toggle(ctx, cuts, t("apartment.action.bonus_12m"), function()
		return state.flags.bonus_enabled
	end, function(enabled)
		actions.set_12mil_bonus(enabled)
		controller.refresh_controls()
	end)
	controls.auto_force_toggle = common.add_toggle(ctx, cuts, t("apartment.action.auto_force_cuts"), function()
		return state.flags.auto_force_cuts
	end, function(enabled)
		state.flags.auto_force_cuts = enabled and true or false
	end)

	common.add_button(cuts, t("apartment.action.apply_selected_preset"), function()
		actions.apply_selected_cut_preset()
		controller.refresh_controls()
	end)
	common.add_button(cuts, t("apartment.action.apply_cuts"), actions.apply_state_cuts)

	local tools = root:submenu(t("apartment.group.tools"))
	common.add_button(tools, t("apartment.action.play_unavailable"), actions.play_unavailable)
	common.add_button(tools, t("apartment.action.unlock_all_jobs"), actions.unlock_all_jobs)
	common.add_button(tools, t("apartment.action.fleeca_hack"), actions.fleeca_hack)
	common.add_button(tools, t("apartment.action.fleeca_drill"), actions.fleeca_drill)
	common.add_button(tools, t("apartment.action.pacific_hack"), actions.pacific_hack)
	common.add_button(tools, t("apartment.action.instant_finish_pacific"), actions.instant_finish_pacific)
	common.add_button(tools, t("apartment.action.instant_finish_other"), actions.instant_finish_other)
	common.add_button(tools, t("apartment.action.skip_cutscene"), actions.skip_cutscene)

	preset_ui.controller_group(root, {
		feature_id = "apartment",
		ctx = controller.ctx,
		collect = apartment_presets.collect,
		apply = apartment_presets.apply,
		refresh = controller.refresh_controls,
	})

	local tp_in_heist = root:submenu(t("apartment.group.teleport_in_heist"))
	common.add_button(tp_in_heist, t("apartment.action.teleport_board"), actions.teleport_heist_board)

	local danger = root:submenu(t("apartment.group.danger"))
	danger:breaker(t("apartment.warning.use_with_caution"))
	common.add_button(danger, t("apartment.action.skip_cooldown"), actions.kill_cooldown)

	controller.refresh_controls()
	return root
end

return controller
