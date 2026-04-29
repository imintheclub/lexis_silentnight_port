local click = require("ShillenSilent_core.ui.click")
local runtime_main_loop = require("ShillenSilent_core.runtime.main_loop")

local app_main = {
	started = false,
	heistTab = nil,
}

function app_main.start()
	-- Ensure click UI loop is not blocked when switching from controller mode.
	_G.ShillenSilent_ForceStop = false

	if app_main.started then
		return app_main.heistTab
	end

	local heistTab = click.register_all()

	if runtime_main_loop.start then
		runtime_main_loop.start()
	end

	app_main.heistTab = heistTab
	app_main.started = true
	return heistTab
end

app_main.start()

return app_main
