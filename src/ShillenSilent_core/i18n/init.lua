local config_store = require("ShillenSilent_core.core.config_store")

local DEFAULT_LANGUAGE = "en"

local locales = {
	en = require("ShillenSilent_core.i18n.locales.en"),
	es = require("ShillenSilent_core.i18n.locales.es"),
}

local locale = locales[DEFAULT_LANGUAGE]

local i18n = {
	locale = locale,
	language = DEFAULT_LANGUAGE,
	languages = {
		{ label_key = "info.language.en", value = "en" },
		{ label_key = "info.language.es", value = "es" },
	},
}

local function normalize_language(value, fallback)
	if type(value) ~= "string" then
		return fallback or DEFAULT_LANGUAGE
	end
	local normalized = value:lower():gsub("^%s+", ""):gsub("%s+$", "")
	for i = 1, #i18n.languages do
		if i18n.languages[i].value == normalized then
			return normalized
		end
	end
	return fallback or DEFAULT_LANGUAGE
end

local function apply_language(language)
	local normalized = normalize_language(language, DEFAULT_LANGUAGE)
	locale = locales[normalized] or locales[DEFAULT_LANGUAGE]
	i18n.locale = locale
	i18n.language = normalized
	return normalized
end

local function read_configured_language()
	return normalize_language(config_store.get("language", nil), DEFAULT_LANGUAGE)
end

local function interpolate(text, vars)
	if type(vars) ~= "table" then
		return text
	end
	return (
		text:gsub("{([%w_]+)}", function(key)
			local value = vars[key]
			if value == nil then
				return "{" .. key .. "}"
			end
			return tostring(value)
		end)
	)
end

function i18n.t(key, vars)
	local text = locale[key]
	if text == nil then
		return tostring(key)
	end
	return interpolate(text, vars)
end

function i18n.normalize_language(value, fallback)
	return normalize_language(value, fallback)
end

function i18n.read_language()
	return apply_language(read_configured_language())
end

function i18n.get_configured_language()
	return read_configured_language()
end

function i18n.write_language(language)
	local normalized = normalize_language(language, i18n.language or DEFAULT_LANGUAGE)
	return config_store.set("language", normalized), normalized
end

i18n.read_language()

return i18n
