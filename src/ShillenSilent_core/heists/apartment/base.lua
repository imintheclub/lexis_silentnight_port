-- ---------------------------------------------------------
-- 6.7. Apartment Heist Functions
-- ---------------------------------------------------------

local core = require("ShillenSilent_core.core.bootstrap")
local safe_access = require("ShillenSilent_core.core.safe_access")
local run_guarded_job = core.run_guarded_job

-- Apartment Globals
local ApartmentGlobals = {
	ReadyBase = 2658294,
	Ready = {
		PLAYER1 = 2658565,
		PLAYER2 = 2659033,
		PLAYER3 = 2659501,
		PLAYER4 = 2659969,
	},
	Board = 1936048,
}

-- Apartment Force Ready
local function apartment_force_ready()
	return run_guarded_job("apartment_force_ready", function()
		safe_access.force_host("fm_mission_controller")
		util.yield(1000)

		safe_access.set_global_int(ApartmentGlobals.Ready.PLAYER2, 6)
		safe_access.set_global_int(ApartmentGlobals.Ready.PLAYER3, 6)
		safe_access.set_global_int(ApartmentGlobals.Ready.PLAYER4, 6)

		if notify then
			notify.push("Apartment Launch", "All players ready", 2000)
		end
	end, function()
		if notify then
			notify.push("Apartment Launch", "Force ready already running", 1500)
		end
	end)
end

local function apartment_redraw_board()
	safe_access.set_global_int(ApartmentGlobals.Board, 22)
	if notify then
		notify.push("Apartment Launch", "Board refreshed", 2000)
	end
end

local function apartment_complete_preps()
	safe_access.set_stat_int("HEIST_PLANNING_STAGE", -1)
	if notify then
		notify.push("Apartment Preps", "Preps applied", 2000)
	end
end

local function apartment_kill_cooldown()
	local player_id = (players and players.user and players.user()) or 0
	local cooldown_global = 1877303 + 1 + (player_id * 77) + 76
	safe_access.set_global_int(cooldown_global, -1)
	if notify then
		notify.push("Apartment Preps", "Cooldown removed", 2000)
	end
end

local apartment_base = {
	ApartmentGlobals = ApartmentGlobals,
	apartment_force_ready = apartment_force_ready,
	apartment_redraw_board = apartment_redraw_board,
	apartment_complete_preps = apartment_complete_preps,
	apartment_kill_cooldown = apartment_kill_cooldown,
}

return apartment_base
