local i18n = require("ShillenSilent_core.i18n")
local config = require("ShillenSilent_core.ui.click.config")
local state = require("ShillenSilent_core.ui.click.state")
local animator = require("ShillenSilent_core.ui.click.animator")
local primitives = require("ShillenSilent_core.ui.click.primitives")
local click_input = require("ShillenSilent_core.ui.click.input")
local info_actions = require("ShillenSilent_core.features.heists.info.actions")
local info_data = require("ShillenSilent_core.features.heists.info.data")

local header_theme = {}

local function build_item()
	local themes = info_data.localized_options(info_data.theme_modes, i18n.t)
	return {
		type = "dropdown",
		id = "header_theme_mode",
		options = info_data.option_names(themes),
		value = info_data.option_index_by_value(info_data.theme_modes, config.theme_mode, 1),
		onChange = function(opt)
			local target_id = info_data.option_value_by_name(themes, opt, config.theme_mode)
			info_actions.set_theme_mode(target_id)
		end,
	}
end

function header_theme.draw(x, y, w, h)
	local item = build_item()
	local is_active_dropdown = (state.active_dropdown == item.id)
	local allow_hover = (not state.active_dropdown) or is_active_dropdown
	local hovered = allow_hover and click_input.is_hovered(x, y, w, h)

	if hovered and state.mouse.clicked then
		state.window.is_dragging = false
		state.window.is_resizing = false
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

	local box_active = hovered or (open_t > 0.01)
	local boxBg = box_active and config.colors.accent or config.colors.bg_control
	local boxBorder = box_active and config.colors.accent_hover or config.colors.border
	local boxText = box_active and config.colors.text_on_accent or config.colors.text_sec
	local boxArrow = box_active and config.colors.text_on_accent or config.colors.text_dim
	local shadow_t = animator.to(
		"dropdown_shadow:" .. tostring(item.id),
		box_active and 1.0 or 0.0,
		animator.motion_speed(config.motion.speed_fast, 0.24)
	)

	primitives.render_depth_shadow(x, y, w, h, config.radius.md, 0.5 + (0.2 * shadow_t), shadow_t)
	primitives.render_rect(x, y, w, h, boxBg, config.radius.md)
	primitives.render_outline(x, y, w, h, boxBorder, 1, config.radius.md)

	local selected = item.options[item.value] or ""
	local selected_max_w = w - config.space.x9
	local selected_text = primitives.text_with_ellipsis(selected, selected_max_w, config.font_scale_small)
	local sel_y = primitives.centered_text_y(y, h, selected_text, config.font_scale_small)
	primitives.render_text(selected_text, x + config.space.x2, sel_y, config.font_scale_small, boxText)

	local arrowFrames = { "v", ">", "^" }
	local arrowIdx = 1 + math.floor((open_t or 0.0) * (#arrowFrames - 1) + 0.5)
	arrowIdx = primitives.clamp(arrowIdx, 1, #arrowFrames)
	local arrow_glyph = arrowFrames[arrowIdx]
	local arrow_y = primitives.centered_text_y(y, h, arrow_glyph, config.font_scale_small)
	primitives.render_text(arrow_glyph, x + w - config.space.x3, arrow_y, config.font_scale_small, boxArrow)

	if open_t > 0.01 then
		return {
			item = item,
			x = x,
			y = y + h + config.space.x1,
			w = w,
			control_y = y,
			control_h = h,
			open_t = open_t,
			interactive = (target_open > 0.5) and (open_t > 0.95),
		}
	end
end

return header_theme
