local jobs = require("ShillenSilent_core.core.jobs")
local notify_core = require("ShillenSilent_core.core.notify")
local i18n = require("ShillenSilent_core.i18n")
local native = require("natives")

local run_guarded_job = jobs.run_guarded_job

local function teleport_to_coords(x, y, z)
	local success = false
	local error_msg = nil

	local ok, err = pcall(function()
		local ped = nil

		ped = native.player_ped_id()
		if ped == 0 then
			ped = nil
		end

		if ped and ped ~= 0 then
			-- Check if player is in a vehicle
			local vehicle = nil
			if native.is_ped_in_any_vehicle(ped, false) then
				vehicle = native.get_vehicle_ped_is_in(ped, false)
				if vehicle == 0 then
					vehicle = nil
				end
			end

			-- Teleport vehicle first if player is in one
			if vehicle and vehicle ~= 0 then
				-- Request network control of vehicle for better sync with passengers
				native.network_request_control_of_entity(vehicle)
				-- Wait for network control (important for sync with passengers)
				util.yield(150)

				-- Try multiple times if needed for network sync
				for _ = 1, 10 do
					if native.network_has_control_of_entity(vehicle) then
						break
					end
					native.network_request_control_of_entity(vehicle)
					util.yield(50)
				end

				-- Get current vehicle heading to preserve it
				local heading = native.get_entity_heading(vehicle) or 0.0

				-- Freeze vehicle during teleport for better sync
				native.freeze_entity_position(vehicle, true)

				-- SET_ENTITY_COORDS for vehicle (better network sync than NO_OFFSET)
				native.set_entity_coords(vehicle, x, y, z, false, false, false, true)

				-- Restore vehicle heading
				native.set_entity_heading(vehicle, heading)

				-- Longer delay for network sync, especially with passengers
				util.yield(250)

				-- Unfreeze vehicle
				native.freeze_entity_position(vehicle, false)

				-- Teleport player (ped) to same location
				native.set_entity_coords(ped, x, y, z, false, false, false, true)
				util.yield(150)

				-- Set player back as driver using TASK_WARP_PED_INTO_VEHICLE
				native.task_warp_ped_into_vehicle(ped, vehicle, -1)
				-- Additional delay for network sync
				util.yield(150)
				success = true
			else
				-- Teleport player (ped) if not in vehicle
				native.set_entity_coords(ped, x, y, z, false, false, false, true)
				success = true
			end
		else
			error_msg = i18n.t("notify.player_ped_missing", { ped = tostring(ped) })
		end
	end)

	if not ok then
		error_msg = i18n.t("notify.pcall_error", { error = tostring(err) })
	end

	return success, error_msg
end

-- Teleport cooldown to prevent spam.
local teleport_cooldown_tick = 0

local function try_begin_teleport_cooldown()
	local current_tick = util.get_tick_count()
	if current_tick < teleport_cooldown_tick then
		return false
	end
	teleport_cooldown_tick = current_tick + 1000
	return true
end

local function run_coords_teleport(title, success_message, x, y, z, include_error_details, on_success)
	if not try_begin_teleport_cooldown() then
		notify_core.raw(title or i18n.t("notify.teleport_title"), i18n.t("notify.teleport_on_cooldown"), 1000)
		return false
	end

	return run_guarded_job("cayo_coords_teleport", function()
		local success, error_msg = teleport_to_coords(x, y, z)
		if success then
			if on_success then
				on_success()
			end
			notify_core.raw(title, success_message, 2000)
			return
		end

		local msg = i18n.t("notify.teleport_failed")
		if include_error_details and error_msg then
			msg = i18n.t("notify.teleport_failed_with_error", { error = error_msg })
		end
		notify_core.raw(title, msg, include_error_details and 3000 or 2000)
	end, function()
		notify_core.raw(title or i18n.t("notify.teleport_title"), i18n.t("notify.teleport_already_running"), 1200)
	end)
end

local coords_teleport = {
	run_coords_teleport = run_coords_teleport,
	try_begin_teleport_cooldown = try_begin_teleport_cooldown,
}

return coords_teleport
