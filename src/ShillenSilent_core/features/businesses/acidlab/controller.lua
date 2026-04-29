local common = require("ShillenSilent_core.ui.controller.widgets")
local i18n = require("ShillenSilent_core.i18n")
local state = require("ShillenSilent_core.features.businesses.acidlab.state")
local actions = require("ShillenSilent_core.features.businesses.acidlab.actions")

local controller = {
	ctx = { syncing = false },
	controls = {},
}

local t = i18n.t

function controller.refresh_controls()
	local ctx = controller.ctx
	local controls = controller.controls
	if controls.fast_status_breaker then
		controls.fast_status_breaker.name = t("acidlab.status.fast_loop", { status = actions.get_fast_prod_status() })
	end
	common.set_control_value(ctx, controls.fast_toggle, state.fast_production.active == true)
	return true
end

function controller.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local ctx = controller.ctx
	local controls = controller.controls

	local root = parent_menu:submenu(t("feature.acidlab.name"))
	root:breaker(t("feature.acidlab.name"))

	local production = root:submenu(t("acidlab.group.production"))
	controls.fast_status_breaker =
		production:breaker(t("acidlab.status.fast_loop", { status = actions.get_fast_prod_status() }))
	controls.fast_toggle = common.add_toggle(ctx, production, t("acidlab.action.production_tick_loop"), function()
		return actions.get_fast_prod_active()
	end, function(enabled)
		actions.set_fast_production(enabled)
		controller.refresh_controls()
	end)
	common.add_button(production, t("acidlab.action.production_tick"), actions.production_tick)
	common.add_button(production, t("acidlab.action.refill_supplies"), actions.refill_supplies)
	common.add_button(production, t("acidlab.action.instant_sell"), actions.instant_sell)

	controller.refresh_controls()
	return root
end

return controller
