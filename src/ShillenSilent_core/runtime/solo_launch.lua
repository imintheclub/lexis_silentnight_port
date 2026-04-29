local safe_access = require("ShillenSilent_core.core.safe_access")

local function hp_solo_launch_player_count_global(value)
	return 794954 + 4 + 1 + (value * 95) + 75
end

local function hp_get_launcher_value()
	if not safe_access.is_script_running("fmmc_launcher") then
		return nil
	end

	local value = safe_access.get_local_int("fmmc_launcher", 20056 + 34, nil)
	if not value or value == 0 then
		return nil
	end

	return value
end

local function solo_launch_generic()
	local value = hp_get_launcher_value()
	if not value then
		return false
	end

	local player_count_global = hp_solo_launch_player_count_global(value)
	local ok = true
	ok = safe_access.set_global_int(player_count_global, 1) and ok
	ok = safe_access.set_local_int("fmmc_launcher", 20056 + 15, 1) and ok

	ok = safe_access.set_global_int(4718592 + 3539, 1) and ok
	ok = safe_access.set_global_int(4718592 + 3540, 1) and ok
	ok = safe_access.set_global_int(4718592 + 3542 + 1, 1) and ok
	ok = safe_access.set_global_int(4718592 + 192451 + 1, 0) and ok
	ok = safe_access.set_global_int(4718592 + 3536, 1) and ok
	ok = safe_access.set_local_int("fmmc_launcher", 20297, 0) and ok

	return ok
end

local function solo_launch_reset_doomsday()
	local value = hp_get_launcher_value()
	if not value then
		return false
	end

	local player_count_global = hp_solo_launch_player_count_global(value)
	local ok = true
	ok = safe_access.set_global_int(player_count_global, 2) and ok
	ok = safe_access.set_local_int("fmmc_launcher", 20056 + 15, 2) and ok

	ok = safe_access.set_global_int(4718592 + 3539, 1) and ok
	ok = safe_access.set_global_int(4718592 + 3540, 1) and ok
	ok = safe_access.set_global_int(4718592 + 3542 + 1, 2) and ok
	ok = safe_access.set_global_int(4718592 + 192451 + 1, 11) and ok
	return ok
end

local function manual_reset_doomsday_launch()
	return solo_launch_reset_doomsday()
end

local solo_launch = {
	solo_launch_generic = solo_launch_generic,
	solo_launch_reset_doomsday = solo_launch_reset_doomsday,
	manual_reset_doomsday_launch = manual_reset_doomsday_launch,
}

return solo_launch
