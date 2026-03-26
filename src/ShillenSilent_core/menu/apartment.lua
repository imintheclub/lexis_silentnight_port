local core = require("ShillenSilent_core.core.bootstrap")
local native_api = require("ShillenSilent_core.core.native_api")
local presets = require("ShillenSilent_core.shared.presets_and_shared")
local heist_state = require("ShillenSilent_core.shared.heist_state")
local apartment_base = require("ShillenSilent_core.heists.apartment.base")
local blip_teleport = require("ShillenSilent_core.shared.blip_teleport")
local common = require("ShillenSilent_core.menu.common")

local state = core.state
local run_guarded_job = core.run_guarded_job
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

local function is_script_running(script_name)
	local ok, result = pcall(script.running, script_name)
	return ok and result and true or false
end

local function force_script_host(script_name)
	local ok, result = pcall(script.force_host, script_name)
	return ok and result and true or false
end

local function set_local_int(script_name, offset, value)
	local ok = pcall(function()
		script.locals(script_name, offset).int32 = value
	end)
	return ok
end

local function set_local_float(script_name, offset, value)
	local ok = pcall(function()
		script.locals(script_name, offset).float = value
	end)
	return ok
end

local function set_global_int(offset, value)
	local ok = pcall(function()
		script.globals(offset).int32 = value
	end)
	return ok
end

local function set_stat_int(stat_name, value)
	local ok = pcall(function()
		local stat = account.stats(stat_name)
		if not stat then
			error("missing stat")
		end
		stat.int32 = value
	end)
	return ok
end

local function set_stat_bool(stat_name, value)
	local ok = pcall(function()
		local stat = account.stats(stat_name)
		if not stat then
			error("missing stat")
		end
		stat.bool = value and true or false
	end)
	return ok
end

local function apartment_fleeca_hack()
	if is_script_running("fm_mission_controller") then
		local ok = set_local_int("fm_mission_controller", 12223 + 24, 7)
		if notify then
			notify.push("Apartment Tools", ok and "Fleeca hack completed" or "Fleeca hack write failed", 2000)
		end
	else
		if notify then
			notify.push("Apartment Tools", "Hack not active", 2000)
		end
	end
end

local function apartment_fleeca_drill()
	if is_script_running("fm_mission_controller") then
		local ok = set_local_float("fm_mission_controller", 10511 + 11, 100.0)
		if notify then
			notify.push("Apartment Tools", ok and "Fleeca drill completed" or "Fleeca drill write failed", 2000)
		end
	else
		if notify then
			notify.push("Apartment Tools", "Drill not active", 2000)
		end
	end
end

local function apartment_pacific_hack()
	if is_script_running("fm_mission_controller") then
		local ok = set_local_int("fm_mission_controller", 10217, 9)
		if notify then
			notify.push("Apartment Tools", ok and "Pacific hack completed" or "Pacific hack write failed", 2000)
		end
	else
		if notify then
			notify.push("Apartment Tools", "Hack not active", 2000)
		end
	end
end

local function apartment_instant_finish_pacific()
	run_guarded_job("apartment_instant_finish_pacific", function()
		if not is_script_running("fm_mission_controller") then
			if notify then
				notify.push("Apartment", "fm_mission_controller is not running", 2000)
			end
			return
		end
		if not force_script_host("fm_mission_controller") then
			if notify then
				notify.push("Apartment", "Could not force host", 2000)
			end
			return
		end

		util.yield(1000)
		local ok = true
		ok = set_local_int("fm_mission_controller", 21457, 5) and ok
		ok = set_local_int("fm_mission_controller", 22136, 80) and ok
		ok = set_local_int("fm_mission_controller", 23081, 10000000) and ok
		ok = set_local_int("fm_mission_controller", 29017, 99999) and ok
		ok = set_local_int("fm_mission_controller", 32541, 99999) and ok
		if notify then
			notify.push(
				"Apartment",
				ok and "Instant finish triggered (Pacific Standard)" or "Instant finish write failed",
				2000
			)
		end
	end, function()
		if notify then
			notify.push("Apartment", "Instant finish already running", 1500)
		end
	end)
end

local function apartment_instant_finish_other()
	run_guarded_job("apartment_instant_finish_other", function()
		if not is_script_running("fm_mission_controller") then
			if notify then
				notify.push("Apartment", "fm_mission_controller is not running", 2000)
			end
			return
		end
		if not force_script_host("fm_mission_controller") then
			if notify then
				notify.push("Apartment", "Could not force host", 2000)
			end
			return
		end

		util.yield(1000)
		local ok = true
		ok = set_local_int("fm_mission_controller", 20395, 12) and ok
		ok = set_local_int("fm_mission_controller", 23081, 99999) and ok
		ok = set_local_int("fm_mission_controller", 29017, 99999) and ok
		ok = set_local_int("fm_mission_controller", 32541, 99999) and ok
		if notify then
			notify.push(
				"Apartment",
				ok and "Instant finish triggered (Other Classics)" or "Instant finish write failed",
				2000
			)
		end
	end, function()
		if notify then
			notify.push("Apartment", "Instant finish already running", 1500)
		end
	end)
end

local function apartment_play_unavailable()
	local player_id = (players and players.user and players.user()) or 0
	local cooldown_step1 = ApartmentGlobals.Cooldown.STEP1 + (player_id * 77)
	local ok = true
	ok = set_global_int(cooldown_step1, -1) and ok
	ok = set_global_int(ApartmentGlobals.Cooldown.STEP2, 0) and ok
	if notify then
		notify.push("Apartment Tools", ok and "Unavailable jobs unlocked" or "Play unavailable failed", 2000)
	end
end

local function apartment_change_session()
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

	local ok = true
	for i = 0, 4 do
		ok = set_stat_int(p .. "HEIST_SAVED_STRAND_" .. i, root_hashes[i + 1]) and ok
		ok = set_stat_int(p .. "HEIST_SAVED_STRAND_" .. i .. "_L", 5) and ok
	end

	ok = apartment_redraw_board() and ok
	if notify then
		notify.push(
			"Apartment Tools",
			ok and "All jobs unlocked. Change session to apply." or "Unlock-all write failed",
			2600
		)
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

local function apply_apartment_cuts()
	local base_pairs = {
		{ global_base = 1936013, local_base = 1937981 },
		{ global_base = 1935536, local_base = 1937504 },
	}
	local total_cut = ApartmentCutsValues.player1
		+ ApartmentCutsValues.player2
		+ ApartmentCutsValues.player3
		+ ApartmentCutsValues.player4
	local over_cap = total_cut - 100
	local any_pair_ok = false

	for i = 1, #base_pairs do
		local pair = base_pairs[i]
		local pair_ok = true
		if over_cap > 0 then
			pair_ok = set_global_int(pair.global_base + 1 + 1, -over_cap) and pair_ok
		else
			pair_ok = set_global_int(pair.global_base + 1 + 1, 0) and pair_ok
		end

		pair_ok = set_global_int(pair.global_base + 1 + 2, ApartmentCutsValues.player2) and pair_ok
		pair_ok = set_global_int(pair.global_base + 1 + 3, ApartmentCutsValues.player3) and pair_ok
		pair_ok = set_global_int(pair.global_base + 1 + 4, ApartmentCutsValues.player4) and pair_ok

		pair_ok = set_global_int(pair.local_base + 3008 + 1, ApartmentCutsValues.player1) and pair_ok
		pair_ok = set_global_int(pair.local_base + 3008 + 2, ApartmentCutsValues.player2) and pair_ok
		pair_ok = set_global_int(pair.local_base + 3008 + 3, ApartmentCutsValues.player3) and pair_ok
		pair_ok = set_global_int(pair.local_base + 3008 + 4, ApartmentCutsValues.player4) and pair_ok

		any_pair_ok = any_pair_ok or pair_ok
	end

	if notify then
		notify.push("Apartment Cuts", any_pair_ok and "Cuts applied" or "Cut write failed", 2000)
	end
	return any_pair_ok
end

local function apartment_12mil_bonus(enable, silent)
	local ok = true
	if enable then
		ok = set_stat_int("MPPLY_HEISTFLOWORDERPROGRESS", 268435455) and ok
		ok = set_stat_bool("MPPLY_AWD_HST_ORDER", false) and ok
		ok = set_stat_int("MPPLY_HEISTTEAMPROGRESSBITSET", 268435455) and ok
		ok = set_stat_bool("MPPLY_AWD_HST_SAME_TEAM", false) and ok
		ok = set_stat_int("MPPLY_HEISTNODEATHPROGREITSET", 268435455) and ok
		ok = set_stat_bool("MPPLY_AWD_HST_ULT_CHAL", false) and ok
		if not silent and notify then
			notify.push("Apartment Bonuses", ok and "12M bonus enabled" or "12M bonus write failed", 2000)
		end
	else
		ok = set_stat_int("MPPLY_HEISTFLOWORDERPROGRESS", 134217727) and ok
		ok = set_stat_bool("MPPLY_AWD_HST_ORDER", true) and ok
		ok = set_stat_int("MPPLY_HEISTTEAMPROGRESSBITSET", 134217727) and ok
		ok = set_stat_bool("MPPLY_AWD_HST_SAME_TEAM", true) and ok
		ok = set_stat_int("MPPLY_HEISTNODEATHPROGREITSET", 134217727) and ok
		ok = set_stat_bool("MPPLY_AWD_HST_ULT_CHAL", true) and ok
		if not silent and notify then
			notify.push("Apartment Bonuses", ok and "12M bonus disabled" or "12M bonus write failed", 2000)
		end
	end
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
		apartment_unlock_all_jobs()
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
