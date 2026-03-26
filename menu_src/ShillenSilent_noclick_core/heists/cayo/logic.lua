-- ---------------------------------------------------------

local core = require("ShillenSilent_noclick_core.core.bootstrap")
local safe_access = require("ShillenSilent_noclick_core.core.safe_access")
local presets = require("ShillenSilent_noclick_core.shared.presets_and_shared")
local heist_state = require("ShillenSilent_noclick_core.shared.heist_state")
local coords_teleport = require("ShillenSilent_noclick_core.shared.coords_teleport")
local run_guarded_job = core.run_guarded_job
local run_coords_teleport = coords_teleport.run_coords_teleport
local try_begin_teleport_cooldown = coords_teleport.try_begin_teleport_cooldown
local GetMP = presets.GetMP
local SAFE_PAYOUT_TARGETS = presets.SAFE_PAYOUT_TARGETS
local hp_clamp_cut_percent = presets.hp_clamp_cut_percent

local cayo_state = heist_state.cayo
local CayoPrepOptions = cayo_state.prep_options
local CayoConfig = cayo_state.config
local CayoCutsValues = cayo_state.cuts
local cayo_flags = cayo_state.flags
local cayo_refs = cayo_state.refs
local cayo_callbacks = cayo_state.callbacks

-- Globals for Cayo Perico
local CayoGlobals = {
	Host = 1980923,
	P2 = 1980924,
	P3 = 1980925,
	P4 = 1980926,
	ReadyBase = 1981147,
}

local CayoReady = {
	PLAYER1 = 1981156,
	PLAYER2 = 1981184,
	PLAYER3 = 1981211,
	PLAYER4 = 1981238,
}

local CAYO_TUNABLE_DEFAULTS = {
	bag_max_capacity = 1800,
	pavel_cut = -0.02,
	fencing_fee = -0.1,
}

local cayo_tunable_backup = {
	bag_max_capacity = nil,
	pavel_cut = nil,
	fencing_fee = nil,
}
local cayo_apply_cuts

local cayo_max_payout_cache = {
	target = nil,
	difficulty = nil,
	cut = nil,
}

local function cayo_sync_crew_cut_ui_lock()
	local toggle = cayo_refs.remove_crew_cuts_toggle
	if not toggle then
		return
	end
	if cayo_flags.max_payout_enabled then
		toggle.label = "Remove Crew Cuts (Locked by Max Payout)"
		toggle.state = false
		toggle.disabled = true
	else
		toggle.label = "Remove Crew Cuts"
		toggle.disabled = false
	end
end

local function hp_tunable_int(name)
	return script.tunables(name).int32
end

local function hp_tunable_float(name)
	return script.tunables(name).float
end

local function hp_set_tunable_int(name, value)
	script.tunables(name).int32 = value
end

local function hp_set_tunable_float(name, value)
	script.tunables(name).float = value
end

local function cayo_set_womans_bag(enable, silent)
	local enabled = enable and true or false
	local changed = (cayo_flags.womans_bag_enabled ~= enabled)

	if enabled and cayo_tunable_backup.bag_max_capacity == nil then
		cayo_tunable_backup.bag_max_capacity = hp_tunable_int("HEIST_BAG_MAX_CAPACITY")
	end

	if enabled then
		hp_set_tunable_int("HEIST_BAG_MAX_CAPACITY", 99999)
	else
		local restore = cayo_tunable_backup.bag_max_capacity
		if restore == nil then
			restore = CAYO_TUNABLE_DEFAULTS.bag_max_capacity
		end
		hp_set_tunable_int("HEIST_BAG_MAX_CAPACITY", restore)
	end

	cayo_flags.womans_bag_enabled = enabled
	if cayo_refs.womans_bag_toggle then
		cayo_refs.womans_bag_toggle.state = enabled
	end
	if changed and not silent and notify then
		notify.push("Cayo Perico", enabled and "Woman's bag enabled" or "Woman's bag disabled", 2000)
	end
end

local function cayo_set_remove_crew_cuts(enable, silent)
	local enabled = enable and true or false
	if cayo_flags.max_payout_enabled and enabled then
		enabled = false
	end
	local changed = (cayo_flags.remove_crew_cuts_enabled ~= enabled)

	if enabled then
		if cayo_tunable_backup.pavel_cut == nil then
			cayo_tunable_backup.pavel_cut = hp_tunable_float("IH_DEDUCTION_PAVEL_CUT")
		end
		if cayo_tunable_backup.fencing_fee == nil then
			cayo_tunable_backup.fencing_fee = hp_tunable_float("IH_DEDUCTION_FENCING_FEE")
		end

		hp_set_tunable_float("IH_DEDUCTION_PAVEL_CUT", 0.0)
		hp_set_tunable_float("IH_DEDUCTION_FENCING_FEE", 0.0)
	else
		local restore_pavel = cayo_tunable_backup.pavel_cut
		local restore_fee = cayo_tunable_backup.fencing_fee
		if restore_pavel == nil then
			restore_pavel = CAYO_TUNABLE_DEFAULTS.pavel_cut
		end
		if restore_fee == nil then
			restore_fee = CAYO_TUNABLE_DEFAULTS.fencing_fee
		end

		hp_set_tunable_float("IH_DEDUCTION_PAVEL_CUT", restore_pavel)
		hp_set_tunable_float("IH_DEDUCTION_FENCING_FEE", restore_fee)
	end

	cayo_flags.remove_crew_cuts_enabled = enabled
	if cayo_refs.remove_crew_cuts_toggle then
		cayo_refs.remove_crew_cuts_toggle.state = enabled
	end
	cayo_sync_crew_cut_ui_lock()
	if changed and not silent and notify then
		notify.push("Cayo Perico", enabled and "Crew cuts removed" or "Crew cuts restored", 2000)
	end
end

local function cayo_enforce_heist_toggles()
	if cayo_flags.womans_bag_enabled then
		hp_set_tunable_int("HEIST_BAG_MAX_CAPACITY", 99999)
	end
	if cayo_flags.max_payout_enabled and cayo_flags.remove_crew_cuts_enabled then
		cayo_set_remove_crew_cuts(false, true)
	end
	if cayo_flags.remove_crew_cuts_enabled then
		hp_set_tunable_float("IH_DEDUCTION_PAVEL_CUT", 0.0)
		hp_set_tunable_float("IH_DEDUCTION_FENCING_FEE", 0.0)
	end
	cayo_sync_crew_cut_ui_lock()
end

-- Apply Cayo Preps
local function cayo_apply_preps()
	local p = GetMP()

	if CayoConfig.unlock_all_poi then
		safe_access.set_stat_int(p .. "H4CNF_BS_GEN", -1)
		safe_access.set_stat_int(p .. "H4CNF_BS_ENTR", 63)
		safe_access.set_stat_int(p .. "H4CNF_BS_ABIL", 63)
		safe_access.set_stat_int(p .. "H4CNF_APPROACH", -1)
		safe_access.set_stat_int(p .. "H4_PLAYTHROUGH_STATUS", 10)
	end

	safe_access.set_stat_int(p .. "H4_PROGRESS", CayoConfig.diff)
	safe_access.set_stat_int(p .. "H4_MISSIONS", CayoConfig.app)
	safe_access.set_stat_int(p .. "H4CNF_WEAPONS", CayoConfig.wep)
	safe_access.set_stat_int(p .. "H4CNF_TARGET", CayoConfig.tgt)

	local has_secondary_target = (CayoConfig.sec_comp ~= "NONE") or (CayoConfig.sec_isl ~= "NONE")
	local value_map = {
		CASH = CayoConfig.val_cash,
		WEED = CayoConfig.val_weed,
		COKE = CayoConfig.val_coke,
		GOLD = CayoConfig.val_gold,
	}

	local loots = { "CASH", "WEED", "COKE", "GOLD" }
	for _, loot in ipairs(loots) do
		local compound_value = (CayoConfig.sec_comp == loot) and CayoConfig.amt_comp or 0
		local island_value = (CayoConfig.sec_isl == loot) and CayoConfig.amt_isl or 0
		local value_stat = has_secondary_target and value_map[loot] or 0

		safe_access.set_stat_int(p .. "H4LOOT_" .. loot .. "_C", compound_value)
		safe_access.set_stat_int(p .. "H4LOOT_" .. loot .. "_C_SCOPED", compound_value)
		safe_access.set_stat_int(p .. "H4LOOT_" .. loot .. "_I", island_value)
		safe_access.set_stat_int(p .. "H4LOOT_" .. loot .. "_I_SCOPED", island_value)
		safe_access.set_stat_int(p .. "H4LOOT_" .. loot .. "_V", value_stat)
	end

	safe_access.set_stat_int(p .. "H4LOOT_PAINT", CayoConfig.paint)
	safe_access.set_stat_int(p .. "H4LOOT_PAINT_SCOPED", CayoConfig.paint)
	safe_access.set_stat_int(p .. "H4LOOT_PAINT_V", (CayoConfig.paint ~= 0) and CayoConfig.val_art or 0)
	safe_access.set_stat_int(p .. "H4CNF_UNIFORM", -1)
	safe_access.set_stat_int(p .. "H4CNF_GRAPPEL", -1)
	safe_access.set_stat_int(p .. "H4CNF_TROJAN", 5)
	safe_access.set_stat_int(p .. "H4CNF_WEP_DISRP", 3)
	safe_access.set_stat_int(p .. "H4CNF_ARM_DISRP", 3)
	safe_access.set_stat_int(p .. "H4CNF_HEL_DISRP", 3)
	safe_access.set_local_int("heist_island_planning", 1570, 2)
	if notify then
		notify.push("Cayo Perico", "Preps applied", 2000)
	end
end

-- Apply Cayo Cuts
local function hp_get_cayo_max_payout_cut()
	local p = GetMP()
	local target = safe_access.get_stat_int(p .. "H4CNF_TARGET", 0)
	local progress = safe_access.get_stat_int(p .. "H4_PROGRESS", 0)
	local difficulty = ((progress & 4096) ~= 0) and 2 or 1

	local payouts = {
		[0] = { 630000, 693000 }, -- Tequila
		[1] = { 700000, 770000 }, -- Ruby Necklace
		[2] = { 770000, 847000 }, -- Bearer Bonds
		[3] = { 1300000, 1430000 }, -- Pink Diamond
		[4] = { 1100000, 1210000 }, -- Madrazo Files
		[5] = { 1900000, 2090000 }, -- Panther Statue
	}

	local payout_by_target = payouts[target]
	if not payout_by_target then
		return 100
	end

	local payout = payout_by_target[difficulty] or payout_by_target[1]
	local max_payout = SAFE_PAYOUT_TARGETS.cayo
	local initial_cut = math.floor(max_payout / (payout / 100))
	local cut = initial_cut
	local final_payout = math.floor(payout * (cut / 100))
	local difference = 1000
	local found_cut = false

	while not found_cut do
		local pavel_fee = math.floor(final_payout * 0.02)
		local fencing_fee = math.floor(final_payout * 0.10)
		local fee_payout = final_payout - (pavel_fee + fencing_fee)

		if fee_payout >= (max_payout - difference) and fee_payout <= max_payout then
			found_cut = true
		else
			cut = cut + 1
			final_payout = math.floor(payout * (cut / 100))

			if cut > 500 then
				cut = initial_cut
				final_payout = math.floor(payout * (cut / 100))
				difference = difference + 1000
			end
		end
	end

	return hp_clamp_cut_percent(cut), target, difficulty
end

local function cayo_refresh_max_payout(force_update, apply_now)
	if not cayo_flags.max_payout_enabled then
		cayo_max_payout_cache.target = nil
		cayo_max_payout_cache.difficulty = nil
		cayo_max_payout_cache.cut = nil
		cayo_sync_crew_cut_ui_lock()
		return false
	end

	cayo_set_remove_crew_cuts(false, true)
	cayo_sync_crew_cut_ui_lock()

	local cut, target, difficulty = hp_get_cayo_max_payout_cut()
	if not cut then
		return false
	end

	local changed = force_update
		or cayo_max_payout_cache.target ~= target
		or cayo_max_payout_cache.difficulty ~= difficulty
		or cayo_max_payout_cache.cut ~= cut

	if changed then
		CayoCutsValues.host = cut
		CayoCutsValues.player2 = cut
		CayoCutsValues.player3 = cut
		CayoCutsValues.player4 = cut
		if cayo_refs.host_slider then
			cayo_refs.host_slider.value = cut
		end
		if cayo_refs.p2_slider then
			cayo_refs.p2_slider.value = cut
		end
		if cayo_refs.p3_slider then
			cayo_refs.p3_slider.value = cut
		end
		if cayo_refs.p4_slider then
			cayo_refs.p4_slider.value = cut
		end

		if apply_now then
			cayo_apply_cuts()
		end

		cayo_max_payout_cache.target = target
		cayo_max_payout_cache.difficulty = difficulty
		cayo_max_payout_cache.cut = cut
	end

	return changed
end

local function cayo_set_max_payout(enable, silent)
	local enabled = enable and true or false
	local changed = (cayo_flags.max_payout_enabled ~= enabled)
	cayo_flags.max_payout_enabled = enabled
	if cayo_refs.max_payout_toggle then
		cayo_refs.max_payout_toggle.state = enabled
	end

	if enabled then
		cayo_set_remove_crew_cuts(false, true)
		cayo_refresh_max_payout(true, false)
	end
	cayo_sync_crew_cut_ui_lock()

	if changed and not silent and notify then
		notify.push("Cayo Perico Cuts", enabled and "Max payout enabled" or "Max payout disabled", 2000)
	end
end

cayo_apply_cuts = function()
	safe_access.set_global_int(CayoGlobals.Host, CayoCutsValues.host)
	safe_access.set_global_int(CayoGlobals.P2, CayoCutsValues.player2)
	safe_access.set_global_int(CayoGlobals.P3, CayoCutsValues.player3)
	safe_access.set_global_int(CayoGlobals.P4, CayoCutsValues.player4)
	if notify then
		notify.push("Cayo Perico", "Cuts applied", 2000)
	end
end

-- Force Ready
local function cayo_force_ready()
	return run_guarded_job("cayo_force_ready", function()
		safe_access.force_host("fm_mission_controller_2020")
		util.yield(1000)

		safe_access.set_global_int(CayoReady.PLAYER2, 1)
		safe_access.set_global_int(CayoReady.PLAYER3, 1) -- READY_STATE_HEIST = 1
		safe_access.set_global_int(CayoReady.PLAYER4, 1) -- READY_STATE_HEIST = 1

		if notify then
			notify.push("Cayo Perico", "All players ready", 2000)
		end
	end, function()
		if notify then
			notify.push("Cayo Perico", "Force ready already running", 1500)
		end
	end)
end

-- Cayo Tools functions
local function cayo_unlock_all_poi()
	local p = GetMP()
	-- Unlock all POIs (set to -1 to unlock all)
	safe_access.set_stat_int(p .. "H4CNF_BS_GEN", -1)
	-- Unlock all entry points
	safe_access.set_stat_int(p .. "H4CNF_BS_ENTR", 63)
	-- Unlock all abilities/equipment
	safe_access.set_stat_int(p .. "H4CNF_BS_ABIL", 63)
	safe_access.set_stat_int(p .. "H4CNF_APPROACH", -1)
	safe_access.set_stat_int(p .. "H4_PLAYTHROUGH_STATUS", 10)
	-- Reload planning board if script is running
	if safe_access.is_script_running("heist_island_planning") then
		safe_access.set_local_int("heist_island_planning", 1570, 2)
	end
	if notify then
		notify.push("Cayo Tools", "All POI unlocked", 2000)
	end
end

local function cayo_reset_preps()
	local p = GetMP()
	safe_access.set_stat_int(p .. "H4_PROGRESS", 0)
	safe_access.set_stat_int(p .. "H4_MISSIONS", 0)
	safe_access.set_stat_int(p .. "H4CNF_APPROACH", 0)
	safe_access.set_stat_int(p .. "H4CNF_TARGET", -1)
	safe_access.set_stat_int(p .. "H4CNF_BS_GEN", 0)
	safe_access.set_stat_int(p .. "H4CNF_BS_ENTR", 0)
	safe_access.set_stat_int(p .. "H4CNF_BS_ABIL", 0)
	safe_access.set_stat_int(p .. "H4_PLAYTHROUGH_STATUS", 0)
	safe_access.set_local_int("heist_island_planning", 1570, 2)
	if notify then
		notify.push("Cayo Tools", "Preps reset", 2000)
	end
end

local function cayo_instant_voltlab_hack()
	if not safe_access.is_script_running("fm_content_island_heist") then
		if notify then
			notify.push("Cayo Tools", "Mission not running", 2000)
		end
		return
	end
	safe_access.set_local_int("fm_content_island_heist", 10166 + 24, 5)
	if notify then
		notify.push("Cayo Tools", "Voltlab hack completed", 2000)
	end
end

local function cayo_instant_password_hack()
	safe_access.set_local_int("fm_mission_controller_2020", 26486, 5)
	if notify then
		notify.push("Cayo Tools", "Password hack completed", 2000)
	end
end

local function cayo_bypass_plasma_cutter()
	safe_access.set_local_float("fm_mission_controller_2020", 32589 + 3, 100.0)
	if notify then
		notify.push("Cayo Tools", "Plasma cutter bypassed", 2000)
	end
end

local function cayo_bypass_drainage_pipe()
	safe_access.set_local_int("fm_mission_controller_2020", 31349, 6)
	if notify then
		notify.push("Cayo Tools", "Drainage pipe bypassed", 2000)
	end
end

local function cayo_reload_planning_screen()
	safe_access.set_local_int("heist_island_planning", 1570, 2)
	if notify then
		notify.push("Cayo Tools", "Planning screen reloaded", 2000)
	end
end

local function cayo_remove_cooldown()
	local p = GetMP()
	safe_access.set_stat_int(p .. "H4_TARGET_POSIX", 1659643454)
	safe_access.set_stat_int(p .. "H4_COOLDOWN", 0)
	safe_access.set_stat_int(p .. "H4_COOLDOWN_HARD", 0)
	if notify then
		notify.push("Cayo Tools", "Solo cooldown removed", 2000)
	end
end

local function cayo_remove_cooldown_team()
	local p = GetMP()
	safe_access.set_stat_int(p .. "H4_TARGET_POSIX", 1659429119)
	safe_access.set_stat_int(p .. "H4_COOLDOWN", 0)
	safe_access.set_stat_int(p .. "H4_COOLDOWN_HARD", 0)
	if notify then
		notify.push("Cayo Tools", "Team cooldown removed", 2000)
	end
end

local function cayo_instant_finish()
	run_guarded_job("cayo_instant_finish", function()
		if safe_access.force_host("fm_mission_controller_2020") then
			util.yield(1000)
			safe_access.set_local_int("fm_mission_controller_2020", 56223, 9)
			safe_access.set_local_int("fm_mission_controller_2020", 58000, 50)
			if notify then
				notify.push("Cayo Tools", "Instant finish triggered", 2000)
			end
		else
			if notify then
				notify.push("Cayo Tools", "Could not force host", 2000)
			end
		end
	end, function()
		if notify then
			notify.push("Cayo Tools", "Instant finish already running", 1500)
		end
	end)
end

local teleport_in_progress = false

local function cayo_teleport_residence()
	-- Residence/Mansion coordinates (Cayo Perico)
	-- Coordinates: 5010, -5753, 30
	run_coords_teleport("Cayo Teleport", "Teleported to Residence", 5010.0, -5753.0, 30.0)
end

local function cayo_teleport_main_target()
	-- Main target location (inside compound vault, Cayo Perico)
	-- Coordinates: 5006, -5754, 16
	run_coords_teleport("Cayo Teleport", "Teleported to Main Target", 5006.0, -5754.0, 16.0)
end

local function cayo_teleport_gate()
	-- Gate entrance coordinates (Cayo Perico compound main gate)
	-- Coordinates: 4992, -5720, 21
	run_coords_teleport("Cayo Teleport", "Teleported to Gate", 4992.0, -5720.0, 21.0)
end

local function cayo_teleport_center()
	-- Center coordinates (Cayo Perico)
	-- Coordinates: 4971, -5136, 4
	run_coords_teleport("Cayo Teleport", "Teleported to Center", 4971.0, -5136.0, 4.0)
end

local function cayo_teleport_loot1()
	-- Loot #1 coordinates (Cayo Perico - In Residence)
	-- Coordinates: 5002, -5751, 16
	run_coords_teleport("Cayo Teleport", "Teleported to Loot #1", 5002.0, -5751.0, 16.0)
end

local function cayo_teleport_loot2()
	-- Loot #2 coordinates (Cayo Perico - In Residence)
	-- Coordinates: 5031, -5737, 19
	run_coords_teleport("Cayo Teleport", "Teleported to Loot #2", 5031.0, -5737.0, 19.0)
end

local function cayo_teleport_loot3()
	-- Loot #3 coordinates (Cayo Perico - In Residence)
	-- Coordinates: 5081, -5756, 17
	run_coords_teleport("Cayo Teleport", "Teleported to Loot #3", 5081.0, -5756.0, 17.0)
end

local function cayo_teleport_gate_outside()
	-- Gate coordinates (Cayo Perico - Outside Residence)
	-- Coordinates: 4977, -5706, 20
	run_coords_teleport("Cayo Teleport", "Teleported to Gate", 4977.0, -5706.0, 20.0)
end

local function cayo_teleport_airport()
	-- Airport coordinates (Cayo Perico - Outside Residence)
	-- Coordinates: 4443, -4510, 5
	run_coords_teleport("Cayo Teleport", "Teleported to Airport", 4443.0, -4510.0, 5.0)
end

local function cayo_teleport_escape()
	-- Escape coordinates (Cayo Perico - Outside Residence)
	-- Coordinates: 3698, -6133, -5
	run_coords_teleport("Cayo Teleport", "Teleported to Escape", 3698.0, -6133.0, -5.0)
end

local function cayo_teleport_kosatka()
	if teleport_in_progress then
		if notify then
			notify.push("Cayo Teleport", "Teleport already running", 1200)
		end
		return false
	end
	if not try_begin_teleport_cooldown() then
		if notify then
			notify.push("Cayo Teleport", "Teleport on cooldown", 1000)
		end
		return false
	end

	local BLIP_SPRITES_KOSATKA = 760
	local BLIP_SPRITES_HEIST = 428
	local TELEPORT_COORDS_MAZEBANK = { x = -75.146, y = -818.687, z = 326.175, heading = 357.531 }
	local TELEPORT_COORDS_KOSATKA_INTERIOR = { x = 1561.087, y = 386.610, z = -49.685, heading = 179.884 }
	local KOSATKA_REQUEST_GLOBALS = {
		2733138 + 613, -- EE
		2733002 + 613, -- Legacy
	}

	local function is_kosatka_blip_exists()
		local blip_result = invoker.call(0x1BEDE233E6CD2A1F, BLIP_SPRITES_KOSATKA) -- GET_FIRST_BLIP_INFO_ID
		return blip_result and blip_result.int and blip_result.int ~= 0
	end

	local function request_kosatka_spawn()
		for i = 1, #KOSATKA_REQUEST_GLOBALS do
			safe_access.set_global_int(KOSATKA_REQUEST_GLOBALS[i], 1)
		end
	end

	teleport_in_progress = true
	local me = players.me()
	if not me then
		teleport_in_progress = false
		if notify then
			notify.push("Cayo Teleport", "Player not found", 2000)
		end
		return false
	end

	local ped = me.ped
	-- Interior teleport should always use ped; vehicle teleport can leave you outside/desynced.
	local entity = ped

	local ok, err = pcall(function()
		invoker.call(0x428CA6DBD1094446, entity, true) -- FREEZE_ENTITY_POSITION

		if me.in_interior then
			invoker.call(
				0x239A3351AC1DA385,
				entity,
				TELEPORT_COORDS_MAZEBANK.x,
				TELEPORT_COORDS_MAZEBANK.y,
				TELEPORT_COORDS_MAZEBANK.z,
				false,
				false,
				false
			) -- SET_ENTITY_COORDS_NO_OFFSET
			invoker.call(0x8E2530AA8ADA980E, entity, TELEPORT_COORDS_MAZEBANK.heading) -- SET_ENTITY_HEADING
			util.yield(800)
		end

		if not is_kosatka_blip_exists() then
			if notify then
				notify.push("Cayo Teleport", "Kosatka not spawned, requesting...", 2000)
			end
			while not is_kosatka_blip_exists() do
				request_kosatka_spawn()
				util.yield()
			end
			if notify then
				notify.push("Cayo Teleport", "Kosatka spawned successfully", 2000)
			end
		end

		invoker.call(
			0x239A3351AC1DA385,
			entity,
			TELEPORT_COORDS_KOSATKA_INTERIOR.x,
			TELEPORT_COORDS_KOSATKA_INTERIOR.y,
			TELEPORT_COORDS_KOSATKA_INTERIOR.z,
			false,
			false,
			false
		) -- SET_ENTITY_COORDS_NO_OFFSET
		invoker.call(0x8E2530AA8ADA980E, entity, TELEPORT_COORDS_KOSATKA_INTERIOR.heading) -- SET_ENTITY_HEADING

		local blip_check = 0
		local attempts = 0
		while blip_check == 0 and attempts < 120 do
			local check_result = invoker.call(0xD484BF71050CA1EE, BLIP_SPRITES_HEIST) -- GET_CLOSEST_BLIP_INFO_ID
			if check_result and check_result.int and check_result.int ~= 0 then
				blip_check = check_result.int
			else
				util.yield()
				attempts = attempts + 1
			end
		end

		if notify then
			notify.push("Cayo Teleport", "Teleported to Kosatka interior", 2000)
		end

		util.yield(500)
		invoker.call(0x428CA6DBD1094446, entity, false) -- FREEZE_ENTITY_POSITION
	end)

	teleport_in_progress = false
	if not ok then
		pcall(function()
			invoker.call(0x428CA6DBD1094446, entity, false) -- FREEZE_ENTITY_POSITION
		end)
		if notify then
			notify.push("Cayo Teleport", "Kosatka teleport failed: " .. tostring(err), 3000)
		end
		return false
	end

	return true
end

cayo_callbacks.set_womans_bag = cayo_set_womans_bag
cayo_callbacks.set_remove_crew_cuts = cayo_set_remove_crew_cuts
cayo_callbacks.set_max_payout = cayo_set_max_payout
cayo_callbacks.refresh_max_payout = cayo_refresh_max_payout

local cayo_logic = {
	CayoConfig = CayoConfig,
	CayoPrepOptions = CayoPrepOptions,
	CayoCutsValues = CayoCutsValues,
	cayo_flags = cayo_flags,
	cayo_refs = cayo_refs,
	cayo_callbacks = cayo_callbacks,
	cayo_set_womans_bag = cayo_set_womans_bag,
	cayo_set_remove_crew_cuts = cayo_set_remove_crew_cuts,
	cayo_set_max_payout = cayo_set_max_payout,
	cayo_refresh_max_payout = cayo_refresh_max_payout,
	cayo_enforce_heist_toggles = cayo_enforce_heist_toggles,
	cayo_apply_preps = cayo_apply_preps,
	cayo_apply_cuts = cayo_apply_cuts,
	cayo_force_ready = cayo_force_ready,
	cayo_unlock_all_poi = cayo_unlock_all_poi,
	cayo_reset_preps = cayo_reset_preps,
	cayo_instant_voltlab_hack = cayo_instant_voltlab_hack,
	cayo_instant_password_hack = cayo_instant_password_hack,
	cayo_bypass_plasma_cutter = cayo_bypass_plasma_cutter,
	cayo_bypass_drainage_pipe = cayo_bypass_drainage_pipe,
	cayo_reload_planning_screen = cayo_reload_planning_screen,
	cayo_remove_cooldown = cayo_remove_cooldown,
	cayo_remove_cooldown_team = cayo_remove_cooldown_team,
	cayo_instant_finish = cayo_instant_finish,
	cayo_teleport_residence = cayo_teleport_residence,
	cayo_teleport_main_target = cayo_teleport_main_target,
	cayo_teleport_gate = cayo_teleport_gate,
	cayo_teleport_center = cayo_teleport_center,
	cayo_teleport_loot1 = cayo_teleport_loot1,
	cayo_teleport_loot2 = cayo_teleport_loot2,
	cayo_teleport_loot3 = cayo_teleport_loot3,
	cayo_teleport_gate_outside = cayo_teleport_gate_outside,
	cayo_teleport_airport = cayo_teleport_airport,
	cayo_teleport_escape = cayo_teleport_escape,
	cayo_teleport_kosatka = cayo_teleport_kosatka,
	hp_get_cayo_max_payout_cut = hp_get_cayo_max_payout_cut,
}

return cayo_logic
