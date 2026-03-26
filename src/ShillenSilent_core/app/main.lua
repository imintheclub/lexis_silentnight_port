local ui = require("ShillenSilent_core.core.ui")
local info_tabs = require("ShillenSilent_core.heists.info.tabs")
local casino_tabs = require("ShillenSilent_core.heists.casino.tabs")
local cayo_tabs = require("ShillenSilent_core.heists.cayo.tabs")
local apartment_tabs = require("ShillenSilent_core.heists.apartment.tabs")
local agency_tabs = require("ShillenSilent_core.heists.agency.tabs")
local autoshop_tabs = require("ShillenSilent_core.heists.autoshop.tabs")
local salvageyard_tabs = require("ShillenSilent_core.heists.salvageyard.tabs")
local doomsday_tabs = require("ShillenSilent_core.heists.doomsday.tabs")
local cluckin_tabs = require("ShillenSilent_core.heists.cluckin.tabs")
local knoway_tabs = require("ShillenSilent_core.heists.knoway.tabs")
local runtime_main_loop = require("ShillenSilent_core.runtime.main_loop")

local app_main = {
	started = false,
	heistTab = nil,
}

local function find_or_create_heist_tab()
	for i = 1, #ui.tabs do
		local tab = ui.tabs[i]
		if tab and tab.id == "heist" then
			return tab
		end
	end
	return ui.tab("heist", "HEIST", "ui/components/network.png")
end

local function register_heist_tabs(heistTab)
	if info_tabs.register then
		info_tabs.register(heistTab)
	end
	if casino_tabs.register then
		casino_tabs.register(heistTab)
	end
	casino_tabs.heistTab = heistTab

	if cayo_tabs.register then
		cayo_tabs.register(heistTab)
	end
	if apartment_tabs.register then
		apartment_tabs.register(heistTab)
	end
	if agency_tabs.register then
		agency_tabs.register(heistTab)
	end
	if autoshop_tabs.register then
		autoshop_tabs.register(heistTab)
	end
	if salvageyard_tabs.register then
		salvageyard_tabs.register(heistTab)
	end
	if doomsday_tabs.register then
		doomsday_tabs.register(heistTab)
	end
	if cluckin_tabs.register then
		cluckin_tabs.register(heistTab)
	end
	if knoway_tabs.register then
		knoway_tabs.register(heistTab)
	end
end

function app_main.start()
	-- Ensure click UI loop is not blocked when switching from controller mode.
	_G.ShillenSilent_ForceStop = false

	if app_main.started then
		return app_main.heistTab
	end

	local heistTab = find_or_create_heist_tab()
	register_heist_tabs(heistTab)

	if runtime_main_loop.start then
		runtime_main_loop.start()
	end

	app_main.heistTab = heistTab
	app_main.started = true
	return heistTab
end

app_main.start()

return app_main
