-- -------------------------------------------------------------------------
-- [Doomsday Functions]
-- -------------------------------------------------------------------------

local core = require_module("core/bootstrap")
local ui = require_module("core/ui")
local native_api = require_module("core/native_api")
local presets = require_module("shared/presets_and_shared")
local blip_teleport = require_module("shared/blip_teleport")

local config = core.config
local state = core.state
local run_guarded_job = core.run_guarded_job
local heist_skip_cutscene = native_api.heist_skip_cutscene
local GetMP = presets.GetMP
local SAFE_PAYOUT_TARGETS = presets.SAFE_PAYOUT_TARGETS
local hp_set_stat_for_all_characters = presets.hp_set_stat_for_all_characters
local hp_set_uniform_cuts = presets.hp_set_uniform_cuts
local hp_clamp_cut_percent = presets.hp_clamp_cut_percent
local BLIP_SPRITES_FACILITY = blip_teleport.BLIP_SPRITES_FACILITY
local BLIP_SPRITES_HEIST = blip_teleport.BLIP_SPRITES_HEIST
local teleport_to_blip_with_job = blip_teleport.teleport_to_blip_with_job

local DoomsdayCutsValues = {
	player1 = 100,
	player2 = 100,
	player3 = 100,
	player4 = 100,
}

local function register(heistTab)
	if type(heistTab) ~= "table" then
		return nil
	end

	-- Doomsday section (wrapped in do...end to reduce local variable count)
	do
		local function doomsday_complete_preps(act)
			local flow, status, notifications

			if act == 1 then
				-- Act I: The Data Breaches
				flow = 503
				status = -229383
				notifications = 1557
			elseif act == 2 then
				-- Act II: The Bogdan Problem
				flow = 240
				status = -229378
				notifications = 1557
			elseif act == 3 then
				-- Act III: The Doomsday Scenario
				flow = 16368
				status = -229380
				notifications = 1557
			else
				if notify then
					notify.push("Doomsday", "Invalid act selected", 2000)
				end
				return false
			end

			hp_set_stat_for_all_characters("GANGOPS_FLOW_MISSION_PROG", flow)
			hp_set_stat_for_all_characters("GANGOPS_HEIST_STATUS", status)
			hp_set_stat_for_all_characters("GANGOPS_FLOW_NOTIFICATIONS", notifications)

			-- Reload board
			script.locals("gb_gang_ops_planning", 211).int32 = 6

			if notify then
				notify.push("Doomsday", "Preps applied", 2000)
			end
			return true
		end

		local function doomsday_reset_progress()
			hp_set_stat_for_all_characters("GANGOPS_FLOW_MISSION_PROG", 503)
			hp_set_stat_for_all_characters("GANGOPS_HEIST_STATUS", 0)
			hp_set_stat_for_all_characters("GANGOPS_FLOW_NOTIFICATIONS", 1557)

			-- Reload board
			script.locals("gb_gang_ops_planning", 211).int32 = 6

			if notify then
				notify.push("Doomsday", "Progress reset", 2000)
			end
		end

		local function doomsday_force_ready()
			return run_guarded_job("doomsday_force_ready", function()
				if script and script.force_host then
					script.force_host("fm_mission_controller")
				end
				util.yield(1000)

				script.globals(1883089).int32 = 1
				script.globals(1883405).int32 = 1
				script.globals(1883721).int32 = 1

				if notify then
					notify.push("Doomsday Launch", "All players ready", 2000)
				end
			end, function()
				if notify then
					notify.push("Doomsday Launch", "Force ready already running", 1500)
				end
			end)
		end

		-- Doomsday Teleportation
		local function doomsday_teleport_to_entrance()
			return teleport_to_blip_with_job(
				BLIP_SPRITES_FACILITY,
				"Teleport",
				"Teleported to Facility",
				"Facility blip not found",
				{ relay_if_interior = true }
			)
		end

		local function doomsday_teleport_to_screen()
			return teleport_to_blip_with_job(
				BLIP_SPRITES_HEIST,
				"Teleport",
				"Teleported to Doomsday Screen",
				"Heist board blip not found (enter Facility first)",
				{ heading = 325.726 }
			)
		end

		-- Doomsday Tab Content
		local gDoomsdayInfo = ui.group(heistTab, "Info", nil, nil, nil, 160, "doomsday")
		ui.label(gDoomsdayInfo, "Doomsday Heist", config.colors.accent)
		ui.label(gDoomsdayInfo, "Max transaction: $2,550,000", config.colors.text_main)
		ui.label(gDoomsdayInfo, "Transaction cooldown: 30 min", config.colors.text_sec)
		ui.label(gDoomsdayInfo, "2 transactions in 30 min possible", config.colors.text_sec)
		ui.label(gDoomsdayInfo, "Heist cooldown: unknown", config.colors.text_sec)

		local gDoomsdayPreps = ui.group(heistTab, "Prep Presets", nil, nil, nil, nil, "doomsday")

		ui.button(gDoomsdayPreps, "doomsday_preset_act1", "Preset Act I: The Data Breaches", function()
			doomsday_complete_preps(1)
		end)
		ui.button(gDoomsdayPreps, "doomsday_preset_act2", "Preset Act II: The Bogdan Problem", function()
			doomsday_complete_preps(2)
		end)
		ui.button(gDoomsdayPreps, "doomsday_preset_act3", "Preset Act III: The Doomsday Scenario", function()
			doomsday_complete_preps(3)
		end)
		ui.button(gDoomsdayPreps, "doomsday_reset", "Reset Doomsday Heist", function()
			doomsday_reset_progress()
		end)

		-- Doomsday Launch group
		local gDoomsdayLaunch = ui.group(heistTab, "Launch", nil, nil, nil, nil, "doomsday")
		ui.toggle(gDoomsdayLaunch, "doomsday_launch_solo", "Solo Launch", state.solo_launch.doomsday, function(val)
			state.solo_launch.doomsday = val
		end)
		ui.button(gDoomsdayLaunch, "doomsday_launch_force_ready", "Force Ready", function()
			doomsday_force_ready()
		end)

		-- Doomsday Teleport group
		local gDoomsdayTeleport = ui.group(heistTab, "Teleport", nil, nil, nil, nil, "doomsday")
		ui.button_pair(
			gDoomsdayTeleport,
			"doomsday_teleport_entrance",
			"Teleport to Entrance",
			function()
				doomsday_teleport_to_entrance()
			end,
			"doomsday_teleport_screen",
			"Teleport to Screen",
			function()
				doomsday_teleport_to_screen()
			end
		)

		local function apply_doomsday_cuts(cuts)
			if not cuts then
				return false
			end

			script.globals(1969406).int32 = cuts[1] or 100
			script.globals(1969407).int32 = cuts[2] or 100
			script.globals(1969408).int32 = cuts[3] or 100
			script.globals(1969409).int32 = cuts[4] or 100

			if notify then
				notify.push("Doomsday Cuts", "Cuts applied", 2000)
			end
			return true
		end

		local function hp_get_doomsday_max_payout_cut()
			local p = GetMP()
			local heist = account.stats(p .. "GANGOPS_FLOW_MISSION_PROG").int32 or 503
			local difficulty_raw = script.globals(4718592 + 3538).int32 -- Heist.Generic.Difficulty
			local difficulty = 1

			-- Support both observed encodings:
			-- 0/1 = Normal/Hard and 1/2 = Normal/Hard
			if difficulty_raw ~= nil then
				if difficulty_raw <= 1 then
					difficulty = difficulty_raw + 1
				else
					difficulty = difficulty_raw
				end
			end

			if difficulty < 1 then
				difficulty = 1
			end
			if difficulty > 2 then
				difficulty = 2
			end

			local payouts = {
				[503] = { 975000, 1218750 }, -- Act I: Data Breaches
				[240] = { 1425000, 1771250 }, -- Act II: Bogdan Problem
				[16368] = { 1800000, 2250000 }, -- Act III: Doomsday Scenario
			}

			local payout_by_heist = payouts[heist] or payouts[503]
			local payout = payout_by_heist[difficulty] or payout_by_heist[1]
			local cut = math.floor(SAFE_PAYOUT_TARGETS.doomsday / (payout / 100))
			return hp_clamp_cut_percent(cut)
		end

		local gDoomsdayCuts = ui.group(heistTab, "Cuts", nil, nil, nil, nil, "doomsday")
		local doomsdayP1Slider = ui.slider(
			gDoomsdayCuts,
			"doomsday_cut_p1",
			"Player 1",
			0,
			300,
			DoomsdayCutsValues.player1,
			function(val)
				DoomsdayCutsValues.player1 = math.floor(val)
			end,
			nil,
			10
		)
		local doomsdayP2Slider = ui.slider(
			gDoomsdayCuts,
			"doomsday_cut_p2",
			"Player 2",
			0,
			300,
			DoomsdayCutsValues.player2,
			function(val)
				DoomsdayCutsValues.player2 = math.floor(val)
			end,
			nil,
			10
		)
		local doomsdayP3Slider = ui.slider(
			gDoomsdayCuts,
			"doomsday_cut_p3",
			"Player 3",
			0,
			300,
			DoomsdayCutsValues.player3,
			function(val)
				DoomsdayCutsValues.player3 = math.floor(val)
			end,
			nil,
			10
		)
		local doomsdayP4Slider = ui.slider(
			gDoomsdayCuts,
			"doomsday_cut_p4",
			"Player 4",
			0,
			300,
			DoomsdayCutsValues.player4,
			function(val)
				DoomsdayCutsValues.player4 = math.floor(val)
			end,
			nil,
			10
		)

		-- Preset row
		ui.button_pair(
			gDoomsdayCuts,
			"doomsday_preset_apply",
			"Apply Preset (100%)",
			function()
				hp_set_uniform_cuts(
					DoomsdayCutsValues,
					{ "player1", "player2", "player3", "player4" },
					{ doomsdayP1Slider, doomsdayP2Slider, doomsdayP3Slider, doomsdayP4Slider },
					100
				)
				if notify then
					notify.push("Doomsday Cuts", "100% cut preset loaded", 2000)
				end
			end,
			"doomsday_preset_max_instant",
			"Apply Preset (Max Payout)",
			function()
				hp_set_uniform_cuts(
					DoomsdayCutsValues,
					{ "player1", "player2", "player3", "player4" },
					{ doomsdayP1Slider, doomsdayP2Slider, doomsdayP3Slider, doomsdayP4Slider },
					hp_get_doomsday_max_payout_cut()
				)
				if notify then
					notify.push("Doomsday Cuts", "Max payout cut preset loaded", 2000)
				end
			end
		)

		ui.button(gDoomsdayCuts, "doomsday_cuts_apply", "Apply Cuts", function()
			apply_doomsday_cuts({
				DoomsdayCutsValues.player1,
				DoomsdayCutsValues.player2,
				DoomsdayCutsValues.player3,
				DoomsdayCutsValues.player4,
			})
		end)

		local function doomsday_data_hack()
			if script.running("fm_mission_controller") then
				script.locals("fm_mission_controller", 1541).int32 = 2
				if notify then
					notify.push("Doomsday Tools", "Data hack completed", 2000)
				end
				return true
			else
				if notify then
					notify.push("Doomsday Tools", "Hack not active", 2000)
				end
				return false
			end
		end

		local function doomsday_doomsday_hack()
			if script.running("fm_mission_controller") then
				script.locals("fm_mission_controller", 1298 + 135).int32 = 3
				if notify then
					notify.push("Doomsday Tools", "Doomsday hack completed", 2000)
				end
				return true
			else
				if notify then
					notify.push("Doomsday Tools", "Hack not active", 2000)
				end
				return false
			end
		end

		-- Instant Finish
		local function doomsday_instant_finish()
			run_guarded_job("doomsday_instant_finish", function()
				if script.force_host("fm_mission_controller") then
					util.yield(1000)
					script.locals("fm_mission_controller", 20395).int32 = 12
					script.locals("fm_mission_controller", 22136).int32 = 150
					script.locals("fm_mission_controller", 29017).int32 = 99999
					script.locals("fm_mission_controller", 32541).int32 = 99999
					script.locals("fm_mission_controller", 32569).int32 = 80
					if notify then
						notify.push("Doomsday Tools", "Instant finish triggered", 2000)
					end
				elseif notify then
					notify.push("Doomsday Tools", "Could not force host", 2000)
				end
			end, function()
				if notify then
					notify.push("Doomsday Tools", "Instant finish already running", 1500)
				end
			end)
		end

		local gDoomsdayTools = ui.group(heistTab, "Tools", nil, nil, nil, nil, "doomsday")
		ui.button_pair(
			gDoomsdayTools,
			"doomsday_data_hack",
			"Data Hack",
			function()
				doomsday_data_hack()
			end,
			"doomsday_doomsday_hack",
			"Doomsday Hack",
			function()
				doomsday_doomsday_hack()
			end
		)
		ui.button_pair(
			gDoomsdayTools,
			"doomsday_instant_finish",
			"Instant Finish",
			function()
				doomsday_instant_finish()
			end,
			"doomsday_skip_cutscene",
			"Skip Cutscene",
			function()
				heist_skip_cutscene("Doomsday")
			end
		)
	end -- End Doomsday section do block
	return heistTab
end

local doomsday_module = {
	DoomsdayCutsValues = DoomsdayCutsValues,
	register = register,
}

return doomsday_module
