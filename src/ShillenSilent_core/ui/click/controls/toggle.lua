local config = require("ShillenSilent_core.ui.click.config")
local state = require("ShillenSilent_core.ui.click.state")
local primitives = require("ShillenSilent_core.ui.click.primitives")
local click_input = require("ShillenSilent_core.ui.click.input")
local common = require("ShillenSilent_core.ui.click.controls.common")

local toggle = {}
local toggle_track_color = { r = 148, g = 163, b = 184, a = 255 }

function toggle.draw(item, x, y, w, original_y)
	local pad_x = config.space.x3
	local hitbox_h = config.item_height.toggle - config.space.x1
	local disabled = item.disabled and true or false
	local hovered = not disabled
		and not state.active_dropdown
		and click_input.is_hovered_content(x, original_y, w, hitbox_h)

	if hovered and state.mouse.clicked and not state.active_dropdown then
		item.state = not item.state
		if item.onChange then
			common.safe_call_ui_handler("toggle", item.id, item.onChange, item.state)
		end
		state.window.is_dragging = false
	end

	local target = item.state and 1.0 or 0.0
	if not item.anim then
		item.anim = target
	end
	item.anim = primitives.lerp(item.anim, target, 0.15)

	local switchW = config.space.x12
	local switchH = config.space.x6
	local switchX = x + w - switchW - pad_x
	local switchY = y + config.space.x3
	local inactiveCol = config.colors.neutral_muted or config.colors.text_dim
	local activeCol = disabled and inactiveCol or config.colors.accent

	toggle_track_color.r = math.floor(inactiveCol.r + (activeCol.r - inactiveCol.r) * item.anim)
	toggle_track_color.g = math.floor(inactiveCol.g + (activeCol.g - inactiveCol.g) * item.anim)
	toggle_track_color.b = math.floor(inactiveCol.b + (activeCol.b - inactiveCol.b) * item.anim)
	toggle_track_color.a = inactiveCol.a or 255

	primitives.render_rect(switchX, switchY, switchW, switchH, toggle_track_color, config.radius.full)
	primitives.render_outline(
		switchX,
		switchY,
		switchW,
		switchH,
		disabled and config.colors.border or config.colors.border_strong,
		config.control.toggle_track_border_thickness,
		config.radius.full
	)

	local thumbPadding = math.max(1, math.floor(config.space.x1 / 2))
	local thumbSize = math.max(2, switchH - (thumbPadding * 2))
	local minX = switchX + thumbPadding
	local maxX = switchX + switchW - thumbSize - thumbPadding
	local thumbX = primitives.lerp(minX, maxX, item.anim)
	local thumbY = switchY + (switchH - thumbSize) / 2

	primitives.render_rect(
		thumbX,
		thumbY,
		thumbSize,
		thumbSize,
		disabled and config.colors.bg_panel or config.colors.white,
		config.radius.full
	)
	primitives.render_outline(
		thumbX,
		thumbY,
		thumbSize,
		thumbSize,
		disabled and config.colors.border or config.colors.accent_hover,
		config.control.toggle_thumb_border_thickness,
		config.radius.full
	)

	local textY = switchY + (switchH - config.font_scale_body) / 2
	primitives.render_text(
		item.label,
		x + pad_x,
		textY,
		config.font_scale_body,
		disabled and config.colors.border or config.colors.text_main
	)
end

return toggle
