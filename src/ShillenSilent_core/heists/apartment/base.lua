-- ---------------------------------------------------------
-- 6.7. Apartment Heist Functions
-- ---------------------------------------------------------

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
	if script and script.force_host then
		script.force_host("fm_mission_controller")
	end

	util.create_job(function()
		util.yield(1000)

		script.globals(ApartmentGlobals.Ready.PLAYER2).int32 = 6
		script.globals(ApartmentGlobals.Ready.PLAYER3).int32 = 6
		script.globals(ApartmentGlobals.Ready.PLAYER4).int32 = 6

		if notify then
			notify.push("Apartment Launch", "All Players Ready", 2000)
		end
	end)
	return true
end

local function apartment_redraw_board()
	script.globals(ApartmentGlobals.Board).int32 = 22
	if notify then
		notify.push("Apartment Launch", "Board Redrawn", 2000)
	end
end

local function apartment_complete_preps()
	account.stats("HEIST_PLANNING_STAGE").int32 = -1
	if notify then
		notify.push("Apartment Preps", "Preps Completed", 2000)
	end
end

local function apartment_kill_cooldown()
	local player_id = (players and players.user and players.user()) or 0
	local cooldown_global = 1877303 + 1 + (player_id * 77) + 76
	script.globals(cooldown_global).int32 = -1
	if notify then
		notify.push("Apartment Preps", "Cooldown Reset", 2000)
	end
end

-- ---------------------------------------------------------
-- 7. Setup Data (Example)
-- ---------------------------------------------------------
ui.tab("heist", "HEIST", "ui/components/network.png")

-- Casino granular prep options (aligned with SilentNight behavior)
