local i18n = require("ShillenSilent_core.i18n")
local config_store = require("ShillenSilent_core.core.config_store")

local ui_mode = {}

local DEFAULT_MODE = "click"
local VALID_MODES = {
	click = true,
	controller = true,
}

local function normalize_mode(mode)
	if type(mode) ~= "string" then
		return nil
	end
	local normalized = mode:lower():gsub("^%s+", ""):gsub("%s+$", "")
	if VALID_MODES[normalized] then
		return normalized
	end
	return nil
end

local function read_mode_config()
	return normalize_mode(config_store.get("ui_mode", nil))
end

function ui_mode.resolve_active_mode()
	local override_mode = normalize_mode(_G.ShillenSilent_UIMode)
	if override_mode then
		return override_mode, "override"
	end

	local config_mode = read_mode_config()
	if config_mode then
		return config_mode, "config"
	end

	return DEFAULT_MODE, "default"
end

function ui_mode.set_mode_for_next_load(mode)
	local normalized = normalize_mode(mode)
	if not normalized then
		return false, i18n.t("notify.invalid_ui_mode")
	end

	local ok, err = config_store.set("ui_mode", normalized)
	if not ok then
		return false, tostring(err)
	end

	return true, normalized
end

function ui_mode.get_mode_for_next_load()
	local mode = read_mode_config()
	return mode or DEFAULT_MODE
end

return ui_mode
