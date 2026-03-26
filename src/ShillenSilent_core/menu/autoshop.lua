local autoshop_logic = require("ShillenSilent_core.heists.autoshop.logic")
local presets = require("ShillenSilent_core.shared.presets_and_shared")
local heist_state = require("ShillenSilent_core.shared.heist_state")
local common = require("ShillenSilent_core.menu.common")

local autoshop_state = heist_state.autoshop
local AutoshopConfig = autoshop_state.config
local AutoshopPrepOptions = autoshop_state.prep_options

local AUTOSHOP_PAYOUT_MAX = presets.AUTOSHOP_TRANSACTION_MAX

local autoshop_menu = {
	ctx = { syncing = false },
	controls = {},
}

function autoshop_menu.refresh_controls()
	local ctx = autoshop_menu.ctx
	local controls = autoshop_menu.controls

	autoshop_logic.autoshop_sync_contract_index()
	common.set_control_value(
		ctx,
		controls.contract_combo,
		common.find_index_by_value(AutoshopPrepOptions.contracts, AutoshopConfig.contract, 1)
	)
	common.set_control_value(
		ctx,
		controls.payout_number,
		common.clamp_int(AutoshopConfig.payout, 0, AUTOSHOP_PAYOUT_MAX)
	)
	return true
end

function autoshop_menu.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local ctx = autoshop_menu.ctx
	local controls = autoshop_menu.controls

	local root = parent_menu:submenu("Auto Shop")
	root:breaker("Auto Shop")
	root:breaker("Max transaction: $2,000,000")
	root:breaker("Transaction cooldown: 20 min")

	local preps = root:submenu("Preps")
	controls.contract_combo = common.add_combo_options(ctx, preps, "Contract", AutoshopPrepOptions.contracts, function()
		return AutoshopConfig.contract
	end, function(value)
		AutoshopConfig.contract = value
		autoshop_logic.autoshop_sync_contract_index()
	end)
	common.add_button(preps, "Apply & Complete Preps", function()
		autoshop_logic.autoshop_apply_and_complete_preps()
	end)
	common.add_button(preps, "Reset Preps", function()
		autoshop_logic.autoshop_reset_preps()
	end)
	common.add_button(preps, "Redraw Board / Reload", function()
		autoshop_logic.autoshop_redraw_board()
	end)

	local misc = root:submenu("Misc")
	common.add_button(misc, "Teleport to Entrance", function()
		autoshop_logic.autoshop_teleport_entrance()
	end)
	common.add_button(misc, "Teleport to Board", function()
		autoshop_logic.autoshop_teleport_board()
	end)
	common.add_button(misc, "Instant Finish", function()
		autoshop_logic.autoshop_instant_finish_new()
	end)

	local danger = root:submenu("Danger")
	danger:breaker("Warning: use with caution")
	common.add_button(danger, "Skip Heist Cooldowns", function()
		autoshop_logic.autoshop_kill_cooldowns()
	end)

	local payout = root:submenu("Payout")
	controls.payout_number = common.add_number_int(ctx, payout, "Payout", 0, AUTOSHOP_PAYOUT_MAX, 50000, function()
		return AutoshopConfig.payout
	end, function(value)
		AutoshopConfig.payout = value
	end)
	common.add_button(payout, "Set Max", function()
		AutoshopConfig.payout = AUTOSHOP_PAYOUT_MAX
		autoshop_menu.refresh_controls()
		if notify then
			notify.push("Auto Shop", "Payout set to max", 2000)
		end
	end)
	common.add_button(payout, "Apply Payout", function()
		autoshop_logic.autoshop_apply_payout()
	end)

	autoshop_menu.refresh_controls()
	return root
end

return autoshop_menu
