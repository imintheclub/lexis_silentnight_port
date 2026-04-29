local ui = require("ShillenSilent_core.ui.click.widgets")
local i18n = require("ShillenSilent_core.i18n")
local data = require("ShillenSilent_core.features.heists.info.data")
local state = require("ShillenSilent_core.features.heists.info.state")
local actions = require("ShillenSilent_core.features.heists.info.actions")

local click = {}
local refs = {}

local t = i18n.t

local function mode_options()
	return data.localized_options(data.ui_modes, t)
end

local function theme_options()
	return data.localized_options(data.theme_modes, t)
end

local function language_options()
	return data.localized_options(data.languages, t)
end

function click.refresh()
	actions.refresh_state()
	if refs.mode_dropdown then
		refs.mode_dropdown.value = data.option_index_by_value(data.ui_modes, state.config.ui_mode, 1)
	end
	if refs.theme_dropdown then
		refs.theme_dropdown.value = data.option_index_by_value(data.theme_modes, state.config.theme_mode, 1)
	end
	if refs.language_dropdown then
		refs.language_dropdown.value = data.option_index_by_value(data.languages, state.config.language, 1)
	end
	return true
end

function click.register(heist_tab)
	if type(heist_tab) ~= "table" then
		return nil
	end

	actions.refresh_state()

	local settings = ui.group(heist_tab, t("info.group.settings"), nil, nil, nil, 160, "info")
	ui.button(settings, "info_gta_plus", t("menu.unlock_gta_plus"), actions.unlock_gta_plus)

	local modes = mode_options()
	refs.mode_dropdown = ui.dropdown(
		settings,
		"info_ui_mode",
		t("info.field.ui_mode"),
		data.option_names(modes),
		data.option_index_by_value(data.ui_modes, state.config.ui_mode, 1),
		function(opt)
			local target_id = data.option_value_by_name(modes, opt, state.config.ui_mode)
			actions.set_ui_mode(target_id)
			click.refresh()
		end
	)

	local themes = theme_options()
	refs.theme_dropdown = ui.dropdown(
		settings,
		"info_theme_mode",
		t("info.field.theme"),
		data.option_names(themes),
		data.option_index_by_value(data.theme_modes, state.config.theme_mode, 1),
		function(opt)
			local target_id = data.option_value_by_name(themes, opt, state.config.theme_mode)
			actions.set_theme_mode(target_id)
			click.refresh()
		end
	)

	local languages = language_options()
	refs.language_dropdown = ui.dropdown(
		settings,
		"info_language",
		t("info.field.language"),
		data.option_names(languages),
		data.option_index_by_value(data.languages, state.config.language, 1),
		function(opt)
			local target_id = data.option_value_by_name(languages, opt, state.config.language)
			actions.set_language(target_id)
			click.refresh()
		end
	)

	return heist_tab
end

return click
