local common = require("ShillenSilent_core.ui.controller.widgets")
local i18n = require("ShillenSilent_core.i18n")
local state = require("ShillenSilent_core.features.businesses.bunker.state")
local actions = require("ShillenSilent_core.features.businesses.bunker.actions")

local controller = {
	ctx = { syncing = false },
	controls = {},
}

local t = i18n.t

function controller.refresh_controls()
	local ctx = controller.ctx
	local controls = controller.controls
	if controls.fast_status_breaker then
		controls.fast_status_breaker.name = t("bunker.status.fast_loop", { status = actions.get_fast_prod_status() })
	end
	common.set_control_value(ctx, controls.fast_toggle, state.fast_production.active == true)
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

	local root = parent_menu:submenu(t("feature.bunker.name"))
	root:breaker(t("feature.bunker.name"))

	local production = root:submenu(t("bunker.group.production"))
	controls.fast_status_breaker =
		production:breaker(t("bunker.status.fast_loop", { status = actions.get_fast_prod_status() }))
	controls.fast_toggle = common.add_toggle(ctx, production, t("bunker.action.production_tick_loop"), function()
		return actions.get_fast_prod_active()
	end, function(enabled)
		actions.set_fast_production(enabled)
		controller.refresh_controls()
	end)
	common.add_button(production, t("bunker.action.production_tick"), actions.production_tick)
	common.add_button(production, t("bunker.action.refill_supplies"), actions.refill_supplies)
	common.add_button(production, t("bunker.action.instant_sell"), actions.instant_sell)

	local protect = root:submenu(t("bunker.group.protections"))
	controls.raids_toggle = common.add_toggle(ctx, protect, t("bunker.action.disable_raids"), function()
		return actions.get_raids_active()
	end, function(enabled)
		actions.set_disable_raids(enabled)
		controller.refresh_controls()
	end)
	controls.reminders_toggle = common.add_toggle(ctx, protect, t("bunker.action.disable_reminders"), function()
		return actions.get_reminders_active()
	end, function(enabled)
		actions.set_disable_reminders(enabled)
		controller.refresh_controls()
	end)

	local teleport = root:submenu(t("bunker.group.teleport"))
	common.add_button(teleport, t("bunker.action.teleport"), actions.teleport)

	controller.refresh_controls()
	return root
end

return controller
