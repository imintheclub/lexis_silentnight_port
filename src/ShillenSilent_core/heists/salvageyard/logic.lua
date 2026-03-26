local core = require("ShillenSilent_core.core.bootstrap")
local presets = require("ShillenSilent_core.shared.presets_and_shared")
local heist_state = require("ShillenSilent_core.shared.heist_state")
local coords_teleport = require("ShillenSilent_core.shared.coords_teleport")
local blip_teleport = require("ShillenSilent_core.shared.blip_teleport")

local run_guarded_job = core.run_guarded_job
local run_coords_teleport = coords_teleport.run_coords_teleport
local teleport_to_blip_with_job = blip_teleport.teleport_to_blip_with_job
local GetMP = presets.GetMP

local salvageyard_state = heist_state.salvageyard
local SalvagePrepOptions = salvageyard_state.prep_options
local SalvageConfig = salvageyard_state.config
local salvage_flags = salvageyard_state.flags
local salvage_refs = salvageyard_state.refs
local salvage_callbacks = salvageyard_state.callbacks

local SALVAGE_BLIP_ENTRANCE = 867
local SALVAGE_BOARD_COORDS = { x = 1074.720, y = -2275.502, z = -48.999, heading = 84.481 }
local SALVAGE_SELL_COORDS = { x = 1169.749, y = -2973.535, z = 5.902, heading = 271.204 }
local SALVAGE_INTERIOR_SCRIPT = "am_mp_salvage_yard"

local SALVAGE_STATS = {
	GEN_BS = "SALV23_GEN_BS",
	SCOPE_BS = "SALV23_SCOPE_BS",
	FM_PROG = "SALV23_FM_PROG",
	INST_PROG = "SALV23_INST_PROG",
	WEEK_SYNC = "SALV23_WEEK_SYNC",
	SAFE_CASH_VALUE = "SALVAGE_SAFE_CASH_VALUE",
}

local SALVAGE_GLOBALS = {
	SAFE_COLLECT_BOOL = 2708859,
}

local SALVAGE_TUNABLES = {
	SETUP_PRICE = 71522671,
	CLAIM_PRICE_STANDARD = "SALV23_VEHICLE_CLAIM_PRICE",
	CLAIM_PRICE_DISCOUNTED = "SALV23_VEHICLE_CLAIM_PRICE_FORGERY_DISCOUNT",
	WEEKLY_COOLDOWN = "SALV23_VEH_ROBBERY_WEEK_ID",
	SALVAGE_MULTIPLIER = 1601153005,
}

local SALVAGE_DEFAULTS = {
	setup_price = 20000,
	claim_price_standard = 20000,
	claim_price_discounted = 10000,
}

local SALVAGE_SLOT_TUNABLES = {
	[1] = {
		robbery = 1152433341,
		vehicle = -1012732012,
		keep = -1700733442,
		value = -1699398139,
		status_stat = "SALV23_VEHROB_STATUS0",
	},
	[2] = {
		robbery = 852564222,
		vehicle = 1366330161,
		keep = -1547046832,
		value = -1997104504,
		status_stat = "SALV23_VEHROB_STATUS1",
	},
	[3] = {
		robbery = 552662330,
		vehicle = 1806057372,
		keep = 1830093543,
		value = -1704051341,
		status_stat = "SALV23_VEHROB_STATUS2",
	},
}

local SALVAGE_SCRIPTS = {
	PLANNING = "vehrob_planning",
	MISSIONS = {
		{
			id = "cargo_ship",
			script = "fm_content_vehrob_cargo_ship",
			offsets = { { step1 = 7187 + 1, step2 = 7332 + 1249 }, { step1 = 7185 + 1, step2 = 7330 + 1249 } },
		},
		{
			id = "police",
			script = "fm_content_vehrob_police",
			offsets = { { step1 = 9013 + 1, step2 = 9146 + 1305 }, { step1 = 9011 + 1, step2 = 9144 + 1305 } },
		},
		{
			id = "arena",
			script = "fm_content_vehrob_arena",
			offsets = { { step1 = 7914 + 1, step2 = 8034 + 1314 }, { step1 = 7912 + 1, step2 = 8032 + 1314 } },
		},
		{
			id = "casino_prize",
			script = "fm_content_vehrob_casino_prize",
			offsets = { { step1 = 9193 + 1, step2 = 9330 + 1258 }, { step1 = 9191 + 1, step2 = 9328 + 1258 } },
		},
		{
			id = "submarine",
			script = "fm_content_vehrob_submarine",
			offsets = { { step1 = 6220 + 1, step2 = 6358 + 1159 }, { step1 = 6218 + 1, step2 = 6356 + 1159 } },
		},
	},
	PLANNING_FORCE_OFFSETS = { 418, 416 },
	PLANNING_RELOAD_OFFSETS = { 537, 535 },
}

local function is_script_running(script_name)
	local ok, result = pcall(script.running, script_name)
	return ok and result and true or false
end

local function set_local_int(script_name, offset, value)
	local ok = pcall(function()
		script.locals(script_name, offset).int32 = value
	end)
	return ok
end

local function get_local_int(script_name, offset, fallback)
	local ok, value = pcall(function()
		return script.locals(script_name, offset).int32
	end)
	if ok and value ~= nil then
		return value
	end
	return fallback
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

local function get_stat_int(stat_name, fallback)
	local ok, value = pcall(function()
		local stat = account.stats(stat_name)
		if not stat then
			return nil
		end
		return stat.int32
	end)
	if ok and value ~= nil then
		return value
	end
	return fallback
end

local function set_tunable_int(name, value)
	local ok = pcall(function()
		script.tunables(name).int32 = value
	end)
	return ok
end

local function set_tunable_float(name, value)
	local ok = pcall(function()
		script.tunables(name).float = value
	end)
	return ok
end

local function set_global_bool(offset, value)
	local ok = pcall(function()
		script.globals(offset).bool = value and true or false
	end)
	return ok
end

local function global_bool_supported(offset)
	local ok = pcall(function()
		local _ = script.globals(offset).bool
	end)
	return ok
end

local function salvage_get_slot_config(slot)
	if slot == 1 then
		return SalvageConfig.slot1
	end
	if slot == 2 then
		return SalvageConfig.slot2
	end
	if slot == 3 then
		return SalvageConfig.slot3
	end
	return nil
end

local function salvage_apply_slot_tunables(slot)
	local slot_cfg = salvage_get_slot_config(slot)
	local tunables = SALVAGE_SLOT_TUNABLES[slot]
	if not slot_cfg or not tunables then
		return false
	end

	local robbery = math.floor(tonumber(slot_cfg.robbery) or 0)
	local vehicle = math.floor(tonumber(slot_cfg.vehicle) or 1)
	local mod = math.floor(tonumber(slot_cfg.modification) or 0)
	local keep = math.floor(tonumber(slot_cfg.keep) or 0)

	local ok1 = set_tunable_int(tunables.robbery, robbery)
	local ok2 = set_tunable_int(tunables.vehicle, vehicle + (mod * 100))
	local ok3 = set_tunable_int(tunables.keep, keep)
	return ok1 and ok2 and ok3
end

local function salvage_reload_screen()
	if not is_script_running(SALVAGE_SCRIPTS.PLANNING) then
		if notify then
			notify.push("Salvage Yard", "Planning screen is not active", 2000)
		end
		return false
	end

	local wrote_any = false
	for i = 1, #SALVAGE_SCRIPTS.PLANNING_RELOAD_OFFSETS do
		local offset = SALVAGE_SCRIPTS.PLANNING_RELOAD_OFFSETS[i]
		local ok = set_local_int(SALVAGE_SCRIPTS.PLANNING, offset, 2)
		if offset == 537 then
			salvage_flags.planning_reload_offset_537_supported = ok and true or false
		elseif offset == 535 then
			salvage_flags.planning_reload_offset_535_supported = ok and true or false
		end
		wrote_any = wrote_any or ok
	end

	if notify then
		notify.push("Salvage Yard", wrote_any and "Planning screen reloaded" or "Reload write failed", 2000)
	end
	return wrote_any
end

local function salvage_apply_slot(slot)
	local ok = salvage_apply_slot_tunables(slot)
	local reload_ok = salvage_reload_screen()
	if notify then
		notify.push(
			"Salvage Yard",
			(ok and reload_ok) and ("Slot " .. tostring(slot) .. " changes applied") or "Apply failed",
			2200
		)
	end
	return ok and reload_ok
end

local function salvage_apply_all_changes()
	local ok = true
	for slot = 1, 3 do
		ok = salvage_apply_slot_tunables(slot) and ok
	end
	local reload_ok = salvage_reload_screen()
	if notify then
		notify.push("Salvage Yard", (ok and reload_ok) and "All slot changes applied" or "Apply all failed", 2200)
	end
	return ok and reload_ok
end

local function salvage_make_slot_available(slot)
	local p = GetMP()
	local tunables = SALVAGE_SLOT_TUNABLES[slot]
	if not tunables then
		return false
	end

	local ok = set_stat_int(p .. tunables.status_stat, 0)
	local reload_ok = salvage_reload_screen()
	if notify then
		notify.push(
			"Salvage Yard",
			(ok and reload_ok) and ("Slot " .. tostring(slot) .. " made available") or "Could not make slot available",
			2200
		)
	end
	return ok and reload_ok
end

local function salvage_complete_preps()
	local p = GetMP()
	local ok = true
	ok = set_stat_int(p .. SALVAGE_STATS.GEN_BS, -1) and ok
	ok = set_stat_int(p .. SALVAGE_STATS.SCOPE_BS, -1) and ok
	ok = set_stat_int(p .. SALVAGE_STATS.FM_PROG, -1) and ok
	ok = set_stat_int(p .. SALVAGE_STATS.INST_PROG, -1) and ok

	local reload_ok = salvage_reload_screen()
	if notify then
		notify.push("Salvage Yard", (ok and reload_ok) and "Preps completed" or "Could not complete preps", 2200)
	end
	return ok and reload_ok
end

local function salvage_reset_preps()
	local p = GetMP()
	local ok = true
	ok = set_stat_int(p .. SALVAGE_STATS.GEN_BS, 0) and ok
	ok = set_stat_int(p .. SALVAGE_STATS.SCOPE_BS, 0) and ok
	ok = set_stat_int(p .. SALVAGE_STATS.FM_PROG, 0) and ok
	ok = set_stat_int(p .. SALVAGE_STATS.INST_PROG, 0) and ok

	local reload_ok = salvage_reload_screen()
	if notify then
		notify.push("Salvage Yard", (ok and reload_ok) and "Preps reset" or "Could not reset preps", 2200)
	end
	return ok and reload_ok
end

local function salvage_set_free_setup(enable, silent)
	local enabled = enable and true or false
	salvage_flags.free_setup = enabled
	if salvage_refs.free_setup_toggle then
		salvage_refs.free_setup_toggle.state = enabled
	end

	local setup_price = enabled and 0 or SALVAGE_DEFAULTS.setup_price
	local ok = set_tunable_int(SALVAGE_TUNABLES.SETUP_PRICE, setup_price)
	if notify and not silent then
		local success_message = enabled and "Free Setup enabled" or "Free Setup disabled"
		notify.push("Salvage Yard", ok and success_message or "Free Setup write failed", 2000)
	end
	return ok
end

local function salvage_set_free_claim(enable, silent)
	local enabled = enable and true or false
	salvage_flags.free_claim = enabled
	if salvage_refs.free_claim_toggle then
		salvage_refs.free_claim_toggle.state = enabled
	end

	local standard = enabled and 0 or SALVAGE_DEFAULTS.claim_price_standard
	local discounted = enabled and 0 or SALVAGE_DEFAULTS.claim_price_discounted
	local ok1 = set_tunable_int(SALVAGE_TUNABLES.CLAIM_PRICE_STANDARD, standard)
	local ok2 = set_tunable_int(SALVAGE_TUNABLES.CLAIM_PRICE_DISCOUNTED, discounted)
	if notify and not silent then
		local success_message = enabled and "Free Claim enabled" or "Free Claim disabled"
		notify.push("Salvage Yard", (ok1 and ok2) and success_message or "Free Claim write failed", 2000)
	end
	return ok1 and ok2
end

local function salvage_enforce_heist_toggles()
	if salvage_flags.free_setup then
		set_tunable_int(SALVAGE_TUNABLES.SETUP_PRICE, 0)
	end
	if salvage_flags.free_claim then
		set_tunable_int(SALVAGE_TUNABLES.CLAIM_PRICE_STANDARD, 0)
		set_tunable_int(SALVAGE_TUNABLES.CLAIM_PRICE_DISCOUNTED, 0)
	end
end

local function salvage_teleport_entrance()
	return teleport_to_blip_with_job(
		SALVAGE_BLIP_ENTRANCE,
		"Salvage Yard",
		"Teleported to Entrance",
		"Salvage Yard entrance blip not found",
		{ relay_if_interior = true }
	)
end

local function salvage_teleport_board()
	if not is_script_running(SALVAGE_INTERIOR_SCRIPT) then
		if notify then
			notify.push("Salvage Yard", "You must be inside the Salvage Yard interior", 2200)
		end
		return false
	end

	return run_coords_teleport(
		"Salvage Yard",
		"Teleported to Screen & Board",
		SALVAGE_BOARD_COORDS.x,
		SALVAGE_BOARD_COORDS.y,
		SALVAGE_BOARD_COORDS.z,
		false,
		function()
			local me = players and players.me and players.me() or nil
			local entity = me and ((me.vehicle and me.vehicle ~= 0) and me.vehicle or me.ped) or nil
			if entity and invoker and invoker.call then
				invoker.call(0x8E2530AA8ADA980E, entity, SALVAGE_BOARD_COORDS.heading) -- SET_ENTITY_HEADING
			end
		end
	)
end

local function salvage_instant_sell()
	return run_coords_teleport(
		"Salvage Yard",
		"Teleported to Terminal",
		SALVAGE_SELL_COORDS.x,
		SALVAGE_SELL_COORDS.y,
		SALVAGE_SELL_COORDS.z,
		false,
		function()
			local me = players and players.me and players.me() or nil
			local entity = me and ((me.vehicle and me.vehicle ~= 0) and me.vehicle or me.ped) or nil
			if entity and invoker and invoker.call then
				invoker.call(0x8E2530AA8ADA980E, entity, SALVAGE_SELL_COORDS.heading) -- SET_ENTITY_HEADING
			end
		end
	)
end

local function salvage_instant_finish()
	return run_guarded_job("salvage_instant_finish", function()
		local mission = nil
		for i = 1, #SALVAGE_SCRIPTS.MISSIONS do
			local candidate = SALVAGE_SCRIPTS.MISSIONS[i]
			if is_script_running(candidate.script) then
				mission = candidate
				break
			end
		end

		if not mission then
			if notify then
				notify.push("Salvage Yard", "No Salvage mission script is active", 2200)
			end
			return
		end

		local selected = mission.offsets[1]
		for i = 1, #mission.offsets do
			local offsets = mission.offsets[i]
			if get_local_int(mission.script, offsets.step1, nil) ~= nil then
				selected = offsets
				break
			end
		end

		local step1_value = get_local_int(mission.script, selected.step1, 0)
		local ok1 = set_local_int(mission.script, selected.step1, step1_value | (1 << 11))
		local ok2 = set_local_int(mission.script, selected.step2, 2)

		local used_fallback = false
		local success = ok1 and ok2
		if not success then
			used_fallback = true
			local fallback1 = set_local_int(mission.script, selected.step1, 4)
			local fallback2 = set_local_int(mission.script, selected.step2, 5)
			success = fallback1 and fallback2
		end

		if notify then
			if success then
				notify.push(
					"Salvage Yard",
					used_fallback and "Instant finish triggered (fallback variant)" or "Instant finish triggered",
					2200
				)
			else
				notify.push("Salvage Yard", "Instant finish write failed", 2200)
			end
		end
	end, function()
		if notify then
			notify.push("Salvage Yard", "Instant finish already running", 1500)
		end
	end)
end

local function salvage_force_through_error()
	return run_guarded_job("salvage_force_through_error", function()
		if not is_script_running(SALVAGE_SCRIPTS.PLANNING) then
			if notify then
				notify.push("Salvage Yard", "Planning screen is not active", 2200)
			end
			return
		end

		local wrote_any = false
		for i = 1, #SALVAGE_SCRIPTS.PLANNING_FORCE_OFFSETS do
			local offset = SALVAGE_SCRIPTS.PLANNING_FORCE_OFFSETS[i]
			local ok = set_local_int(SALVAGE_SCRIPTS.PLANNING, offset, 1)
			if offset == 418 then
				salvage_flags.planning_force_offset_418_supported = ok and true or false
			elseif offset == 416 then
				salvage_flags.planning_force_offset_416_supported = ok and true or false
			end
			wrote_any = wrote_any or ok
		end

		if notify then
			notify.push(
				"Salvage Yard",
				wrote_any and "Forced through error state" or "Force-through write failed",
				2200
			)
		end
	end, function()
		if notify then
			notify.push("Salvage Yard", "Force Through Error already running", 1500)
		end
	end)
end

local function salvage_skip_weekly_cooldown()
	local p = GetMP()
	local week_sync = get_stat_int(p .. SALVAGE_STATS.WEEK_SYNC, 0) or 0
	local ok = set_tunable_int(SALVAGE_TUNABLES.WEEKLY_COOLDOWN, week_sync + 1)
	local reload_ok = salvage_reload_screen()
	if notify then
		notify.push("Salvage Yard", (ok and reload_ok) and "Weekly cooldown skipped" or "Could not skip cooldown", 2200)
	end
	return ok and reload_ok
end

local function salvage_collect_safe()
	if not salvage_flags.collect_safe_ee_only then
		if notify then
			notify.push("Salvage Yard", "Collect Safe is only supported on EE", 2200)
		end
		return false
	end

	local p = GetMP()
	local value = get_stat_int(p .. SALVAGE_STATS.SAFE_CASH_VALUE, 0) or 0
	if value <= 0 then
		if notify then
			notify.push("Salvage Yard", "Safe is empty", 2000)
		end
		return false
	end

	local ok = set_global_bool(SALVAGE_GLOBALS.SAFE_COLLECT_BOOL, true)
	if notify then
		notify.push("Salvage Yard", ok and "Safe collected" or "Collect failed", 2000)
	end
	return ok
end

local function salvage_refresh_collect_safe_state()
	salvage_flags.collect_safe_ee_only = global_bool_supported(SALVAGE_GLOBALS.SAFE_COLLECT_BOOL)
	if salvage_refs.collect_safe_button then
		salvage_refs.collect_safe_button.disabled = not salvage_flags.collect_safe_ee_only
	end
	return salvage_flags.collect_safe_ee_only
end

local function salvage_apply_sell_values()
	local multiplier = tonumber(SalvageConfig.salvage_multiplier) or 0.8
	local slot1 = math.floor(tonumber(SalvageConfig.sell_value_slot1) or 0)
	local slot2 = math.floor(tonumber(SalvageConfig.sell_value_slot2) or 0)
	local slot3 = math.floor(tonumber(SalvageConfig.sell_value_slot3) or 0)

	local ok = true
	ok = set_tunable_float(SALVAGE_TUNABLES.SALVAGE_MULTIPLIER, multiplier) and ok
	ok = set_tunable_int(SALVAGE_SLOT_TUNABLES[1].value, slot1) and ok
	ok = set_tunable_int(SALVAGE_SLOT_TUNABLES[2].value, slot2) and ok
	ok = set_tunable_int(SALVAGE_SLOT_TUNABLES[3].value, slot3) and ok

	local reload_ok = salvage_reload_screen()
	if notify then
		notify.push("Salvage Yard", (ok and reload_ok) and "Sell values applied" or "Could not apply sell values", 2200)
	end
	return ok and reload_ok
end

salvage_callbacks.apply_slot = salvage_apply_slot
salvage_callbacks.apply_all_slots = salvage_apply_all_changes
salvage_callbacks.complete_preps = salvage_complete_preps
salvage_callbacks.reset_preps = salvage_reset_preps
salvage_callbacks.reload_screen = salvage_reload_screen
salvage_callbacks.set_free_setup = salvage_set_free_setup
salvage_callbacks.set_free_claim = salvage_set_free_claim
salvage_callbacks.instant_finish = salvage_instant_finish
salvage_callbacks.force_through_error = salvage_force_through_error
salvage_callbacks.skip_weekly_cooldown = salvage_skip_weekly_cooldown
salvage_callbacks.collect_safe = salvage_collect_safe
salvage_callbacks.apply_sell_values = salvage_apply_sell_values
salvage_callbacks.apply_sell_multiplier = salvage_apply_sell_values
salvage_callbacks.enforce_toggles = salvage_enforce_heist_toggles

local salvageyard_logic = {
	SalvagePrepOptions = SalvagePrepOptions,
	SalvageConfig = SalvageConfig,
	salvage_flags = salvage_flags,
	salvage_refs = salvage_refs,
	salvage_callbacks = salvage_callbacks,
	salvage_apply_slot = salvage_apply_slot,
	salvage_make_slot_available = salvage_make_slot_available,
	salvage_apply_all_changes = salvage_apply_all_changes,
	salvage_complete_preps = salvage_complete_preps,
	salvage_reset_preps = salvage_reset_preps,
	salvage_reload_screen = salvage_reload_screen,
	salvage_set_free_setup = salvage_set_free_setup,
	salvage_set_free_claim = salvage_set_free_claim,
	salvage_enforce_heist_toggles = salvage_enforce_heist_toggles,
	salvage_teleport_entrance = salvage_teleport_entrance,
	salvage_teleport_board = salvage_teleport_board,
	salvage_instant_finish = salvage_instant_finish,
	salvage_instant_sell = salvage_instant_sell,
	salvage_force_through_error = salvage_force_through_error,
	salvage_skip_weekly_cooldown = salvage_skip_weekly_cooldown,
	salvage_collect_safe = salvage_collect_safe,
	salvage_refresh_collect_safe_state = salvage_refresh_collect_safe_state,
	salvage_apply_sell_values = salvage_apply_sell_values,
}

return salvageyard_logic
