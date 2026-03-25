local safe_access = {}

local function has_script_fn(name)
	return script and type(script[name]) == "function"
end

local function has_account_stats()
	return account and type(account.stats) == "function"
end

local function has_tunable_fn()
	return script and type(script.tunables) == "function"
end

function safe_access.is_script_running(script_name)
	if not has_script_fn("running") then
		return false
	end
	local ok, result = pcall(script.running, script_name)
	if not ok then
		return false
	end
	return result and true or false
end

function safe_access.force_host(script_name)
	if not has_script_fn("force_host") then
		return false
	end
	local ok, result = pcall(script.force_host, script_name)
	if not ok then
		return false
	end
	return result and true or false
end

function safe_access.set_global_int(offset, value)
	if not has_script_fn("globals") then
		return false
	end
	local ok = pcall(function()
		script.globals(offset).int32 = value
	end)
	return ok
end

function safe_access.get_global_int(offset, fallback)
	if not has_script_fn("globals") then
		return fallback
	end
	local ok, result = pcall(function()
		return script.globals(offset).int32
	end)
	if not ok or result == nil then
		return fallback
	end
	return result
end

function safe_access.set_global_bool(offset, value)
	if not has_script_fn("globals") then
		return false
	end
	local ok = pcall(function()
		script.globals(offset).bool = value and true or false
	end)
	return ok
end

function safe_access.get_global_bool(offset, fallback)
	if not has_script_fn("globals") then
		return fallback
	end
	local ok, result = pcall(function()
		return script.globals(offset).bool
	end)
	if not ok or result == nil then
		return fallback
	end
	return result and true or false
end

function safe_access.set_local_int(script_name, offset, value)
	if not has_script_fn("locals") then
		return false
	end
	local ok = pcall(function()
		script.locals(script_name, offset).int32 = value
	end)
	return ok
end

function safe_access.get_local_int(script_name, offset, fallback)
	if not has_script_fn("locals") then
		return fallback
	end
	local ok, result = pcall(function()
		return script.locals(script_name, offset).int32
	end)
	if not ok or result == nil then
		return fallback
	end
	return result
end

function safe_access.set_local_float(script_name, offset, value)
	if not has_script_fn("locals") then
		return false
	end
	local ok = pcall(function()
		script.locals(script_name, offset).float = value
	end)
	return ok
end

function safe_access.get_tunable_int(name, fallback)
	if not has_tunable_fn() then
		return fallback
	end
	local ok, result = pcall(function()
		return script.tunables(name).int32
	end)
	if not ok or result == nil then
		return fallback
	end
	return result
end

function safe_access.set_tunable_int(name, value)
	if not has_tunable_fn() then
		return false
	end
	local ok = pcall(function()
		script.tunables(name).int32 = value
	end)
	return ok
end

function safe_access.get_tunable_float(name, fallback)
	if not has_tunable_fn() then
		return fallback
	end
	local ok, result = pcall(function()
		return script.tunables(name).float
	end)
	if not ok or result == nil then
		return fallback
	end
	return result
end

function safe_access.set_tunable_float(name, value)
	if not has_tunable_fn() then
		return false
	end
	local ok = pcall(function()
		script.tunables(name).float = value
	end)
	return ok
end

function safe_access.get_stat_int(stat_name, fallback, profile)
	if not has_account_stats() then
		return fallback
	end
	local ok, result = pcall(function()
		local stat = account.stats(stat_name, profile)
		if not stat then
			return nil
		end
		return stat.int32
	end)
	if not ok or result == nil then
		return fallback
	end
	return result
end

function safe_access.set_stat_int(stat_name, value, profile)
	if not has_account_stats() then
		return false
	end
	local ok = pcall(function()
		local stat = account.stats(stat_name, profile)
		if not stat then
			error("stat unavailable")
		end
		stat.int32 = value
	end)
	return ok
end

function safe_access.get_stat_bool(stat_name, fallback, profile)
	if not has_account_stats() then
		return fallback
	end
	local ok, result = pcall(function()
		local stat = account.stats(stat_name, profile)
		if not stat then
			return nil
		end
		return stat.bool
	end)
	if not ok or result == nil then
		return fallback
	end
	return result
end

function safe_access.set_stat_bool(stat_name, value, profile)
	if not has_account_stats() then
		return false
	end
	local ok = pcall(function()
		local stat = account.stats(stat_name, profile)
		if not stat then
			error("stat unavailable")
		end
		stat.bool = value and true or false
	end)
	return ok
end

return safe_access
