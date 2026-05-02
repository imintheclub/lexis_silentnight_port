local common = require("ShillenSilent_core.ui.controller.widgets")
local i18n = require("ShillenSilent_core.i18n")
local preset_ui = require("ShillenSilent_core.presets.ui")
local data = require("ShillenSilent_core.features.heists.salvageyard.data")
local state = require("ShillenSilent_core.features.heists.salvageyard.state")
local actions = require("ShillenSilent_core.features.heists.salvageyard.actions")
local salvage_presets = require("ShillenSilent_core.features.heists.salvageyard.presets")

local controller = {
	ctx = { syncing = false },
	controls = {},
}

local t = i18n.t

local function localized_options(options)
	return data.localized_options(options, t)
end

local function slot_control(slot, field)
	return "slot" .. tostring(slot) .. "_" .. field
end

local function get_slot_cfg(slot)
	return state.slot(slot)
end

local function register_slot_menu(root, slot)
	local ctx = controller.ctx
	local controls = controller.controls
	local slot_cfg = get_slot_cfg(slot)
	if not slot_cfg then
		return
	end

	local menu = root:submenu(t("salvageyard.group.slot", { slot = tostring(slot) }))
	common.add_button(menu, t("salvageyard.action.make_available"), function()
		actions.make_slot_available(slot)
	end)

	local fields = {
		{ id = "robbery", label = "salvageyard.field.robbery", options = data.options.robberies },
		{ id = "vehicle", label = "salvageyard.field.vehicle", options = data.options.vehicles },
		{ id = "modification", label = "salvageyard.field.modification", options = data.options.modifications },
		{ id = "keep", label = "salvageyard.field.status", options = data.options.keep_statuses },
	}
	for i = 1, #fields do
		local field = fields[i]
		local options = localized_options(field.options)
		controls[slot_control(slot, field.id)] = common.add_combo_options(ctx, menu, t(field.label), options, function()
			return slot_cfg[field.id]
		end, function(value)
			state.set_slot_value(slot, field.id, value)
			controller.refresh_controls()
		end)
	end

	common.add_button(menu, t("salvageyard.action.apply_changes"), function()
		actions.apply_slot(slot)
	end)
end

function controller.refresh_controls()
	local ctx = controller.ctx
	local controls = controller.controls

	for slot = 1, 3 do
		local slot_cfg = get_slot_cfg(slot)
		if slot_cfg then
			common.set_control_value(
				ctx,
				controls[slot_control(slot, "robbery")],
				common.find_index_by_value(data.options.robberies, slot_cfg.robbery, 1)
			)
			common.set_control_value(
				ctx,
				controls[slot_control(slot, "vehicle")],
				common.find_index_by_value(data.options.vehicles, slot_cfg.vehicle, 1)
			)
			common.set_control_value(
				ctx,
				controls[slot_control(slot, "modification")],
				common.find_index_by_value(data.options.modifications, slot_cfg.modification, 1)
			)
			common.set_control_value(
				ctx,
				controls[slot_control(slot, "keep")],
				common.find_index_by_value(data.options.keep_statuses, slot_cfg.keep, 1)
			)
		end
	end

	common.set_control_value(ctx, controls.free_setup, state.flags.free_setup and true or false)
	common.set_control_value(ctx, controls.free_claim, state.flags.free_claim and true or false)
	common.set_control_value(
		ctx,
		controls.multiplier,
		common.clamp_float(state.config.salvage_multiplier, data.multiplier.min, data.multiplier.max)
	)
	for slot = 1, 3 do
		common.set_control_value(
			ctx,
			controls["sell" .. tostring(slot)],
			common.clamp_int(state.sell_value(slot), data.sell_value.min, data.sell_value.max)
		)
	end
	return true
end

function controller.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local ctx = controller.ctx
	local controls = controller.controls
	actions.refresh_collect_safe_state()

	local root = parent_menu:submenu(t("feature.salvageyard.name"))
	root:breaker(t("feature.salvageyard.name"))
	root:breaker(t("salvageyard.info.max_transaction"))
	root:breaker(t("salvageyard.info.cooldown"))
	root:breaker(t("salvageyard.info.planning_controls"))

	common.add_button(root, t("salvageyard.action.teleport_entrance"), actions.teleport_entrance)

	local preps = root:submenu(t("salvageyard.group.preps"))
	common.add_button(preps, t("salvageyard.action.apply_all_changes"), actions.apply_all_changes)
	common.add_button(preps, t("salvageyard.action.complete_preps"), actions.complete_preps)
	common.add_button(preps, t("salvageyard.action.reset_preps"), actions.reset_preps)
	common.add_button(preps, t("salvageyard.action.reload_screen"), actions.reload_screen)
	controls.free_setup = common.add_toggle(ctx, preps, t("salvageyard.action.free_setup"), function()
		return state.flags.free_setup
	end, function(enabled)
		actions.set_free_setup(enabled, false)
		controller.refresh_controls()
	end)
	controls.free_claim = common.add_toggle(ctx, preps, t("salvageyard.action.free_claim"), function()
		return state.flags.free_claim
	end, function(enabled)
		actions.set_free_claim(enabled, false)
		controller.refresh_controls()
	end)

	for slot = 1, 3 do
		register_slot_menu(root, slot)
	end

	local payout = root:submenu(t("salvageyard.group.payout"))
	controls.multiplier = common.add_number_float(
		ctx,
		payout,
		t("salvageyard.field.multiplier"),
		data.multiplier.min,
		data.multiplier.max,
		data.multiplier.step,
		function()
			return state.config.salvage_multiplier
		end,
		state.set_multiplier
	)
	for slot = 1, 3 do
		controls["sell" .. tostring(slot)] = common.add_number_int(
			ctx,
			payout,
			t("salvageyard.field.sell_value_slot", { slot = tostring(slot) }),
			data.sell_value.min,
			data.sell_value.max,
			data.sell_value.step,
			function()
				return state.sell_value(slot)
			end,
			function(value)
				state.set_sell_value(slot, value)
			end
		)
	end
	common.add_button(payout, t("salvageyard.action.apply_sell_values"), actions.apply_sell_values)

	local tools = root:submenu(t("salvageyard.group.tools"))
	common.add_button(tools, t("salvageyard.action.teleport_board"), actions.teleport_board)
	common.add_button(tools, t("salvageyard.action.instant_finish"), actions.instant_finish)
	common.add_button(tools, t("salvageyard.action.instant_sell"), actions.instant_sell)
	common.add_button(tools, t("salvageyard.action.tow_finish"), actions.tow_truck_instant_finish)
	common.add_button(tools, t("salvageyard.action.force_error"), actions.force_through_error)
	common.add_button(tools, t("salvageyard.action.collect_safe"), actions.collect_safe)
	common.add_button(tools, t("salvageyard.action.skip_cutscene"), actions.skip_cutscene)

	preset_ui.controller_group(root, {
		feature_id = "salvageyard",
		ctx = controller.ctx,
		collect = salvage_presets.collect,
		apply = salvage_presets.apply,
		refresh = controller.refresh_controls,
	})

	local danger = root:submenu(t("salvageyard.group.danger"))
	danger:breaker(t("salvageyard.warning.use_with_caution"))
	common.add_button(danger, t("salvageyard.action.skip_weekly_cooldown"), actions.skip_weekly_cooldown)

	local popularity = root:submenu(t("salvageyard.group.popularity"))
	common.add_number_int(
		ctx,
		popularity,
		t("salvageyard.field.popularity"),
		data.popularity.min,
		data.popularity.max,
		data.popularity.step,
		actions.get_popularity_editor_value,
		actions.set_popularity_editor_value
	)
	common.add_button(popularity, t("salvageyard.action.apply_popularity"), actions.apply_popularity_editor_value)
	common.add_toggle(
		ctx,
		popularity,
		t("salvageyard.action.lock_popularity"),
		actions.get_popularity_lock_active,
		function(enabled)
			actions.set_popularity_lock_active(enabled)
		end
	)

	actions.set_free_setup(state.flags.free_setup, true)
	actions.set_free_claim(state.flags.free_claim, true)
	controller.refresh_controls()
	return root
end

return controller
