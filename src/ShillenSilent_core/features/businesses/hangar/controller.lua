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

	local teleport = root:submenu(t("hangar.group.teleport"))
	common.add_button(teleport, t("hangar.action.teleport"), actions.teleport)

	controller.refresh_controls()
	return root
end

return controller
