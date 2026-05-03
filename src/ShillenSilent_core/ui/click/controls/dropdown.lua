local config = require("ShillenSilent_core.ui.click.config")
local state = require("ShillenSilent_core.ui.click.state")
local animator = require("ShillenSilent_core.ui.click.animator")
local primitives = require("ShillenSilent_core.ui.click.primitives")
local click_input = require("ShillenSilent_core.ui.click.input")
local layout_engine = require("ShillenSilent_core.ui.click.layout_engine")

local dropdown = {}

function dropdown.draw(item, x, y, w, original_y)
	local pad_x = config.space.x3
	local available_w = math.max(1, w - (pad_x * 2))
	local boxW = available_w
	local boxH = config.space.x9
	local boxX = x + pad_x
	local label_h = layout_engine.dropdown_label_height(item, w)
	local boxY = y + config.space.x1 + label_h + layout_engine.dropdown_label_gap()
	local is_active_dropdown = (state.active_dropdown == item.id)
	local allow_hover = (not state.active_dropdown) or is_active_dropdown
	local hovered = allow_hover
		and click_input.is_hovered_content(x, original_y, w, layout_engine.get_dropdown_item_height(item, w))

	if hovered and state.mouse.clicked then
		state.window.is_dragging = false
		if is_active_dropdown then
			item.isOpen = false
			state.active_dropdown = nil
			state.dropdown_scroll_max = 0
		elseif not state.active_dropdown then
			item.isOpen = true
			state.active_dropdown = item.id
			state.dropdown_just_opened = true
			state.dropdown_scroll = state.dropdown_scroll or {}
			state.dropdown_scroll_init = state.dropdown_scroll_init or {}
			state.dropdown_scroll[item.id] = nil
			state.dropdown_scroll_init[item.id] = false
		end
	end

	local target_open = (state.active_dropdown == item.id) and 1.0 or 0.0
	local open_t = animator.to(
		"dropdown_open:" .. tostring(item.id),
		target_open,
		animator.motion_speed(config.motion.dropdown_speed, config.motion.speed_fast or 0.24)
	)
	if target_open > 0.5 then
		item.isOpen = true
	elseif open_t < 0.01 then
		item.isOpen = false
	end

	primitives.render_wrapped_text(
		layout_engine.dropdown_label_text(item),
		x + pad_x,
		y + config.space.x1,
		available_w,
		config.font_scale_body,
		config.colors.text_main
	)

	local box_active = hovered or (open_t > 0.01)
	local boxBg = box_active and config.colors.accent or config.colors.bg_control
	local boxBorder = box_active and config.colors.accent_hover or config.colors.border
	local boxText = box_active and config.colors.text_on_accent or config.colors.text_sec
	local boxArrow = box_active and config.colors.text_on_accent or config.colors.text_dim
	local shadow_t = animator.to(
		"dropdown_shadow:" .. tostring(item.id or item.label or ""),
		box_active and 1.0 or 0.0,
		animator.motion_speed(config.motion.speed_fast, 0.24)
	)
	primitives.render_depth_shadow(boxX, boxY, boxW, boxH, config.radius.md, 0.55 + (0.25 * shadow_t), shadow_t)
	primitives.render_rect(boxX, boxY, boxW, boxH, boxBg, config.radius.md)
	primitives.render_outline(boxX, boxY, boxW, boxH, boxBorder, 1, config.radius.md)

	local selected = item.options[item.value] or ""
	local selected_max_w = boxW - config.space.x9
	local selected_text = primitives.text_with_ellipsis(selected, selected_max_w, config.font_scale_body)
	local sel_y = primitives.centered_text_y(boxY, boxH, selected_text, config.font_scale_body)
	primitives.render_text(selected_text, boxX + config.space.x3, sel_y, config.font_scale_body, boxText)

	local arrowFrames = { "v", ">", "^" }
	local arrowIdx = 1 + math.floor((open_t or 0.0) * (#arrowFrames - 1) + 0.5)
	arrowIdx = primitives.clamp(arrowIdx, 1, #arrowFrames)
	local arrow_glyph = arrowFrames[arrowIdx]
	local arrow_y = primitives.centered_text_y(boxY, boxH, arrow_glyph, config.font_scale_small)
	primitives.render_text(arrow_glyph, boxX + boxW - config.space.x4, arrow_y, config.font_scale_small, boxArrow)

	if open_t > 0.01 then
		return {
			item = item,
			x = boxX,
			y = boxY + boxH + config.space.x1,
			w = boxW,
			control_y = boxY,
			control_h = boxH,
			open_t = open_t,
			interactive = (target_open > 0.5) and (open_t > 0.95),
		}
	end
end

return dropdown
