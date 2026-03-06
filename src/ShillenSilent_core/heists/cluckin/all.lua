-- -------------------------------------------------------------------------
-- [Cluckin Bell Farm Raid] - 1:1 from HeistTool.lua
-- -------------------------------------------------------------------------

local core = require("ShillenSilent_core.core.bootstrap")
local ui = require("ShillenSilent_core.core.ui")
local presets = require("ShillenSilent_core.shared.presets_and_shared")

local config = core.config
local hp_set_stat_for_all_characters = presets.hp_set_stat_for_all_characters

-- Cluckin Bell Functions
local function cluckin_skip_to_finale()
	hp_set_stat_for_all_characters("SALV23_INST_PROG", 31)

	local other_stats = { "SALV23_GEN_BS", "SALV23_SCOPE_BS", "SALV23_FM_PROG" }
	for _, stat in ipairs(other_stats) do
		hp_set_stat_for_all_characters(stat, -1)
	end
	if notify then
		notify.push("Cluckin Bell", "Skipped to finale", 2000)
	end
end

local function cluckin_remove_cooldown()
	hp_set_stat_for_all_characters("SALV23_CFR_COOLDOWN", -1)
	if notify then
		notify.push("Cluckin Bell", "Cooldown removed", 2000)
	end
end

local function cluckin_reset_progress()
	hp_set_stat_for_all_characters("SALV23_INST_PROG", 0)
	if notify then
		notify.push("Cluckin Bell", "Progress reset", 2000)
	end
end

local function cluckin_instant_finish()
	local action_taken = false

	if script.running("circuitblockhack") then
		script.locals("circuitblockhack", 62).int32 = 2
		action_taken = true
	end

	if script.running("word_hack") then
		script.locals("word_hack", 106).int32 = 5
		action_taken = true
	end

	if not action_taken and script.running("fm_mission_controller_2020") then
		local base = 56223
		local cash_take_offset = 55173
		script.locals("fm_mission_controller_2020", cash_take_offset).int32 = 4000000
		script.locals("fm_mission_controller_2020", base + 1777).int32 = 999999
		script.locals("fm_mission_controller_2020", base + 1062).int32 = 5
		script.locals("fm_mission_controller_2020", 48794).int32 = script.locals("fm_mission_controller_2020", 48794).int32
			| (1 << 7)
		local win_flags = (1 << 9) | (1 << 10) | (1 << 11) | (1 << 12) | (1 << 16)
		script.locals("fm_mission_controller_2020", base + 1).int32 = script.locals(
			"fm_mission_controller_2020",
			base + 1
		).int32 | win_flags
		action_taken = true
	end

	if notify then
		if action_taken then
			notify.push("Cluckin Bell", "Instant finish triggered", 2000)
		else
			notify.push("Cluckin Bell", "Mission not running", 2000)
		end
	end
end

local function register(heistTab)
	if type(heistTab) ~= "table" then
		return nil
	end

	-- Cluckin Bell Tab Content
	local gCluckinInfo = ui.group(heistTab, "Info", nil, nil, nil, 140, "cluckin")
	ui.label(gCluckinInfo, "Cluckin Bell Farm Raid", config.colors.accent)
	ui.label(gCluckinInfo, "Farm Raid Heist", config.colors.text_main)

	local gCluckinTools = ui.group(heistTab, "Tools", nil, nil, nil, nil, "cluckin")
	ui.button_pair(
		gCluckinTools,
		"cluckin_skip_finale",
		"Skip to Finale",
		function()
			cluckin_skip_to_finale()
		end,
		"cluckin_remove_cooldown",
		"Remove Cooldown",
		function()
			cluckin_remove_cooldown()
		end
	)
	ui.button_pair(
		gCluckinTools,
		"cluckin_reset_progress",
		"Reset Progress",
		function()
			cluckin_reset_progress()
		end,
		"cluckin_instant_finish",
		"Instant Finish",
		function()
			cluckin_instant_finish()
		end
	)
	return heistTab
end

local cluckin_module = {
	cluckin_skip_to_finale = cluckin_skip_to_finale,
	cluckin_remove_cooldown = cluckin_remove_cooldown,
	cluckin_reset_progress = cluckin_reset_progress,
	cluckin_instant_finish = cluckin_instant_finish,
	register = register,
}

return cluckin_module
