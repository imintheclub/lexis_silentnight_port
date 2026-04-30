local assets = require("ShillenSilent_core.ui.click.assets")
local config = require("ShillenSilent_core.ui.click.config")
local i18n = require("ShillenSilent_core.i18n")
local state = require("ShillenSilent_core.ui.click.state")

local splash = {
	started = false,
	finished = true,
	start_at = 0.0,
	message_key = "splash.press_open_window",
	thread_running = false,
	gen = nil,
}

local function current_gen()
	return _G.ShillenSilent_Generation or 0
end

local LIFETIME_S = 15.0
local FADE_OUT_S = 3.0

local function snap(value)
	return math.floor((value or 0) + 0.5)
end

local function vec(x, y)
	return vec2(x, y)
end

local function get_resolution()
	if game and game.resolution then
		local ok, resolution = pcall(game.resolution)
		if ok and resolution and resolution.x and resolution.y then
			return resolution.x, resolution.y
		end
	end
	return 1920, 1080
end

local function with_alpha(col, alpha_mul, fallback)
	local source = col or fallback or { r = 255, g = 255, b = 255, a = 255 }
	local base_alpha = source.a or 255
	return color(
		source.r or 255,
		source.g or 255,
		source.b or 255,
		math.max(0, math.min(255, math.floor(base_alpha * (alpha_mul or 1.0))))
	)
end

local function draw_rect(x, y, w, h, col)
	if not (gui and gui.rect) then
		return
	end
	local rect = gui.rect(vec(snap(x), snap(y)), vec(snap(w), snap(h)))
	rect:color(col)
	rect:filled()
	rect:draw()
end

local function draw_text(text, x, y, size, col)
	if not (gui and gui.text) then
		return
	end
	local item = gui.text(tostring(text or "")):position(vec(snap(x), snap(y))):color(col):scale(size)

	if state.fonts and state.fonts.regular then
		item:font(state.fonts.regular)
	end
	if gui.justify then
		item:justify(gui.justify.center)
	end
	item:draw()
end

local function measure_text(text, size)
	if gui and gui.text_size then
		local ok, measured =
			pcall(gui.text_size, tostring(text or ""), size, { font = state.fonts and state.fonts.regular })
		if ok and measured and measured.x and measured.y then
			return measured.x, measured.y
		end
	end
	return #(tostring(text or "")) * (size or 16) * 0.55, (size or 16) * 1.1
end

local function alpha_for_elapsed(elapsed)
	local fade_start = LIFETIME_S - FADE_OUT_S
	if elapsed < fade_start then
		return 1.0
	end
	local fade_t = (elapsed - fade_start) / FADE_OUT_S
	if fade_t > 1.0 then
		fade_t = 1.0
	elseif fade_t < 0.0 then
		fade_t = 0.0
	end
	return 1.0 - fade_t
end

function splash.start(message_key)
	splash.started = true
	splash.finished = false
	splash.start_at = os.clock()
	splash.message_key = message_key or "splash.press_open_window"
	splash.gen = current_gen()
end

function splash.stop()
	splash.finished = true
end

function splash.is_active()
	if splash.gen ~= nil and splash.gen ~= current_gen() then
		splash.finished = true
		return false
	end
	return splash.started and not splash.finished
end

function splash.render()
	if not splash.is_active() then
		return
	end
	pcall(assets.ensure_assets)

	local elapsed = os.clock() - splash.start_at
	if elapsed >= LIFETIME_S then
		splash.finished = true
		return
	end

	local sw, sh = get_resolution()
	local scale = config.scale or math.min(sw / 1920, sh / 1080)
	local alpha_mul = alpha_for_elapsed(elapsed)
	if alpha_mul <= 0.0 then
		splash.finished = true
		return
	end

	local text = i18n.t(splash.message_key or "splash.press_open_window")
	local font_size = math.max(44 * scale, (config.font_scale_title or 24) * 2.1)
	local max_width = sw - math.max(96, math.floor(160 * scale))
	local text_w, text_h = measure_text(text, font_size)
	while text_w > max_width and font_size > math.max(24, 24 * scale) do
		font_size = font_size - math.max(1, math.floor(3 * scale))
		text_w, text_h = measure_text(text, font_size)
	end

	draw_rect(0, 0, sw, sh, color(0, 0, 0, math.floor(200 * alpha_mul)))

	local text_x = sw * 0.5
	local text_y = (sh * 0.5) - (text_h * 0.5)
	local shadow_offset = math.max(2, math.floor(3 * scale))
	draw_text(
		text,
		text_x + shadow_offset,
		text_y + shadow_offset,
		font_size,
		color(0, 0, 0, math.floor(190 * alpha_mul))
	)
	draw_text(text, text_x, text_y, font_size, with_alpha(config.colors.text_main, alpha_mul))
end

function splash.start_thread(message_key)
	splash.start(message_key)
	if splash.thread_running or not (util and util.create_thread) then
		return
	end

	splash.thread_running = true
	local my_gen = current_gen()
	util.create_thread(function()
		while splash.is_active() and current_gen() == my_gen do
			pcall(splash.render)
			util.yield(0)
		end
		splash.thread_running = false
	end)
end

return splash
