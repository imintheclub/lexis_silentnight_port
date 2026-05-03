local i18n = require("ShillenSilent_core.i18n")
local notify_core = require("ShillenSilent_core.core.notify")
local config = require("ShillenSilent_core.ui.click.config")
local state = require("ShillenSilent_core.ui.click.state")
local model = require("ShillenSilent_core.ui.click.model")
local animator = require("ShillenSilent_core.ui.click.animator")
local primitives = require("ShillenSilent_core.ui.click.primitives")
local click_input = require("ShillenSilent_core.ui.click.input")

local drawer = {}

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

local heist_subtab_loader = nil
local heist_subtab_load_state = {}
local cache = {
	drawer_overlay_col = { r = 0, g = 0, b = 0, a = 0 },
	drawer_active_bg_col = { r = 255, g = 255, b = 255, a = 255 },
	drawer_active_text_col = { r = 255, g = 255, b = 255, a = 255 },
	drawer_rows = {},
}

local function clear_array(tbl)
	for i = #tbl, 1, -1 do
		tbl[i] = nil
	end
end

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
		config.origin_y = config.origin_y + math.floor((prev_h - needed) / 2)
	end
end

function drawer.name(index)
	return HEIST_SUBTAB_NAMES[index]
end

function drawer.key(index)
	return HEIST_SUBTAB_KEYS[index]
end

function drawer.selected_key()
	return HEIST_SUBTAB_KEYS[state.heist_subtab]
end

function drawer.set_heist_subtabs(names, keys)
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
	model.mark_layout_dirty()
	return true
end

function drawer.set_heist_subtab_loader(loader)
	heist_subtab_loader = type(loader) == "function" and loader or nil
	heist_subtab_load_state = {}
	return heist_subtab_loader ~= nil
end

function drawer.ensure_heist_subtab_loaded(index)
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

function drawer.update_animation()
	local state_drawer = state.drawer
	if type(state_drawer) ~= "table" then
		state_drawer = { open = false, progress = 0.0, target = 0.0 }
		state.drawer = state_drawer
	end

	state_drawer.target = state_drawer.open and 1.0 or 0.0
	state_drawer.progress = animator.to(
		"drawer_progress",
		state_drawer.target,
		animator.motion_speed(config.motion.drawer_speed, config.motion.speed_base or 0.16)
	)
	return state_drawer.progress
end

function drawer.hamburger_rect(bodyY)
	local drawer_cfg = config.drawer or {}
	local size = drawer_cfg.button_size or config.space.x6
	local header_h = config.header_height or config.content_margin
	local top_gap = math.max(0, math.floor((header_h - size) / 2))
	return config.origin_x + config.content_margin, bodyY + top_gap, size, size
end

function drawer.set_open(open)
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
	drawer.ensure_heist_subtab_loaded(index)
	state.scroll.y = 0
	state.scroll.is_dragging = false
	state.dragging_slider = nil
	state.window.is_dragging = false
	state.window.is_resizing = false
	drawer.set_open(false)
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

function drawer.render_hamburger_button(x, y, size, hovered)
	local bg = hovered and config.colors.bg_control_hover or config.colors.bg_control
	primitives.render_rect(x, y, size, size, bg, config.radius.md)
	primitives.render_outline(x, y, size, size, config.colors.border, 1, config.radius.md)

	local line_w = math.max(1, size - config.space.x3)
	local line_h = (config.drawer and config.drawer.line_thickness) or 2
	local line_x = x + math.floor((size - line_w) / 2)
	local center_y = y + math.floor(size / 2)
	local gap = math.max(line_h + 1, math.floor(size / 5))
	primitives.render_rect(line_x, center_y - gap, line_w, line_h, config.colors.text_main, config.radius.full)
	primitives.render_rect(line_x, center_y, line_w, line_h, config.colors.text_main, config.radius.full)
	primitives.render_rect(line_x, center_y + gap, line_w, line_h, config.colors.text_main, config.radius.full)
end

function drawer.render(bodyY, bodyH, drawer_t)
	if drawer_t <= 0.01 then
		return
	end

	local drawer_cfg = config.drawer or {}
	local drawer_w = math.min(drawer_cfg.width or config.space.x15 * 4, config.menu_width - config.content_margin)
	local drawer_x = config.origin_x - drawer_w + (drawer_w * drawer_t)
	local overlay_col = cache.drawer_overlay_col
	overlay_col.a = math.floor((drawer_cfg.overlay_alpha or 90) * drawer_t)
	primitives.render_rect(config.origin_x, bodyY, config.menu_width, bodyH, overlay_col, config.radius.xl)

	local ox, oy = state._frame_ox, state._frame_oy
	gui.push_clip(primitives.vec(config.origin_x + ox, bodyY + oy), primitives.vec(config.menu_width, bodyH))
	primitives.render_card(
		drawer_x,
		bodyY,
		drawer_w,
		bodyH,
		config.colors.bg_panel,
		config.colors.border_strong,
		config.radius.xl
	)

	local rows = cache.drawer_rows
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
			local header_label =
				primitives.text_with_ellipsis(row.label, item_w - config.space.x3, config.font_scale_small)
			primitives.render_text_in_rect(
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
			primitives.render_rect(
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
		local label =
			primitives.text_with_ellipsis(HEIST_SUBTAB_NAMES[i], item_w - config.space.x6, config.font_scale_body)
		local is_active = state.heist_subtab == i
		local hovered = (not state.active_dropdown) and click_input.is_hovered(item_x, item_y, item_w, row_h)
		local bg_col = nil
		local text_col = config.colors.text_main

		if is_active then
			bg_col = cache.drawer_active_bg_col
			animator.blend_color(config.colors.bg_control, config.colors.accent, drawer_t, bg_col)
			text_col = cache.drawer_active_text_col
			animator.blend_color(config.colors.text_main, config.colors.text_on_accent, drawer_t, text_col)
		elseif hovered then
			bg_col = config.colors.bg_control_hover
		end

		if bg_col then
			primitives.render_rect(item_x, item_y, item_w, row_h, bg_col, config.radius.md)
		end

		primitives.render_text_in_rect(
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
		and not click_input.is_hovered(drawer_x, bodyY, drawer_w, bodyH)
		and not state.window.is_dragging
		and not state.window.is_resizing
	then
		drawer.set_open(false)
	end
end

return drawer
