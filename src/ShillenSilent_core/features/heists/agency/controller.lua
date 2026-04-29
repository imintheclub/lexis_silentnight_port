local common = require("ShillenSilent_core.ui.controller.widgets")
local i18n = require("ShillenSilent_core.i18n")
local notify_core = require("ShillenSilent_core.core.notify")
local preset_ui = require("ShillenSilent_core.presets.ui")
local data = require("ShillenSilent_core.features.heists.agency.data")
local state = require("ShillenSilent_core.features.heists.agency.state")
local actions = require("ShillenSilent_core.features.heists.agency.actions")
local agency_presets = require("ShillenSilent_core.features.heists.agency.presets")

local controller = {
	ctx = { syncing = false },
	controls = {},
}

local t = i18n.t

local push = notify_core.feature("feature.agency.name")

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

	actions.refresh_collect_safe_state()

	local root = parent_menu:submenu(t("feature.agency.name"))
	root:breaker(t("feature.agency.name"))
	root:breaker(t("agency.info.max_transaction"))
	root:breaker(t("agency.info.cooldown"))

	common.add_button(root, t("agency.action.teleport_entrance"), actions.teleport_entrance)

	local preps = root:submenu(t("agency.group.preps"))
	local contract_options = data.localized_options(data.contracts, t)
	controls.contract_combo = common.add_combo_options(
		ctx,
		preps,
		t("agency.field.contract"),
		contract_options,
		function()
			return state.config.contract
		end,
		function(value)
			state.set_contract(value)
			controller.refresh_controls()
		end
	)
	common.add_button(preps, t("agency.action.apply_preps"), actions.apply_and_complete_preps)

	local payout = root:submenu(t("agency.group.payout"))
	controls.payout_number = common.add_number_int(
		ctx,
		payout,
		t("agency.field.payout"),
		0,
		data.payout.max,
		data.payout.step,
		function()
			return state.config.payout
		end,
		state.set_payout
	)
	common.add_button(payout, t("agency.action.set_max"), function()
		state.set_payout(data.payout.max)
		controller.refresh_controls()
		push("agency.notify.payout_max", 2000)
	end)
	common.add_button(payout, t("agency.action.apply_payout"), actions.apply_payout)

	local tools = root:submenu(t("agency.group.tools"))
	common.add_button(tools, t("agency.action.teleport_computer"), actions.teleport_computer)
	common.add_button(tools, t("agency.action.teleport_mission"), actions.teleport_mission)
	common.add_button(tools, t("agency.action.collect_safe"), actions.collect_safe)
	common.add_button(tools, t("agency.action.instant_finish"), actions.instant_finish_new)
	common.add_button(tools, t("agency.action.skip_cutscene"), actions.skip_cutscene)

	preset_ui.controller_group(root, {
		feature_id = "agency",
		ctx = controller.ctx,
		collect = agency_presets.collect,
		apply = agency_presets.apply,
		refresh = controller.refresh_controls,
	})

	local danger = root:submenu(t("agency.group.danger"))
	danger:breaker(t("agency.warning.use_with_caution"))
	common.add_button(danger, t("agency.action.skip_cooldowns"), actions.kill_cooldowns)

	controller.refresh_controls()
	return root
end

return controller
