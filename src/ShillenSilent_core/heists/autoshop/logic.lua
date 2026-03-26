local core = require("ShillenSilent_core.core.bootstrap")
local presets = require("ShillenSilent_core.shared.presets_and_shared")
local heist_state = require("ShillenSilent_core.shared.heist_state")
local coords_teleport = require("ShillenSilent_core.shared.coords_teleport")
local blip_teleport = require("ShillenSilent_core.shared.blip_teleport")

local run_guarded_job = core.run_guarded_job
local run_coords_teleport = coords_teleport.run_coords_teleport
local teleport_to_blip_with_job = blip_teleport.teleport_to_blip_with_job
local GetMP = presets.GetMP
local hp_option_index_by_value = presets.hp_option_index_by_value

local autoshop_state = heist_state.autoshop
local AutoshopPrepOptions = autoshop_state.prep_options
local AutoshopConfig = autoshop_state.config
local autoshop_flags = autoshop_state.flags
local autoshop_refs = autoshop_state.refs
local autoshop_callbacks = autoshop_state.callbacks

local AUTOSHOP_BLIP_ENTRANCE = 779
local AUTOSHOP_BOARD_COORDS = { x = -1349.024, y = 138.381, z = -95.121, heading = 194.202 }
local AUTOSHOP_INTERIOR_SCRIPT = "am_mp_auto_shop"

local AUTOSHOP_STATS = {
	CURRENT = "TUNER_CURRENT",
	GEN_BS = "TUNER_GEN_BS",
}

local AUTOSHOP_TUNABLES = {
	COOLDOWN = "TUNER_ROBBERY_COOLDOWN_TIME",
	COOLDOWN_LEGACY = "TUNER_ROBBERY_COOLDOWN",
	CONTACT_FEE = "TUNER_ROBBERY_CONTACT_FEE",
	LEADER_REWARDS = {
		"TUNER_ROBBERY_LEADER_CASH_REWARD0",
		"TUNER_ROBBERY_LEADER_CASH_REWARD1",
		"TUNER_ROBBERY_LEADER_CASH_REWARD2",
		"TUNER_ROBBERY_LEADER_CASH_REWARD3",
		"TUNER_ROBBERY_LEADER_CASH_REWARD4",
		"TUNER_ROBBERY_LEADER_CASH_REWARD5",
		"TUNER_ROBBERY_LEADER_CASH_REWARD6",
		"TUNER_ROBBERY_LEADER_CASH_REWARD7",
	},
}

local AUTOSHOP_BOARD_RELOAD_SCRIPT = "tuner_planning"
local AUTOSHOP_BOARD_RELOAD_OFFSETS = { 406, 408 }
local AUTOSHOP_BOARD_RELOAD_VALUE = 2

local AUTOSHOP_FINISH_SCRIPT = "fm_mission_controller_2020"
local AUTOSHOP_FINISH_OLD = {
	step1_offset = 56223 + 1,
	step2_offset = 56223 + 1776 + 1,
	step1_value = 51338977,
	step2_value = 101,
}
local AUTOSHOP_FINISH_NEW = {
	step1_offset = 56223 + 1589,
	step2_offset = 56223 + 1776 + 1,
	step3_offset = 56223 + 1,
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

local function autoshop_sync_contract_index()
	AutoshopConfig.contract_index = hp_option_index_by_value(
		AutoshopPrepOptions.contracts,
		AutoshopConfig.contract,
		AutoshopConfig.contract_index or 1
	)
	if autoshop_refs.contract_dropdown then
		autoshop_refs.contract_dropdown.value = AutoshopConfig.contract_index
	end
end

local function autoshop_redraw_board()
	if not is_script_running(AUTOSHOP_BOARD_RELOAD_SCRIPT) then
		if notify then
			notify.push("Auto Shop", "Auto Shop board is not active", 2000)
		end
		return false
	end

	local wrote_any = false
	for i = 1, #AUTOSHOP_BOARD_RELOAD_OFFSETS do
		local offset = AUTOSHOP_BOARD_RELOAD_OFFSETS[i]
		local ok = set_local_int(AUTOSHOP_BOARD_RELOAD_SCRIPT, offset, AUTOSHOP_BOARD_RELOAD_VALUE)
		if offset == 406 then
			autoshop_flags.board_reload_offset_406_supported = ok and true or false
		elseif offset == 408 then
			autoshop_flags.board_reload_offset_408_supported = ok and true or false
		end
		wrote_any = wrote_any or ok
	end

	if notify then
		notify.push("Auto Shop", wrote_any and "Board redrawn" or "Board redraw write failed", 2000)
	end
	return wrote_any
end

local function autoshop_apply_and_complete_preps()
	local p = GetMP()
	local contract = math.floor(tonumber(AutoshopConfig.contract) or -1)
	local gen_bs = (contract == 1) and 4351 or 12543

	local ok1 = set_stat_int(p .. AUTOSHOP_STATS.CURRENT, contract)
	local ok2 = set_stat_int(p .. AUTOSHOP_STATS.GEN_BS, gen_bs)
	local board_ok = autoshop_redraw_board()

	if notify then
		notify.push("Auto Shop", (ok1 and ok2 and board_ok) and "Preps applied" or "Could not apply preps", 2000)
	end
	return ok1 and ok2 and board_ok
end

local function autoshop_reset_preps()
	local p = GetMP()
	local ok = set_stat_int(p .. AUTOSHOP_STATS.GEN_BS, 12467)
	local board_ok = autoshop_redraw_board()
	if notify then
		notify.push("Auto Shop", (ok and board_ok) and "Preps reset" or "Could not reset preps", 2000)
	end
	return ok and board_ok
end

local function autoshop_teleport_entrance()
	return teleport_to_blip_with_job(
		AUTOSHOP_BLIP_ENTRANCE,
		"Auto Shop",
		"Teleported to Entrance",
		"Auto Shop entrance blip not found",
		{ relay_if_interior = true }
	)
end

local function autoshop_teleport_board()
	if not is_script_running(AUTOSHOP_INTERIOR_SCRIPT) then
		if notify then
			notify.push("Auto Shop", "You must be inside the Auto Shop interior", 2200)
		end
		return false
	end

	return run_coords_teleport(
		"Auto Shop",
		"Teleported to Board",
		AUTOSHOP_BOARD_COORDS.x,
		AUTOSHOP_BOARD_COORDS.y,
		AUTOSHOP_BOARD_COORDS.z,
		false,
		function()
			local me = players and players.me and players.me() or nil
			local entity = me and ((me.vehicle and me.vehicle ~= 0) and me.vehicle or me.ped) or nil
			if entity and invoker and invoker.call then
				invoker.call(0x8E2530AA8ADA980E, entity, AUTOSHOP_BOARD_COORDS.heading) -- SET_ENTITY_HEADING
			end
		end
	)
end

local function autoshop_instant_finish_old()
	return run_guarded_job("autoshop_instant_finish_old", function()
		if not is_script_running(AUTOSHOP_FINISH_SCRIPT) then
			if notify then
				notify.push("Auto Shop", "Old finish requires fm_mission_controller_2020", 2200)
			end
			return
		end

		if not force_script_host(AUTOSHOP_FINISH_SCRIPT) then
			if notify then
				notify.push("Auto Shop", "Could not force host", 2200)
			end
			return
		end
		util.yield(1000)

		local ok1 =
			set_local_int(AUTOSHOP_FINISH_SCRIPT, AUTOSHOP_FINISH_OLD.step1_offset, AUTOSHOP_FINISH_OLD.step1_value)
		local ok2 =
			set_local_int(AUTOSHOP_FINISH_SCRIPT, AUTOSHOP_FINISH_OLD.step2_offset, AUTOSHOP_FINISH_OLD.step2_value)

		if notify then
			notify.push(
				"Auto Shop",
				(ok1 and ok2) and "Instant finish triggered (Old)" or "Old finish write failed",
				2200
			)
		end
	end, function()
		if notify then
			notify.push("Auto Shop", "Old finish already running", 1500)
		end
	end)
end

local function autoshop_instant_finish_new()
	return run_guarded_job("autoshop_instant_finish_new", function()
		if not is_script_running(AUTOSHOP_FINISH_SCRIPT) then
			if notify then
				notify.push("Auto Shop", "New finish requires fm_mission_controller_2020", 2200)
			end
			return
		end

		if not force_script_host(AUTOSHOP_FINISH_SCRIPT) then
			if notify then
				notify.push("Auto Shop", "Could not force host", 2200)
			end
			return
		end
		util.yield(1000)

		local flags = get_local_int(AUTOSHOP_FINISH_SCRIPT, AUTOSHOP_FINISH_NEW.step3_offset, 0)
		flags = flags | (1 << 9)
		flags = flags | (1 << 16)

		local ok1 = set_local_int(AUTOSHOP_FINISH_SCRIPT, AUTOSHOP_FINISH_NEW.step1_offset, 5)
		local ok2 = set_local_int(AUTOSHOP_FINISH_SCRIPT, AUTOSHOP_FINISH_NEW.step2_offset, 999999)
		local ok3 = set_local_int(AUTOSHOP_FINISH_SCRIPT, AUTOSHOP_FINISH_NEW.step3_offset, flags)

		if notify then
			notify.push(
				"Auto Shop",
				(ok1 and ok2 and ok3) and "Instant finish triggered (New)" or "New finish write failed",
				2200
			)
		end
	end, function()
		if notify then
			notify.push("Auto Shop", "New finish already running", 1500)
		end
	end)
end

local function autoshop_kill_cooldowns()
	local p = GetMP()

	local stats_ok = true
	for i = 0, 7 do
		local ok = set_stat_int(p .. "TUNER_CONTRACT" .. tostring(i) .. "_POSIX", 0)
		stats_ok = stats_ok and ok
	end

	local cooldown_ok = set_tunable_int(AUTOSHOP_TUNABLES.COOLDOWN, 0)
	local cooldown_legacy_ok = set_tunable_int(AUTOSHOP_TUNABLES.COOLDOWN_LEGACY, 0)
	local any_tunable = cooldown_ok or cooldown_legacy_ok

	if notify then
		notify.push(
			"Auto Shop",
			(stats_ok and any_tunable) and "Cooldowns removed" or "Cooldown write incomplete",
			2200
		)
	end
	return stats_ok and any_tunable
end

local function autoshop_apply_payout()
	local payout = math.floor(tonumber(AutoshopConfig.payout) or 1000000)
	local payout_ok = true

	for i = 1, #AUTOSHOP_TUNABLES.LEADER_REWARDS do
		local ok = set_tunable_int(AUTOSHOP_TUNABLES.LEADER_REWARDS[i], payout)
		payout_ok = payout_ok and ok
	end

	local fee_ok = set_tunable_float(AUTOSHOP_TUNABLES.CONTACT_FEE, 0.0)
	if notify then
		notify.push("Auto Shop", (payout_ok and fee_ok) and "Payout applied" or "Payout write incomplete", 2200)
	end
	return payout_ok and fee_ok
end

autoshop_callbacks.apply_preps = autoshop_apply_and_complete_preps
autoshop_callbacks.reset_preps = autoshop_reset_preps
autoshop_callbacks.redraw_board = autoshop_redraw_board
autoshop_callbacks.kill_cooldowns = autoshop_kill_cooldowns
autoshop_callbacks.instant_finish = autoshop_instant_finish_new
autoshop_callbacks.apply_payout = autoshop_apply_payout

local autoshop_logic = {
	AutoshopPrepOptions = AutoshopPrepOptions,
	AutoshopConfig = AutoshopConfig,
	autoshop_flags = autoshop_flags,
	autoshop_refs = autoshop_refs,
	autoshop_callbacks = autoshop_callbacks,
	autoshop_sync_contract_index = autoshop_sync_contract_index,
	autoshop_apply_and_complete_preps = autoshop_apply_and_complete_preps,
	autoshop_reset_preps = autoshop_reset_preps,
	autoshop_redraw_board = autoshop_redraw_board,
	autoshop_teleport_entrance = autoshop_teleport_entrance,
	autoshop_teleport_board = autoshop_teleport_board,
	autoshop_instant_finish_old = autoshop_instant_finish_old,
	autoshop_instant_finish_new = autoshop_instant_finish_new,
	autoshop_kill_cooldowns = autoshop_kill_cooldowns,
	autoshop_apply_payout = autoshop_apply_payout,
}

return autoshop_logic
