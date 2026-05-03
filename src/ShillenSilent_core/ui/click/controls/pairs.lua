local config = require("ShillenSilent_core.ui.click.config")
local primitives = require("ShillenSilent_core.ui.click.primitives")
local layout_engine = require("ShillenSilent_core.ui.click.layout_engine")
local button = require("ShillenSilent_core.ui.click.controls.button")
local toggle = require("ShillenSilent_core.ui.click.controls.toggle")
local slider = require("ShillenSilent_core.ui.click.controls.slider")
local dropdown = require("ShillenSilent_core.ui.click.controls.dropdown")
local text_controls = require("ShillenSilent_core.ui.click.controls.text")

local pairs = {}

function pairs.render_group_item(item, group_x, item_y, group_w, pad_x)
	if item.type == "toggle" then
		toggle.draw(item, group_x, item_y, group_w, item_y)
		return item_y + config.item_height.toggle, nil
	end
	if item.type == "button" then
		button.draw_item(item, group_x, item_y, group_w)
		return item_y + layout_engine.get_item_height(item, group_w), nil
	end
	if item.type == "button_pair" then
		button.draw_pair_item(item, group_x, item_y, group_w)
		return item_y + layout_engine.get_item_height(item, group_w), nil
	end
	if item.type == "slider" then
		slider.draw(item, group_x, item_y, group_w, item_y)
		return item_y + config.item_height.slider, nil
	end
	if item.type == "dropdown" then
		local dd = dropdown.draw(item, group_x, item_y, group_w, item_y)
		return item_y + layout_engine.get_dropdown_item_height(item, group_w), dd
	end
	if item.type == "label" then
		return text_controls.draw_label(item, group_x, item_y, pad_x, group_w), nil
	end
	if item.type == "info" then
		return text_controls.draw_info(item, group_x, item_y, pad_x, group_w), nil
	end
	if item.type == "spacer" then
		return item_y + math.max(0, item.height or 0), nil
	end
	return item_y, nil
end

function pairs.render_button_pair_row(left_button, right_button, group_x, item_y, group_w)
	if right_button then
		local pair = { type = "button_pair", left = left_button, right = right_button }
		button.draw_pair_item(pair, group_x, item_y, group_w)
		return item_y + layout_engine.get_item_height(pair, group_w)
	else
		button.draw_item(left_button, group_x, item_y, group_w)
		return item_y + layout_engine.get_item_height(left_button, group_w)
	end
end

function pairs.render_cut_control_pair(first_item, second_item, group_x, item_y, group_w)
	local offset = config.cut_pair_inner_offset or config.item_height.toggle
	if first_item.type == "slider" then
		slider.draw(first_item, group_x, item_y, group_w, item_y)
		toggle.draw(second_item, group_x, item_y + offset, group_w, item_y + offset)
	else
		toggle.draw(first_item, group_x, item_y, group_w, item_y)
		slider.draw(second_item, group_x, item_y + offset, group_w, item_y + offset)
	end
	return item_y + layout_engine.get_cut_control_pair_height()
end

function pairs.render_dropdown_pair_row(left_dropdown, right_dropdown, group_x, item_y, group_w)
	if right_dropdown then
		local pad_x = config.space.x3
		local gap = config.space.x2_5
		local leftW, rightW = primitives.button_pair_half_widths(group_w)
		local baseX = group_x + pad_x
		local left_dd = dropdown.draw(left_dropdown, baseX - pad_x, item_y, leftW + (pad_x * 2), item_y)
		local right_dd =
			dropdown.draw(right_dropdown, baseX + leftW + gap - pad_x, item_y, rightW + (pad_x * 2), item_y)
		local row_h = math.max(
			layout_engine.get_dropdown_item_height(left_dropdown, leftW + (pad_x * 2)),
			layout_engine.get_dropdown_item_height(right_dropdown, rightW + (pad_x * 2))
		)
		return item_y + row_h, left_dd, right_dd
	end

	local dd = dropdown.draw(left_dropdown, group_x, item_y, group_w, item_y)
	return item_y + layout_engine.get_dropdown_item_height(left_dropdown, group_w), dd, nil
end

return pairs
