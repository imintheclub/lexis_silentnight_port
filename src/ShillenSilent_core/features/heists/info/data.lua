local option_helpers = require("ShillenSilent_core.core.options")
local i18n = require("ShillenSilent_core.i18n")
local data = {}

data.gta_plus = {
	pattern = "48 8D 15 ? ? ? ? 41 B8 18 02 00 00 E8",
}

data.ui_modes = {
	{ label_key = "info.mode.click", value = "click" },
	{ label_key = "info.mode.controller", value = "controller" },
}

data.theme_modes = {
	{ label_key = "info.theme.dark", value = "dark" },
	{ label_key = "info.theme.light", value = "light" },
	{ label_key = "info.theme.dracula", value = "dracula" },
	{ label_key = "info.theme.google_dark", value = "google_dark" },
	{ label_key = "info.theme.google_light", value = "google_light" },
	{ label_key = "info.theme.github_light", value = "github_light" },
	{ label_key = "info.theme.flexoki_light", value = "flexoki_light" },
	{ label_key = "info.theme.gruvbox", value = "gruvbox" },
	{ label_key = "info.theme.nord", value = "nord" },
	{ label_key = "info.theme.material", value = "material" },
	{ label_key = "info.theme.tokyo_night", value = "tokyo_night" },
	{ label_key = "info.theme.night_owl", value = "night_owl" },
	{ label_key = "info.theme.cobalt2", value = "cobalt2" },
	{ label_key = "info.theme.shades_of_purple", value = "shades_of_purple" },
	{ label_key = "info.theme.everforest", value = "everforest" },
	{ label_key = "info.theme.ayu", value = "ayu" },
	{ label_key = "info.theme.synthwave84", value = "synthwave84" },
	{ label_key = "info.theme.kanagawa", value = "kanagawa" },
	{ label_key = "info.theme.solarized_dark", value = "solarized_dark" },
}

data.languages = i18n.languages
data.visible_languages = {}

local hidden_menu_languages = {
	jp = true,
	kr = true,
	["zh-cn"] = true,
}

for i = 1, #data.languages do
	local language = data.languages[i]
	if not hidden_menu_languages[language.value] then
		data.visible_languages[#data.visible_languages + 1] = language
	end
end

local function normalize_from_options(options, value, fallback)
	if type(value) ~= "string" then
		return fallback
	end
	local normalized = value:lower():gsub("^%s+", ""):gsub("%s+$", "")
	for i = 1, #options do
		if options[i].value == normalized then
			return normalized
		end
	end
	return fallback
end

function data.normalize_ui_mode(value, fallback)
	return normalize_from_options(data.ui_modes, value, fallback or "click")
end

function data.normalize_theme_mode(value, fallback)
	return normalize_from_options(data.theme_modes, value, fallback or "dark")
end

function data.normalize_language(value, fallback)
	return normalize_from_options(data.languages, value, fallback or "en")
end

data.option_index_by_value = option_helpers.index_by_value

function data.localized_options(options, translate)
	local out = {}
	for i = 1, #options do
		local option = options[i]
		out[i] = {
			name = translate(option.label_key),
			label_key = option.label_key,
			value = option.value,
		}
	end
	return out
end

data.option_names = option_helpers.names

data.option_value_by_name = option_helpers.value_by_name

return data
