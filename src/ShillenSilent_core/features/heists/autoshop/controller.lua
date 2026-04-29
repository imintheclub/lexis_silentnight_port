local common = require("ShillenSilent_core.ui.controller.widgets")
local i18n = require("ShillenSilent_core.i18n")
local notify_core = require("ShillenSilent_core.core.notify")
local preset_ui = require("ShillenSilent_core.presets.ui")
local data = require("ShillenSilent_core.features.heists.autoshop.data")
local state = require("ShillenSilent_core.features.heists.autoshop.state")
local actions = require("ShillenSilent_core.features.heists.autoshop.actions")
local autoshop_presets = require("ShillenSilent_core.features.heists.autoshop.presets")

local controller = {
	ctx = { syncing = false },
	controls = {},
}

local t = i18n.t

function controller.refresh_controls()
	local ctx = controller.ctx
	local controls = controller.controls
	common.set_control_value(ctx, controls.contract_combo, state.contract_index())
	common.set_control_value(ctx, controls.payout_number, common.clamp_int(state.config.payout, 0, data.payout.max))
	return true
end

function controller.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local ctx = controller.ctx
	local controls = controller.controls

	local root = parent_menu:submenu(t("feature.autoshop.name"))
	root:breaker(t("feature.autoshop.name"))
	root:breaker(t("autoshop.info.max_transaction"))
	root:breaker(t("autoshop.info.cooldown"))

	common.add_button(root, t("autoshop.action.teleport_entrance"), actions.teleport_entrance)
	preset_ui.controller_group(root, {
		feature_id = "autoshop",
		ctx = controller.ctx,
		collect = autoshop_presets.collect,
		apply = autoshop_presets.apply,
		refresh = controller.refresh_controls,
	})

	local preps = root:submenu(t("autoshop.group.preps"))
	controls.contract_combo = common.add_combo_options(
		ctx,
		preps,
		t("autoshop.field.contract"),
		data.contracts,
		function()
			return state.config.contract
		end,
		function(value)
			state.set_contract(value)
			controller.refresh_controls()
		end
	)
	common.add_button(preps, t("autoshop.action.apply_preps"), actions.apply_and_complete_preps)
	common.add_button(preps, t("autoshop.action.reset_preps"), actions.reset_preps)
	common.add_button(preps, t("autoshop.action.redraw_board"), actions.redraw_board)

	local payout = root:submenu(t("autoshop.group.payout"))
	controls.payout_number = common.add_number_int(
		ctx,
		payout,
		t("autoshop.field.payout"),
		0,
		data.payout.max,
		data.payout.step,
		function()
			return state.config.payout
		end,
		state.set_payout
	)
	common.add_button(payout, t("autoshop.action.set_max"), function()
		state.set_payout(data.payout.max)
		controller.refresh_controls()
		notify_core.raw(t("feature.autoshop.name"), t("autoshop.notify.payout_max"), 2000)
	end)
	common.add_button(payout, t("autoshop.action.apply_payout"), actions.apply_payout)

	local tools = root:submenu(t("autoshop.group.tools"))
	common.add_button(tools, t("autoshop.action.teleport_board"), actions.teleport_board)
	common.add_button(tools, t("autoshop.action.instant_finish"), actions.instant_finish_new)
	common.add_button(tools, t("autoshop.action.skip_cutscene"), actions.skip_cutscene)

	local danger = root:submenu(t("autoshop.group.danger"))
	danger:breaker(t("autoshop.warning.use_with_caution"))
	common.add_button(danger, t("autoshop.action.skip_cooldowns"), actions.kill_cooldowns)

	controller.refresh_controls()
	return root
end

return controller
