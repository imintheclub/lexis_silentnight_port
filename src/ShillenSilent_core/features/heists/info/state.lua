local data = require("ShillenSilent_core.features.heists.info.data")

local state = {
	config = {
		ui_mode = "click",
		theme_mode = "dark",
		language = "en",
	},
}

function state.set_ui_mode(mode)
	state.config.ui_mode = data.normalize_ui_mode(mode, state.config.ui_mode)
	return state.config.ui_mode
end

function state.set_theme_mode(mode)
	state.config.theme_mode = data.normalize_theme_mode(mode, state.config.theme_mode)
	return state.config.theme_mode
end

function state.set_language(language)
	state.config.language = data.normalize_language(language, state.config.language)
	return state.config.language
end

return state
