local common = require("ShillenSilent_core.ui.controller.widgets")
local i18n = require("ShillenSilent_core.i18n")
local data = require("ShillenSilent_core.features.heists.info.data")
local state = require("ShillenSilent_core.features.heists.info.state")
local actions = require("ShillenSilent_core.features.heists.info.actions")

local controller = {
	ctx = { syncing = false },
	controls = {},
}

local t = i18n.t

function controller.refresh_controls()
	actions.refresh_state()
	local ctx = controller.ctx
	local controls = controller.controls
	common.set_control_value(
		ctx,
		controls.mode_combo,
		data.option_index_by_value(data.ui_modes, state.config.ui_mode, 1)
	)
	common.set_control_value(
		ctx,
		controls.theme_combo,
		data.option_index_by_value(data.theme_modes, state.config.theme_mode, 1)
	)
	common.set_control_value(
		ctx,
		controls.language_combo,
		data.option_index_by_value(data.languages, state.config.language, 1)
	)
	return true
end

function controller.register(parent_menu)
	if not parent_menu then
		return nil
	end

	actions.refresh_state()
	local ctx = controller.ctx
	local controls = controller.controls

	local root = parent_menu:submenu(t("feature.info.name"))
	common.add_button(root, t("menu.unlock_gta_plus"), actions.unlock_gta_plus)
	controls.mode_combo = common.add_combo_options(
		ctx,
		root,
		t("info.field.ui_mode"),
		data.localized_options(data.ui_modes, t),
		function()
			return state.config.ui_mode
		end,
		function(value)
			actions.set_ui_mode(value)
			controller.refresh_controls()
		end
	)

	controls.theme_combo = common.add_combo_options(
		ctx,
		root,
		t("info.field.theme"),
		data.localized_options(data.theme_modes, t),
		function()
			return state.config.theme_mode
		end,
		function(value)
			actions.set_theme_mode(value)
			controller.refresh_controls()
		end
	)

	controls.language_combo = common.add_combo_options(
		ctx,
		root,
		t("info.field.language"),
		data.localized_options(data.languages, t),
		function()
			return state.config.language
		end,
		function(value)
			actions.set_language(value)
			controller.refresh_controls()
		end
	)

	controller.refresh_controls()
	return root
end

return controller
