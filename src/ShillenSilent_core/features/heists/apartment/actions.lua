local jobs = require("ShillenSilent_core.core.jobs")
local safe_access = require("ShillenSilent_core.core.safe_access")
local heist_cuts = require("ShillenSilent_core.core.heist_cuts")
local notify_core = require("ShillenSilent_core.core.notify")
local native_api = require("ShillenSilent_core.core.native_api")
local i18n = require("ShillenSilent_core.i18n")
local offsets = require("ShillenSilent_core.data.offsets.resolver")
local data = require("ShillenSilent_core.features.heists.apartment.data")
local state = require("ShillenSilent_core.features.heists.apartment.state")
local blip_teleport = require("ShillenSilent_core.shared.blip_teleport")
local solo_launch_runtime = require("ShillenSilent_core.runtime.solo_launch")

local core_state = require("ShillenSilent_core.shared.runtime_state")
local run_guarded_job = jobs.run_guarded_job
local teleport_to_blip_with_job = blip_teleport.teleport_to_blip_with_job

local actions = {}

local function config()
	return offsets.feature("apartment")
end

local push = notify_core.feature("feature.apartment.name")

local text = i18n.t

local function mission_script()
	return config().scripts.mission_controller
end

local function user_id()
	return (players and players.user and players.user()) or 0
end

local function read_heist_key_from_stat(stat_name)
	local heist_id = safe_access.get_stat_string(stat_name, nil)
	if heist_id and data.heist_key_by_rcont[heist_id] then
		return data.heist_key_by_rcont[heist_id]
	end

	local value = safe_access.get_stat_int(stat_name, nil)
	if value and data.heist_key_by_rcont[value] then
		return data.heist_key_by_rcont[value]
	end

	return nil
end

local function read_heist_key_from_stat_variants(stat_name)
	local raw = read_heist_key_from_stat(stat_name)
	if raw then
		return raw
	end

	local active = read_heist_key_from_stat(safe_access.stat_name(stat_name, { active = true }))
	if active then
		return active
	end

	return read_heist_key_from_stat(safe_access.stat_name(stat_name))
end

local function current_heist_key()
	local cfg = config()
	local rcont = cfg.stats.heist_mission_rcont_id
	local by_stat1 = read_heist_key_from_stat_variants(rcont .. "1")
	if by_stat1 then
		return by_stat1
	end

	local by_stat0 = read_heist_key_from_stat_variants(rcont .. "0")
	if by_stat0 then
		return by_stat0
	end

	local progress_hash = safe_access.get_stat_int(cfg.stats.heist_progress_hash, nil)
	if progress_hash and data.heist_key_by_progress_hash[progress_hash] then
		return data.heist_key_by_progress_hash[progress_hash]
	end

	return nil
end

local function current_heist_id()
	local heist_key = current_heist_key()
	local heist = heist_key and data.preps[heist_key] or nil
	return heist and heist.rcont_ids[2] or nil
end

local function world_apartment_id()
	local cfg = config()
	local player_id = user_id()
	local world = cfg.globals.world_apartment_id
	local ee_global = world.ee + (player_id * world.ee_stride)
	local legacy_global = world.legacy + (player_id * world.legacy_stride)

	local id = safe_access.get_global_int(ee_global, nil)
	if id ~= nil then
		return id
	end

	id = safe_access.get_global_int(legacy_global, nil)
	if id ~= nil then
		return id
	end

	return safe_access.get_stat_int(cfg.stats.property_house, 0) or 0
end

local function normalize_hash(value)
	local numeric = tonumber(value)
	if not numeric or numeric == 0 then
		return nil
	end
	return math.floor(numeric)
end

local function resolve_root_hash(tunable_name, fallback_text)
	local value = normalize_hash(safe_access.get_tunable_int(tunable_name, nil))
	if value then
		return value
	end

	local ok_joaat, joaat_hash = pcall(function()
		if type(joaat) ~= "function" then
			return nil
		end
		return joaat(fallback_text)
	end)
	if ok_joaat then
		value = normalize_hash(joaat_hash)
		if value then
			return value
		end
	end

	local ok_native, native_hash = pcall(function()
		local hashed = invoker.call(data.natives.get_hash_key, fallback_text)
		if type(hashed) == "number" then
			return hashed
		end
		if type(hashed) == "table" then
			return hashed.int32 or hashed.int or hashed.uint or hashed.u32 or hashed.hash
		end
		return nil
	end)
	if ok_native then
		return normalize_hash(native_hash)
	end

	return nil
end

local function is_in_apartment_interior()
	local cfg = config()
	local me = players and players.me and players.me() or nil
	if not (me and me.in_interior) then
		return false
	end

	for i = 1, #cfg.scripts.excluded_interiors do
		if safe_access.is_script_running(cfg.scripts.excluded_interiors[i]) then
			return false
		end
	end
	return true
end

function actions.is_fleeca()
	return current_heist_key() == "fleeca"
end

function actions.teleport_entrance()
	return teleport_to_blip_with_job(
		blip_teleport.BLIP_SPRITES_APARTMENT,
		text("feature.apartment.name"),
		text("apartment.notify.tp_entrance"),
		text("apartment.notify.tp_entrance_missing"),
		{ relay_if_interior = true }
	)
end

function actions.teleport_heist_board()
	if not is_in_apartment_interior() then
		push("apartment.notify.tp_need_interior", 2200)
		return false
	end

	return teleport_to_blip_with_job(
		blip_teleport.BLIP_SPRITES_HEIST,
		text("feature.apartment.name"),
		text("apartment.notify.tp_board"),
		text("apartment.notify.tp_board_missing"),
		{ heading = 173.376 }
	)
end

function actions.force_ready()
	local script_name = mission_script()
	return run_guarded_job("apartment_force_ready", function()
		if not safe_access.is_script_running(script_name) then
			push("apartment.notify.mission_not_running", 2200)
			return
		end
		if not safe_access.force_host(script_name) then
			push("apartment.notify.finish_host_failed", 2200)
			return
		end
		util.yield(1000)

		local ready = config().globals.ready
		local ok = true
		ok = safe_access.set_global_int(ready.player2, data.values.force_ready) and ok
		ok = safe_access.set_global_int(ready.player3, data.values.force_ready) and ok
		ok = safe_access.set_global_int(ready.player4, data.values.force_ready) and ok

		push(ok and "apartment.notify.ready_ok" or "apartment.notify.ready_failed", 2000)
	end, function()
		push("apartment.notify.ready_running", 1500)
	end)
end

function actions.redraw_board()
	local cfg = config()
	local reload = cfg.globals.reload
	local ok = true
	ok = safe_access.set_global_int(reload.step1, data.values.board_reload_step1_reset) and ok
	util.yield(1000)
	ok = safe_access.set_global_int(reload.step1, data.values.board_reload_step1) and ok
	ok = safe_access.set_global_int(reload.step2, data.values.board_reload_step2) and ok

	push(ok and "apartment.notify.board_ok" or "apartment.notify.board_failed", 2000)
	return ok
end

function actions.complete_preps()
	local cfg = config()
	local heist_key = current_heist_key()
	local heist = heist_key and data.preps[heist_key] or nil
	if not heist then
		push("apartment.notify.preps_no_heist", 2600)
		return false
	end

	local ok = true
	ok = safe_access.set_stat_int(cfg.stats.heist_planning_stage, data.values.heist_planning_stage_complete) and ok
	ok = safe_access.set_stat_int(cfg.stats.bitset_heist_vs_missions, data.values.bitset_heist_vs_missions_complete)
		and ok
	ok = safe_access.set_stat_int(cfg.stats.heist_session_id_macaddr, data.values.heist_session_id_macaddr) and ok
	ok = safe_access.set_stat_int(cfg.stats.heist_leader_apart_id, world_apartment_id()) and ok
	ok = safe_access.set_stat_int(cfg.stats.heist_progress_hash, heist.progress_hash) and ok
	ok = safe_access.set_stat_int(cfg.stats.heist_total_reward_cosmetic, heist.reward_cosmetic) and ok

	for i = 0, 7 do
		local rcont_value = heist.rcont_ids[i + 1]
		if i == 0 then
			ok = safe_access.set_stat_int(
				cfg.stats.heist_mission_rcont_id .. tostring(i),
				math.floor(tonumber(rcont_value) or 0)
			) and ok
		else
			ok = safe_access.set_stat_string(
				cfg.stats.heist_mission_rcont_id .. tostring(i),
				rcont_value and tostring(rcont_value) or ""
			) and ok
		end
		ok = safe_access.set_stat_int(cfg.stats.heist_mission_depth_lv .. tostring(i), heist.depth_lvs[i + 1] or -1)
			and ok
	end

	local root = cfg.globals.root_content
	ok = safe_access.set_global_string(root.step1, heist.root_content_id) and ok
	ok = safe_access.set_global_string(root.step2, heist.root_content_id) and ok
	ok = safe_access.set_global_string(root.step3, heist.root_content_id) and ok

	ok = safe_access.set_global_int(cfg.globals.cooldown.step1, data.values.cooldown_enabled) and ok
	ok = safe_access.set_global_int(cfg.globals.cooldown.step2, data.values.cooldown_cleared) and ok
	ok = actions.redraw_board() and ok

	push(ok and "apartment.notify.preps_ok" or "apartment.notify.preps_failed", 2200)
	return ok
end

local function clear_cooldown()
	local cooldown = config().globals.cooldown
	local cooldown_step1 = cooldown.step1 + (user_id() * cooldown.player_stride)
	local ok = true
	ok = safe_access.set_global_int(cooldown_step1, data.values.cooldown_removed) and ok
	ok = safe_access.set_global_int(cooldown.step2, data.values.cooldown_cleared) and ok
	return ok
end

function actions.kill_cooldown()
	local ok = clear_cooldown()
	push(ok and "apartment.notify.cooldown_ok" or "apartment.notify.cooldown_failed", 2000)
	return ok
end

function actions.fleeca_hack()
	local cfg = config()
	local script_name = cfg.scripts.mission_controller
	if safe_access.is_script_running(script_name) then
		local ok = safe_access.set_local_int(script_name, cfg.locals.fleeca_hack, data.values.fleeca_hack_complete)
		push(ok and "apartment.notify.fleeca_hack_ok" or "apartment.notify.fleeca_hack_failed", 2000)
		return ok
	end

	push("apartment.notify.hack_inactive", 2000)
	return false
end

function actions.fleeca_drill()
	local cfg = config()
	local script_name = cfg.scripts.mission_controller
	if safe_access.is_script_running(script_name) then
		local ok = safe_access.set_local_float(script_name, cfg.locals.fleeca_drill, data.values.fleeca_drill_complete)
		push(ok and "apartment.notify.fleeca_drill_ok" or "apartment.notify.fleeca_drill_failed", 2000)
		return ok
	end

	push("apartment.notify.drill_inactive", 2000)
	return false
end

function actions.pacific_hack()
	local cfg = config()
	local script_name = cfg.scripts.mission_controller
	if safe_access.is_script_running(script_name) then
		local ok = safe_access.set_local_int(script_name, cfg.locals.pacific_hack, data.values.pacific_hack_complete)
		push(ok and "apartment.notify.pacific_hack_ok" or "apartment.notify.pacific_hack_failed", 2000)
		return ok
	end

	push("apartment.notify.hack_inactive", 2000)
	return false
end

function actions.instant_finish_pacific()
	local cfg = config()
	local script_name = cfg.scripts.mission_controller
	return run_guarded_job("apartment_instant_finish_pacific", function()
		if not safe_access.is_script_running(script_name) then
			push("apartment.notify.mission_not_running", 2000)
			return
		end
		if not safe_access.force_host(script_name) then
			push("apartment.notify.finish_host_failed", 2000)
			return
		end

		util.yield(1000)
		local ok = true
		ok = safe_access.set_local_int(script_name, cfg.locals.pacific_finish_status, data.values.pacific_finish_status)
			and ok
		ok = safe_access.set_local_int(script_name, cfg.locals.pacific_finish_percent, 80) and ok
		ok = safe_access.set_local_int(script_name, cfg.locals.finish_take_1, data.values.pacific_finish_take) and ok
		ok = safe_access.set_local_int(script_name, cfg.locals.finish_take_2, data.values.finish_large_take) and ok
		ok = safe_access.set_local_int(script_name, cfg.locals.finish_take_3, data.values.finish_large_take) and ok
		push(ok and "apartment.notify.finish_pacific_ok" or "apartment.notify.finish_write_failed", 2000)
	end, function()
		push("apartment.notify.finish_running", 1500)
	end)
end

function actions.instant_finish_other()
	local cfg = config()
	local script_name = cfg.scripts.mission_controller
	return run_guarded_job("apartment_instant_finish_other", function()
		if not safe_access.is_script_running(script_name) then
			push("apartment.notify.mission_not_running", 2000)
			return
		end
		if not safe_access.force_host(script_name) then
			push("apartment.notify.finish_host_failed", 2000)
			return
		end

		util.yield(1000)
		local ok = true
		ok = safe_access.set_local_int(script_name, cfg.locals.other_finish_status, data.values.other_finish_status)
			and ok
		ok = safe_access.set_local_int(script_name, cfg.locals.finish_take_1, data.values.finish_large_take) and ok
		ok = safe_access.set_local_int(script_name, cfg.locals.finish_take_2, data.values.finish_large_take) and ok
		ok = safe_access.set_local_int(script_name, cfg.locals.finish_take_3, data.values.finish_large_take) and ok
		push(ok and "apartment.notify.finish_other_ok" or "apartment.notify.finish_write_failed", 2000)
	end, function()
		push("apartment.notify.finish_running", 1500)
	end)
end

function actions.play_unavailable()
	local ok = clear_cooldown()
	push(ok and "apartment.notify.jobs_unlock_ok" or "apartment.notify.jobs_unlock_failed", 2000)
	return ok
end

function actions.change_session()
	local started
	local result = invoker.call(data.natives.network_session_host_closed, 0, 32)
	if result and result.bool then
		started = true
	else
		local fallback = invoker.call(data.natives.network_session_host, 0, 32, true)
		started = (fallback and fallback.bool) and true or false
	end

	push(started and "apartment.notify.session_ok" or "apartment.notify.session_failed", started and 2000 or 2800)
	return started
end

function actions.unlock_all_jobs()
	local cfg = config()
	local root_hashes = {}
	for i = 1, #data.root_defs do
		local root_hash = resolve_root_hash(data.root_defs[i].tunable, data.root_defs[i].fallback)
		if not root_hash then
			push("apartment.notify.unlock_invalid_hash", 2600)
			return false
		end
		root_hashes[i] = root_hash
	end

	local prefix = safe_access.get_mp_prefix()
	local ok_all = true
	for i = 0, 4 do
		local strand_ok = safe_access.set_stat_int(prefix .. cfg.stats.saved_strand .. tostring(i), root_hashes[i + 1])
		local depth_ok = safe_access.set_stat_int(
			prefix .. cfg.stats.saved_strand .. tostring(i) .. cfg.stats.saved_strand_level_suffix,
			data.values.unlock_depth
		)
		ok_all = strand_ok and depth_ok and ok_all
	end

	ok_all = safe_access.set_global_int(cfg.globals.reload.step2, data.values.board_unlock_all) and ok_all
	ok_all = actions.redraw_board() and ok_all

	push(ok_all and "apartment.notify.unlock_all_ok" or "apartment.notify.unlock_all_partial", 2600)
	return ok_all
end

local function force_cut_ui_flow()
	pcall(function()
		local gui = _G.GUI
		if gui and type(gui.IsOpen) == "function" and type(gui.Toggle) == "function" and gui.IsOpen() then
			gui.Toggle()
		end
	end)

	if util and type(util.yield) == "function" then
		util.yield(1000)
	end

	pcall(function()
		local gta = _G.GTA
		if gta and type(gta.SimulatePlayerControl) == "function" then
			gta.SimulatePlayerControl(237)
		end
	end)
	pcall(function()
		local gta = _G.GTA
		if gta and type(gta.SimulateFrontendControl) == "function" then
			gta.SimulateFrontendControl(202)
		end
	end)
end

function actions.apply_cuts(cuts_values, auto_force_cuts)
	if type(cuts_values) ~= "table" then
		push("apartment.notify.cuts_failed", 2000)
		return false
	end

	local cfg = config()
	local ok = heist_cuts.write_apartment_globals({
		player_keys = data.player_keys,
		offsets = cfg.globals.cuts,
		cuts = cuts_values,
		enabled = {
			player1 = true,
			player2 = true,
			player3 = true,
			player4 = true,
		},
		clamp = data.clamp_cut,
	})

	if auto_force_cuts then
		force_cut_ui_flow()
	end

	push(ok and "apartment.notify.cuts_ok" or "apartment.notify.cuts_failed", 2000)
	return ok
end

function actions.apply_state_cuts()
	return actions.apply_cuts(state.enabled_cuts(), state.flags.auto_force_cuts)
end

function actions.apply_selected_cut_preset()
	local selected = state.selected_cut_preset()
	state.apply_uniform_cut(selected.value)
	return selected.value
end

function actions.set_12mil_bonus(enable, silent)
	local cfg = config()
	local bonus_value = enable and data.bonus.enabled_progress or data.bonus.disabled_progress
	local award_value = not enable
	local ok = true
	ok = safe_access.set_stat_int(cfg.stats.flow_order_progress, bonus_value) and ok
	ok = safe_access.set_stat_bool(cfg.stats.flow_order_award, award_value) and ok
	ok = safe_access.set_stat_int(cfg.stats.team_progress, bonus_value) and ok
	ok = safe_access.set_stat_bool(cfg.stats.team_award, award_value) and ok
	ok = safe_access.set_stat_int(cfg.stats.no_death_progress, bonus_value) and ok
	ok = safe_access.set_stat_bool(cfg.stats.no_death_award, award_value) and ok

	state.flags.bonus_enabled = enable and true or false
	if not silent then
		if enable then
			push(ok and "apartment.notify.bonus_enabled" or "apartment.notify.bonus_failed", 2000)
		else
			push(ok and "apartment.notify.bonus_disabled" or "apartment.notify.bonus_failed", 2000)
		end
	end
	return ok
end

function actions.refresh_max_payout(force_update)
	if not state.flags.max_payout_enabled then
		state.runtime.max_payout_cache = {}
		return false
	end

	local heist_id = current_heist_id()
	local payout_by_heist = heist_id and data.payouts[heist_id] or nil
	if not payout_by_heist then
		state.runtime.max_payout_cache = {}
		return false
	end

	local difficulty = math.floor(tonumber(safe_access.get_stat_int("HEIST_DIFFICULTY", 1)) or 1)
	if difficulty < 1 then
		difficulty = 1
	end
	if difficulty > #payout_by_heist then
		difficulty = #payout_by_heist
	end

	local payout = payout_by_heist[difficulty]
	if not payout or payout <= 0 then
		return false
	end

	local divisor = state.flags.double_rewards_week and 2 or 1
	local cut = data.clamp_cut(math.floor((data.safe_payout_target * 100) / (payout * divisor)))
	local cache = state.runtime.max_payout_cache
	if
		force_update
		or cache.heist ~= heist_id
		or cache.difficulty ~= difficulty
		or cache.double ~= state.flags.double_rewards_week
		or cache.cut ~= cut
	then
		state.apply_uniform_cut(cut)
		cache.heist = heist_id
		cache.difficulty = difficulty
		cache.double = state.flags.double_rewards_week
		cache.cut = cut
	end
	return true
end

function actions.set_max_payout(enabled, silent)
	state.flags.max_payout_enabled = enabled and true or false
	if enabled then
		local ok = actions.refresh_max_payout(true)
		if not silent then
			push(
				ok and "apartment.notify.max_payout_enabled" or "apartment.notify.max_payout_unknown",
				ok and 2000 or 2400
			)
		end
		return ok
	end

	state.runtime.max_payout_cache = {}
	if not silent then
		push("apartment.notify.max_payout_disabled", 2000)
	end
	return true
end

function actions.set_double_rewards(enabled, silent)
	state.flags.double_rewards_week = enabled and true or false
	if state.flags.max_payout_enabled then
		actions.refresh_max_payout(true)
	end
	if not silent then
		push(enabled and "apartment.notify.double_enabled" or "apartment.notify.double_disabled", 2000)
	end
	return true
end

local function launcher_value()
	local cfg = config()
	if not safe_access.is_script_running(cfg.scripts.launcher) then
		return nil
	end

	local value = safe_access.get_local_int(cfg.scripts.launcher, cfg.locals.launcher_value, nil)
	if not value or value == 0 then
		return nil
	end
	return value
end

local function solo_launch_player_count_global(value)
	local launcher = config().launcher
	return launcher.player_count_base + (value * launcher.player_count_stride) + launcher.player_count_offset
end

function actions.solo_launch_reset()
	local cfg = config()
	local value = launcher_value()
	if not value then
		return false
	end

	local required_players = actions.is_fleeca() and 2 or 4
	local globals = cfg.launcher.globals
	local ok = true
	ok = safe_access.set_global_int(solo_launch_player_count_global(value), required_players) and ok
	ok = safe_access.set_local_int(cfg.scripts.launcher, cfg.locals.launcher_required_players, required_players) and ok
	ok = safe_access.set_global_int(globals.player_count_1, required_players) and ok
	ok = safe_access.set_global_int(globals.player_count_2, required_players) and ok
	ok = safe_access.set_global_int(globals.flow, data.values.launcher_apartment_flow) and ok
	ok = safe_access.set_global_int(globals.extra, data.values.launcher_apartment_extra) and ok
	ok = safe_access.set_local_int(
		cfg.scripts.launcher,
		cfg.locals.launcher_flags,
		data.values.launcher_apartment_extra
	) and ok
	ok = safe_access.set_global_int(globals.flags, data.values.launcher_apartment_flow) and ok
	return ok
end

function actions.maintain_solo_launch()
	local enabled = core_state.solo_launch.apartment and true or false
	local was_enabled = core_state.solo_launch_prev.apartment and true or false

	if not enabled and was_enabled then
		pcall(actions.solo_launch_reset)
	end

	core_state.solo_launch_prev.apartment = enabled
	if enabled and solo_launch_runtime.solo_launch_generic then
		return solo_launch_runtime.solo_launch_generic()
	end
	return true
end

function actions.skip_cutscene()
	return native_api.heist_skip_cutscene(text("feature.apartment.name"))
end

return actions
