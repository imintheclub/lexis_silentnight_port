local common = require("ShillenSilent_core.ui.controller.widgets")
local i18n = require("ShillenSilent_core.i18n")
local data = require("ShillenSilent_core.features.businesses.speccargo.data")
local state = require("ShillenSilent_core.features.businesses.speccargo.state")
local actions = require("ShillenSilent_core.features.businesses.speccargo.actions")

local controller = {
	ctx = { syncing = false },
	controls = {},
}

local t = i18n.t

function controller.refresh_controls()
	local ctx = controller.ctx
	local controls = controller.controls
	if controls.fill_status_breaker then
		controls.fill_status_breaker.name =
			t(state.fill.active and "speccargo.status.fill_running" or "speccargo.status.fill_stopped")
	end
	common.set_control_value(ctx, controls.fill_toggle, state.fill.active == true)
	common.set_control_value(ctx, controls.raids_toggle, state.protections.raids_active == true)
	common.set_control_value(ctx, controls.reminders_toggle, state.protections.reminders_active == true)
	common.set_control_value(ctx, controls.location_combo, state.config.location_index)
	return true
end

function controller.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local ctx = controller.ctx
	local controls = controller.controls
	local root = parent_menu:submenu(t("feature.speccargo.name"))
	root:breaker(t("feature.speccargo.name"))

	local stock = root:submenu(t("speccargo.group.stock"))
	controls.fill_status_breaker =
		stock:breaker(t(state.fill.active and "speccargo.status.fill_running" or "speccargo.status.fill_stopped"))
	common.add_button(stock, t("speccargo.action.instant_sell"), actions.instant_sell)
	controls.fill_toggle = common.add_toggle(ctx, stock, t("speccargo.action.fill_loop"), function()
		return actions.get_fill_active()
	end, function(enabled)
		actions.set_fill_loop(enabled)
		controller.refresh_controls()
	end)
	common.add_button(stock, t("speccargo.action.fill_tick"), function()
		actions.fill_tick_once()
		controller.refresh_controls()
	end)

	local protect = root:submenu(t("speccargo.group.protections"))
	controls.raids_toggle = common.add_toggle(ctx, protect, t("speccargo.action.disable_raids"), function()
		return actions.get_raids_active()
	end, function(enabled)
		actions.set_disable_raids(enabled)
		controller.refresh_controls()
	end)
	controls.reminders_toggle = common.add_toggle(ctx, protect, t("speccargo.action.disable_reminders"), function()
		return actions.get_reminders_active()
	end, function(enabled)
		actions.set_disable_reminders(enabled)
		controller.refresh_controls()
	end)

	local teleport = root:submenu(t("speccargo.group.teleport"))
	local locations = actions.get_locations()
	local localized_locations = data.localized_locations(locations, t)
	if #localized_locations > 0 then
		controls.location_combo = common.add_combo_options(
			ctx,
			teleport,
			t("speccargo.field.location"),
			localized_locations,
			function()
				return state.config.location_index
			end,
			function(value)
				state.set_location_index(value, #localized_locations)
				controller.refresh_controls()
			end
		)
		common.add_button(teleport, t("speccargo.action.teleport"), actions.teleport)
	else
		teleport:breaker(t("speccargo.notify.no_owned_warehouses"))
	end

	controller.refresh_controls()
	return root
end

return controller
