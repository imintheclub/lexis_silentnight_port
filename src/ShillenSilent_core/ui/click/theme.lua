local config_store = require("ShillenSilent_core.core.config_store")

local theme = {}

local DEFAULT_THEME_MODE = "dark"
local VALID_THEME_MODES = {
	dark = true,
	light = true,
	dracula = true,
	google_dark = true,
	google_light = true,
	github_light = true,
	flexoki_light = true,
	gruvbox = true,
	nord = true,
	material = true,
	tokyo_night = true,
	night_owl = true,
	cobalt2 = true,
	shades_of_purple = true,
	everforest = true,
	ayu = true,
	synthwave84 = true,
	kanagawa = true,
	solarized_dark = true,
}

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

local THEME_PRIMITIVES = {
	dark = {
		bg = "#020617",
		panel = "#0F172A",
		control = "#1E293B",
		control_hover = "#334155",
		border = "#334155",
		border_strong = "#475569",
		accent = "#F1F5F9",
		accent_hover = "#E2E8F0",
		fg = "#F8FAFC",
		fg_sec = "#E2E8F0",
		comment = "#94A3B8",
		text_on_accent = "#0F172A",
		scroll_track = "#334155",
		card_shadow = "#020617",
		card_shadow_alpha = 120,
		transparent = "#0F172A",
		neutral_muted = "#475569",
		chrome_shadow_soft = "#020617",
		chrome_highlight_soft = "#F1F5F9",
		danger = "#DC2626",
		danger_hover = "#B91C1C",
		danger_soft = "#FEF2F2",
		danger_text = "#991B1B",
		success = "#059669",
		success_hover = "#047857",
	},
	light = {
		is_light = true,
		bg = "#F8FAFC",
		panel = "#F8FAFC",
		control = "#F1F5F9",
		control_hover = "#E2E8F0",
		ghost_hover = "#E2E8F0",
		border = "#E2E8F0",
		border_strong = "#CBD5E1",
		accent = "#0F172A",
		accent_hover = "#020617",
		fg = "#0F172A",
		fg_sec = "#334155",
		comment = "#64748B",
		text_on_accent = "#F8FAFC",
		scroll_track = "#E2E8F0",
		card_shadow = "#020617",
		card_shadow_alpha = 36,
		transparent = "#F8FAFC",
		neutral_muted = "#94A3B8",
		chrome_shadow_soft = "#020617",
		chrome_highlight_soft = "#F8FAFC",
		danger = "#DC2626",
		danger_hover = "#B91C1C",
		danger_soft = "#FEF2F2",
		danger_text = "#991B1B",
		success = "#059669",
		success_hover = "#047857",
	},
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
	google_dark = {
		bg = "#171717",
		panel = "#2B2C2F",
		control = "#35363A",
		control_hover = "#3C4043",
		ghost_hover = "#303134",
		border = "#3C4043",
		border_strong = "#5F6368",
		accent = "#4285F4",
		accent_hover = "#3367D6",
		fg = "#F8F9FA",
		fg_sec = "#E8EAED",
		comment = "#9AA0A6",
		text_on_accent = "#FFFFFF",
		scroll_track = "#3C4043",
		neutral_muted = "#5F6368",
		chrome_highlight_soft = "#FBBC04",
		danger = "#EA4335",
		danger_hover = "#C5221F",
		danger_soft = "#3C1F1B",
		danger_text = "#F28B82",
		success = "#34A853",
		success_hover = "#188038",
	},
	google_light = {
		is_light = true,
		bg = "#E8EAED",
		panel = "#FFFFFF",
		control = "#F1F3F4",
		control_hover = "#DADCE0",
		ghost_hover = "#F1F3F4",
		border = "#DADCE0",
		border_strong = "#BDC1C6",
		accent = "#4285F4",
		accent_hover = "#3367D6",
		fg = "#202124",
		fg_sec = "#3C4043",
		comment = "#5F6368",
		text_on_accent = "#FFFFFF",
		scroll_track = "#E8EAED",
		card_shadow = "#202124",
		card_shadow_alpha = 32,
		neutral_muted = "#9AA0A6",
		chrome_highlight_soft = "#FBBC04",
		danger = "#EA4335",
		danger_hover = "#C5221F",
		danger_soft = "#FCE8E6",
		danger_text = "#A50E0E",
		success = "#34A853",
		success_hover = "#188038",
	},
	github_light = {
		is_light = true,
		bg = "#F6F8FA",
		panel = "#FFFFFF",
		control = "#F6F8FA",
		control_hover = "#EAEEF2",
		ghost_hover = "#EAEEF2",
		border = "#D0D7DE",
		border_strong = "#8C959F",
		accent = "#0969DA",
		accent_hover = "#0550AE",
		fg = "#24292F",
		fg_sec = "#57606A",
		comment = "#6E7781",
		text_on_accent = "#FFFFFF",
		scroll_track = "#EAEEF2",
		card_shadow = "#1F2328",
		card_shadow_alpha = 28,
		neutral_muted = "#AFB8C1",
		chrome_highlight_soft = "#1F6FEB",
		danger = "#CF222E",
		danger_hover = "#A40E26",
		danger_soft = "#FFEBE9",
		danger_text = "#A40E26",
		success = "#1A7F37",
		success_hover = "#116329",
	},
	flexoki_light = {
		is_light = true,
		bg = "#FFFCF0",
		panel = "#FFFCF0",
		control = "#F2F0E5",
		control_hover = "#E6E4D9",
		ghost_hover = "#F2F0E5",
		border = "#DAD8CE",
		border_strong = "#CECDC3",
		accent = "#205EA6",
		accent_hover = "#1A4F8C",
		fg = "#100F0F",
		fg_sec = "#403E3C",
		comment = "#6F6E69",
		text_on_accent = "#FFFCF0",
		scroll_track = "#E6E4D9",
		card_shadow = "#100F0F",
		card_shadow_alpha = 24,
		neutral_muted = "#B7B5AC",
		chrome_highlight_soft = "#4385BE",
		danger = "#AF3029",
		danger_hover = "#942822",
		danger_soft = "#FFE1D5",
		danger_text = "#942822",
		success = "#66800B",
		success_hover = "#536907",
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
	cobalt2 = {
		bg = "#193549",
		panel = "#122738",
		control = "#1F4662",
		control_hover = "#2D5F80",
		border = "#1F4662",
		border_strong = "#3A7895",
		accent = "#FFC600",
		accent_hover = "#E6B200",
		fg = "#FFFFFF",
		fg_sec = "#E1EFFF",
		comment = "#0088FF",
		text_on_accent = "#193549",
		danger = "#FF5A5F",
		danger_hover = "#E04045",
		success = "#3AD900",
		success_hover = "#2EBA00",
	},
	shades_of_purple = {
		bg = "#1E1736",
		panel = "#2D2B55",
		control = "#3D3B6E",
		control_hover = "#4F4C8F",
		border = "#3D3B6E",
		border_strong = "#7B77C1",
		accent = "#FAD000",
		accent_hover = "#E0B800",
		fg = "#FFFFFF",
		fg_sec = "#B2B0E0",
		comment = "#8B8AC2",
		text_on_accent = "#1E1736",
		danger = "#FF3434",
		danger_hover = "#E02020",
		success = "#3AD900",
		success_hover = "#2EBA00",
	},
	everforest = {
		bg = "#2D353B",
		panel = "#272E33",
		control = "#343F44",
		control_hover = "#3D484D",
		border = "#343F44",
		border_strong = "#4A555B",
		accent = "#A7C080",
		accent_hover = "#8EAD68",
		fg = "#D3C6AA",
		fg_sec = "#C4B597",
		comment = "#7A8478",
		text_on_accent = "#2D353B",
		danger = "#E67E80",
		danger_hover = "#CC6669",
		success = "#A7C080",
		success_hover = "#8EAD68",
	},
	ayu = {
		bg = "#0D1017",
		panel = "#13191F",
		control = "#1A2129",
		control_hover = "#232D37",
		border = "#1A2129",
		border_strong = "#2D3640",
		accent = "#E6B450",
		accent_hover = "#CC9A38",
		fg = "#BFBDB6",
		fg_sec = "#A8A49E",
		comment = "#5C6773",
		text_on_accent = "#0D1017",
		danger = "#F07178",
		danger_hover = "#D65A60",
		success = "#AAD94C",
		success_hover = "#8EB934",
	},
	synthwave84 = {
		bg = "#262335",
		panel = "#1A1A2E",
		control = "#2A2139",
		control_hover = "#3D3060",
		border = "#2A2139",
		border_strong = "#4A3F7A",
		accent = "#FF7EDB",
		accent_hover = "#E060C4",
		fg = "#FFFFFF",
		fg_sec = "#E3D9FF",
		comment = "#848BBD",
		text_on_accent = "#262335",
		danger = "#FE4450",
		danger_hover = "#E02E39",
		success = "#72F1B8",
		success_hover = "#5BCFA0",
	},
	kanagawa = {
		bg = "#1F1F28",
		panel = "#16161D",
		control = "#2A2A37",
		control_hover = "#363646",
		border = "#2A2A37",
		border_strong = "#54546D",
		accent = "#7E9CD8",
		accent_hover = "#6585C4",
		fg = "#DCD7BA",
		fg_sec = "#C8C093",
		comment = "#727169",
		text_on_accent = "#1F1F28",
		danger = "#E82424",
		danger_hover = "#C41F1F",
		success = "#98BB6C",
		success_hover = "#7EA358",
	},
	solarized_dark = {
		bg = "#002B36",
		panel = "#073642",
		control = "#083F4D",
		control_hover = "#0D525E",
		border = "#073642",
		border_strong = "#586E75",
		accent = "#268BD2",
		accent_hover = "#1A75BC",
		fg = "#839496",
		fg_sec = "#93A1A1",
		comment = "#657B83",
		text_on_accent = "#FDF6E3",
		danger = "#DC322F",
		danger_hover = "#C42A27",
		success = "#859900",
		success_hover = "#6E7D00",
	},
}

local function build_palette_from_primitives(p)
	local is_light = p.is_light == true
	return {
		bg_main = hex(p.bg),
		bg_panel = hex(p.panel or p.bg),
		bg_control = hex(p.control),
		bg_control_hover = hex(p.control_hover or p.control),
		bg_ghost_hover = hex(p.ghost_hover or p.control),
		accent = hex(p.accent),
		accent_hover = hex(p.accent_hover or p.accent),
		text_main = hex(p.fg),
		text_sec = hex(p.fg_sec or p.fg),
		text_dim = hex(p.comment, 240),
		text_on_accent = hex(p.text_on_accent or p.bg),
		white = hex(p.fg),
		border = hex(p.border or p.control),
		border_strong = hex(p.border_strong or p.comment),
		scroll_track = hex(p.scroll_track or p.control, 220),
		card_shadow = hex(p.card_shadow or "#000000", p.card_shadow_alpha or (is_light and 30 or 120)),
		transparent = hex(p.transparent or p.bg, 0),
		neutral_muted = hex(p.neutral_muted or p.comment),
		chrome_shadow_soft = hex(p.chrome_shadow_soft or "#000000"),
		chrome_highlight_soft = hex(p.chrome_highlight_soft or p.fg),
		danger = hex(p.danger or "#DC2626"),
		danger_hover = hex(p.danger_hover or "#B91C1C"),
		danger_soft = hex(p.danger_soft or (is_light and "#FEF2F2" or "#3A1F22")),
		danger_text = hex(p.danger_text or p.danger or "#FCA5A5"),
		success = hex(p.success or "#059669"),
		success_hover = hex(p.success_hover or "#047857"),
	}
end

local THEME_BUILDERS = {}

for name, primitives in pairs(THEME_PRIMITIVES) do
	local primitive_set = primitives
	THEME_BUILDERS[name] = function()
		return build_palette_from_primitives(primitive_set)
	end
end

function theme.normalize_theme_mode(mode)
	return normalize_theme_mode(mode)
end

function theme.default_mode()
	return DEFAULT_THEME_MODE
end

function theme.default_palette()
	return build_palette_from_primitives(THEME_PRIMITIVES[DEFAULT_THEME_MODE])
end

function theme.read_theme_mode()
	local mode = normalize_theme_mode(config_store.get("theme_mode", nil))
	if mode then
		return mode
	end
	return DEFAULT_THEME_MODE
end

function theme.write_theme_mode(mode)
	local normalized = normalize_theme_mode(mode)
	if not normalized then
		return false
	end

	local ok = config_store.set("theme_mode", normalized)

	return ok and true or false
end

function theme.apply_theme(config, mode)
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

return theme
