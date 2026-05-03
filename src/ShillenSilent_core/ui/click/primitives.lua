local config = require("ShillenSilent_core.ui.click.config")
local state = require("ShillenSilent_core.ui.click.state")
local animator = require("ShillenSilent_core.ui.click.animator")

local primitives = {}

function primitives.vec(x, y)
	return vec2(x, y)
end

function primitives.snap(v)
	return math.floor((v or 0) + 0.5)
end

function primitives.snap_rect(x, y, w, h)
	return primitives.snap(x), primitives.snap(y), math.max(1, primitives.snap(w)), math.max(1, primitives.snap(h))
end

function primitives.lerp(a, b, t)
	return a + (b - a) * t
end

function primitives.clamp(value, min_value, max_value)
	if value < min_value then
		return min_value
	end
	if value > max_value then
		return max_value
	end
	return value
end

function primitives.to_gui_color(c, use_anim)
	if not c then
		return color(255, 255, 255, 255)
	end
	local r, g, b, a = c.r or 255, c.g or 255, c.b or 255, c.a or 255
	if use_anim and state.animation then
		a = math.floor(a * state.animation.progress)
	end
	if state.render_alpha_mul and state.render_alpha_mul < 0.999 then
		a = math.floor(a * state.render_alpha_mul)
	end
	return color(r, g, b, a)
end

function primitives.render_rect(x, y, w, h, col, rounding)
	if state.animation.progress < 0.01 then
		return
	end
	local ox, oy = state._frame_ox, state._frame_oy
	local sx, sy, sw, sh = primitives.snap_rect(x + ox, y + oy, w, h)
	local r = gui.rect(primitives.vec(sx, sy), primitives.vec(sw, sh))
	r:color(primitives.to_gui_color(col, true))
	r:filled()
	if rounding then
		r:rounding(rounding)
	end
	r:draw()
end

function primitives.render_outline(x, y, w, h, col, thickness, rounding)
	if state.animation.progress < 0.01 then
		return
	end
	local ox, oy = state._frame_ox, state._frame_oy
	local sx, sy, sw, sh = primitives.snap_rect(x + ox, y + oy, w, h)
	local r = gui.rect(primitives.vec(sx, sy), primitives.vec(sw, sh))
	r:color(primitives.to_gui_color(col, true))
	r:outline(thickness or 1, primitives.to_gui_color(col, true))
	if rounding then
		r:rounding(rounding)
	end
	r:draw()
end

function primitives.render_text(str, x, y, size, col, align)
	if not str or state.animation.progress < 0.01 then
		return
	end
	local ox, oy = state._frame_ox, state._frame_oy
	local t = gui.text(tostring(str))
		:position(primitives.vec(primitives.snap(x + ox), primitives.snap(y + oy)))
		:color(primitives.to_gui_color(col, true))
		:scale(size or 1.0)

	if state.fonts.regular then
		t:font(state.fonts.regular)
	end

	if gui.justify then
		if align == "center" then
			t:justify(gui.justify.center)
		elseif align == "right" then
			t:justify(gui.justify.right)
		else
			t:justify(gui.justify.left)
		end
	end
	t:draw()
	return t
end

function primitives.measure_text_size(value, draw_size)
	if not gui.text_size then
		return nil
	end
	return gui.text_size(tostring(value or ""), draw_size, { font = state.fonts.regular })
end

function primitives.centered_text_y(y, h, value, draw_size)
	local size = primitives.measure_text_size(value, draw_size)
	local text_h = (size and size.y) or ((draw_size or 1.0) * 0.7)
	return y + math.floor((h - text_h) / 2)
end

function primitives.render_text_in_rect(str, x, y, w, h, size, col, align, clip)
	if not str or state.animation.progress < 0.01 then
		return
	end

	local ox, oy = state._frame_ox, state._frame_oy
	local text_x = x
	if align == "center" then
		text_x = x + (w / 2)
	elseif align == "right" then
		text_x = x + w
	end
	local text_y = primitives.centered_text_y(y, h, str, size)

	if clip and gui.push_clip and gui.pop_clip then
		gui.push_clip(primitives.vec(x + ox, y + oy), primitives.vec(w, h))
		primitives.render_text(str, text_x, text_y, size, col, align)
		gui.pop_clip()
	else
		primitives.render_text(str, text_x, text_y, size, col, align)
	end
end

function primitives.measure_text_width(value, draw_size)
	local text_width_cache = state._text_width_cache
	if not text_width_cache then
		text_width_cache = { by_font = {}, count = 0 }
		state._text_width_cache = text_width_cache
	end

	local font_key = tostring(state.fonts.regular or "nil")
	local font_bucket = text_width_cache.by_font[font_key]
	if not font_bucket then
		font_bucket = {}
		text_width_cache.by_font[font_key] = font_bucket
	end

	local value_key = tostring(value)
	local cache_key = value_key .. "\31" .. tostring(draw_size or 1.0)
	local cached = font_bucket[cache_key]
	if cached ~= nil then
		if cached == false then
			return nil
		end
		return cached
	end

	local size = primitives.measure_text_size(value_key, draw_size)
	if not size then
		font_bucket[cache_key] = false
		return nil
	end
	font_bucket[cache_key] = size.x
	text_width_cache.count = text_width_cache.count + 1
	if text_width_cache.count > 4096 then
		text_width_cache.by_font = {}
		text_width_cache.count = 0
	end
	return size.x
end

function primitives.text_with_ellipsis(value, max_width, draw_size)
	local text = tostring(value or "")
	if text == "" then
		return ""
	end
	if max_width <= 0 then
		return ""
	end

	local ellipsis_cache = state._ellipsis_text_cache
	if not ellipsis_cache then
		ellipsis_cache = { by_font = {}, count = 0 }
		state._ellipsis_text_cache = ellipsis_cache
	end

	local font_key = tostring(state.fonts.regular or "nil")
	local font_bucket = ellipsis_cache.by_font[font_key]
	if not font_bucket then
		font_bucket = {}
		ellipsis_cache.by_font[font_key] = font_bucket
	end

	local width_bucket = font_bucket[text]
	if not width_bucket then
		width_bucket = {}
		font_bucket[text] = width_bucket
	end
	local max_width_bucket = width_bucket[max_width]
	if not max_width_bucket then
		max_width_bucket = {}
		width_bucket[max_width] = max_width_bucket
	end
	local scale_key = draw_size or 1.0
	local cached = max_width_bucket[scale_key]
	if cached ~= nil then
		return cached
	end

	local width = primitives.measure_text_width(text, draw_size)
	if width and width <= max_width then
		max_width_bucket[scale_key] = text
		ellipsis_cache.count = ellipsis_cache.count + 1
		return text
	end

	local ellipsis = "..."
	local ellipsis_width = primitives.measure_text_width(ellipsis, draw_size) or ((draw_size or 1.0) * 3.0)
	if ellipsis_width >= max_width then
		max_width_bucket[scale_key] = ""
		ellipsis_cache.count = ellipsis_cache.count + 1
		return ""
	end

	local low, high = 0, #text
	while low < high do
		local mid = math.floor((low + high + 1) / 2)
		local candidate = text:sub(1, mid) .. ellipsis
		local candidate_width = primitives.measure_text_width(candidate, draw_size)
		if candidate_width and candidate_width <= max_width then
			low = mid
		else
			high = mid - 1
		end
	end

	local output = text:sub(1, low) .. ellipsis
	max_width_bucket[scale_key] = output
	ellipsis_cache.count = ellipsis_cache.count + 1
	if ellipsis_cache.count > 4096 then
		ellipsis_cache.by_font = {}
		ellipsis_cache.count = 0
	end
	return output
end

function primitives.measure_wrapped_text_height(text, max_w, scale)
	if gui.text_size then
		local size = gui.text_size(tostring(text or ""), scale, { wrap = max_w, font = state.fonts.regular })
		if size and size.y and size.y > 0 then
			return size.y
		end
	end
	return config.space.x6
end

function primitives.render_wrapped_text(text, x, y, max_w, scale, col, align)
	if not text or state.animation.progress < 0.01 then
		return
	end
	local ox, oy = state._frame_ox, state._frame_oy
	local t = gui.text(tostring(text))
		:position(primitives.vec(primitives.snap(x + ox), primitives.snap(y + oy)))
		:color(primitives.to_gui_color(col, true))
		:scale(scale or 1.0)

	if state.fonts.regular then
		t:font(state.fonts.regular)
	end
	if t.wrap then
		t:wrap(max_w)
	end
	if gui.justify then
		if align == "center" then
			t:justify(gui.justify.center)
		elseif align == "right" then
			t:justify(gui.justify.right)
		else
			t:justify(gui.justify.left)
		end
	end
	t:draw()
	return t
end

function primitives.info_item_text(item)
	return "· " .. ((item and item.text) or "")
end

function primitives.info_item_pad_top()
	return config.space.x1_5
end

function primitives.info_item_pad_bottom()
	return config.space.x1
end

function primitives.info_item_height(text, max_w, scale)
	if not max_w or max_w <= 0 then
		return config.space.x3
	end
	return primitives.info_item_pad_top()
		+ math.ceil(primitives.measure_wrapped_text_height(text, max_w, scale))
		+ primitives.info_item_pad_bottom()
end

function primitives.button_line_count(label, btn_w)
	if not btn_w or btn_w <= 0 then
		return 1
	end
	local pad_x = config.space.x3
	local draw_size = (config.font_scale_small or 1.0) * 0.9
	local wrapped_h =
		primitives.measure_wrapped_text_height(tostring(label or ""), math.max(1, btn_w - (pad_x * 2)), draw_size)
	return math.max(1, math.ceil(wrapped_h / config.space.x6))
end

function primitives.button_h_from_lines(n)
	return config.item_height.button + (n - 1) * config.space.x6
end

function primitives.button_pair_half_widths(col_w)
	local pad_x = config.space.x3
	local gap = config.space.x2_5
	local totalW = col_w - (pad_x * 2)
	local innerW = math.max(2, math.floor((totalW - gap) + 0.5))
	local leftW = math.floor(innerW / 2)
	return leftW, innerW - leftW
end

local _shadow_col = { r = 0, g = 0, b = 0, a = 8 }

function primitives.shadow_color(alpha)
	local shadow_col = config.colors.chrome_shadow_soft or config.colors.card_shadow or { r = 0, g = 0, b = 0 }
	_shadow_col.r = shadow_col.r
	_shadow_col.g = shadow_col.g
	_shadow_col.b = shadow_col.b
	_shadow_col.a = math.max(0, math.floor(alpha or 0))
	return _shadow_col
end

function primitives.shadow_alpha(scale, fallback)
	local card_shadow = config.colors.card_shadow
	local base = (card_shadow and card_shadow.a) or fallback or 120
	return math.max(0, math.floor(base * (scale or 1.0)))
end

function primitives.render_depth_shadow(x, y, w, h, rounding, scale, proximity)
	local hover_t = animator.clamp01(proximity or 0.0)
	local far_alpha = primitives.shadow_alpha((scale or 1.0) * 0.1, 120)
	local near_alpha = primitives.shadow_alpha((scale or 1.0) * 0.22, 120)
	if near_alpha <= 0 and far_alpha <= 0 then
		return
	end

	local far_offset = config.space.x1_5 - ((config.space.x1_5 - config.space.x1) * hover_t)
	local near_offset = config.space.x1 - ((config.space.x1 * 0.45) * hover_t)
	local spread = math.max(1, math.floor(config.space.x1 * 0.35))
	if far_alpha > 0 then
		primitives.render_rect(
			x + far_offset - spread,
			y + far_offset - spread,
			w + (spread * 2),
			h + (spread * 2),
			primitives.shadow_color(far_alpha),
			rounding
		)
	end
	if near_alpha > 0 then
		primitives.render_rect(x + near_offset, y + near_offset, w, h, primitives.shadow_color(near_alpha), rounding)
	end
end

function primitives.render_card_shadow(x, y, w, h, rounding)
	local alpha = primitives.shadow_alpha(0.16, 120)
	if alpha <= 0 then
		return
	end

	local offset = config.space.x1
	primitives.render_rect(x + offset, y + offset, w, h, primitives.shadow_color(alpha), rounding)
end

function primitives.render_card(x, y, w, h, bg_col, border_col, rounding)
	local r = rounding or config.radius.md
	primitives.render_card_shadow(x, y, w, h, r)
	primitives.render_rect(x, y, w, h, bg_col or config.colors.bg_panel, r)
	primitives.render_outline(x, y, w, h, border_col or config.colors.border, 1, r)
end

function primitives.render_background_tile(x, y, w, h)
	local image = state.images and state.images.background_tile
	if not image or not gui.image then
		return
	end

	local image_scale = image.scale
	local tile_w = image_scale and image_scale.x
	local tile_h = image_scale and image_scale.y
	if not tile_w or not tile_h or tile_w <= 0 or tile_h <= 0 then
		return
	end

	local ox, oy = state._frame_ox, state._frame_oy
	local alpha = config.background_tile_alpha or 255
	local tint = color(255, 255, 255, math.floor(alpha * state.animation.progress))

	gui.push_clip(primitives.vec(x + ox, y + oy), primitives.vec(w, h))
	local draw_y = y
	while draw_y < y + h do
		local draw_x = x
		while draw_x < x + w do
			gui.image(
				image,
				primitives.vec(primitives.snap(draw_x + ox), primitives.snap(draw_y + oy)),
				image_scale,
				tint
			)
			draw_x = draw_x + tile_w
		end
		draw_y = draw_y + tile_h
	end
	gui.pop_clip()
end

return primitives
