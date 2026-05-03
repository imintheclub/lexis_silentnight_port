local safe_access = {}

local MP_GLOBAL = 1574927

local function has_script_fn(name)
	return script and type(script[name]) == "function"
end

local function has_account_stats()
	return account and type(account.stats) == "function"
end

local function has_tunable_fn()
	return script and type(script.tunables) == "function"
end

local function get_stat_handle(stat_name)
	if not has_account_stats() then
		return nil
	end
	local ok, stat = pcall(account.stats, stat_name)
	if not ok then
		return nil
	end
	return stat
end

local function account_character()
	if account and type(account.character) == "function" then
		local ok, result = pcall(account.character)
		local character = math.floor(tonumber(ok and result or nil) or -1)
		if character == 0 or character == 1 then
			return character
		end
	end
	return nil
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

function safe_access.set_global_string(offset, value)
	if not has_script_fn("globals") then
		return false
	end
	local ok = pcall(function()
		script.globals(offset).str = value
	end)
	if ok then
		return true
	end
	return pcall(function()
		script.globals(offset).string = value
	end)
end

function safe_access.set_global_at_int(offset, at_index, value)
	if not has_script_fn("globals") then
		return false
	end
	local ok = pcall(function()
		script.globals(offset):at(at_index).int32 = value
	end)
	return ok
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

function safe_access.global_bool_supported(offset)
	if not has_script_fn("globals") then
		return false
	end
	local ok = pcall(function()
		local _ = script.globals(offset).bool
	end)
	return ok
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

function safe_access.set_tunable_int(name, value)
	if not has_tunable_fn() then
		return false
	end
	local ok = pcall(function()
		script.tunables(name).int32 = value
	end)
	return ok
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

function safe_access.get_stat_int(stat_name, fallback)
	local stat = get_stat_handle(stat_name)
	if not stat then
		return fallback
	end
	local ok, result = pcall(function()
		return stat.int32
	end)
	if not ok or result == nil then
		return fallback
	end
	return result
end

function safe_access.get_stat_string(stat_name, fallback)
	local stat = get_stat_handle(stat_name)
	if not stat then
		return fallback
	end
	local ok, result = pcall(function()
		if type(stat.str) == "string" and stat.str ~= "" then
			return stat.str
		end
		if type(stat.string) == "string" and stat.string ~= "" then
			return stat.string
		end
		return nil
	end)
	if not ok or result == nil then
		return fallback
	end
	return result
end

function safe_access.set_stat_int(stat_name, value)
	local stat = get_stat_handle(stat_name)
	if not stat then
		return false
	end
	local ok = pcall(function()
		stat.int32 = value
	end)
	return ok
end

function safe_access.set_stat_string(stat_name, value)
	local stat = get_stat_handle(stat_name)
	if not stat then
		return false
	end
	local ok = pcall(function()
		stat.str = value
	end)
	if ok then
		return true
	end
	return pcall(function()
		stat.string = value
	end)
end

function safe_access.set_stat_bool(stat_name, value)
	local stat = get_stat_handle(stat_name)
	if not stat then
		return false
	end
	local ok = pcall(function()
		stat.bool = value and true or false
	end)
	return ok
end

function safe_access.get_mp_prefix()
	local character = account_character()
	if character ~= nil then
		return character == 1 and "MP1_" or "MP0_"
	end
	local mp_idx = safe_access.get_global_int(MP_GLOBAL, 0)
	return mp_idx == 1 and "MP1_" or "MP0_"
end

function safe_access.get_active_mp_prefix()
	local character = account_character()
	if character ~= nil then
		return character == 1 and "MP1_" or "MP0_"
	end
	local last_char = safe_access.get_stat_int("MPPLY_LAST_MP_CHAR", 0)
	return (math.floor(tonumber(last_char) or 0) == 1) and "MP1_" or "MP0_"
end

function safe_access.stat_name(name, opts)
	if type(opts) == "table" and opts.raw then
		return name
	end
	local prefix = (type(opts) == "table" and opts.active) and safe_access.get_active_mp_prefix()
		or safe_access.get_mp_prefix()
	return prefix .. tostring(name)
end

function safe_access.get_mp_stat_int(stat_name, fallback)
	return safe_access.get_stat_int(safe_access.stat_name(stat_name), fallback)
end

function safe_access.get_active_mp_stat_int(stat_name, fallback)
	return safe_access.get_stat_int(safe_access.stat_name(stat_name, { active = true }), fallback)
end

function safe_access.set_mp_stat_int(stat_name, value)
	return safe_access.set_stat_int(safe_access.stat_name(stat_name), value)
end

function safe_access.set_mp_stat_int_map(values)
	local ok = true
	for stat_name, value in pairs(values or {}) do
		ok = safe_access.set_mp_stat_int(stat_name, value) and ok
	end
	return ok
end

function safe_access.set_stat_for_all_characters(stat_name, value)
	local ok0 = safe_access.set_stat_int("MP0_" .. stat_name, value)
	local ok1 = safe_access.set_stat_int("MP1_" .. stat_name, value)
	return ok0 and ok1
end

function safe_access.set_stat_pairs_for_all_characters(pairs_to_write)
	local ok = true
	for i = 1, #(pairs_to_write or {}) do
		ok = safe_access.set_stat_for_all_characters(pairs_to_write[i][1], pairs_to_write[i][2]) and ok
	end
	return ok
end

function safe_access.set_global_string_variants(field, value)
	if type(field) == "number" then
		return safe_access.set_global_string(field, value)
	end
	local ee_ok = safe_access.set_global_string(field.ee, value)
	local legacy_ok = safe_access.set_global_string(field.legacy, value)
	return ee_ok or legacy_ok
end

function safe_access.set_local_float_variants(script_name, field, value)
	if type(field) == "number" then
		return safe_access.set_local_float(script_name, field, value)
	end
	local ee_ok = safe_access.set_local_float(script_name, field.ee, value)
	local legacy_ok = safe_access.set_local_float(script_name, field.legacy, value)
	return ee_ok or legacy_ok
end

function safe_access.set_global_int_strided_variants(field, index, value)
	if type(field) == "number" then
		return safe_access.set_global_int(field, value)
	end
	local ee_offset = field.ee + (index * field.ee_stride)
	local legacy_offset = field.legacy + (index * field.legacy_stride)
	local ee_ok = safe_access.set_global_int(ee_offset, value)
	local legacy_ok = safe_access.set_global_int(legacy_offset, value)
	return ee_ok or legacy_ok
end

function safe_access.get_global_int_variants(field, fallback)
	if type(field) == "number" then
		return safe_access.get_global_int(field, fallback)
	end
	local val = safe_access.get_global_int(field.ee, nil)
	if val ~= nil then
		return val
	end
	val = safe_access.get_global_int(field.legacy, nil)
	if val ~= nil then
		return val
	end
	return fallback
end

function safe_access.set_global_int_variants(field, value)
	if type(field) == "number" then
		return safe_access.set_global_int(field, value)
	end
	local ee_ok = safe_access.set_global_int(field.ee, value)
	local legacy_ok = safe_access.set_global_int(field.legacy, value)
	return ee_ok or legacy_ok
end

function safe_access.set_global_bool_variants(field, value)
	if type(field) == "number" then
		return safe_access.set_global_bool(field, value)
	end
	local ee_ok = safe_access.set_global_bool(field.ee, value)
	local legacy_ok = safe_access.set_global_bool(field.legacy, value)
	return ee_ok or legacy_ok
end

function safe_access.get_local_int_variants(script_name, field, fallback)
	if type(field) == "number" then
		return safe_access.get_local_int(script_name, field, fallback)
	end
	local val = safe_access.get_local_int(script_name, field.ee, nil)
	if val ~= nil then
		return val
	end
	val = safe_access.get_local_int(script_name, field.legacy, nil)
	if val ~= nil then
		return val
	end
	return fallback
end

function safe_access.set_local_int_variants(script_name, field, value)
	if type(field) == "number" then
		return safe_access.set_local_int(script_name, field, value)
	end
	local ee_ok = safe_access.set_local_int(script_name, field.ee, value)
	local legacy_ok = safe_access.set_local_int(script_name, field.legacy, value)
	return ee_ok or legacy_ok
end

function safe_access.set_tunable_int_variants(field, value)
	if type(field) == "string" then
		return safe_access.set_tunable_int(field, value)
	end
	local any = false
	for _, name in pairs(field) do
		if type(name) == "string" then
			any = safe_access.set_tunable_int(name, value) or any
		end
	end
	return any
end

function safe_access.get_global_int_strided_variants(field, index, fallback)
	if type(field) == "number" then
		return safe_access.get_global_int(field, fallback)
	end
	local ee_offset = field.ee + (index * field.ee_stride)
	local legacy_offset = field.legacy + (index * field.legacy_stride)
	local val = safe_access.get_global_int(ee_offset, nil)
	if val ~= nil then
		return val
	end
	val = safe_access.get_global_int(legacy_offset, nil)
	if val ~= nil then
		return val
	end
	return fallback
end

return safe_access
