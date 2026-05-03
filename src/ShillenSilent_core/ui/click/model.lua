local config = require("ShillenSilent_core.ui.click.config")

local model = {
	tabs = {},
	currentTab = nil,
	layout_revision = 0,
}

function model.mark_layout_dirty()
	model.layout_revision = model.layout_revision + 1
end

function model.tab(id, label, hidden)
	local tab = { id = id, label = label, groups = {}, hidden = hidden or false }
	table.insert(model.tabs, tab)
	model.mark_layout_dirty()
	if #model.tabs == 1 and not tab.hidden then
		model.currentTab = tab
	end
	return tab
end

function model.group(tabRef, label, x, y, w, min_h, heist_subtab)
	local group =
		{ label = label, items = {}, rect = { x = x, y = y, w = w, h = min_h or 100 }, heist_subtab = heist_subtab }
	table.insert(tabRef.groups, group)
	model.mark_layout_dirty()
	return group
end

function model.toggle(groupRef, configKey, label, defaultState, onChange, tooltip)
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
	model.mark_layout_dirty()
	return item
end

function model.slider(groupRef, configKey, label, min, max, defaultVal, onChange, tooltip, step)
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
	model.mark_layout_dirty()
	return item
end

function model.button(groupRef, id, label, onClick, tooltip, disabled, color)
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
	model.mark_layout_dirty()
	return item
end

function model.button_pair(
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
	model.mark_layout_dirty()
	return item
end

function model.dropdown(groupRef, configKey, label, options, defaultIdx, onChange, tooltip)
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
	model.mark_layout_dirty()
	return item
end

function model.label(groupRef, text, color)
	local item = { type = "label", text = text, color = color }
	table.insert(groupRef.items, item)
	model.mark_layout_dirty()
	return item
end

function model.info(groupRef, text, color)
	local item = { type = "info", text = text, color = color }
	table.insert(groupRef.items, item)
	model.mark_layout_dirty()
	return item
end

function model.spacer(groupRef, height)
	local item = { type = "spacer", height = math.max(0, height or config.space.x2) }
	table.insert(groupRef.items, item)
	model.mark_layout_dirty()
	return item
end

return model
