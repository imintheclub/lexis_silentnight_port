-- ---------------------------------------------------------
-- 2. Core Rendering Helpers
-- ---------------------------------------------------------

local i18n = require("ShillenSilent_core.i18n")
local notify_core = require("ShillenSilent_core.core.notify")
local assets = require("ShillenSilent_core.ui.click.assets")
local config = require("ShillenSilent_core.ui.click.config")
local state = require("ShillenSilent_core.ui.click.state")
local group_layouts = require("ShillenSilent_core.ui.click.group_layouts")
local info_actions = require("ShillenSilent_core.features.heists.info.actions")
local info_data = require("ShillenSilent_core.features.heists.info.data")

local ui = {}

function ui.ensure_assets()
	return assets.ensure_assets()
end

local function vec(x, y)
	return vec2(x, y)
end

local function snap(v)
	return math.floor((v or 0) + 0.5)
end

local function snap_rect(x, y, w, h)
	return snap(x), snap(y), math.max(1, snap(w)), math.max(1, snap(h))
end

local function get_win_offset()
	local anim_y_offset = (1.0 - state.animation.progress) * config.motion.open_y_offset
	return state.window.x - config.origin_x, (state.window.y - config.origin_y) + anim_y_offset
end

local function is_hovered(x, y, w, h)
	if state.animation.progress < 0.9 then
		return false
	end
	local ox, oy = state._frame_ox, state._frame_oy
	return input.is_mouse_within(vec(x + ox, y + oy), vec(w, h))
end

local function drawer_blocks_content_hover()
	local drawer = state.drawer
	return type(drawer) == "table"
		and (drawer.open == true or (drawer.target or 0.0) > 0.01 or (drawer.progress or 0.0) > 0.01)
end

local function is_hovered_content(item_x, item_y, w, h)
	if drawer_blocks_content_hover() then
		return false
	end

	local ox, oy = state._frame_ox, state._frame_oy

	local cx, cy = config.content_area.x + ox, config.content_area.y + oy
	local cw, ch = config.content_area.w, config.content_area.h

	if not input.is_mouse_within(vec(cx, cy), vec(cw, ch)) then
		return false
	end

	return input.is_mouse_within(vec(item_x + ox, item_y + oy), vec(w, h))
end

local function update_input()
	local m_pos = input.mouse_position()
	local m_click = input.mouse(1)
	state.mouse.x = m_pos.x
	state.mouse.y = m_pos.y
	state.mouse.down = m_click.pressed
	state.mouse.clicked = m_click.just_pressed

	if not state.mouse.down then
		state.dragging_slider = nil
		state.window.is_dragging = false
		state.window.is_resizing = false
		state.scroll.is_dragging = false
	end
end

local function to_gui_color(c, use_anim)
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

local function render_rect(x, y, w, h, col, rounding)
	if state.animation.progress < 0.01 then
		return
	end
	local ox, oy = state._frame_ox, state._frame_oy
	local sx, sy, sw, sh = snap_rect(x + ox, y + oy, w, h)
	local r = gui.rect(vec(sx, sy), vec(sw, sh))
	r:color(to_gui_color(col, true))
	r:filled()
	if rounding then
		r:rounding(rounding)
	end
	r:draw()
end

local function render_outline(x, y, w, h, col, thickness, rounding)
	if state.animation.progress < 0.01 then
		return
	end
	local ox, oy = state._frame_ox, state._frame_oy
	local sx, sy, sw, sh = snap_rect(x + ox, y + oy, w, h)
	local r = gui.rect(vec(sx, sy), vec(sw, sh))
	r:color(to_gui_color(col, true))
	r:outline(thickness or 1, to_gui_color(col, true))
	if rounding then
		r:rounding(rounding)
	end
	r:draw()
end

local function render_text(str, x, y, size, col, align)
	if not str or state.animation.progress < 0.01 then
		return
	end
	local ox, oy = state._frame_ox, state._frame_oy
	local t = gui.text(tostring(str))
		:position(vec(snap(x + ox), snap(y + oy)))
		:color(to_gui_color(col, true))
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

local function measure_text_size(value, draw_size)
	if not gui.text_size then
		return nil
	end
	return gui.text_size(tostring(value or ""), draw_size, { font = state.fonts.regular })
end

local function centered_text_y(y, h, value, draw_size)
	local size = measure_text_size(value, draw_size)
	local text_h = (size and size.y) or ((draw_size or 1.0) * 0.7)
	return y + math.floor((h - text_h) / 2)
end

local function render_text_in_rect(str, x, y, w, h, size, col, align, clip)
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
	local text_y = centered_text_y(y, h, str, size)

	if clip and gui.push_clip and gui.pop_clip then
		gui.push_clip(vec(x + ox, y + oy), vec(w, h))
		render_text(str, text_x, text_y, size, col, align)
		gui.pop_clip()
	else
		render_text(str, text_x, text_y, size, col, align)
	end
end

local function measure_text_width(value, draw_size)
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

	local size = measure_text_size(value_key, draw_size)
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

local function text_with_ellipsis(value, max_width, draw_size)
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

	local width = measure_text_width(text, draw_size)
	if width and width <= max_width then
		max_width_bucket[scale_key] = text
		ellipsis_cache.count = ellipsis_cache.count + 1
		return text
	end

	local ellipsis = "..."
	local ellipsis_width = measure_text_width(ellipsis, draw_size) or ((draw_size or 1.0) * 3.0)
	if ellipsis_width >= max_width then
		max_width_bucket[scale_key] = ""
		ellipsis_cache.count = ellipsis_cache.count + 1
		return ""
	end

	local low, high = 0, #text
	while low < high do
		local mid = math.floor((low + high + 1) / 2)
		local candidate = text:sub(1, mid) .. ellipsis
		local candidate_width = measure_text_width(candidate, draw_size)
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

local function measure_wrapped_text_height(text, max_w, scale)
	if gui.text_size then
		local size = gui.text_size(tostring(text or ""), scale, { wrap = max_w, font = state.fonts.regular })
		if size and size.y and size.y > 0 then
			return size.y
		end
	end
	return config.space.x6
end

local function render_wrapped_text(text, x, y, max_w, scale, col, align)
	if not text or state.animation.progress < 0.01 then
		return
	end
	local ox, oy = state._frame_ox, state._frame_oy
	local t = gui.text(tostring(text))
		:position(vec(snap(x + ox), snap(y + oy)))
		:color(to_gui_color(col, true))
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

local function info_item_text(item)
	return "· " .. ((item and item.text) or "")
end

local function info_item_pad_top()
	return config.space.x1_5
end

local function info_item_pad_bottom()
	return config.space.x1
end

local function info_item_height(text, max_w, scale)
	if not max_w or max_w <= 0 then
		return config.space.x3
	end
	return info_item_pad_top() + math.ceil(measure_wrapped_text_height(text, max_w, scale)) + info_item_pad_bottom()
end

local function button_line_count(label, btn_w)
	if not btn_w or btn_w <= 0 then
		return 1
	end
	local pad_x = config.space.x3
	local draw_size = (config.font_scale_small or 1.0) * 0.9
	local wrapped_h = measure_wrapped_text_height(tostring(label or ""), math.max(1, btn_w - (pad_x * 2)), draw_size)
	return math.max(1, math.ceil(wrapped_h / config.space.x6))
end

local function button_h_from_lines(n)
	return config.item_height.button + (n - 1) * config.space.x6
end

local function button_pair_half_widths(col_w)
	local pad_x = config.space.x3
	local gap = config.space.x2_5
	local totalW = col_w - (pad_x * 2)
	local innerW = math.max(2, math.floor((totalW - gap) + 0.5))
	local leftW = math.floor(innerW / 2)
	return leftW, innerW - leftW
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function clamp(value, min_value, max_value)
	if value < min_value then
		return min_value
	end
	if value > max_value then
		return max_value
	end
	return value
end

local animator = { values = {}, frame = 0 }

function animator.clamp01(v)
	if v < 0 then
		return 0
	end
	if v > 1 then
		return 1
	end
	return v
end

function animator.motion_disabled()
	return config.motion and config.motion.reduced_motion
end

function animator.motion_speed(token_value, fallback)
	if animator.motion_disabled() then
		return 1.0
	end
	return token_value or fallback or 0.16
end

function animator.to(key, target, speed)
	if animator.motion_disabled() then
		animator.values[key] = { v = target, seen = animator.frame }
		return target
	end

	local node = animator.values[key]
	if not node then
		node = { v = target, seen = animator.frame }
		animator.values[key] = node
		return target
	end

	node.v = lerp(node.v, target, speed)
	if math.abs(node.v - target) < 0.01 then
		node.v = target
	end
	node.seen = animator.frame
	return node.v
end

function animator.vec2(key, target_x, target_y, speed)
	local x = animator.to(key .. ":x", target_x, speed)
	local y = animator.to(key .. ":y", target_y, speed)
	return x, y
end

function animator.prune(max_age)
	local cutoff = animator.frame - max_age
	for key, node in pairs(animator.values) do
		if not node.seen or node.seen < cutoff then
			animator.values[key] = nil
		end
	end
end

function animator.blend_color(c1, c2, t, out)
	local tt = animator.clamp01(t)
	local inv = 1 - tt
	out = out or {}
	out.r = math.floor((c1.r or 0) * inv + (c2.r or 0) * tt)
	out.g = math.floor((c1.g or 0) * inv + (c2.g or 0) * tt)
	out.b = math.floor((c1.b or 0) * inv + (c2.b or 0) * tt)
	out.a = math.floor((c1.a or 255) * inv + (c2.a or 255) * tt)
	return out
end

-- ---------------------------------------------------------
-- 3. UI Structure
-- ---------------------------------------------------------
ui.tabs = {}
ui.currentTab = nil
local layout_cache_revision = 0

local function mark_layout_dirty()
	layout_cache_revision = layout_cache_revision + 1
end

ui.tab = function(id, label, hidden)
	local tab = { id = id, label = label, groups = {}, hidden = hidden or false }
	table.insert(ui.tabs, tab)
	mark_layout_dirty()
	if #ui.tabs == 1 and not tab.hidden then
		ui.currentTab = tab
	end
	return tab
end

ui.group = function(tabRef, label, x, y, w, min_h, heist_subtab)
	local group =
		{ label = label, items = {}, rect = { x = x, y = y, w = w, h = min_h or 100 }, heist_subtab = heist_subtab }
	table.insert(tabRef.groups, group)
	mark_layout_dirty()
	return group
end

ui.toggle = function(groupRef, configKey, label, defaultState, onChange, tooltip)
	local item = {
		type = "toggle",
		id = configKey,
		label = label,
		state = defaultState,
		onChange = onChange,
		tooltip = tooltip,
		hotkey = nil,
		anim = defaultState and 1.0 or 0.0,
	}
	table.insert(groupRef.items, item)
	mark_layout_dirty()
	return item
end

ui.slider = function(groupRef, configKey, label, min, max, defaultVal, onChange, tooltip, step)
	-- Round default value to step if specified
	local initialValue = defaultVal
	if step and step > 0 then
		initialValue = math.floor((defaultVal + step / 2) / step) * step
	end
	local item = {
		type = "slider",
		id = configKey,
		label = label,
		min = min,
		max = max,
		value = initialValue,
		onChange = onChange,
		tooltip = tooltip,
		anim = 0.0,
		step = step,
	}
	table.insert(groupRef.items, item)
	mark_layout_dirty()
	return item
end

ui.button = function(groupRef, id, label, onClick, tooltip, disabled, color)
	local item = {
		type = "button",
		id = id,
		label = label,
		onClick = onClick,
		tooltip = tooltip,
		disabled = disabled or false,
		color = color,
	}
	table.insert(groupRef.items, item)
	mark_layout_dirty()
	return item
end

ui.button_pair = function(
	groupRef,
	left_id,
	left_label,
	left_onClick,
	right_id,
	right_label,
	right_onClick,
	left_tooltip,
	right_tooltip,
	left_disabled,
	right_disabled,
	left_color,
	right_color
)
	local item = {
		type = "button_pair",
		left = {
			id = left_id,
			label = left_label,
			onClick = left_onClick,
			tooltip = left_tooltip,
			disabled = left_disabled or false,
			color = left_color,
		},
		right = {
			id = right_id,
			label = right_label,
			onClick = right_onClick,
			tooltip = right_tooltip,
			disabled = right_disabled or false,
			color = right_color,
		},
	}
	table.insert(groupRef.items, item)
	mark_layout_dirty()
	return item
end

ui.dropdown = function(groupRef, configKey, label, options, defaultIdx, onChange, tooltip)
	local item = {
		type = "dropdown",
		id = configKey,
		label = label,
		options = options,
		value = defaultIdx,
		onChange = onChange,
		isOpen = false,
		tooltip = tooltip,
	}
	table.insert(groupRef.items, item)
	mark_layout_dirty()
	return item
end

ui.label = function(groupRef, text, color)
	local item = { type = "label", text = text, color = color }
	table.insert(groupRef.items, item)
	mark_layout_dirty()
	return item
end

ui.info = function(groupRef, text, color)
	local item = { type = "info", text = text, color = color }
	table.insert(groupRef.items, item)
	mark_layout_dirty()
	return item
end

ui.spacer = function(groupRef, height)
	local item = { type = "spacer", height = math.max(0, height or config.space.x2) }
	table.insert(groupRef.items, item)
	mark_layout_dirty()
	return item
end

local _shadow_col = { r = 0, g = 0, b = 0, a = 8 }

local function shadow_color(alpha)
	local shadow_col = config.colors.chrome_shadow_soft or config.colors.card_shadow or { r = 0, g = 0, b = 0 }
	_shadow_col.r = shadow_col.r
	_shadow_col.g = shadow_col.g
	_shadow_col.b = shadow_col.b
	_shadow_col.a = math.max(0, math.floor(alpha or 0))
	return _shadow_col
end

local function shadow_alpha(scale, fallback)
	local card_shadow = config.colors.card_shadow
	local base = (card_shadow and card_shadow.a) or fallback or 120
	return math.max(0, math.floor(base * (scale or 1.0)))
end

local function render_depth_shadow(x, y, w, h, rounding, scale, proximity)
	local hover_t = animator.clamp01(proximity or 0.0)
	local far_alpha = shadow_alpha((scale or 1.0) * 0.1, 120)
	local near_alpha = shadow_alpha((scale or 1.0) * 0.22, 120)
	if near_alpha <= 0 and far_alpha <= 0 then
		return
	end

	local far_offset = config.space.x1_5 - ((config.space.x1_5 - config.space.x1) * hover_t)
	local near_offset = config.space.x1 - ((config.space.x1 * 0.45) * hover_t)
	local spread = math.max(1, math.floor(config.space.x1 * 0.35))
	if far_alpha > 0 then
		render_rect(
			x + far_offset - spread,
			y + far_offset - spread,
			w + (spread * 2),
			h + (spread * 2),
			shadow_color(far_alpha),
			rounding
		)
	end
	if near_alpha > 0 then
		render_rect(x + near_offset, y + near_offset, w, h, shadow_color(near_alpha), rounding)
	end
end

local function render_card_shadow(x, y, w, h, rounding)
	local alpha = shadow_alpha(0.16, 120)
	if alpha <= 0 then
		return
	end

	local offset = config.space.x1
	render_rect(x + offset, y + offset, w, h, shadow_color(alpha), rounding)
end

local function render_card(x, y, w, h, bg_col, border_col, rounding)
	local r = rounding or config.radius.md
	render_card_shadow(x, y, w, h, r)
	render_rect(x, y, w, h, bg_col or config.colors.bg_panel, r)
	render_outline(x, y, w, h, border_col or config.colors.border, 1, r)
end

local function render_background_tile(x, y, w, h)
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

	gui.push_clip(vec(x + ox, y + oy), vec(w, h))
	local draw_y = y
	while draw_y < y + h do
		local draw_x = x
		while draw_x < x + w do
			gui.image(image, vec(snap(draw_x + ox), snap(draw_y + oy)), image_scale, tint)
			draw_x = draw_x + tile_w
		end
		draw_y = draw_y + tile_h
	end
	gui.pop_clip()
end

local function button_variant_for(btn)
	if btn.color == "green" then
		return "success"
	end
	if btn.color == "danger" then
		return "danger"
	end
	if btn.color == "ghost" then
		return "ghost"
	end
	if btn.color == "primary" then
		return "primary"
	end

	local id = string.lower(tostring(btn.id or ""))
	if id == "" then
		return "outline"
	end

	if id:find("instant_finish", 1, true) or id == "cayo_tool_finish" then
		return "success"
	end

	if
		id:find("preset_copy", 1, true)
		or id:find("preset_refresh", 1, true)
		or id:find("preset_set_name", 1, true)
		or id:find("preset_name_clip", 1, true)
	then
		return "outline"
	end

	if id:find("preset_remove", 1, true) then
		return "ghost_danger"
	end

	if id:find("cooldown", 1, true) then
		return "danger"
	end

	if id:find("_tp_", 1, true) or id:find("teleport", 1, true) then
		return "outline"
	end

	if id == "doomsday_preset_apply" then
		return "outline"
	end

	if
		id:find("cuts_apply", 1, true)
		or id:find("cuts_reset", 1, true)
		or id:find("reset_cuts", 1, true)
		or id:find("_apply", 1, true)
		or id:find("preset_save", 1, true)
		or id:find("preset_load", 1, true)
	then
		return "primary"
	end

	return "outline"
end

local function dropdown_label_text(item)
	return tostring((item and item.label) or "")
end

local function dropdown_label_width(w)
	local pad_x = config.space.x3
	return math.max(1, (w or 0) - (pad_x * 2))
end

local function dropdown_label_height(item, w)
	return math.max(
		config.space.x4,
		math.ceil(
			measure_wrapped_text_height(dropdown_label_text(item), dropdown_label_width(w), config.font_scale_body)
		)
	)
end

local function dropdown_label_gap()
	return config.space.x1
end

local function get_dropdown_item_height(item, w)
	return config.space.x1 + dropdown_label_height(item, w) + dropdown_label_gap() + config.space.x9 + config.space.x2
end

local function get_dropdown_panel_width(item, min_w, max_w)
	local longest_w = 0
	local options = item and item.options or {}
	for i = 1, #options do
		local option_w = measure_text_width(options[i], config.font_scale_body)
		if option_w and option_w > longest_w then
			longest_w = option_w
		end
	end

	if longest_w <= 0 then
		return min_w
	end

	local text_padding = config.space.x6
	local scroll_padding = config.space.x3
	local desired_w = math.ceil(longest_w + text_padding + scroll_padding)
	return clamp(desired_w, min_w, math.max(min_w, max_w or min_w))
end

local BUTTON_COLOR_STYLES = {
	disabled = {
		normal = { bg = config.colors.danger, border = config.colors.danger, text = config.colors.text_on_accent },
		hover = {
			bg = config.colors.danger_hover,
			border = config.colors.danger_hover,
			text = config.colors.text_on_accent,
		},
	},
	primary = {
		normal = { bg = config.colors.accent, border = config.colors.accent, text = config.colors.text_on_accent },
		hover = {
			bg = config.colors.accent_hover,
			border = config.colors.accent_hover,
			text = config.colors.text_on_accent,
		},
	},
	success = {
		normal = { bg = config.colors.success, border = config.colors.success, text = config.colors.text_on_accent },
		hover = {
			bg = config.colors.success_hover,
			border = config.colors.success_hover,
			text = config.colors.text_on_accent,
		},
	},
	danger = {
		normal = { bg = config.colors.danger, border = config.colors.danger, text = config.colors.text_on_accent },
		hover = {
			bg = config.colors.danger_hover,
			border = config.colors.danger_hover,
			text = config.colors.text_on_accent,
		},
	},
	ghost = {
		normal = { bg = config.colors.transparent, border = config.colors.transparent, text = config.colors.text_main },
		hover = {
			bg = config.colors.bg_ghost_hover,
			border = config.colors.transparent,
			text = config.colors.text_main,
		},
	},
	ghost_danger = {
		normal = {
			bg = config.colors.transparent,
			border = config.colors.transparent,
			text = config.colors.danger_text,
		},
		hover = { bg = config.colors.danger_soft, border = config.colors.transparent, text = config.colors.danger_text },
	},
	outline = {
		normal = {
			bg = config.colors.bg_ghost_hover,
			border = config.colors.transparent,
			text = config.colors.text_main,
		},
		hover = { bg = config.colors.bg_panel, border = config.colors.transparent, text = config.colors.text_main },
	},
}

local HEIST_SUBTAB_NAMES = {
	"Settings",
	"Cayo",
	"Casino",
	"Doomsday",
	"Apartment",
	"Agency",
	"Auto Shop",
	"Salvage Yard",
	"Cluckin",
	"KnoWay",
}
local HEIST_SUBTAB_KEYS = {
	"info",
	"cayo",
	"casino",
	"doomsday",
	"apartment",
	"agency",
	"autoshop",
	"salvageyard",
	"cluckin",
	"knoway",
}

local BIZ_SUBTAB_NAMES = {
	"Bunker",
	"Moto Club",
	"Acid Lab",
	"Hangar",
	"Spec Cargo",
	"Nightclub",
	"Misc",
}
local BIZ_SUBTAB_KEYS = {
	"bunker",
	"mc",
	"acidlab",
	"hangar",
	"speccargo",
	"nightclub",
	"misc",
}
for _, v in ipairs(BIZ_SUBTAB_NAMES) do
	HEIST_SUBTAB_NAMES[#HEIST_SUBTAB_NAMES + 1] = v
end
for _, v in ipairs(BIZ_SUBTAB_KEYS) do
	HEIST_SUBTAB_KEYS[#HEIST_SUBTAB_KEYS + 1] = v
end

local heist_subtab_loader = nil
local heist_subtab_load_state = {}

local DRAWER_HEIST_KEYS = {
	cayo = true,
	casino = true,
	doomsday = true,
	apartment = true,
	agency = true,
	autoshop = true,
	salvageyard = true,
	cluckin = true,
	knoway = true,
}

local DRAWER_GENERAL_KEYS = {
	info = true,
	faq = true,
}

-- Natural drawer height = enough vertical room to render every subtab row at
-- its configured item_h, plus section headers and gaps. We use this as the
-- min resize height so users can't shrink the menu shorter than its own nav
-- list, which previously made the drawer clip rows and look empty.
local function compute_drawer_min_menu_height()
	local drawer_cfg = config.drawer or {}
	local item_h = drawer_cfg.item_h or config.space.x8
	local header_row_h = config.space.x7
	local item_gap = config.space.x1
	local top_pad = config.space.x3
	local bot_pad = config.space.x3

	local item_count = 0
	local has_general, has_heist, has_business = false, false, false
	for i = 1, #HEIST_SUBTAB_KEYS do
		local key = HEIST_SUBTAB_KEYS[i]
		item_count = item_count + 1
		if DRAWER_GENERAL_KEYS[key] then
			has_general = true
		elseif DRAWER_HEIST_KEYS[key] then
			has_heist = true
		else
			has_business = true
		end
	end
	local header_count = (has_general and 1 or 0) + (has_heist and 1 or 0) + (has_business and 1 or 0)
	local total_rows = item_count + header_count
	if total_rows <= 0 then
		return 0
	end
	local list_h = (item_count * item_h) + (header_count * header_row_h) + (math.max(0, total_rows - 1) * item_gap)
	return list_h + top_pad + bot_pad
end

local function refresh_min_menu_height_for_drawer()
	local needed = compute_drawer_min_menu_height()
	if needed <= 0 then
		return
	end
	config.resize.min_menu_height = needed
	if (config.resize.max_menu_height or 0) < needed then
		config.resize.max_menu_height = needed
	end
	if config.menu_height < needed then
		local prev_h = config.menu_height
		config.menu_height = needed
		-- Re-center vertically so the bumped height doesn't push the menu off-screen.
		config.origin_y = config.origin_y + math.floor((prev_h - needed) / 2)
	end
end

function ui.set_heist_subtabs(names, keys)
	if type(names) ~= "table" or type(keys) ~= "table" or #names ~= #keys or #names == 0 then
		return false
	end
	for i = #HEIST_SUBTAB_NAMES, 1, -1 do
		HEIST_SUBTAB_NAMES[i] = nil
	end
	for i = #HEIST_SUBTAB_KEYS, 1, -1 do
		HEIST_SUBTAB_KEYS[i] = nil
	end
	for i = 1, #names do
		HEIST_SUBTAB_NAMES[i] = names[i]
		HEIST_SUBTAB_KEYS[i] = keys[i]
	end
	heist_subtab_load_state = {}
	refresh_min_menu_height_for_drawer()
	mark_layout_dirty()
	return true
end

function ui.set_heist_subtab_loader(loader)
	heist_subtab_loader = type(loader) == "function" and loader or nil
	heist_subtab_load_state = {}
	return heist_subtab_loader ~= nil
end

local function ensure_heist_subtab_loaded(index)
	if type(heist_subtab_loader) ~= "function" then
		return false
	end
	local key = HEIST_SUBTAB_KEYS[index]
	if not key or heist_subtab_load_state[key] then
		return false
	end

	local ok, err = pcall(heist_subtab_loader, key)
	heist_subtab_load_state[key] = ok and true or "failed"
	if not ok then
		notify_core.push("notify.ui_callback_error_title", "notify.ui_callback_error", 4500, {
			kind = "subtab_loader",
			id = tostring(key),
			error = tostring(err),
		})
	end
	return ok
end

local function clear_array(tbl)
	for i = #tbl, 1, -1 do
		tbl[i] = nil
	end
end

local render_cache = {
	active_groups = {},
	active_groups_tab = nil,
	active_groups_subtab = nil,
	active_groups_revision = -1,
	col_x = {},
	groups_by_column = { {}, {}, {} },
	ordered_groups = {},
	pending_dropdowns = {},
	layout_tab_id = nil,
	layout_selected_heist_key = nil,
	layout_column_count = nil,
	layout_col_w = nil,
	layout_revision = -1,
	layout_dirty = true,
	group_heights = {},
}
render_cache.drawer_overlay_col = { r = 0, g = 0, b = 0, a = 0 }
render_cache.drawer_active_bg_col = { r = 255, g = 255, b = 255, a = 255 }
render_cache.drawer_active_text_col = { r = 255, g = 255, b = 255, a = 255 }

local function get_active_groups()
	local activeGroups = render_cache.active_groups
	local currentTab = ui.currentTab
	local selected_heist_key = nil

	if currentTab and currentTab.id == "heist" then
		selected_heist_key = HEIST_SUBTAB_KEYS[state.heist_subtab]
	end

	if
		render_cache.active_groups_tab == currentTab
		and render_cache.active_groups_subtab == selected_heist_key
		and render_cache.active_groups_revision == layout_cache_revision
	then
		return activeGroups, selected_heist_key
	end

	clear_array(activeGroups)
	if currentTab then
		if currentTab.id == "heist" then
			for i = 1, #currentTab.groups do
				local group = currentTab.groups[i]
				if selected_heist_key and group.heist_subtab == selected_heist_key then
					activeGroups[#activeGroups + 1] = group
				end
			end
		else
			for i = 1, #currentTab.groups do
				activeGroups[#activeGroups + 1] = currentTab.groups[i]
			end
		end
	end

	render_cache.active_groups_tab = currentTab
	render_cache.active_groups_subtab = selected_heist_key
	render_cache.active_groups_revision = layout_cache_revision
	return activeGroups, selected_heist_key
end

local function update_drawer_animation()
	local drawer = state.drawer
	if type(drawer) ~= "table" then
		drawer = { open = false, progress = 0.0, target = 0.0 }
		state.drawer = drawer
	end

	drawer.target = drawer.open and 1.0 or 0.0
	drawer.progress = animator.to(
		"drawer_progress",
		drawer.target,
		animator.motion_speed(config.motion.drawer_speed, config.motion.speed_base or 0.16)
	)
	return drawer.progress
end

local function get_hamburger_rect(bodyY)
	local drawer_cfg = config.drawer or {}
	local size = drawer_cfg.button_size or config.space.x6
	local header_h = config.header_height or config.content_margin
	local top_gap = math.max(0, math.floor((header_h - size) / 2))
	return config.origin_x + config.content_margin, bodyY + top_gap, size, size
end

local function set_drawer_open(open)
	if type(state.drawer) ~= "table" then
		state.drawer = { open = false, progress = 0.0, target = 0.0 }
	end
	state.drawer.open = open == true
	state.drawer.target = state.drawer.open and 1.0 or 0.0
end

local function select_heist_subtab(index)
	if not HEIST_SUBTAB_KEYS[index] then
		return false
	end
	if state.heist_subtab ~= index then
		state.heist_subtab = index
		state.content_transition.subtab = index
		state.content_transition.progress = 0.0
		animator.values["content_transition"] = { v = 0.0, seen = animator.frame }
	end
	ensure_heist_subtab_loaded(index)
	state.scroll.y = 0
	state.scroll.is_dragging = false
	state.dragging_slider = nil
	state.window.is_dragging = false
	state.window.is_resizing = false
	set_drawer_open(false)
	return true
end

local function build_drawer_rows(rows)
	clear_array(rows)

	local heist_start = nil
	local business_start = nil
	local general_start = nil
	for i = 1, #HEIST_SUBTAB_KEYS do
		local key = HEIST_SUBTAB_KEYS[i]
		if DRAWER_GENERAL_KEYS[key] then
			if not general_start then
				general_start = #rows + 1
				rows[#rows + 1] = { type = "header", label = i18n.t("drawer.section.general") }
			end
			rows[#rows + 1] = { type = "item", index = i }
		elseif DRAWER_HEIST_KEYS[key] then
			if not heist_start then
				heist_start = #rows + 1
				rows[#rows + 1] = { type = "header", label = i18n.t("drawer.section.heists") }
			end
			rows[#rows + 1] = { type = "item", index = i }
		else
			if not business_start then
				business_start = #rows + 1
				rows[#rows + 1] = { type = "header", label = i18n.t("drawer.section.businesses") }
			end
			rows[#rows + 1] = { type = "item", index = i }
		end
	end
end

local function render_hamburger_button(x, y, size, hovered)
	local bg = hovered and config.colors.bg_control_hover or config.colors.bg_control
	render_rect(x, y, size, size, bg, config.radius.md)
	render_outline(x, y, size, size, config.colors.border, 1, config.radius.md)

	local line_w = math.max(1, size - config.space.x3)
	local line_h = (config.drawer and config.drawer.line_thickness) or 2
	local line_x = x + math.floor((size - line_w) / 2)
	local center_y = y + math.floor(size / 2)
	local gap = math.max(line_h + 1, math.floor(size / 5))
	render_rect(line_x, center_y - gap, line_w, line_h, config.colors.text_main, config.radius.full)
	render_rect(line_x, center_y, line_w, line_h, config.colors.text_main, config.radius.full)
	render_rect(line_x, center_y + gap, line_w, line_h, config.colors.text_main, config.radius.full)
end

local function render_drawer(bodyY, bodyH, drawer_t)
	if drawer_t <= 0.01 then
		return
	end

	local drawer_cfg = config.drawer or {}
	local drawer_w = math.min(drawer_cfg.width or config.space.x15 * 4, config.menu_width - config.content_margin)
	local drawer_x = config.origin_x - drawer_w + (drawer_w * drawer_t)
	local overlay_col = render_cache.drawer_overlay_col
	overlay_col.a = math.floor((drawer_cfg.overlay_alpha or 90) * drawer_t)
	render_rect(config.origin_x, bodyY, config.menu_width, bodyH, overlay_col, config.radius.xl)

	local ox, oy = state._frame_ox, state._frame_oy
	gui.push_clip(vec(config.origin_x + ox, bodyY + oy), vec(config.menu_width, bodyH))
	render_card(drawer_x, bodyY, drawer_w, bodyH, config.colors.bg_panel, config.colors.border_strong, config.radius.xl)

	local rows = render_cache.drawer_rows or {}
	render_cache.drawer_rows = rows
	build_drawer_rows(rows)

	local header_h = config.space.x7
	local item_h = drawer_cfg.item_h or config.space.x8
	local item_gap = config.space.x1
	local item_x = drawer_x + config.space.x2
	local item_w = drawer_w - config.space.x4
	local item_y = bodyY + config.space.x3
	local list_bottom = bodyY + bodyH - config.space.x3
	local list_available_h = math.max(1, list_bottom - item_y)
	local item_count = 0
	local header_count = 0
	for i = 1, #rows do
		if rows[i].type == "header" then
			header_count = header_count + 1
		else
			item_count = item_count + 1
		end
	end
	local full_list_h = (item_count * item_h) + (header_count * header_h) + (math.max(0, #rows - 1) * item_gap)
	if full_list_h > list_available_h then
		item_h = math.max(
			config.space.x6,
			math.floor(
				(list_available_h - (header_count * header_h) - (math.max(0, #rows - 1) * item_gap)) / item_count
			)
		)
	end
	for row_index = 1, #rows do
		local row = rows[row_index]
		local row_h = row.type == "header" and header_h or item_h
		if item_y + row_h > list_bottom then
			break
		end

		if row.type == "header" then
			local header_label = text_with_ellipsis(row.label, item_w - config.space.x3, config.font_scale_small)
			render_text_in_rect(
				header_label,
				item_x + config.space.x2,
				item_y,
				item_w - config.space.x3,
				row_h,
				config.font_scale_small,
				config.colors.text_sec,
				"left",
				true
			)
			local line_y = item_y + row_h - config.space.x1
			render_rect(
				item_x + config.space.x2,
				line_y,
				item_w - config.space.x4,
				config.space.x1,
				config.colors.border,
				config.radius.full
			)
			item_y = item_y + row_h + item_gap
			goto continue_drawer_row
		end

		local i = row.index
		local label = text_with_ellipsis(HEIST_SUBTAB_NAMES[i], item_w - config.space.x6, config.font_scale_body)
		local is_active = state.heist_subtab == i
		local hovered = (not state.active_dropdown) and is_hovered(item_x, item_y, item_w, row_h)
		local bg_col = nil
		local text_col = config.colors.text_main

		if is_active then
			bg_col = render_cache.drawer_active_bg_col
			animator.blend_color(config.colors.bg_control, config.colors.accent, drawer_t, bg_col)
			text_col = render_cache.drawer_active_text_col
			animator.blend_color(config.colors.text_main, config.colors.text_on_accent, drawer_t, text_col)
		elseif hovered then
			bg_col = config.colors.bg_control_hover
		end

		if bg_col then
			render_rect(item_x, item_y, item_w, row_h, bg_col, config.radius.md)
		end

		render_text_in_rect(
			label,
			item_x + config.space.x3,
			item_y,
			item_w - config.space.x6,
			row_h,
			config.font_scale_body,
			text_col,
			"left",
			true
		)

		if hovered and state.mouse.clicked and drawer_t > 0.75 then
			select_heist_subtab(i)
		end

		item_y = item_y + row_h + item_gap
		::continue_drawer_row::
	end
	gui.pop_clip()

	if
		state.mouse.clicked
		and not is_hovered(drawer_x, bodyY, drawer_w, bodyH)
		and not state.window.is_dragging
		and not state.window.is_resizing
	then
		set_drawer_open(false)
	end
end

local function flatten_groups_by_order(activeGroups, subtab_key, column_count)
	local ordered = render_cache.ordered_groups
	clear_array(ordered)

	for i, group in ipairs(activeGroups) do
		local rank = 1000000 + i
		local pref_col = nil
		local pref_order = nil
		local spec = group_layouts.lookup(subtab_key, group, column_count)
		if spec then
			rank = ((spec.col - 1) * 1000) + spec.order
			pref_col = spec.col
			pref_order = spec.order
		end
		ordered[#ordered + 1] = {
			group = group,
			rank = rank,
			idx = i,
			pref_col = pref_col,
			pref_order = pref_order,
		}
	end

	table.sort(ordered, function(a, b)
		if a.rank == b.rank then
			return a.idx < b.idx
		end
		return a.rank < b.rank
	end)

	return ordered
end

local function group_animation_key(group, subkey, order)
	return "group:" .. subkey .. ":" .. tostring(order or 0) .. ":" .. tostring(group and group.label or "")
end

local function group_animation_keys(group, subkey, order)
	local key = group_animation_key(group, subkey, order)
	return key, key .. ":x", key .. ":y"
end

local function group_column_entry(group, order, h, animation_subkey)
	local anim_key, anim_key_x, anim_key_y = group_animation_keys(group, animation_subkey, order)
	return {
		group = group,
		order = order,
		h = h,
		anim_key = anim_key,
		anim_key_x = anim_key_x,
		anim_key_y = anim_key_y,
	}
end

local function get_item_height(item, col_w)
	if item.hidden then
		return 0
	end
	if item.type == "toggle" then
		return config.item_height.toggle
	elseif item.type == "button" then
		if col_w and col_w > 0 then
			local pad_x = config.space.x3
			local n = button_line_count(item.label, col_w - (pad_x * 2))
			return button_h_from_lines(n)
		end
		return config.item_height.button
	elseif item.type == "button_pair" then
		if col_w and col_w > 0 then
			local leftW, rightW = button_pair_half_widths(col_w)
			local nl = button_line_count(item.left and item.left.label, leftW)
			local nr = button_line_count(item.right and item.right.label, rightW)
			return button_h_from_lines(math.max(nl, nr))
		end
		return config.item_height.button
	elseif item.type == "slider" then
		return config.item_height.slider
	elseif item.type == "dropdown" then
		return get_dropdown_item_height(item, col_w)
	elseif item.type == "label" then
		return config.space.x6
	elseif item.type == "info" then
		local pad_x = config.space.x3
		local max_w = (col_w or 0) - (pad_x * 2)
		if max_w <= 0 then
			return config.space.x6
		end
		return info_item_height(info_item_text(item), max_w, config.font_scale_small)
	elseif item.type == "spacer" then
		return math.max(0, item.height or 0)
	end
	return 0
end

local function is_auto_pairable_button(item)
	return type(item) == "table" and item.type == "button" and not item.hidden
end

local function is_auto_pairable_dropdown(item)
	return type(item) == "table" and item.type == "dropdown" and not item.hidden
end

local function cut_control_base_id(item)
	if type(item) ~= "table" or type(item.id) ~= "string" or not item.id:find("_cut", 1, true) then
		return nil
	end
	if item.type == "toggle" and item.id:sub(-8) == "_enabled" then
		return item.id:sub(1, -9)
	elseif item.type == "slider" then
		return item.id
	end
	return nil
end

local function is_cut_slider_toggle_pair(left, right)
	local left_base = cut_control_base_id(left)
	local right_base = cut_control_base_id(right)
	if not left_base or left_base ~= right_base then
		return false
	end
	return (left.type == "slider" and right.type == "toggle") or (left.type == "toggle" and right.type == "slider")
end

local function next_auto_pair_button_index(items, start_index)
	local i = start_index + 1
	while i <= #items do
		local item = items[i]
		if not item.hidden then
			if is_auto_pairable_button(item) then
				return i
			end
			return nil
		end
		i = i + 1
	end
	return nil
end

local function next_auto_pair_dropdown_index(items, start_index)
	local i = start_index + 1
	while i <= #items do
		local item = items[i]
		if not item.hidden then
			if is_auto_pairable_dropdown(item) then
				return i
			end
			return nil
		end
		i = i + 1
	end
	return nil
end

local function next_cut_control_pair_index(items, start_index)
	local item = items[start_index]
	local i = start_index + 1
	while i <= #items do
		local next_item = items[i]
		if not next_item.hidden then
			if is_cut_slider_toggle_pair(item, next_item) then
				return i
			end
			return nil
		end
		i = i + 1
	end
	return nil
end

local function get_cut_control_pair_height()
	return config.cut_pair_height or (config.item_height.slider + config.item_height.toggle)
end

local function get_group_actual_height(group, col_w)
	local cache_col_w = col_w or 0
	if
		group._cached_h
		and group._cached_layout_revision == layout_cache_revision
		and group._cached_col_w == cache_col_w
	then
		return group._cached_h
	end

	local h = config.item_height.header_padding + config.space.x5
	local items = group and group.items or {}
	local visible_count = 0
	local i = 1

	while i <= #items do
		local item = items[i]
		local item_h = get_item_height(item, col_w)
		local pair_index = nil
		if item_h > 0 then
			pair_index = next_cut_control_pair_index(items, i)
			if pair_index then
				item_h = get_cut_control_pair_height()
			end
		end
		if item_h > 0 then
			if visible_count > 0 then
				h = h + (config.item_gap or 0)
			end
			h = h + item_h
			visible_count = visible_count + 1
		end

		if pair_index then
			i = pair_index
		elseif is_auto_pairable_button(item) then
			local pair_index = next_auto_pair_button_index(items, i)
			if pair_index then
				local pair_item = items[pair_index]
				if col_w and col_w > 0 then
					local leftW, rightW = button_pair_half_widths(col_w)
					local nl = button_line_count(item.label, leftW)
					local nr = button_line_count(pair_item.label, rightW)
					local pair_h = button_h_from_lines(math.max(nl, nr))
					h = h - item_h + pair_h
				end
				i = pair_index
			end
		elseif is_auto_pairable_dropdown(item) then
			local pair_index = next_auto_pair_dropdown_index(items, i)
			if pair_index then
				local pair_item = items[pair_index]
				if col_w and col_w > 0 then
					local leftW, rightW = button_pair_half_widths(col_w)
					local pair_h = math.max(
						get_dropdown_item_height(item, leftW + (config.space.x3 * 2)),
						get_dropdown_item_height(pair_item, rightW + (config.space.x3 * 2))
					)
					h = h - item_h + pair_h
				end
				i = pair_index
			end
		end
		i = i + 1
	end

	local min_h = (group and group.rect and group.rect.h) or 0
	if h < min_h then
		h = min_h
	end
	group._cached_h = h
	group._cached_layout_revision = layout_cache_revision
	group._cached_col_w = cache_col_w
	return h
end

-- Strict explicit-layout placement. Every card's column and within-column
-- order come from group_layouts.lookup (via flatten_groups_by_order). There
-- is no dynamic flow / linear-partition fallback: if a tab's layout map is
-- missing entries, those groups deterministically pile up at the bottom of
-- col 1 instead of being silently rebalanced.
local UNMATCHED_PREF_ORDER_OFFSET = 1e9

local function distribute_groups_by_column(flattened, groups_by_column, column_count, group_heights, animation_subkey)
	for col = 1, column_count do
		clear_array(groups_by_column[col])
	end

	local total = #flattened
	if total == 0 then
		return
	end

	local cols = math.max(1, math.min(column_count, total))

	if cols == 1 then
		for i = 1, total do
			local entry = flattened[i]
			groups_by_column[1][#groups_by_column[1] + 1] =
				group_column_entry(entry.group, i, group_heights[entry.group], animation_subkey)
		end
		return
	end

	local column_entries = {}
	for col = 1, cols do
		column_entries[col] = {}
	end

	for i = 1, total do
		local entry = flattened[i]
		local target_col = tonumber(entry.pref_col)
		local pref_order
		if target_col == nil then
			target_col = 1
			pref_order = UNMATCHED_PREF_ORDER_OFFSET + i
		else
			if target_col < 1 then
				target_col = 1
			elseif target_col > cols then
				target_col = cols
			end
			pref_order = tonumber(entry.pref_order) or (UNMATCHED_PREF_ORDER_OFFSET + i)
		end

		column_entries[target_col][#column_entries[target_col] + 1] = {
			entry = entry,
			pref_order = pref_order,
			seq_order = i,
		}
	end

	for col = 1, cols do
		table.sort(column_entries[col], function(a, b)
			if a.pref_order == b.pref_order then
				return a.seq_order < b.seq_order
			end
			return a.pref_order < b.pref_order
		end)

		for _, col_entry in ipairs(column_entries[col]) do
			local entry = col_entry.entry
			groups_by_column[col][#groups_by_column[col] + 1] =
				group_column_entry(entry.group, col_entry.seq_order, group_heights[entry.group], animation_subkey)
		end
	end
end

local toggle_track_color = { r = 148, g = 163, b = 184, a = 255 }
local slider_glow_color = { r = 255, g = 255, b = 255, a = 0 }

local function button_colors_for(btn, hovered)
	if btn.disabled then
		return hovered and BUTTON_COLOR_STYLES.disabled.hover or BUTTON_COLOR_STYLES.disabled.normal
	end

	local variant = button_variant_for(btn)
	if variant == "primary" then
		return hovered and BUTTON_COLOR_STYLES.primary.hover or BUTTON_COLOR_STYLES.primary.normal
	elseif variant == "success" then
		return hovered and BUTTON_COLOR_STYLES.success.hover or BUTTON_COLOR_STYLES.success.normal
	elseif variant == "danger" then
		return hovered and BUTTON_COLOR_STYLES.danger.hover or BUTTON_COLOR_STYLES.danger.normal
	elseif variant == "ghost" then
		return hovered and BUTTON_COLOR_STYLES.ghost.hover or BUTTON_COLOR_STYLES.ghost.normal
	elseif variant == "ghost_danger" then
		return hovered and BUTTON_COLOR_STYLES.ghost_danger.hover or BUTTON_COLOR_STYLES.ghost_danger.normal
	else
		return hovered and BUTTON_COLOR_STYLES.outline.hover or BUTTON_COLOR_STYLES.outline.normal
	end
end

local function safe_call_ui_handler(kind, id, fn, ...)
	if type(fn) ~= "function" then
		return true
	end
	local ok, err = pcall(fn, ...)
	if not ok then
		notify_core.push("notify.ui_callback_error_title", "notify.ui_callback_error", 4500, {
			kind = tostring(kind),
			id = tostring(id),
			error = tostring(err),
		})
	end
	return ok
end

-- ---------------------------------------------------------
-- 4. Rendering Implementations
-- ---------------------------------------------------------

local function draw_toggle_item(item, x, y, w, original_y)
	local pad_x = config.space.x3
	local hitbox_h = config.item_height.toggle - config.space.x1
	local disabled = item.disabled and true or false
	local hovered = (not disabled) and not state.active_dropdown and is_hovered_content(x, original_y, w, hitbox_h)

	if hovered and state.mouse.clicked and not state.active_dropdown then
		item.state = not item.state
		if item.onChange then
			safe_call_ui_handler("toggle", item.id, item.onChange, item.state)
		end
		state.window.is_dragging = false
	end

	-- Animation
	local target = item.state and 1.0 or 0.0
	if not item.anim then
		item.anim = target
	end
	item.anim = lerp(item.anim, target, 0.15)

	local switchW = config.space.x12
	local switchH = config.space.x6
	local switchX = x + w - switchW - pad_x
	local switchY = y + config.space.x3

	local inactiveCol = config.colors.neutral_muted or config.colors.text_dim
	local activeCol = disabled and inactiveCol or config.colors.accent

	local trackR = math.floor(inactiveCol.r + (activeCol.r - inactiveCol.r) * item.anim)
	local trackG = math.floor(inactiveCol.g + (activeCol.g - inactiveCol.g) * item.anim)
	local trackB = math.floor(inactiveCol.b + (activeCol.b - inactiveCol.b) * item.anim)
	toggle_track_color.r = trackR
	toggle_track_color.g = trackG
	toggle_track_color.b = trackB
	toggle_track_color.a = inactiveCol.a or 255

	render_rect(switchX, switchY, switchW, switchH, toggle_track_color, config.radius.full)
	render_outline(
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
	local thumbX = lerp(minX, maxX, item.anim)
	local thumbY = switchY + (switchH - thumbSize) / 2

	render_rect(
		thumbX,
		thumbY,
		thumbSize,
		thumbSize,
		disabled and config.colors.bg_panel or config.colors.white,
		config.radius.full
	)
	render_outline(
		thumbX,
		thumbY,
		thumbSize,
		thumbSize,
		disabled and config.colors.border or config.colors.accent_hover,
		config.control.toggle_thumb_border_thickness,
		config.radius.full
	)

	-- Center text vertically with switch
	local textY = switchY + (switchH - config.font_scale_body) / 2
	render_text(
		item.label,
		x + pad_x,
		textY,
		config.font_scale_body,
		disabled and config.colors.border or config.colors.text_main
	)
end

local function is_button_hovered(btnX, btnY, btnW, btnH)
	if state.active_dropdown then
		return false
	end

	if is_hovered_content(btnX, btnY, btnW, btnH) then
		return true
	end

	local ox, oy = state._frame_ox, state._frame_oy
	return input.is_mouse_within(vec(btnX + ox, btnY + oy), vec(btnW, btnH))
end

local function draw_button_surface(btn, btnX, btnY, btnW, btnH, disabled_message)
	local hovered = is_button_hovered(btnX, btnY, btnW, btnH)
	local shadow_t = animator.to(
		"button_shadow:" .. tostring(btn.id or btn.label or ""),
		hovered and 1.0 or 0.0,
		animator.motion_speed(config.motion.speed_fast, 0.24)
	)
	render_depth_shadow(btnX, btnY, btnW, btnH, config.radius.md, 0.65 + (0.25 * shadow_t), shadow_t)

	if hovered and state.mouse.clicked and not state.active_dropdown then
		if btn.disabled then
			if disabled_message then
				notify_core.push("notify.error_title", disabled_message, 3000)
			end
		elseif btn.onClick then
			safe_call_ui_handler("button", btn.id, btn.onClick)
		end
		state.window.is_dragging = false
	end

	local style = button_colors_for(btn, hovered)
	render_rect(btnX, btnY, btnW, btnH, style.bg, config.radius.md)
	if style.border.a and style.border.a > 0 then
		render_outline(btnX, btnY, btnW, btnH, style.border, 1, config.radius.md)
	end
	render_rect(btnX + 1, btnY + 1, math.max(1, btnW - 2), 1, {
		r = (config.colors.chrome_highlight_soft or config.colors.text_on_accent).r,
		g = (config.colors.chrome_highlight_soft or config.colors.text_on_accent).g,
		b = (config.colors.chrome_highlight_soft or config.colors.text_on_accent).b,
		a = hovered and 16 or 8,
	}, config.radius.full)

	return style
end

local BUTTON_LABEL_SCALE = 1.0

local function render_button_label(label, btnX, btnY, btnW, btnH, textColor)
	local pad_x = config.space.x3
	local draw_size = config.font_scale_small * BUTTON_LABEL_SCALE
	local max_w = math.max(1, btnW - (pad_x * 2))
	local text = tostring(label or "")
	local text_h = measure_wrapped_text_height(text, max_w, draw_size)
	local text_y = btnY + math.floor((btnH - text_h) / 2)
	local text_x = btnX + (btnW / 2)

	if gui.push_clip and gui.pop_clip then
		local ox, oy = state._frame_ox, state._frame_oy
		gui.push_clip(vec(btnX + ox, btnY + oy), vec(btnW, btnH))
		render_wrapped_text(text, text_x, text_y, max_w, draw_size, textColor, "center")
		gui.pop_clip()
	else
		render_wrapped_text(text, text_x, text_y, max_w, draw_size, textColor, "center")
	end
end

local function draw_button_item(item, x, y, w)
	local pad_x = config.space.x3
	local btnW = w - (pad_x * 2)
	local btnX = x + pad_x
	local btnY = y + config.space.x1
	local n = button_line_count(item.label, btnW)
	local btnH = button_h_from_lines(n) - config.space.x1

	local style = draw_button_surface(item, btnX, btnY, btnW, btnH, "ui.disabled.instant_finish")
	render_button_label(item.label, btnX, btnY, btnW, btnH, style.text)
end

local function draw_button_pair_item(item, x, y, w)
	local pad_x = config.space.x3
	local baseX = x + pad_x
	local btnY = y + config.space.x1
	local leftW, rightW = button_pair_half_widths(w)
	local nl = button_line_count(item.left and item.left.label, leftW)
	local nr = button_line_count(item.right and item.right.label, rightW)
	local btnH = button_h_from_lines(math.max(nl, nr)) - config.space.x1
	local gap = config.space.x2_5

	local function draw_half(btn, btnX, btnW)
		local style = draw_button_surface(btn, btnX, btnY, btnW, btnH, "ui.disabled.action")
		render_button_label(btn.label, btnX, btnY, btnW, btnH, style.text)
	end

	draw_half(item.left, baseX, leftW)
	draw_half(item.right, baseX + leftW + gap, rightW)
end

local function draw_slider_item(item, x, y, w, original_y)
	local pad_x = config.space.x3
	local barH = math.max(3, config.space.x1 + 1)
	local barY = y + config.space.x8
	local target = (state.dragging_slider == item.id) and 1.0 or 0.0
	if not item.anim then
		item.anim = 0.0
	end
	item.anim = lerp(item.anim, target, 0.2)

	local baseSize = config.control.slider_thumb_base
	local growSize = config.control.slider_thumb_grow
	local thumbSize = math.floor(baseSize + (growSize * item.anim))
	local thumbInset = thumbSize / 2
	local trackX = x + pad_x + thumbInset
	local trackW = math.max(1, w - (pad_x * 2) - thumbSize)
	local barX = trackX
	local barW = trackW

	local hovered = (not state.active_dropdown) and is_hovered_content(x, original_y, w, config.item_height.slider)

	if hovered and state.mouse.clicked and not state.active_dropdown then
		state.dragging_slider = item.id
		state.window.is_dragging = false -- Prevent window dragging when slider clicked
	end

	if state.dragging_slider == item.id and state.mouse.down then
		local mx = state.mouse.x
		local ox = state._frame_ox
		local relative_mx = mx - ox
		local ratio = math.max(0, math.min(1, (relative_mx - trackX) / trackW))
		local rawValue = item.min + ratio * (item.max - item.min)
		local prev_value = item.value
		local next_value

		-- Round to step if specified (e.g., 5 for cuts sliders)
		if item.step and item.step > 0 then
			next_value = math.floor((rawValue + item.step / 2) / item.step) * item.step
		else
			next_value = rawValue
		end

		if next_value ~= prev_value then
			item.value = next_value
			if item.onChange then
				safe_call_ui_handler("slider", item.id, item.onChange, item.value)
			end
		end
	end

	render_text(item.label, x + pad_x, y + config.space.x1, config.font_scale_body, config.colors.text_main)
	-- Display integer value (no decimals)
	local displayValue = math.floor(item.value)
	render_text(
		tostring(displayValue),
		x + w - pad_x - thumbInset,
		y + config.space.x1,
		config.font_scale_body,
		config.colors.accent,
		"right"
	)

	render_rect(barX, barY, barW, barH, config.colors.bg_control, config.radius.full)

	local fillRatio = (item.value - item.min) / (item.max - item.min)
	if fillRatio > 0 then
		render_rect(barX, barY, barW * fillRatio, barH, config.colors.accent, config.radius.full)
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
		render_rect(glowX, glowY, glowSize, glowSize, slider_glow_color, glowSize / 2)
	end

	-- Main circle
	render_rect(thumbX, thumbY, thumbSize, thumbSize, config.colors.text_on_accent, config.radius.full)
	render_outline(thumbX, thumbY, thumbSize, thumbSize, config.colors.accent, 1, config.radius.full)
end

local function draw_dropdown_item(item, x, y, w, original_y)
	local pad_x = config.space.x3
	local available_w = math.max(1, w - (pad_x * 2))
	local boxW = available_w
	local boxH = config.space.x9
	local boxX = x + pad_x
	local label_h = dropdown_label_height(item, w)
	local boxY = y + config.space.x1 + label_h + dropdown_label_gap()

	local is_active_dropdown = (state.active_dropdown == item.id)
	local allow_hover = (not state.active_dropdown) or is_active_dropdown
	local hovered = allow_hover and is_hovered_content(x, original_y, w, get_dropdown_item_height(item, w))

	if hovered and state.mouse.clicked then
		state.window.is_dragging = false -- Prevent window dragging
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

	local label_y = y + config.space.x1
	render_wrapped_text(
		dropdown_label_text(item),
		x + pad_x,
		label_y,
		available_w,
		config.font_scale_body,
		config.colors.text_main
	)

	local box_active = hovered or (open_t > 0.01)
	local boxBg = box_active and config.colors.accent or config.colors.bg_control
	local boxBorder = box_active and config.colors.accent_hover or config.colors.border
	local boxText = box_active and config.colors.text_on_accent or config.colors.text_sec
	local boxArrow = box_active and config.colors.text_on_accent or config.colors.text_dim
	local shadow_t = animator.to(
		"dropdown_shadow:" .. tostring(item.id or item.label or ""),
		box_active and 1.0 or 0.0,
		animator.motion_speed(config.motion.speed_fast, 0.24)
	)
	render_depth_shadow(boxX, boxY, boxW, boxH, config.radius.md, 0.55 + (0.25 * shadow_t), shadow_t)
	render_rect(boxX, boxY, boxW, boxH, boxBg, config.radius.md)
	render_outline(boxX, boxY, boxW, boxH, boxBorder, 1, config.radius.md)
	local selected = item.options[item.value] or ""
	local selected_max_w = boxW - config.space.x9
	local selected_text = text_with_ellipsis(selected, selected_max_w, config.font_scale_body)
	local sel_y = centered_text_y(boxY, boxH, selected_text, config.font_scale_body)
	render_text(selected_text, boxX + config.space.x3, sel_y, config.font_scale_body, boxText)

	-- Dropdown Arrow (ASCII-safe frames to simulate rotation)
	local arrowFrames = { "v", ">", "^" }
	local arrowIdx = 1 + math.floor((open_t or 0.0) * (#arrowFrames - 1) + 0.5)
	if arrowIdx < 1 then
		arrowIdx = 1
	end
	if arrowIdx > #arrowFrames then
		arrowIdx = #arrowFrames
	end
	local arrow_glyph = arrowFrames[arrowIdx]
	local arrow_y = centered_text_y(boxY, boxH, arrow_glyph, config.font_scale_small)
	render_text(arrow_glyph, boxX + boxW - config.space.x4, arrow_y, config.font_scale_small, boxArrow)

	if open_t > 0.01 then
		return {
			item = item,
			x = boxX,
			y = boxY + boxH + config.space.x1,
			w = boxW,
			control_y = boxY,
			control_h = boxH,
			open_t = open_t,
			interactive = (target_open > 0.5) and (open_t > 0.95),
		}
	end
end

local function draw_label_item(item, x, y, pad_x, group_w)
	local labelCol = item.color or config.colors.text_sec
	local text = item.text
	if group_w then
		local max_w = group_w - (pad_x * 2)
		if max_w > 0 then
			text = text_with_ellipsis(text, max_w, config.font_scale_small)
		end
	end
	render_text(text, x + pad_x, y + config.space.x3, config.font_scale_small, labelCol)
	return y + config.space.x6
end

local function draw_info_item(item, x, y, pad_x, group_w)
	local text_col = item.color or config.colors.text_sec
	local scale = config.font_scale_small
	local max_w = group_w - (pad_x * 2)
	local text = info_item_text(item)
	local item_h = info_item_height(text, max_w, scale)

	render_wrapped_text(text, x + pad_x, y + info_item_pad_top(), max_w, scale, text_col)
	return y + item_h
end

local function render_group_item(item, group_x, item_y, group_w, pad_x)
	if item.type == "toggle" then
		draw_toggle_item(item, group_x, item_y, group_w, item_y)
		return item_y + config.item_height.toggle, nil
	end
	if item.type == "button" then
		draw_button_item(item, group_x, item_y, group_w)
		return item_y + get_item_height(item, group_w), nil
	end
	if item.type == "button_pair" then
		draw_button_pair_item(item, group_x, item_y, group_w)
		return item_y + get_item_height(item, group_w), nil
	end
	if item.type == "slider" then
		draw_slider_item(item, group_x, item_y, group_w, item_y)
		return item_y + config.item_height.slider, nil
	end
	if item.type == "dropdown" then
		local dd = draw_dropdown_item(item, group_x, item_y, group_w, item_y)
		return item_y + get_dropdown_item_height(item, group_w), dd
	end
	if item.type == "label" then
		return draw_label_item(item, group_x, item_y, pad_x, group_w), nil
	end
	if item.type == "info" then
		return draw_info_item(item, group_x, item_y, pad_x, group_w), nil
	end
	if item.type == "spacer" then
		return item_y + math.max(0, item.height or 0), nil
	end
	return item_y, nil
end

local function render_button_pair_row(left_button, right_button, group_x, item_y, group_w)
	if right_button then
		local pair = { type = "button_pair", left = left_button, right = right_button }
		draw_button_pair_item(pair, group_x, item_y, group_w)
		return item_y + get_item_height(pair, group_w)
	else
		draw_button_item(left_button, group_x, item_y, group_w)
		return item_y + get_item_height(left_button, group_w)
	end
end

local function render_cut_control_pair(first_item, second_item, group_x, item_y, group_w)
	local offset = config.cut_pair_inner_offset or config.item_height.toggle
	if first_item.type == "slider" then
		draw_slider_item(first_item, group_x, item_y, group_w, item_y)
		draw_toggle_item(second_item, group_x, item_y + offset, group_w, item_y + offset)
	else
		draw_toggle_item(first_item, group_x, item_y, group_w, item_y)
		draw_slider_item(second_item, group_x, item_y + offset, group_w, item_y + offset)
	end
	return item_y + get_cut_control_pair_height()
end

local function render_dropdown_pair_row(left_dropdown, right_dropdown, group_x, item_y, group_w)
	if right_dropdown then
		local pad_x = config.space.x3
		local gap = config.space.x2_5
		local leftW, rightW = button_pair_half_widths(group_w)
		local baseX = group_x + pad_x
		local left_dd = draw_dropdown_item(left_dropdown, baseX - pad_x, item_y, leftW + (pad_x * 2), item_y)
		local right_dd =
			draw_dropdown_item(right_dropdown, baseX + leftW + gap - pad_x, item_y, rightW + (pad_x * 2), item_y)
		local row_h = math.max(
			get_dropdown_item_height(left_dropdown, leftW + (pad_x * 2)),
			get_dropdown_item_height(right_dropdown, rightW + (pad_x * 2))
		)
		return item_y + row_h, left_dd, right_dd
	end

	local dd = draw_dropdown_item(left_dropdown, group_x, item_y, group_w, item_y)
	return item_y + get_dropdown_item_height(left_dropdown, group_w), dd, nil
end

local function build_header_theme_dropdown_item()
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

local function draw_header_theme_dropdown(x, y, w, h)
	local item = build_header_theme_dropdown_item()
	local is_active_dropdown = (state.active_dropdown == item.id)
	local allow_hover = (not state.active_dropdown) or is_active_dropdown
	local hovered = allow_hover and is_hovered(x, y, w, h)

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

	render_depth_shadow(x, y, w, h, config.radius.md, 0.5 + (0.2 * shadow_t), shadow_t)
	render_rect(x, y, w, h, boxBg, config.radius.md)
	render_outline(x, y, w, h, boxBorder, 1, config.radius.md)

	local selected = item.options[item.value] or ""
	local selected_max_w = w - config.space.x9
	local selected_text = text_with_ellipsis(selected, selected_max_w, config.font_scale_small)
	local sel_y = centered_text_y(y, h, selected_text, config.font_scale_small)
	render_text(selected_text, x + config.space.x2, sel_y, config.font_scale_small, boxText)

	local arrowFrames = { "v", ">", "^" }
	local arrowIdx = 1 + math.floor((open_t or 0.0) * (#arrowFrames - 1) + 0.5)
	arrowIdx = clamp(arrowIdx, 1, #arrowFrames)
	local arrow_glyph = arrowFrames[arrowIdx]
	local arrow_y = centered_text_y(y, h, arrow_glyph, config.font_scale_small)
	render_text(arrow_glyph, x + w - config.space.x3, arrow_y, config.font_scale_small, boxArrow)

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

local function render_header_title(header_h, hamburger_x, hamburger_size, right_edge)
	local title = HEIST_SUBTAB_NAMES[state.heist_subtab]
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
	local title_text = text_with_ellipsis(title, title_w, title_scale)
	local title_x = title_left + math.floor(title_w / 2)
	local title_y = centered_text_y(config.origin_y, header_h, title_text, title_scale)
	render_text(title_text, title_x, title_y, title_scale, config.colors.text_main, "center")
end

local function render_background_watermarks(header_h, body_h, hamburger_x, hamburger_size)
	local version_label = i18n.t("app.version")
	local wm_x = config.origin_x + config.menu_width - config.content_margin
	local wm_scale = config.font_scale_small or 1.0
	local wm_y = centered_text_y(config.origin_y, header_h, version_label, wm_scale)
	local wm_col = config.colors.text_main
	render_text(version_label, wm_x, wm_y, wm_scale, wm_col, "right")

	local theme_w = math.max(config.space.x15 * 3, math.floor(config.menu_width * 0.18))
	local theme_h = math.max(config.space.x7, header_h - (config.space.x2 * 2))
	local version_w = measure_text_width(version_label, wm_scale) or 0
	local theme_x = wm_x - version_w - ((config.space.x10 * 2) + config.space.x5) - theme_w
	local theme_y = config.origin_y + math.floor((header_h - theme_h) / 2)
	local min_x = config.origin_x + config.content_margin + config.space.x8
	local header_dropdown = nil
	if theme_x >= min_x and theme_w > 0 and theme_h > 0 then
		header_dropdown = draw_header_theme_dropdown(theme_x, theme_y, theme_w, theme_h)
	end

	if hamburger_x and hamburger_size then
		render_header_title(header_h, hamburger_x, hamburger_size, theme_x)
	end

	local credits_x = config.origin_x + config.space.x2
	local credits_y = config.origin_y + body_h - (config.space.x2 * 2)
	render_text(i18n.t("app.credits"), credits_x, credits_y, wm_scale, wm_col, "left")

	return header_dropdown
end

-- ---------------------------------------------------------
-- 5. Main Render Loop
-- ---------------------------------------------------------

ui.render = function()
	ui.ensure_assets()
	update_input()
	animator.frame = animator.frame + 1
	if animator.frame % 240 == 0 then
		animator.prune(720)
	end
	state.render_alpha_mul = 1.0

	-- Heist-only layout: always keep the Heist tab selected.
	ui.currentTab = ui.tabs[1]
	ensure_heist_subtab_loaded(state.heist_subtab)

	-- Animation
	state.animation.speed = config.motion.open_speed or state.animation.speed
	local diff = state.animation.target - state.animation.progress
	if math.abs(diff) > 0.001 then
		state.animation.progress = state.animation.progress + diff * state.animation.speed
	else
		state.animation.progress = state.animation.target
	end
	if state.animation.progress < 0.01 and state.animation.target == 0.0 then
		return
	end

	state._frame_ox, state._frame_oy = get_win_offset()
	local ox, oy = state._frame_ox, state._frame_oy

	local dynamicBodyH = config.menu_height

	local bodyY = config.origin_y
	local bodyH = dynamicBodyH
	local header_h = config.header_height or config.content_margin
	local resize_hit_w = config.resize.edge_hit_w
	local resize_hit_h = config.resize.edge_hit_h or config.space.x6
	local resize_hit_x = config.origin_x + config.menu_width - resize_hit_w
	local resize_hit_y = bodyY + bodyH - resize_hit_h
	local resize_hovered = not state.active_dropdown
		and is_hovered(
			resize_hit_x - config.space.x1,
			resize_hit_y - config.space.x1,
			resize_hit_w + config.space.x2,
			resize_hit_h + config.space.x2
		)
	local drawer_t = update_drawer_animation()
	local drawer_visible = drawer_t > 0.01 or (state.drawer and state.drawer.open)
	local hamburger_x, hamburger_y, hamburger_size = get_hamburger_rect(bodyY)
	local hamburger_hovered = not state.active_dropdown
		and is_hovered(hamburger_x, hamburger_y, hamburger_size, hamburger_size)
	local raw_mouse_clicked = state.mouse.clicked
	local consumed_nav_click = false

	if raw_mouse_clicked and hamburger_hovered then
		set_drawer_open(not (state.drawer and state.drawer.open))
		state.active_dropdown = nil
		state.dropdown_just_opened = false
		state.scroll.is_dragging = false
		state.dragging_slider = nil
		state.window.is_dragging = false
		state.window.is_resizing = false
		consumed_nav_click = true
	end

	if drawer_visible or consumed_nav_click then
		state.mouse.clicked = false
	end

	if state.mouse.clicked and not state.active_dropdown and not state.dragging_slider then
		local menuStartY = config.origin_y
		if resize_hovered then
			state.window.is_resizing = true
			state.window.is_dragging = false
			state.window.resize_start.x = state.mouse.x
			state.window.resize_start.y = state.mouse.y
			state.window.resize_start.width = config.menu_width
			state.window.resize_start.height = config.menu_height
		elseif is_hovered(config.origin_x, menuStartY, config.menu_width, dynamicBodyH) then
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

	-- Full-width content panel (no sidebar/tab navigation).
	config.content_area.x = config.origin_x
	config.content_area.y = bodyY
	config.content_area.w = config.menu_width
	config.content_area.h = bodyH
	config.scrollbar.x = config.origin_x + config.menu_width - config.space.x2
	config.scrollbar.y = config.content_area.y + header_h
	config.scrollbar.h = config.content_area.h - header_h - config.content_margin

	render_card(
		config.origin_x,
		bodyY,
		config.menu_width,
		bodyH,
		config.colors.bg_main,
		config.colors.border_strong,
		config.radius.xl
	)
	render_background_tile(config.origin_x, bodyY, config.menu_width, bodyH)
	local headerDropdown = render_background_watermarks(header_h, dynamicBodyH, hamburger_x, hamburger_size)

	-- Bottom-right corner grip to indicate draggable resize area.
	local grip_color = config.colors.accent
	local grip_right = config.origin_x + config.menu_width - config.space.x1
	local grip_bottom = bodyY + bodyH - config.space.x1
	render_rect(
		grip_right - config.space.x7,
		grip_bottom - config.space.x1,
		config.space.x5,
		config.space.x1,
		grip_color,
		config.radius.full
	)
	render_rect(
		grip_right - config.space.x5,
		grip_bottom - config.space.x3,
		config.space.x4,
		config.space.x1,
		grip_color,
		config.radius.full
	)
	render_rect(
		grip_right - config.space.x3,
		grip_bottom - config.space.x5,
		config.space.x3,
		config.space.x1,
		grip_color,
		config.radius.full
	)

	local contentX = config.content_area.x + config.content_margin
	local contentY = config.content_area.y + header_h
	local contentW = config.content_area.w - (config.content_margin * 2)
	local contentH = config.content_area.h - header_h - config.content_margin
	local layout_cfg = config.layout or {}
	local column_gap = layout_cfg.column_gap or config.space.x4
	local fixed_col_w = layout_cfg.fixed_column_w or math.max(1, math.floor((contentW - (2 * column_gap)) / 3))
	local max_columns = layout_cfg.max_columns or 3
	local column_count = math.floor((contentW + column_gap) / (fixed_col_w + column_gap))
	if column_count < 1 then
		column_count = 1
	end
	if column_count > max_columns then
		column_count = max_columns
	end

	local subtab_bar_height = 0
	local groups_start_y = contentY
	if state.content_transition.subtab ~= state.heist_subtab then
		state.content_transition.subtab = state.heist_subtab
		state.content_transition.progress = 0.0
		animator.values["content_transition"] = { v = 0.0, seen = animator.frame }
	end
	state.content_transition.progress = animator.to(
		"content_transition",
		1.0,
		animator.motion_speed(config.motion.subtab_switch_speed, config.motion.speed_base or 0.16)
	)
	local content_intro_t = state.content_transition.progress

	-- Push clip for scrollable content area.
	local clip_y = ui.currentTab and ui.currentTab.id == "heist" and groups_start_y or contentY
	local clip_h = contentH - subtab_bar_height
	gui.push_clip(vec(contentX + ox, clip_y + oy), vec(contentW, clip_h))

	local pendingDropdowns = render_cache.pending_dropdowns
	clear_array(pendingDropdowns)
	if headerDropdown then
		pendingDropdowns[#pendingDropdowns + 1] = headerDropdown
	end

	local activeGroups, selected_heist_key = get_active_groups()

	if #activeGroups > 0 then
		local col_w = fixed_col_w
		local used_w = (column_count * col_w) + ((column_count - 1) * column_gap)
		local start_x = contentX + math.max(0, math.floor((contentW - used_w) / 2))
		local col_x = render_cache.col_x
		clear_array(col_x)
		local base_y = groups_start_y - state.scroll.y

		for col = 1, column_count do
			col_x[col] = start_x + ((col - 1) * (col_w + column_gap))
		end

		local groups_by_column = render_cache.groups_by_column
		local layout_tab_id = ui.currentTab and ui.currentTab.id or ""
		local animation_subkey = selected_heist_key or tostring(state.heist_subtab or 0)
		if
			render_cache.layout_dirty
			or render_cache.layout_revision ~= layout_cache_revision
			or render_cache.layout_tab_id ~= layout_tab_id
			or render_cache.layout_selected_heist_key ~= selected_heist_key
			or render_cache.layout_column_count ~= column_count
			or render_cache.layout_col_w ~= col_w
		then
			local ordered = flatten_groups_by_order(activeGroups, selected_heist_key, column_count)
			local group_heights = render_cache.group_heights
			for key in pairs(group_heights) do
				group_heights[key] = nil
			end
			for i = 1, #ordered do
				local group = ordered[i].group
				group_heights[group] = get_group_actual_height(group, col_w)
			end
			distribute_groups_by_column(ordered, groups_by_column, column_count, group_heights, animation_subkey)
			render_cache.layout_tab_id = layout_tab_id
			render_cache.layout_selected_heist_key = selected_heist_key
			render_cache.layout_column_count = column_count
			render_cache.layout_col_w = col_w
			render_cache.layout_revision = layout_cache_revision
			render_cache.layout_dirty = false
		end

		local group_move_speed = animator.motion_speed(config.motion.group_move_speed, config.motion.speed_base or 0.16)
		local intro_slide_dist = config.motion.subtab_switch_slide or config.space.x3
		local max_col_y = base_y
		for col = 1, column_count do
			local gX = col_x[col]
			local col_y = base_y

			for _, entry in ipairs(groups_by_column[col]) do
				local group = entry.group
				local gY = col_y
				local actual_h = entry.h or get_group_actual_height(group, col_w)
				local anim_key = entry.anim_key or group_animation_key(group, animation_subkey, entry.order)
				local drawX, drawY
				if entry.anim_key_x and entry.anim_key_y then
					drawX = animator.to(entry.anim_key_x, gX, group_move_speed)
					drawY = animator.to(entry.anim_key_y, gY, group_move_speed)
				else
					drawX, drawY = animator.vec2(anim_key, gX, gY, group_move_speed)
				end
				local stagger = math.min(0.45, ((entry.order or 1) - 1) * 0.06)
				local reveal_t = (content_intro_t <= stagger) and 0.0 or ((content_intro_t - stagger) / (1.0 - stagger))
				reveal_t = animator.clamp01(reveal_t)
				drawY = drawY + ((1.0 - reveal_t) * intro_slide_dist)

				local available_height = contentH - subtab_bar_height
				local clip_start = groups_start_y
				if reveal_t > 0.01 and (drawY + actual_h > clip_start) and (drawY < clip_start + available_height) then
					local pad_x = config.space.x3
					state.render_alpha_mul = reveal_t
					render_card(
						drawX,
						drawY,
						col_w,
						actual_h,
						config.colors.bg_panel,
						config.colors.border,
						config.radius.lg
					)
					-- Group Header Label
					render_text(
						group.label,
						drawX + pad_x,
						drawY + config.space.x3,
						config.font_scale_header,
						config.colors.text_main
					)
					local dividerY = drawY + config.item_height.header_padding - config.space.x1
					render_rect(
						drawX + pad_x,
						dividerY,
						col_w - (pad_x * 2),
						config.space.x1,
						config.colors.border,
						config.radius.full
					)

					local itemY = drawY + config.item_height.header_padding + config.space.x3
					local clip_bottom = clip_start + available_height
					local rendered_items = 0
					local item_index = 1
					while item_index <= #group.items do
						local item = group.items[item_index]
						if item.hidden then
							item_index = item_index + 1
							goto continue_item
						end
						local item_h = get_item_height(item, col_w)
						local pair_index = nil
						local pair_item = nil
						local pair_kind = nil
						local cut_pair_index = next_cut_control_pair_index(group.items, item_index)
						if cut_pair_index then
							pair_index = cut_pair_index
							pair_item = group.items[pair_index]
							pair_kind = "cut"
							item_h = get_cut_control_pair_height()
						elseif is_auto_pairable_button(item) then
							pair_index = next_auto_pair_button_index(group.items, item_index)
							if pair_index then
								pair_item = group.items[pair_index]
								pair_kind = "button"
							end
						elseif is_auto_pairable_dropdown(item) then
							pair_index = next_auto_pair_dropdown_index(group.items, item_index)
							if pair_index then
								pair_item = group.items[pair_index]
								pair_kind = "dropdown"
								local leftW, rightW = button_pair_half_widths(col_w)
								item_h = math.max(
									get_dropdown_item_height(item, leftW + (pad_x * 2)),
									get_dropdown_item_height(pair_item, rightW + (pad_x * 2))
								)
							end
						end
						local item_gap = (rendered_items > 0) and (config.item_gap or 0) or 0
						itemY = itemY + item_gap
						if (itemY + item_h) < clip_start or itemY > clip_bottom then
							-- Item fully outside visible area, skip rendering
							itemY = itemY + item_h
						elseif pair_item then
							if pair_kind == "cut" then
								itemY = render_cut_control_pair(item, pair_item, drawX, itemY, col_w)
							elseif pair_kind == "dropdown" then
								local left_dd, right_dd
								itemY, left_dd, right_dd =
									render_dropdown_pair_row(item, pair_item, drawX, itemY, col_w)
								if left_dd then
									pendingDropdowns[#pendingDropdowns + 1] = left_dd
								end
								if right_dd then
									pendingDropdowns[#pendingDropdowns + 1] = right_dd
								end
							else
								itemY = render_button_pair_row(item, pair_item, drawX, itemY, col_w)
							end
						elseif is_auto_pairable_button(item) then
							itemY = render_button_pair_row(item, nil, drawX, itemY, col_w)
						elseif is_auto_pairable_dropdown(item) then
							local dd
							itemY, dd = render_dropdown_pair_row(item, nil, drawX, itemY, col_w)
							if dd then
								pendingDropdowns[#pendingDropdowns + 1] = dd
							end
						else
							local dd
							itemY, dd = render_group_item(item, drawX, itemY, col_w, pad_x)
							if dd then
								pendingDropdowns[#pendingDropdowns + 1] = dd
							end
						end
						rendered_items = rendered_items + 1
						if pair_index then
							item_index = pair_index
						end
						item_index = item_index + 1
						::continue_item::
					end
					state.render_alpha_mul = 1.0
				end

				col_y = col_y + actual_h + config.space.x4
			end

			if col_y > max_col_y then
				max_col_y = col_y
			end
		end

		local total_h = max_col_y - base_y
		local available_height = contentH - subtab_bar_height
		state.scroll.max_y = math.max(0, total_h - available_height)
	end

	state.render_alpha_mul = 1.0
	gui.pop_clip()

	-- Scrollbar
	if state.scroll.max_y > 0 then
		local sb = config.scrollbar
		local sbH = contentH - subtab_bar_height
		local sbY = groups_start_y

		local thumbH = math.max(config.control.scrollbar_min_thumb, (sbH / (sbH + state.scroll.max_y)) * sbH)
		local thumbY = sbY + (state.scroll.y / state.scroll.max_y) * (sbH - thumbH)

		render_rect(sb.x, sbY, sb.w, sbH, config.colors.scroll_track, config.radius.full)
		render_rect(sb.x, thumbY, sb.w, thumbH, config.colors.accent, config.radius.full)

		if
			not state.active_dropdown
			and is_hovered(
				sb.x - config.control.scrollbar_grab_pad,
				sbY,
				sb.w + (config.control.scrollbar_grab_pad * 2),
				sbH
			)
			and state.mouse.clicked
		then
			state.scroll.is_dragging = true
		end
		if state.scroll.is_dragging and state.mouse.down then
			local my = state.mouse.y - oy
			local ratio = math.max(0, math.min(1, (my - sbY) / sbH))
			state.scroll.y = ratio * state.scroll.max_y
		end
	end

	if #pendingDropdowns > 0 then
		for dd_idx = 1, #pendingDropdowns do
			local dd = pendingDropdowns[dd_idx]
			local itemHeight = config.space.x9
			local fullOptsH = #dd.item.options * itemHeight
			local open_t = dd.open_t or 1.0
			local resolution = game.resolution()
			local screen_w = resolution.x
			local screen_h = resolution.y
			local screen_margin = config.space.x2
			local max_panel_w = math.max(dd.w, screen_w - (screen_margin * 2))
			local panel_w = get_dropdown_panel_width(dd.item, dd.w, max_panel_w)
			local panel_x = clamp(dd.x, screen_margin - ox, screen_w - ox - screen_margin - panel_w)
			local max_visible_items =
				math.max(1, math.floor((config.control and config.control.dropdown_max_visible_items) or 10))
			local min_visible_items =
				math.max(1, math.floor((config.control and config.control.dropdown_min_visible_items) or 3))
			local max_list_h = itemHeight * max_visible_items
			local min_list_h = math.min(fullOptsH, itemHeight * min_visible_items)
			local screen_list_h = math.max(1, screen_h - (screen_margin * 2))
			local below_space = screen_h - (dd.y + oy) - screen_margin
			local above_space = (dd.control_y + oy) - screen_margin
			local open_above = above_space > below_space and below_space < math.min(fullOptsH, max_list_h)
			local available_space = open_above and above_space or below_space
			local visible_full_h = math.min(fullOptsH, max_list_h, screen_list_h, math.max(min_list_h, available_space))
			visible_full_h = math.max(1, visible_full_h)
			local optsH = math.max(1, math.floor(visible_full_h * open_t))
			local panel_y = dd.y
			if open_above then
				panel_y = dd.control_y - config.space.x1 - optsH
			end
			panel_y = clamp(panel_y, screen_margin - oy, screen_h - oy - screen_margin - optsH)
			local max_scroll_y = math.max(0, fullOptsH - visible_full_h)
			local dropdown_id = dd.item.id
			state.dropdown_scroll = state.dropdown_scroll or {}
			state.dropdown_scroll_init = state.dropdown_scroll_init or {}
			if not state.dropdown_scroll_init[dropdown_id] then
				local selected_y = math.max(0, ((dd.item.value or 1) - 1) * itemHeight)
				state.dropdown_scroll[dropdown_id] =
					clamp(selected_y - math.floor((visible_full_h - itemHeight) / 2), 0, max_scroll_y)
				state.dropdown_scroll_init[dropdown_id] = true
			end
			local scroll_y = clamp(state.dropdown_scroll[dropdown_id] or 0, 0, max_scroll_y)
			state.dropdown_scroll[dropdown_id] = scroll_y
			state.dropdown_scroll_max = max_scroll_y
			local can_interact = dd.interactive and (open_t > 0.95)

			state.render_alpha_mul = open_t
			render_card(
				panel_x,
				panel_y,
				panel_w,
				optsH,
				config.colors.bg_panel,
				config.colors.border,
				config.radius.md
			)
			gui.push_clip(vec(panel_x + ox, panel_y + oy), vec(panel_w, optsH))

			for i, opt in ipairs(dd.item.options) do
				local optY = panel_y + (i - 1) * itemHeight - scroll_y
				local optTextCol = config.colors.text_main
				local visible = optY + itemHeight >= panel_y and optY <= panel_y + optsH
				if visible and can_interact and is_hovered(panel_x, optY, panel_w, itemHeight) then
					render_rect(panel_x, optY, panel_w, itemHeight, config.colors.accent, config.radius.none)
					if state.mouse.clicked and not state.dropdown_just_opened then
						dd.item.value = i
						dd.item.isOpen = false
						state.active_dropdown = nil
						state.dropdown_scroll_max = 0
						state.dropdown_scroll_init[dropdown_id] = false
						state.window.is_dragging = false
						if dd.item.onChange then
							safe_call_ui_handler("dropdown", dd.item.id, dd.item.onChange, opt)
						end
					end
					optTextCol = config.colors.text_on_accent
				end
				if visible then
					local option_max_w = panel_w - config.space.x6
					if max_scroll_y > 0 then
						option_max_w = option_max_w - config.space.x2
					end
					local option_text = text_with_ellipsis(opt, option_max_w, config.font_scale_body)
					render_text_in_rect(
						option_text,
						panel_x + config.space.x3,
						optY,
						option_max_w,
						itemHeight,
						config.font_scale_body,
						optTextCol,
						"left"
					)
				end
			end

			gui.pop_clip()
			if max_scroll_y > 0 then
				local track_w = config.scrollbar.w or config.space.x1
				local track_x = panel_x + panel_w - config.space.x2
				local thumb_h = math.max(config.control.scrollbar_min_thumb, (visible_full_h / fullOptsH) * optsH)
				local thumb_y = panel_y
				if max_scroll_y > 0 then
					thumb_y = panel_y + (scroll_y / max_scroll_y) * (optsH - thumb_h)
				end
				render_rect(
					track_x,
					thumb_y + config.space.x1,
					track_w,
					math.max(1, thumb_h - config.space.x2),
					config.colors.accent,
					config.radius.full
				)
			end
			state.render_alpha_mul = 1.0

			if
				can_interact
				and state.mouse.clicked
				and not state.dropdown_just_opened
				and not is_hovered(panel_x, panel_y, panel_w, optsH)
			then
				dd.item.isOpen = false
				state.active_dropdown = nil
				state.dropdown_scroll_max = 0
				state.dropdown_scroll_init[dropdown_id] = false
				state.window.is_dragging = false
			end
		end
		state.dropdown_just_opened = false
	else
		state.dropdown_scroll_max = 0
	end

	state.mouse.clicked = raw_mouse_clicked and not consumed_nav_click
	render_hamburger_button(hamburger_x, hamburger_y, hamburger_size, hamburger_hovered)
	render_drawer(bodyY, bodyH, drawer_t)
	state.mouse.clicked = raw_mouse_clicked
end

return ui
