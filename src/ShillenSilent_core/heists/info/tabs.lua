local core = require("ShillenSilent_core.core.bootstrap")
local ui_mode = require("ShillenSilent_core.app.ui_mode")
local ui = require("ShillenSilent_core.core.ui")

local config = core.config

local GTA_PLUS_PATTERN = "48 8D 15 ? ? ? ? 41 B8 18 02 00 00 E8"
local GTA_PLUS_GLOBAL = 1965683

local function unlock_gta_plus()
	local ok, err = pcall(function()
		local s = memory.scan(GTA_PLUS_PATTERN)
		if not s or s.value == 0 then
			if notify then
				notify.push("GTA+", "Pattern not found (game version mismatch?)", 3000)
			end
			return
		end
		local a = s:rip(3, 7)
		if a then
			a.int32 = 1
		end
		script.globals(GTA_PLUS_GLOBAL).bool = true
		script.globals(GTA_PLUS_GLOBAL):at(3).int32 = 10
	end)
	if not ok then
		if notify then
			notify.push("GTA+", "Error: " .. tostring(err), 3000)
		end
		return
	end
	if notify then
		notify.push("GTA+", "GTA+ temporarily unlocked", 3000)
	end
end

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

	local gInfo = ui.group(heistTab, "", nil, nil, nil, 160, "info")
	ui.label(gInfo, "Current menu: " .. tostring(ui_mode.get_mode_for_next_load()), config.colors.accent)
	ui.button(gInfo, "info_ui_mode_toggle", "Toggle UI Mode", function()
		toggle_mode_with_notice()
	end)
	ui.button(gInfo, "info_gta_plus", "Unlock GTA+", function()
		unlock_gta_plus()
	end)
	local current_theme_label = ui.label(gInfo, "", config.colors.text_sec)
	local theme_toggle_button = nil

	local function sync_theme_ui_state()
		local active_mode = tostring(config.theme_mode or core.read_theme_mode())
		local next_mode = (active_mode == "dark") and "light" or "dark"
		current_theme_label.text = "Current theme: " .. active_mode
		if theme_toggle_button then
			local title_mode = next_mode:gsub("^%l", string.upper)
			theme_toggle_button.label = "Switch to " .. title_mode
		end
	end

	theme_toggle_button = ui.button(gInfo, "info_theme_mode_toggle", "Switch to Light", function()
		local current_mode = tostring(config.theme_mode or core.read_theme_mode())
		local next_mode = (current_mode == "dark") and "light" or "dark"
		local applied_mode = core.apply_theme(next_mode)
		local wrote = core.write_theme_mode(applied_mode)
		sync_theme_ui_state()

		if notify then
			if wrote then
				notify.push("Theme", "Theme set to " .. tostring(applied_mode) .. " (saved for next reload)", 2600)
			else
				notify.push("Theme", "Theme set to " .. tostring(applied_mode) .. " (save failed)", 3200)
			end
		end
	end)
	sync_theme_ui_state()

	return heistTab
end

local info_tabs = {
	register = register,
}

return info_tabs
