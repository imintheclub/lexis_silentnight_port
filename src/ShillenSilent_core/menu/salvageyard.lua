local salvageyard_logic = require("ShillenSilent_core.heists.salvageyard.logic")
local presets = require("ShillenSilent_core.shared.presets_and_shared")
local heist_state = require("ShillenSilent_core.shared.heist_state")
local common = require("ShillenSilent_core.menu.common")
local native_api = require("ShillenSilent_core.core.native_api")

local salvage_state = heist_state.salvageyard
local SalvageConfig = salvage_state.config
local SalvagePrepOptions = salvage_state.prep_options
local salvage_flags = salvage_state.flags

local SALVAGE_MAX_TRANSACTION = presets.SALVAGE_SELL_VALUE_MAX

local salvageyard_menu = {
	ctx = { syncing = false },
	controls = {},
}

local function slot_key(slot)
	return "slot" .. tostring(slot)
end

local function get_slot_cfg(slot)
	return SalvageConfig[slot_key(slot)]
end

local function register_slot_menu(root, slot)
	local ctx = salvageyard_menu.ctx
	local controls = salvageyard_menu.controls
	local slot_cfg = get_slot_cfg(slot)
	if not slot_cfg then
		return
	end

	local menu = root:submenu("Slot " .. tostring(slot))
	common.add_button(menu, "Make Available", function()
		salvageyard_logic.salvage_make_slot_available(slot)
	end)

	controls["slot" .. slot .. "_robbery"] = common.add_combo_options(
		ctx,
		menu,
		"Robbery",
		SalvagePrepOptions.robberies,
		function()
			return slot_cfg.robbery
		end,
		function(value)
			slot_cfg.robbery = value
		end
	)
	controls["slot" .. slot .. "_vehicle"] = common.add_combo_options(
		ctx,
		menu,
		"Vehicle",
		SalvagePrepOptions.vehicles,
		function()
			return slot_cfg.vehicle
		end,
		function(value)
			slot_cfg.vehicle = value
		end
	)
	controls["slot" .. slot .. "_modification"] = common.add_combo_options(
		ctx,
		menu,
		"Modification",
		SalvagePrepOptions.modifications,
		function()
			return slot_cfg.modification
		end,
		function(value)
			slot_cfg.modification = value
		end
	)
	controls["slot" .. slot .. "_keep"] = common.add_combo_options(
		ctx,
		menu,
		"Status",
		SalvagePrepOptions.keep_statuses,
		function()
			return slot_cfg.keep
		end,
		function(value)
			slot_cfg.keep = value
		end
	)

	common.add_button(menu, "Apply Changes", function()
		salvageyard_logic.salvage_apply_slot(slot)
	end)
end

function salvageyard_menu.refresh_controls()
	local ctx = salvageyard_menu.ctx
	local controls = salvageyard_menu.controls

	for slot = 1, 3 do
		local slot_cfg = get_slot_cfg(slot)
		if slot_cfg then
			common.set_control_value(
				ctx,
				controls["slot" .. slot .. "_robbery"],
				common.find_index_by_value(SalvagePrepOptions.robberies, slot_cfg.robbery, 1)
			)
			common.set_control_value(
				ctx,
				controls["slot" .. slot .. "_vehicle"],
				common.find_index_by_value(SalvagePrepOptions.vehicles, slot_cfg.vehicle, 1)
			)
			common.set_control_value(
				ctx,
				controls["slot" .. slot .. "_modification"],
				common.find_index_by_value(SalvagePrepOptions.modifications, slot_cfg.modification, 1)
			)
			common.set_control_value(
				ctx,
				controls["slot" .. slot .. "_keep"],
				common.find_index_by_value(SalvagePrepOptions.keep_statuses, slot_cfg.keep, 1)
			)
		end
	end

	common.set_control_value(ctx, controls.free_setup, salvage_flags.free_setup and true or false)
	common.set_control_value(ctx, controls.free_claim, salvage_flags.free_claim and true or false)
	common.set_control_value(
		ctx,
		controls.multiplier,
		common.clamp_float(SalvageConfig.salvage_multiplier or 0.8, 0.0, 5.0)
	)
	common.set_control_value(
		ctx,
		controls.sell1,
		common.clamp_int(SalvageConfig.sell_value_slot1 or 0, 0, SALVAGE_MAX_TRANSACTION)
	)
	common.set_control_value(
		ctx,
		controls.sell2,
		common.clamp_int(SalvageConfig.sell_value_slot2 or 0, 0, SALVAGE_MAX_TRANSACTION)
	)
	common.set_control_value(
		ctx,
		controls.sell3,
		common.clamp_int(SalvageConfig.sell_value_slot3 or 0, 0, SALVAGE_MAX_TRANSACTION)
	)
	return true
end

function salvageyard_menu.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local ctx = salvageyard_menu.ctx
	local controls = salvageyard_menu.controls
	local root = parent_menu:submenu("Salvage Yard")

	root:breaker("Salvage Yard")
	root:breaker("Max transaction: $2,100,000")
	root:breaker("Vehicle robbery planning controls")

	register_slot_menu(root, 1)
	register_slot_menu(root, 2)
	register_slot_menu(root, 3)

	local preps = root:submenu("Preps")
	common.add_button(preps, "Apply All Changes", function()
		salvageyard_logic.salvage_apply_all_changes()
	end)
	common.add_button(preps, "Complete Preps", function()
		salvageyard_logic.salvage_complete_preps()
	end)
	common.add_button(preps, "Reset Preps", function()
		salvageyard_logic.salvage_reset_preps()
	end)
	common.add_button(preps, "Reload Screen", function()
		salvageyard_logic.salvage_reload_screen()
	end)
	controls.free_setup = common.add_toggle(ctx, preps, "Free Setup", function()
		return salvage_flags.free_setup
	end, function(enabled)
		salvageyard_logic.salvage_set_free_setup(enabled, false)
	end)
	controls.free_claim = common.add_toggle(ctx, preps, "Free Claim", function()
		return salvage_flags.free_claim
	end, function(enabled)
		salvageyard_logic.salvage_set_free_claim(enabled, false)
	end)

	local misc = root:submenu("Misc")
	common.add_button(misc, "Teleport to Entrance", function()
		salvageyard_logic.salvage_teleport_entrance()
	end)
	common.add_button(misc, "Teleport to Screen & Board", function()
		salvageyard_logic.salvage_teleport_board()
	end)
	common.add_button(misc, "Instant Finish", function()
		salvageyard_logic.salvage_instant_finish()
	end)
	common.add_button(misc, "Instant Sell", function()
		salvageyard_logic.salvage_instant_sell()
	end)
	common.add_button(misc, "Force Through Error", function()
		salvageyard_logic.salvage_force_through_error()
	end)
	common.add_button(misc, "Collect Safe", function()
		salvageyard_logic.salvage_collect_safe()
	end)
	common.add_button(misc, "Skip Cutscene", function()
		native_api.heist_skip_cutscene("Salvage Yard")
	end)

	local danger = root:submenu("Danger")
	danger:breaker("Warning: use with caution")
	common.add_button(danger, "Skip Weekly Cooldown", function()
		salvageyard_logic.salvage_skip_weekly_cooldown()
	end)

	local payout = root:submenu("Payout")
	controls.multiplier = common.add_number_float(ctx, payout, "Salvage Value Multiplier", 0.0, 5.0, 0.1, function()
		return SalvageConfig.salvage_multiplier
	end, function(value)
		SalvageConfig.salvage_multiplier = value
	end)
	controls.sell1 = common.add_number_int(
		ctx,
		payout,
		"Sell Value Slot 1",
		0,
		SALVAGE_MAX_TRANSACTION,
		100000,
		function()
			return SalvageConfig.sell_value_slot1
		end,
		function(value)
			SalvageConfig.sell_value_slot1 = value
		end
	)
	controls.sell2 = common.add_number_int(
		ctx,
		payout,
		"Sell Value Slot 2",
		0,
		SALVAGE_MAX_TRANSACTION,
		100000,
		function()
			return SalvageConfig.sell_value_slot2
		end,
		function(value)
			SalvageConfig.sell_value_slot2 = value
		end
	)
	controls.sell3 = common.add_number_int(
		ctx,
		payout,
		"Sell Value Slot 3",
		0,
		SALVAGE_MAX_TRANSACTION,
		100000,
		function()
			return SalvageConfig.sell_value_slot3
		end,
		function(value)
			SalvageConfig.sell_value_slot3 = value
		end
	)
	common.add_button(payout, "Apply Sell Values", function()
		salvageyard_logic.salvage_apply_sell_values()
	end)

	salvageyard_logic.salvage_set_free_setup(salvage_flags.free_setup, true)
	salvageyard_logic.salvage_set_free_claim(salvage_flags.free_claim, true)
	salvageyard_logic.salvage_refresh_collect_safe_state()
	salvageyard_menu.refresh_controls()
	return root
end

return salvageyard_menu
