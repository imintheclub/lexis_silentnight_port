-- ---------------------------------------------------------
-- 8. Loop (Safe Control Lock Edition)
-- ---------------------------------------------------------

local core = require("ShillenSilent_core.core.bootstrap")
local ui = require("ShillenSilent_core.core.ui")
local native_api = require("ShillenSilent_core.core.native_api")
local presets = require("ShillenSilent_core.shared.presets_and_shared")
local heist_state = require("ShillenSilent_core.shared.heist_state")
local solo_launch = require("ShillenSilent_core.runtime.solo_launch")
local cayo_logic = require("ShillenSilent_core.heists.cayo.logic")
local casino_logic = require("ShillenSilent_core.heists.casino.logic")
local salvageyard_logic = require("ShillenSilent_core.heists.salvageyard.logic")

local state = core.state
local config = core.config
local native = core.native
local CONTROL_ACTION_BLOCK_LIST = native_api.CONTROL_ACTION_BLOCK_LIST
local disable_control_action = native_api.disable_control_action

local solo_launch_generic = solo_launch.solo_launch_generic
local solo_launch_casino_setup = solo_launch.solo_launch_casino_setup
local solo_launch_reset_casino = solo_launch.solo_launch_reset_casino
local solo_launch_reset_doomsday = solo_launch.solo_launch_reset_doomsday
local solo_launch_reset_apartment = solo_launch.solo_launch_reset_apartment

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

local SOLO_LAUNCH_HANDLERS = {
	{ key = "casino", setup = solo_launch_casino_setup, reset = solo_launch_reset_casino },
	{ key = "apartment", setup = nil, reset = solo_launch_reset_apartment },
	{ key = "doomsday", setup = nil, reset = solo_launch_reset_doomsday },
}

local HEIST_ENFORCE_INTERVAL_MS = 150
local next_heist_enforce_tick = 0

local function maybe_sync_max_payouts()
	pcall(presets.hp_refresh_apartment_max_payout, false, false)
	pcall(cayo_logic.cayo_refresh_max_payout, false, false)
	pcall(casino_logic.casino_refresh_max_payout, false, false)

	local doomsday_callbacks = heist_state.doomsday and heist_state.doomsday.callbacks or nil
	if doomsday_callbacks and type(doomsday_callbacks.refresh_max_payout) == "function" then
		pcall(doomsday_callbacks.refresh_max_payout, false, false)
	end
end

local function maybe_enforce_heist_toggles()
	local now_tick = (util and util.get_tick_count and util.get_tick_count()) or nil
	if now_tick and now_tick < next_heist_enforce_tick then
		return
	end

	pcall(cayo_logic.cayo_enforce_heist_toggles)
	pcall(casino_logic.casino_enforce_heist_toggles)
	pcall(salvageyard_logic.salvage_enforce_heist_toggles)

	if now_tick then
		next_heist_enforce_tick = now_tick + HEIST_ENFORCE_INTERVAL_MS
	end
end

local function start_runtime_loop()
	util.create_thread(function()
		while true do
			if _G.ShillenSilent_ForceStop then
				return
			end

			for i = 1, #SOLO_LAUNCH_HANDLERS do
				local handler = SOLO_LAUNCH_HANDLERS[i]
				local key = handler.key

				local enabled = state.solo_launch[key]
				local was_enabled = state.solo_launch_prev[key]

				if enabled then
					pcall(solo_launch_generic)
					if handler.setup then
						pcall(handler.setup)
					end
				elseif was_enabled and handler.reset then
					pcall(handler.reset)
				end

				state.solo_launch_prev[key] = enabled
			end

			pcall(maybe_sync_max_payouts)
			pcall(maybe_enforce_heist_toggles)

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

	pcall(subscribe_scroll_handler)
	start_runtime_loop()
	return true
end

return runtime_main_loop
