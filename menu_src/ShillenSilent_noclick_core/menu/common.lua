local common = {}

function common.clamp_int(value, min_value, max_value)
	local number = tonumber(value)
	if not number then
		return min_value
	end
	local floored = math.floor(number)
	if floored < min_value then
		return min_value
	end
	if floored > max_value then
		return max_value
	end
	return floored
end

function common.clamp_float(value, min_value, max_value)
	local number = tonumber(value)
	if not number then
		return min_value
	end
	if number < min_value then
		return min_value
	end
	if number > max_value then
		return max_value
	end
	return number
end

function common.find_index_by_value(options, value, default_index)
	for i = 1, #options do
		if options[i].value == value then
			return i
		end
	end
	return default_index or 1
end

function common.safe_call(fn, ...)
	local ok, err = pcall(fn, ...)
	if not ok and notify then
		notify.push("ShillenSilent Menu", tostring(err), 3000)
	end
	return ok
end

function common.with_sync(ctx, fn)
	ctx.syncing = true
	local ok = common.safe_call(fn)
	ctx.syncing = false
	return ok
end

function common.bind_click(option, fn)
	option:event(menu.event.click, function(opt)
		common.safe_call(fn, opt)
	end)
end

function common.bind_change(ctx, option, fn)
	option:event(menu.event.click, function(opt)
		if ctx.syncing then
			return
		end
		common.safe_call(fn, opt)
	end)
end

function common.set_control_value(ctx, control, value)
	if control == nil then
		return
	end
	common.with_sync(ctx, function()
		control.value = value
	end)
end

function common.add_button(parent_menu, label, fn)
	local button = parent_menu:button(label)
	common.bind_click(button, fn)
	return button
end

function common.add_toggle(ctx, parent_menu, label, get_value, set_value)
	local toggle = parent_menu:toggle(label)
	toggle.value = get_value() and true or false
	common.bind_change(ctx, toggle, function(opt)
		local enabled = (opt and opt.value) and true or false
		set_value(enabled)
	end)
	return toggle
end

function common.add_number_int(ctx, parent_menu, label, min_value, max_value, step, get_value, set_value)
	local number = parent_menu:number_int(label, menu.type.scroll):fmt("%i", min_value, max_value, step)
	number.value = common.clamp_int(get_value(), min_value, max_value)
	common.bind_change(ctx, number, function(opt)
		local value = common.clamp_int(opt and opt.value or number.value, min_value, max_value)
		set_value(value)
	end)
	return number
end

function common.add_number_float(ctx, parent_menu, label, min_value, max_value, step, get_value, set_value)
	local number = parent_menu:number_float(label, menu.type.scroll):fmt("%.2f", min_value, max_value, step)
	number.value = common.clamp_float(get_value(), min_value, max_value)
	common.bind_change(ctx, number, function(opt)
		local value = common.clamp_float(opt and opt.value or number.value, min_value, max_value)
		set_value(value)
	end)
	return number
end

function common.add_combo_options(ctx, parent_menu, label, options, get_value, set_value)
	local entries = {}
	for i = 1, #options do
		entries[i] = { options[i].name, i }
	end

	local combo = parent_menu:combo_int(label, entries, menu.type.scroll)
	combo.value = common.find_index_by_value(options, get_value(), 1)
	common.bind_change(ctx, combo, function(opt)
		local idx = common.clamp_int(opt and opt.value or combo.value, 1, #options)
		local selected = options[idx]
		if selected then
			set_value(selected.value, idx, selected.name)
		end
	end)
	return combo
end

function common.add_combo_entries(ctx, parent_menu, label, entries, get_index, set_index)
	local combo = parent_menu:combo_int(label, entries, menu.type.scroll)
	combo.value = get_index()
	common.bind_change(ctx, combo, function(opt)
		local idx = common.clamp_int(opt and opt.value or combo.value, 1, #entries)
		set_index(idx)
	end)
	return combo
end

return common
