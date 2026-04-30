local config = require("ShillenSilent_core.ui.click.config")

local state = {
	fonts = {},
	images = {},
	logo = nil,
	font_load_attempted = false,
	active_dropdown = nil,
	dropdown_just_opened = false,
	dropdown_scroll = {},
	dropdown_scroll_init = {},
	dropdown_scroll_max = 0,
	dragging_slider = nil,
	scroll = { y = 0, max_y = 0, is_dragging = false },
	window = {
		x = config.origin_x,
		y = config.origin_y,
		is_dragging = false,
		is_resizing = false,
		drag_offset = { x = 0, y = 0 },
		resize_start = { x = 0, y = 0, width = config.menu_width, height = config.menu_height },
	},
	animation = { open = false, progress = 0.0, target = 0.0, speed = config.motion.open_speed or 0.15 },
	drawer = { open = false, progress = 0.0, target = 0.0 },
	render_alpha_mul = 1.0,
	content_transition = { subtab = 1, progress = 1.0 },
	active_tab_y = nil,
	mouse = { x = 0, y = 0, down = false, clicked = false },
	heist_subtab = 2,
}

return state
