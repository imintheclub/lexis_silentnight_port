local numbers = {}

function numbers.clamp_number(value, min_value, max_value, fallback)
	local number = tonumber(value)
	if not number then
		number = tonumber(fallback)
	end
	if not number then
		number = min_value
	end
	if number < min_value then
		return min_value
	end
	if number > max_value then
		return max_value
	end
	return number
end

function numbers.clamp_int(value, min_value, max_value, fallback)
	return math.floor(numbers.clamp_number(value, min_value, max_value, fallback))
end

return numbers
