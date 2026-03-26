local core = require("ShillenSilent_core.core.bootstrap")
local native_api = require("ShillenSilent_core.core.native_api")
local presets = require("ShillenSilent_core.shared.presets_and_shared")
local heist_state = require("ShillenSilent_core.shared.heist_state")
local apartment_base = require("ShillenSilent_core.heists.apartment.base")
local blip_teleport = require("ShillenSilent_core.shared.blip_teleport")
local common = require("ShillenSilent_core.menu.common")

local state = core.state
local apartment_force_ready = apartment_base.apartment_force_ready
local apartment_redraw_board = apartment_base.apartment_redraw_board
local apartment_complete_preps = apartment_base.apartment_complete_preps
local apartment_kill_cooldown = apartment_base.apartment_kill_cooldown
local apartment_fleeca_hack = apartment_base.apartment_fleeca_hack
local apartment_fleeca_drill = apartment_base.apartment_fleeca_drill
local apartment_pacific_hack = apartment_base.apartment_pacific_hack
local apartment_instant_finish_pacific = apartment_base.apartment_instant_finish_pacific
local apartment_instant_finish_other = apartment_base.apartment_instant_finish_other
local apartment_play_unavailable = apartment_base.apartment_play_unavailable
local apartment_change_session = apartment_base.apartment_change_session
local apartment_unlock_all_jobs = apartment_base.apartment_unlock_all_jobs
local apartment_apply_cuts = apartment_base.apartment_apply_cuts
local apartment_set_12mil_bonus = apartment_base.apartment_set_12mil_bonus
local teleport_to_blip_with_job = blip_teleport.teleport_to_blip_with_job
local BLIP_SPRITES_APARTMENT = blip_teleport.BLIP_SPRITES_APARTMENT
local BLIP_SPRITES_HEIST = blip_teleport.BLIP_SPRITES_HEIST
local heist_skip_cutscene = native_api.heist_skip_cutscene
local GetMP = presets.GetMP
local APARTMENT_CUT_PRESET_OPTIONS = presets.APARTMENT_CUT_PRESET_OPTIONS
local hp_apply_selected_apartment_cut_preset = presets.hp_apply_selected_apartment_cut_preset
local hp_refresh_apartment_max_payout = presets.hp_refresh_apartment_max_payout

local apartment_state = heist_state.apartment
local ApartmentCutsValues = apartment_state.cuts
local apartment_flags = apartment_state.flags

local apartment_menu = {
	ctx = { syncing = false },
	controls = {},
}

local function is_in_apartment_interior()
	local me = players and players.me and players.me() or nil
	if not (me and me.in_interior) then
		return false
	end
	local in_kosatka = script and script.running and script.running("am_mp_submarine") or false
	local in_arcade = script and script.running and script.running("am_mp_arcade") or false
	local in_facility = script and script.running and script.running("am_mp_defunct_base") or false
	local in_agency = script and script.running and script.running("am_mp_fixer_hq") or false
	local in_autoshop = script and script.running and script.running("am_mp_auto_shop") or false
	local in_salvage = script and script.running and script.running("am_mp_salvage_yard") or false
	return not in_kosatka and not in_arcade and not in_facility and not in_agency and not in_autoshop and not in_salvage
end

local function apartment_teleport_to_entrance()
	return teleport_to_blip_with_job(
		BLIP_SPRITES_APARTMENT,
		"Teleport",
		"Teleported to Entrance",
		"Entrance blip not found",
		{ relay_if_interior = true }
	)
end

local function apartment_teleport_to_heist_board()
	if not is_in_apartment_interior() then
		if notify then
			notify.push("Teleport", "You must be inside an Apartment interior", 2200)
		end
		return false
	end

	return teleport_to_blip_with_job(
		BLIP_SPRITES_HEIST,
		"Teleport",
		"Teleported to Heist Board",
		"Heist board blip not found (enter property first)",
		{ heading = 173.376 }
	)
end

local function apply_apartment_cuts()
	return apartment_apply_cuts(ApartmentCutsValues)
end

local function apartment_12mil_bonus(enable, silent)
	local ok = apartment_set_12mil_bonus(enable, silent)
	apartment_flags.bonus_enabled = enable and true or false
	return ok
end

function apartment_menu.refresh_controls()
	local ctx = apartment_menu.ctx
	local controls = apartment_menu.controls

	common.set_control_value(ctx, controls.solo_launch_toggle, state.solo_launch.apartment and true or false)
	common.set_control_value(ctx, controls.bonus_toggle, apartment_flags.bonus_enabled and true or false)
	common.set_control_value(ctx, controls.double_toggle, apartment_flags.double_rewards_week and true or false)
	common.set_control_value(ctx, controls.max_payout_toggle, apartment_flags.max_payout_enabled and true or false)
	common.set_control_value(
		ctx,
		controls.preset_combo,
		common.clamp_int(apartment_flags.cut_preset_index, 1, #APARTMENT_CUT_PRESET_OPTIONS)
	)

	common.set_control_value(ctx, controls.p1_cut, common.clamp_int(ApartmentCutsValues.player1, 0, 3000))
	common.set_control_value(ctx, controls.p2_cut, common.clamp_int(ApartmentCutsValues.player2, 0, 3000))
	common.set_control_value(ctx, controls.p3_cut, common.clamp_int(ApartmentCutsValues.player3, 0, 3000))
	common.set_control_value(ctx, controls.p4_cut, common.clamp_int(ApartmentCutsValues.player4, 0, 3000))
	return true
end

function apartment_menu.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local ctx = apartment_menu.ctx
	local controls = apartment_menu.controls
	local root = parent_menu:submenu("Apartment")

	root:breaker("Apartment Heist")
	root:breaker("Max transaction: $3,000,000")
	root:breaker("Transaction cooldown: 3 min")
	root:breaker("15M possible (Criminal Mastermind)")
	root:breaker("Heist cooldown: unknown")

	local launch = root:submenu("Launch")
	controls.solo_launch_toggle = common.add_toggle(ctx, launch, "Solo Launch", function()
		return state.solo_launch.apartment
	end, function(enabled)
		state.solo_launch.apartment = enabled
	end)
	common.add_button(launch, "Force Ready", function()
		apartment_force_ready()
	end)
	common.add_button(launch, "Redraw Board", function()
		apartment_redraw_board()
	end)

	local preps = root:submenu("Preps")
	common.add_button(preps, "Complete Preps", function()
		apartment_complete_preps()
	end)
	common.add_button(preps, "Change Session", function()
		apartment_change_session()
	end)

	local tools = root:submenu("Tools")
	common.add_button(tools, "Fleeca Hack", function()
		apartment_fleeca_hack()
	end)
	common.add_button(tools, "Fleeca Drill", function()
		apartment_fleeca_drill()
	end)
	common.add_button(tools, "Pacific Hack", function()
		apartment_pacific_hack()
	end)
	common.add_button(tools, "Play Unavailable", function()
		apartment_play_unavailable()
	end)
	common.add_button(tools, "Unlock All Jobs", function()
		apartment_unlock_all_jobs(GetMP())
	end)
	common.add_button(tools, "Skip Cutscene", function()
		heist_skip_cutscene("Apartment")
	end)

	local finish = root:submenu("Instant Finish")
	common.add_button(finish, "Instant Finish (Pacific Standard)", function()
		apartment_instant_finish_pacific()
	end)
	common.add_button(finish, "Instant Finish (Other)", function()
		apartment_instant_finish_other()
	end)

	local tp = root:submenu("Teleport")
	common.add_button(tp, "Teleport to Entrance", function()
		apartment_teleport_to_entrance()
	end)
	common.add_button(tp, "Teleport to Heist Board", function()
		apartment_teleport_to_heist_board()
	end)

	local danger = root:submenu("Danger")
	danger:breaker("Warning: use with caution")
	common.add_button(danger, "Skip Heist Cooldown", function()
		apartment_kill_cooldown()
	end)

	local cuts = root:submenu("Cuts")
	controls.p1_cut = common.add_number_int(ctx, cuts, "Host Cut %", 0, 3000, 10, function()
		return ApartmentCutsValues.player1
	end, function(value)
		ApartmentCutsValues.player1 = value
	end)
	controls.p2_cut = common.add_number_int(ctx, cuts, "Player 2 Cut %", 0, 3000, 10, function()
		return ApartmentCutsValues.player2
	end, function(value)
		ApartmentCutsValues.player2 = value
	end)
	controls.p3_cut = common.add_number_int(ctx, cuts, "Player 3 Cut %", 0, 3000, 10, function()
		return ApartmentCutsValues.player3
	end, function(value)
		ApartmentCutsValues.player3 = value
	end)
	controls.p4_cut = common.add_number_int(ctx, cuts, "Player 4 Cut %", 0, 3000, 10, function()
		return ApartmentCutsValues.player4
	end, function(value)
		ApartmentCutsValues.player4 = value
	end)

	local preset_entries = {}
	for i = 1, #APARTMENT_CUT_PRESET_OPTIONS do
		preset_entries[i] = { APARTMENT_CUT_PRESET_OPTIONS[i].name, i }
	end
	controls.preset_combo = common.add_combo_entries(ctx, cuts, "Preset", preset_entries, function()
		return common.clamp_int(apartment_flags.cut_preset_index, 1, #APARTMENT_CUT_PRESET_OPTIONS)
	end, function(idx)
		apartment_flags.cut_preset_index = idx
	end)

	controls.max_payout_toggle = common.add_toggle(ctx, cuts, "3mil Payout", function()
		return apartment_flags.max_payout_enabled
	end, function(enabled)
		apartment_flags.max_payout_enabled = enabled and true or false
		if enabled then
			if not hp_refresh_apartment_max_payout(true, false) then
				if notify then
					notify.push("Apartment Cuts", "Unknown heist. Load an Apartment finale first.", 2400)
				end
			elseif notify then
				notify.push("Apartment Cuts", "3M payout mode enabled", 2000)
			end
		elseif notify then
			notify.push("Apartment Cuts", "3M payout mode disabled", 2000)
		end
	end)

	controls.double_toggle = common.add_toggle(ctx, cuts, "Double Rewards Week", function()
		return apartment_flags.double_rewards_week
	end, function(enabled)
		apartment_flags.double_rewards_week = enabled and true or false
		if apartment_flags.max_payout_enabled then
			hp_refresh_apartment_max_payout(true, false)
		end
		if notify then
			notify.push("Apartment Cuts", enabled and "Double rewards enabled" or "Double rewards disabled", 2000)
		end
	end)

	common.add_button(cuts, "Apply Selected Preset", function()
		hp_apply_selected_apartment_cut_preset(true)
		apartment_menu.refresh_controls()
	end)
	common.add_button(cuts, "Apply Cuts", function()
		apply_apartment_cuts()
	end)

	local bonuses = root:submenu("Bonuses")
	controls.bonus_toggle = common.add_toggle(ctx, bonuses, "Enable 12M Bonus", function()
		return apartment_flags.bonus_enabled
	end, function(enabled)
		apartment_12mil_bonus(enabled)
	end)

	apartment_menu.refresh_controls()
	return root
end

return apartment_menu
