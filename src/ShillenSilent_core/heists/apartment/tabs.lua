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
local run_guarded_job = core.run_guarded_job
local build_skip_cooldown_danger_group = danger_groups.build_skip_cooldown_danger_group
local ApartmentGlobals = apartment_base.ApartmentGlobals
local apartment_force_ready = apartment_base.apartment_force_ready
local apartment_redraw_board = apartment_base.apartment_redraw_board
local apartment_complete_preps = apartment_base.apartment_complete_preps
local apartment_kill_cooldown = apartment_base.apartment_kill_cooldown
local teleport_to_blip_with_job = blip_teleport.teleport_to_blip_with_job
local BLIP_SPRITES_APARTMENT = blip_teleport.BLIP_SPRITES_APARTMENT
local BLIP_SPRITES_HEIST = blip_teleport.BLIP_SPRITES_HEIST
local heist_skip_cutscene = native_api.heist_skip_cutscene
local GetMP = presets.GetMP
local hp_build_heist_preset_group = presets.hp_build_heist_preset_group
local hp_set_uniform_cuts = presets.hp_set_uniform_cuts
local hp_options_to_names = presets.hp_options_to_names
local hp_find_option_index = presets.hp_find_option_index
local hp_set_apartment_uniform_cuts = presets.hp_set_apartment_uniform_cuts
local APARTMENT_CUT_PRESET_OPTIONS = presets.APARTMENT_CUT_PRESET_OPTIONS
local hp_apply_selected_apartment_cut_preset = presets.hp_apply_selected_apartment_cut_preset
local hp_refresh_apartment_max_payout = presets.hp_refresh_apartment_max_payout
local hp_get_apartment_max_payout_cut = presets.hp_get_apartment_max_payout_cut

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
		local apartment_change_session

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

		local apartmentPresetsGroup = hp_build_heist_preset_group(heistTab, "apartment", "apartment", "apartment")

		local function apartment_fleeca_hack()
			if script.running("fm_mission_controller") then
				script.locals("fm_mission_controller", 12223 + 24).int32 = 7
				if notify then
					notify.push("Apartment Tools", "Fleeca hack completed", 2000)
				end
			else
				if notify then
					notify.push("Apartment Tools", "Hack not active", 2000)
				end
			end
		end

		local function apartment_fleeca_drill()
			if script.running("fm_mission_controller") then
				script.locals("fm_mission_controller", 10511 + 11).float = 100.0
				if notify then
					notify.push("Apartment Tools", "Fleeca drill completed", 2000)
				end
			else
				if notify then
					notify.push("Apartment Tools", "Drill not active", 2000)
				end
			end
		end

		local function apartment_pacific_hack()
			if script.running("fm_mission_controller") then
				script.locals("fm_mission_controller", 10217).int32 = 9
				if notify then
					notify.push("Apartment Tools", "Pacific hack completed", 2000)
				end
			else
				if notify then
					notify.push("Apartment Tools", "Hack not active", 2000)
				end
			end
		end

		-- Instant Finish (Pacific Standard)
		local function apartment_instant_finish_pacific()
			run_guarded_job("apartment_instant_finish_pacific", function()
				if script.force_host("fm_mission_controller") then
					util.yield(1000)
					script.locals("fm_mission_controller", 21457).int32 = 5
					script.locals("fm_mission_controller", 22136).int32 = 80
					script.locals("fm_mission_controller", 23081).int32 = 10000000
					script.locals("fm_mission_controller", 29017).int32 = 99999
					script.locals("fm_mission_controller", 32541).int32 = 99999
					if notify then
						notify.push("Apartment", "Instant finish triggered (Pacific Standard)", 2000)
					end
				else
					if notify then
						notify.push("Apartment", "Could not force host", 2000)
					end
				end
			end, function()
				if notify then
					notify.push("Apartment", "Instant finish already running", 1500)
				end
			end)
		end

		-- Instant Finish (Other Classics)
		local function apartment_instant_finish_other()
			run_guarded_job("apartment_instant_finish_other", function()
				if script.force_host("fm_mission_controller") then
					util.yield(1000)
					script.locals("fm_mission_controller", 20395).int32 = 12
					script.locals("fm_mission_controller", 23081).int32 = 99999
					script.locals("fm_mission_controller", 29017).int32 = 99999
					script.locals("fm_mission_controller", 32541).int32 = 99999
					if notify then
						notify.push("Apartment", "Instant finish triggered (Other Classics)", 2000)
					end
				else
					if notify then
						notify.push("Apartment", "Could not force host", 2000)
					end
				end
			end, function()
				if notify then
					notify.push("Apartment", "Instant finish already running", 1500)
				end
			end)
		end

		local function apartment_play_unavailable()
			local player_id = (players and players.user and players.user()) or 0
			local cooldown_global = 1877303 + 1 + (player_id * 77) + 76
			script.globals(cooldown_global).int32 = -1
			if notify then
				notify.push("Apartment Tools", "Unavailable jobs unlocked", 2000)
			end
		end

		apartment_change_session = function()
			local started

			local result = invoker.call(0xED34C0C02C098BB7, 0, 32) -- NETWORK_SESSION_HOST_CLOSED
			if result and result.bool then
				started = true
			else
				local fallback = invoker.call(0x6F3D4ED9BEE4E61D, 0, 32, true) -- NETWORK_SESSION_HOST
				started = (fallback and fallback.bool) and true or false
			end

			if started then
				if notify then
					notify.push("Apartment Tools", "Invite-only session started", 2000)
				end
			else
				if notify then
					notify.push("Apartment Tools", "Could not change session. Change it manually.", 2800)
				end
			end

			return started
		end

		local function apartment_unlock_all_jobs()
			local p = GetMP()
			local function hash_text(text)
				if type(joaat) == "function" then
					return joaat(text)
				end
				local hashed = invoker.call(0xD24D37CC275948CC, text) -- GET_HASH_KEY
				return (hashed and hashed.int) or 0
			end

			local root_hashes = {
				hash_text("33TxqLipLUintwlU_YDzMg"),
				hash_text("A6UBSyF61kiveglc58lm2Q"),
				hash_text("a_hWnpMUz0-7Yd_Rc5pJ4w"),
				hash_text("7r5AKL5aB0qe9HiDy3nW8w"),
				hash_text("hKSf9RCT8UiaZlykyGrMwg"),
			}

			for i = 0, 4 do
				account.stats(p .. "HEIST_SAVED_STRAND_" .. i).int32 = root_hashes[i + 1]
				account.stats(p .. "HEIST_SAVED_STRAND_" .. i .. "_L").int32 = 5
			end

			script.globals(ApartmentGlobals.Board).int32 = 22
			if notify then
				notify.push("Apartment Tools", "All jobs unlocked. Change session to apply.", 2600)
			end
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
				apartment_unlock_all_jobs()
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
			local base_global = 1936013
			local base_local = 1937981
			local total_cut = ApartmentCutsValues.player1
				+ ApartmentCutsValues.player2
				+ ApartmentCutsValues.player3
				+ ApartmentCutsValues.player4

			-- Calculate over_cap - if total > 100, we need to compensate
			local over_cap = total_cut - 100
			if over_cap > 0 then
				script.globals(base_global + 1 + 1).int32 = -over_cap
			else
				script.globals(base_global + 1 + 1).int32 = 0
			end

			-- Set globals for players 2, 3, 4
			script.globals(base_global + 1 + 2).int32 = ApartmentCutsValues.player2
			script.globals(base_global + 1 + 3).int32 = ApartmentCutsValues.player3
			script.globals(base_global + 1 + 4).int32 = ApartmentCutsValues.player4

			-- Set locals for ALL players (critical fix!)
			script.globals(base_local + 3008 + 1).int32 = ApartmentCutsValues.player1
			script.globals(base_local + 3008 + 2).int32 = ApartmentCutsValues.player2
			script.globals(base_local + 3008 + 3).int32 = ApartmentCutsValues.player3
			script.globals(base_local + 3008 + 4).int32 = ApartmentCutsValues.player4

			if notify then
				notify.push("Apartment Cuts", "Cuts applied", 2000)
			end
		end

		local gApartmentCuts = ui.group(heistTab, "Cuts", nil, nil, nil, nil, "apartment")
		apartment_refs.p1_slider = ui.slider(
			gApartmentCuts,
			"apartment_cut_p1",
			"Host Cut %",
			0,
			300,
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
			300,
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
			300,
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
			300,
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

		ui.button_pair(
			gApartmentCuts,
			"apartment_apply_selected_preset",
			"Apply Selected Preset",
			function()
				hp_apply_selected_apartment_cut_preset(true)
			end,
			"apartment_cuts_max_instant",
			"Apply Preset (Max Payout)",
			function()
				local cut = hp_get_apartment_max_payout_cut(apartment_flags.double_rewards_week)
				if not cut then
					if notify then
						notify.push("Apartment Cuts", "Unknown heist. Load an Apartment finale first.", 2400)
					end
					return
				end
				hp_set_apartment_uniform_cuts(cut, true)
			end
		)
		ui.button(gApartmentCuts, "apartment_cuts_apply", "Apply Cuts", function()
			apply_apartment_cuts()
		end)

		-- 12M Bonus Function
		local function apartment_12mil_bonus(enable, silent)
			if enable then
				account.stats("MPPLY_HEISTFLOWORDERPROGRESS").int32 = 268435455
				account.stats("MPPLY_AWD_HST_ORDER").bool = false

				account.stats("MPPLY_HEISTTEAMPROGRESSBITSET").int32 = 268435455
				account.stats("MPPLY_AWD_HST_SAME_TEAM").bool = false

				account.stats("MPPLY_HEISTNODEATHPROGREITSET").int32 = 268435455
				account.stats("MPPLY_AWD_HST_ULT_CHAL").bool = false
				if not silent and notify then
					notify.push("Apartment Bonuses", "12M bonus enabled", 2000)
				end
			else
				account.stats("MPPLY_HEISTFLOWORDERPROGRESS").int32 = 134217727
				account.stats("MPPLY_AWD_HST_ORDER").bool = true

				account.stats("MPPLY_HEISTTEAMPROGRESSBITSET").int32 = 134217727
				account.stats("MPPLY_AWD_HST_SAME_TEAM").bool = true

				account.stats("MPPLY_HEISTNODEATHPROGREITSET").int32 = 134217727
				account.stats("MPPLY_AWD_HST_ULT_CHAL").bool = true
				if not silent and notify then
					notify.push("Apartment Bonuses", "12M bonus disabled", 2000)
				end
			end
			apartment_flags.bonus_enabled = enable
			return true
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
