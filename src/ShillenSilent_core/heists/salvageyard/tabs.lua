local core = require("ShillenSilent_core.core.bootstrap")
local ui = require("ShillenSilent_core.core.ui")
local presets = require("ShillenSilent_core.shared.presets_and_shared")
local heist_state = require("ShillenSilent_core.shared.heist_state")
local danger_groups = require("ShillenSilent_core.shared.danger_groups")
local salvageyard_logic = require("ShillenSilent_core.heists.salvageyard.logic")

local config = core.config
local hp_build_heist_preset_group = presets.hp_build_heist_preset_group
local hp_options_to_names = presets.hp_options_to_names
local hp_option_index_by_value = presets.hp_option_index_by_value
local hp_option_value_by_name = presets.hp_option_value_by_name
local build_skip_cooldown_danger_group = danger_groups.build_skip_cooldown_danger_group

local salvage_state = heist_state.salvageyard
local SalvagePrepOptions = salvage_state.prep_options
local SalvageConfig = salvage_state.config
local salvage_flags = salvage_state.flags
local salvage_refs = salvage_state.refs
local salvage_apply_slot = salvageyard_logic.salvage_apply_slot
local salvage_make_slot_available = salvageyard_logic.salvage_make_slot_available
local salvage_apply_all_changes = salvageyard_logic.salvage_apply_all_changes
local salvage_complete_preps = salvageyard_logic.salvage_complete_preps
local salvage_reset_preps = salvageyard_logic.salvage_reset_preps
local salvage_reload_screen = salvageyard_logic.salvage_reload_screen
local salvage_set_free_setup = salvageyard_logic.salvage_set_free_setup
local salvage_set_free_claim = salvageyard_logic.salvage_set_free_claim
local salvage_teleport_entrance = salvageyard_logic.salvage_teleport_entrance
local salvage_teleport_board = salvageyard_logic.salvage_teleport_board
local salvage_instant_finish = salvageyard_logic.salvage_instant_finish
local salvage_instant_sell = salvageyard_logic.salvage_instant_sell
local salvage_force_through_error = salvageyard_logic.salvage_force_through_error
local salvage_skip_weekly_cooldown = salvageyard_logic.salvage_skip_weekly_cooldown
local salvage_collect_safe = salvageyard_logic.salvage_collect_safe
local salvage_refresh_collect_safe_state = salvageyard_logic.salvage_refresh_collect_safe_state
local salvage_apply_sell_values = salvageyard_logic.salvage_apply_sell_values

local SALVAGE_MAX_TRANSACTION = 2100000

local function salvage_slot_key(slot)
	return "slot" .. tostring(slot)
end

local function salvage_get_slot_config(slot)
	return SalvageConfig[salvage_slot_key(slot)]
end

local function salvage_bind_slot_dropdowns(group, slot)
	local slot_cfg = salvage_get_slot_config(slot)
	if not slot_cfg then
		return
	end

	local robbery_ref_key = "slot" .. tostring(slot) .. "_robbery_dropdown"
	local vehicle_ref_key = "slot" .. tostring(slot) .. "_vehicle_dropdown"
	local mod_ref_key = "slot" .. tostring(slot) .. "_modification_dropdown"
	local keep_ref_key = "slot" .. tostring(slot) .. "_keep_dropdown"

	salvage_refs[robbery_ref_key] = ui.dropdown(
		group,
		"salvage_slot" .. tostring(slot) .. "_robbery",
		"Robbery",
		hp_options_to_names(SalvagePrepOptions.robberies),
		hp_option_index_by_value(SalvagePrepOptions.robberies, slot_cfg.robbery, 1),
		function(opt)
			slot_cfg.robbery = hp_option_value_by_name(SalvagePrepOptions.robberies, opt, slot_cfg.robbery)
		end
	)

	salvage_refs[vehicle_ref_key] = ui.dropdown(
		group,
		"salvage_slot" .. tostring(slot) .. "_vehicle",
		"Vehicle",
		hp_options_to_names(SalvagePrepOptions.vehicles),
		hp_option_index_by_value(SalvagePrepOptions.vehicles, slot_cfg.vehicle, 1),
		function(opt)
			slot_cfg.vehicle = hp_option_value_by_name(SalvagePrepOptions.vehicles, opt, slot_cfg.vehicle)
		end
	)

	salvage_refs[mod_ref_key] = ui.dropdown(
		group,
		"salvage_slot" .. tostring(slot) .. "_modification",
		"Modification",
		hp_options_to_names(SalvagePrepOptions.modifications),
		hp_option_index_by_value(SalvagePrepOptions.modifications, slot_cfg.modification, 1),
		function(opt)
			slot_cfg.modification =
				hp_option_value_by_name(SalvagePrepOptions.modifications, opt, slot_cfg.modification)
		end
	)

	salvage_refs[keep_ref_key] = ui.dropdown(
		group,
		"salvage_slot" .. tostring(slot) .. "_keep",
		"Status",
		hp_options_to_names(SalvagePrepOptions.keep_statuses),
		hp_option_index_by_value(SalvagePrepOptions.keep_statuses, slot_cfg.keep, 1),
		function(opt)
			slot_cfg.keep = hp_option_value_by_name(SalvagePrepOptions.keep_statuses, opt, slot_cfg.keep)
		end
	)
end

local function salvage_build_slot_group(heistTab, slot)
	local group = ui.group(heistTab, "Slot " .. tostring(slot), nil, nil, nil, nil, "salvageyard")
	ui.button(group, "salvage_slot" .. tostring(slot) .. "_available", "Make Available", function()
		salvage_make_slot_available(slot)
	end)
	salvage_bind_slot_dropdowns(group, slot)
	ui.button(group, "salvage_slot" .. tostring(slot) .. "_apply", "Apply Changes", function()
		salvage_apply_slot(slot)
	end)
end

local function register(heistTab)
	if type(heistTab) ~= "table" then
		return nil
	end

	local gSalvageInfo = ui.group(heistTab, "Info", nil, nil, nil, 140, "salvageyard")
	ui.label(gSalvageInfo, "Salvage Yard", config.colors.accent)
	ui.label(gSalvageInfo, "Max transaction: $2,100,000", config.colors.text_main)
	ui.label(gSalvageInfo, "Vehicle robbery planning controls", config.colors.text_sec)
	salvage_refs.presets_group = hp_build_heist_preset_group(heistTab, "salvageyard", "salvageyard", "salvageyard")

	salvage_build_slot_group(heistTab, 1)
	salvage_build_slot_group(heistTab, 2)
	salvage_build_slot_group(heistTab, 3)

	local gSalvagePreps = ui.group(heistTab, "Preps", nil, nil, nil, nil, "salvageyard")
	ui.button(gSalvagePreps, "salvage_apply_all_changes", "Apply All Changes", function()
		salvage_apply_all_changes()
	end)
	ui.button_pair(
		gSalvagePreps,
		"salvage_complete_preps",
		"Complete Preps",
		function()
			salvage_complete_preps()
		end,
		"salvage_reset_preps",
		"Reset Preps",
		function()
			salvage_reset_preps()
		end
	)
	ui.button(gSalvagePreps, "salvage_reload_screen", "Reload Screen", function()
		salvage_reload_screen()
	end)
	salvage_refs.free_setup_toggle = ui.toggle(
		gSalvagePreps,
		"salvage_free_setup",
		"Free Setup",
		salvage_flags.free_setup,
		function(enabled)
			salvage_set_free_setup(enabled, false)
		end
	)
	salvage_refs.free_claim_toggle = ui.toggle(
		gSalvagePreps,
		"salvage_free_claim",
		"Free Claim",
		salvage_flags.free_claim,
		function(enabled)
			salvage_set_free_claim(enabled, false)
		end
	)

	local gSalvageMisc = ui.group(heistTab, "Misc", nil, nil, nil, nil, "salvageyard")
	ui.button_pair(
		gSalvageMisc,
		"salvage_tp_entrance",
		"Teleport to Entrance",
		function()
			salvage_teleport_entrance()
		end,
		"salvage_tp_board",
		"Teleport to Screen & Board",
		function()
			salvage_teleport_board()
		end
	)
	ui.button_pair(
		gSalvageMisc,
		"salvage_instant_finish",
		"Instant Finish",
		function()
			salvage_instant_finish()
		end,
		"salvage_instant_sell",
		"Instant Sell",
		function()
			salvage_instant_sell()
		end
	)
	ui.button_pair(
		gSalvageMisc,
		"salvage_force_through_error",
		"Force Through Error",
		function()
			salvage_force_through_error()
		end,
		"salvage_collect_safe",
		"Collect Safe",
		function()
			salvage_collect_safe()
		end
	)
	salvage_refs.collect_safe_button = gSalvageMisc.items[#gSalvageMisc.items].right

	build_skip_cooldown_danger_group(heistTab, "salvageyard", "salvage_skip_weekly_cooldown", function()
		salvage_skip_weekly_cooldown()
	end)

	local gSalvagePayout = ui.group(heistTab, "Payout", nil, nil, nil, nil, "salvageyard")
	salvage_refs.salvage_multiplier_slider = ui.slider(
		gSalvagePayout,
		"salvage_multiplier",
		"Salvage Value Multiplier",
		0.0,
		5.0,
		SalvageConfig.salvage_multiplier,
		function(val)
			SalvageConfig.salvage_multiplier = val
		end,
		nil,
		0.1
	)
	salvage_refs.sell_value_slot1_slider = ui.slider(
		gSalvagePayout,
		"salvage_sell_value_slot1",
		"Sell Value Slot 1",
		0,
		SALVAGE_MAX_TRANSACTION,
		SalvageConfig.sell_value_slot1,
		function(val)
			SalvageConfig.sell_value_slot1 = math.floor(val)
		end,
		nil,
		100000
	)
	salvage_refs.sell_value_slot2_slider = ui.slider(
		gSalvagePayout,
		"salvage_sell_value_slot2",
		"Sell Value Slot 2",
		0,
		SALVAGE_MAX_TRANSACTION,
		SalvageConfig.sell_value_slot2,
		function(val)
			SalvageConfig.sell_value_slot2 = math.floor(val)
		end,
		nil,
		100000
	)
	salvage_refs.sell_value_slot3_slider = ui.slider(
		gSalvagePayout,
		"salvage_sell_value_slot3",
		"Sell Value Slot 3",
		0,
		SALVAGE_MAX_TRANSACTION,
		SalvageConfig.sell_value_slot3,
		function(val)
			SalvageConfig.sell_value_slot3 = math.floor(val)
		end,
		nil,
		100000
	)
	ui.button(gSalvagePayout, "salvage_apply_sell_values", "Apply Sell Values", function()
		salvage_apply_sell_values()
	end)

	salvage_set_free_setup(salvage_flags.free_setup, true)
	salvage_set_free_claim(salvage_flags.free_claim, true)
	salvage_refresh_collect_safe_state()
	if not salvage_flags.collect_safe_ee_only and notify then
		notify.push("Salvage Yard", "Collect Safe disabled (EE only)", 2200)
	end

	return heistTab
end

local salvageyard_tabs = {
	register = register,
}

return salvageyard_tabs
