local data = {
	feature_id = "acidlab",
}

data.status = {
	stopped = "stopped",
	running = "running",
	full = "full",
}

function data.status_label_key(status)
	return "acidlab.status." .. tostring(status or data.status.stopped)
end

function data.normalize_status(status)
	local value = tostring(status or data.status.stopped)
	return data.status[value] or data.status.stopped
end

return data
