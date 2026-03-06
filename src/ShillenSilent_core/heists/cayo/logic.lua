-- ---------------------------------------------------------

local core = require("ShillenSilent_core.core.bootstrap")
local presets = require("ShillenSilent_core.shared.presets_and_shared")
local heist_state = require("ShillenSilent_core.shared.heist_state")
local coords_teleport = require("ShillenSilent_core.shared.coords_teleport")
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
	if changed and not silent and notify then
		notify.push("Cayo Perico", enabled and "Crew cuts removed" or "Crew cuts restored", 2000)
	end
end

local function cayo_enforce_heist_toggles()
	if cayo_flags.womans_bag_enabled then
		hp_set_tunable_int("HEIST_BAG_MAX_CAPACITY", 99999)
	end
	if cayo_flags.remove_crew_cuts_enabled then
		hp_set_tunable_float("IH_DEDUCTION_PAVEL_CUT", 0.0)
		hp_set_tunable_float("IH_DEDUCTION_FENCING_FEE", 0.0)
	end
end

-- Apply Cayo Preps
local function cayo_apply_preps()
	local p = GetMP()

	if CayoConfig.unlock_all_poi then
		account.stats(p .. "H4CNF_BS_GEN").int32 = -1
		account.stats(p .. "H4CNF_BS_ENTR").int32 = 63
		account.stats(p .. "H4CNF_BS_ABIL").int32 = 63
		account.stats(p .. "H4CNF_APPROACH").int32 = -1
		account.stats(p .. "H4_PLAYTHROUGH_STATUS").int32 = 10
	end

	account.stats(p .. "H4_PROGRESS").int32 = CayoConfig.diff
	account.stats(p .. "H4_MISSIONS").int32 = CayoConfig.app
	account.stats(p .. "H4CNF_WEAPONS").int32 = CayoConfig.wep
	account.stats(p .. "H4CNF_TARGET").int32 = CayoConfig.tgt

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

		account.stats(p .. "H4LOOT_" .. loot .. "_C").int32 = compound_value
		account.stats(p .. "H4LOOT_" .. loot .. "_C_SCOPED").int32 = compound_value
		account.stats(p .. "H4LOOT_" .. loot .. "_I").int32 = island_value
		account.stats(p .. "H4LOOT_" .. loot .. "_I_SCOPED").int32 = island_value
		account.stats(p .. "H4LOOT_" .. loot .. "_V").int32 = value_stat
	end

	account.stats(p .. "H4LOOT_PAINT").int32 = CayoConfig.paint
	account.stats(p .. "H4LOOT_PAINT_SCOPED").int32 = CayoConfig.paint
	account.stats(p .. "H4LOOT_PAINT_V").int32 = (CayoConfig.paint ~= 0) and CayoConfig.val_art or 0
	account.stats(p .. "H4CNF_UNIFORM").int32 = -1
	account.stats(p .. "H4CNF_GRAPPEL").int32 = -1
	account.stats(p .. "H4CNF_TROJAN").int32 = 5
	account.stats(p .. "H4CNF_WEP_DISRP").int32 = 3
	account.stats(p .. "H4CNF_ARM_DISRP").int32 = 3
	account.stats(p .. "H4CNF_HEL_DISRP").int32 = 3
	script.locals("heist_island_planning", 1570).int32 = 2
	if notify then
		notify.push("Cayo Perico", "Preps applied", 2000)
	end
end

-- Apply Cayo Cuts
local function hp_get_cayo_max_payout_cut()
	local p = GetMP()
	local target = account.stats(p .. "H4CNF_TARGET").int32 or 0
	local difficulty = (account.stats(p .. "H4_PROGRESS").int32 == 131055) and 2 or 1

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
	local difference = 1000
	local tries = 0

	while tries < 10000 do
		local final_payout = math.floor(payout * (cut / 100))
		local pavel_fee = math.floor(final_payout * 0.02)
		local fencing_fee = math.floor(final_payout * 0.10)
		local fee_payout = final_payout - (pavel_fee + fencing_fee)

		if fee_payout >= (max_payout - difference) and fee_payout <= max_payout then
			break
		end

		cut = cut + 1
		if cut > 500 then
			cut = initial_cut
			difference = difference + 1000
		end
		tries = tries + 1
	end

	return hp_clamp_cut_percent(cut)
end

local function cayo_apply_cuts()
	script.globals(CayoGlobals.Host).int32 = CayoCutsValues.host
	script.globals(CayoGlobals.P2).int32 = CayoCutsValues.player2
	script.globals(CayoGlobals.P3).int32 = CayoCutsValues.player3
	script.globals(CayoGlobals.P4).int32 = CayoCutsValues.player4
	if notify then
		notify.push("Cayo Perico", "Cuts applied", 2000)
	end
end

-- Force Ready
local function cayo_force_ready()
	return run_guarded_job("cayo_force_ready", function()
		if script and script.force_host then
			script.force_host("fm_mission_controller_2020")
		end
		util.yield(1000)

		script.globals(CayoReady.PLAYER2).int32 = 1
		script.globals(CayoReady.PLAYER3).int32 = 1 -- READY_STATE_HEIST = 1
		script.globals(CayoReady.PLAYER4).int32 = 1 -- READY_STATE_HEIST = 1

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
	account.stats(p .. "H4CNF_BS_GEN").int32 = -1
	-- Unlock all entry points
	account.stats(p .. "H4CNF_BS_ENTR").int32 = 63
	-- Unlock all abilities/equipment
	account.stats(p .. "H4CNF_BS_ABIL").int32 = 63
	account.stats(p .. "H4CNF_APPROACH").int32 = -1
	account.stats(p .. "H4_PLAYTHROUGH_STATUS").int32 = 10
	-- Reload planning board if script is running
	if script.running("heist_island_planning") then
		script.locals("heist_island_planning", 1570).int32 = 2
	end
	if notify then
		notify.push("Cayo Tools", "All POI unlocked", 2000)
	end
end

local function cayo_reset_preps()
	local p = GetMP()
	account.stats(p .. "H4_PROGRESS").int32 = 0
	account.stats(p .. "H4_MISSIONS").int32 = 0
	account.stats(p .. "H4CNF_APPROACH").int32 = 0
	account.stats(p .. "H4CNF_TARGET").int32 = -1
	account.stats(p .. "H4CNF_BS_GEN").int32 = 0
	account.stats(p .. "H4CNF_BS_ENTR").int32 = 0
	account.stats(p .. "H4CNF_BS_ABIL").int32 = 0
	account.stats(p .. "H4_PLAYTHROUGH_STATUS").int32 = 0
	script.locals("heist_island_planning", 1570).int32 = 2
	if notify then
		notify.push("Cayo Tools", "Preps reset", 2000)
	end
end

local function cayo_instant_voltlab_hack()
	if not script.running("fm_content_island_heist") then
		if notify then
			notify.push("Cayo Tools", "Mission not running", 2000)
		end
		return
	end
	script.locals("fm_content_island_heist", 10166 + 24).int32 = 5
	if notify then
		notify.push("Cayo Tools", "Voltlab hack completed", 2000)
	end
end

local function cayo_instant_password_hack()
	script.locals("fm_mission_controller_2020", 26486).int32 = 5
	if notify then
		notify.push("Cayo Tools", "Password hack completed", 2000)
	end
end

local function cayo_bypass_plasma_cutter()
	script.locals("fm_mission_controller_2020", 32589 + 3).float = 100.0
	if notify then
		notify.push("Cayo Tools", "Plasma cutter bypassed", 2000)
	end
end

local function cayo_bypass_drainage_pipe()
	script.locals("fm_mission_controller_2020", 31349).int32 = 6
	if notify then
		notify.push("Cayo Tools", "Drainage pipe bypassed", 2000)
	end
end

local function cayo_reload_planning_screen()
	script.locals("heist_island_planning", 1570).int32 = 2
	if notify then
		notify.push("Cayo Tools", "Planning screen reloaded", 2000)
	end
end

local function cayo_remove_cooldown()
	local p = GetMP()
	account.stats(p .. "H4_TARGET_POSIX").int32 = 1659643454
	account.stats(p .. "H4_COOLDOWN").int32 = 0
	account.stats(p .. "H4_COOLDOWN_HARD").int32 = 0
	if notify then
		notify.push("Cayo Tools", "Solo cooldown removed", 2000)
	end
end

local function cayo_remove_cooldown_team()
	local p = GetMP()
	account.stats(p .. "H4_TARGET_POSIX").int32 = 1659429119
	account.stats(p .. "H4_COOLDOWN").int32 = 0
	account.stats(p .. "H4_COOLDOWN_HARD").int32 = 0
	if notify then
		notify.push("Cayo Tools", "Team cooldown removed", 2000)
	end
end

local function cayo_instant_finish()
	run_guarded_job("cayo_instant_finish", function()
		if script.force_host("fm_mission_controller_2020") then
			util.yield(1000)
			script.locals("fm_mission_controller_2020", 56223).int32 = 9
			script.locals("fm_mission_controller_2020", 58000).int32 = 50
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

	local MAZE_RELAY = { x = -75.146, y = -818.687, z = 326.175, heading = 357.531 }
	local KOSATKA_INTERIOR = { x = 1561.087, y = 386.610, z = -49.685, heading = 179.884 }
	local BLIP_SPRITE_HEIST = 428
	local LOOP_TIMEOUT_MS = 30000
	local LOOP_STEP_MS = 100
	local MAX_WAIT_ATTEMPTS = math.floor(LOOP_TIMEOUT_MS / LOOP_STEP_MS)
	local KOSATKA_REQUEST_GLOBALS = {
		2733138 + 613, -- EE
		2733002 + 613, -- Legacy
	}

	local function get_local_player_id()
		if players and players.user then
			local id = players.user()
			if type(id) == "number" and id >= 0 then
				return id
			end
		end
		local me = players and players.me and players.me() or nil
		if me and type(me.id) == "number" and me.id >= 0 then
			return me.id
		end
		return 0
	end

	local function player_owns_kosatka()
		local p = GetMP()
		return (account.stats(p .. "IH_SUB_OWNED").int32 or 0) ~= 0
	end

	local function request_kosatka_spawn()
		for i = 1, #KOSATKA_REQUEST_GLOBALS do
			script.globals(KOSATKA_REQUEST_GLOBALS[i]).int32 = 1
		end
	end

	local function is_kosatka_in_ocean()
		local player_id = get_local_player_id()
		local status_ee = script.globals(2658294 + 1 + (player_id * 468) + 325 + 4).int32 or 0
		if (status_ee & (1 << 31)) ~= 0 then
			return true
		end
		local status_legacy = script.globals(2658291 + 1 + (player_id * 468) + 325 + 4).int32 or 0
		return (status_legacy & (1 << 31)) ~= 0
	end

	local function has_heist_blip()
		local result = invoker.call(0xD484BF71050CA1EE, BLIP_SPRITE_HEIST) -- GET_CLOSEST_BLIP_INFO_ID
		return result and result.int and result.int ~= 0
	end

	if not player_owns_kosatka() then
		if notify then
			notify.push("Cayo Teleport", "You don't own a Kosatka", 2200)
		end
		return false
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
	local entity = ped

	local function set_coords(coords)
		invoker.call(0x239A3351AC1DA385, entity, coords.x, coords.y, coords.z, false, false, false) -- SET_ENTITY_COORDS_NO_OFFSET
	end

	local function set_heading(heading)
		invoker.call(0x8E2530AA8ADA980E, entity, heading) -- SET_ENTITY_HEADING
	end

	local function move_to_maze_bank()
		set_coords(MAZE_RELAY)
		set_heading(MAZE_RELAY.heading)
	end

	local ok, err = pcall(function()
		invoker.call(0x428CA6DBD1094446, entity, true) -- FREEZE_ENTITY_POSITION
		move_to_maze_bank()
		util.yield(700)

		local announced_request = false
		local spawned = is_kosatka_in_ocean()
		if not spawned then
			for _ = 1, MAX_WAIT_ATTEMPTS do
				if is_kosatka_in_ocean() then
					spawned = true
					break
				end
				request_kosatka_spawn()
				if not announced_request and notify then
					notify.push("Cayo Teleport", "Requesting Kosatka...", 1200)
					announced_request = true
				end
				util.yield(LOOP_STEP_MS)
			end
		end

		if not spawned then
			move_to_maze_bank()
			if notify then
				notify.push("Cayo Teleport", "Kosatka not ready after 30s. Stayed at Maze Bank.", 3000)
			end
			invoker.call(0x428CA6DBD1094446, entity, false) -- FREEZE_ENTITY_POSITION
			return
		end

		set_coords(KOSATKA_INTERIOR)
		set_heading(KOSATKA_INTERIOR.heading)

		local interior_loaded = false
		for _ = 1, MAX_WAIT_ATTEMPTS do
			if has_heist_blip() then
				interior_loaded = true
				break
			end
			util.yield(LOOP_STEP_MS)
		end

		if interior_loaded then
			if notify then
				notify.push("Cayo Teleport", "Teleported to Kosatka interior", 2000)
			end
		else
			move_to_maze_bank()
			if notify then
				notify.push("Cayo Teleport", "Kosatka interior not ready after 30s. Stayed at Maze Bank.", 3000)
			end
		end

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

local cayo_logic = {
	CayoConfig = CayoConfig,
	CayoPrepOptions = CayoPrepOptions,
	CayoCutsValues = CayoCutsValues,
	cayo_flags = cayo_flags,
	cayo_refs = cayo_refs,
	cayo_callbacks = cayo_callbacks,
	cayo_set_womans_bag = cayo_set_womans_bag,
	cayo_set_remove_crew_cuts = cayo_set_remove_crew_cuts,
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
