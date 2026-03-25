local core = require("ShillenSilent_core.core.bootstrap")
local ui = require("ShillenSilent_core.core.ui")
local presets = require("ShillenSilent_core.shared.presets_and_shared")
local heist_state = require("ShillenSilent_core.shared.heist_state")
local danger_groups = require("ShillenSilent_core.shared.danger_groups")
local autoshop_logic = require("ShillenSilent_core.heists.autoshop.logic")

local config = core.config
local hp_build_heist_preset_group = presets.hp_build_heist_preset_group
local hp_options_to_names = presets.hp_options_to_names
local hp_option_index_by_value = presets.hp_option_index_by_value
local hp_option_value_by_name = presets.hp_option_value_by_name
local build_skip_cooldown_danger_group = danger_groups.build_skip_cooldown_danger_group

local autoshop_state = heist_state.autoshop
local AutoshopPrepOptions = autoshop_state.prep_options
local AutoshopConfig = autoshop_state.config
local autoshop_refs = autoshop_state.refs
local autoshop_apply_and_complete_preps = autoshop_logic.autoshop_apply_and_complete_preps
local autoshop_reset_preps = autoshop_logic.autoshop_reset_preps
local autoshop_redraw_board = autoshop_logic.autoshop_redraw_board
local autoshop_teleport_entrance = autoshop_logic.autoshop_teleport_entrance
local autoshop_teleport_board = autoshop_logic.autoshop_teleport_board
local autoshop_instant_finish_old = autoshop_logic.autoshop_instant_finish_old
local autoshop_instant_finish_new = autoshop_logic.autoshop_instant_finish_new
local autoshop_kill_cooldowns = autoshop_logic.autoshop_kill_cooldowns
local autoshop_apply_payout = autoshop_logic.autoshop_apply_payout
local autoshop_sync_contract_index = autoshop_logic.autoshop_sync_contract_index

local AUTOSHOP_PAYOUT_MAX = 2000000

local function register(heistTab)
	if type(heistTab) ~= "table" then
		return nil
	end

	autoshop_sync_contract_index()

	local gAutoshopInfo = ui.group(heistTab, "Info", nil, nil, nil, 140, "autoshop")
	ui.label(gAutoshopInfo, "Auto Shop", config.colors.accent)
	ui.label(gAutoshopInfo, "Max transaction: $2,000,000", config.colors.text_main)
	ui.label(gAutoshopInfo, "Transaction cooldown: 20 min", config.colors.text_sec)
	autoshop_refs.presets_group = hp_build_heist_preset_group(heistTab, "autoshop", "autoshop", "autoshop")

	local gAutoshopPreps = ui.group(heistTab, "Preps", nil, nil, nil, nil, "autoshop")
	autoshop_refs.contract_dropdown = ui.dropdown(
		gAutoshopPreps,
		"autoshop_contract",
		"Contract",
		hp_options_to_names(AutoshopPrepOptions.contracts),
		hp_option_index_by_value(AutoshopPrepOptions.contracts, AutoshopConfig.contract, 1),
		function(opt)
			AutoshopConfig.contract =
				hp_option_value_by_name(AutoshopPrepOptions.contracts, opt, AutoshopConfig.contract)
			autoshop_sync_contract_index()
		end
	)
	ui.button_pair(
		gAutoshopPreps,
		"autoshop_apply_preps",
		"Apply & Complete Preps",
		function()
			autoshop_apply_and_complete_preps()
		end,
		"autoshop_reset_preps",
		"Reset Preps",
		function()
			autoshop_reset_preps()
		end
	)
	ui.button(gAutoshopPreps, "autoshop_redraw_board", "Redraw Board / Reload", function()
		autoshop_redraw_board()
	end)

	local gAutoshopMisc = ui.group(heistTab, "Misc", nil, nil, nil, nil, "autoshop")
	ui.button_pair(
		gAutoshopMisc,
		"autoshop_tp_entrance",
		"Teleport to Entrance",
		function()
			autoshop_teleport_entrance()
		end,
		"autoshop_tp_board",
		"Teleport to Board",
		function()
			autoshop_teleport_board()
		end
	)
	ui.button_pair(
		gAutoshopMisc,
		"autoshop_instant_finish_old",
		"Instant Finish (Old)",
		function()
			autoshop_instant_finish_old()
		end,
		"autoshop_instant_finish_new",
		"Instant Finish (New)",
		function()
			autoshop_instant_finish_new()
		end
	)

	build_skip_cooldown_danger_group(heistTab, "autoshop", "autoshop_kill_cooldown", function()
		autoshop_kill_cooldowns()
	end)

	local gAutoshopPayout = ui.group(heistTab, "Payout", nil, nil, nil, nil, "autoshop")
	autoshop_refs.payout_slider = ui.slider(
		gAutoshopPayout,
		"autoshop_payout",
		"Payout",
		0,
		AUTOSHOP_PAYOUT_MAX,
		AutoshopConfig.payout,
		function(val)
			AutoshopConfig.payout = math.floor(val)
		end,
		nil,
		50000
	)
	ui.button_pair(
		gAutoshopPayout,
		"autoshop_payout_max",
		"Max",
		function()
			AutoshopConfig.payout = AUTOSHOP_PAYOUT_MAX
			if autoshop_refs.payout_slider then
				autoshop_refs.payout_slider.value = AutoshopConfig.payout
			end
			if notify then
				notify.push("Auto Shop", "Payout set to max", 2000)
			end
		end,
		"autoshop_payout_apply",
		"Apply Payout",
		function()
			autoshop_apply_payout()
		end
	)

	return heistTab
end

local autoshop_tabs = {
	register = register,
}

return autoshop_tabs
