local i18n = require("ShillenSilent_core.i18n")

local notify_core = {}

function notify_core.push(title_key, message_key, duration, vars)
	if not notify or type(notify.push) ~= "function" then
		return false
	end
	local title = i18n.t(title_key, vars)
	local message = i18n.t(message_key, vars)
	notify.push(title, message, { time = duration or 2500 })
	return true
end

function notify_core.feature(title_key, default_duration)
	return function(message_key, duration, vars)
		return notify_core.push(title_key, message_key, duration or default_duration or 2200, vars)
	end
end

function notify_core.raw(title, message, duration)
	if not notify or type(notify.push) ~= "function" then
		return false
	end
	notify.push(tostring(title), tostring(message), { time = duration or 2500 })
	return true
end

return notify_core
