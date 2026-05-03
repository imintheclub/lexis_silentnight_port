local config = require("ShillenSilent_core.ui.click.config")
local state = require("ShillenSilent_core.ui.click.state")
local primitives = require("ShillenSilent_core.ui.click.primitives")
local click_input = require("ShillenSilent_core.ui.click.input")
local layout_engine = require("ShillenSilent_core.ui.click.layout_engine")
local common = require("ShillenSilent_core.ui.click.controls.common")

local dropdown_panel = {}

function dropdown_panel.render(pendingDropdowns)
	if #pendingDropdowns <= 0 then
		state.dropdown_scroll_max = 0
		return
	end

	local ox, oy = state._frame_ox, state._frame_oy
	for dd_idx = 1, #pendingDropdowns do
		local dd = pendingDropdowns[dd_idx]
		local itemHeight = config.space.x9
		local fullOptsH = #dd.item.options * itemHeight
		local open_t = dd.open_t or 1.0
		local resolution = game.resolution()
		local screen_w = resolution.x
		local screen_h = resolution.y
		local screen_margin = config.space.x2
		local max_panel_w = math.max(dd.w, screen_w - (screen_margin * 2))
		local panel_w = layout_engine.get_dropdown_panel_width(dd.item, dd.w, max_panel_w)
		local panel_x = primitives.clamp(dd.x, screen_margin - ox, screen_w - ox - screen_margin - panel_w)
		local max_visible_items =
			math.max(1, math.floor((config.control and config.control.dropdown_max_visible_items) or 10))
		local min_visible_items =
			math.max(1, math.floor((config.control and config.control.dropdown_min_visible_items) or 3))
		local max_list_h = itemHeight * max_visible_items
		local min_list_h = math.min(fullOptsH, itemHeight * min_visible_items)
		local screen_list_h = math.max(1, screen_h - (screen_margin * 2))
		local below_space = screen_h - (dd.y + oy) - screen_margin
		local above_space = (dd.control_y + oy) - screen_margin
		local open_above = above_space > below_space and below_space < math.min(fullOptsH, max_list_h)
		local available_space = open_above and above_space or below_space
		local visible_full_h = math.min(fullOptsH, max_list_h, screen_list_h, math.max(min_list_h, available_space))
		visible_full_h = math.max(1, visible_full_h)
		local optsH = math.max(1, math.floor(visible_full_h * open_t))
		local panel_y = dd.y
		if open_above then
			panel_y = dd.control_y - config.space.x1 - optsH
		end
		panel_y = primitives.clamp(panel_y, screen_margin - oy, screen_h - oy - screen_margin - optsH)
		local max_scroll_y = math.max(0, fullOptsH - visible_full_h)
		local dropdown_id = dd.item.id
		state.dropdown_scroll = state.dropdown_scroll or {}
		state.dropdown_scroll_init = state.dropdown_scroll_init or {}
		if not state.dropdown_scroll_init[dropdown_id] then
			local selected_y = math.max(0, ((dd.item.value or 1) - 1) * itemHeight)
			state.dropdown_scroll[dropdown_id] =
				primitives.clamp(selected_y - math.floor((visible_full_h - itemHeight) / 2), 0, max_scroll_y)
			state.dropdown_scroll_init[dropdown_id] = true
		end
		local scroll_y = primitives.clamp(state.dropdown_scroll[dropdown_id] or 0, 0, max_scroll_y)
		state.dropdown_scroll[dropdown_id] = scroll_y
		state.dropdown_scroll_max = max_scroll_y
		local can_interact = dd.interactive and (open_t > 0.95)

		state.render_alpha_mul = open_t
		primitives.render_card(
			panel_x,
			panel_y,
			panel_w,
			optsH,
			config.colors.bg_panel,
			config.colors.border,
			config.radius.md
		)
		gui.push_clip(primitives.vec(panel_x + ox, panel_y + oy), primitives.vec(panel_w, optsH))

		for i, opt in ipairs(dd.item.options) do
			local optY = panel_y + (i - 1) * itemHeight - scroll_y
			local optTextCol = config.colors.text_main
			local visible = optY + itemHeight >= panel_y and optY <= panel_y + optsH
			if visible and can_interact and click_input.is_hovered(panel_x, optY, panel_w, itemHeight) then
				primitives.render_rect(panel_x, optY, panel_w, itemHeight, config.colors.accent, config.radius.none)
				if state.mouse.clicked and not state.dropdown_just_opened then
					dd.item.value = i
					dd.item.isOpen = false
					state.active_dropdown = nil
					state.dropdown_scroll_max = 0
					state.dropdown_scroll_init[dropdown_id] = false
					state.window.is_dragging = false
					if dd.item.onChange then
						common.safe_call_ui_handler("dropdown", dd.item.id, dd.item.onChange, opt)
					end
				end
				optTextCol = config.colors.text_on_accent
			end
			if visible then
				local option_max_w = panel_w - config.space.x6
				if max_scroll_y > 0 then
					option_max_w = option_max_w - config.space.x2
				end
				local option_text = primitives.text_with_ellipsis(opt, option_max_w, config.font_scale_body)
				primitives.render_text_in_rect(
					option_text,
					panel_x + config.space.x3,
					optY,
					option_max_w,
					itemHeight,
					config.font_scale_body,
					optTextCol,
					"left"
				)
			end
		end

		gui.pop_clip()
		if max_scroll_y > 0 then
			local track_w = config.scrollbar.w or config.space.x1
			local track_x = panel_x + panel_w - config.space.x2
			local thumb_h = math.max(config.control.scrollbar_min_thumb, (visible_full_h / fullOptsH) * optsH)
			local thumb_y = panel_y
			if max_scroll_y > 0 then
				thumb_y = panel_y + (scroll_y / max_scroll_y) * (optsH - thumb_h)
			end
			primitives.render_rect(
				track_x,
				thumb_y + config.space.x1,
				track_w,
				math.max(1, thumb_h - config.space.x2),
				config.colors.accent,
				config.radius.full
			)
		end
		state.render_alpha_mul = 1.0

		if
			can_interact
			and state.mouse.clicked
			and not state.dropdown_just_opened
			and not click_input.is_hovered(panel_x, panel_y, panel_w, optsH)
		then
			dd.item.isOpen = false
			state.active_dropdown = nil
			state.dropdown_scroll_max = 0
			state.dropdown_scroll_init[dropdown_id] = false
			state.window.is_dragging = false
		end
	end
	state.dropdown_just_opened = false
end

return dropdown_panel
