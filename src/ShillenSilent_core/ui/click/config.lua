local paths = require("ShillenSilent_core.core.paths")
local theme = require("ShillenSilent_core.ui.click.theme")

local BASE_WIDTH = 1920
local BASE_HEIGHT = 1080

local function get_screen_scale()
	local res = game.resolution()
	local scale_x = res.x / BASE_WIDTH
	local scale_y = res.y / BASE_HEIGHT
	return math.min(scale_x, scale_y)
end

local function init_config()
	local scale = get_screen_scale()
	local function s(px)
		return math.max(1, math.floor(px * scale))
	end
	local function tw(units)
		return s(units * 4)
	end

	local design_menu_width = tw(356)
	local menu_height = tw(150)
	local content_margin = tw(6)
	local header_height = tw(12)
	local column_gap = tw(4)
	local default_content_w = design_menu_width - (content_margin * 2)
	local full_column_w = math.floor((default_content_w - (2 * column_gap)) / 3)
	local group_card_width_scale = 0.7
	local fixed_column_w = math.floor(full_column_w * group_card_width_scale)
	local menu_width = (content_margin * 2) + (fixed_column_w * 3) + (column_gap * 2)
	local min_w_from_one_card = (content_margin * 2) + fixed_column_w

	return {
		font_path = paths.fonts_dir .. "\\NotoSansSC-SemiBold.ttf",
		font_load_scale = 16.0,
		background_tile_path = paths.img_dir
			.. "\\43d8dab59abbbb877fd374f24b34a459880815bd195696b01e0301de7c079a79.png",
		background_tile_alpha = 255,

		font_scale_title = 24.0 * scale,
		font_scale_header = 18.0 * scale,
		font_scale_body = 16.0 * scale,
		font_scale_small = 14.0 * scale,

		origin_x = math.floor((game.resolution().x - menu_width) / 2),
		origin_y = math.floor((game.resolution().y - menu_height) / 2),
		menu_width = menu_width,
		menu_height = menu_height,

		sidebar_width = 0,
		sidebar_gap = 0,

		content_margin = content_margin,
		header_height = header_height,

		layout = {
			fixed_column_w = fixed_column_w,
			group_card_width_scale = group_card_width_scale,
			column_gap = column_gap,
			max_columns = 3,
		},

		resize = {
			edge_hit_w = tw(3),
			edge_hit_h = tw(6),
			min_menu_width = min_w_from_one_card,
			max_menu_width = menu_width,
			min_menu_height = menu_height,
			max_menu_height = menu_height * 2,
			max_screen_margin = tw(10),
		},

		content_area = {
			x = 0,
			y = 0,
			w = 0,
			h = 0,
		},

		item_height = {
			toggle = tw(12),
			button = tw(12),
			slider = tw(15),
			dropdown = tw(12),
			header_padding = tw(10),
		},
		item_gap = tw(2),

		space = {
			x1 = tw(1),
			x1_5 = tw(1.5),
			x2 = tw(2),
			x2_5 = tw(2.5),
			x3 = tw(3),
			x3_5 = tw(3.5),
			x4 = tw(4),
			x5 = tw(5),
			x6 = tw(6),
			x7 = tw(7),
			x8 = tw(8),
			x9 = tw(9),
			x10 = tw(10),
			x11 = tw(11),
			x12 = tw(12),
			x15 = tw(15),
		},

		radius = {
			none = 0,
			sm = s(2),
			md = s(3),
			lg = s(5),
			xl = s(8),
			full = s(999),
		},

		control = {
			slider_thumb_base = tw(4),
			slider_thumb_grow = tw(2),
			scrollbar_min_thumb = tw(8),
			scrollbar_grab_pad = tw(1),
			dropdown_max_visible_items = 10,
			dropdown_min_visible_items = 3,
			toggle_track_border_thickness = s(2),
			toggle_thumb_border_thickness = s(1.25),
		},

		drawer = {
			width = tw(72),
			item_h = tw(7),
			button_size = tw(6),
			overlay_alpha = 90,
			line_thickness = s(2),
		},

		motion = {
			reduced_motion = false,
			open_y_offset = tw(7.5),
			speed_fast = 0.24,
			speed_base = 0.16,
			speed_slow = 0.11,
			open_speed = 0.15,
			subtab_switch_speed = 0.18,
			subtab_switch_slide = tw(3),
			subtab_active_speed = 0.2,
			drawer_speed = 0.2,
			group_move_speed = 0.2,
			dropdown_speed = 0.22,
		},

		scale = scale,
		theme_mode = theme.default_mode(),
		colors = theme.default_palette(),
	}
end

local config = init_config()

local body_offset = config.sidebar_gap
config.content_area.x = config.origin_x + config.sidebar_width + config.sidebar_gap
config.content_area.y = config.origin_y + body_offset
config.content_area.w = config.menu_width - config.sidebar_width - config.sidebar_gap
config.content_area.h = config.menu_height - body_offset
config.scrollbar = {
	x = config.origin_x + config.menu_width - config.space.x2,
	y = config.content_area.y + config.header_height,
	w = config.space.x1,
	h = config.content_area.h - config.header_height - config.content_margin,
}

theme.apply_theme(config, theme.read_theme_mode())

return config
