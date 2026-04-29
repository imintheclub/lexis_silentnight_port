local safe_access = require("ShillenSilent_core.core.safe_access")

local heist_cuts = {}

local function clamp_value(clamp, value)
	if type(clamp) == "function" then
		return clamp(value)
	end
	return math.floor(tonumber(value) or 0)
end

local function offset_for(offsets, key, index)
	if type(offsets) ~= "table" then
		return nil
	end
	return offsets[key] or offsets[index]
end

function heist_cuts.enabled_values(opts)
	local out = {}
	local player_keys = opts.player_keys or {}
	local cuts = opts.cuts or {}
	local enabled = opts.enabled or {}
	local clamp = opts.clamp

	for i = 1, #player_keys do
		local key = player_keys[i]
		out[key] = enabled[key] and clamp_value(clamp, cuts[key]) or 0
	end
	return out
end

function heist_cuts.write_player_globals(opts)
	local player_keys = opts.player_keys or {}
	local offsets = opts.offsets or {}
	local values = opts.values or heist_cuts.enabled_values(opts)
	local ok = true

	for i = 1, #player_keys do
		local key = player_keys[i]
		local offset = offset_for(offsets, key, i)
		if offset == nil then
			ok = false
		else
			ok = safe_access.set_global_int(offset, values[key] or 0) and ok
		end
	end

	return ok, values
end

function heist_cuts.write_apartment_globals(opts)
	local values = opts.values or heist_cuts.enabled_values(opts)
	local offsets = opts.offsets or {}
	local p1 = values.player1 or 0
	local p2 = values.player2 or 0
	local p3 = values.player3 or 0
	local p4 = values.player4 or 0
	local ok = true

	ok = safe_access.set_global_int(offsets.host_balance, 100 - (p1 + p2 + p3 + p4)) and ok
	ok = safe_access.set_global_int(offsets.player2_balance, p2) and ok
	ok = safe_access.set_global_int(offsets.player3_balance, p3) and ok
	ok = safe_access.set_global_int(offsets.player4_balance, p4) and ok

	local player_ok = heist_cuts.write_player_globals({
		player_keys = opts.player_keys,
		offsets = offsets,
		values = values,
	})
	ok = player_ok and ok

	return ok, values
end

return heist_cuts
