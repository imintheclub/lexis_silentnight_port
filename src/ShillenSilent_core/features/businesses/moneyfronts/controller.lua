local common = require("ShillenSilent_core.ui.controller.widgets")
local i18n = require("ShillenSilent_core.i18n")
local data = require("ShillenSilent_core.features.businesses.moneyfronts.data")
local state = require("ShillenSilent_core.features.businesses.moneyfronts.state")
local actions = require("ShillenSilent_core.features.businesses.moneyfronts.actions")

local controller = {
	ctx = { syncing = false },
	controls = {
		front_heat = {},
		front_lock = {},
	},
}

local t = i18n.t

function controller.refresh_controls()
	local ctx = controller.ctx
	local controls = controller.controls
	for _, key in ipairs(data.front_keys) do
		common.set_control_value(ctx, controls.front_heat[key], state.config.front_heat[key])
		common.set_control_value(ctx, controls.front_lock[key], state.flags.front_heat_lock[key] == true)
	end
	return true
end

function controller.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local ctx = controller.ctx
	local controls = controller.controls

	for _, key in ipairs(data.front_keys) do
		if not actions.is_front_available(key) then
			goto continue
		end
		local loc = data.location_by_key(key)
		local front = parent_menu:submenu(t(loc.heat_label_key))
		common.add_button(front, t("moneyfronts.action.teleport_entrance"), function()
			actions.teleport_front(key)
		end)
		common.add_button(front, t("moneyfronts.action.teleport_laptop"), function()
			actions.teleport_laptop(key)
		end)
		if key == "car_wash" then
			common.add_button(front, t("moneyfronts.action.collect_car_wash_safe"), actions.car_wash_collect_safe)
		end
		controls.front_heat[key] = common.add_number_int(
			ctx,
			front,
			t("moneyfronts.field.heat"),
			data.heat.min,
			data.heat.max,
			data.heat.step,
			function()
				return actions.get_front_heat_value(key)
			end,
			function(value)
				actions.set_front_heat_value(key, value)
				controller.refresh_controls()
			end
		)
		common.add_button(front, t("moneyfronts.action.apply_heat"), function()
			actions.apply_front_heat_value(key)
			controller.refresh_controls()
		end)
		controls.front_lock[key] = common.add_toggle(ctx, front, t("moneyfronts.action.lock_heat"), function()
			return actions.get_front_heat_lock_active(key)
		end, function(enabled)
			actions.set_front_heat_lock_active(key, enabled)
			controller.refresh_controls()
		end)
		::continue::
	end

	controller.refresh_controls()
	return parent_menu
end

return controller
