-- Teleport constants and shared helper functions
local core = require("ShillenSilent_core.core.bootstrap")
local run_guarded_job = core.run_guarded_job

local TELEPORT_COORDS_MAZEBANK = { x = -75.146, y = -818.687, z = 326.175 }
local BLIP_SPRITES_FACILITY = 590
local BLIP_SPRITES_APARTMENT = 40
local BLIP_SPRITES_HEIST = 428

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
	local me = players.me()
	if not me then
		if notify then
			notify.push(notify_title, "Player not found", 2000)
		end
		return false
	end

	local job_key = "blip_teleport_" .. tostring(blip_sprite)
	return run_guarded_job(job_key, function()
		local ped = me.ped
		local veh = me.vehicle
		local entity = (veh and veh ~= 0) and veh or ped

		invoker.call(0x428CA6DBD1094446, entity, true) -- FREEZE_ENTITY_POSITION

		if opts.relay_if_interior and me.in_interior then
			local relay = opts.relay_coords or TELEPORT_COORDS_MAZEBANK
			invoker.call(0x239A3351AC1DA385, entity, relay.x, relay.y, relay.z, false, false, false) -- SET_ENTITY_COORDS_NO_OFFSET
			util.yield(opts.relay_delay_ms or 800)
		end

		local coords = get_blip_coords(blip_sprite)
		if coords then
			invoker.call(0x239A3351AC1DA385, entity, coords.x, coords.y, coords.z, false, false, false) -- SET_ENTITY_COORDS_NO_OFFSET
			if opts.heading then
				invoker.call(0x8E2530AA8ADA980E, entity, opts.heading) -- SET_ENTITY_HEADING
			end
			util.yield(opts.arrival_delay_ms or 500)
			if notify and success_message then
				notify.push(notify_title, success_message, opts.success_duration_ms or 2000)
			end
		elseif opts.fallback_coords then
			local fb = opts.fallback_coords
			invoker.call(0x239A3351AC1DA385, entity, fb.x, fb.y, fb.z, false, false, false) -- SET_ENTITY_COORDS_NO_OFFSET
			if opts.heading then
				invoker.call(0x8E2530AA8ADA980E, entity, opts.heading) -- SET_ENTITY_HEADING
			end
			util.yield(opts.arrival_delay_ms or 500)
			if notify and opts.fallback_message then
				notify.push(notify_title, opts.fallback_message, opts.fallback_duration_ms or 2200)
			end
		else
			if notify and not_found_message then
				notify.push(notify_title, not_found_message, opts.not_found_duration_ms or 2000)
			end
		end

		invoker.call(0x428CA6DBD1094446, entity, false) -- FREEZE_ENTITY_POSITION
	end, function()
		if notify then
			notify.push(notify_title or "Teleport", "Teleport failed (already running)", 1200)
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
