local core = require("ShillenSilent_core.core.bootstrap")
local ui = require("ShillenSilent_core.core.ui")
local native_api = require("ShillenSilent_core.core.native_api")
local presets = require("ShillenSilent_core.shared.presets_and_shared")
local heist_state = require("ShillenSilent_core.shared.heist_state")
local danger_groups = require("ShillenSilent_core.shared.danger_groups")
local apartment_base = require("ShillenSilent_core.heists.apartment.base")
local blip_teleport = require("ShillenSilent_core.shared.blip_teleport")

local config = core.config
local state = core.state
local build_skip_cooldown_danger_group = danger_groups.build_skip_cooldown_danger_group
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
local hp_build_heist_preset_group = presets.hp_build_heist_preset_group
local hp_options_to_names = presets.hp_options_to_names
local hp_find_option_index = presets.hp_find_option_index
local APARTMENT_CUT_PRESET_OPTIONS = presets.APARTMENT_CUT_PRESET_OPTIONS
local hp_apply_selected_apartment_cut_preset = presets.hp_apply_selected_apartment_cut_preset
local hp_refresh_apartment_max_payout = presets.hp_refresh_apartment_max_payout

local apartment_state = heist_state.apartment
local ApartmentCutsValues = apartment_state.cuts
local apartment_flags = apartment_state.flags
local apartment_refs = apartment_state.refs
local apartment_callbacks = apartment_state.callbacks

local function register(heistTab)
	if type(heistTab) ~= "table" then
		return nil
	end

	-- Apartment Tab Content (wrapped in do...end to reduce local variable count)
	do
		local gApartmentInfo = ui.group(heistTab, "Info", nil, nil, nil, 160, "apartment")
		ui.label(gApartmentInfo, "Apartment Heist", config.colors.accent)
		ui.label(gApartmentInfo, "Max transaction: $3,000,000", config.colors.text_main)
		ui.label(gApartmentInfo, "Transaction cooldown: 3 min", config.colors.text_sec)
		ui.label(gApartmentInfo, "15M possible (Criminal Mastermind)", config.colors.text_sec)
		ui.label(gApartmentInfo, "Heist cooldown: unknown", config.colors.text_sec)

		local gApartmentLaunch = ui.group(heistTab, "Launch", nil, nil, nil, nil, "apartment")
		apartment_refs.solo_launch_toggle = ui.toggle(
			gApartmentLaunch,
			"apartment_launch_solo",
			"Solo Launch",
			state.solo_launch.apartment,
			function(val)
				state.solo_launch.apartment = val
			end
		)
		ui.button(gApartmentLaunch, "apartment_force_ready", "Force Ready", function()
			apartment_force_ready()
		end)
		ui.button(gApartmentLaunch, "apartment_redraw_board", "Redraw Board", function()
			apartment_redraw_board()
		end)

		local gApartmentPreps = ui.group(heistTab, "Preps", nil, nil, nil, nil, "apartment")
		ui.button(gApartmentPreps, "apartment_complete_preps", "Complete Preps", function()
			apartment_complete_preps()
		end)
		ui.button(gApartmentPreps, "apartment_change_session", "Change Session", function()
			apartment_change_session()
		end)

		hp_build_heist_preset_group(heistTab, "apartment", "apartment", "apartment")

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
			return teleport_to_blip_with_job(
				BLIP_SPRITES_HEIST,
				"Teleport",
				"Teleported to Heist Board",
				"Heist board blip not found (enter property first)",
				{ heading = 173.376 }
			)
		end

		local gApartmentTools = ui.group(heistTab, "Tools", nil, nil, nil, nil, "apartment")
		ui.button_pair(
			gApartmentTools,
			"apartment_fleeca_hack",
			"Fleeca Hack",
			function()
				apartment_fleeca_hack()
			end,
			"apartment_fleeca_drill",
			"Fleeca Drill",
			function()
				apartment_fleeca_drill()
			end
		)
		ui.button_pair(
			gApartmentTools,
			"apartment_pacific_hack",
			"Pacific Hack",
			function()
				apartment_pacific_hack()
			end,
			"apartment_play_unavailable",
			"Play Unavailable",
			function()
				apartment_play_unavailable()
			end
		)
		ui.button_pair(
			gApartmentTools,
			"apartment_unlock_all",
			"Unlock All Jobs",
			function()
				apartment_unlock_all_jobs(GetMP())
			end,
			"apartment_skip_cutscene",
			"Skip Cutscene",
			function()
				heist_skip_cutscene("Apartment")
			end
		)

		local gApartmentInstantFinish = ui.group(heistTab, "Instant Finish", nil, nil, nil, nil, "apartment")
		ui.button(
			gApartmentInstantFinish,
			"apartment_instant_finish_pacific",
			"Instant Finish (Pacific Standard)",
			function()
				apartment_instant_finish_pacific()
			end
		)
		ui.button(gApartmentInstantFinish, "apartment_instant_finish_other", "Instant Finish (Other)", function()
			apartment_instant_finish_other()
		end)

		local gApartmentTeleport = ui.group(heistTab, "Teleport", nil, nil, nil, nil, "apartment")
		ui.button(gApartmentTeleport, "apartment_tp_entrance", "Teleport to Entrance", function()
			apartment_teleport_to_entrance()
		end)
		ui.button(gApartmentTeleport, "apartment_tp_heist_board", "Teleport to Heist Board", function()
			apartment_teleport_to_heist_board()
		end)

		build_skip_cooldown_danger_group(heistTab, "apartment", "apartment_skip_heist_cooldown", function()
			apartment_kill_cooldown()
		end)

		-- Apply Apartment Cuts
		local function apply_apartment_cuts()
			return apartment_apply_cuts(ApartmentCutsValues)
		end

		local gApartmentCuts = ui.group(heistTab, "Cuts", nil, nil, nil, nil, "apartment")
		apartment_refs.p1_slider = ui.slider(
			gApartmentCuts,
			"apartment_cut_p1",
			"Host Cut %",
			0,
			3000,
			ApartmentCutsValues.player1,
			function(val)
				ApartmentCutsValues.player1 = math.floor(val)
			end,
			nil,
			10
		)
		apartment_refs.p2_slider = ui.slider(
			gApartmentCuts,
			"apartment_cut_p2",
			"Player 2 Cut %",
			0,
			3000,
			ApartmentCutsValues.player2,
			function(val)
				ApartmentCutsValues.player2 = math.floor(val)
			end,
			nil,
			10
		)
		apartment_refs.p3_slider = ui.slider(
			gApartmentCuts,
			"apartment_cut_p3",
			"Player 3 Cut %",
			0,
			3000,
			ApartmentCutsValues.player3,
			function(val)
				ApartmentCutsValues.player3 = math.floor(val)
			end,
			nil,
			10
		)
		apartment_refs.p4_slider = ui.slider(
			gApartmentCuts,
			"apartment_cut_p4",
			"Player 4 Cut %",
			0,
			3000,
			ApartmentCutsValues.player4,
			function(val)
				ApartmentCutsValues.player4 = math.floor(val)
			end,
			nil,
			10
		)

		local apartmentCutPresetNames = hp_options_to_names(APARTMENT_CUT_PRESET_OPTIONS)
		apartment_refs.preset_dropdown = ui.dropdown(
			gApartmentCuts,
			"apartment_cut_preset",
			"Preset",
			apartmentCutPresetNames,
			apartment_flags.cut_preset_index,
			function(opt)
				apartment_flags.cut_preset_index =
					hp_find_option_index(apartmentCutPresetNames, opt, apartment_flags.cut_preset_index)
			end
		)

		apartment_refs.max_payout_toggle = ui.toggle(
			gApartmentCuts,
			"apartment_max_payout",
			"3mil Payout",
			apartment_flags.max_payout_enabled,
			function(val)
				apartment_flags.max_payout_enabled = val
				if val then
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
			end
		)

		apartment_refs.double_toggle = ui.toggle(
			gApartmentCuts,
			"apartment_double_rewards",
			"Double Rewards Week",
			apartment_flags.double_rewards_week,
			function(val)
				apartment_flags.double_rewards_week = val
				if apartment_flags.max_payout_enabled then
					hp_refresh_apartment_max_payout(true, false)
				end
				if notify then
					notify.push("Apartment Cuts", val and "Double rewards enabled" or "Double rewards disabled", 2000)
				end
			end
		)

		ui.button(gApartmentCuts, "apartment_apply_selected_preset", "Apply Selected Preset", function()
			hp_apply_selected_apartment_cut_preset(true)
		end)
		ui.button(gApartmentCuts, "apartment_cuts_apply", "Apply Cuts", function()
			apply_apartment_cuts()
		end)

		-- 12M Bonus Function
		local function apartment_12mil_bonus(enable, silent)
			local ok = apartment_set_12mil_bonus(enable, silent)
			apartment_flags.bonus_enabled = enable
			return ok
		end

		-- Bonuses Group
		local gApartmentBonuses = ui.group(heistTab, "Bonuses", nil, nil, nil, nil, "apartment")
		apartment_refs.bonus_toggle = ui.toggle(
			gApartmentBonuses,
			"apartment_12m_bonus",
			"Enable 12M Bonus",
			apartment_flags.bonus_enabled,
			function(val)
				apartment_12mil_bonus(val)
			end
		)

		apartment_callbacks.apply_cuts = apply_apartment_cuts
		apartment_callbacks.set_bonus = apartment_12mil_bonus
	end -- End Apartment Tab do block
	return heistTab
end

local apartment_tabs = {
	ApartmentCutsValues = ApartmentCutsValues,
	register = register,
}

return apartment_tabs
