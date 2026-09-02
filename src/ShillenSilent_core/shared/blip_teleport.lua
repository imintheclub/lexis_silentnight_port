-- Teleport constants and shared helper functions
local jobs = require("ShillenSilent_core.core.jobs")
local notify_core = require("ShillenSilent_core.core.notify")
local i18n = require("ShillenSilent_core.i18n")
local native = require("natives")
local run_guarded_job = jobs.run_guarded_job

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
	local ped = resolve_entity_handle(native.player_ped_id())
	if not ped and me then
		ped = resolve_entity_handle(me.ped)
	end
	return ped
end

local function get_local_vehicle_handle(ped, me)
	local veh = nil
	if ped and native.is_ped_in_any_vehicle(ped, false) then
		veh = resolve_entity_handle(native.get_vehicle_ped_is_in(ped, false))
	end
	if not veh and me then
		veh = resolve_entity_handle(me.vehicle)
	end
	return veh
end

local function get_blip_coords(blip_sprite)
	local blip = native.get_first_blip_info_id(blip_sprite)
	if not blip or blip == 0 then
		return nil
	end

	local blip_handle = blip
	while blip_handle and blip_handle ~= 0 do
		if native.does_blip_exist(blip_handle) then
			local color = native.get_blip_colour(blip_handle)
			if color ~= 3 then
				-- TODO(Lexis API): current native wrappers do not expose GET_BLIP_COORDS.
				-- GET_BLIP_COORDS 0x586AFE3FF72D996E(blipHandle:int) -> scr_vec3.
				local coords = invoker.call(0x586AFE3FF72D996E, blip_handle) -- GET_BLIP_COORDS
				if coords and coords.scr_vec3 then
					return { x = coords.scr_vec3.x, y = coords.scr_vec3.y, z = coords.scr_vec3.z + 1.0 }
				end
			end
		end
		local next_blip = native.get_next_blip_info_id(blip_sprite)
		if next_blip and next_blip ~= blip_handle then
			blip_handle = next_blip
		else
			break
		end
	end
	return nil
end

local function teleport_to_blip_with_job(blip_sprite, notify_title, success_message, not_found_message, opts)
	opts = opts or {}
	local title = notify_title or i18n.t("notify.teleport_title")
	local me = players.me()
	if not me then
		notify_core.raw(title, i18n.t("notify.player_not_found"), 2000)
		return false
	end

	local job_key = "blip_teleport_" .. tostring(blip_sprite)
	return run_guarded_job(job_key, function()
		local ped = get_local_ped_handle(me)
		local veh = get_local_vehicle_handle(ped, me)
		local entity = (veh and veh ~= 0) and veh or ped
		if not entity then
			notify_core.raw(title, i18n.t("notify.teleport_invalid_player_entity"), 2200)
			return
		end

		native.freeze_entity_position(entity, true)

		if opts.relay_if_interior and me.in_interior then
			local relay = opts.relay_coords or TELEPORT_COORDS_MAZEBANK
			local rx, ry, rz = tonumber(relay.x), tonumber(relay.y), tonumber(relay.z)
			if rx and ry and rz then
				native.set_entity_coords_no_offset(entity, rx, ry, rz, false, false, false)
			end
			util.yield(opts.relay_delay_ms or 800)
		end

		local coords = get_blip_coords(blip_sprite)
		if coords then
			local x, y, z = tonumber(coords.x), tonumber(coords.y), tonumber(coords.z)
			if not (x and y and z) then
				notify_core.raw(title, i18n.t("notify.teleport_invalid_blip_coordinates"), 2200)
			else
				native.set_entity_coords_no_offset(entity, x, y, z, false, false, false)
			end
			local heading = tonumber(opts.heading)
			if heading then
				native.set_entity_heading(entity, heading)
			end
			util.yield(opts.arrival_delay_ms or 500)
			if success_message then
				notify_core.raw(title, success_message, opts.success_duration_ms or 2000)
			end
		elseif opts.fallback_coords then
			local fb = opts.fallback_coords
			local fx, fy, fz = tonumber(fb.x), tonumber(fb.y), tonumber(fb.z)
			if fx and fy and fz then
				native.set_entity_coords_no_offset(entity, fx, fy, fz, false, false, false)
			end
			local heading = tonumber(opts.heading)
			if heading then
				native.set_entity_heading(entity, heading)
			end
			util.yield(opts.arrival_delay_ms or 500)
			if opts.fallback_message then
				notify_core.raw(title, opts.fallback_message, opts.fallback_duration_ms or 2200)
			end
		else
			if not_found_message then
				notify_core.raw(title, not_found_message, opts.not_found_duration_ms or 2000)
			end
		end

		native.freeze_entity_position(entity, false)
	end, function()
		notify_core.raw(title, i18n.t("notify.teleport_already_running"), 1200)
	end)
end

local blip_teleport = {
	BLIP_SPRITES_FACILITY = BLIP_SPRITES_FACILITY,
	BLIP_SPRITES_APARTMENT = BLIP_SPRITES_APARTMENT,
	BLIP_SPRITES_HEIST = BLIP_SPRITES_HEIST,
	teleport_to_blip_with_job = teleport_to_blip_with_job,
}

return blip_teleport
