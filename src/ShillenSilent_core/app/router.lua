local ui_mode = require("ShillenSilent_core.app.ui_mode")
local i18n = require("ShillenSilent_core.i18n")
local notify_core = require("ShillenSilent_core.core.notify")

local app_router = {
	started = false,
	active_mode = nil,
}

local notify_mode = notify_core.feature("app.name", 2500)

local function install_quick_switch_utilities()
	_G.ShillenSilent_GetUIModeNextLoad = function()
		return ui_mode.get_mode_for_next_load()
	end

	_G.ShillenSilent_SetUIModeNextLoad = function(mode)
		local ok, result = ui_mode.set_mode_for_next_load(mode)
		if ok then
			notify_mode("notify.ui_mode_set_next_load", 2800, { mode = tostring(result) })
		else
			notify_mode("notify.ui_mode_set_failed", 3200, { error = tostring(result) })
		end
		return ok, result
	end

	_G.ShillenSilent_ToggleUIModeNextLoad = function()
		local current = ui_mode.get_mode_for_next_load()
		local next_mode = (current == "controller") and "click" or "controller"
		return _G.ShillenSilent_SetUIModeNextLoad(next_mode)
	end
end

local function load_mode(mode)
	if mode == "controller" then
		local menu_main = require("ShillenSilent_core.ui.controller")
		if not menu_main or type(menu_main.start) ~= "function" then
			return false, i18n.t("notify.controller_entry_missing")
		end

		if menu_main.started then
			return true
		end

		local ok, started = pcall(menu_main.start)
		if not ok then
			return false, started
		end
		if started == false and not menu_main.started then
			return false, i18n.t("notify.controller_start_false")
		end
		return true
	end

	local app_main = require("ShillenSilent_core.app.main")
	if not app_main or type(app_main.start) ~= "function" then
		return false, i18n.t("notify.click_entry_missing")
	end
	local ok, started = pcall(app_main.start)
	if not ok then
		return false, started
	end
	if started == nil then
		return false, i18n.t("notify.click_start_nil")
	end
	return true
end

function app_router.start()
	if app_router.started then
		return app_router.active_mode
	end

	install_quick_switch_utilities()

	local resolved_mode, resolved_from = ui_mode.resolve_active_mode()
	local active_mode = resolved_mode

	local ok, err = load_mode(active_mode)
	if not ok and active_mode == "controller" then
		notify_mode("notify.controller_mode_fallback", 3200)
		local fallback_ok, fallback_err = load_mode("click")
		if fallback_ok then
			active_mode = "click"
		else
			err = fallback_err
		end
		ok = fallback_ok
	end

	if not ok then
		notify_mode("notify.ui_mode_load_failed", 3500, { error = tostring(err) })
		return nil
	end

	app_router.active_mode = active_mode
	app_router.started = true

	if resolved_from ~= "default" then
		local mode = resolved_mode
		if active_mode ~= resolved_mode then
			mode = mode .. " -> " .. active_mode
		end
		notify_mode("notify.ui_mode_active", 2200, { mode = mode, source = resolved_from })
	end

	return active_mode
end

app_router.start()

return app_router
