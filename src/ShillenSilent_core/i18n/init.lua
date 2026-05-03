local config_store = require("ShillenSilent_core.core.config_store")

local DEFAULT_LANGUAGE = "en"

local locale_registry = {
	{ label_key = "info.language.en", value = "en", module = "ShillenSilent_core.i18n.locales.en" },
	{ label_key = "info.language.es", value = "es", module = "ShillenSilent_core.i18n.locales.es" },
	{ label_key = "info.language.de", value = "de", module = "ShillenSilent_core.i18n.locales.de" },
	{ label_key = "info.language.fr", value = "fr", module = "ShillenSilent_core.i18n.locales.fr" },
	{ label_key = "info.language.it", value = "it", module = "ShillenSilent_core.i18n.locales.it" },
	{ label_key = "info.language.jp", value = "jp", module = "ShillenSilent_core.i18n.locales.jp" },
	{ label_key = "info.language.kr", value = "kr", module = "ShillenSilent_core.i18n.locales.kr" },
	{ label_key = "info.language.pl", value = "pl", module = "ShillenSilent_core.i18n.locales.pl" },
	{ label_key = "info.language.pt_br", value = "pt-br", module = "ShillenSilent_core.i18n.locales.pt-BR" },
	{ label_key = "info.language.ru", value = "ru", module = "ShillenSilent_core.i18n.locales.ru" },
	{ label_key = "info.language.zh_cn", value = "zh-cn", module = "ShillenSilent_core.i18n.locales.zh-cn" },
}

local locale_modules = {}
local locale_cache = {
	language = nil,
	module = nil,
	values = nil,
}
local locale = {}

local languages = {}
for i = 1, #locale_registry do
	local entry = locale_registry[i]
	languages[i] = {
		label_key = entry.label_key,
		value = entry.value,
	}
	locale_modules[entry.value] = entry.module
end

local i18n = {
	locale = locale,
	language = DEFAULT_LANGUAGE,
	languages = languages,
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

local function load_locale(language)
	local module_name = locale_modules[language]
	if not module_name then
		return nil
	end
	if locale_cache.language == language and locale_cache.values then
		return locale_cache.values
	end

	local ok, loaded = pcall(require, module_name)
	if ok and type(loaded) == "table" then
		if locale_cache.module and locale_cache.module ~= module_name then
			package.loaded[locale_cache.module] = nil
		end
		locale_cache.language = language
		locale_cache.module = module_name
		locale_cache.values = loaded
		return loaded
	end
	return nil
end

local function load_uncached_locale(language)
	if locale_cache.language == language and locale_cache.values then
		return locale_cache.values
	end

	local module_name = locale_modules[language]
	if not module_name then
		return nil
	end

	local ok, loaded = pcall(require, module_name)
	if ok and type(loaded) == "table" then
		package.loaded[module_name] = nil
		return loaded
	end
	return nil
end

local function drop_inactive_locale_modules(active_language)
	for language, module_name in pairs(locale_modules) do
		if language ~= active_language then
			package.loaded[module_name] = nil
		end
	end
end

local function apply_language(language)
	local normalized = normalize_language(language, DEFAULT_LANGUAGE)
	local loaded = load_locale(normalized)
	if not loaded and normalized ~= DEFAULT_LANGUAGE then
		normalized = DEFAULT_LANGUAGE
		loaded = load_locale(DEFAULT_LANGUAGE)
	end

	locale = loaded or {}
	i18n.locale = locale
	i18n.language = normalized
	drop_inactive_locale_modules(normalized)
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
	if text == nil and i18n.language ~= DEFAULT_LANGUAGE then
		local fallback_locale = load_uncached_locale(DEFAULT_LANGUAGE)
		text = fallback_locale and fallback_locale[key] or nil
	end
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
