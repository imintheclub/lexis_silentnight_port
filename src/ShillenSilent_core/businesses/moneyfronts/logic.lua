local biz = require("ShillenSilent_core.businesses.shared")

local MONEYFRONTS_LOCATIONS = {
	{ name = "Car Wash (Hands On)", x = -3.0, y = -1396.5, z = 29.3, owned_stat = "SB_CAR_WASH_OWNED" },
	{ name = "Heli Tours (Higgins)", x = -749.3, y = -1510.2, z = 5.0, owned_stat = "SB_HELI_TOURS_OWNED" },
	{ name = "Weed Shop (Smoke on the Water)", x = -1162.9, y = -1566.8, z = 4.4, owned_stat = "SB_WEED_SHOP_OWNED" },
}
local selected_loc = 1

-- Money Fronts heat uses packed int stats in both character slots.
-- Mirrors SyloCore indices for Car Wash / Heli Tours / Weed Shop.
local STAT_SET_PACKED_INT = 0x1581503AE529CD2E
local STAT_GET_PACKED_INT = 0x0BC900A27CBBAC55
local HEAT_PACKED_INDICES = { 24924, 24925, 24926 }
local HEAT_CHAR_SLOTS = { 0, 1 }
local HEAT_MIN = 0
local HEAT_MAX = 100
local HEAT_LOCK_THRESHOLD = 10

local _heat_editor_value = 0
local _heat_lock_active = false

local function clamp_heat(v)
	local n = tonumber(v) or HEAT_MIN
	n = math.floor(n)
	if n < HEAT_MIN then
		return HEAT_MIN
	end
	if n > HEAT_MAX then
		return HEAT_MAX
	end
	return n
end

local function get_locations()
	return MONEYFRONTS_LOCATIONS
end

local function get_selected_loc()
	return selected_loc
end

local function set_selected_loc(idx)
	selected_loc = idx
end

local function is_location_owned(loc)
	if not loc or not loc.owned_stat then
		return false
	end
	local mp = biz.GetMP()
	local candidates = { mp .. loc.owned_stat, "MPX_" .. loc.owned_stat, loc.owned_stat }
	for _, stat_name in ipairs(candidates) do
		local value = biz.get_stat_int(stat_name, 0)
		if value and value > 0 then
			return true
		end
	end
	return false
end

local function pick_owned_location()
	local selected = MONEYFRONTS_LOCATIONS[selected_loc]
	if selected and is_location_owned(selected) then
		return selected
	end
	for _, loc in ipairs(MONEYFRONTS_LOCATIONS) do
		if is_location_owned(loc) then
			return loc
		end
	end
	return nil
end

local function teleport()
	local loc = pick_owned_location() or MONEYFRONTS_LOCATIONS[selected_loc]
	if not loc then
		return
	end
	biz.run_coords_teleport("Money Fronts", "Teleported to " .. loc.name, loc.x, loc.y, loc.z, false, nil)
end

local function set_front_heat(value, silent)
	local heat = clamp_heat(value)
	local any_ok = false

	for _, idx in ipairs(HEAT_PACKED_INDICES) do
		if type(idx) == "number" and idx >= 0 then
			for _, slot in ipairs(HEAT_CHAR_SLOTS) do
				local ok = pcall(function()
					invoker.call(STAT_SET_PACKED_INT, idx, heat, slot)
				end)
				if ok then
					any_ok = true
				end
			end
		end
	end

	_heat_editor_value = heat
	if (not silent) and notify then
		notify.push("Money Fronts", any_ok and ("Heat set to " .. tostring(heat)) or "Heat apply failed", 2000)
	end
	return any_ok
end

local function read_packed_int(idx, slot)
	if not (memory and invoker and invoker.call and memory.alloc_int and memory.read_int) then
		return nil
	end

	local buf = memory.alloc_int()
	if not buf then
		return nil
	end

	local value = nil
	local ok_call = pcall(function()
		invoker.call(STAT_GET_PACKED_INT, idx, buf, slot or 0)
	end)
	if ok_call then
		local ok_read, v = pcall(memory.read_int, buf)
		if ok_read then
			value = tonumber(v)
		end
	end

	if memory.free then
		pcall(memory.free, buf)
	elseif memory.free_int then
		pcall(memory.free_int, buf)
	end

	return value
end

local function get_heat_editor_value()
	return _heat_editor_value
end

local function set_heat_editor_value(value)
	_heat_editor_value = clamp_heat(value)
end

local function apply_heat_editor_value()
	return set_front_heat(_heat_editor_value, false)
end

local function reset_heat()
	return set_front_heat(0, false)
end

local function reset_safe_production_state()
	local ok = set_front_heat(0, true)
	if notify then
		notify.push("Money Fronts", ok and "Safe production state reset" or "Safe production reset failed", 2200)
	end
	return ok
end

local function set_heat_lock_active(enabled)
	_heat_lock_active = enabled == true
	if _heat_lock_active then
		set_front_heat(0, true)
	end
	if notify then
		notify.push("Money Fronts", _heat_lock_active and "Heat lock enabled" or "Heat lock disabled", 2000)
	end
end

local function get_heat_lock_active()
	return _heat_lock_active
end

local function tick_heat_lock()
	if not _heat_lock_active then
		return
	end

	for _, idx in ipairs(HEAT_PACKED_INDICES) do
		if type(idx) == "number" and idx >= 0 then
			for _, slot in ipairs(HEAT_CHAR_SLOTS) do
				local value = read_packed_int(idx, slot)
				if value and value > HEAT_LOCK_THRESHOLD then
					set_front_heat(0, true)
					return
				end
			end
		end
	end
end

local moneyfronts_logic = {
	get_locations = get_locations,
	get_selected_loc = get_selected_loc,
	set_selected_loc = set_selected_loc,
	teleport = teleport,
	get_heat_editor_value = get_heat_editor_value,
	set_heat_editor_value = set_heat_editor_value,
	apply_heat_editor_value = apply_heat_editor_value,
	reset_heat = reset_heat,
	reset_safe_production_state = reset_safe_production_state,
	set_heat_lock_active = set_heat_lock_active,
	get_heat_lock_active = get_heat_lock_active,
	tick_heat_lock = tick_heat_lock,
}

return moneyfronts_logic
