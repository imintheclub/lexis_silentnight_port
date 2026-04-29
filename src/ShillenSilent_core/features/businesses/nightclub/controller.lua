local common = require("ShillenSilent_core.ui.controller.widgets")
local i18n = require("ShillenSilent_core.i18n")
local data = require("ShillenSilent_core.features.businesses.nightclub.data")
local state = require("ShillenSilent_core.features.businesses.nightclub.state")
local actions = require("ShillenSilent_core.features.businesses.nightclub.actions")

local controller = {
	ctx = { syncing = false },
	controls = {},
}

local t = i18n.t

function controller.refresh_controls()
	local ctx = controller.ctx
	local controls = controller.controls
	if controls.fast_status_breaker then
		controls.fast_status_breaker.name = t("nightclub.status.fast_loop", { status = actions.get_fast_prod_status() })
	end
	common.set_control_value(
		ctx,
		controls.fast_target_combo,
		data.option_index_by_value(data.fast_product_options, state.config.fast_prod_target, 1)
	)
	common.set_control_value(ctx, controls.fast_toggle, state.fast_production.active == true)
	common.set_control_value(ctx, controls.popularity_number, state.config.popularity_editor_value)
	common.set_control_value(ctx, controls.popularity_lock_toggle, state.popularity.lock_active == true)
	common.set_control_value(ctx, controls.raids_toggle, state.protections.raids_active == true)
	common.set_control_value(ctx, controls.reminders_toggle, state.protections.reminders_active == true)
	return true
end

function controller.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local ctx = controller.ctx
	local controls = controller.controls
	local root = parent_menu:submenu(t("feature.nightclub.name"))
	root:breaker(t("feature.nightclub.name"))

	local prod = root:submenu(t("nightclub.group.production"))
	controls.fast_status_breaker =
		prod:breaker(t("nightclub.status.fast_loop", { status = actions.get_fast_prod_status() }))
	controls.fast_target_combo = common.add_combo_options(
		ctx,
		prod,
		t("nightclub.field.fast_target"),
		actions.get_fast_product_options(),
		function()
			return state.config.fast_prod_target
		end,
		function(value)
			actions.set_fast_prod_target(value)
			controller.refresh_controls()
		end
	)
	controls.fast_toggle = common.add_toggle(ctx, prod, t("nightclub.action.fast_production"), function()
		return actions.get_fast_prod_active()
	end, function(enabled)
		actions.set_fast_production(enabled)
		controller.refresh_controls()
	end)
	common.add_button(prod, t("nightclub.action.production_tick"), actions.production_tick_all)

	local safe = root:submenu(t("nightclub.group.safe"))
	common.add_button(safe, t("nightclub.action.collect_safe"), actions.safe_collect)
	common.add_button(safe, t("nightclub.action.fill_safe"), actions.safe_fill)
	common.add_button(safe, t("nightclub.action.unbrick_safe"), actions.safe_unbrick)

	local pop = root:submenu(t("nightclub.group.popularity"))
	controls.popularity_number = common.add_number_int(
		ctx,
		pop,
		t("nightclub.field.popularity"),
		data.popularity.min,
		data.popularity.max,
		data.popularity.step,
		function()
			return state.config.popularity_editor_value
		end,
		actions.set_popularity_editor_value
	)
	common.add_button(pop, t("nightclub.action.apply_popularity"), actions.apply_popularity_editor_value)
	common.add_button(pop, t("nightclub.action.max_popularity"), function()
		actions.set_popularity_max()
		controller.refresh_controls()
	end)
	controls.popularity_lock_toggle = common.add_toggle(ctx, pop, t("nightclub.action.lock_popularity"), function()
		return actions.get_popularity_lock_active()
	end, function(enabled)
		actions.set_popularity_lock_active(enabled)
		controller.refresh_controls()
	end)

	local protect = root:submenu(t("nightclub.group.protections"))
	controls.raids_toggle = common.add_toggle(ctx, protect, t("nightclub.action.disable_raids"), function()
		return actions.get_raids_active()
	end, function(enabled)
		actions.set_disable_raids(enabled)
		controller.refresh_controls()
	end)
	controls.reminders_toggle = common.add_toggle(ctx, protect, t("nightclub.action.disable_reminders"), function()
		return actions.get_reminders_active()
	end, function(enabled)
		actions.set_disable_reminders(enabled)
		controller.refresh_controls()
	end)

	local teleport = root:submenu(t("nightclub.group.teleport"))
	common.add_button(teleport, t("nightclub.action.teleport"), actions.teleport)

	controller.refresh_controls()
	return root
end

return controller
