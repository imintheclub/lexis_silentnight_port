local cayo_menu = require("ShillenSilent_core.menu.cayo")
local casino_menu = require("ShillenSilent_core.menu.casino")
local apartment_menu = require("ShillenSilent_core.menu.apartment")
local doomsday_menu = require("ShillenSilent_core.menu.doomsday")
local agency_menu = require("ShillenSilent_core.menu.agency")
local autoshop_menu = require("ShillenSilent_core.menu.autoshop")
local salvageyard_menu = require("ShillenSilent_core.menu.salvageyard")
local cluckin_menu = require("ShillenSilent_core.menu.cluckin")
local knoway_menu = require("ShillenSilent_core.menu.knoway")
local biz_bunker_menu = require("ShillenSilent_core.menu.biz_bunker")
local biz_mc_menu = require("ShillenSilent_core.menu.biz_mc")
local biz_acidlab_menu = require("ShillenSilent_core.menu.biz_acidlab")
local biz_hangar_menu = require("ShillenSilent_core.menu.biz_hangar")
local biz_speccargo_menu = require("ShillenSilent_core.menu.biz_speccargo")
local biz_nightclub_menu = require("ShillenSilent_core.menu.biz_nightclub")
local biz_misc_menu = require("ShillenSilent_core.menu.biz_misc")
local ui_mode = require("ShillenSilent_core.app.ui_mode")
local runtime_services = require("ShillenSilent_core.runtime.services")
local common = require("ShillenSilent_core.menu.common")

local menu_main = {
	started = false,
}

local function register_menu_group(register_fn, root)
	local ok, err = pcall(register_fn, root)
	if not ok and notify then
		notify.push("ShillenSilent", "Menu register failed: " .. tostring(err), 3500)
	end
end

local function toggle_mode_with_notice()
	local current = ui_mode.get_mode_for_next_load()
	local next_mode = (current == "controller") and "click" or "controller"
	local ok, result = ui_mode.set_mode_for_next_load(next_mode)
	if notify then
		if ok then
			notify.push("UI Mode", "Next load: " .. tostring(result), 2600)
		else
			notify.push("UI Mode", "Failed: " .. tostring(result), 3200)
		end
	end
	return ok
end

local function register_info_menu(root)
	local info_menu = root:submenu("Settings")
	info_menu:breaker("Current menu: " .. tostring(ui_mode.get_mode_for_next_load()))

	common.add_button(info_menu, "Toggle UI Mode", function()
		toggle_mode_with_notice()
	end)
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

	root:breaker("ShillenSilent v0.1.1")
	register_info_menu(root)

	register_menu_group(cayo_menu.register, root)
	register_menu_group(casino_menu.register, root)
	register_menu_group(apartment_menu.register, root)
	register_menu_group(doomsday_menu.register, root)
	register_menu_group(agency_menu.register, root)
	register_menu_group(autoshop_menu.register, root)
	register_menu_group(salvageyard_menu.register, root)
	register_menu_group(cluckin_menu.register, root)
	register_menu_group(knoway_menu.register, root)

	local biz_root = root:submenu("Business Manager")
	biz_root:breaker("Business Manager")
	register_menu_group(biz_bunker_menu.register, biz_root)
	register_menu_group(biz_mc_menu.register, biz_root)
	register_menu_group(biz_acidlab_menu.register, biz_root)
	register_menu_group(biz_hangar_menu.register, biz_root)
	register_menu_group(biz_speccargo_menu.register, biz_root)
	register_menu_group(biz_nightclub_menu.register, biz_root)
	register_menu_group(biz_misc_menu.register, biz_root)

	pcall(runtime_services.start)
	menu_main.started = true
	if notify then
		notify.push("ShillenSilent", "Menu UI loaded (all heists)", 2500)
	end
	return true
end

menu_main.start()

return menu_main
