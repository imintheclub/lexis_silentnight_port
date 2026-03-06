local ui = require_module("core/ui")
local casino_tabs = require_module("heists/casino/tabs")
local cayo_tabs = require_module("heists/cayo/tabs")
local apartment_tabs = require_module("heists/apartment/tabs")
local doomsday_module = require_module("heists/doomsday/all")
local cluckin_module = require_module("heists/cluckin/all")
local runtime_main_loop = require_module("runtime/main_loop")

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
	if doomsday_module.register then
		doomsday_module.register(heistTab)
	end
	if cluckin_module.register then
		cluckin_module.register(heistTab)
	end
end

function app_main.start()
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
