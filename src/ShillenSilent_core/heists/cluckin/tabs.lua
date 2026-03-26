local core = require("ShillenSilent_core.core.bootstrap")
local ui = require("ShillenSilent_core.core.ui")
local danger_groups = require("ShillenSilent_core.shared.danger_groups")
local cluckin_module = require("ShillenSilent_core.heists.cluckin.all")
local native_api = require("ShillenSilent_core.core.native_api")

local config = core.config
local build_skip_cooldown_danger_group = danger_groups.build_skip_cooldown_danger_group
local heist_skip_cutscene = native_api.heist_skip_cutscene

local function register(heistTab)
	if type(heistTab) ~= "table" then
		return nil
	end

	local gCluckinInfo = ui.group(heistTab, "Info", nil, nil, nil, 140, "cluckin")
	ui.label(gCluckinInfo, "Cluckin Bell Farm Raid", config.colors.accent)
	ui.label(gCluckinInfo, "Farm Raid Heist", config.colors.text_main)

	local gCluckinTools = ui.group(heistTab, "Tools", nil, nil, nil, nil, "cluckin")
	ui.button(gCluckinTools, "cluckin_skip_finale", "Skip to Finale", function()
		cluckin_module.cluckin_skip_to_finale()
	end)
	ui.button_pair(
		gCluckinTools,
		"cluckin_reset_progress",
		"Reset Progress",
		function()
			cluckin_module.cluckin_reset_progress()
		end,
		"cluckin_instant_finish",
		"Instant Finish",
		function()
			cluckin_module.cluckin_instant_finish()
		end
	)
	ui.button(gCluckinTools, "cluckin_skip_cutscene", "Skip Cutscene", function()
		heist_skip_cutscene("Cluckin Bell")
	end)

	build_skip_cooldown_danger_group(heistTab, "cluckin", "cluckin_remove_cooldown", function()
		cluckin_module.cluckin_remove_cooldown()
	end)
	return heistTab
end

local cluckin_tabs = {
	register = register,
}

return cluckin_tabs
