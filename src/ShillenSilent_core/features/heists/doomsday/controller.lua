local common = require("ShillenSilent_core.ui.controller.widgets")
local i18n = require("ShillenSilent_core.i18n")
local preset_ui = require("ShillenSilent_core.presets.ui")
local data = require("ShillenSilent_core.features.heists.doomsday.data")
local state = require("ShillenSilent_core.features.heists.doomsday.state")
local actions = require("ShillenSilent_core.features.heists.doomsday.actions")
local doomsday_presets = require("ShillenSilent_core.features.heists.doomsday.presets")

local core_state = require("ShillenSilent_core.shared.runtime_state")

local controller = {
	ctx = { syncing = false },
	controls = {},
}

local t = i18n.t

function controller.refresh_controls()
	local ctx = controller.ctx
	local controls = controller.controls

	common.set_control_value(ctx, controls.act_combo, state.act_index())
	common.set_control_value(ctx, controls.solo_launch_toggle, core_state.solo_launch.doomsday and true or false)
	common.set_control_value(ctx, controls.max_payout_toggle, state.flags.max_payout_enabled and true or false)
	common.set_control_value(ctx, controls.preset_combo, data.clamp_cut_preset_index(state.flags.cut_preset_index))

	for i = 1, #data.player_keys do
		local key = data.player_keys[i]
		common.set_control_value(ctx, controls[key .. "_enable"], state.cut_enabled[key] and true or false)
		common.set_control_value(ctx, controls[key .. "_cut"], data.clamp_cut(state.cuts[key]))
	end
	return true
end

function controller.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local ctx = controller.ctx
	local controls = controller.controls

	local root = parent_menu:submenu(t(data.label_key))
	root:breaker(t("doomsday.info.title"))
	root:breaker(t("doomsday.info.max_transaction"))
	root:breaker(t("doomsday.info.transaction_cooldown"))
	root:breaker(t("doomsday.info.heist_cooldown"))
	root:breaker(t("doomsday.tip.force_ready"))

	local tp = root:submenu(t("doomsday.group.teleport"))
	common.add_button(tp, t("doomsday.action.teleport_entrance"), actions.teleport_to_entrance)
	common.add_button(tp, t("doomsday.action.teleport_screen"), actions.teleport_to_screen)

	local launch = root:submenu(t("doomsday.group.launch"))
	controls.solo_launch_toggle = common.add_toggle(ctx, launch, t("doomsday.action.solo_launch"), function()
		return core_state.solo_launch.doomsday
	end, function(enabled)
		core_state.solo_launch.doomsday = enabled and true or false
	end)
	common.add_button(launch, t("doomsday.action.force_ready"), actions.force_ready)

	local preps = root:submenu(t("doomsday.group.preps"))
	local act_options = data.localized_options(data.act_options, t)
	controls.act_combo = common.add_combo_options(ctx, preps, t("doomsday.field.act"), act_options, function()
		return state.config.act
	end, function(value)
		actions.set_selected_act(value, true)
		controller.refresh_controls()
	end)
	common.add_button(preps, t("doomsday.action.apply_selected_act"), function()
		actions.complete_preps(state.config.act)
	end)
	common.add_button(preps, t("doomsday.action.reset_progress"), actions.reset_progress)
	common.add_button(preps, t("doomsday.action.reset_preps"), actions.reset_preps)
	common.add_button(preps, t("doomsday.action.reload_board"), actions.reload_board)

	local cuts = root:submenu(t("doomsday.group.cuts"))
	controls.max_payout_toggle = common.add_toggle(ctx, cuts, t("doomsday.action.max_payout"), function()
		return state.flags.max_payout_enabled
	end, function(enabled)
		actions.set_max_payout(enabled)
		controller.refresh_controls()
	end)

	local cut_preset_options = data.localized_options(data.cut_preset_options, t)
	controls.preset_combo = common.add_combo_options(
		ctx,
		cuts,
		t("doomsday.field.presets"),
		cut_preset_options,
		function()
			local option = data.cut_preset_options[data.clamp_cut_preset_index(state.flags.cut_preset_index)]
			return option and option.value or 100
		end,
		function(_, idx)
			state.set_cut_preset_index(idx)
		end
	)
	common.add_button(cuts, t("doomsday.action.apply_selected_preset"), function()
		actions.apply_selected_cut_preset(false)
		controller.refresh_controls()
	end)

	for i = 1, #data.player_keys do
		local key = data.player_keys[i]
		controls[key .. "_enable"] = common.add_toggle(
			ctx,
			cuts,
			t("doomsday.field.enable_player", { player = i }),
			function()
				return state.cut_enabled[key]
			end,
			function(enabled)
				state.set_cut_enabled(key, enabled)
			end
		)
		controls[key .. "_cut"] = common.add_number_int(
			ctx,
			cuts,
			t("doomsday.field.player", { player = i }),
			data.cuts.min,
			data.cuts.max,
			data.cuts.step,
			function()
				return state.cuts[key]
			end,
			function(value)
				state.set_cut(key, value)
			end
		)
	end
	common.add_button(cuts, t("doomsday.action.apply_cuts"), actions.apply_cuts)

	preset_ui.controller_group(root, {
		feature_id = data.feature_id,
		ctx = controller.ctx,
		collect = doomsday_presets.collect,
		apply = doomsday_presets.apply,
		refresh = controller.refresh_controls,
	})

	local tools = root:submenu(t("doomsday.group.tools"))
	common.add_button(tools, t("doomsday.action.data_hack"), actions.data_hack)
	common.add_button(tools, t("doomsday.action.doomsday_hack"), actions.doomsday_hack)
	common.add_button(tools, t("doomsday.action.instant_finish"), actions.instant_finish_new)
	common.add_button(tools, t("doomsday.action.skip_cutscene"), actions.skip_cutscene)

	controller.refresh_controls()
	return root
end

return controller
