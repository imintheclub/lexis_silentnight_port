local cluckin_module = require("ShillenSilent_core.heists.cluckin.all")
local common = require("ShillenSilent_core.menu.common")

local cluckin_menu = {}

function cluckin_menu.refresh_controls()
	return true
end

function cluckin_menu.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local root = parent_menu:submenu("Cluckin Bell")
	root:breaker("Cluckin Bell Farm Raid")
	root:breaker("Farm Raid Heist")

	local tools = root:submenu("Tools")
	common.add_button(tools, "Skip to Finale", function()
		cluckin_module.cluckin_skip_to_finale()
	end)
	common.add_button(tools, "Reset Progress", function()
		cluckin_module.cluckin_reset_progress()
	end)
	common.add_button(tools, "Instant Finish", function()
		cluckin_module.cluckin_instant_finish()
	end)

	local danger = root:submenu("Danger")
	danger:breaker("Warning: use with caution")
	common.add_button(danger, "Skip Heist Cooldown", function()
		cluckin_module.cluckin_remove_cooldown()
	end)

	return root
end

return cluckin_menu
