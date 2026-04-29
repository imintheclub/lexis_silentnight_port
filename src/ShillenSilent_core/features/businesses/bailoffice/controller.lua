local common = require("ShillenSilent_core.ui.controller.widgets")
local i18n = require("ShillenSilent_core.i18n")
local data = require("ShillenSilent_core.features.businesses.bailoffice.data")
local state = require("ShillenSilent_core.features.businesses.bailoffice.state")
local actions = require("ShillenSilent_core.features.businesses.bailoffice.actions")

local controller = {
	ctx = { syncing = false },
	controls = {},
}

local t = i18n.t

function controller.refresh_controls()
	common.set_control_value(controller.ctx, controller.controls.location_combo, state.config.location_index)
	return true
end

function controller.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local ctx = controller.ctx
	local controls = controller.controls

	local root = parent_menu:submenu(t("feature.bailoffice.name"))
	root:breaker(t("feature.bailoffice.name"))

	local teleport = root:submenu(t("bailoffice.group.teleport"))
	local locations = data.localized_locations(t)
	controls.location_combo = common.add_combo_options(
		ctx,
		teleport,
		t("bailoffice.field.location"),
		locations,
		function()
			return state.config.location_index
		end,
		function(value)
			state.set_location_index(value)
			controller.refresh_controls()
		end
	)
	common.add_button(teleport, t("bailoffice.action.teleport"), actions.teleport)
	common.add_button(teleport, t("bailoffice.action.teleport_computer"), actions.teleport_computer)

	local tools = root:submenu(t("bailoffice.group.tools"))
	common.add_button(tools, t("bailoffice.action.collect_safe"), actions.collect_safe)

	controller.refresh_controls()
	return root
end

return controller
