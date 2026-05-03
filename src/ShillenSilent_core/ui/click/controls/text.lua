local config = require("ShillenSilent_core.ui.click.config")
local primitives = require("ShillenSilent_core.ui.click.primitives")

local text_controls = {}

function text_controls.draw_label(item, x, y, pad_x, group_w)
	local labelCol = item.color or config.colors.text_sec
	local text = item.text
	if group_w then
		local max_w = group_w - (pad_x * 2)
		if max_w > 0 then
			text = primitives.text_with_ellipsis(text, max_w, config.font_scale_small)
		end
	end
	primitives.render_text(text, x + pad_x, y + config.space.x3, config.font_scale_small, labelCol)
	return y + config.space.x6
end

function text_controls.draw_info(item, x, y, pad_x, group_w)
	local text_col = item.color or config.colors.text_sec
	local scale = config.font_scale_small
	local max_w = group_w - (pad_x * 2)
	local text = primitives.info_item_text(item)
	local item_h = primitives.info_item_height(text, max_w, scale)
	primitives.render_wrapped_text(text, x + pad_x, y + primitives.info_item_pad_top(), max_w, scale, text_col)
	return y + item_h
end

return text_controls
