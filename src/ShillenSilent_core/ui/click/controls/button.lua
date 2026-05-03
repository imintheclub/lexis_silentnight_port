local notify_core = require("ShillenSilent_core.core.notify")
local config = require("ShillenSilent_core.ui.click.config")
local state = require("ShillenSilent_core.ui.click.state")
local animator = require("ShillenSilent_core.ui.click.animator")
local primitives = require("ShillenSilent_core.ui.click.primitives")
local click_input = require("ShillenSilent_core.ui.click.input")
local common = require("ShillenSilent_core.ui.click.controls.common")

local button = {}

function button.is_hovered(btnX, btnY, btnW, btnH)
	if state.active_dropdown then
		return false
	end
	if click_input.is_hovered_content(btnX, btnY, btnW, btnH) then
		return true
	end
	local ox, oy = state._frame_ox, state._frame_oy
	return input.is_mouse_within(primitives.vec(btnX + ox, btnY + oy), primitives.vec(btnW, btnH))
end

function button.draw_surface(btn, btnX, btnY, btnW, btnH, disabled_message)
	local hovered = button.is_hovered(btnX, btnY, btnW, btnH)
	local shadow_t = animator.to(
		"button_shadow:" .. tostring(btn.id or btn.label or ""),
		hovered and 1.0 or 0.0,
		animator.motion_speed(config.motion.speed_fast, 0.24)
	)
	primitives.render_depth_shadow(btnX, btnY, btnW, btnH, config.radius.md, 0.65 + (0.25 * shadow_t), shadow_t)

	if hovered and state.mouse.clicked and not state.active_dropdown then
		if btn.disabled then
			if disabled_message then
				notify_core.push("notify.error_title", disabled_message, 3000)
			end
		elseif btn.onClick then
			common.safe_call_ui_handler("button", btn.id, btn.onClick)
		end
		state.window.is_dragging = false
	end

	local style = common.button_colors_for(btn, hovered)
	primitives.render_rect(btnX, btnY, btnW, btnH, style.bg, config.radius.md)
	if style.border.a and style.border.a > 0 then
		primitives.render_outline(btnX, btnY, btnW, btnH, style.border, 1, config.radius.md)
	end
	primitives.render_rect(btnX + 1, btnY + 1, math.max(1, btnW - 2), 1, {
		r = (config.colors.chrome_highlight_soft or config.colors.text_on_accent).r,
		g = (config.colors.chrome_highlight_soft or config.colors.text_on_accent).g,
		b = (config.colors.chrome_highlight_soft or config.colors.text_on_accent).b,
		a = hovered and 16 or 8,
	}, config.radius.full)

	return style
end

local BUTTON_LABEL_SCALE = 1.0

function button.render_label(label, btnX, btnY, btnW, btnH, textColor)
	local pad_x = config.space.x3
	local draw_size = config.font_scale_small * BUTTON_LABEL_SCALE
	local max_w = math.max(1, btnW - (pad_x * 2))
	local text = tostring(label or "")
	local text_h = primitives.measure_wrapped_text_height(text, max_w, draw_size)
	local text_y = btnY + math.floor((btnH - text_h) / 2)
	local text_x = btnX + (btnW / 2)

	if gui.push_clip and gui.pop_clip then
		local ox, oy = state._frame_ox, state._frame_oy
		gui.push_clip(primitives.vec(btnX + ox, btnY + oy), primitives.vec(btnW, btnH))
		primitives.render_wrapped_text(text, text_x, text_y, max_w, draw_size, textColor, "center")
		gui.pop_clip()
	else
		primitives.render_wrapped_text(text, text_x, text_y, max_w, draw_size, textColor, "center")
	end
end

function button.draw_item(item, x, y, w)
	local pad_x = config.space.x3
	local btnW = w - (pad_x * 2)
	local btnX = x + pad_x
	local btnY = y + config.space.x1
	local n = primitives.button_line_count(item.label, btnW)
	local btnH = primitives.button_h_from_lines(n) - config.space.x1
	local style = button.draw_surface(item, btnX, btnY, btnW, btnH, "ui.disabled.instant_finish")
	button.render_label(item.label, btnX, btnY, btnW, btnH, style.text)
end

function button.draw_pair_item(item, x, y, w)
	local pad_x = config.space.x3
	local baseX = x + pad_x
	local btnY = y + config.space.x1
	local leftW, rightW = primitives.button_pair_half_widths(w)
	local nl = primitives.button_line_count(item.left and item.left.label, leftW)
	local nr = primitives.button_line_count(item.right and item.right.label, rightW)
	local btnH = primitives.button_h_from_lines(math.max(nl, nr)) - config.space.x1
	local gap = config.space.x2_5

	local function draw_half(btn, btnX, btnW)
		local style = button.draw_surface(btn, btnX, btnY, btnW, btnH, "ui.disabled.action")
		button.render_label(btn.label, btnX, btnY, btnW, btnH, style.text)
	end

	draw_half(item.left, baseX, leftW)
	draw_half(item.right, baseX + leftW + gap, rightW)
end

return button
