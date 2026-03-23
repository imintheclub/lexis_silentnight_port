-- -------------------------------------------------------------------------
-- [Cluckin Bell Farm Raid] - 1:1 from HeistTool.lua
-- -------------------------------------------------------------------------

local core = require("ShillenSilent_core.core.bootstrap")
local ui = require("ShillenSilent_core.core.ui")
local safe_access = require("ShillenSilent_core.core.safe_access")
local presets = require("ShillenSilent_core.shared.presets_and_shared")
local danger_groups = require("ShillenSilent_core.shared.danger_groups")

local config = core.config
local hp_set_stat_for_all_characters = presets.hp_set_stat_for_all_characters
local build_skip_cooldown_danger_group = danger_groups.build_skip_cooldown_danger_group

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

	if safe_access.is_script_running("circuitblockhack") then
		safe_access.set_local_int("circuitblockhack", 62, 2)
		action_taken = true
	end

	if safe_access.is_script_running("word_hack") then
		safe_access.set_local_int("word_hack", 106, 5)
		action_taken = true
	end

	if not action_taken and safe_access.is_script_running("fm_mission_controller_2020") then
		local base = 56223
		local cash_take_offset = 55173
		safe_access.set_local_int("fm_mission_controller_2020", cash_take_offset, 4000000)
		safe_access.set_local_int("fm_mission_controller_2020", base + 1777, 999999)
		safe_access.set_local_int("fm_mission_controller_2020", base + 1062, 5)
		local flags = safe_access.get_local_int("fm_mission_controller_2020", 48794, 0) | (1 << 7)
		safe_access.set_local_int("fm_mission_controller_2020", 48794, flags)
		local win_flags = (1 << 9) | (1 << 10) | (1 << 11) | (1 << 12) | (1 << 16)
		local current = safe_access.get_local_int("fm_mission_controller_2020", base + 1, 0)
		safe_access.set_local_int("fm_mission_controller_2020", base + 1, current | win_flags)
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
	ui.button(gCluckinTools, "cluckin_skip_finale", "Skip to Finale", function()
		cluckin_skip_to_finale()
	end)
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

	build_skip_cooldown_danger_group(heistTab, "cluckin", "cluckin_remove_cooldown", function()
		cluckin_remove_cooldown()
	end)
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
