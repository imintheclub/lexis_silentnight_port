local common = require("ShillenSilent_core.ui.controller.widgets")
local i18n = require("ShillenSilent_core.i18n")
local data = require("ShillenSilent_core.features.businesses.moneyfronts.data")
local state = require("ShillenSilent_core.features.businesses.moneyfronts.state")
local actions = require("ShillenSilent_core.features.businesses.moneyfronts.actions")

local controller = {
	ctx = { syncing = false },
	controls = {},
}

local t = i18n.t

function controller.refresh_controls()
	local ctx = controller.ctx
	local controls = controller.controls
	common.set_control_value(ctx, controls.location_combo, state.config.location_index)
	common.set_control_value(ctx, controls.heat_number, state.config.heat_editor_value)
	common.set_control_value(ctx, controls.heat_lock_toggle, state.flags.heat_lock_active == true)
	return true
end

function controller.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local ctx = controller.ctx
	local controls = controller.controls

	local root = parent_menu:submenu(t("feature.moneyfronts.name"))
	root:breaker(t("feature.moneyfronts.name"))

	local teleport = root:submenu(t("moneyfronts.group.teleport"))
	local locations = data.localized_locations(t)
	controls.location_combo = common.add_combo_options(
		ctx,
		teleport,
		t("moneyfronts.field.location"),
		locations,
		function()
			return state.config.location_index
		end,
		function(value)
			state.set_location_index(value)
			controller.refresh_controls()
		end
	)
	common.add_button(teleport, t("moneyfronts.action.teleport"), actions.teleport)

	local heat = root:submenu(t("moneyfronts.group.heat"))
	controls.heat_number = common.add_number_int(
		ctx,
		heat,
		t("moneyfronts.field.heat"),
		data.heat.min,
		data.heat.max,
		data.heat.step,
		function()
			return state.config.heat_editor_value
		end,
		function(value)
			actions.set_heat_editor_value(value)
			controller.refresh_controls()
		end
	)
	common.add_button(heat, t("moneyfronts.action.apply_heat"), actions.apply_heat_editor_value)
	common.add_button(heat, t("moneyfronts.action.set_heat_zero"), function()
		actions.reset_heat()
		controller.refresh_controls()
	end)
	controls.heat_lock_toggle = common.add_toggle(ctx, heat, t("moneyfronts.action.lock_heat_zero"), function()
		return actions.get_heat_lock_active()
	end, function(enabled)
		actions.set_heat_lock_active(enabled)
		controller.refresh_controls()
	end)
	common.add_button(heat, t("moneyfronts.action.reset_safe_production"), actions.reset_safe_production_state)

	local tools = root:submenu(t("moneyfronts.group.tools"))
	common.add_button(tools, t("moneyfronts.action.collect_car_wash_safe"), actions.car_wash_collect_safe)

	controller.refresh_controls()
	return root
end

return controller
