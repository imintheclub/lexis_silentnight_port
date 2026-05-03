local config = require("ShillenSilent_core.ui.click.config")
local state = require("ShillenSilent_core.ui.click.state")
local group_layouts = require("ShillenSilent_core.ui.click.group_layouts")
local model = require("ShillenSilent_core.ui.click.model")
local drawer = require("ShillenSilent_core.ui.click.drawer")
local primitives = require("ShillenSilent_core.ui.click.primitives")

local layout_engine = {}

local cache = {
	active_groups = {},
	active_groups_tab = nil,
	active_groups_subtab = nil,
	active_groups_revision = -1,
	ordered_groups = {},
	groups_by_column = { {}, {}, {} },
	layout_tab_id = nil,
	layout_selected_heist_key = nil,
	layout_column_count = nil,
	layout_col_w = nil,
	layout_revision = -1,
	layout_dirty = true,
	group_heights = {},
}

function layout_engine.clear_array(tbl)
	for i = #tbl, 1, -1 do
		tbl[i] = nil
	end
end

function layout_engine.dropdown_label_text(item)
	return tostring((item and item.label) or "")
end

function layout_engine.dropdown_label_width(w)
	local pad_x = config.space.x3
	return math.max(1, (w or 0) - (pad_x * 2))
end

function layout_engine.dropdown_label_height(item, w)
	return math.max(
		config.space.x4,
		math.ceil(
			primitives.measure_wrapped_text_height(
				layout_engine.dropdown_label_text(item),
				layout_engine.dropdown_label_width(w),
				config.font_scale_body
			)
		)
	)
end

function layout_engine.dropdown_label_gap()
	return config.space.x1
end

function layout_engine.get_dropdown_item_height(item, w)
	return config.space.x1
		+ layout_engine.dropdown_label_height(item, w)
		+ layout_engine.dropdown_label_gap()
		+ config.space.x9
		+ config.space.x2
end

function layout_engine.get_dropdown_panel_width(item, min_w, max_w)
	local longest_w = 0
	local options = item and item.options or {}
	for i = 1, #options do
		local option_w = primitives.measure_text_width(options[i], config.font_scale_body)
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
	return primitives.clamp(desired_w, min_w, math.max(min_w, max_w or min_w))
end

function layout_engine.get_active_groups(currentTab)
	local activeGroups = cache.active_groups
	local selected_heist_key = nil

	if currentTab and currentTab.id == "heist" then
		selected_heist_key = drawer.selected_key()
	end

	if
		cache.active_groups_tab == currentTab
		and cache.active_groups_subtab == selected_heist_key
		and cache.active_groups_revision == model.layout_revision
	then
		return activeGroups, selected_heist_key
	end

	layout_engine.clear_array(activeGroups)
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

	cache.active_groups_tab = currentTab
	cache.active_groups_subtab = selected_heist_key
	cache.active_groups_revision = model.layout_revision
	return activeGroups, selected_heist_key
end

local function flatten_groups_by_order(activeGroups, subtab_key, column_count)
	local ordered = cache.ordered_groups
	layout_engine.clear_array(ordered)

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

function layout_engine.get_item_height(item, col_w)
	if item.hidden then
		return 0
	end
	if item.type == "toggle" then
		return config.item_height.toggle
	elseif item.type == "button" then
		if col_w and col_w > 0 then
			local pad_x = config.space.x3
			local n = primitives.button_line_count(item.label, col_w - (pad_x * 2))
			return primitives.button_h_from_lines(n)
		end
		return config.item_height.button
	elseif item.type == "button_pair" then
		if col_w and col_w > 0 then
			local leftW, rightW = primitives.button_pair_half_widths(col_w)
			local nl = primitives.button_line_count(item.left and item.left.label, leftW)
			local nr = primitives.button_line_count(item.right and item.right.label, rightW)
			return primitives.button_h_from_lines(math.max(nl, nr))
		end
		return config.item_height.button
	elseif item.type == "slider" then
		return config.item_height.slider
	elseif item.type == "dropdown" then
		return layout_engine.get_dropdown_item_height(item, col_w)
	elseif item.type == "label" then
		return config.space.x6
	elseif item.type == "info" then
		local pad_x = config.space.x3
		local max_w = (col_w or 0) - (pad_x * 2)
		if max_w <= 0 then
			return config.space.x6
		end
		return primitives.info_item_height(primitives.info_item_text(item), max_w, config.font_scale_small)
	elseif item.type == "spacer" then
		return math.max(0, item.height or 0)
	end
	return 0
end

function layout_engine.is_auto_pairable_button(item)
	return type(item) == "table" and item.type == "button" and not item.hidden
end

function layout_engine.is_auto_pairable_dropdown(item)
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

function layout_engine.is_cut_slider_toggle_pair(left, right)
	local left_base = cut_control_base_id(left)
	local right_base = cut_control_base_id(right)
	if not left_base or left_base ~= right_base then
		return false
	end
	return (left.type == "slider" and right.type == "toggle") or (left.type == "toggle" and right.type == "slider")
end

function layout_engine.next_auto_pair_button_index(items, start_index)
	local i = start_index + 1
	while i <= #items do
		local item = items[i]
		if not item.hidden then
			if layout_engine.is_auto_pairable_button(item) then
				return i
			end
			return nil
		end
		i = i + 1
	end
	return nil
end

function layout_engine.next_auto_pair_dropdown_index(items, start_index)
	local i = start_index + 1
	while i <= #items do
		local item = items[i]
		if not item.hidden then
			if layout_engine.is_auto_pairable_dropdown(item) then
				return i
			end
			return nil
		end
		i = i + 1
	end
	return nil
end

function layout_engine.next_cut_control_pair_index(items, start_index)
	local item = items[start_index]
	local i = start_index + 1
	while i <= #items do
		local next_item = items[i]
		if not next_item.hidden then
			if layout_engine.is_cut_slider_toggle_pair(item, next_item) then
				return i
			end
			return nil
		end
		i = i + 1
	end
	return nil
end

function layout_engine.get_cut_control_pair_height()
	return config.cut_pair_height or (config.item_height.slider + config.item_height.toggle)
end

function layout_engine.get_group_actual_height(group, col_w)
	local cache_col_w = col_w or 0
	if
		group._cached_h
		and group._cached_layout_revision == model.layout_revision
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
		local item_h = layout_engine.get_item_height(item, col_w)
		local pair_index = nil
		if item_h > 0 then
			pair_index = layout_engine.next_cut_control_pair_index(items, i)
			if pair_index then
				item_h = layout_engine.get_cut_control_pair_height()
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
		elseif layout_engine.is_auto_pairable_button(item) then
			local button_pair_index = layout_engine.next_auto_pair_button_index(items, i)
			if button_pair_index then
				local pair_item = items[button_pair_index]
				if col_w and col_w > 0 then
					local leftW, rightW = primitives.button_pair_half_widths(col_w)
					local nl = primitives.button_line_count(item.label, leftW)
					local nr = primitives.button_line_count(pair_item.label, rightW)
					local pair_h = primitives.button_h_from_lines(math.max(nl, nr))
					h = h - item_h + pair_h
				end
				i = button_pair_index
			end
		elseif layout_engine.is_auto_pairable_dropdown(item) then
			local dropdown_pair_index = layout_engine.next_auto_pair_dropdown_index(items, i)
			if dropdown_pair_index then
				local pair_item = items[dropdown_pair_index]
				if col_w and col_w > 0 then
					local leftW, rightW = primitives.button_pair_half_widths(col_w)
					local pair_h = math.max(
						layout_engine.get_dropdown_item_height(item, leftW + (config.space.x3 * 2)),
						layout_engine.get_dropdown_item_height(pair_item, rightW + (config.space.x3 * 2))
					)
					h = h - item_h + pair_h
				end
				i = dropdown_pair_index
			end
		end
		i = i + 1
	end

	local min_h = (group and group.rect and group.rect.h) or 0
	if h < min_h then
		h = min_h
	end
	group._cached_h = h
	group._cached_layout_revision = model.layout_revision
	group._cached_col_w = cache_col_w
	return h
end

local UNMATCHED_PREF_ORDER_OFFSET = 1e9

local function distribute_groups_by_column(flattened, groups_by_column, column_count, group_heights, animation_subkey)
	for col = 1, column_count do
		layout_engine.clear_array(groups_by_column[col])
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

function layout_engine.groups_by_column(activeGroups, selected_heist_key, current_tab_id, column_count, col_w)
	local groups_by_column = cache.groups_by_column
	local animation_subkey = selected_heist_key or tostring(state.heist_subtab or 0)

	if
		cache.layout_dirty
		or cache.layout_revision ~= model.layout_revision
		or cache.layout_tab_id ~= current_tab_id
		or cache.layout_selected_heist_key ~= selected_heist_key
		or cache.layout_column_count ~= column_count
		or cache.layout_col_w ~= col_w
	then
		local ordered = flatten_groups_by_order(activeGroups, selected_heist_key, column_count)
		local group_heights = cache.group_heights
		for key in pairs(group_heights) do
			group_heights[key] = nil
		end
		for i = 1, #ordered do
			local group = ordered[i].group
			group_heights[group] = layout_engine.get_group_actual_height(group, col_w)
		end
		distribute_groups_by_column(ordered, groups_by_column, column_count, group_heights, animation_subkey)
		cache.layout_tab_id = current_tab_id
		cache.layout_selected_heist_key = selected_heist_key
		cache.layout_column_count = column_count
		cache.layout_col_w = col_w
		cache.layout_revision = model.layout_revision
		cache.layout_dirty = false
	end

	return groups_by_column, animation_subkey
end

return layout_engine
