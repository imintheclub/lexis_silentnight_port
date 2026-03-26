local cayo_menu = require("ShillenSilent_noclick_core.menu.cayo")
local casino_menu = require("ShillenSilent_noclick_core.menu.casino")
local apartment_menu = require("ShillenSilent_noclick_core.menu.apartment")
local doomsday_menu = require("ShillenSilent_noclick_core.menu.doomsday")
local agency_menu = require("ShillenSilent_noclick_core.menu.agency")
local autoshop_menu = require("ShillenSilent_noclick_core.menu.autoshop")
local salvageyard_menu = require("ShillenSilent_noclick_core.menu.salvageyard")
local cluckin_menu = require("ShillenSilent_noclick_core.menu.cluckin")
local knoway_menu = require("ShillenSilent_noclick_core.menu.knoway")
local cayo_logic = require("ShillenSilent_noclick_core.heists.cayo.logic")
local casino_logic = require("ShillenSilent_noclick_core.heists.casino.logic")
local salvageyard_logic = require("ShillenSilent_noclick_core.heists.salvageyard.logic")

local menu_main = {
	started = false,
}

local function start_runtime_sync()
	util.create_thread(function()
		while true do
			if _G.ShillenSilent_ForceStop then
				return
			end

			pcall(cayo_logic.cayo_enforce_heist_toggles)
			pcall(casino_logic.casino_enforce_heist_toggles)
			pcall(salvageyard_logic.salvage_enforce_heist_toggles)
			util.yield(150)
		end
	end)
end

local function register_menu_group(register_fn, root)
	local ok, err = pcall(register_fn, root)
	if not ok and notify then
		notify.push("ShillenSilent", "Menu register failed: " .. tostring(err), 3500)
	end
end

function menu_main.start()
	if menu_main.started then
		return false
	end

	-- Menu build should disable any legacy click-UI runtime loop that may still be loaded.
	_G.ShillenSilent_ForceStop = true

	local root = menu.root()
	if not root then
		if notify then
			notify.push("ShillenSilent", "menu.root() unavailable", 2500)
		end
		return false
	end

	root:breaker("ShillenSillent v0.0.9")

	register_menu_group(cayo_menu.register, root)
	register_menu_group(casino_menu.register, root)
	register_menu_group(apartment_menu.register, root)
	register_menu_group(doomsday_menu.register, root)
	register_menu_group(agency_menu.register, root)
	register_menu_group(autoshop_menu.register, root)
	register_menu_group(salvageyard_menu.register, root)
	register_menu_group(cluckin_menu.register, root)
	register_menu_group(knoway_menu.register, root)

	start_runtime_sync()
	menu_main.started = true
	if notify then
		notify.push("ShillenSilent", "Menu UI loaded (all heists)", 2500)
	end
	return true
end

menu_main.start()

return menu_main
