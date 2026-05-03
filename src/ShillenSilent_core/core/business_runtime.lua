local safe_access = require("ShillenSilent_core.core.safe_access")

local business_runtime = {}

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

local function packed_slots(slots)
	if slots == "active" then
		local last_char = account_character() or safe_access.get_stat_int("MPPLY_LAST_MP_CHAR", 0)
		return { math.floor(tonumber(last_char) or 0) }
	end
	return slots or { 0 }
end

local function native_result_ok(result)
	if not result then
		return false
	end
	if result.bool ~= nil then
		return result.bool == true or tonumber(result.bool) == 1
	end
	return tonumber(result.int) == 1
end

function business_runtime.active_character_slot()
	local last_char = account_character() or safe_access.get_stat_int("MPPLY_LAST_MP_CHAR", 0)
	return math.floor(tonumber(last_char) or 0)
end

function business_runtime.start_invite_only_session()
	if not (invoker and invoker.call) then
		return false
	end
	local result = invoker.call(0xED34C0C02C098BB7, 0, 32)
	local started = native_result_ok(result)
	if not started then
		local fallback = invoker.call(0x6F3D4ED9BEE4E61D, 0, 32, true)
		started = native_result_ok(fallback)
	end
	return started
end

function business_runtime.write_packed_bool(idx, value, slots, native_hash)
	if not (invoker and invoker.call and type(native_hash) == "number" and type(idx) == "number") then
		return false
	end

	local ok_any = false
	for _, slot in ipairs(packed_slots(slots)) do
		local ok = pcall(function()
			invoker.call(native_hash, idx, value and true or false, slot)
		end)
		ok_any = ok or ok_any
	end
	return ok_any
end

function business_runtime.write_packed_bool_range(first_idx, last_idx, value, slots, native_hash)
	local first = tonumber(first_idx)
	local last = tonumber(last_idx)
	if not first or not last then
		return false
	end

	local ok_any = false
	for idx = first, last do
		ok_any = business_runtime.write_packed_bool(idx, value, slots, native_hash) or ok_any
	end
	return ok_any
end

function business_runtime.write_packed_int(idx, value, slots, native_hash)
	if not (invoker and invoker.call and type(native_hash) == "number" and type(idx) == "number") then
		return false
	end

	local ok_any = false
	for _, slot in ipairs(packed_slots(slots)) do
		local ok = pcall(function()
			invoker.call(native_hash, idx, math.floor(tonumber(value) or 0), slot)
		end)
		ok_any = ok or ok_any
	end
	return ok_any
end

function business_runtime.read_packed_int(idx, slot, native_hash)
	if not (memory and invoker and invoker.call and memory.alloc_int and memory.read_int) then
		return nil
	end
	if type(native_hash) ~= "number" or type(idx) ~= "number" then
		return nil
	end

	local buf = memory.alloc_int()
	if not buf then
		return nil
	end

	local value = nil
	local ok_call = pcall(function()
		invoker.call(native_hash, idx, buf, slot or 0)
	end)
	if ok_call then
		local ok_read, read_value = pcall(memory.read_int, buf)
		if ok_read then
			value = tonumber(read_value)
		end
	end

	if memory.free then
		pcall(memory.free, buf)
	elseif memory.free_int then
		pcall(memory.free_int, buf)
	end

	return value
end

function business_runtime.apply_tunables(tunables, value)
	local ok = true
	for _, tunable in ipairs(tunables or {}) do
		if tunable.type == "float" then
			ok = safe_access.set_tunable_float(tunable.name, value) and ok
		else
			ok = safe_access.set_tunable_int(tunable.name, value) and ok
		end
	end
	return ok
end

function business_runtime.restore_tunables(tunables)
	local ok = true
	for _, tunable in ipairs(tunables or {}) do
		local default = tunable.default
		if tunable.type == "float" then
			ok = safe_access.set_tunable_float(tunable.name, default) and ok
		else
			ok = safe_access.set_tunable_int(tunable.name, default) and ok
		end
	end
	return ok
end

function business_runtime.set_tunable_list_toggle(opts)
	local enabled = opts.enabled == true
	opts.set_active(enabled)
	local active = opts.is_active()
	local ok = active and business_runtime.apply_tunables(opts.tunables, opts.enabled_value or 0)
		or business_runtime.restore_tunables(opts.tunables)
	return active, ok
end

function business_runtime.set_cached_tunable_toggle(opts)
	local enabled = opts.enabled == true
	local cache = opts.cache or {}
	local cache_key = opts.cache_key
	local tunable = opts.tunable
	local default = opts.default
	local disabled_value = opts.disabled_value

	if enabled then
		if cache_key and cache[cache_key] == nil then
			cache[cache_key] = safe_access.get_tunable_int(tunable, default)
		end
		local ok = safe_access.set_tunable_int(tunable, disabled_value)
		opts.set_active(true)
		return opts.is_active(), ok
	end

	local restore_value = (cache_key and cache[cache_key]) or default
	local ok = safe_access.set_tunable_int(tunable, restore_value)
	opts.set_active(false)
	return opts.is_active(), ok
end

function business_runtime.set_recurring_tunable_loop(opts)
	local was_active = opts.is_active()
	opts.set_active(opts.enabled == true)
	local active = opts.is_active()
	local ok

	if active then
		if not was_active and opts.start_invite_only ~= false then
			business_runtime.start_invite_only_session()
		end
		ok = opts.apply()
	else
		ok = opts.restore()
	end

	return active, ok
end

function business_runtime.tick_recurring_tunable_loop(opts)
	if not opts.is_active() then
		return false
	end
	return opts.apply()
end

function business_runtime.set_xp_multiplier(enabled, tunable_name)
	if not tunable_name then
		return true
	end
	return safe_access.set_tunable_float(tunable_name, enabled and 0.0 or 1.0)
end

function business_runtime.player_id()
	local me = players and players.me and players.me()
	return me and tonumber(me.id) or 0
end

function business_runtime.start_script(script_cfg)
	if type(script_cfg) ~= "table" or type(script_cfg.name) ~= "string" then
		return false
	end
	if safe_access.is_script_running(script_cfg.name) then
		return true
	end

	local ok, native_api = pcall(require, "natives")
	if ok and native_api then
		if type(native_api.request_script) == "function" then
			pcall(native_api.request_script, script_cfg.name)
			util.yield(100)
		end
		if type(native_api.start_new_script) == "function" then
			local result_ok, result =
				pcall(native_api.start_new_script, script_cfg.name, tonumber(script_cfg.stack) or 4592)
			return result_ok and tonumber(result) ~= 0
		end
	end

	if invoker and invoker.call then
		local call_ok, result =
			pcall(invoker.call, 0xE81651AD79516E48, script_cfg.name, tonumber(script_cfg.stack) or 4592)
		return call_ok and result and tonumber(result.int) ~= 0
	end

	return false
end

return business_runtime
