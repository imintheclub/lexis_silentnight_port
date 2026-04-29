local data = require("ShillenSilent_core.features.businesses.mc.data")

local state = {
	fast_production = {
		active = false,
		status = data.status.stopped,
	},
	sub_production = {
		active = {},
		status = {},
	},
	protections = {
		raids_default = nil,
		raids_active = false,
		reminders_default = nil,
		reminders_active = false,
	},
}

for i = 1, #data.subs do
	local key = data.subs[i].key
	state.sub_production.active[key] = false
	state.sub_production.status[key] = data.status.stopped
end

function state.set_fast_production(enabled)
	state.fast_production.active = enabled == true
	state.fast_production.status = state.fast_production.active and data.status.running or data.status.stopped
end

function state.set_fast_status(status)
	state.fast_production.status = data.normalize_status(status)
end

function state.set_sub_production(sub_key, enabled)
	if not data.find_sub(sub_key) then
		return false
	end
	state.sub_production.active[sub_key] = enabled == true
	state.sub_production.status[sub_key] = state.sub_production.active[sub_key] and data.status.running
		or data.status.stopped
	return true
end

function state.set_sub_status(sub_key, status)
	if not data.find_sub(sub_key) then
		return false
	end
	state.sub_production.status[sub_key] = data.normalize_status(status)
	return true
end

function state.apply_sub_flags(flags)
	for i = 1, #data.subs do
		local key = data.subs[i].key
		state.set_sub_production(key, flags and flags[key] == true)
	end
end

function state.set_reminders_active(enabled)
	state.protections.reminders_active = enabled == true
end

function state.set_raids_active(enabled)
	state.protections.raids_active = enabled == true
end

return state
