local safe_access = require("ShillenSilent_core.core.safe_access")

local LAUNCHER_VALUE = { ee = 20056 + 34, legacy = 20054 + 34 }
local LAUNCHER_REQUIRED_PLAYERS = { ee = 20056 + 15, legacy = 20054 + 15 }
local LAUNCHER_FLAGS = { ee = 20297, legacy = 20295 }
local LAUNCHER_EXTRA = { ee = 4718592 + 192451 + 1, legacy = 4718592 + 185951 + 1 }

local function hp_solo_launch_player_count_global(value)
	return 794954 + 4 + 1 + (value * 95) + 75
end

local function hp_get_launcher_value()
	if not safe_access.is_script_running("fmmc_launcher") then
		return nil
	end

	local value = safe_access.get_local_int_variants("fmmc_launcher", LAUNCHER_VALUE, nil)
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
	ok = safe_access.set_local_int_variants("fmmc_launcher", LAUNCHER_REQUIRED_PLAYERS, 1) and ok

	ok = safe_access.set_global_int(4718592 + 3539, 1) and ok
	ok = safe_access.set_global_int(4718592 + 3540, 1) and ok
	ok = safe_access.set_global_int(4718592 + 3542 + 1, 1) and ok
	ok = safe_access.set_global_int_variants(LAUNCHER_EXTRA, 0) and ok
	ok = safe_access.set_global_int(4718592 + 3536, 1) and ok
	ok = safe_access.set_local_int_variants("fmmc_launcher", LAUNCHER_FLAGS, 0) and ok

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
	ok = safe_access.set_local_int_variants("fmmc_launcher", LAUNCHER_REQUIRED_PLAYERS, 2) and ok

	ok = safe_access.set_global_int(4718592 + 3539, 1) and ok
	ok = safe_access.set_global_int(4718592 + 3540, 1) and ok
	ok = safe_access.set_global_int(4718592 + 3542 + 1, 2) and ok
	ok = safe_access.set_global_int_variants(LAUNCHER_EXTRA, 11) and ok
	return ok
end

local solo_launch = {
	solo_launch_generic = solo_launch_generic,
	solo_launch_reset_doomsday = solo_launch_reset_doomsday,
}

return solo_launch
