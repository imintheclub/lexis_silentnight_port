local presets = require("ShillenSilent_core.shared.presets_and_shared")

local GetMP = presets.GetMP
local hp_is_apartment_fleeca = presets.hp_is_apartment_fleeca

local function hp_solo_launch_player_count_global(value)
	return 794954 + 4 + 1 + (value * 95) + 75
end

local function hp_get_launcher_value()
	if not script.running("fmmc_launcher") then
		return nil
	end

	local value = script.locals("fmmc_launcher", 20056 + 34).int32
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
	script.globals(player_count_global).int32 = 1
	script.locals("fmmc_launcher", 20056 + 15).int32 = 1

	script.globals(4718592 + 3539).int32 = 1
	script.globals(4718592 + 3540).int32 = 1
	script.globals(4718592 + 3542 + 1).int32 = 1
	script.globals(4718592 + 192451 + 1).int32 = 0
	script.globals(4718592 + 3536).int32 = 1
	script.locals("fmmc_launcher", 20297).int32 = 0

	return true
end

local function solo_launch_casino_setup()
	if not script.running("fm_mission_controller") then
		return false
	end

	local is_finale = script.globals(2685153 + 21).int32
	if not is_finale or is_finale ~= 1 then
		return false
	end

	local p = GetMP()
	local approach = account.stats(p .. "H3OPT_APPROACH").int32
	if not approach then
		return false
	end

	if approach == 2 then
		script.globals(1973219).int32 = 3
	end

	local target = account.stats(p .. "H3OPT_TARGET").int32 or 0
	script.globals(1973198).int32 = target
	return true
end

local function solo_launch_reset_casino()
	local value = hp_get_launcher_value()
	if not value then
		return false
	end

	local player_count_global = hp_solo_launch_player_count_global(value)
	script.globals(player_count_global).int32 = 2
	script.locals("fmmc_launcher", 20056 + 15).int32 = 2

	script.globals(4718592 + 3539).int32 = 1
	script.globals(4718592 + 3540).int32 = 1
	script.globals(4718592 + 3542 + 1).int32 = 2
	script.globals(4718592 + 192451 + 1).int32 = 11
	return true
end

local function solo_launch_reset_doomsday()
	local value = hp_get_launcher_value()
	if not value then
		return false
	end

	local player_count_global = hp_solo_launch_player_count_global(value)
	script.globals(player_count_global).int32 = 2
	script.locals("fmmc_launcher", 20056 + 15).int32 = 2

	script.globals(4718592 + 3539).int32 = 1
	script.globals(4718592 + 3540).int32 = 1
	script.globals(4718592 + 3542 + 1).int32 = 2
	script.globals(4718592 + 192451 + 1).int32 = 11
	return true
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
	script.globals(player_count_global).int32 = required_players
	script.locals("fmmc_launcher", 20056 + 15).int32 = required_players
	script.globals(4718592 + 3539).int32 = required_players
	script.globals(4718592 + 3540).int32 = required_players

	script.globals(4718592 + 3542 + 1).int32 = 1
	script.globals(4718592 + 192451 + 1).int32 = 0
	script.locals("fmmc_launcher", 20297).int32 = 0
	script.globals(4718592 + 3536).int32 = 1
	return true
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
