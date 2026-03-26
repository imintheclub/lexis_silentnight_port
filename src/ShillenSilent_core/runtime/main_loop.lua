-- ---------------------------------------------------------
-- 8. Loop (Safe Control Lock Edition)
-- ---------------------------------------------------------

local core = require("ShillenSilent_core.core.bootstrap")
local ui = require("ShillenSilent_core.core.ui")
local native_api = require("ShillenSilent_core.core.native_api")
local runtime_services = require("ShillenSilent_core.runtime.services")

local state = core.state
local config = core.config
local native = core.native
local CONTROL_ACTION_BLOCK_LIST = native_api.CONTROL_ACTION_BLOCK_LIST
local disable_control_action = native_api.disable_control_action

local runtime_main_loop = {
	started = false,
}

local function subscribe_scroll_handler()
	if not events.event.scroll then
		return
	end

	events.subscribe(events.event.scroll, function(e)
		if _G.ShillenSilent_ForceStop then
			return
		end
		if not state.animation.open and state.animation.progress < 0.01 then
			return
		end

		local scroll_speed = 30
		local delta = e.offset * scroll_speed

		local m = input.mouse_position()
		local mx, my = m.x, m.y

		local win_x = state.window.x
		local win_y = state.window.y
		local menu_w = config.menu_width

		local bodyY_local = config.sidebar_gap
		local bodyY_abs = win_y + bodyY_local

		if my < bodyY_abs then
			return
		end

		if mx >= win_x and mx <= win_x + menu_w then
			if state.scroll.max_y > 0 then
				state.scroll.y = state.scroll.y + delta
				if state.scroll.y < 0 then
					state.scroll.y = 0
				end
				if state.scroll.y > state.scroll.max_y then
					state.scroll.y = state.scroll.max_y
				end
			end
		end
	end)
end

local function start_runtime_loop()
	util.create_thread(function()
		while true do
			if _G.ShillenSilent_ForceStop then
				return
			end

			local t_pressed = false
			pcall(function()
				if input and input.key and input.key(84) then
					t_pressed = input.key(84).just_pressed
				end
			end)

			if t_pressed then
				state.animation.open = not state.animation.open
				state.animation.target = state.animation.open and 1.0 or 0.0
				pcall(function()
					input.show_cursor(state.animation.open)
				end)

				if state.animation.open then
					if native and native.set_cursor_position then
						pcall(native.set_cursor_position, 0.5, 0.5)
					end
				end
			end

			local custom_visible = state.animation.open or state.animation.progress > 0.01
			if custom_visible then
				pcall(ui.render)

				pcall(function()
					-- Disable clicking and scrolling specific actions
					disable_control_action(CONTROL_ACTION_BLOCK_LIST)

					-- Disable player firing
					if players and players.user then
						local player_id = players.user()
						invoker.call(0x5E6CC07646BBEAB8, player_id, true)
					end
				end)
			else
				pcall(function()
					if players and players.user then
						local player_id = players.user()
						invoker.call(0x5E6CC07646BBEAB8, player_id, false)
					end
				end)
			end

			util.yield(0)
		end
	end)
end

function runtime_main_loop.start()
	if runtime_main_loop.started then
		return false
	end
	runtime_main_loop.started = true

	pcall(runtime_services.start)
	pcall(subscribe_scroll_handler)
	start_runtime_loop()
	return true
end

return runtime_main_loop
