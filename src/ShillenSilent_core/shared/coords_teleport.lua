local core = require_module("core/bootstrap")

local run_guarded_job = core.run_guarded_job

local function teleport_to_coords(x, y, z)
	local success = false
	local error_msg = nil

	local ok, err = pcall(function()
		local ped = nil

		-- Method 1: Try using invoker directly to get player ped (most reliable)
		if invoker and invoker.call then
			local result = invoker.call(0xD80958FC74E988A6) -- PLAYER_PED_ID
			if result and result.int and result.int ~= 0 then
				ped = result.int
			end
		end

		-- Method 2: Try using native.player_ped_id() (fallback)
		if not ped then
			local native_ok, native_result = pcall(function()
				local native_api = require("natives")
				if native_api and native_api.player_ped_id then
					return native_api.player_ped_id()
				end
				return nil
			end)

			if native_ok and native_result and native_result ~= 0 then
				ped = native_result
			end
		end

		if ped and ped ~= 0 then
			-- Check if player is in a vehicle
			local vehicle = nil
			if invoker and invoker.call then
				-- IS_PED_IN_ANY_VEHICLE native (0x997ABD671D25CA0B)
				local in_vehicle = invoker.call(0x997ABD671D25CA0B, ped, false)
				if in_vehicle and in_vehicle.bool then
					-- GET_VEHICLE_PED_IS_IN native (0x9A9112A0FE9A4713)
					local veh_result = invoker.call(0x9A9112A0FE9A4713, ped, false)
					if veh_result and veh_result.int and veh_result.int ~= 0 then
						vehicle = veh_result.int
					end
				end
			end

			-- Teleport vehicle first if player is in one
			if vehicle and vehicle ~= 0 then
				-- Request network control of vehicle for better sync with passengers
				if invoker and invoker.call then
					-- NETWORK_REQUEST_CONTROL_OF_ENTITY (0xB69317BF5E782347)
					invoker.call(0xB69317BF5E782347, vehicle) -- NETWORK_REQUEST_CONTROL_OF_ENTITY
					-- Wait for network control (important for sync with passengers)
					util.yield(150)

					-- Try multiple times if needed for network sync
					for _ = 1, 10 do
						local has_control = invoker.call(0x01BF60A500E28887, vehicle) -- NETWORK_HAS_CONTROL_OF_ENTITY
						if has_control and has_control.bool then
							break
						end
						invoker.call(0xB69317BF5E782347, vehicle) -- NETWORK_REQUEST_CONTROL_OF_ENTITY
						util.yield(50)
					end
				end

				-- Get current vehicle heading to preserve it
				local heading_result = nil
				if invoker and invoker.call then
					heading_result = invoker.call(0xE83D4F9BA2A38914, vehicle) -- GET_ENTITY_HEADING
				end
				local heading = (heading_result and heading_result.float) or 0.0

				-- Freeze vehicle during teleport for better sync
				if invoker and invoker.call then
					invoker.call(0x428CA6DBD1094446, vehicle, true) -- FREEZE_ENTITY_POSITION
				end

				-- SET_ENTITY_COORDS for vehicle (better network sync than NO_OFFSET)
				invoker.call(0x06843DA7060A026B, vehicle, x, y, z, false, false, false, true)

				-- Restore vehicle heading
				if invoker and invoker.call then
					invoker.call(0x8E2530AA8ADA980E, vehicle, heading) -- SET_ENTITY_HEADING
				end

				-- Longer delay for network sync, especially with passengers
				util.yield(250)

				-- Unfreeze vehicle
				if invoker and invoker.call then
					invoker.call(0x428CA6DBD1094446, vehicle, false) -- FREEZE_ENTITY_POSITION
				end

				-- Teleport player (ped) to same location
				if invoker and invoker.call then
					invoker.call(0x06843DA7060A026B, ped, x, y, z, false, false, false, true)
					util.yield(150)

					-- Set player back as driver using TASK_WARP_PED_INTO_VEHICLE
					-- Parameters: ped, vehicle, seat (-1 = driver seat)
					invoker.call(0x9A7D091411C5F684, ped, vehicle, -1)
					-- Additional delay for network sync
					util.yield(150)
					success = true
				else
					error_msg = "Invoker not available"
				end
			else
				-- Teleport player (ped) if not in vehicle
				if invoker and invoker.call then
					-- Use SET_ENTITY_COORDS native (0x06843DA7060A026B)
					-- Parameters: entity, x, y, z, xAxis, yAxis, zAxis, clearArea
					invoker.call(0x06843DA7060A026B, ped, x, y, z, false, false, false, true)
					success = true
				else
					error_msg = "Invoker not available"
				end
			end
		else
			error_msg = "Could not get player ped (ped=" .. tostring(ped) .. ")"
		end
	end)

	if not ok then
		error_msg = "pcall error: " .. tostring(err)
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
		return false
	end

	return run_guarded_job("cayo_coords_teleport", function()
		local success, error_msg = teleport_to_coords(x, y, z)
		if success then
			if on_success then
				on_success()
			end
			if notify then
				notify.push(title, success_message, 2000)
			end
			return
		end

		local msg = "Failed to teleport"
		if include_error_details and error_msg then
			msg = msg .. ": " .. error_msg
		end
		if notify then
			notify.push(title, msg, include_error_details and 3000 or 2000)
		end
	end, function()
		if notify then
			notify.push(title or "Cayo Teleport", "Teleport already running", 1200)
		end
	end)
end

local coords_teleport = {
	run_coords_teleport = run_coords_teleport,
	try_begin_teleport_cooldown = try_begin_teleport_cooldown,
}

return coords_teleport
