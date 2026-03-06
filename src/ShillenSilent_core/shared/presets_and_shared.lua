-- ---------------------------------------------------------
-- 6.5. Heist Functions (Casino)
-- ---------------------------------------------------------

-- Globals for Casino Heist
local CasinoGlobals = {
	Host = 1975557,
	P2 = 1975558,
	P3 = 1975559,
	P4 = 1975560,
	ReadyBase = 1977593,
}
local MPGlobal = 1574927

-- Cuts values storage
local CutsValues = {
	host = 100,
	player2 = 0,
	player3 = 0,
	player4 = 0,
}

-- GetMP function
local function GetMP()
	local mp_idx = script.globals(MPGlobal).int32
	return mp_idx == 1 and "MP1_" or "MP0_"
end

function hp_options_to_names(options)
	local names = {}
	for i = 1, #options do
		names[i] = options[i].name
	end
	return names
end

function hp_option_index_by_value(options, value, default_index)
	for i = 1, #options do
		if options[i].value == value then
			return i
		end
	end
	return default_index or 1
end

function hp_option_value_by_name(options, name, default_value)
	for i = 1, #options do
		if options[i].name == name then
			return options[i].value
		end
	end
	return default_value
end

function hp_option_names_range(options, first, last)
	local names = {}
	for i = first, last do
		if options[i] then
			names[#names + 1] = options[i].name
		end
	end
	return names
end

function hp_set_stat_for_all_characters(stat_name, value)
	account.stats("MP0_" .. stat_name).int32 = value
	account.stats("MP1_" .. stat_name).int32 = value
end

hp_keyboard_guard = nil

hp_heist_presets = {
	root = SHILLENSILENT_HEIST_PRESETS_DIR,
	apartment = {
		dir = "",
		name = "QuickPreset",
		options = { "(empty)" },
		selected = 1,
		dropdown = nil,
		name_label = nil,
	},
	cayo = {
		dir = "",
		name = "QuickPreset",
		options = { "(empty)" },
		selected = 1,
		dropdown = nil,
		name_label = nil,
	},
	casino = {
		dir = "",
		name = "QuickPreset",
		options = { "(empty)" },
		selected = 1,
		dropdown = nil,
		name_label = nil,
	},
	keyboard = { waiting = false, mode = nil },
}

hp_heist_presets.apartment.dir = hp_heist_presets.root .. "\\Apartment"
hp_heist_presets.cayo.dir = hp_heist_presets.root .. "\\CayoPerico"
hp_heist_presets.casino.dir = hp_heist_presets.root .. "\\DiamondCasino"

function hp_trim_text(text)
	if type(text) ~= "string" then
		return ""
	end
	local trimmed = text:gsub("^%s+", ""):gsub("%s+$", "")
	return trimmed
end

function hp_sanitize_preset_name(name)
	local clean = hp_trim_text(name)
	clean = clean:gsub('[<>:"/\\|%?%*]', "_")
	clean = clean:gsub("%.$", "")
	return clean
end

function hp_get_preset_state(mode)
	if mode == "apartment" then
		return hp_heist_presets.apartment
	end
	if mode == "cayo" then
		return hp_heist_presets.cayo
	end
	if mode == "casino" then
		return hp_heist_presets.casino
	end
	return nil
end

function hp_get_invoker_string(result)
	if not result then
		return ""
	end

	if type(result.str) == "string" and result.str ~= "" then
		return result.str
	end
	if type(result.ptr_string) == "string" and result.ptr_string ~= "" then
		return result.ptr_string
	end
	if type(result.as_str) == "string" and result.as_str ~= "" then
		return result.as_str
	end
	return ""
end

local function hp_notify_presets(message, duration)
	if notify then
		notify.push("Heist Presets", message, duration or 2000)
	end
end

function hp_update_preset_name_label(mode)
	local state_tbl = hp_get_preset_state(mode)
	if not state_tbl or not state_tbl.name_label then
		return
	end
	local shown_name = state_tbl.name
	if shown_name == nil or shown_name == "" then
		shown_name = "(not set)"
	end
	state_tbl.name_label.text = "Name: " .. shown_name
end

function hp_set_heist_preset_name_from_clipboard(mode)
	local state_tbl = hp_get_preset_state(mode)
	if not state_tbl then
		return false
	end

	local clip = input.get_clipboard_text()
	local clean = hp_sanitize_preset_name(clip)
	if clean == "" then
		hp_notify_presets("Clipboard is empty/invalid", 2000)
		return false
	end

	state_tbl.name = clean
	hp_update_preset_name_label(mode)
	hp_notify_presets("Name set: " .. clean, 2000)
	return true
end

function hp_find_option_index(option_names, selected_name, fallback)
	for i = 1, #option_names do
		if option_names[i] == selected_name then
			return i
		end
	end
	return fallback or 1
end

function hp_resolve_option_value(options, raw_value, fallback_value)
	local numeric = tonumber(raw_value)
	if numeric then
		local int_numeric = math.floor(numeric)
		local zero_based = options[int_numeric + 1]
		if zero_based then
			return zero_based.value
		end
		local one_based = options[int_numeric]
		if one_based then
			return one_based.value
		end
	end

	for i = 1, #options do
		local option_value = options[i].value
		if option_value == raw_value then
			return option_value
		end
		if numeric and type(option_value) == "number" and option_value == numeric then
			return option_value
		end
	end

	return fallback_value
end

local PRESET_SCHEMA_VERSION = 1
local PRESET_HEIST_MODE_TO_ID = {
	apartment = "apartment",
	cayo = "cayo_perico",
	casino = "diamond_casino",
}

local function hp_validate_heist_preset(mode, preps)
	if type(preps) ~= "table" then
		return false, "Invalid preset JSON"
	end

	local expected_heist = PRESET_HEIST_MODE_TO_ID[mode]
	if expected_heist and preps.heist ~= expected_heist then
		return false, "Preset/heist mismatch"
	end

	local schema = tonumber(preps.schema)
	if schema ~= PRESET_SCHEMA_VERSION then
		return false, "Unsupported preset schema"
	end

	return true, nil
end

function hp_get_zero_based_option_index(options, value, default_index)
	local idx = hp_option_index_by_value(options, value, default_index or 1)
	return idx - 1
end

function hp_clamp_number(value, min_value, max_value)
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

local function hp_read_player_cut(preps, player_key, legacy_key, fallback, clamp_fn)
	local player_tbl = preps[player_key]
	local value = fallback

	if type(player_tbl) == "table" and tonumber(player_tbl.cut) then
		value = tonumber(player_tbl.cut)
	elseif tonumber(preps[legacy_key]) then
		value = tonumber(preps[legacy_key])
	end

	if clamp_fn then
		return clamp_fn(value or 0)
	end

	return math.floor(tonumber(value) or 0)
end

local SAFE_PAYOUT_TARGETS = {
	apartment = 3000000,
	cayo = 2500000,
	casino = 3550000,
	doomsday = 2500000,
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

local APARTMENT_CUT_PRESET_OPTIONS = {
	{ name = "All - 0%", value = 0 },
	{ name = "All - 25%", value = 25 },
	{ name = "All - 85%", value = 85 },
	{ name = "All - 100%", value = 100 },
}

function hp_extract_preset_name(file_entry)
	local name = tostring(file_entry or "")
	name = name:gsub("/", "\\")
	name = name:match("([^\\]+)$") or name
	name = name:gsub("%.json$", "")
	return name
end

function hp_ensure_heist_preset_dirs()
	ensure_core_dirs()
	if not dirs.exists(hp_heist_presets.root) then
		dirs.create(hp_heist_presets.root)
	end
	if not dirs.exists(hp_heist_presets.apartment.dir) then
		dirs.create(hp_heist_presets.apartment.dir)
	end
	if not dirs.exists(hp_heist_presets.cayo.dir) then
		dirs.create(hp_heist_presets.cayo.dir)
	end
	if not dirs.exists(hp_heist_presets.casino.dir) then
		dirs.create(hp_heist_presets.casino.dir)
	end
end

function hp_refresh_heist_preset_files(mode, preferred_name)
	local state_tbl = hp_get_preset_state(mode)
	if not state_tbl then
		return
	end

	hp_ensure_heist_preset_dirs()
	local files = dirs.list(state_tbl.dir, ".json") or {}
	local names = {}
	local previous = preferred_name

	if not previous and state_tbl.options[state_tbl.selected] ~= "(empty)" then
		previous = state_tbl.options[state_tbl.selected]
	end

	for i = 1, #files do
		local extracted = hp_extract_preset_name(files[i])
		if extracted ~= "" then
			names[#names + 1] = extracted
		end
	end

	table.sort(names, function(a, b)
		return string.lower(a) < string.lower(b)
	end)

	if #names == 0 then
		names[1] = "(empty)"
	end

	state_tbl.options = names
	state_tbl.selected = hp_find_option_index(names, previous, 1)

	if state_tbl.dropdown then
		state_tbl.dropdown.options = names
		state_tbl.dropdown.value = state_tbl.selected
	end
end

function hp_get_selected_preset_name(mode)
	local state_tbl = hp_get_preset_state(mode)
	if not state_tbl then
		return nil
	end
	local selected = state_tbl.options[state_tbl.selected]
	if not selected or selected == "" or selected == "(empty)" then
		return nil
	end
	return selected
end

function hp_get_heist_preset_path(mode, preset_name)
	local state_tbl = hp_get_preset_state(mode)
	if not state_tbl then
		return nil
	end
	return state_tbl.dir .. "\\" .. preset_name .. ".json"
end

function hp_open_heist_preset_name_keyboard(mode)
	local state_tbl = hp_get_preset_state(mode)
	if not state_tbl then
		return
	end

	if hp_keyboard_guard then
		hp_notify_presets("Keyboard already in use", 2000)
		return
	end

	hp_keyboard_guard = "heist_presets"
	hp_heist_presets.keyboard.waiting = true
	hp_heist_presets.keyboard.mode = mode

	local default_name = state_tbl.name
	if default_name == nil then
		default_name = ""
	end

	native.display_onscreen_keyboard(6, "FMMC_KEY_TIP8", "", default_name, "", "", "", 64)
	hp_notify_presets("Enter preset name...", 2200)
end

util.create_thread(function()
	while true do
		util.yield(100)

		if hp_heist_presets.keyboard.waiting then
			local status = native.update_onscreen_keyboard()
			if status == 1 then
				local result = invoker.call(0x8362B09B91893647)
				local raw_name = hp_get_invoker_string(result)
				local mode = hp_heist_presets.keyboard.mode
				local state_tbl = hp_get_preset_state(mode)

				local clean_name = hp_sanitize_preset_name(raw_name)
				if state_tbl then
					if clean_name ~= "" then
						state_tbl.name = clean_name
						hp_update_preset_name_label(mode)
						hp_notify_presets("Name set: " .. clean_name, 2000)
					else
						hp_notify_presets("Preset name cannot be empty", 2000)
					end
				end

				hp_heist_presets.keyboard.waiting = false
				hp_heist_presets.keyboard.mode = nil
				hp_keyboard_guard = nil
			elseif status == 2 then
				hp_heist_presets.keyboard.waiting = false
				hp_heist_presets.keyboard.mode = nil
				hp_keyboard_guard = nil
				hp_notify_presets("Name entry canceled", 1500)
			end
		end
	end
end)

function hp_build_heist_preset_group(tab_ref, mode, heist_subtab, id_prefix)
	local state_tbl = hp_get_preset_state(mode)
	if not tab_ref or not state_tbl then
		return nil
	end

	local prefix = id_prefix or mode
	local group = ui.group(tab_ref, "Presets (JSON)", nil, nil, nil, nil, heist_subtab)
	state_tbl.name_label = ui.label(group, "Name: QuickPreset", config.colors.text_sec)

	ui.button(group, prefix .. "_preset_set_name", "Set Name From Keyboard", function()
		hp_open_heist_preset_name_keyboard(mode)
	end)
	ui.button(group, prefix .. "_preset_name_clip", "Set Name From Clipboard", function()
		hp_set_heist_preset_name_from_clipboard(mode)
	end)

	state_tbl.dropdown = ui.dropdown(
		group,
		prefix .. "_preset_file",
		"Preset File",
		state_tbl.options,
		state_tbl.selected,
		function(opt)
			state_tbl.selected = hp_find_option_index(state_tbl.options, opt, 1)
		end
	)

	ui.button_pair(
		group,
		prefix .. "_preset_save",
		"Save",
		function()
			hp_save_heist_preset(mode)
		end,
		prefix .. "_preset_load",
		"Load",
		function()
			hp_load_heist_preset(mode)
		end
	)
	ui.button_pair(
		group,
		prefix .. "_preset_remove",
		"Remove",
		function()
			hp_remove_heist_preset(mode)
		end,
		prefix .. "_preset_refresh",
		"Refresh",
		function()
			hp_refresh_heist_preset_files(mode)
		end
	)
	ui.button(group, prefix .. "_preset_copy", "Copy Folder Path", function()
		hp_copy_heist_preset_folder(mode)
	end)

	hp_update_preset_name_label(mode)
	hp_refresh_heist_preset_files(mode)
	return group
end

function hp_read_json_file(path)
	local ok, result = pcall(function()
		local handle = file.open(path, { append = false, create_if_not_exists = false })
		if not handle or not handle.valid then
			return nil
		end

		if handle.json ~= nil then
			local ok_decode, decoded = pcall(json.decode, handle.json)
			if ok_decode and type(decoded) == "table" then
				return decoded
			end

			if type(handle.json) == "table" then
				return handle.json
			end
		end

		if handle.text and handle.text ~= "" then
			local ok_decode_text, decoded_text = pcall(json.decode, handle.text)
			if ok_decode_text and type(decoded_text) == "table" then
				return decoded_text
			end
		end
		return nil
	end)

	if not ok then
		return nil
	end
	return result
end

function hp_write_json_file(path, content)
	local ok, err = pcall(function()
		local handle = file.open(path, { create_if_not_exists = true })
		if not handle or not handle.valid then
			error("Invalid file handle")
		end
		handle.json = json.encode(content)
	end)
	return ok, err
end

function hp_collect_cayo_preset_data()
	local preps = {
		schema = PRESET_SCHEMA_VERSION,
		heist = "cayo_perico",
		difficulty = hp_get_zero_based_option_index(CayoPrepOptions.difficulties, CayoConfig.diff, 1),
		approach = hp_get_zero_based_option_index(CayoPrepOptions.approaches, CayoConfig.app, 1),
		loadout = hp_get_zero_based_option_index(CayoPrepOptions.loadouts, CayoConfig.wep, 1),
		primary_target = hp_get_zero_based_option_index(CayoPrepOptions.primary_targets, CayoConfig.tgt, 1),
		compound_target = hp_get_zero_based_option_index(CayoPrepOptions.secondary_targets, CayoConfig.sec_comp, 1),
		compound_amount = hp_get_zero_based_option_index(CayoPrepOptions.compound_amounts, CayoConfig.amt_comp, 1),
		arts_amount = hp_get_zero_based_option_index(CayoPrepOptions.arts_amounts, CayoConfig.paint, 1),
		island_target = hp_get_zero_based_option_index(CayoPrepOptions.secondary_targets, CayoConfig.sec_isl, 1),
		island_amount = hp_get_zero_based_option_index(CayoPrepOptions.island_amounts, CayoConfig.amt_isl, 1),
		cash_value = CayoConfig.val_cash,
		weed_value = CayoConfig.val_weed,
		coke_value = CayoConfig.val_coke,
		gold_value = CayoConfig.val_gold,
		arts_value = CayoConfig.val_art,
		womans_bag = cayo_womans_bag_enabled and true or false,
		remove_crew_cuts = cayo_remove_crew_cuts_enabled and true or false,
		unlock_all_poi = CayoConfig.unlock_all_poi and true or false,
		player1 = { enabled = true, cut = CayoCutsValues.host },
		player2 = { enabled = (CayoCutsValues.player2 > 0), cut = CayoCutsValues.player2 },
		player3 = { enabled = (CayoCutsValues.player3 > 0), cut = CayoCutsValues.player3 },
		player4 = { enabled = (CayoCutsValues.player4 > 0), cut = CayoCutsValues.player4 },
	}
	return preps
end

function hp_apply_cayo_preset_data(preps)
	if type(preps) ~= "table" then
		return false
	end

	CayoConfig.diff = hp_resolve_option_value(CayoPrepOptions.difficulties, preps.difficulty, CayoConfig.diff)
	CayoConfig.app = hp_resolve_option_value(CayoPrepOptions.approaches, preps.approach, CayoConfig.app)
	CayoConfig.wep = hp_resolve_option_value(CayoPrepOptions.loadouts, preps.loadout, CayoConfig.wep)
	CayoConfig.tgt = hp_resolve_option_value(CayoPrepOptions.primary_targets, preps.primary_target, CayoConfig.tgt)
	CayoConfig.sec_comp =
		hp_resolve_option_value(CayoPrepOptions.secondary_targets, preps.compound_target, CayoConfig.sec_comp)
	CayoConfig.amt_comp =
		hp_resolve_option_value(CayoPrepOptions.compound_amounts, preps.compound_amount, CayoConfig.amt_comp)
	CayoConfig.paint = hp_resolve_option_value(CayoPrepOptions.arts_amounts, preps.arts_amount, CayoConfig.paint)
	CayoConfig.sec_isl =
		hp_resolve_option_value(CayoPrepOptions.secondary_targets, preps.island_target, CayoConfig.sec_isl)
	CayoConfig.amt_isl =
		hp_resolve_option_value(CayoPrepOptions.island_amounts, preps.island_amount, CayoConfig.amt_isl)

	if type(preps.unlock_all_poi) == "boolean" then
		CayoConfig.unlock_all_poi = preps.unlock_all_poi
	end
	if type(preps.womans_bag) == "boolean" then
		cayo_set_womans_bag(preps.womans_bag, true)
	end
	if type(preps.remove_crew_cuts) == "boolean" then
		cayo_set_remove_crew_cuts(preps.remove_crew_cuts, true)
	end

	if tonumber(preps.cash_value) then
		CayoConfig.val_cash = math.floor(tonumber(preps.cash_value))
	end
	if tonumber(preps.weed_value) then
		CayoConfig.val_weed = math.floor(tonumber(preps.weed_value))
	end
	if tonumber(preps.coke_value) then
		CayoConfig.val_coke = math.floor(tonumber(preps.coke_value))
	end
	if tonumber(preps.gold_value) then
		CayoConfig.val_gold = math.floor(tonumber(preps.gold_value))
	end
	if tonumber(preps.arts_value) then
		CayoConfig.val_art = math.floor(tonumber(preps.arts_value))
	end

	CayoCutsValues.host = hp_read_player_cut(preps, "player1", "host_cut", CayoCutsValues.host, hp_clamp_cut_percent)
	CayoCutsValues.player2 =
		hp_read_player_cut(preps, "player2", "player2_cut", CayoCutsValues.player2, hp_clamp_cut_percent)
	CayoCutsValues.player3 =
		hp_read_player_cut(preps, "player3", "player3_cut", CayoCutsValues.player3, hp_clamp_cut_percent)
	CayoCutsValues.player4 =
		hp_read_player_cut(preps, "player4", "player4_cut", CayoCutsValues.player4, hp_clamp_cut_percent)

	if cayoUnlockOnApplyToggle then
		cayoUnlockOnApplyToggle.state = CayoConfig.unlock_all_poi
	end
	if cayoDifficultyDropdown then
		cayoDifficultyDropdown.value = hp_option_index_by_value(CayoPrepOptions.difficulties, CayoConfig.diff, 1)
	end
	if cayoApproachDropdown then
		cayoApproachDropdown.value = hp_option_index_by_value(CayoPrepOptions.approaches, CayoConfig.app, 1)
	end
	if cayoLoadoutDropdown then
		cayoLoadoutDropdown.value = hp_option_index_by_value(CayoPrepOptions.loadouts, CayoConfig.wep, 1)
	end
	if cayoPrimaryTargetDropdown then
		cayoPrimaryTargetDropdown.value = hp_option_index_by_value(CayoPrepOptions.primary_targets, CayoConfig.tgt, 1)
	end
	if cayoCompoundTargetDropdown then
		cayoCompoundTargetDropdown.value =
			hp_option_index_by_value(CayoPrepOptions.secondary_targets, CayoConfig.sec_comp, 1)
	end
	if cayoCompoundAmountDropdown then
		cayoCompoundAmountDropdown.value =
			hp_option_index_by_value(CayoPrepOptions.compound_amounts, CayoConfig.amt_comp, 1)
	end
	if cayoArtsAmountDropdown then
		cayoArtsAmountDropdown.value = hp_option_index_by_value(CayoPrepOptions.arts_amounts, CayoConfig.paint, 1)
	end
	if cayoIslandTargetDropdown then
		cayoIslandTargetDropdown.value =
			hp_option_index_by_value(CayoPrepOptions.secondary_targets, CayoConfig.sec_isl, 1)
	end
	if cayoIslandAmountDropdown then
		cayoIslandAmountDropdown.value = hp_option_index_by_value(CayoPrepOptions.island_amounts, CayoConfig.amt_isl, 1)
	end
	if cayoCashValueSlider then
		cayoCashValueSlider.value = CayoConfig.val_cash
	end
	if cayoWeedValueSlider then
		cayoWeedValueSlider.value = CayoConfig.val_weed
	end
	if cayoCokeValueSlider then
		cayoCokeValueSlider.value = CayoConfig.val_coke
	end
	if cayoGoldValueSlider then
		cayoGoldValueSlider.value = CayoConfig.val_gold
	end
	if cayoArtValueSlider then
		cayoArtValueSlider.value = CayoConfig.val_art
	end
	if cayoWomansBagToggle then
		cayoWomansBagToggle.state = cayo_womans_bag_enabled
	end
	if cayoRemoveCrewCutsToggle then
		cayoRemoveCrewCutsToggle.state = cayo_remove_crew_cuts_enabled
	end
	if cayoHostSliderRef then
		cayoHostSliderRef.value = CayoCutsValues.host
	end
	if cayoP2SliderRef then
		cayoP2SliderRef.value = CayoCutsValues.player2
	end
	if cayoP3SliderRef then
		cayoP3SliderRef.value = CayoCutsValues.player3
	end
	if cayoP4SliderRef then
		cayoP4SliderRef.value = CayoCutsValues.player4
	end

	return true
end

function hp_collect_casino_preset_data()
	local preps = {
		schema = PRESET_SCHEMA_VERSION,
		heist = "diamond_casino",
		difficulty = hp_get_zero_based_option_index(CasinoPrepOptions.difficulties, CasinoManualPreps.difficulty, 1),
		approach = hp_get_zero_based_option_index(CasinoPrepOptions.approaches, CasinoManualPreps.approach, 1),
		gunman = hp_get_zero_based_option_index(CasinoPrepOptions.gunmen, CasinoManualPreps.crew_weapon, 1),
		driver = hp_get_zero_based_option_index(CasinoPrepOptions.drivers, CasinoManualPreps.crew_driver, 1),
		hacker = hp_get_zero_based_option_index(CasinoPrepOptions.hackers, CasinoManualPreps.crew_hacker, 1),
		masks = hp_get_zero_based_option_index(CasinoPrepOptions.masks, CasinoManualPreps.masks, 1),
		guards = hp_get_zero_based_option_index(CasinoPrepOptions.guards, CasinoManualPreps.disrupt_shipments, 1),
		keycards = hp_get_zero_based_option_index(CasinoPrepOptions.keycards, CasinoManualPreps.key_levels, 1),
		target = hp_get_zero_based_option_index(CasinoPrepOptions.targets, CasinoManualPreps.target, 1),
		loadout = CasinoManualPreps.loadout_slot - 1,
		vehicles = CasinoManualPreps.vehicle_slot - 1,
		unlock_all_poi = CasinoManualPreps.unlock_all_poi and true or false,
		solo_launch = state.solo_launch.casino and true or false,
		remove_crew_cuts = casino_remove_crew_cuts_enabled and true or false,
		autograbber = casino_autograbber_enabled and true or false,
		player1 = { enabled = true, cut = CutsValues.host },
		player2 = { enabled = (CutsValues.player2 > 0), cut = CutsValues.player2 },
		player3 = { enabled = (CutsValues.player3 > 0), cut = CutsValues.player3 },
		player4 = { enabled = (CutsValues.player4 > 0), cut = CutsValues.player4 },
	}
	return preps
end

function hp_apply_casino_preset_data(preps)
	if type(preps) ~= "table" then
		return false
	end

	CasinoManualPreps.difficulty =
		hp_resolve_option_value(CasinoPrepOptions.difficulties, preps.difficulty, CasinoManualPreps.difficulty)
	CasinoManualPreps.approach =
		hp_resolve_option_value(CasinoPrepOptions.approaches, preps.approach, CasinoManualPreps.approach)
	CasinoManualPreps.crew_weapon =
		hp_resolve_option_value(CasinoPrepOptions.gunmen, preps.gunman, CasinoManualPreps.crew_weapon)
	CasinoManualPreps.crew_driver =
		hp_resolve_option_value(CasinoPrepOptions.drivers, preps.driver, CasinoManualPreps.crew_driver)
	CasinoManualPreps.crew_hacker =
		hp_resolve_option_value(CasinoPrepOptions.hackers, preps.hacker, CasinoManualPreps.crew_hacker)
	CasinoManualPreps.masks = hp_resolve_option_value(CasinoPrepOptions.masks, preps.masks, CasinoManualPreps.masks)
	CasinoManualPreps.disrupt_shipments =
		hp_resolve_option_value(CasinoPrepOptions.guards, preps.guards, CasinoManualPreps.disrupt_shipments)
	CasinoManualPreps.key_levels =
		hp_resolve_option_value(CasinoPrepOptions.keycards, preps.keycards, CasinoManualPreps.key_levels)
	CasinoManualPreps.target =
		hp_resolve_option_value(CasinoPrepOptions.targets, preps.target, CasinoManualPreps.target)

	local loadout_slot = tonumber(preps.loadout)
	local vehicle_slot = tonumber(preps.vehicles)
	if loadout_slot then
		CasinoManualPreps.loadout_slot = math.floor(loadout_slot) + 1
	end
	if vehicle_slot then
		CasinoManualPreps.vehicle_slot = math.floor(vehicle_slot) + 1
	end

	if type(preps.unlock_all_poi) == "boolean" then
		CasinoManualPreps.unlock_all_poi = preps.unlock_all_poi
	end
	if type(preps.solo_launch) == "boolean" then
		state.solo_launch.casino = preps.solo_launch
	end
	if type(preps.remove_crew_cuts) == "boolean" then
		casino_set_remove_crew_cuts(preps.remove_crew_cuts, true)
	end
	if type(preps.autograbber) == "boolean" then
		casino_set_autograbber(preps.autograbber, true)
	end

	CutsValues.host = hp_read_player_cut(preps, "player1", "host_cut", CutsValues.host, hp_clamp_cut_percent)
	CutsValues.player2 = hp_read_player_cut(preps, "player2", "player2_cut", CutsValues.player2, hp_clamp_cut_percent)
	CutsValues.player3 = hp_read_player_cut(preps, "player3", "player3_cut", CutsValues.player3, hp_clamp_cut_percent)
	CutsValues.player4 = hp_read_player_cut(preps, "player4", "player4_cut", CutsValues.player4, hp_clamp_cut_percent)

	if manualDifficultyDropdown then
		manualDifficultyDropdown.value =
			hp_option_index_by_value(CasinoPrepOptions.difficulties, CasinoManualPreps.difficulty, 1)
	end
	if manualApproachDropdown then
		manualApproachDropdown.value =
			hp_option_index_by_value(CasinoPrepOptions.approaches, CasinoManualPreps.approach, 1)
	end
	if manualGunmanDropdown then
		manualGunmanDropdown.value =
			hp_option_index_by_value(CasinoPrepOptions.gunmen, CasinoManualPreps.crew_weapon, 1)
	end
	if manualDriverDropdown then
		manualDriverDropdown.value =
			hp_option_index_by_value(CasinoPrepOptions.drivers, CasinoManualPreps.crew_driver, 1)
	end
	if manualHackerDropdown then
		manualHackerDropdown.value =
			hp_option_index_by_value(CasinoPrepOptions.hackers, CasinoManualPreps.crew_hacker, 1)
	end
	if manualMasksDropdown then
		manualMasksDropdown.value = hp_option_index_by_value(CasinoPrepOptions.masks, CasinoManualPreps.masks, 1)
	end
	if manualGuardsDropdown then
		manualGuardsDropdown.value =
			hp_option_index_by_value(CasinoPrepOptions.guards, CasinoManualPreps.disrupt_shipments, 1)
	end
	if manualKeycardsDropdown then
		manualKeycardsDropdown.value =
			hp_option_index_by_value(CasinoPrepOptions.keycards, CasinoManualPreps.key_levels, 1)
	end
	if manualTargetDropdown then
		manualTargetDropdown.value = hp_option_index_by_value(CasinoPrepOptions.targets, CasinoManualPreps.target, 1)
	end
	if manualUnlockPoiToggle then
		manualUnlockPoiToggle.state = CasinoManualPreps.unlock_all_poi
	end
	if casinoSoloLaunchToggle then
		casinoSoloLaunchToggle.state = state.solo_launch.casino
	end
	if casinoRemoveCrewCutsToggle then
		casinoRemoveCrewCutsToggle.state = casino_remove_crew_cuts_enabled
	end
	if casinoAutograbberToggle then
		casinoAutograbberToggle.state = casino_autograbber_enabled
	end

	if manualLoadoutDropdown and manualVehiclesDropdown then
		hp_update_casino_loadout_dropdown(false)
		hp_update_casino_vehicle_dropdown(false)
		CasinoManualPreps.loadout_slot =
			hp_clamp_number(CasinoManualPreps.loadout_slot, 1, math.max(1, #manualLoadoutDropdown.options))
		CasinoManualPreps.vehicle_slot =
			hp_clamp_number(CasinoManualPreps.vehicle_slot, 1, math.max(1, #manualVehiclesDropdown.options))
		manualLoadoutDropdown.value = CasinoManualPreps.loadout_slot
		manualVehiclesDropdown.value = CasinoManualPreps.vehicle_slot
	end

	if casinoHostSliderRef then
		casinoHostSliderRef.value = CutsValues.host
	end
	if casinoP2SliderRef then
		casinoP2SliderRef.value = CutsValues.player2
	end
	if casinoP3SliderRef then
		casinoP3SliderRef.value = CutsValues.player3
	end
	if casinoP4SliderRef then
		casinoP4SliderRef.value = CutsValues.player4
	end

	return true
end

function hp_collect_apartment_preset_data()
	local cuts = ApartmentCutsValues or {}
	local preps = {
		schema = PRESET_SCHEMA_VERSION,
		heist = "apartment",
		solo_launch = state.solo_launch.apartment and true or false,
		bonus_12mil = apartment_bonus_enabled and true or false,
		double_rewards_week = apartment_double_rewards_week and true or false,
		max_payout = apartment_max_payout_enabled and true or false,
		preset = math.max(0, (apartment_cut_preset_index or 1) - 1),
		player1 = { enabled = true, cut = cuts.player1 or 0 },
		player2 = { enabled = ((cuts.player2 or 0) > 0), cut = cuts.player2 or 0 },
		player3 = { enabled = ((cuts.player3 or 0) > 0), cut = cuts.player3 or 0 },
		player4 = { enabled = ((cuts.player4 or 0) > 0), cut = cuts.player4 or 0 },
	}
	return preps
end

function hp_apply_apartment_preset_data(preps)
	if type(preps) ~= "table" then
		return false
	end

	if type(preps.solo_launch) == "boolean" then
		state.solo_launch.apartment = preps.solo_launch
	end

	local bonus = preps.bonus_12mil
	if type(bonus) ~= "boolean" and type(preps.bonus) == "boolean" then
		bonus = preps.bonus
	end
	if type(bonus) == "boolean" then
		if type(apartment_12mil_bonus) == "function" then
			apartment_12mil_bonus(bonus, true)
		else
			apartment_bonus_enabled = bonus
		end
	end

	if type(preps.double_rewards_week) == "boolean" then
		apartment_double_rewards_week = preps.double_rewards_week
	end
	if type(preps.max_payout) == "boolean" then
		apartment_max_payout_enabled = preps.max_payout
	end

	local preset = tonumber(preps.preset)
	if not preset then
		preset = tonumber(preps.presets)
	end
	if preset then
		apartment_cut_preset_index = math.floor(hp_clamp_number(preset + 1, 1, #APARTMENT_CUT_PRESET_OPTIONS))
	end

	ApartmentCutsValues.player1 =
		hp_read_player_cut(preps, "player1", "player1_cut", ApartmentCutsValues.player1, hp_clamp_cut_percent)
	ApartmentCutsValues.player2 =
		hp_read_player_cut(preps, "player2", "player2_cut", ApartmentCutsValues.player2, hp_clamp_cut_percent)
	ApartmentCutsValues.player3 =
		hp_read_player_cut(preps, "player3", "player3_cut", ApartmentCutsValues.player3, hp_clamp_cut_percent)
	ApartmentCutsValues.player4 =
		hp_read_player_cut(preps, "player4", "player4_cut", ApartmentCutsValues.player4, hp_clamp_cut_percent)

	if apartmentSoloLaunchToggle then
		apartmentSoloLaunchToggle.state = state.solo_launch.apartment
	end
	if apartmentBonusToggleRef then
		apartmentBonusToggleRef.state = apartment_bonus_enabled
	end
	if apartmentDoubleToggleRef then
		apartmentDoubleToggleRef.state = apartment_double_rewards_week
	end
	if apartmentMaxPayoutToggleRef then
		apartmentMaxPayoutToggleRef.state = apartment_max_payout_enabled
	end
	if apartmentPresetDropdownRef then
		apartmentPresetDropdownRef.value = apartment_cut_preset_index
	end

	if apartmentP1SliderRef then
		apartmentP1SliderRef.value = ApartmentCutsValues.player1
	end
	if apartmentP2SliderRef then
		apartmentP2SliderRef.value = ApartmentCutsValues.player2
	end
	if apartmentP3SliderRef then
		apartmentP3SliderRef.value = ApartmentCutsValues.player3
	end
	if apartmentP4SliderRef then
		apartmentP4SliderRef.value = ApartmentCutsValues.player4
	end

	if apartment_max_payout_enabled then
		hp_refresh_apartment_max_payout(true, false)
	end

	return true
end

local HP_PRESET_MODE_HANDLERS = {
	apartment = {
		collect = hp_collect_apartment_preset_data,
		apply = hp_apply_apartment_preset_data,
	},
	cayo = {
		collect = hp_collect_cayo_preset_data,
		apply = hp_apply_cayo_preset_data,
	},
	casino = {
		collect = hp_collect_casino_preset_data,
		apply = hp_apply_casino_preset_data,
	},
}

function hp_save_heist_preset(mode)
	local state_tbl = hp_get_preset_state(mode)
	if not state_tbl then
		return
	end

	local clean_name = hp_sanitize_preset_name(state_tbl.name)
	if clean_name == "" then
		hp_notify_presets("Failed to save. Name is empty.", 2200)
		return
	end

	hp_ensure_heist_preset_dirs()
	local path = hp_get_heist_preset_path(mode, clean_name)
	local handlers = HP_PRESET_MODE_HANDLERS[mode]
	if not handlers or type(handlers.collect) ~= "function" then
		hp_notify_presets("Unsupported preset mode", 2000)
		return
	end
	local content = handlers.collect()

	local ok = hp_write_json_file(path, content)
	if not ok then
		hp_notify_presets("Failed to save preset", 2200)
		return
	end

	state_tbl.name = ""
	hp_update_preset_name_label(mode)
	hp_refresh_heist_preset_files(mode, clean_name)
	hp_notify_presets("Saved: " .. clean_name, 2200)
end

function hp_load_heist_preset(mode)
	local selected = hp_get_selected_preset_name(mode)
	if not selected then
		hp_notify_presets("No preset selected", 2000)
		return
	end

	local path = hp_get_heist_preset_path(mode, selected)
	if not file.exists(path) then
		hp_notify_presets("Preset does not exist", 2000)
		hp_refresh_heist_preset_files(mode)
		return
	end

	local preps = hp_read_json_file(path)
	local ok_preset, err_message = hp_validate_heist_preset(mode, preps)
	if not ok_preset then
		hp_notify_presets(err_message or "Invalid preset JSON", 2200)
		return
	end

	local handlers = HP_PRESET_MODE_HANDLERS[mode]
	if not handlers or type(handlers.apply) ~= "function" then
		hp_notify_presets("Unsupported preset mode", 2000)
		return
	end
	local applied = handlers.apply(preps)

	if applied then
		hp_notify_presets("Loaded: " .. selected, 2200)
	else
		hp_notify_presets("Failed to apply preset", 2200)
	end
end

function hp_remove_heist_preset(mode)
	local selected = hp_get_selected_preset_name(mode)
	if not selected then
		hp_notify_presets("No preset selected", 2000)
		return
	end

	local path = hp_get_heist_preset_path(mode, selected)
	if not file.exists(path) then
		hp_notify_presets("Preset does not exist", 2000)
		hp_refresh_heist_preset_files(mode)
		return
	end

	local removed = file.remove(path)
	hp_refresh_heist_preset_files(mode)
	if removed then
		hp_notify_presets("Removed: " .. selected, 2000)
	else
		hp_notify_presets("Failed to remove preset", 2200)
	end
end

function hp_copy_heist_preset_folder(mode)
	local state_tbl = hp_get_preset_state(mode)
	if not state_tbl then
		return
	end
	hp_ensure_heist_preset_dirs()
	input.set_clipboard_text(state_tbl.dir)
	hp_notify_presets("Folder path copied", 2000)
end

apartment_bonus_enabled = false
apartment_double_rewards_week = false
apartment_max_payout_enabled = false
apartment_cut_preset_index = 4

apartmentP1SliderRef = nil
apartmentP2SliderRef = nil
apartmentP3SliderRef = nil
apartmentP4SliderRef = nil
apartmentBonusToggleRef = nil
apartmentDoubleToggleRef = nil
apartmentMaxPayoutToggleRef = nil
apartmentPresetDropdownRef = nil
apartmentSoloLaunchToggle = nil

local apartment_max_payout_cache = {
	heist = nil,
	difficulty = nil,
	double = nil,
	cut = nil,
}

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

function hp_is_apartment_fleeca()
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
	local payout = payout_by_heist[difficulty] or payout_by_heist[#payout_by_heist]
	if not payout or payout <= 0 then
		return nil, heist, difficulty
	end

	local divisor = (double_rewards and true or false) and 2 or 1
	local cut = math.floor(SAFE_PAYOUT_TARGETS.apartment / (payout / 100) / divisor)
	return hp_clamp_cut_percent(cut), heist, difficulty
end

function hp_set_apartment_uniform_cuts(cut, apply_now)
	if type(ApartmentCutsValues) ~= "table" then
		return hp_clamp_cut_percent(cut)
	end

	return hp_set_uniform_cuts(
		ApartmentCutsValues,
		{ "player1", "player2", "player3", "player4" },
		{ apartmentP1SliderRef, apartmentP2SliderRef, apartmentP3SliderRef, apartmentP4SliderRef },
		cut,
		(apply_now and type(apply_apartment_cuts) == "function") and apply_apartment_cuts or nil
	)
end

function hp_apply_selected_apartment_cut_preset(apply_now)
	local selected = APARTMENT_CUT_PRESET_OPTIONS[apartment_cut_preset_index]
		or APARTMENT_CUT_PRESET_OPTIONS[#APARTMENT_CUT_PRESET_OPTIONS]
	local value = selected and selected.value or 100
	return hp_set_apartment_uniform_cuts(value, apply_now)
end

function hp_refresh_apartment_max_payout(force_update, apply_now)
	if not apartment_max_payout_enabled then
		apartment_max_payout_cache.heist = nil
		apartment_max_payout_cache.difficulty = nil
		apartment_max_payout_cache.double = nil
		apartment_max_payout_cache.cut = nil
		return false
	end

	local cut, heist, difficulty = hp_get_apartment_max_payout_cut(apartment_double_rewards_week)
	if not cut then
		return false
	end

	local changed = force_update
		or apartment_max_payout_cache.heist ~= heist
		or apartment_max_payout_cache.difficulty ~= difficulty
		or apartment_max_payout_cache.double ~= apartment_double_rewards_week
		or apartment_max_payout_cache.cut ~= cut

	if changed then
		hp_set_apartment_uniform_cuts(cut, apply_now)
		apartment_max_payout_cache.heist = heist
		apartment_max_payout_cache.difficulty = difficulty
		apartment_max_payout_cache.double = apartment_double_rewards_week
		apartment_max_payout_cache.cut = cut
	end

	return changed
end

-- Apply cuts for Casino Heist
