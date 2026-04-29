local core_state = require("ShillenSilent_core.shared.runtime_state")
local jobs = require("ShillenSilent_core.core.jobs")
local safe_access = require("ShillenSilent_core.core.safe_access")
local notify_core = require("ShillenSilent_core.core.notify")
local native_api = require("ShillenSilent_core.core.native_api")
local i18n = require("ShillenSilent_core.i18n")
local offsets = require("ShillenSilent_core.data.offsets.resolver")
local data = require("ShillenSilent_core.features.heists.casino.data")
local state = require("ShillenSilent_core.features.heists.casino.state")
local coords_teleport = require("ShillenSilent_core.shared.coords_teleport")
local blip_teleport = require("ShillenSilent_core.shared.blip_teleport")

local run_guarded_job = jobs.run_guarded_job
local run_coords_teleport = coords_teleport.run_coords_teleport
local teleport_to_blip_with_job = blip_teleport.teleport_to_blip_with_job

local actions = {}

local function cfg()
	return offsets.feature(data.feature_id)
end

local t = i18n.t

local push = notify_core.feature("feature.casino.name")

local tool_push = notify_core.feature("casino.group.tools")

local launch_push = notify_core.feature("casino.group.launch")

local prep_push = notify_core.feature("casino.group.preps")

local function should_notify(silent)
	return not silent
end

local function reload_planning_screen()
	local c = cfg()
	local ok = true
	for i = 1, #c.locals.planning_reload do
		ok = safe_access.set_local_int(c.scripts.planning, c.locals.planning_reload[i], c.locals.planning_reload_value)
			and ok
	end
	return ok
end

function actions.get_max_payout_cut_details()
	local c = cfg()
	local config = state.config
	local target = safe_access.get_active_mp_stat_int(c.stats.target, config.target)
	local approach = safe_access.get_active_mp_stat_int(c.stats.approach, config.approach)
	local hard_approach = safe_access.get_active_mp_stat_int(c.stats.hard_approach, 0)
	local difficulty = (hard_approach == approach and approach ~= 0) and 2 or 1
	local payout_by_target = data.primary_target_payouts[target]
	if not payout_by_target then
		return nil
	end

	local payout = (payout_by_target[difficulty] or payout_by_target[1]) + c.payout.vault_bonus
	local host_cut = data.clamp_cut(math.floor(data.safe_payout_target / (payout / 100)))
	local solo = core_state.solo_launch.casino and true or false
	if solo then
		return {
			target = target,
			difficulty = difficulty,
			solo = true,
			host_cut = host_cut,
			crew_cut = nil,
		}
	end

	local buyer = safe_access.get_global_int(c.globals.buyer, 0)
	local gunman = safe_access.get_active_mp_stat_int(c.stats.crew_weapon, config.crew_weapon)
	local driver = safe_access.get_active_mp_stat_int(c.stats.crew_driver, config.crew_driver)
	local hacker = safe_access.get_active_mp_stat_int(c.stats.crew_hacker, config.crew_hacker)

	local crew_cut = nil
	if
		data.buyer_fees[buyer]
		and data.gunman_cuts[gunman]
		and data.driver_cuts[driver]
		and data.hacker_cuts[hacker]
	then
		local fee_payout = payout - (payout * data.buyer_fees[buyer])
		local crew_ratio = 0.05 + data.gunman_cuts[gunman] + data.driver_cuts[driver] + data.hacker_cuts[hacker]
		local payout_after_crew = fee_payout - (fee_payout * crew_ratio)
		if payout_after_crew > 0 then
			crew_cut = data.clamp_cut(math.floor(data.safe_payout_target / (payout_after_crew / 100)))
		end
	end

	return {
		target = target,
		difficulty = difficulty,
		buyer = buyer,
		gunman = gunman,
		driver = driver,
		hacker = hacker,
		solo = false,
		host_cut = host_cut,
		crew_cut = crew_cut,
	}
end

function actions.get_max_payout_cut()
	local details = actions.get_max_payout_cut_details()
	return details and details.host_cut or 100
end

function actions.apply_cuts()
	local c = cfg()
	local ok = true
	for player_key, offset in pairs(c.globals.cuts) do
		local enabled = state.cut_enabled[player_key]
		local cut = enabled and state.cuts[player_key] or 0
		ok = safe_access.set_global_int(offset, data.clamp_cut(cut)) and ok
	end
	push(ok and "casino.notify.cuts_ok" or "casino.notify.cuts_failed", 2000)
	return ok
end

function actions.set_remove_crew_cuts(enable, silent)
	local c = cfg()
	local enabled = enable and true or false
	if state.flags.max_payout_enabled and not enabled then
		enabled = true
	end

	local changed = state.flags.remove_crew_cuts_enabled ~= enabled
	local backup = state.runtime.crew_cut_backup
	local ok = true
	for i = 1, #c.tunables.crew_cuts do
		local item = c.tunables.crew_cuts[i]
		if enabled then
			if backup[item.name] == nil then
				backup[item.name] = safe_access.get_tunable_int(item.name, item.default)
			end
			ok = safe_access.set_tunable_int(item.name, 0) and ok
		else
			ok = safe_access.set_tunable_int(item.name, backup[item.name] or item.default) and ok
		end
	end

	state.flags.remove_crew_cuts_enabled = enabled
	if changed and should_notify(silent) then
		push(enabled and "casino.notify.crew_cuts_removed" or "casino.notify.crew_cuts_restored", 2000)
	end
	return ok
end

function actions.set_autograbber(enable, silent)
	local enabled = enable and true or false
	local changed = state.flags.autograbber_enabled ~= enabled
	state.flags.autograbber_enabled = enabled
	if changed and should_notify(silent) then
		push(enabled and "casino.notify.autograbber_enabled" or "casino.notify.autograbber_disabled", 2000)
	end
	return true
end

function actions.refresh_max_payout(force_update)
	if not state.flags.max_payout_enabled then
		state.reset_max_payout_cache()
		return false
	end

	actions.set_remove_crew_cuts(true, true)
	local details = actions.get_max_payout_cut_details()
	if not details then
		return false
	end

	local cache = state.runtime.max_payout_cache
	local changed = force_update
		or cache.target ~= details.target
		or cache.difficulty ~= details.difficulty
		or cache.buyer ~= details.buyer
		or cache.gunman ~= details.gunman
		or cache.driver ~= details.driver
		or cache.hacker ~= details.hacker
		or cache.solo ~= details.solo
		or cache.host_cut ~= details.host_cut
		or cache.crew_cut ~= details.crew_cut

	if changed then
		state.set_cut("host", details.host_cut)
		if not details.solo and details.crew_cut ~= nil then
			state.set_cut("player2", details.crew_cut)
			state.set_cut("player3", details.crew_cut)
			state.set_cut("player4", details.crew_cut)
		end

		cache.target = details.target
		cache.difficulty = details.difficulty
		cache.buyer = details.buyer
		cache.gunman = details.gunman
		cache.driver = details.driver
		cache.hacker = details.hacker
		cache.solo = details.solo
		cache.host_cut = details.host_cut
		cache.crew_cut = details.crew_cut
	end
	return changed
end

function actions.set_max_payout(enable, silent)
	local enabled = enable and true or false
	local changed = state.flags.max_payout_enabled ~= enabled
	state.flags.max_payout_enabled = enabled
	if enabled then
		actions.set_remove_crew_cuts(true, true)
		actions.refresh_max_payout(true)
	else
		state.reset_max_payout_cache()
	end
	if changed and should_notify(silent) then
		push(enabled and "casino.notify.max_payout_enabled" or "casino.notify.max_payout_disabled", 2000)
	end
	return enabled
end

function actions.autograbber_tick()
	local c = cfg()
	if not state.flags.autograbber_enabled then
		return false
	end
	if not safe_access.is_script_running(c.scripts.controller) then
		return false
	end

	local grab = safe_access.get_local_int(c.scripts.controller, c.locals.autograbber_grab, 0)
	if grab == 3 then
		return safe_access.set_local_int(c.scripts.controller, c.locals.autograbber_grab, 4)
	elseif grab == 4 then
		return safe_access.set_local_float(c.scripts.controller, c.locals.autograbber_speed, 2.0)
	end
	return false
end

function actions.enforce_heist_toggles()
	local c = cfg()
	if state.flags.max_payout_enabled then
		for i = 1, #c.tunables.buyer_multipliers do
			safe_access.set_tunable_float(c.tunables.buyer_multipliers[i], 1.0)
		end
		if not state.flags.remove_crew_cuts_enabled then
			actions.set_remove_crew_cuts(true, true)
		end
	end
	if state.flags.remove_crew_cuts_enabled then
		for i = 1, #c.tunables.crew_cuts do
			safe_access.set_tunable_int(c.tunables.crew_cuts[i].name, 0)
		end
	end
	actions.autograbber_tick()
	return true
end

function actions.apply_preps()
	local c = cfg()
	local config = state.config
	state.clamp_loadout_slot()
	state.clamp_vehicle_slot()

	local ok = true
	if config.unlock_all_poi then
		ok = safe_access.set_stat_pairs_for_all_characters(c.preps.poi_unlock_pairs) and ok
	end

	ok = safe_access.set_stat_pairs_for_all_characters({
		{ c.stats.last_approach, 0 },
		{ c.stats.hard_approach, (config.difficulty == 0) and 0 or config.approach },
		{ c.stats.approach, config.approach },
		{ c.stats.crew_weapon, config.crew_weapon },
		{ c.stats.weapons, config.loadout_slot - 1 },
		{ c.stats.crew_driver, config.crew_driver },
		{ c.stats.vehicles, config.vehicle_slot - 1 },
		{ c.stats.crew_hacker, config.crew_hacker },
		{ c.stats.target, config.target },
		{ c.stats.masks, config.masks },
		{ c.stats.disrupt_shipments, config.disrupt_shipments },
		{ c.stats.key_levels, config.key_levels },
		{ c.stats.body_armor_level, -1 },
		{ c.stats.bitset0, -1 },
		{ c.stats.bitset1, -1 },
		{ c.stats.completed_posix, -1 },
	}) and ok
	ok = reload_planning_screen() and ok
	prep_push(ok and "casino.notify.preps_ok" or "casino.notify.preps_failed", 2000)
	return ok
end

function actions.reset_preps()
	local c = cfg()
	local ok = safe_access.set_stat_pairs_for_all_characters(c.preps.reset_pairs)
	ok = safe_access.set_stat_int(c.stats.cooldown, 0) and ok
	ok = reload_planning_screen() and ok
	prep_push(ok and "casino.notify.reset_ok" or "casino.notify.reset_failed", 2000)
	return ok
end

function actions.skip_arcade_setup()
	local ok = safe_access.set_stat_bool(cfg().stats.arcade_setup_done, true)
	tool_push(ok and "casino.notify.arcade_setup_ok" or "casino.notify.arcade_setup_failed", 2000)
	return ok
end

function actions.fix_stuck_keycards()
	local c = cfg()
	local ok = safe_access.set_local_int(c.scripts.controller, c.locals.keycards_fix, 5)
	tool_push(ok and "casino.notify.keycards_ok" or "casino.notify.keycards_failed", 2000)
	return ok
end

function actions.skip_objective()
	local c = cfg()
	local value = safe_access.get_local_int(c.scripts.controller, c.locals.objective_flags, 0)
	local ok = safe_access.set_local_int(c.scripts.controller, c.locals.objective_flags, value | (1 << 17))
	tool_push(ok and "casino.notify.objective_ok" or "casino.notify.objective_failed", 2000)
	return ok
end

function actions.fingerprint_hack()
	local c = cfg()
	local ok = safe_access.set_local_int(c.scripts.controller, c.locals.fingerprint_hack, 5)
	tool_push(ok and "casino.notify.fingerprint_ok" or "casino.notify.fingerprint_failed", 2000)
	return ok
end

function actions.instant_keypad_hack()
	local c = cfg()
	local ok = safe_access.set_local_int(c.scripts.controller, c.locals.keypad_hack, 5)
	tool_push(ok and "casino.notify.keypad_ok" or "casino.notify.keypad_failed", 2000)
	return ok
end

function actions.instant_vault_drill()
	local c = cfg()
	local vd2 =
		safe_access.get_local_int(c.scripts.controller, c.locals.vault_drill_base + c.locals.vault_drill_second, 0)
	local ok =
		safe_access.set_local_int(c.scripts.controller, c.locals.vault_drill_base + c.locals.vault_drill_first, vd2)
	tool_push(ok and "casino.notify.vault_drill_ok" or "casino.notify.vault_drill_failed", 2000)
	return ok
end

function actions.remove_cooldown()
	local c = cfg()
	local ok = true
	ok = safe_access.set_mp_stat_int(c.stats.completed_posix, -1) and ok
	ok = safe_access.set_stat_int(c.stats.cooldown, -1) and ok
	tool_push(ok and "casino.notify.cooldown_ok" or "casino.notify.cooldown_failed", 2000)
	return ok
end

function actions.set_team_lives()
	local c = cfg()
	if not safe_access.is_script_running(c.scripts.controller) then
		tool_push("casino.notify.controller_not_running", 2000)
		return false
	end
	local ok = safe_access.set_local_int(c.scripts.controller, c.locals.team_lives, -100)
	tool_push(ok and "casino.notify.team_lives_ok" or "casino.notify.team_lives_failed", 2000)
	return ok
end

function actions.instant_finish()
	local c = cfg()
	if not safe_access.is_script_running(c.scripts.controller) then
		tool_push("casino.notify.mission_not_running", 2000)
		return false
	end

	return run_guarded_job("casino_instant_finish", function()
		if not safe_access.force_host(c.scripts.controller) then
			tool_push("casino.notify.finish_host_failed", 2000)
			return
		end
		util.yield(1000)

		local approach = safe_access.get_mp_stat_int(c.stats.approach, 1)
		local finish = c.finish
		local ok = true
		if approach == 3 then
			ok = safe_access.set_local_int(c.scripts.controller, finish.aggressive_step1, 12) and ok
		else
			ok = safe_access.set_local_int(c.scripts.controller, finish.silent_step2, 5) and ok
		end
		ok = safe_access.set_local_int(c.scripts.controller, finish.step3, 80) and ok
		ok = safe_access.set_local_int(c.scripts.controller, finish.step4_money, 10000000) and ok
		ok = safe_access.set_local_int(c.scripts.controller, finish.step5, 99999) and ok
		ok = safe_access.set_local_int(c.scripts.controller, finish.step6, 99999) and ok
		tool_push(ok and "casino.notify.finish_ok" or "casino.notify.finish_failed", 2000)
	end, function()
		tool_push("casino.notify.finish_running", 1500)
	end)
end

function actions.force_ready()
	return run_guarded_job("casino_force_ready", function()
		local c = cfg()
		safe_access.force_host(c.scripts.controller)
		util.yield(1000)
		local ok = true
		ok = safe_access.set_global_int(c.globals.ready.player2, 1) and ok
		ok = safe_access.set_global_int(c.globals.ready.player3, 1) and ok
		ok = safe_access.set_global_int(c.globals.ready.player4, 1) and ok
		launch_push(ok and "casino.notify.ready_ok" or "casino.notify.ready_failed", 2000)
	end, function()
		launch_push("casino.notify.ready_running", 1500)
	end)
end

local function launcher_value()
	local c = cfg()
	if not safe_access.is_script_running(c.scripts.launcher) then
		return nil
	end
	local value = safe_access.get_local_int(c.scripts.launcher, c.launcher.value_offset, nil)
	if not value or value == 0 then
		return nil
	end
	return value
end

local function solo_launch_player_count_global(value)
	local c = cfg()
	return c.launcher.player_count_base + (value * c.launcher.player_count_stride) + c.launcher.player_count_offset
end

local function solo_launch_generic()
	local c = cfg()
	local value = launcher_value()
	if not value then
		return false
	end

	local ok = true
	ok = safe_access.set_global_int(solo_launch_player_count_global(value), 1) and ok
	ok = safe_access.set_local_int(c.scripts.launcher, c.launcher.required_players_offset, 1) and ok
	ok = safe_access.set_global_int(c.launcher.globals.player_count_1, 1) and ok
	ok = safe_access.set_global_int(c.launcher.globals.player_count_2, 1) and ok
	ok = safe_access.set_global_int(c.launcher.globals.flow, 1) and ok
	ok = safe_access.set_global_int(c.launcher.globals.extra, 0) and ok
	ok = safe_access.set_global_int(c.launcher.globals.flags, 1) and ok
	ok = safe_access.set_local_int(c.scripts.launcher, c.launcher.flags_offset, 0) and ok
	return ok
end

local function solo_launch_setup()
	local c = cfg()
	if not safe_access.is_script_running(c.scripts.controller) then
		return false
	end
	local is_finale = safe_access.get_global_int(c.globals.finale_flag, nil)
	if not is_finale or is_finale ~= 1 then
		return false
	end
	local approach = safe_access.get_mp_stat_int(c.stats.approach, nil)
	if not approach then
		return false
	end
	if approach == 2 and not safe_access.set_global_int(c.globals.big_con_approach, 3) then
		return false
	end
	local target = safe_access.get_mp_stat_int(c.stats.target, 0)
	return safe_access.set_global_int(c.globals.finale_target, target)
end

local function solo_launch_reset()
	local c = cfg()
	local value = launcher_value()
	if not value then
		return false
	end

	local ok = true
	ok = safe_access.set_global_int(solo_launch_player_count_global(value), 2) and ok
	ok = safe_access.set_local_int(c.scripts.launcher, c.launcher.required_players_offset, 2) and ok
	ok = safe_access.set_global_int(c.launcher.globals.player_count_1, 1) and ok
	ok = safe_access.set_global_int(c.launcher.globals.player_count_2, 1) and ok
	ok = safe_access.set_global_int(c.launcher.globals.flow, 2) and ok
	ok = safe_access.set_global_int(c.launcher.globals.extra, 11) and ok
	return ok
end

function actions.maintain_solo_launch()
	local enabled = core_state.solo_launch.casino and true or false
	if not enabled and state.runtime.solo_launch_prev then
		pcall(solo_launch_reset)
	end
	state.runtime.solo_launch_prev = enabled
	if not enabled then
		return false
	end
	pcall(solo_launch_generic)
	pcall(solo_launch_setup)
	return true
end

function actions.teleport_arcade()
	local c = cfg()
	return teleport_to_blip_with_job(
		c.blips.arcade,
		t("casino.group.teleport"),
		t("casino.notify.tp_arcade"),
		t("casino.notify.tp_arcade_missing"),
		{ relay_if_interior = true }
	)
end

local function teleport_to_coord(coord_key, message_key)
	local c = cfg()
	local coords = c.coords[coord_key]
	return run_coords_teleport(t("casino.group.teleport"), t(message_key), coords.x, coords.y, coords.z)
end

function actions.teleport_tunnel()
	return teleport_to_coord("tunnel", "casino.notify.tp_tunnel")
end

function actions.teleport_staff_lobby()
	return teleport_to_coord("staff_lobby", "casino.notify.tp_staff_lobby")
end

function actions.teleport_staff_lobby_inside()
	return teleport_to_coord("staff_lobby_inside", "casino.notify.tp_staff_lobby")
end

function actions.teleport_side_safe()
	return teleport_to_coord("side_safe", "casino.notify.tp_side_safe")
end

function actions.teleport_tunnel_door()
	return teleport_to_coord("tunnel_door", "casino.notify.tp_tunnel_door")
end

function actions.skip_cutscene()
	return native_api.heist_skip_cutscene(t("feature.casino.name"))
end

actions.casino_set_remove_crew_cuts = actions.set_remove_crew_cuts
actions.casino_set_autograbber = actions.set_autograbber
actions.casino_set_max_payout = actions.set_max_payout
actions.casino_refresh_max_payout = actions.refresh_max_payout
actions.casino_enforce_heist_toggles = actions.enforce_heist_toggles
actions.casino_skip_arcade_setup = actions.skip_arcade_setup
actions.casino_fix_stuck_keycards = actions.fix_stuck_keycards
actions.casino_skip_objective = actions.skip_objective
actions.casino_fingerprint_hack = actions.fingerprint_hack
actions.casino_instant_keypad_hack = actions.instant_keypad_hack
actions.casino_instant_vault_drill = actions.instant_vault_drill
actions.casino_remove_cooldown = actions.remove_cooldown
actions.casino_set_team_lives = actions.set_team_lives
actions.casino_instant_finish = actions.instant_finish
actions.casino_force_ready = actions.force_ready
actions.reset_heist_preps = actions.reset_preps
actions.apply_casino_cuts = actions.apply_cuts
actions.hp_get_casino_max_payout_cut = actions.get_max_payout_cut

return actions
