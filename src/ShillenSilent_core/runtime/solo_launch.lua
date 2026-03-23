local presets = require("ShillenSilent_core.shared.presets_and_shared")

local GetMP = presets.GetMP
local hp_is_apartment_fleeca = presets.hp_is_apartment_fleeca

local function sl_try_is_script_running(script_name)
	if not script or type(script.running) ~= "function" then
		return false
	end

	local ok, result = pcall(script.running, script_name)
	if not ok then
		return false
	end
	return result and true or false
end

local function sl_try_set_global_int(offset, value)
	if not script or type(script.globals) ~= "function" then
		return false
	end

	local ok = pcall(function()
		script.globals(offset).int32 = value
	end)
	return ok
end

local function sl_try_get_global_int(offset, fallback)
	if not script or type(script.globals) ~= "function" then
		return fallback
	end

	local ok, result = pcall(function()
		return script.globals(offset).int32
	end)
	if not ok or result == nil then
		return fallback
	end
	return result
end

local function sl_try_set_local_int(script_name, offset, value)
	if not script or type(script.locals) ~= "function" then
		return false
	end

	local ok = pcall(function()
		script.locals(script_name, offset).int32 = value
	end)
	return ok
end

local function sl_try_get_local_int(script_name, offset, fallback)
	if not script or type(script.locals) ~= "function" then
		return fallback
	end

	local ok, result = pcall(function()
		return script.locals(script_name, offset).int32
	end)
	if not ok or result == nil then
		return fallback
	end
	return result
end

local function sl_try_get_stat_int(stat_name, fallback)
	if not account or type(account.stats) ~= "function" then
		return fallback
	end

	local ok, result = pcall(function()
		local stat = account.stats(stat_name)
		if not stat then
			return nil
		end
		return stat.int32
	end)
	if not ok or result == nil then
		return fallback
	end
	return result
end

local function hp_solo_launch_player_count_global(value)
	return 794954 + 4 + 1 + (value * 95) + 75
end

local function hp_get_launcher_value()
	if not sl_try_is_script_running("fmmc_launcher") then
		return nil
	end

	local value = sl_try_get_local_int("fmmc_launcher", 20056 + 34, nil)
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
	ok = sl_try_set_global_int(player_count_global, 1) and ok
	ok = sl_try_set_local_int("fmmc_launcher", 20056 + 15, 1) and ok

	ok = sl_try_set_global_int(4718592 + 3539, 1) and ok
	ok = sl_try_set_global_int(4718592 + 3540, 1) and ok
	ok = sl_try_set_global_int(4718592 + 3542 + 1, 1) and ok
	ok = sl_try_set_global_int(4718592 + 192451 + 1, 0) and ok
	ok = sl_try_set_global_int(4718592 + 3536, 1) and ok
	ok = sl_try_set_local_int("fmmc_launcher", 20297, 0) and ok

	return ok
end

local function solo_launch_casino_setup()
	if not sl_try_is_script_running("fm_mission_controller") then
		return false
	end

	local is_finale = sl_try_get_global_int(2685153 + 21, nil)
	if not is_finale or is_finale ~= 1 then
		return false
	end

	local p = GetMP()
	local approach = sl_try_get_stat_int(p .. "H3OPT_APPROACH", nil)
	if not approach then
		return false
	end

	if approach == 2 then
		if not sl_try_set_global_int(1973219, 3) then
			return false
		end
	end

	local target = sl_try_get_stat_int(p .. "H3OPT_TARGET", 0)
	return sl_try_set_global_int(1973198, target)
end

local function solo_launch_reset_casino()
	local value = hp_get_launcher_value()
	if not value then
		return false
	end

	local player_count_global = hp_solo_launch_player_count_global(value)
	local ok = true
	ok = sl_try_set_global_int(player_count_global, 2) and ok
	ok = sl_try_set_local_int("fmmc_launcher", 20056 + 15, 2) and ok

	ok = sl_try_set_global_int(4718592 + 3539, 1) and ok
	ok = sl_try_set_global_int(4718592 + 3540, 1) and ok
	ok = sl_try_set_global_int(4718592 + 3542 + 1, 2) and ok
	ok = sl_try_set_global_int(4718592 + 192451 + 1, 11) and ok
	return ok
end

local function solo_launch_reset_doomsday()
	local value = hp_get_launcher_value()
	if not value then
		return false
	end

	local player_count_global = hp_solo_launch_player_count_global(value)
	local ok = true
	ok = sl_try_set_global_int(player_count_global, 2) and ok
	ok = sl_try_set_local_int("fmmc_launcher", 20056 + 15, 2) and ok

	ok = sl_try_set_global_int(4718592 + 3539, 1) and ok
	ok = sl_try_set_global_int(4718592 + 3540, 1) and ok
	ok = sl_try_set_global_int(4718592 + 3542 + 1, 2) and ok
	ok = sl_try_set_global_int(4718592 + 192451 + 1, 11) and ok
	return ok
end

local function manual_reset_doomsday_launch()
	return solo_launch_reset_doomsday()
end

local function solo_launch_reset_apartment()
	local value = hp_get_launcher_value()
	if not value then
		return false
	end

	local is_fleeca = hp_is_apartment_fleeca()
	local required_players = is_fleeca and 2 or 4

	local player_count_global = hp_solo_launch_player_count_global(value)
	local ok = true
	ok = sl_try_set_global_int(player_count_global, required_players) and ok
	ok = sl_try_set_local_int("fmmc_launcher", 20056 + 15, required_players) and ok
	ok = sl_try_set_global_int(4718592 + 3539, required_players) and ok
	ok = sl_try_set_global_int(4718592 + 3540, required_players) and ok

	ok = sl_try_set_global_int(4718592 + 3542 + 1, 1) and ok
	ok = sl_try_set_global_int(4718592 + 192451 + 1, 0) and ok
	ok = sl_try_set_local_int("fmmc_launcher", 20297, 0) and ok
	ok = sl_try_set_global_int(4718592 + 3536, 1) and ok
	return ok
end

local solo_launch = {
	solo_launch_generic = solo_launch_generic,
	solo_launch_casino_setup = solo_launch_casino_setup,
	solo_launch_reset_casino = solo_launch_reset_casino,
	solo_launch_reset_doomsday = solo_launch_reset_doomsday,
	manual_reset_doomsday_launch = manual_reset_doomsday_launch,
	solo_launch_reset_apartment = solo_launch_reset_apartment,
}

return solo_launch
