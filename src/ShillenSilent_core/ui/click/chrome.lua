local i18n = require("ShillenSilent_core.i18n")
local config = require("ShillenSilent_core.ui.click.config")
local state = require("ShillenSilent_core.ui.click.state")
local primitives = require("ShillenSilent_core.ui.click.primitives")
local click_input = require("ShillenSilent_core.ui.click.input")
local drawer = require("ShillenSilent_core.ui.click.drawer")
local header_theme = require("ShillenSilent_core.ui.click.header_theme")

local chrome = {}

function chrome.resize_hovered(bodyY, bodyH)
	local resize_hit_w = config.resize.edge_hit_w
	local resize_hit_h = config.resize.edge_hit_h or config.space.x6
	local resize_hit_x = config.origin_x + config.menu_width - resize_hit_w
	local resize_hit_y = bodyY + bodyH - resize_hit_h
	return not state.active_dropdown
		and click_input.is_hovered(
			resize_hit_x - config.space.x1,
			resize_hit_y - config.space.x1,
			resize_hit_w + config.space.x2,
			resize_hit_h + config.space.x2
		)
end

function chrome.update_window_interaction(resize_hovered, dynamicBodyH)
	if state.mouse.clicked and not state.active_dropdown and not state.dragging_slider then
		local menuStartY = config.origin_y
		if resize_hovered then
			state.window.is_resizing = true
			state.window.is_dragging = false
			state.window.resize_start.x = state.mouse.x
			state.window.resize_start.y = state.mouse.y
			state.window.resize_start.width = config.menu_width
			state.window.resize_start.height = config.menu_height
		elseif click_input.is_hovered(config.origin_x, menuStartY, config.menu_width, dynamicBodyH) then
			state.window.is_dragging = true
			state.window.drag_offset.x = state.mouse.x - state.window.x
			state.window.drag_offset.y = state.mouse.y - state.window.y
		end
	end

	if state.dragging_slider then
		state.window.is_dragging = false
		state.window.is_resizing = false
	end

	if state.window.is_resizing and state.mouse.down and not state.dragging_slider then
		local delta_x = state.mouse.x - state.window.resize_start.x
		local delta_y = state.mouse.y - state.window.resize_start.y
		local next_w = state.window.resize_start.width + delta_x
		local next_h = state.window.resize_start.height + delta_y
		local max_w_screen = math.floor(game.resolution().x - config.resize.max_screen_margin)
		local max_w_cfg = config.resize.max_menu_width or max_w_screen
		local max_w = math.min(max_w_cfg, max_w_screen)
		if max_w < config.resize.min_menu_width then
			max_w = config.resize.min_menu_width
		end
		local max_h_screen = math.floor(game.resolution().y - config.resize.max_screen_margin)
		local max_h_cfg = config.resize.max_menu_height or max_h_screen
		local max_h = math.min(max_h_cfg, max_h_screen)
		if max_h < config.resize.min_menu_height then
			max_h = config.resize.min_menu_height
		end
		config.menu_width = math.max(config.resize.min_menu_width, math.min(max_w, next_w))
		config.menu_height = math.max(config.resize.min_menu_height, math.min(max_h, next_h))
	elseif state.window.is_dragging and state.mouse.down and not state.dragging_slider then
		state.window.x = state.mouse.x - state.window.drag_offset.x
		state.window.y = state.mouse.y - state.window.drag_offset.y
	end
end

function chrome.update_content_area(bodyY, bodyH, header_h)
	config.content_area.x = config.origin_x
	config.content_area.y = bodyY
	config.content_area.w = config.menu_width
	config.content_area.h = bodyH
	config.scrollbar.x = config.origin_x + config.menu_width - config.space.x2
	config.scrollbar.y = config.content_area.y + header_h
	config.scrollbar.h = config.content_area.h - header_h - config.content_margin
end

local function render_header_title(header_h, hamburger_x, hamburger_size, right_edge)
	local title = drawer.name(state.heist_subtab)
	if not title or title == "" then
		return
	end
	local title_left = hamburger_x + hamburger_size + config.space.x4
	local title_right = right_edge - config.space.x4
	local title_w = title_right - title_left
	if title_w <= config.space.x8 then
		return
	end
	local title_scale = config.font_scale_header or config.font_scale_body
	local title_text = primitives.text_with_ellipsis(title, title_w, title_scale)
	local title_x = title_left + math.floor(title_w / 2)
	local title_y = primitives.centered_text_y(config.origin_y, header_h, title_text, title_scale)
	primitives.render_text(title_text, title_x, title_y, title_scale, config.colors.text_main, "center")
end

function chrome.render_header(header_h, body_h, hamburger_x, hamburger_size)
	local version_label = i18n.t("app.version")
	local wm_x = config.origin_x + config.menu_width - config.content_margin
	local wm_scale = config.font_scale_small or 1.0
	local wm_y = primitives.centered_text_y(config.origin_y, header_h, version_label, wm_scale)
	local wm_col = config.colors.text_main
	primitives.render_text(version_label, wm_x, wm_y, wm_scale, wm_col, "right")

	local theme_w = math.max(config.space.x15 * 3, math.floor(config.menu_width * 0.18))
	local theme_h = math.max(config.space.x7, header_h - (config.space.x2 * 2))
	local version_w = primitives.measure_text_width(version_label, wm_scale) or 0
	local theme_x = wm_x - version_w - ((config.space.x10 * 2) + config.space.x5) - theme_w
	local theme_y = config.origin_y + math.floor((header_h - theme_h) / 2)
	local min_x = config.origin_x + config.content_margin + config.space.x8
	local header_dropdown = nil
	if theme_x >= min_x and theme_w > 0 and theme_h > 0 then
		header_dropdown = header_theme.draw(theme_x, theme_y, theme_w, theme_h)
	end
	if hamburger_x and hamburger_size then
		render_header_title(header_h, hamburger_x, hamburger_size, theme_x)
	end

	local credits_x = config.origin_x + config.space.x2
	local credits_y = config.origin_y + body_h - (config.space.x2 * 2)
	primitives.render_text(i18n.t("app.credits"), credits_x, credits_y, wm_scale, wm_col, "left")
	return header_dropdown
end

function chrome.render_shell(bodyY, bodyH, header_h, hamburger_x, hamburger_size)
	primitives.render_card(
		config.origin_x,
		bodyY,
		config.menu_width,
		bodyH,
		config.colors.bg_main,
		config.colors.border_strong,
		config.radius.xl
	)
	primitives.render_background_tile(config.origin_x, bodyY, config.menu_width, bodyH)
	local header_dropdown = chrome.render_header(header_h, bodyH, hamburger_x, hamburger_size)

	local grip_color = config.colors.accent
	local grip_right = config.origin_x + config.menu_width - config.space.x1
	local grip_bottom = bodyY + bodyH - config.space.x1
	primitives.render_rect(
		grip_right - config.space.x7,
		grip_bottom - config.space.x1,
		config.space.x5,
		config.space.x1,
		grip_color,
		config.radius.full
	)
	primitives.render_rect(
		grip_right - config.space.x5,
		grip_bottom - config.space.x3,
		config.space.x4,
		config.space.x1,
		grip_color,
		config.radius.full
	)
	primitives.render_rect(
		grip_right - config.space.x3,
		grip_bottom - config.space.x5,
		config.space.x3,
		config.space.x1,
		grip_color,
		config.radius.full
	)

	return header_dropdown
end

return chrome
