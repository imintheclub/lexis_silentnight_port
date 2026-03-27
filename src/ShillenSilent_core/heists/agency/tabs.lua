local core = require("ShillenSilent_core.core.bootstrap")
local ui = require("ShillenSilent_core.core.ui")
local presets = require("ShillenSilent_core.shared.presets_and_shared")
local heist_state = require("ShillenSilent_core.shared.heist_state")
local danger_groups = require("ShillenSilent_core.shared.danger_groups")
local agency_logic = require("ShillenSilent_core.heists.agency.logic")
local native_api = require("ShillenSilent_core.core.native_api")

local config = core.config
local hp_build_heist_preset_group = presets.hp_build_heist_preset_group
local hp_options_to_names = presets.hp_options_to_names
local hp_option_index_by_value = presets.hp_option_index_by_value
local hp_option_value_by_name = presets.hp_option_value_by_name
local build_skip_cooldown_danger_group = danger_groups.build_skip_cooldown_danger_group
local heist_skip_cutscene = native_api.heist_skip_cutscene

local agency_state = heist_state.agency
local AgencyConfig = agency_state.config
local AgencyPrepOptions = agency_state.prep_options
local agency_flags = agency_state.flags
local agency_refs = agency_state.refs
local agency_apply_and_complete_preps = agency_logic.agency_apply_and_complete_preps
local agency_kill_cooldowns = agency_logic.agency_kill_cooldowns
local agency_apply_payout = agency_logic.agency_apply_payout
local agency_teleport_entrance = agency_logic.agency_teleport_entrance
local agency_teleport_computer = agency_logic.agency_teleport_computer
local agency_teleport_mission = agency_logic.agency_teleport_mission
local agency_collect_safe = agency_logic.agency_collect_safe
local agency_instant_finish_new = agency_logic.agency_instant_finish_new
local agency_refresh_collect_safe_state = agency_logic.agency_refresh_collect_safe_state
local agency_refresh_tp_computer_state = agency_logic.agency_refresh_tp_computer_state

local function register(heistTab)
	if type(heistTab) ~= "table" then
		return nil
	end

	local gAgencyInfo = ui.group(heistTab, "Info", nil, nil, nil, 140, "agency")
	ui.label(gAgencyInfo, "Agency", config.colors.accent)
	ui.label(gAgencyInfo, "Max transaction: $2,500,000", config.colors.text_main)
	ui.label(gAgencyInfo, "Transaction cooldown: 20 min", config.colors.text_sec)
	agency_refs.presets_group = hp_build_heist_preset_group(heistTab, "agency", "agency", "agency")

	local gAgencyPreps = ui.group(heistTab, "Preps", nil, nil, nil, nil, "agency")
	ui.button(gAgencyPreps, "agency_tp_entrance", "Teleport to Entrance", function()
		agency_teleport_entrance()
	end)
	agency_refs.contract_dropdown = ui.dropdown(
		gAgencyPreps,
		"agency_contract",
		"Contract",
		hp_options_to_names(AgencyPrepOptions.contracts),
		hp_option_index_by_value(AgencyPrepOptions.contracts, AgencyConfig.contract, 1),
		function(opt)
			AgencyConfig.contract = hp_option_value_by_name(AgencyPrepOptions.contracts, opt, AgencyConfig.contract)
		end
	)
	ui.button(gAgencyPreps, "agency_apply_preps", "Apply & Complete Preps", function()
		agency_apply_and_complete_preps()
	end)

	local gAgencyTools = ui.group(heistTab, "Tools", nil, nil, nil, nil, "agency")
	agency_refs.tp_computer_button = ui.button(gAgencyTools, "agency_tp_computer", "Teleport to Computer", function()
		agency_teleport_computer()
	end)
	ui.button_pair(
		gAgencyTools,
		"agency_tp_mission",
		"Teleport to Mission",
		function()
			agency_teleport_mission()
		end,
		"agency_collect_safe",
		"Collect Safe",
		function()
			agency_collect_safe()
		end
	)
	agency_refs.collect_safe_button = gAgencyTools.items[#gAgencyTools.items].right
	ui.button_pair(
		gAgencyTools,
		"agency_instant_finish",
		"Instant Finish",
		function()
			agency_instant_finish_new()
		end,
		"agency_skip_cutscene",
		"Skip Cutscene",
		function()
			heist_skip_cutscene("Agency")
		end
	)

	build_skip_cooldown_danger_group(heistTab, "agency", "agency_kill_cooldowns", function()
		agency_kill_cooldowns()
	end)

	local gAgencyPayout = ui.group(heistTab, "Payout", nil, nil, nil, nil, "agency")
	agency_refs.payout_slider = ui.slider(
		gAgencyPayout,
		"agency_payout",
		"Payout",
		0,
		2500000,
		AgencyConfig.payout,
		function(val)
			AgencyConfig.payout = math.floor(val)
		end,
		nil,
		50000
	)
	ui.button_pair(
		gAgencyPayout,
		"agency_payout_max",
		"Max",
		function()
			AgencyConfig.payout = 2500000
			if agency_refs.payout_slider then
				agency_refs.payout_slider.value = AgencyConfig.payout
			end
			if notify then
				notify.push("Agency", "Payout set to max", 2000)
			end
		end,
		"agency_payout_apply",
		"Apply Payout",
		function()
			agency_apply_payout()
		end
	)

	agency_refresh_tp_computer_state()
	agency_refresh_collect_safe_state()
	if not agency_flags.collect_safe_ee_only and notify then
		notify.push("Agency", "Collect Safe disabled (EE only)", 2200)
	end

	return heistTab
end

local agency_tabs = {
	register = register,
}

return agency_tabs
