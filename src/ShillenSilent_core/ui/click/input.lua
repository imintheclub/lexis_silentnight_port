local config = require("ShillenSilent_core.ui.click.config")
local state = require("ShillenSilent_core.ui.click.state")
local primitives = require("ShillenSilent_core.ui.click.primitives")

local click_input = {}

function click_input.get_win_offset()
	local anim_y_offset = (1.0 - state.animation.progress) * config.motion.open_y_offset
	return state.window.x - config.origin_x, (state.window.y - config.origin_y) + anim_y_offset
end

function click_input.is_hovered(x, y, w, h)
	if state.animation.progress < 0.9 then
		return false
	end
	local ox, oy = state._frame_ox, state._frame_oy
	return input.is_mouse_within(primitives.vec(x + ox, y + oy), primitives.vec(w, h))
end

function click_input.drawer_blocks_content_hover()
	local drawer = state.drawer
	return type(drawer) == "table"
		and (drawer.open == true or (drawer.target or 0.0) > 0.01 or (drawer.progress or 0.0) > 0.01)
end

function click_input.is_hovered_content(item_x, item_y, w, h)
	if click_input.drawer_blocks_content_hover() then
		return false
	end

	local ox, oy = state._frame_ox, state._frame_oy

	local cx, cy = config.content_area.x + ox, config.content_area.y + oy
	local cw, ch = config.content_area.w, config.content_area.h

	if not input.is_mouse_within(primitives.vec(cx, cy), primitives.vec(cw, ch)) then
		return false
	end

	return input.is_mouse_within(primitives.vec(item_x + ox, item_y + oy), primitives.vec(w, h))
end

function click_input.update()
	local m_pos = input.mouse_position()
	local m_click = input.mouse(1)
	state.mouse.x = m_pos.x
	state.mouse.y = m_pos.y
	state.mouse.down = m_click.pressed
	state.mouse.clicked = m_click.just_pressed

	if not state.mouse.down then
		state.dragging_slider = nil
		state.window.is_dragging = false
		state.window.is_resizing = false
		state.scroll.is_dragging = false
	end
end

return click_input
