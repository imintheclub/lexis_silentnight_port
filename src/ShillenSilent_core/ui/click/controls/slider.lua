local config = require("ShillenSilent_core.ui.click.config")
local state = require("ShillenSilent_core.ui.click.state")
local primitives = require("ShillenSilent_core.ui.click.primitives")
local click_input = require("ShillenSilent_core.ui.click.input")
local common = require("ShillenSilent_core.ui.click.controls.common")

local slider = {}
local slider_glow_color = { r = 255, g = 255, b = 255, a = 0 }

function slider.draw(item, x, y, w, original_y)
	local pad_x = config.space.x3
	local barH = math.max(3, config.space.x1 + 1)
	local barY = y + config.space.x8
	local target = (state.dragging_slider == item.id) and 1.0 or 0.0
	if not item.anim then
		item.anim = 0.0
	end
	item.anim = primitives.lerp(item.anim, target, 0.2)

	local baseSize = config.control.slider_thumb_base
	local growSize = config.control.slider_thumb_grow
	local thumbSize = math.floor(baseSize + (growSize * item.anim))
	local thumbInset = thumbSize / 2
	local trackX = x + pad_x + thumbInset
	local trackW = math.max(1, w - (pad_x * 2) - thumbSize)
	local barX = trackX
	local barW = trackW
	local hovered = not state.active_dropdown
		and click_input.is_hovered_content(x, original_y, w, config.item_height.slider)

	if hovered and state.mouse.clicked and not state.active_dropdown then
		state.dragging_slider = item.id
		state.window.is_dragging = false
	end

	if state.dragging_slider == item.id and state.mouse.down then
		local mx = state.mouse.x
		local ox = state._frame_ox
		local relative_mx = mx - ox
		local ratio = math.max(0, math.min(1, (relative_mx - trackX) / trackW))
		local rawValue = item.min + ratio * (item.max - item.min)
		local prev_value = item.value
		local next_value
		if item.step and item.step > 0 then
			next_value = math.floor((rawValue + item.step / 2) / item.step) * item.step
		else
			next_value = rawValue
		end
		if next_value ~= prev_value then
			item.value = next_value
			if item.onChange then
				common.safe_call_ui_handler("slider", item.id, item.onChange, item.value)
			end
		end
	end

	primitives.render_text(item.label, x + pad_x, y + config.space.x1, config.font_scale_body, config.colors.text_main)
	local displayValue = math.floor(item.value)
	primitives.render_text(
		tostring(displayValue),
		x + w - pad_x - thumbInset,
		y + config.space.x1,
		config.font_scale_body,
		config.colors.accent,
		"right"
	)
	primitives.render_rect(barX, barY, barW, barH, config.colors.bg_control, config.radius.full)

	local fillRatio = (item.value - item.min) / (item.max - item.min)
	if fillRatio > 0 then
		primitives.render_rect(barX, barY, barW * fillRatio, barH, config.colors.accent, config.radius.full)
	end

	local thumbX = trackX + (trackW * fillRatio) - thumbInset
	local thumbY = barY - thumbSize / 2 + barH / 2
	if item.anim > 0.01 then
		local glowSize = thumbSize + math.floor(config.space.x2 * item.anim)
		local glowX = thumbX - (glowSize - thumbSize) / 2
		local glowY = thumbY - (glowSize - thumbSize) / 2
		local glowMinX = x + pad_x
		local glowMaxX = x + w - pad_x - glowSize
		if glowMaxX >= glowMinX then
			glowX = math.max(glowMinX, math.min(glowMaxX, glowX))
		end
		slider_glow_color.r = config.colors.accent.r
		slider_glow_color.g = config.colors.accent.g
		slider_glow_color.b = config.colors.accent.b
		slider_glow_color.a = math.floor(90 * item.anim)
		primitives.render_rect(glowX, glowY, glowSize, glowSize, slider_glow_color, glowSize / 2)
	end

	primitives.render_rect(thumbX, thumbY, thumbSize, thumbSize, config.colors.text_on_accent, config.radius.full)
	primitives.render_outline(thumbX, thumbY, thumbSize, thumbSize, config.colors.accent, 1, config.radius.full)
end

return slider
