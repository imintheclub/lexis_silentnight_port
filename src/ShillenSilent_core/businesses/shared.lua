-- Shared helpers reused across all business modules.
local core = require("ShillenSilent_core.core.bootstrap")
local coords_teleport = require("ShillenSilent_core.shared.coords_teleport")
local presets = require("ShillenSilent_core.shared.presets_and_shared")

local run_guarded_job = core.run_guarded_job
local run_coords_teleport = coords_teleport.run_coords_teleport
local GetMP = presets.GetMP

local function set_global_int(offset, value)
	local ok = pcall(function()
		script.globals(offset).int32 = value
	end)
	return ok
end

local function get_global_int(offset, default)
	local ok, value = pcall(function()
		return script.globals(offset).int32
	end)
	if ok and value ~= nil then
		return value
	end
	return default
end

local function set_stat_int(stat_name, value)
	local ok = pcall(function()
		local stat = account.stats(stat_name)
		if not stat then
			error("missing stat")
		end
		stat.int32 = value
	end)
	return ok
end

local function get_stat_int(stat_name, default)
	local ok, value = pcall(function()
		local stat = account.stats(stat_name)
		if not stat then
			error("missing stat")
		end
		return stat.int32
	end)
	if ok and value ~= nil then
		return value
	end
	return default
end

local function set_tunable_int(name, value)
	local ok = pcall(function()
		script.tunables(name).int32 = value
	end)
	return ok
end

local function get_tunable_int(name, default)
	local ok, value = pcall(function()
		return script.tunables(name).int32
	end)
	if ok and value ~= nil then
		return value
	end
	return default
end

local function is_script_running(name)
	local ok, result = pcall(script.running, name)
	return ok and result and true or false
end

local function set_local_int(script_name, offset, value)
	local ok = pcall(function()
		script.locals(script_name, offset).int32 = value
	end)
	return ok
end

local function get_local_int(script_name, offset, fallback)
	local ok, value = pcall(function()
		return script.locals(script_name, offset).int32
	end)
	if ok and value ~= nil then
		return value
	end
	return fallback
end

local function force_script_host(script_name)
	local ok, result = pcall(script.force_host, script_name)
	return ok and result and true or false
end

-- Supply fill: writes 1 to SUPPLIES_BASE+slot 7 times with 5ms yielding.
-- Must be called inside a guarded job.
local SUPPLIES_BASE = 1673814
local function fill_supply_slot(slot)
	for _ = 1, 7 do
		set_global_int(SUPPLIES_BASE + slot, 1)
		util.yield(5)
	end
end

-- Production timer base (derived from bunker trigger + bunker slot).
-- Slot layout: Meth=1 Weed=2 Cocaine=3 Counterfeit=4 Forgery=5 Bunker=6 AcidLab=7
local BUNKER_TRIG1 = 2708936
local BUNKER_SLOT = 6
local TIMER_ROOT = BUNKER_TRIG1 - ((BUNKER_SLOT - 1) * 2) - 1

-- Advance production timer for one slot (equivalent to one production tick).
local function production_tick(slot)
	local trig1 = TIMER_ROOT + 1 + (slot - 1) * 2
	local trig2 = trig1 + 1
	set_global_int(SUPPLIES_BASE + slot, 1)
	set_global_int(trig1, 0)
	set_global_int(trig2, 1)
end

-- Look up a map blip by sprite ID and return its world coordinates.
-- This is the primary teleport method: the game places the blip at the exact
-- entrance of whatever property the player owns, so no hardcoded coords needed.
-- Returns x, y, z or nil if the blip isn't on the map or has zero coords.
local function get_blip_coords(sprite_id)
	local ok_blip, blip = pcall(function()
		return invoker.call(0x1BEDE233E6CD2A1F, sprite_id).int -- GET_FIRST_BLIP_INFO_ID
	end)
	if not ok_blip or not blip or blip == 0 then
		return nil
	end
	local ok_exists, exists = pcall(function()
		return invoker.call(0xA6DB27D19ECBB7DA, blip).bool -- DOES_BLIP_EXIST
	end)
	if not ok_exists or not exists then
		return nil
	end
	local ok_vec, vec = pcall(function()
		return invoker.call(0x586AFE3FF72D996E, blip).scr_vec3 -- GET_BLIP_COORDS
	end)
	if not ok_vec or not vec then
		return nil
	end
	local x, y, z = vec.x, vec.y, vec.z
	if not x or not y or not z or (x == 0 and y == 0 and z == 0) then
		return nil
	end
	return x, y, z
end

-- Read an ownership stat, trying the current MP character prefix then MPX fallback.
-- Returns the raw property ID integer (> 0) or nil if not owned / stat unreadable.
local function read_owned_id(stat_suffix)
	local mp = GetMP()
	local candidates = { mp .. stat_suffix, "MPX_" .. stat_suffix, stat_suffix }
	for _, sname in ipairs(candidates) do
		local id = get_stat_int(sname, 0)
		if id and id > 0 then
			return id
		end
	end
	return nil
end

-- Find the owned location entry in `locations` by matching loc.id to the property ID
-- stored in the ownership stat.  Returns the location table entry or nil.
local function find_owned_location(stat_suffix, locations)
	local id = read_owned_id(stat_suffix)
	if not id then
		return nil
	end
	for _, loc in ipairs(locations) do
		if loc.id == id then
			return loc
		end
	end
	return nil
end

-- MC-specific: ownership ID → location index via floor((id-1)/5)+1.
-- Returns the location entry for the given sub's locations table, or nil.
local function find_mc_owned_location(factoryslot_idx, sub_locations)
	local stat_suffix = "FACTORYSLOT" .. tostring(factoryslot_idx)
	local id = read_owned_id(stat_suffix)
	if not id then
		return nil
	end
	local loc_idx = math.floor((id - 1) / 5) + 1
	return sub_locations[loc_idx]
end

return {
	GetMP = GetMP,
	run_guarded_job = run_guarded_job,
	run_coords_teleport = run_coords_teleport,
	set_global_int = set_global_int,
	get_global_int = get_global_int,
	set_stat_int = set_stat_int,
	get_stat_int = get_stat_int,
	set_tunable_int = set_tunable_int,
	get_tunable_int = get_tunable_int,
	is_script_running = is_script_running,
	set_local_int = set_local_int,
	get_local_int = get_local_int,
	force_script_host = force_script_host,
	fill_supply_slot = fill_supply_slot,
	production_tick = production_tick,
	get_blip_coords = get_blip_coords,
	find_owned_location = find_owned_location,
	find_mc_owned_location = find_mc_owned_location,
	SUPPLIES_BASE = SUPPLIES_BASE,
	TIMER_ROOT = TIMER_ROOT,
}
