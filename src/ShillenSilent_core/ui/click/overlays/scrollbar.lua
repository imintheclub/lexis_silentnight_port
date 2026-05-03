local config = require("ShillenSilent_core.ui.click.config")
local state = require("ShillenSilent_core.ui.click.state")
local primitives = require("ShillenSilent_core.ui.click.primitives")
local click_input = require("ShillenSilent_core.ui.click.input")

local scrollbar = {}

function scrollbar.render(contentH, subtab_bar_height, groups_start_y)
	if state.scroll.max_y <= 0 then
		return
	end

	local sb = config.scrollbar
	local sbH = contentH - subtab_bar_height
	local sbY = groups_start_y
	local thumbH = math.max(config.control.scrollbar_min_thumb, (sbH / (sbH + state.scroll.max_y)) * sbH)
	local thumbY = sbY + (state.scroll.y / state.scroll.max_y) * (sbH - thumbH)

	primitives.render_rect(sb.x, sbY, sb.w, sbH, config.colors.scroll_track, config.radius.full)
	primitives.render_rect(sb.x, thumbY, sb.w, thumbH, config.colors.accent, config.radius.full)

	if
		not state.active_dropdown
		and click_input.is_hovered(
			sb.x - config.control.scrollbar_grab_pad,
			sbY,
			sb.w + (config.control.scrollbar_grab_pad * 2),
			sbH
		)
		and state.mouse.clicked
	then
		state.scroll.is_dragging = true
	end
	if state.scroll.is_dragging and state.mouse.down then
		local my = state.mouse.y - state._frame_oy
		local ratio = math.max(0, math.min(1, (my - sbY) / sbH))
		state.scroll.y = ratio * state.scroll.max_y
	end
end

return scrollbar
