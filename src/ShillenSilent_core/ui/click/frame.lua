local assets = require("ShillenSilent_core.ui.click.assets")
local config = require("ShillenSilent_core.ui.click.config")
local state = require("ShillenSilent_core.ui.click.state")
local model = require("ShillenSilent_core.ui.click.model")
local animator = require("ShillenSilent_core.ui.click.animator")
local primitives = require("ShillenSilent_core.ui.click.primitives")
local click_input = require("ShillenSilent_core.ui.click.input")
local drawer = require("ShillenSilent_core.ui.click.drawer")
local chrome = require("ShillenSilent_core.ui.click.chrome")
local layout_engine = require("ShillenSilent_core.ui.click.layout_engine")
local control_pairs = require("ShillenSilent_core.ui.click.controls.pairs")
local scrollbar = require("ShillenSilent_core.ui.click.overlays.scrollbar")
local dropdown_panel = require("ShillenSilent_core.ui.click.overlays.dropdown_panel")

local frame = model

function frame.ensure_assets()
	return assets.ensure_assets()
end

function frame.set_heist_subtabs(names, keys)
	return drawer.set_heist_subtabs(names, keys)
end

function frame.set_heist_subtab_loader(loader)
	return drawer.set_heist_subtab_loader(loader)
end

local pending_dropdowns = {}
local col_x = {}

local function prepare_frame()
	frame.ensure_assets()
	click_input.update()
	animator.frame = animator.frame + 1
	if animator.frame % 240 == 0 then
		animator.prune(720)
	end
	state.render_alpha_mul = 1.0

	frame.currentTab = frame.tabs[1]
	drawer.ensure_heist_subtab_loaded(state.heist_subtab)

	state.animation.speed = config.motion.open_speed or state.animation.speed
	local diff = state.animation.target - state.animation.progress
	if math.abs(diff) > 0.001 then
		state.animation.progress = state.animation.progress + diff * state.animation.speed
	else
		state.animation.progress = state.animation.target
	end
	if state.animation.progress < 0.01 and state.animation.target == 0.0 then
		return false
	end

	state._frame_ox, state._frame_oy = click_input.get_win_offset()
	return true
end

local function consume_drawer_clicks(bodyY)
	local drawer_t = drawer.update_animation()
	local drawer_visible = drawer_t > 0.01 or (state.drawer and state.drawer.open)
	local hamburger_x, hamburger_y, hamburger_size = drawer.hamburger_rect(bodyY)
	local hamburger_hovered = not state.active_dropdown
		and click_input.is_hovered(hamburger_x, hamburger_y, hamburger_size, hamburger_size)
	local raw_mouse_clicked = state.mouse.clicked
	local consumed_nav_click = false

	if raw_mouse_clicked and hamburger_hovered then
		drawer.set_open(not (state.drawer and state.drawer.open))
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

	return {
		drawer_t = drawer_t,
		hamburger_x = hamburger_x,
		hamburger_y = hamburger_y,
		hamburger_size = hamburger_size,
		hamburger_hovered = hamburger_hovered,
		raw_mouse_clicked = raw_mouse_clicked,
		consumed_nav_click = consumed_nav_click,
	}
end

local function compute_content_layout(header_h, bodyY, bodyH)
	chrome.update_content_area(bodyY, bodyH, header_h)

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

	return {
		contentX = contentX,
		contentY = contentY,
		contentW = contentW,
		contentH = contentH,
		column_gap = column_gap,
		col_w = fixed_col_w,
		column_count = column_count,
		subtab_bar_height = 0,
		groups_start_y = contentY,
	}
end

local function update_content_transition()
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
	return state.content_transition.progress
end

local function render_group_items(group, drawX, drawY, actual_h, col_w, clip_start, available_height, pendingDropdowns)
	if drawY + actual_h <= clip_start or drawY >= clip_start + available_height then
		return
	end

	local pad_x = config.space.x3
	primitives.render_card(
		drawX,
		drawY,
		col_w,
		actual_h,
		config.colors.bg_panel,
		config.colors.border,
		config.radius.lg
	)
	primitives.render_text(
		group.label,
		drawX + pad_x,
		drawY + config.space.x3,
		config.font_scale_header,
		config.colors.text_main
	)
	local dividerY = drawY + config.item_height.header_padding - config.space.x1
	primitives.render_rect(
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

		local item_h = layout_engine.get_item_height(item, col_w)
		local pair_index = nil
		local pair_item = nil
		local pair_kind = nil
		local cut_pair_index = layout_engine.next_cut_control_pair_index(group.items, item_index)
		if cut_pair_index then
			pair_index = cut_pair_index
			pair_item = group.items[pair_index]
			pair_kind = "cut"
			item_h = layout_engine.get_cut_control_pair_height()
		elseif layout_engine.is_auto_pairable_button(item) then
			pair_index = layout_engine.next_auto_pair_button_index(group.items, item_index)
			if pair_index then
				pair_item = group.items[pair_index]
				pair_kind = "button"
			end
		elseif layout_engine.is_auto_pairable_dropdown(item) then
			pair_index = layout_engine.next_auto_pair_dropdown_index(group.items, item_index)
			if pair_index then
				pair_item = group.items[pair_index]
				pair_kind = "dropdown"
				local leftW, rightW = primitives.button_pair_half_widths(col_w)
				item_h = math.max(
					layout_engine.get_dropdown_item_height(item, leftW + (pad_x * 2)),
					layout_engine.get_dropdown_item_height(pair_item, rightW + (pad_x * 2))
				)
			end
		end

		local item_gap = (rendered_items > 0) and (config.item_gap or 0) or 0
		itemY = itemY + item_gap
		if (itemY + item_h) < clip_start or itemY > clip_bottom then
			itemY = itemY + item_h
		elseif pair_item then
			if pair_kind == "cut" then
				itemY = control_pairs.render_cut_control_pair(item, pair_item, drawX, itemY, col_w)
			elseif pair_kind == "dropdown" then
				local left_dd, right_dd
				itemY, left_dd, right_dd = control_pairs.render_dropdown_pair_row(item, pair_item, drawX, itemY, col_w)
				if left_dd then
					pendingDropdowns[#pendingDropdowns + 1] = left_dd
				end
				if right_dd then
					pendingDropdowns[#pendingDropdowns + 1] = right_dd
				end
			else
				itemY = control_pairs.render_button_pair_row(item, pair_item, drawX, itemY, col_w)
			end
		elseif layout_engine.is_auto_pairable_button(item) then
			itemY = control_pairs.render_button_pair_row(item, nil, drawX, itemY, col_w)
		elseif layout_engine.is_auto_pairable_dropdown(item) then
			local dd
			itemY, dd = control_pairs.render_dropdown_pair_row(item, nil, drawX, itemY, col_w)
			if dd then
				pendingDropdowns[#pendingDropdowns + 1] = dd
			end
		else
			local dd
			itemY, dd = control_pairs.render_group_item(item, drawX, itemY, col_w, pad_x)
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
end

local function render_groups(layout, pendingDropdowns)
	local activeGroups, selected_heist_key = layout_engine.get_active_groups(frame.currentTab)
	if #activeGroups <= 0 then
		update_content_transition()
		return
	end

	local col_w = layout.col_w
	local column_count = layout.column_count
	local used_w = (column_count * col_w) + ((column_count - 1) * layout.column_gap)
	local start_x = layout.contentX + math.max(0, math.floor((layout.contentW - used_w) / 2))
	layout_engine.clear_array(col_x)
	local base_y = layout.groups_start_y - state.scroll.y
	for col = 1, column_count do
		col_x[col] = start_x + ((col - 1) * (col_w + layout.column_gap))
	end

	local current_tab_id = frame.currentTab and frame.currentTab.id or ""
	local groups_by_column, animation_subkey =
		layout_engine.groups_by_column(activeGroups, selected_heist_key, current_tab_id, column_count, col_w)
	local group_move_speed = animator.motion_speed(config.motion.group_move_speed, config.motion.speed_base or 0.16)
	local intro_slide_dist = config.motion.subtab_switch_slide or config.space.x3
	local content_intro_t = update_content_transition()
	local max_col_y = base_y
	local available_height = layout.contentH - layout.subtab_bar_height
	local clip_start = layout.groups_start_y

	for col = 1, column_count do
		local gX = col_x[col]
		local col_y = base_y
		for _, entry in ipairs(groups_by_column[col]) do
			local group = entry.group
			local gY = col_y
			local actual_h = entry.h or layout_engine.get_group_actual_height(group, col_w)
			local drawX, drawY
			if entry.anim_key_x and entry.anim_key_y then
				drawX = animator.to(entry.anim_key_x, gX, group_move_speed)
				drawY = animator.to(entry.anim_key_y, gY, group_move_speed)
			else
				drawX, drawY = animator.vec2(entry.anim_key or ("group:" .. animation_subkey), gX, gY, group_move_speed)
			end
			local stagger = math.min(0.45, ((entry.order or 1) - 1) * 0.06)
			local reveal_t = (content_intro_t <= stagger) and 0.0 or ((content_intro_t - stagger) / (1.0 - stagger))
			reveal_t = animator.clamp01(reveal_t)
			drawY = drawY + ((1.0 - reveal_t) * intro_slide_dist)

			if reveal_t > 0.01 then
				state.render_alpha_mul = reveal_t
				render_group_items(group, drawX, drawY, actual_h, col_w, clip_start, available_height, pendingDropdowns)
				state.render_alpha_mul = 1.0
			end
			col_y = col_y + actual_h + config.space.x4
		end
		if col_y > max_col_y then
			max_col_y = col_y
		end
	end

	local total_h = max_col_y - base_y
	state.scroll.max_y = math.max(0, total_h - available_height)
end

function frame.render()
	if not prepare_frame() then
		return
	end

	local dynamicBodyH = config.menu_height
	local bodyY = config.origin_y
	local bodyH = dynamicBodyH
	local header_h = config.header_height or config.content_margin
	local resize_hovered = chrome.resize_hovered(bodyY, bodyH)
	local nav = consume_drawer_clicks(bodyY)

	chrome.update_window_interaction(resize_hovered, dynamicBodyH)
	local layout = compute_content_layout(header_h, bodyY, bodyH)
	local headerDropdown = chrome.render_shell(bodyY, bodyH, header_h, nav.hamburger_x, nav.hamburger_size)

	local ox, oy = state._frame_ox, state._frame_oy
	local clip_y = frame.currentTab and frame.currentTab.id == "heist" and layout.groups_start_y or layout.contentY
	local clip_h = layout.contentH - layout.subtab_bar_height
	gui.push_clip(primitives.vec(layout.contentX + ox, clip_y + oy), primitives.vec(layout.contentW, clip_h))

	layout_engine.clear_array(pending_dropdowns)
	if headerDropdown then
		pending_dropdowns[#pending_dropdowns + 1] = headerDropdown
	end
	render_groups(layout, pending_dropdowns)

	state.render_alpha_mul = 1.0
	gui.pop_clip()

	scrollbar.render(layout.contentH, layout.subtab_bar_height, layout.groups_start_y)
	dropdown_panel.render(pending_dropdowns)

	state.mouse.clicked = nav.raw_mouse_clicked and not nav.consumed_nav_click
	drawer.render_hamburger_button(nav.hamburger_x, nav.hamburger_y, nav.hamburger_size, nav.hamburger_hovered)
	drawer.render(bodyY, bodyH, nav.drawer_t)
	state.mouse.clicked = nav.raw_mouse_clicked
end

return frame
