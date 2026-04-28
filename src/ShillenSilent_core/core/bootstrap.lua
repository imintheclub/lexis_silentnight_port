-- Core bootstrap: shared config, paths, runtime state, and guarded jobs.

local ui = {}
local native = require("natives")

local function get_path(path)
	local base = paths.script
	local drive, rest = base:match("^([A-Z]:)(.*)")
	if drive then
		base = drive:lower() .. rest
	end
	return base .. path
end

local SHILLENSILENT_CORE_DIR = get_path("\\ShillenSilent_core")
local SHILLENSILENT_CORE_FONTS_DIR = SHILLENSILENT_CORE_DIR .. "\\fonts"
local SHILLENSILENT_HEIST_PRESETS_DIR = get_path("\\ShillenSilent_HeistPresets")
local SHILLENSILENT_THEME_MODE_PATH = SHILLENSILENT_CORE_DIR .. "\\theme_mode.txt"

local DEFAULT_THEME_MODE = "dark"
local VALID_THEME_MODES = {
	dark = true,
	light = true,
	dracula = true,
	solarized_dark = true,
	solarized_light = true,
	monokai = true,
	one_dark = true,
	gruvbox = true,
	nord = true,
	material = true,
	tokyo_night = true,
	night_owl = true,
}

local SLATE = {
	[50] = { 248, 250, 252 },
	[100] = { 241, 245, 249 },
	[200] = { 226, 232, 240 },
	[300] = { 203, 213, 225 },
	[400] = { 148, 163, 184 },
	[500] = { 100, 116, 139 },
	[600] = { 71, 85, 105 },
	[700] = { 51, 65, 85 },
	[800] = { 30, 41, 59 },
	[900] = { 15, 23, 42 },
	[950] = { 2, 6, 23 },
}

local function ensure_core_dirs()
	if not dirs.exists(SHILLENSILENT_CORE_DIR) then
		dirs.create(SHILLENSILENT_CORE_DIR)
	end
	if not dirs.exists(SHILLENSILENT_CORE_FONTS_DIR) then
		dirs.create(SHILLENSILENT_CORE_FONTS_DIR)
	end
	if not dirs.exists(SHILLENSILENT_HEIST_PRESETS_DIR) then
		dirs.create(SHILLENSILENT_HEIST_PRESETS_DIR)
	end
end

local function normalize_theme_mode(mode)
	if type(mode) ~= "string" then
		return nil
	end
	local normalized = mode:lower():gsub("^%s+", ""):gsub("%s+$", "")
	if VALID_THEME_MODES[normalized] then
		return normalized
	end
	return nil
end

local function slate(level, alpha)
	local rgb = SLATE[level]
	if not rgb then
		return { r = 255, g = 255, b = 255, a = alpha or 255 }
	end
	return {
		r = rgb[1],
		g = rgb[2],
		b = rgb[3],
		a = alpha or 255,
	}
end

local function build_light_palette()
	return {
		bg_main = slate(50),
		bg_panel = slate(50),
		bg_control = slate(100),
		bg_control_hover = slate(200),
		bg_ghost_hover = slate(200),

		accent = slate(900),
		accent_hover = slate(950),

		text_main = slate(900),
		text_sec = slate(700),
		text_dim = slate(500, 240),
		text_on_accent = slate(50),

		white = slate(50),
		border = slate(200),
		border_strong = slate(300),
		scroll_track = slate(200, 220),
		card_shadow = slate(950, 0),
		transparent = slate(50, 0),

		neutral_muted = slate(400),
		chrome_shadow_soft = slate(950),
		chrome_highlight_soft = slate(50),

		danger = { r = 220, g = 38, b = 38, a = 255 }, -- red-600
		danger_hover = { r = 185, g = 28, b = 28, a = 255 }, -- red-700
		danger_soft = { r = 254, g = 242, b = 242, a = 255 }, -- red-50
		danger_text = { r = 153, g = 27, b = 27, a = 255 }, -- red-800
		success = { r = 5, g = 150, b = 105, a = 255 }, -- emerald-600
		success_hover = { r = 4, g = 120, b = 87, a = 255 }, -- emerald-700
	}
end

local function build_dark_palette()
	return {
		bg_main = slate(950),
		bg_panel = slate(900),
		bg_control = slate(800),
		bg_control_hover = slate(700),
		bg_ghost_hover = slate(800),

		accent = slate(100),
		accent_hover = slate(200),

		text_main = slate(50),
		text_sec = slate(200),
		text_dim = slate(400, 240),
		text_on_accent = slate(900),

		white = slate(50),
		border = slate(700),
		border_strong = slate(600),
		scroll_track = slate(700, 220),
		card_shadow = slate(950, 120),
		transparent = slate(900, 0),

		neutral_muted = slate(600),
		chrome_shadow_soft = slate(950),
		chrome_highlight_soft = slate(100),

		danger = { r = 220, g = 38, b = 38, a = 255 }, -- red-600
		danger_hover = { r = 185, g = 28, b = 28, a = 255 }, -- red-700
		danger_soft = { r = 254, g = 242, b = 242, a = 255 }, -- red-50
		danger_text = { r = 153, g = 27, b = 27, a = 255 }, -- red-800
		success = { r = 5, g = 150, b = 105, a = 255 }, -- emerald-600
		success_hover = { r = 4, g = 120, b = 87, a = 255 }, -- emerald-700
	}
end

local function hex(h, alpha)
	if type(h) ~= "string" then
		return { r = 255, g = 255, b = 255, a = alpha or 255 }
	end
	local s = h:gsub("^#", "")
	return {
		r = tonumber(s:sub(1, 2), 16) or 0,
		g = tonumber(s:sub(3, 4), 16) or 0,
		b = tonumber(s:sub(5, 6), 16) or 0,
		a = alpha or 255,
	}
end

-- Primitives for syntax-highlighting-inspired themes. Each table provides a
-- minimal set of source colors; build_palette_from_primitives expands them
-- into the full 25-key palette structure.
local THEME_PRIMITIVES = {
	dracula = {
		bg = "#282A36",
		panel = "#21222C",
		control = "#44475A",
		control_hover = "#5A5E78",
		border = "#44475A",
		border_strong = "#6272A4",
		accent = "#BD93F9",
		accent_hover = "#A77AF0",
		fg = "#F8F8F2",
		fg_sec = "#E0E0DC",
		comment = "#6272A4",
		danger = "#FF5555",
		danger_hover = "#E04545",
		success = "#50FA7B",
		success_hover = "#3FE068",
	},
	solarized_dark = {
		bg = "#002B36",
		panel = "#073642",
		control = "#073642",
		control_hover = "#586E75",
		border = "#073642",
		border_strong = "#586E75",
		accent = "#268BD2",
		accent_hover = "#1A6FA8",
		fg = "#FDF6E3",
		fg_sec = "#93A1A1",
		comment = "#586E75",
		danger = "#DC322F",
		danger_hover = "#B82826",
		success = "#859900",
		success_hover = "#6B7B00",
	},
	solarized_light = {
		is_light = true,
		bg = "#FDF6E3",
		panel = "#EEE8D5",
		control = "#EEE8D5",
		control_hover = "#93A1A1",
		border = "#EEE8D5",
		border_strong = "#93A1A1",
		accent = "#268BD2",
		accent_hover = "#1A6FA8",
		fg = "#586E75",
		fg_sec = "#657B83",
		comment = "#93A1A1",
		text_on_accent = "#FDF6E3",
		danger = "#DC322F",
		danger_hover = "#B82826",
		success = "#859900",
		success_hover = "#6B7B00",
	},
	monokai = {
		bg = "#272822",
		panel = "#1F1F1A",
		control = "#3E3D32",
		control_hover = "#5A5A48",
		border = "#3E3D32",
		border_strong = "#75715E",
		accent = "#F92672",
		accent_hover = "#D81C5F",
		fg = "#F8F8F2",
		fg_sec = "#CCCCCC",
		comment = "#75715E",
		danger = "#F92672",
		danger_hover = "#D81C5F",
		success = "#A6E22E",
		success_hover = "#8BBF26",
	},
	one_dark = {
		bg = "#282C34",
		panel = "#21252B",
		control = "#3E4451",
		control_hover = "#4F5666",
		border = "#3E4451",
		border_strong = "#5C6370",
		accent = "#61AFEF",
		accent_hover = "#4F95D0",
		fg = "#ABB2BF",
		fg_sec = "#9DA5B4",
		comment = "#5C6370",
		danger = "#E06C75",
		danger_hover = "#C7515B",
		success = "#98C379",
		success_hover = "#7DAB5E",
	},
	gruvbox = {
		bg = "#282828",
		panel = "#1D2021",
		control = "#3C3836",
		control_hover = "#504945",
		border = "#3C3836",
		border_strong = "#665C54",
		accent = "#FE8019",
		accent_hover = "#D65D0E",
		fg = "#EBDBB2",
		fg_sec = "#D5C4A1",
		comment = "#928374",
		danger = "#FB4934",
		danger_hover = "#CC241D",
		success = "#B8BB26",
		success_hover = "#98971A",
	},
	nord = {
		bg = "#2E3440",
		panel = "#3B4252",
		control = "#434C5E",
		control_hover = "#4C566A",
		border = "#434C5E",
		border_strong = "#4C566A",
		accent = "#88C0D0",
		accent_hover = "#5E81AC",
		fg = "#ECEFF4",
		fg_sec = "#D8DEE9",
		comment = "#4C566A",
		danger = "#BF616A",
		danger_hover = "#A14953",
		success = "#A3BE8C",
		success_hover = "#8AA572",
	},
	material = {
		bg = "#263238",
		panel = "#1E272C",
		control = "#314549",
		control_hover = "#3E5359",
		border = "#314549",
		border_strong = "#546E7A",
		accent = "#82AAFF",
		accent_hover = "#5C8AE6",
		fg = "#EEFFFF",
		fg_sec = "#B2CCD6",
		comment = "#546E7A",
		danger = "#F07178",
		danger_hover = "#D45A60",
		success = "#C3E88D",
		success_hover = "#A6CC72",
	},
	tokyo_night = {
		bg = "#1A1B26",
		panel = "#1F2335",
		control = "#283457",
		control_hover = "#3B4261",
		border = "#3B4261",
		border_strong = "#565F89",
		accent = "#7AA2F7",
		accent_hover = "#5E85DB",
		fg = "#C0CAF5",
		fg_sec = "#A9B1D6",
		comment = "#565F89",
		danger = "#F7768E",
		danger_hover = "#DB6079",
		success = "#9ECE6A",
		success_hover = "#82B254",
	},
	night_owl = {
		bg = "#011627",
		panel = "#001019",
		control = "#0E293F",
		control_hover = "#1D3B53",
		border = "#1D3B53",
		border_strong = "#5F7E97",
		accent = "#82AAFF",
		accent_hover = "#5C8AE6",
		fg = "#D6DEEB",
		fg_sec = "#C5D1E2",
		comment = "#637777",
		danger = "#EF5350",
		danger_hover = "#D03A3A",
		success = "#22DA6E",
		success_hover = "#1AB95C",
	},
}

local function build_palette_from_primitives(p)
	local is_light = p.is_light == true
	return {
		bg_main = hex(p.bg),
		bg_panel = hex(p.panel or p.bg),
		bg_control = hex(p.control),
		bg_control_hover = hex(p.control_hover or p.control),
		bg_ghost_hover = hex(p.control),

		accent = hex(p.accent),
		accent_hover = hex(p.accent_hover or p.accent),

		text_main = hex(p.fg),
		text_sec = hex(p.fg_sec or p.fg),
		text_dim = hex(p.comment, 240),
		text_on_accent = hex(p.text_on_accent or p.bg),

		white = hex(p.fg),
		border = hex(p.border or p.control),
		border_strong = hex(p.border_strong or p.comment),
		scroll_track = hex(p.control, 220),
		card_shadow = hex("#000000", is_light and 30 or 120),
		transparent = hex(p.bg, 0),

		neutral_muted = hex(p.comment),
		chrome_shadow_soft = hex("#000000"),
		chrome_highlight_soft = hex(p.fg),

		danger = hex(p.danger or "#DC2626"),
		danger_hover = hex(p.danger_hover or "#B91C1C"),
		danger_soft = hex(p.danger_soft or (is_light and "#FEF2F2" or "#3A1F22")),
		danger_text = hex(p.danger_text or p.danger or "#FCA5A5"),
		success = hex(p.success or "#059669"),
		success_hover = hex(p.success_hover or "#047857"),
	}
end

local THEME_BUILDERS = {
	dark = build_dark_palette,
	light = build_light_palette,
}

for name, primitives in pairs(THEME_PRIMITIVES) do
	THEME_BUILDERS[name] = function()
		return build_palette_from_primitives(primitives)
	end
end

local function read_theme_mode()
	local ok, result = pcall(function()
		local handle = file.open(SHILLENSILENT_THEME_MODE_PATH, { append = false, create_if_not_exists = false })
		if not handle or not handle.valid then
			return nil
		end
		return handle.text
	end)

	if not ok then
		return DEFAULT_THEME_MODE
	end

	return normalize_theme_mode(result) or DEFAULT_THEME_MODE
end

local function write_theme_mode(mode)
	local normalized = normalize_theme_mode(mode)
	if not normalized then
		return false
	end

	ensure_core_dirs()
	local ok = pcall(function()
		local handle = file.open(SHILLENSILENT_THEME_MODE_PATH, { create_if_not_exists = true })
		if not handle or not handle.valid then
			error("Invalid theme mode file handle")
		end
		handle.text = normalized
	end)

	return ok and true or false
end

-- ---------------------------------------------------------
-- 1. Configuration & Assets
-- ---------------------------------------------------------

local BASE_WIDTH = 1920
local BASE_HEIGHT = 1080

local function get_screen_scale()
	local res = game.resolution()
	local scale_x = res.x / BASE_WIDTH
	local scale_y = res.y / BASE_HEIGHT
	return math.min(scale_x, scale_y)
end

local function load_tab_icon(path)
	if not path or path == "" then
		return nil
	end

	local full_path = path

	local status, img = pcall(gui.load_image, full_path)
	if status and img then
		return img
	end

	if not path:match("^[A-Za-z]:") then
		full_path = get_path(path:match("ui/components/.*") or path)
		status, img = pcall(gui.load_image, full_path)
		if status and img then
			return img
		end
	end

	return nil
end

local function init_config()
	local scale = get_screen_scale()
	local function s(px)
		return math.max(1, math.floor(px * scale))
	end
	local function tw(units)
		return s(units * 4)
	end

	local menu_width = tw(356)
	local menu_height = tw(150)
	local content_margin = tw(6)
	local column_gap = tw(4)
	local default_content_w = menu_width - (content_margin * 2)
	local fixed_column_w = math.floor((default_content_w - (2 * column_gap)) / 3)
	local min_column_side_pad = tw(6)
	local subtab_count = 10
	local min_subtab_w = tw(18)
	local subtab_gap = tw(2)
	local min_w_from_subtabs = (content_margin * 2) + (subtab_count * min_subtab_w) + ((subtab_count - 1) * subtab_gap)
	local min_w_from_columns = (content_margin * 2) + fixed_column_w + (min_column_side_pad * 2)
	local min_h_from_content = (content_margin * 2) + tw(9) + tw(2) + tw(10) + tw(3) + tw(12) + tw(4)

	return {
		font_path = SHILLENSILENT_CORE_FONTS_DIR .. "\\Inter-SemiBold.ttf",

		-- Typography scale tuned for Inter.
		font_scale_title = 24.0 * scale,
		font_scale_header = 18.0 * scale,
		font_scale_body = 16.0 * scale,
		font_scale_small = 14.0 * scale,

		origin_x = math.floor((game.resolution().x - menu_width) / 2),
		origin_y = math.floor((game.resolution().y - menu_height) / 2),
		menu_width = menu_width,
		menu_height = menu_height,

		sidebar_width = tw(26),
		sidebar_gap = tw(4),

		content_margin = content_margin,

		layout = {
			fixed_column_w = fixed_column_w,
			column_gap = column_gap,
			max_columns = 3,
		},

		resize = {
			edge_hit_w = tw(3),
			edge_hit_h = tw(6),
			min_menu_width = math.max(min_w_from_subtabs, min_w_from_columns),
			max_menu_width = menu_width,
			min_menu_height = min_h_from_content,
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

		space = {
			x1 = tw(1), -- 4px
			x1_5 = tw(1.5), -- 6px
			x2 = tw(2), -- 8px
			x2_5 = tw(2.5), -- 10px
			x3 = tw(3), -- 12px
			x3_5 = tw(3.5), -- 14px
			x4 = tw(4), -- 16px
			x5 = tw(5), -- 20px
			x6 = tw(6), -- 24px
			x7 = tw(7), -- 28px
			x8 = tw(8), -- 32px
			x9 = tw(9), -- 36px
			x10 = tw(10), -- 40px
			x11 = tw(11), -- 44px
			x12 = tw(12), -- 48px
			x15 = tw(15), -- 60px
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
			dropdown_w = tw(45), -- 180px
			slider_thumb_base = tw(4), -- 16px
			slider_thumb_grow = tw(2), -- 8px
			scrollbar_min_thumb = tw(8),
			scrollbar_grab_pad = tw(1),
			toggle_track_border_thickness = s(2),
			toggle_thumb_border_thickness = s(1.25),
		},

		motion = {
			-- Global motion tokens for consistent easing/timing.
			reduced_motion = false,
			open_y_offset = tw(7.5), -- 30px
			speed_fast = 0.24,
			speed_base = 0.16,
			speed_slow = 0.11,
			open_speed = 0.15,
			subtab_switch_speed = 0.18,
			subtab_switch_slide = tw(3),
			subtab_active_speed = 0.2,
			group_move_speed = 0.2,
			dropdown_speed = 0.22,
		},

		scale = scale,
		theme_mode = DEFAULT_THEME_MODE,

		colors = build_dark_palette(),
	}
end

local config = init_config()

local function apply_theme(mode)
	local applied_mode = normalize_theme_mode(mode) or DEFAULT_THEME_MODE
	local builder = THEME_BUILDERS[applied_mode] or THEME_BUILDERS[DEFAULT_THEME_MODE]
	local palette = builder()
	local target_colors = config.colors or {}
	config.colors = target_colors

	for key, src_color in pairs(palette) do
		local dst_color = target_colors[key]
		if type(dst_color) ~= "table" then
			dst_color = {}
			target_colors[key] = dst_color
		end

		dst_color.r = src_color.r or 255
		dst_color.g = src_color.g or 255
		dst_color.b = src_color.b or 255
		dst_color.a = src_color.a or 255
	end

	config.theme_mode = applied_mode
	return applied_mode
end

local startup_theme_mode = read_theme_mode()
apply_theme(startup_theme_mode)

-- Heist-only mode: no sidebar tab navigation.
config.sidebar_width = 0
config.sidebar_gap = 0

local body_offset = config.sidebar_gap
config.content_area.x = config.origin_x + config.sidebar_width + config.sidebar_gap
config.content_area.y = config.origin_y + body_offset
config.content_area.w = config.menu_width - config.sidebar_width - config.sidebar_gap
config.content_area.h = config.menu_height - body_offset
config.scrollbar = {
	x = config.origin_x + config.menu_width - config.space.x2,
	y = config.content_area.y + config.content_margin,
	w = config.space.x1,
	h = config.content_area.h - (config.content_margin * 2),
}

-- State
local state = {
	fonts = {},
	logo = nil,
	font_load_attempted = false,
	active_dropdown = nil,
	dropdown_just_opened = false,
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
	animation = { open = false, progress = 0.0, target = 1.0, speed = config.motion.open_speed or 0.15 },
	render_alpha_mul = 1.0,
	content_transition = { subtab = 1, progress = 1.0 },
	active_tab_y = nil,
	mouse = { x = 0, y = 0, down = false, clicked = false },
	heist_subtab = 2, -- default Cayo
	solo_launch = {
		casino = false,
		apartment = false,
		doomsday = false,
	},
	solo_launch_prev = {
		casino = false,
		apartment = false,
		doomsday = false,
	},
}

local guarded_jobs = {}

local function run_guarded_job(job_key, job_fn, on_busy)
	if type(job_fn) ~= "function" then
		return false
	end

	local key = tostring(job_key or "")
	if key == "" then
		return false
	end

	if guarded_jobs[key] then
		if type(on_busy) == "function" then
			pcall(on_busy)
		end
		return false
	end

	guarded_jobs[key] = true
	local ok_spawn, spawn_err = pcall(util.create_job, function()
		local ok_job, job_err = pcall(job_fn)
		guarded_jobs[key] = nil
		if not ok_job and notify then
			notify.push("Async Job Error", key .. ": " .. tostring(job_err), 3000)
		end
	end)

	if not ok_spawn then
		guarded_jobs[key] = nil
		if notify then
			notify.push("Async Job Error", key .. ": " .. tostring(spawn_err), 3000)
		end
		return false
	end

	return true
end

local bootstrap = {
	ui = ui,
	native = native,
	config = config,
	state = state,
	ensure_core_dirs = ensure_core_dirs,
	load_tab_icon = load_tab_icon,
	read_theme_mode = read_theme_mode,
	write_theme_mode = write_theme_mode,
	apply_theme = apply_theme,
	SHILLENSILENT_HEIST_PRESETS_DIR = SHILLENSILENT_HEIST_PRESETS_DIR,
	run_guarded_job = run_guarded_job,
}

return bootstrap
