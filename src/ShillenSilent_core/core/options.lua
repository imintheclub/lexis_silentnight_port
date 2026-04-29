local options = {}

local function option_label(option)
	return option and (option.name or option.label_key) or nil
end

function options.names(list)
	local names = {}
	for i = 1, #(list or {}) do
		names[i] = option_label(list[i])
	end
	return names
end

function options.names_range(list, first, last)
	local names = {}
	for i = first, last do
		if list[i] then
			names[#names + 1] = option_label(list[i])
		end
	end
	return names
end

function options.index_by_value(list, value, default_index)
	for i = 1, #(list or {}) do
		if list[i].value == value then
			return i
		end
	end
	return default_index or 1
end

function options.index_by_name(list, name, default_index)
	for i = 1, #(list or {}) do
		if list[i].name == name or list[i].label_key == name then
			return i
		end
	end
	return default_index or 1
end

function options.value_by_name(list, name, default_value)
	for i = 1, #(list or {}) do
		if list[i].name == name or list[i].label_key == name then
			return list[i].value
		end
	end
	return default_value
end

function options.resolve_value(list, value, fallback_value)
	for i = 1, #(list or {}) do
		if list[i].value == value then
			return value
		end
	end
	return fallback_value
end

return options
