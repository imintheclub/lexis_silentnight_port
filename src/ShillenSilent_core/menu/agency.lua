local agency_logic = require("ShillenSilent_core.heists.agency.logic")
local presets = require("ShillenSilent_core.shared.presets_and_shared")
local heist_state = require("ShillenSilent_core.shared.heist_state")
local common = require("ShillenSilent_core.menu.common")

local agency_state = heist_state.agency
local AgencyConfig = agency_state.config
local AgencyPrepOptions = agency_state.prep_options
local AGENCY_PAYOUT_MAX = presets.AGENCY_PAYOUT_MAX

local agency_menu = {
	ctx = { syncing = false },
	controls = {},
}

function agency_menu.refresh_controls()
	local ctx = agency_menu.ctx
	local controls = agency_menu.controls

	common.set_control_value(
		ctx,
		controls.contract_combo,
		common.find_index_by_value(AgencyPrepOptions.contracts, AgencyConfig.contract, 1)
	)
	common.set_control_value(ctx, controls.payout_number, common.clamp_int(AgencyConfig.payout, 0, AGENCY_PAYOUT_MAX))
	return true
end

function agency_menu.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local ctx = agency_menu.ctx
	local controls = agency_menu.controls

	local root = parent_menu:submenu("Agency")
	root:breaker("Agency")
	root:breaker("Max transaction: $2,500,000")
	root:breaker("Transaction cooldown: 20 min")

	local preps = root:submenu("Preps")
	controls.contract_combo = common.add_combo_options(ctx, preps, "Contract", AgencyPrepOptions.contracts, function()
		return AgencyConfig.contract
	end, function(value)
		AgencyConfig.contract = value
	end)
	common.add_button(preps, "Apply & Complete Preps", function()
		agency_logic.agency_apply_and_complete_preps()
	end)

	local misc = root:submenu("Misc")
	common.add_button(misc, "Teleport to Entrance", function()
		agency_logic.agency_teleport_entrance()
	end)
	common.add_button(misc, "Teleport to Computer", function()
		agency_logic.agency_teleport_computer()
	end)
	common.add_button(misc, "Teleport to Mission", function()
		agency_logic.agency_teleport_mission()
	end)
	common.add_button(misc, "Collect Safe", function()
		agency_logic.agency_collect_safe()
	end)
	common.add_button(misc, "Instant Finish", function()
		agency_logic.agency_instant_finish_new()
	end)

	local danger = root:submenu("Danger")
	danger:breaker("Warning: use with caution")
	common.add_button(danger, "Skip Heist Cooldowns", function()
		agency_logic.agency_kill_cooldowns()
	end)

	local payout = root:submenu("Payout")
	controls.payout_number = common.add_number_int(ctx, payout, "Payout", 0, AGENCY_PAYOUT_MAX, 50000, function()
		return AgencyConfig.payout
	end, function(value)
		AgencyConfig.payout = value
	end)
	common.add_button(payout, "Set Max", function()
		AgencyConfig.payout = AGENCY_PAYOUT_MAX
		agency_menu.refresh_controls()
		if notify then
			notify.push("Agency", "Payout set to max", 2000)
		end
	end)
	common.add_button(payout, "Apply Payout", function()
		agency_logic.agency_apply_payout()
	end)

	agency_logic.agency_refresh_collect_safe_state()
	agency_menu.refresh_controls()
	return root
end

return agency_menu
