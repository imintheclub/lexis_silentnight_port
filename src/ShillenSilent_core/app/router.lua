local ui_mode = require("ShillenSilent_core.app.ui_mode")

local app_router = {
	started = false,
	active_mode = nil,
}

local function notify_mode(title, message, duration)
	if notify then
		notify.push(title, message, duration or 2500)
	end
end

local function install_quick_switch_utilities()
	_G.ShillenSilent_GetUIModeNextLoad = function()
		return ui_mode.get_mode_for_next_load()
	end

	_G.ShillenSilent_SetUIModeNextLoad = function(mode)
		local ok, result = ui_mode.set_mode_for_next_load(mode)
		if ok then
			notify_mode("ShillenSilent", "UI mode set for next load: " .. tostring(result), 2800)
		else
			notify_mode("ShillenSilent", "Failed to set UI mode: " .. tostring(result), 3200)
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
		local menu_main = require("ShillenSilent_core.menu.main")
		if not menu_main or type(menu_main.start) ~= "function" then
			return false, "controller mode entry missing start()"
		end

		if menu_main.started then
			return true
		end

		local ok, started = pcall(menu_main.start)
		if not ok then
			return false, started
		end
		if started == false and not menu_main.started then
			return false, "controller mode start returned false"
		end
		return true
	end

	local app_main = require("ShillenSilent_core.app.main")
	if not app_main or type(app_main.start) ~= "function" then
		return false, "click mode entry missing start()"
	end
	local ok, started = pcall(app_main.start)
	if not ok then
		return false, started
	end
	if started == nil then
		return false, "click mode start returned nil"
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
		notify_mode("ShillenSilent", "Controller mode failed; falling back to click.", 3200)
		local fallback_ok, fallback_err = load_mode("click")
		if fallback_ok then
			active_mode = "click"
		else
			err = fallback_err
		end
		ok = fallback_ok
	end

	if not ok then
		notify_mode("ShillenSilent", "UI mode load failed: " .. tostring(err), 3500)
		return nil
	end

	app_router.active_mode = active_mode
	app_router.started = true

	if resolved_from ~= "default" then
		local suffix = (active_mode ~= resolved_mode) and (" -> " .. active_mode) or ""
		notify_mode("ShillenSilent", "UI mode: " .. resolved_mode .. " (" .. resolved_from .. ")" .. suffix, 2200)
	end

	return active_mode
end

app_router.start()

return app_router
