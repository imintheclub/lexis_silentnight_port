-- ---------------------------------------------------------
-- 6.7. Apartment Heist Functions
-- ---------------------------------------------------------

local core = require("ShillenSilent_core.core.bootstrap")
local run_guarded_job = core.run_guarded_job

-- Apartment Globals
local ApartmentGlobals = {
	Ready = {
		PLAYER2 = 2659033,
		PLAYER3 = 2659501,
		PLAYER4 = 2659969,
	},
	Cooldown = {
		STEP1 = 1877303 + 1 + 76,
		STEP2 = 2635125 + 1,
	},
	Reload = {
		STEP1 = 2635124,
		STEP2 = 1937981 + 2768,
	},
	RootContent = {
		STEP1 = 1941591 + 10,
		STEP2 = 2635125 + 2,
		STEP3 = 1936048 + 1787,
	},
	WorldApartmentId = {
		EE = 1845299 + 1 + 260 + 37,
		LEGACY = 1845250 + 1 + 260 + 37,
	},
}

local APARTMENT_PREP_DATA = {
	fleeca = {
		rcont_ids = { -1072870761, "hK5OgJk1BkinXGGXghhTMg", "V7yEdnL6TEyU3i-U1Rv_pQ" },
		depth_lvs = { -1, 0, 1 },
		progress_hash = -836352461,
		reward_cosmetic = 25,
		root_content_id = "33TxqLipLUintwlU_YDzMg",
	},
	prison_break = {
		rcont_ids = {
			979654579,
			"7-w96-PU4kSevhtG5YwUHQ",
			"oSXhVwaHH0KDOzg0rfIj3Q",
			"QS6WYcjJFk2YxqYDMN8mjQ",
			"JJ9OzPbPo02eQbaniO8E3g",
		},
		depth_lvs = { -1, 0, 0, 0, 1 },
		progress_hash = 137052480,
		reward_cosmetic = 22,
		root_content_id = "A6UBSyF61kiveglc58lm2Q",
	},
	humane_labs = {
		rcont_ids = {
			-1096986654,
			"BWsCWtmnvEWXBrprK9hDHA",
			"6k6LOpnf2E-GG38OhjS-TA",
			"nSWwSwAf3EaHZWsk449lBg",
			"ciWN4gwmakid4lW-nSllcA",
			"v-8OOQYzxE-Zvqj5xO03DQ",
		},
		depth_lvs = { -1, 0, 0, 1, 2, 2 },
		progress_hash = 496643418,
		reward_cosmetic = 23,
		root_content_id = "a_hWnpMUz0-7Yd_Rc5pJ4w",
	},
	series_a = {
		rcont_ids = {
			164435858,
			"20Lu41Px20OJMPdZ6wXG3g",
			"6UzZkstFeEeCkvs2lrF_6A",
			"PPnsIR0v2U2COyRbED87gw",
			"z49DSS9db0i_vh6A2e-Q-g",
			"Fo168mMjCUCeN_IKmL4VnA",
		},
		depth_lvs = { -1, 0, 0, 0, 1, 2 },
		progress_hash = 1585746186,
		reward_cosmetic = 24,
		root_content_id = "7r5AKL5aB0qe9HiDy3nW8w",
	},
	pacific_standard = {
		rcont_ids = {
			-231973569,
			"zCxFg29teE2ReKGnr0L4Bg",
			"6ClY8ZA_DkuBUdZ_fPn6Rw",
			"OiSO3Z0YdkCaEqVHhhkj4Q",
			"Cy2OZSwCt0-mSXY00o4SNw",
			"Y4zpRQDfvkawfFDR1Uxi2A",
		},
		depth_lvs = { -1, 0, 1, 2, 2, 2 },
		progress_hash = 911181645,
		reward_cosmetic = 21,
		root_content_id = "hKSf9RCT8UiaZlykyGrMwg",
	},
}

local APARTMENT_HEIST_IDS = {
	hK5OgJk1BkinXGGXghhTMg = "fleeca",
	["7-w96-PU4kSevhtG5YwUHQ"] = "prison_break",
	BWsCWtmnvEWXBrprK9hDHA = "humane_labs",
	["20Lu41Px20OJMPdZ6wXG3g"] = "series_a",
	zCxFg29teE2ReKGnr0L4Bg = "pacific_standard",
}

local APARTMENT_HEIST_PROGRESS_HASH_TO_KEY = {
	[-836352461] = "fleeca",
	[137052480] = "prison_break",
	[496643418] = "humane_labs",
	[1585746186] = "series_a",
	[911181645] = "pacific_standard",
}

local function is_script_running(script_name)
	local ok, result = pcall(script.running, script_name)
	return ok and result and true or false
end

local function force_script_host(script_name)
	local ok, result = pcall(script.force_host, script_name)
	return ok and result and true or false
end

local function set_global_int(offset, value)
	local ok = pcall(function()
		script.globals(offset).int32 = value
	end)
	return ok
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

local function get_global_int(offset, fallback)
	local ok, value = pcall(function()
		return script.globals(offset).int32
	end)
	if ok and value ~= nil then
		return value
	end
	return fallback
end

local function set_global_string(offset, value)
	local ok = pcall(function()
		script.globals(offset).str = value
	end)
	if ok then
		return true
	end
	return pcall(function()
		script.globals(offset).string = value
	end)
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

local function set_stat_string(stat_name, value)
	local ok = pcall(function()
		local stat = account.stats(stat_name)
		if not stat then
			error("missing stat")
		end
		stat.str = value
	end)
	if ok then
		return true
	end
	return pcall(function()
		local stat = account.stats(stat_name)
		if not stat then
			error("missing stat")
		end
		stat.string = value
	end)
end

local function get_stat_string(stat_name, fallback)
	local ok, value = pcall(function()
		local stat = account.stats(stat_name)
		if not stat then
			return nil
		end
		if type(stat.str) == "string" and stat.str ~= "" then
			return stat.str
		end
		if type(stat.string) == "string" and stat.string ~= "" then
			return stat.string
		end
		return nil
	end)
	if ok and value ~= nil then
		return value
	end
	return fallback
end

local function read_apartment_heist_key_from_stat(stat_name)
	local heist_id = get_stat_string(stat_name, nil)
	if heist_id and APARTMENT_HEIST_IDS[heist_id] then
		return APARTMENT_HEIST_IDS[heist_id]
	end

	local value = get_stat_int(stat_name, nil)
	for key, data in pairs(APARTMENT_PREP_DATA) do
		if data.rcont_ids[1] == value then
			return key
		end
	end

	return nil
end

local function get_current_apartment_heist_key()
	local by_stat1 = read_apartment_heist_key_from_stat("HEIST_MISSION_RCONT_ID_1")
	if by_stat1 then
		return by_stat1
	end

	local by_stat0 = read_apartment_heist_key_from_stat("HEIST_MISSION_RCONT_ID_0")
	if by_stat0 then
		return by_stat0
	end

	local progress_hash = get_stat_int("MPPLY_HEIST_PROGRESS_HASH", nil)
	if progress_hash and APARTMENT_HEIST_PROGRESS_HASH_TO_KEY[progress_hash] then
		return APARTMENT_HEIST_PROGRESS_HASH_TO_KEY[progress_hash]
	end

	return nil
end

local function get_world_apartment_id()
	local player_id = (players and players.user and players.user()) or 0
	local ee_global = ApartmentGlobals.WorldApartmentId.EE + (player_id * 883)
	local legacy_global = ApartmentGlobals.WorldApartmentId.LEGACY + (player_id * 880)

	local id = get_global_int(ee_global, nil)
	if id ~= nil then
		return id
	end

	id = get_global_int(legacy_global, nil)
	if id ~= nil then
		return id
	end

	return get_stat_int("PROPERTY_HOUSE", 0) or 0
end

-- Apartment Force Ready
local function apartment_force_ready()
	return run_guarded_job("apartment_force_ready", function()
		if not is_script_running("fm_mission_controller") then
			if notify then
				notify.push("Apartment Launch", "fm_mission_controller is not running", 2200)
			end
			return
		end
		if not force_script_host("fm_mission_controller") then
			if notify then
				notify.push("Apartment Launch", "Instant finish failed (host override)", 2200)
			end
			return
		end
		util.yield(1000)

		local ok = true
		ok = set_global_int(ApartmentGlobals.Ready.PLAYER2, 6) and ok
		ok = set_global_int(ApartmentGlobals.Ready.PLAYER3, 6) and ok
		ok = set_global_int(ApartmentGlobals.Ready.PLAYER4, 6) and ok

		if notify then
			notify.push("Apartment Launch", ok and "Force ready completed" or "Force ready failed to apply", 2000)
		end
	end, function()
		if notify then
			notify.push("Apartment Launch", "Force ready failed (already running)", 1500)
		end
	end)
end

local function apartment_redraw_board()
	local ok = true
	ok = set_global_int(ApartmentGlobals.Reload.STEP1, 0) and ok
	util.yield(1000)
	ok = set_global_int(ApartmentGlobals.Reload.STEP1, 5) and ok
	ok = set_global_int(ApartmentGlobals.Reload.STEP2, 10) and ok

	if notify then
		notify.push("Apartment Launch", ok and "Board refresh completed" or "Board refresh failed to apply", 2000)
	end
	return ok
end

local function apartment_complete_preps()
	local heist_key = get_current_apartment_heist_key()
	local heist_data = heist_key and APARTMENT_PREP_DATA[heist_key] or nil
	if not heist_data then
		if notify then
			notify.push("Apartment Preps", "Preps failed (no active heist detected)", 2600)
		end
		return false
	end

	local ok = true
	ok = set_stat_int("HEIST_PLANNING_STAGE", -1) and ok
	ok = set_stat_int("BITSET_HEIST_VS_MISSIONS", -17809409) and ok
	ok = set_stat_int("HEIST_SESSION_ID_MACADDR", 183381814) and ok
	ok = set_stat_int("HEIST_LEADER_APART_ID", get_world_apartment_id()) and ok
	ok = set_stat_int("MPPLY_HEIST_PROGRESS_HASH", heist_data.progress_hash) and ok
	ok = set_stat_int("HEIST_TOTAL_REWARD_COSMETIC", heist_data.reward_cosmetic) and ok

	for i = 0, 7 do
		local rcont_value = heist_data.rcont_ids[i + 1]
		if i == 0 then
			ok = set_stat_int("HEIST_MISSION_RCONT_ID_0", math.floor(tonumber(rcont_value) or 0)) and ok
		else
			ok = set_stat_string("HEIST_MISSION_RCONT_ID_" .. tostring(i), rcont_value and tostring(rcont_value) or "")
				and ok
		end
		ok = set_stat_int("HEIST_MISSION_DEPTH_LV_" .. tostring(i), heist_data.depth_lvs[i + 1] or -1) and ok
	end

	ok = set_global_string(ApartmentGlobals.RootContent.STEP1, heist_data.root_content_id) and ok
	ok = set_global_string(ApartmentGlobals.RootContent.STEP2, heist_data.root_content_id) and ok
	ok = set_global_string(ApartmentGlobals.RootContent.STEP3, heist_data.root_content_id) and ok

	ok = set_global_int(ApartmentGlobals.Cooldown.STEP1, 1) and ok
	ok = set_global_int(ApartmentGlobals.Cooldown.STEP2, 0) and ok

	ok = apartment_redraw_board() and ok

	if notify then
		notify.push("Apartment Preps", ok and "Preps completed" or "Preps failed to apply", 2200)
	end
	return ok
end

local function apartment_kill_cooldown()
	local player_id = (players and players.user and players.user()) or 0
	local cooldown_step1 = ApartmentGlobals.Cooldown.STEP1 + (player_id * 77)
	local ok = true
	ok = set_global_int(cooldown_step1, -1) and ok
	ok = set_global_int(ApartmentGlobals.Cooldown.STEP2, 0) and ok
	if notify then
		notify.push("Apartment Preps", ok and "Cooldown removal completed" or "Cooldown removal failed to apply", 2000)
	end
	return ok
end

local function apartment_fleeca_hack()
	if is_script_running("fm_mission_controller") then
		local ok = set_local_int("fm_mission_controller", 12223 + 24, 7)
		if notify then
			notify.push("Apartment Tools", ok and "Fleeca hack completed" or "Fleeca hack failed to apply", 2000)
		end
		return ok
	end

	if notify then
		notify.push("Apartment Tools", "Hack not active", 2000)
	end
	return false
end

local function apartment_fleeca_drill()
	if is_script_running("fm_mission_controller") then
		local ok = set_local_float("fm_mission_controller", 10511 + 11, 100.0)
		if notify then
			notify.push("Apartment Tools", ok and "Fleeca drill completed" or "Fleeca drill failed to apply", 2000)
		end
		return ok
	end

	if notify then
		notify.push("Apartment Tools", "Drill not active", 2000)
	end
	return false
end

local function apartment_pacific_hack()
	if is_script_running("fm_mission_controller") then
		local ok = set_local_int("fm_mission_controller", 10217, 9)
		if notify then
			notify.push("Apartment Tools", ok and "Pacific hack completed" or "Pacific hack failed to apply", 2000)
		end
		return ok
	end

	if notify then
		notify.push("Apartment Tools", "Hack not active", 2000)
	end
	return false
end

local function apartment_instant_finish_pacific()
	return run_guarded_job("apartment_instant_finish_pacific", function()
		if not is_script_running("fm_mission_controller") then
			if notify then
				notify.push("Apartment", "fm_mission_controller is not running", 2000)
			end
			return
		end
		if not force_script_host("fm_mission_controller") then
			if notify then
				notify.push("Apartment", "Instant finish failed (host override)", 2000)
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
			notify.push("Apartment", "Instant finish failed (already running)", 1500)
		end
	end)
end

local function apartment_instant_finish_other()
	return run_guarded_job("apartment_instant_finish_other", function()
		if not is_script_running("fm_mission_controller") then
			if notify then
				notify.push("Apartment", "fm_mission_controller is not running", 2000)
			end
			return
		end
		if not force_script_host("fm_mission_controller") then
			if notify then
				notify.push("Apartment", "Instant finish failed (host override)", 2000)
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
			notify.push("Apartment", "Instant finish failed (already running)", 1500)
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
		notify.push("Apartment Tools", ok and "All jobs unlock completed" or "Jobs unlock failed", 2000)
	end
	return ok
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
			notify.push("Apartment Tools", "Session change failed", 2800)
		end
	end

	return started
end

local function normalize_hash(value)
	local numeric = tonumber(value)
	if not numeric or numeric == 0 then
		return nil
	end
	return math.floor(numeric)
end

local function resolve_root_hash(tunable_name, fallback_text)
	local ok_tunable, tunable_hash = pcall(function()
		local tunable = script.tunables(tunable_name)
		if not tunable then
			return nil
		end
		return tunable.int32
	end)
	if ok_tunable then
		local value = normalize_hash(tunable_hash)
		if value then
			return value
		end
	end

	local ok_joaat, joaat_hash = pcall(function()
		if type(joaat) ~= "function" then
			return nil
		end
		return joaat(fallback_text)
	end)
	if ok_joaat then
		local value = normalize_hash(joaat_hash)
		if value then
			return value
		end
	end

	local ok_native, native_hash = pcall(function()
		local hashed = invoker.call(0xD24D37CC275948CC, fallback_text) -- GET_HASH_KEY
		if type(hashed) == "number" then
			return hashed
		end
		if type(hashed) == "table" then
			return hashed.int32 or hashed.int or hashed.uint or hashed.u32 or hashed.hash
		end
		return nil
	end)
	if ok_native then
		local value = normalize_hash(native_hash)
		if value then
			return value
		end
	end

	return nil
end

local function apartment_unlock_all_jobs(mp_prefix)
	local p = tostring(mp_prefix or "")
	local root_defs = {
		{ tunable = "ROOT_ID_HASH_THE_FLECCA_JOB", fallback = "33TxqLipLUintwlU_YDzMg" },
		{ tunable = "ROOT_ID_HASH_THE_PRISON_BREAK", fallback = "A6UBSyF61kiveglc58lm2Q" },
		{ tunable = "ROOT_ID_HASH_THE_HUMANE_LABS_RAID", fallback = "a_hWnpMUz0-7Yd_Rc5pJ4w" },
		{ tunable = "ROOT_ID_HASH_SERIES_A_FUNDING", fallback = "7r5AKL5aB0qe9HiDy3nW8w" },
		{ tunable = "ROOT_ID_HASH_THE_PACIFIC_STANDARD_JOB", fallback = "hKSf9RCT8UiaZlykyGrMwg" },
	}

	local root_hashes = {}
	for i = 1, #root_defs do
		local root_hash = resolve_root_hash(root_defs[i].tunable, root_defs[i].fallback)
		if not root_hash then
			if notify then
				notify.push("Apartment Tools", "Unlock failed (invalid root hash). No stats written.", 2600)
			end
			return false
		end
		root_hashes[i] = root_hash
	end

	local ok_all = true
	for i = 0, 4 do
		local strand_ok = set_stat_int(p .. "HEIST_SAVED_STRAND_" .. i, root_hashes[i + 1])
		local depth_ok = set_stat_int(p .. "HEIST_SAVED_STRAND_" .. i .. "_L", 5)
		ok_all = strand_ok and depth_ok and ok_all
	end

	local board_ok = set_global_int(ApartmentGlobals.Reload.STEP2, 22)
	ok_all = board_ok and ok_all
	local redraw_ok = apartment_redraw_board()
	ok_all = redraw_ok and ok_all

	if notify then
		notify.push(
			"Apartment Tools",
			ok_all and "All jobs unlocked. Change session to apply." or "Unlock-all partial failure",
			2600
		)
	end
	return ok_all
end

local function apartment_apply_cuts(cuts_values)
	if type(cuts_values) ~= "table" then
		if notify then
			notify.push("Apartment Cuts", "Cuts failed to apply", 2000)
		end
		return false
	end

	local p1 = math.floor(tonumber(cuts_values.player1) or 0)
	local p2 = math.floor(tonumber(cuts_values.player2) or 0)
	local p3 = math.floor(tonumber(cuts_values.player3) or 0)
	local p4 = math.floor(tonumber(cuts_values.player4) or 0)
	local base_pairs = {
		{ global_base = 1936013, local_base = 1937981 },
		{ global_base = 1935536, local_base = 1937504 },
	}
	local total_cut = p1 + p2 + p3 + p4
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

		pair_ok = set_global_int(pair.global_base + 1 + 2, p2) and pair_ok
		pair_ok = set_global_int(pair.global_base + 1 + 3, p3) and pair_ok
		pair_ok = set_global_int(pair.global_base + 1 + 4, p4) and pair_ok

		pair_ok = set_global_int(pair.local_base + 3008 + 1, p1) and pair_ok
		pair_ok = set_global_int(pair.local_base + 3008 + 2, p2) and pair_ok
		pair_ok = set_global_int(pair.local_base + 3008 + 3, p3) and pair_ok
		pair_ok = set_global_int(pair.local_base + 3008 + 4, p4) and pair_ok

		any_pair_ok = any_pair_ok or pair_ok
	end

	if notify then
		notify.push("Apartment Cuts", any_pair_ok and "Cuts completed" or "Cuts failed to apply", 2000)
	end
	return any_pair_ok
end

local function apartment_set_12mil_bonus(enable, silent)
	local ok = true
	if enable then
		ok = set_stat_int("MPPLY_HEISTFLOWORDERPROGRESS", 268435455) and ok
		ok = set_stat_bool("MPPLY_AWD_HST_ORDER", false) and ok
		ok = set_stat_int("MPPLY_HEISTTEAMPROGRESSBITSET", 268435455) and ok
		ok = set_stat_bool("MPPLY_AWD_HST_SAME_TEAM", false) and ok
		ok = set_stat_int("MPPLY_HEISTNODEATHPROGREITSET", 268435455) and ok
		ok = set_stat_bool("MPPLY_AWD_HST_ULT_CHAL", false) and ok
		if not silent and notify then
			notify.push("Apartment Bonuses", ok and "12M bonus enabled" or "12M bonus failed to apply", 2000)
		end
	else
		ok = set_stat_int("MPPLY_HEISTFLOWORDERPROGRESS", 134217727) and ok
		ok = set_stat_bool("MPPLY_AWD_HST_ORDER", true) and ok
		ok = set_stat_int("MPPLY_HEISTTEAMPROGRESSBITSET", 134217727) and ok
		ok = set_stat_bool("MPPLY_AWD_HST_SAME_TEAM", true) and ok
		ok = set_stat_int("MPPLY_HEISTNODEATHPROGREITSET", 134217727) and ok
		ok = set_stat_bool("MPPLY_AWD_HST_ULT_CHAL", true) and ok
		if not silent and notify then
			notify.push("Apartment Bonuses", ok and "12M bonus disabled" or "12M bonus failed to apply", 2000)
		end
	end
	return ok
end

local apartment_base = {
	ApartmentGlobals = ApartmentGlobals,
	apartment_force_ready = apartment_force_ready,
	apartment_redraw_board = apartment_redraw_board,
	apartment_complete_preps = apartment_complete_preps,
	apartment_kill_cooldown = apartment_kill_cooldown,
	apartment_fleeca_hack = apartment_fleeca_hack,
	apartment_fleeca_drill = apartment_fleeca_drill,
	apartment_pacific_hack = apartment_pacific_hack,
	apartment_instant_finish_pacific = apartment_instant_finish_pacific,
	apartment_instant_finish_other = apartment_instant_finish_other,
	apartment_play_unavailable = apartment_play_unavailable,
	apartment_change_session = apartment_change_session,
	apartment_unlock_all_jobs = apartment_unlock_all_jobs,
	apartment_apply_cuts = apartment_apply_cuts,
	apartment_set_12mil_bonus = apartment_set_12mil_bonus,
}

return apartment_base
