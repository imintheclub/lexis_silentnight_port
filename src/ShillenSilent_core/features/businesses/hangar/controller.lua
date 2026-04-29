local common = require("ShillenSilent_core.ui.controller.widgets")
local i18n = require("ShillenSilent_core.i18n")
local state = require("ShillenSilent_core.features.businesses.hangar.state")
local actions = require("ShillenSilent_core.features.businesses.hangar.actions")

local controller = {
	ctx = { syncing = false },
	controls = {},
}

local t = i18n.t

function controller.refresh_controls()
	local controls = controller.controls
	if controls.fill_status_breaker then
		controls.fill_status_breaker.name =
			t(state.fill.active and "hangar.status.fill_running" or "hangar.status.fill_stopped")
	end
	common.set_control_value(controller.ctx, controls.fill_toggle, state.fill.active == true)
	common.set_control_value(controller.ctx, controls.sale_price_toggle, state.config.sale_price_active == true)
	common.set_control_value(controller.ctx, controls.no_xp_toggle, state.config.no_xp == true)
	common.set_control_value(controller.ctx, controls.supplier_toggle, state.config.supplier_active == true)
	common.set_control_value(controller.ctx, controls.pocket_toggle, state.config.pocket_active == true)
	common.set_control_value(controller.ctx, controls.stop_number, state.config.pocket_stop_at)
	common.set_control_value(controller.ctx, controls.delay_number, state.config.pocket_delay)
	common.set_control_value(controller.ctx, controls.cooldowns_toggle, state.config.cooldowns_active == true)
	return true
end

function controller.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local ctx = controller.ctx
	local controls = controller.controls

	local root = parent_menu:submenu(t("feature.hangar.name"))
	root:breaker(t("feature.hangar.name"))

	local stock = root:submenu(t("hangar.group.stock"))
	controls.fill_status_breaker =
		stock:breaker(t(state.fill.active and "hangar.status.fill_running" or "hangar.status.fill_stopped"))
	controls.fill_toggle = common.add_toggle(ctx, stock, t("hangar.action.fill_loop"), function()
		return actions.get_fill_active()
	end, function(enabled)
		actions.set_fill_loop(enabled)
		controller.refresh_controls()
	end)
	common.add_button(stock, t("hangar.action.fill_tick"), function()
		actions.fill_tick_once()
		controller.refresh_controls()
	end)
	controls.supplier_toggle = common.add_toggle(ctx, stock, t("hangar.action.supplier_loop"), function()
		return actions.get_supplier_loop_active()
	end, function(enabled)
		actions.set_supplier_loop(enabled)
		controller.refresh_controls()
	end)
	controls.pocket_toggle = common.add_toggle(ctx, stock, t("hangar.action.pocket_dimension"), function()
		return actions.get_pocket_active()
	end, function(enabled)
		actions.set_pocket_active(enabled)
		controller.refresh_controls()
	end)
	controls.stop_number = common.add_number_int(
		ctx,
		stock,
		t("hangar.field.stop_at"),
		0,
		data.supplier.max_stop_at,
		data.supplier.stop_step,
		actions.get_pocket_stop_at,
		actions.set_pocket_stop_at
	)
	controls.delay_number = common.add_number_float(
		ctx,
		stock,
		t("hangar.field.delay"),
		data.supplier.min_delay,
		data.supplier.max_delay,
		data.supplier.delay_step,
		actions.get_pocket_delay,
		actions.set_pocket_delay
	)

	local sale = root:submenu(t("hangar.group.sale"))
	controls.sale_price_toggle = common.add_toggle(ctx, sale, t("hangar.action.sale_price_loop"), function()
		return actions.get_sale_price_loop_active()
	end, function(enabled)
		actions.set_sale_price_loop(enabled)
		controller.refresh_controls()
	end)
	controls.no_xp_toggle = common.add_toggle(ctx, sale, t("hangar.action.no_xp"), function()
		return actions.get_no_xp()
	end, function(enabled)
		actions.set_no_xp(enabled)
		controller.refresh_controls()
	end)
	common.add_button(sale, t("hangar.action.instant_sell"), actions.instant_sell)
	controls.cooldowns_toggle = common.add_toggle(ctx, sale, t("hangar.action.kill_cooldowns"), function()
		return actions.get_cooldowns_active()
	end, function(enabled)
		actions.set_cooldowns(enabled)
		controller.refresh_controls()
	end)

	local teleport = root:submenu(t("hangar.group.teleport"))
	common.add_button(teleport, t("hangar.action.teleport"), actions.teleport)
	common.add_button(teleport, t("hangar.action.teleport_laptop"), actions.teleport_laptop)
	common.add_button(teleport, t("hangar.action.open_laptop"), actions.open_laptop)

	controller.refresh_controls()
	return root
end

return controller
