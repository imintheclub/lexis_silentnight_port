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
				notify.push("Apartment Launch", "Could not force host", 2200)
			end
			return
		end
		util.yield(1000)

		local ok = true
		ok = set_global_int(ApartmentGlobals.Ready.PLAYER2, 6) and ok
		ok = set_global_int(ApartmentGlobals.Ready.PLAYER3, 6) and ok
		ok = set_global_int(ApartmentGlobals.Ready.PLAYER4, 6) and ok

		if notify then
			notify.push("Apartment Launch", ok and "All players ready" or "Force ready write failed", 2000)
		end
	end, function()
		if notify then
			notify.push("Apartment Launch", "Force ready already running", 1500)
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
		notify.push("Apartment Launch", ok and "Board refreshed" or "Board refresh failed", 2000)
	end
	return ok
end

local function apartment_complete_preps()
	local heist_key = get_current_apartment_heist_key()
	local heist_data = heist_key and APARTMENT_PREP_DATA[heist_key] or nil
	if not heist_data then
		if notify then
			notify.push("Apartment Preps", "Could not detect active Apartment heist", 2600)
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
		notify.push("Apartment Preps", ok and "Preps applied" or "Prep write failed", 2200)
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
		notify.push("Apartment Preps", ok and "Cooldown removed" or "Cooldown write failed", 2000)
	end
	return ok
end

local apartment_base = {
	ApartmentGlobals = ApartmentGlobals,
	apartment_force_ready = apartment_force_ready,
	apartment_redraw_board = apartment_redraw_board,
	apartment_complete_preps = apartment_complete_preps,
	apartment_kill_cooldown = apartment_kill_cooldown,
}

return apartment_base
