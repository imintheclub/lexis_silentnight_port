-- Teleport constants and shared helper functions
local core = require("ShillenSilent_core.core.bootstrap")
local run_guarded_job = core.run_guarded_job

local TELEPORT_COORDS_MAZEBANK = { x = -75.146, y = -818.687, z = 326.175 }
local BLIP_SPRITES_FACILITY = 590
local BLIP_SPRITES_APARTMENT = 40
local BLIP_SPRITES_HEIST = 428

local function resolve_entity_handle(value)
	local t = type(value)
	if t == "number" then
		return value ~= 0 and value or nil
	end
	if t == "table" then
		if type(value.int) == "number" and value.int ~= 0 then
			return value.int
		end
		if type(value.handle) == "number" and value.handle ~= 0 then
			return value.handle
		end
		if type(value.id) == "number" and value.id ~= 0 then
			return value.id
		end
	end
	return nil
end

local function get_local_ped_handle(me)
	local ped = nil
	if invoker and invoker.call then
		local result = invoker.call(0xD80958FC74E988A6) -- PLAYER_PED_ID
		ped = resolve_entity_handle(result)
	end
	if not ped and me then
		ped = resolve_entity_handle(me.ped)
	end
	return ped
end

local function get_local_vehicle_handle(ped, me)
	local veh = nil
	if invoker and invoker.call and ped then
		local in_vehicle = invoker.call(0x997ABD671D25CA0B, ped, false) -- IS_PED_IN_ANY_VEHICLE
		if in_vehicle and in_vehicle.bool then
			local result = invoker.call(0x9A9112A0FE9A4713, ped, false) -- GET_VEHICLE_PED_IS_IN
			veh = resolve_entity_handle(result)
		end
	end
	if not veh and me then
		veh = resolve_entity_handle(me.vehicle)
	end
	return veh
end

local function get_blip_coords(blip_sprite)
	local blip = invoker.call(0x1BEDE233E6CD2A1F, blip_sprite) -- GET_FIRST_BLIP_INFO_ID
	if not blip or not blip.int or blip.int == 0 then
		return nil
	end

	local blip_handle = blip.int
	while blip_handle and blip_handle ~= 0 do
		local exists = invoker.call(0xA6DB27D19ECBB7DA, blip_handle) -- DOES_BLIP_EXIST
		if exists and exists.bool then
			local color = invoker.call(0xDF729E8D20CF7327, blip_handle) -- GET_BLIP_COLOUR
			if not color or color.int ~= 3 then
				-- GET_BLIP_COORDS - returns scr_vec3
				local coords = invoker.call(0x586AFE3FF72D996E, blip_handle) -- GET_BLIP_COORDS
				if coords and coords.scr_vec3 then
					return { x = coords.scr_vec3.x, y = coords.scr_vec3.y, z = coords.scr_vec3.z + 1.0 }
				end
			end
		end
		local next_blip = invoker.call(0x14F96AA50D6FBEA7, blip_sprite) -- GET_NEXT_BLIP_INFO_ID
		if next_blip and next_blip.int and next_blip.int ~= blip_handle then
			blip_handle = next_blip.int
		else
			break
		end
	end
	return nil
end

local function teleport_to_blip_with_job(blip_sprite, notify_title, success_message, not_found_message, opts)
	opts = opts or {}
	local title = notify_title or "Teleport"
	local me = players.me()
	if not me then
		if notify then
			notify.push(title, "Player not found", 2000)
		end
		return false
	end

	local job_key = "blip_teleport_" .. tostring(blip_sprite)
	return run_guarded_job(job_key, function()
		local ped = get_local_ped_handle(me)
		local veh = get_local_vehicle_handle(ped, me)
		local entity = (veh and veh ~= 0) and veh or ped
		if not entity then
			if notify then
				notify.push(title, "Teleport failed (invalid player entity)", 2200)
			end
			return
		end

		invoker.call(0x428CA6DBD1094446, entity, true) -- FREEZE_ENTITY_POSITION

		if opts.relay_if_interior and me.in_interior then
			local relay = opts.relay_coords or TELEPORT_COORDS_MAZEBANK
			local rx, ry, rz = tonumber(relay.x), tonumber(relay.y), tonumber(relay.z)
			if rx and ry and rz then
				invoker.call(0x239A3351AC1DA385, entity, rx, ry, rz, false, false, false) -- SET_ENTITY_COORDS_NO_OFFSET
			end
			util.yield(opts.relay_delay_ms or 800)
		end

		local coords = get_blip_coords(blip_sprite)
		if coords then
			local x, y, z = tonumber(coords.x), tonumber(coords.y), tonumber(coords.z)
			if not (x and y and z) then
				if notify then
					notify.push(title, "Teleport failed (invalid blip coordinates)", 2200)
				end
			else
				invoker.call(0x239A3351AC1DA385, entity, x, y, z, false, false, false) -- SET_ENTITY_COORDS_NO_OFFSET
			end
			local heading = tonumber(opts.heading)
			if heading then
				invoker.call(0x8E2530AA8ADA980E, entity, heading) -- SET_ENTITY_HEADING
			end
			util.yield(opts.arrival_delay_ms or 500)
			if notify and success_message then
				notify.push(title, success_message, opts.success_duration_ms or 2000)
			end
		elseif opts.fallback_coords then
			local fb = opts.fallback_coords
			local fx, fy, fz = tonumber(fb.x), tonumber(fb.y), tonumber(fb.z)
			if fx and fy and fz then
				invoker.call(0x239A3351AC1DA385, entity, fx, fy, fz, false, false, false) -- SET_ENTITY_COORDS_NO_OFFSET
			end
			local heading = tonumber(opts.heading)
			if heading then
				invoker.call(0x8E2530AA8ADA980E, entity, heading) -- SET_ENTITY_HEADING
			end
			util.yield(opts.arrival_delay_ms or 500)
			if notify and opts.fallback_message then
				notify.push(title, opts.fallback_message, opts.fallback_duration_ms or 2200)
			end
		else
			if notify and not_found_message then
				notify.push(title, not_found_message, opts.not_found_duration_ms or 2000)
			end
		end

		invoker.call(0x428CA6DBD1094446, entity, false) -- FREEZE_ENTITY_POSITION
	end, function()
		if notify then
			notify.push(title, "Teleport failed (already running)", 1200)
		end
	end)
end

local blip_teleport = {
	BLIP_SPRITES_FACILITY = BLIP_SPRITES_FACILITY,
	BLIP_SPRITES_APARTMENT = BLIP_SPRITES_APARTMENT,
	BLIP_SPRITES_HEIST = BLIP_SPRITES_HEIST,
	teleport_to_blip_with_job = teleport_to_blip_with_job,
}

return blip_teleport
