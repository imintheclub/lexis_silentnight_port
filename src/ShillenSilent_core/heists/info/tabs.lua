local core = require("ShillenSilent_core.core.bootstrap")
local ui_mode = require("ShillenSilent_core.app.ui_mode")
local ui = require("ShillenSilent_core.core.ui")

local config = core.config

local function toggle_mode_with_notice()
	local current = ui_mode.get_mode_for_next_load()
	local next_mode = (current == "controller") and "click" or "controller"
	local ok, result = ui_mode.set_mode_for_next_load(next_mode)
	if notify then
		if ok then
			notify.push("UI Mode", "Next load: " .. tostring(result), 2600)
		else
			notify.push("UI Mode", "Failed: " .. tostring(result), 3200)
		end
	end
	return ok
end

local function register(heistTab)
	if type(heistTab) ~= "table" then
		return nil
	end

	local gInfo = ui.group(heistTab, "Info", nil, nil, nil, 160, "info")
	ui.label(gInfo, "Current menu: " .. tostring(ui_mode.get_mode_for_next_load()), config.colors.accent)
	ui.button(gInfo, "info_ui_mode_toggle", "Toggle UI Mode", function()
		toggle_mode_with_notice()
	end)

	return heistTab
end

local info_tabs = {
	register = register,
}

return info_tabs
