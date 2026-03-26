-- Shared helpers and constants consumed by menu/runtime heist modules.

local heist_state = require("ShillenSilent_noclick_core.shared.heist_state")

local MPGlobal = 1574927

local CasinoGlobals = {
	Host = 1975557,
	P2 = 1975558,
	P3 = 1975559,
	P4 = 1975560,
	ReadyBase = 1977593,
}

local CutsValues = {
	host = 100,
	player2 = 0,
	player3 = 0,
	player4 = 0,
}

local SAFE_PAYOUT_TARGETS = {
	apartment = 3000000,
	cayo = 2550000,
	casino = 3619000,
	doomsday = 2550000,
}

local APARTMENT_CUT_PRESET_OPTIONS = {
	{ name = "All - 0%", value = 0 },
	{ name = "All - 25%", value = 25 },
	{ name = "All - 85%", value = 85 },
	{ name = "All - 100%", value = 100 },
}

local APARTMENT_HEIST_IDS = {
	fleeca = "hK5OgJk1BkinXGGXghhTMg",
	prison_break = "7-w96-PU4kSevhtG5YwUHQ",
	humane_labs = "BWsCWtmnvEWXBrprK9hDHA",
	series_a = "20Lu41Px20OJMPdZ6wXG3g",
	pacific_standard = "zCxFg29teE2ReKGnr0L4Bg",
}

local APARTMENT_HEIST_IDS_BY_INDEX = {
	[1] = APARTMENT_HEIST_IDS.fleeca,
	[2] = APARTMENT_HEIST_IDS.prison_break,
	[3] = APARTMENT_HEIST_IDS.humane_labs,
	[4] = APARTMENT_HEIST_IDS.series_a,
	[5] = APARTMENT_HEIST_IDS.pacific_standard,
}

local APARTMENT_PAYOUTS = {
	[APARTMENT_HEIST_IDS.fleeca] = { 100625, 201250, 251563 },
	[APARTMENT_HEIST_IDS.prison_break] = { 350000, 700000, 875000 },
	[APARTMENT_HEIST_IDS.humane_labs] = { 472500, 945000, 1181250 },
	[APARTMENT_HEIST_IDS.series_a] = { 353500, 707000, 883750 },
	[APARTMENT_HEIST_IDS.pacific_standard] = { 750000, 1500000, 1875000 },
}

local apartment_state = heist_state.apartment
local ApartmentCutsValues = apartment_state.cuts
local apartment_flags = apartment_state.flags
local apartment_refs = apartment_state.refs
local apartment_callbacks = apartment_state.callbacks

local function GetMP()
	local mp_idx = script.globals(MPGlobal).int32
	return mp_idx == 1 and "MP1_" or "MP0_"
end

local function hp_option_index_by_value(options, value, default_index)
	for i = 1, #options do
		if options[i].value == value then
			return i
		end
	end
	return default_index or 1
end

local function hp_set_stat_for_all_characters(stat_name, value)
	account.stats("MP0_" .. stat_name).int32 = value
	account.stats("MP1_" .. stat_name).int32 = value
end

local function hp_clamp_number(value, min_value, max_value)
	local number = tonumber(value)
	if not number then
		return min_value
	end
	if number < min_value then
		return min_value
	end
	if number > max_value then
		return max_value
	end
	return number
end

local function hp_clamp_cut_percent(value)
	return math.floor(hp_clamp_number(value, 0, 300))
end

local function hp_clamp_doomsday_cut_percent(value)
	return math.floor(hp_clamp_number(value, 0, 999))
end

local function hp_clamp_apartment_cut_percent(value)
	return math.floor(hp_clamp_number(value, 0, 3000))
end

local function hp_set_uniform_cuts(state_tbl, keys, sliders, cut, apply_fn)
	local value = hp_clamp_cut_percent(cut)

	for i = 1, 4 do
		local key = keys[i]
		if key then
			state_tbl[key] = value
		end

		local slider = sliders[i]
		if slider then
			slider.value = value
		end
	end

	if apply_fn then
		apply_fn()
	end

	return value
end

local function hp_get_apartment_heist_id()
	local stat = account.stats("HEIST_MISSION_RCONT_ID_1")
	local heist = ""

	if stat and type(stat.str) == "string" then
		heist = stat.str
	end
	if heist ~= "" then
		return heist
	end

	local legacy_index = (stat and stat.int32) or nil
	if legacy_index and APARTMENT_HEIST_IDS_BY_INDEX[legacy_index] then
		return APARTMENT_HEIST_IDS_BY_INDEX[legacy_index]
	end
	return nil
end

local function hp_is_apartment_fleeca()
	return hp_get_apartment_heist_id() == APARTMENT_HEIST_IDS.fleeca
end

local function hp_get_apartment_difficulty_index()
	local raw = script.globals(4718592 + 3538).int32 or 1
	local difficulty = math.floor(raw) + 1
	if difficulty < 1 then
		difficulty = 1
	end
	if difficulty > 3 then
		difficulty = 3
	end
	return difficulty
end

local function hp_get_apartment_max_payout_cut(double_rewards)
	local heist = hp_get_apartment_heist_id()
	local payout_by_heist = heist and APARTMENT_PAYOUTS[heist] or nil
	if not payout_by_heist then
		return nil, heist, nil
	end

	local difficulty = hp_get_apartment_difficulty_index()
	local payout = payout_by_heist[difficulty]
	if not payout then
		return nil, heist, difficulty
	end

	local divisor = (double_rewards and true or false) and 2 or 1
	local cut = math.floor((SAFE_PAYOUT_TARGETS.apartment * 100) / (payout * divisor))
	return hp_clamp_apartment_cut_percent(cut), heist, difficulty
end

local function hp_set_apartment_uniform_cuts(cut, apply_now)
	local value = hp_clamp_apartment_cut_percent(cut)
	ApartmentCutsValues.player1 = value
	ApartmentCutsValues.player2 = value
	ApartmentCutsValues.player3 = value
	ApartmentCutsValues.player4 = value

	if apartment_refs.p1_slider then
		apartment_refs.p1_slider.value = value
	end
	if apartment_refs.p2_slider then
		apartment_refs.p2_slider.value = value
	end
	if apartment_refs.p3_slider then
		apartment_refs.p3_slider.value = value
	end
	if apartment_refs.p4_slider then
		apartment_refs.p4_slider.value = value
	end

	if apply_now and type(apartment_callbacks.apply_cuts) == "function" then
		apartment_callbacks.apply_cuts()
	end

	return value
end

local function hp_apply_selected_apartment_cut_preset(apply_now)
	local preset_index = apartment_flags.cut_preset_index or #APARTMENT_CUT_PRESET_OPTIONS
	if preset_index < 1 then
		preset_index = 1
	end
	if preset_index > #APARTMENT_CUT_PRESET_OPTIONS then
		preset_index = #APARTMENT_CUT_PRESET_OPTIONS
	end

	local selected = APARTMENT_CUT_PRESET_OPTIONS[preset_index]
	local value = (selected and selected.value) or 100
	return hp_set_apartment_uniform_cuts(value, apply_now)
end

local apartment_max_payout_cache = {
	heist = nil,
	difficulty = nil,
	double = nil,
	cut = nil,
}

local function hp_refresh_apartment_max_payout(force_update, apply_now)
	if not apartment_flags.max_payout_enabled then
		apartment_max_payout_cache.heist = nil
		apartment_max_payout_cache.difficulty = nil
		apartment_max_payout_cache.double = nil
		apartment_max_payout_cache.cut = nil
		return false
	end

	local cut, heist, difficulty = hp_get_apartment_max_payout_cut(apartment_flags.double_rewards_week)
	if not cut then
		return false
	end

	local changed = force_update
		or apartment_max_payout_cache.heist ~= heist
		or apartment_max_payout_cache.difficulty ~= difficulty
		or apartment_max_payout_cache.double ~= apartment_flags.double_rewards_week
		or apartment_max_payout_cache.cut ~= cut

	if changed then
		hp_set_apartment_uniform_cuts(cut, apply_now)
		apartment_max_payout_cache.heist = heist
		apartment_max_payout_cache.difficulty = difficulty
		apartment_max_payout_cache.double = apartment_flags.double_rewards_week
		apartment_max_payout_cache.cut = cut
	end

	return changed
end

local presets = {
	CasinoGlobals = CasinoGlobals,
	CutsValues = CutsValues,
	SAFE_PAYOUT_TARGETS = SAFE_PAYOUT_TARGETS,
	APARTMENT_CUT_PRESET_OPTIONS = APARTMENT_CUT_PRESET_OPTIONS,
	GetMP = GetMP,
	hp_option_index_by_value = hp_option_index_by_value,
	hp_set_stat_for_all_characters = hp_set_stat_for_all_characters,
	hp_set_uniform_cuts = hp_set_uniform_cuts,
	hp_clamp_cut_percent = hp_clamp_cut_percent,
	hp_clamp_doomsday_cut_percent = hp_clamp_doomsday_cut_percent,
	hp_apply_selected_apartment_cut_preset = hp_apply_selected_apartment_cut_preset,
	hp_refresh_apartment_max_payout = hp_refresh_apartment_max_payout,
	hp_is_apartment_fleeca = hp_is_apartment_fleeca,
}

return presets
