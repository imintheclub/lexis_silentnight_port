local jobs = require("ShillenSilent_core.core.jobs")
local safe_access = require("ShillenSilent_core.core.safe_access")
local notify_core = require("ShillenSilent_core.core.notify")
local native_api = require("ShillenSilent_core.core.native_api")
local i18n = require("ShillenSilent_core.i18n")
local offsets = require("ShillenSilent_core.data.offsets.current")
local data = require("ShillenSilent_core.features.heists.autoshop.data")
local state = require("ShillenSilent_core.features.heists.autoshop.state")
local coords_teleport = require("ShillenSilent_core.shared.coords_teleport")
local blip_teleport = require("ShillenSilent_core.shared.blip_teleport")

local run_guarded_job = jobs.run_guarded_job
local run_coords_teleport = coords_teleport.run_coords_teleport
local teleport_to_blip_with_job = blip_teleport.teleport_to_blip_with_job

local actions = {}

local function config()
	return offsets.autoshop or {}
end

local text = i18n.t

local push = notify_core.feature("feature.autoshop.name")

function actions.sync_contract_index()
	return state.contract_index()
end

function actions.redraw_board()
	local cfg = config()
	if not safe_access.is_script_running(cfg.scripts.board_reload) then
		push("autoshop.notify.board_inactive", 2000)
		return false
	end

	local wrote_any = false
	for i = 1, #cfg.board.reload_offsets do
		local offset = cfg.board.reload_offsets[i]
		local ok = safe_access.set_local_int(cfg.scripts.board_reload, offset, cfg.board.reload_value)
		if offset == 406 then
			state.flags.board_reload_offset_406_supported = ok and true or false
		elseif offset == 408 then
			state.flags.board_reload_offset_408_supported = ok and true or false
		end
		wrote_any = wrote_any or ok
	end

	push(wrote_any and "autoshop.notify.board_redraw_ok" or "autoshop.notify.board_redraw_failed", 2000)
	return wrote_any
end

function actions.apply_and_complete_preps()
	local cfg = config()
	local contract = math.floor(tonumber(state.config.contract) or -1)
	local gen_bs = (contract == 1) and 4351 or 12543

	local ok1 = safe_access.set_mp_stat_int(cfg.stats.current, contract)
	local ok2 = safe_access.set_mp_stat_int(cfg.stats.gen_bs, gen_bs)
	local board_ok = actions.redraw_board()

	push((ok1 and ok2 and board_ok) and "autoshop.notify.preps_ok" or "autoshop.notify.preps_failed", 2000)
	return ok1 and ok2 and board_ok
end

function actions.reset_preps()
	local cfg = config()
	local ok = safe_access.set_mp_stat_int(cfg.stats.gen_bs, 12467)
	local board_ok = actions.redraw_board()
	push((ok and board_ok) and "autoshop.notify.reset_ok" or "autoshop.notify.reset_failed", 2000)
	return ok and board_ok
end

function actions.teleport_entrance()
	local cfg = config()
	return teleport_to_blip_with_job(
		cfg.blips.entrance,
		text("feature.autoshop.name"),
		text("autoshop.notify.teleported_entrance"),
		text("autoshop.notify.entrance_missing"),
		{ relay_if_interior = true }
	)
end

function actions.teleport_board()
	local cfg = config()
	if not safe_access.is_script_running(cfg.scripts.interior) then
		push("autoshop.notify.must_be_inside", 2200)
		return false
	end

	return run_coords_teleport(
		text("feature.autoshop.name"),
		text("autoshop.notify.teleported_board"),
		cfg.board.coords.x,
		cfg.board.coords.y,
		cfg.board.coords.z,
		false,
		function()
			local me = players and players.me and players.me() or nil
			local entity = me and ((me.vehicle and me.vehicle ~= 0) and me.vehicle or me.ped) or nil
			if entity and invoker and invoker.call then
				invoker.call(0x8E2530AA8ADA980E, entity, cfg.board.coords.heading)
			end
		end
	)
end

function actions.instant_finish_old()
	return run_guarded_job("autoshop_instant_finish_old", function()
		local cfg = config()
		if not safe_access.is_script_running(cfg.scripts.finish) then
			push("autoshop.notify.old_finish_requires", 2200)
			return
		end

		if not safe_access.force_host(cfg.scripts.finish) then
			push("autoshop.notify.host_failed", 2200)
			return
		end
		util.yield(1000)

		local finish = cfg.finish.old
		local ok1 = safe_access.set_local_int_variants(cfg.scripts.finish, finish.step1_offset, finish.step1_value)
		local ok2 = safe_access.set_local_int_variants(cfg.scripts.finish, finish.step2_offset, finish.step2_value)

		push((ok1 and ok2) and "autoshop.notify.finish_ok_old" or "autoshop.notify.finish_failed", 2200)
	end, function()
		push("autoshop.notify.finish_running", 1500)
	end)
end

function actions.instant_finish_new()
	return run_guarded_job("autoshop_instant_finish_new", function()
		local cfg = config()
		if not safe_access.is_script_running(cfg.scripts.finish) then
			push("autoshop.notify.new_finish_requires", 2200)
			return
		end

		if not safe_access.force_host(cfg.scripts.finish) then
			push("autoshop.notify.host_failed", 2200)
			return
		end
		util.yield(1000)

		local finish = cfg.finish.current
		local flags = safe_access.get_local_int_variants(cfg.scripts.finish, finish.step3_offset, 0)
		flags = flags | (1 << 9)
		flags = flags | (1 << 16)

		local ok1 = safe_access.set_local_int_variants(cfg.scripts.finish, finish.step1_offset, 5)
		local ok2 = safe_access.set_local_int_variants(cfg.scripts.finish, finish.step2_offset, 999999)
		local ok3 = safe_access.set_local_int_variants(cfg.scripts.finish, finish.step3_offset, flags)

		push((ok1 and ok2 and ok3) and "autoshop.notify.finish_ok" or "autoshop.notify.finish_failed", 2200)
	end, function()
		push("autoshop.notify.finish_running", 1500)
	end)
end

function actions.kill_cooldowns()
	local cfg = config()
	local stats_ok = true
	for i = 0, 7 do
		local ok = safe_access.set_mp_stat_int("TUNER_CONTRACT" .. tostring(i) .. "_POSIX", 0)
		stats_ok = stats_ok and ok
	end

	local any_tunable = safe_access.set_tunable_int_variants(cfg.tunables.cooldown, 0)

	push(
		(stats_ok and any_tunable) and "autoshop.notify.cooldowns_removed" or "autoshop.notify.cooldowns_incomplete",
		2200
	)
	return stats_ok and any_tunable
end

function actions.apply_payout()
	local cfg = config()
	local payout = data.clamp_payout(state.config.payout)
	state.set_payout(payout)
	local payout_ok = true

	for i = 1, #cfg.tunables.leader_rewards do
		local ok = safe_access.set_tunable_int(cfg.tunables.leader_rewards[i], payout)
		payout_ok = payout_ok and ok
	end

	local fee_ok = safe_access.set_tunable_float(cfg.tunables.contact_fee, 0.0)
	push((payout_ok and fee_ok) and "autoshop.notify.payout_ok" or "autoshop.notify.payout_failed", 2200)
	return payout_ok and fee_ok
end

function actions.skip_cutscene()
	return native_api.heist_skip_cutscene(i18n.t("feature.autoshop.name"))
end

return actions
