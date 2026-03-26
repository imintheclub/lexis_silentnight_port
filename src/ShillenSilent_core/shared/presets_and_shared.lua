-- ---------------------------------------------------------
-- 6.5. Heist Functions (Casino)
-- ---------------------------------------------------------

local core = require("ShillenSilent_core.core.bootstrap")
local ui = require("ShillenSilent_core.core.ui")
local safe_access = require("ShillenSilent_core.core.safe_access")
local heist_state = require("ShillenSilent_core.shared.heist_state")
local native = core.native
local config = core.config
local state = core.state
local ensure_core_dirs = core.ensure_core_dirs
local SHILLENSILENT_HEIST_PRESETS_DIR = core.SHILLENSILENT_HEIST_PRESETS_DIR

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

local cayo_state = heist_state.cayo
local CayoPrepOptions = cayo_state.prep_options
local CayoConfig = cayo_state.config
local CayoCutsValues = cayo_state.cuts
local cayo_flags = cayo_state.flags
local cayo_refs = cayo_state.refs
local cayo_callbacks = cayo_state.callbacks

local casino_state = heist_state.casino
local CasinoPrepOptions = casino_state.prep_options
local CasinoManualPreps = casino_state.manual_preps
local casino_flags = casino_state.flags
local casino_refs = casino_state.refs
local casino_callbacks = casino_state.callbacks

local apartment_state = heist_state.apartment
local ApartmentCutsValues = apartment_state.cuts
local apartment_flags = apartment_state.flags
local apartment_refs = apartment_state.refs
local apartment_callbacks = apartment_state.callbacks

local doomsday_state = heist_state.doomsday
local doomsday_config = doomsday_state.config
local doomsday_cuts = doomsday_state.cuts
local doomsday_cut_enabled = doomsday_state.cut_enabled
local doomsday_flags = doomsday_state.flags
local doomsday_refs = doomsday_state.refs
local doomsday_callbacks = doomsday_state.callbacks

local agency_state = heist_state.agency
local AgencyPrepOptions = agency_state.prep_options
local AgencyConfig = agency_state.config
local agency_refs = agency_state.refs

local autoshop_state = heist_state.autoshop
local AutoshopPrepOptions = autoshop_state.prep_options
local AutoshopConfig = autoshop_state.config
local autoshop_refs = autoshop_state.refs

local salvageyard_state = heist_state.salvageyard
local SalvagePrepOptions = salvageyard_state.prep_options
local SalvageConfig = salvageyard_state.config
local salvage_flags = salvageyard_state.flags
local salvage_refs = salvageyard_state.refs
local salvage_callbacks = salvageyard_state.callbacks

-- GetMP function
local function GetMP()
	local mp_idx = script.globals(MPGlobal).int32
	return mp_idx == 1 and "MP1_" or "MP0_"
end

local function hp_options_to_names(options)
	local names = {}
	for i = 1, #options do
		names[i] = options[i].name
	end
	return names
end

local function hp_option_index_by_value(options, value, default_index)
	for i = 1, #options do
		if options[i].value == value then
			return i
		end
	end
	return default_index or 1
end

local function hp_option_value_by_name(options, name, default_value)
	for i = 1, #options do
		if options[i].name == name then
			return options[i].value
		end
	end
	return default_value
end

local function hp_option_names_range(options, first, last)
	local names = {}
	for i = first, last do
		if options[i] then
			names[#names + 1] = options[i].name
		end
	end
	return names
end

local function hp_set_stat_for_all_characters(stat_name, value)
	account.stats("MP0_" .. stat_name).int32 = value
	account.stats("MP1_" .. stat_name).int32 = value
end

local function hp_apply_casino_manual_preps(preps, opts)
	if type(preps) ~= "table" then
		return false
	end

	local options = (type(opts) == "table") and opts or {}
	local should_notify = (options.notify == nil) and true or (options.notify and true or false)
	local notify_title = options.notify_title or "Casino Manual Preps"
	local notify_message = options.notify_message or "Preps applied"
	local notify_duration = tonumber(options.notify_duration) or 2000

	if preps.unlock_all_poi then
		hp_set_stat_for_all_characters("H3OPT_POI", -1)
		hp_set_stat_for_all_characters("H3OPT_ACCESSPOINTS", -1)
		hp_set_stat_for_all_characters("CAS_HEIST_NOTS", -1)
		hp_set_stat_for_all_characters("CAS_HEIST_FLOW", -1)
	end

	hp_set_stat_for_all_characters("H3_LAST_APPROACH", 0)
	hp_set_stat_for_all_characters("H3_HARD_APPROACH", (preps.difficulty == 0) and 0 or preps.approach)
	hp_set_stat_for_all_characters("H3OPT_APPROACH", preps.approach)
	hp_set_stat_for_all_characters("H3OPT_CREWWEAP", preps.crew_weapon)
	hp_set_stat_for_all_characters("H3OPT_WEAPS", (tonumber(preps.loadout_slot) or 1) - 1)
	hp_set_stat_for_all_characters("H3OPT_CREWDRIVER", preps.crew_driver)
	hp_set_stat_for_all_characters("H3OPT_VEHS", (tonumber(preps.vehicle_slot) or 1) - 1)
	hp_set_stat_for_all_characters("H3OPT_CREWHACKER", preps.crew_hacker)
	hp_set_stat_for_all_characters("H3OPT_TARGET", preps.target)
	hp_set_stat_for_all_characters("H3OPT_MASKS", preps.masks)
	hp_set_stat_for_all_characters("H3OPT_DISRUPTSHIP", preps.disrupt_shipments)
	hp_set_stat_for_all_characters("H3OPT_KEYLEVELS", preps.key_levels)
	hp_set_stat_for_all_characters("H3OPT_BODYARMORLVL", -1)
	hp_set_stat_for_all_characters("H3OPT_BITSET0", -1)
	hp_set_stat_for_all_characters("H3OPT_BITSET1", -1)
	hp_set_stat_for_all_characters("H3OPT_COMPLETEDPOSIX", -1)

	safe_access.set_local_int("gb_casino_heist_planning", 210, 2)
	safe_access.set_local_int("gb_casino_heist_planning", 212, 2)

	if should_notify and notify then
		notify.push(notify_title, notify_message, notify_duration)
	end
	return true
end

local hp_keyboard_guard = nil

local hp_heist_presets = {
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
	doomsday = {
		dir = "",
		name = "QuickPreset",
		options = { "(empty)" },
		selected = 1,
		dropdown = nil,
		name_label = nil,
	},
	agency = {
		dir = "",
		name = "QuickPreset",
		options = { "(empty)" },
		selected = 1,
		dropdown = nil,
		name_label = nil,
	},
	autoshop = {
		dir = "",
		name = "QuickPreset",
		options = { "(empty)" },
		selected = 1,
		dropdown = nil,
		name_label = nil,
	},
	salvageyard = {
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
hp_heist_presets.doomsday.dir = hp_heist_presets.root .. "\\Doomsday"
hp_heist_presets.agency.dir = hp_heist_presets.root .. "\\Agency"
hp_heist_presets.autoshop.dir = hp_heist_presets.root .. "\\AutoShop"
hp_heist_presets.salvageyard.dir = hp_heist_presets.root .. "\\SalvageYard"

-- Forward declarations for functions referenced before their definitions.
local hp_save_heist_preset
local hp_load_heist_preset
local hp_remove_heist_preset
local hp_copy_heist_preset_folder
local hp_refresh_apartment_max_payout

local function hp_trim_text(text)
	if type(text) ~= "string" then
		return ""
	end
	local trimmed = text:gsub("^%s+", ""):gsub("%s+$", "")
	return trimmed
end

local function hp_sanitize_preset_name(name)
	local clean = hp_trim_text(name)
	clean = clean:gsub('[<>:"/\\|%?%*]', "_")
	clean = clean:gsub("%.$", "")
	return clean
end

local function hp_get_preset_state(mode)
	if mode == "apartment" then
		return hp_heist_presets.apartment
	end
	if mode == "cayo" then
		return hp_heist_presets.cayo
	end
	if mode == "casino" then
		return hp_heist_presets.casino
	end
	if mode == "doomsday" then
		return hp_heist_presets.doomsday
	end
	if mode == "agency" then
		return hp_heist_presets.agency
	end
	if mode == "autoshop" then
		return hp_heist_presets.autoshop
	end
	if mode == "salvageyard" then
		return hp_heist_presets.salvageyard
	end
	return nil
end

local function hp_get_invoker_string(result)
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

local function hp_update_preset_name_label(mode)
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

local function hp_set_heist_preset_name_from_clipboard(mode)
	local state_tbl = hp_get_preset_state(mode)
	if not state_tbl then
		return false
	end

	local clip = input.get_clipboard_text()
	local clean = hp_sanitize_preset_name(clip)
	if clean == "" then
		hp_notify_presets("Clipboard is empty or invalid", 2000)
		return false
	end

	state_tbl.name = clean
	hp_update_preset_name_label(mode)
	hp_notify_presets("Preset name set: " .. clean, 2000)
	return true
end

local function hp_find_option_index(option_names, selected_name, fallback)
	for i = 1, #option_names do
		if option_names[i] == selected_name then
			return i
		end
	end
	return fallback or 1
end

local function hp_resolve_option_value(options, raw_value, fallback_value)
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
	doomsday = "doomsday",
	agency = "agency",
	autoshop = "auto_shop",
	salvageyard = "salvage_yard",
}

local function hp_validate_heist_preset(mode, preps)
	if type(preps) ~= "table" then
		return false, "Invalid preset JSON"
	end

	local expected_heist = PRESET_HEIST_MODE_TO_ID[mode]
	local is_legacy_doomsday = mode == "doomsday" and preps.heist == nil and preps.schema == nil and preps.act ~= nil
	if expected_heist and not is_legacy_doomsday and preps.heist ~= expected_heist then
		return false, "Preset/heist mismatch"
	end

	local schema = tonumber(preps.schema)
	if schema ~= PRESET_SCHEMA_VERSION and not is_legacy_doomsday then
		return false, "Unsupported preset schema"
	end

	return true, nil
end

local function hp_get_zero_based_option_index(options, value, default_index)
	local idx = hp_option_index_by_value(options, value, default_index or 1)
	return idx - 1
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

local function hp_read_player_enabled(preps, player_key, legacy_key, fallback)
	local player_tbl = preps[player_key]
	if type(player_tbl) == "table" and type(player_tbl.enabled) == "boolean" then
		return player_tbl.enabled
	end

	local legacy = preps[legacy_key]
	if type(legacy) == "boolean" then
		return legacy
	end
	if tonumber(legacy) then
		return tonumber(legacy) ~= 0
	end

	return fallback and true or false
end

local SAFE_PAYOUT_TARGETS = {
	apartment = 3000000,
	cayo = 2550000,
	casino = 3619000,
	doomsday = 2550000,
}

local AGENCY_PAYOUT_MAX = 2500000
local AUTOSHOP_PAYOUT_MAX = 2200000
local AUTOSHOP_TRANSACTION_MAX = 2000000
local SALVAGE_MULTIPLIER_MIN = 0.0
local SALVAGE_MULTIPLIER_MAX = 5.0
local SALVAGE_SELL_VALUE_MAX = 2100000

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

local function hp_extract_preset_name(file_entry)
	local name = tostring(file_entry or "")
	name = name:gsub("/", "\\")
	name = name:match("([^\\]+)$") or name
	name = name:gsub("%.json$", "")
	return name
end

local function hp_ensure_heist_preset_dirs()
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
	if not dirs.exists(hp_heist_presets.doomsday.dir) then
		dirs.create(hp_heist_presets.doomsday.dir)
	end
	if not dirs.exists(hp_heist_presets.agency.dir) then
		dirs.create(hp_heist_presets.agency.dir)
	end
	if not dirs.exists(hp_heist_presets.autoshop.dir) then
		dirs.create(hp_heist_presets.autoshop.dir)
	end
	if not dirs.exists(hp_heist_presets.salvageyard.dir) then
		dirs.create(hp_heist_presets.salvageyard.dir)
	end
end

local function hp_refresh_heist_preset_files(mode, preferred_name)
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

local function hp_get_selected_preset_name(mode)
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

local function hp_get_heist_preset_path(mode, preset_name)
	local state_tbl = hp_get_preset_state(mode)
	if not state_tbl then
		return nil
	end
	return state_tbl.dir .. "\\" .. preset_name .. ".json"
end

local function hp_open_heist_preset_name_keyboard(mode)
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
						hp_notify_presets("Preset name set: " .. clean_name, 2000)
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
				hp_notify_presets("Preset name entry canceled", 1500)
			end
		end
	end
end)

local function hp_build_heist_preset_group(tab_ref, mode, heist_subtab, id_prefix)
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

local function hp_read_json_file(path)
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

local function hp_write_json_file(path, content)
	local ok, err = pcall(function()
		local handle = file.open(path, { create_if_not_exists = true })
		if not handle or not handle.valid then
			error("Invalid file handle")
		end
		handle.json = json.encode(content)
	end)
	return ok, err
end

local function hp_collect_cayo_preset_data()
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
		womans_bag = cayo_flags.womans_bag_enabled and true or false,
		remove_crew_cuts = cayo_flags.remove_crew_cuts_enabled and true or false,
		max_payout = cayo_flags.max_payout_enabled and true or false,
		unlock_all_poi = CayoConfig.unlock_all_poi and true or false,
		player1 = { enabled = true, cut = CayoCutsValues.host },
		player2 = { enabled = (CayoCutsValues.player2 > 0), cut = CayoCutsValues.player2 },
		player3 = { enabled = (CayoCutsValues.player3 > 0), cut = CayoCutsValues.player3 },
		player4 = { enabled = (CayoCutsValues.player4 > 0), cut = CayoCutsValues.player4 },
	}
	return preps
end

local function hp_apply_cayo_preset_data(preps)
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
		if type(cayo_callbacks.set_womans_bag) == "function" then
			cayo_callbacks.set_womans_bag(preps.womans_bag, true)
		else
			cayo_flags.womans_bag_enabled = preps.womans_bag
		end
	end
	if type(preps.remove_crew_cuts) == "boolean" then
		if type(cayo_callbacks.set_remove_crew_cuts) == "function" then
			cayo_callbacks.set_remove_crew_cuts(preps.remove_crew_cuts, true)
		else
			cayo_flags.remove_crew_cuts_enabled = preps.remove_crew_cuts
		end
	end
	if type(preps.max_payout) == "boolean" then
		if type(cayo_callbacks.set_max_payout) == "function" then
			cayo_callbacks.set_max_payout(preps.max_payout, true)
		else
			cayo_flags.max_payout_enabled = preps.max_payout
		end
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

	if cayo_refs.unlock_on_apply_toggle then
		cayo_refs.unlock_on_apply_toggle.state = CayoConfig.unlock_all_poi
	end
	if cayo_refs.difficulty_dropdown then
		cayo_refs.difficulty_dropdown.value = hp_option_index_by_value(CayoPrepOptions.difficulties, CayoConfig.diff, 1)
	end
	if cayo_refs.approach_dropdown then
		cayo_refs.approach_dropdown.value = hp_option_index_by_value(CayoPrepOptions.approaches, CayoConfig.app, 1)
	end
	if cayo_refs.loadout_dropdown then
		cayo_refs.loadout_dropdown.value = hp_option_index_by_value(CayoPrepOptions.loadouts, CayoConfig.wep, 1)
	end
	if cayo_refs.primary_target_dropdown then
		cayo_refs.primary_target_dropdown.value =
			hp_option_index_by_value(CayoPrepOptions.primary_targets, CayoConfig.tgt, 1)
	end
	if cayo_refs.compound_target_dropdown then
		cayo_refs.compound_target_dropdown.value =
			hp_option_index_by_value(CayoPrepOptions.secondary_targets, CayoConfig.sec_comp, 1)
	end
	if cayo_refs.compound_amount_dropdown then
		cayo_refs.compound_amount_dropdown.value =
			hp_option_index_by_value(CayoPrepOptions.compound_amounts, CayoConfig.amt_comp, 1)
	end
	if cayo_refs.arts_amount_dropdown then
		cayo_refs.arts_amount_dropdown.value =
			hp_option_index_by_value(CayoPrepOptions.arts_amounts, CayoConfig.paint, 1)
	end
	if cayo_refs.island_target_dropdown then
		cayo_refs.island_target_dropdown.value =
			hp_option_index_by_value(CayoPrepOptions.secondary_targets, CayoConfig.sec_isl, 1)
	end
	if cayo_refs.island_amount_dropdown then
		cayo_refs.island_amount_dropdown.value =
			hp_option_index_by_value(CayoPrepOptions.island_amounts, CayoConfig.amt_isl, 1)
	end
	if cayo_refs.cash_value_slider then
		cayo_refs.cash_value_slider.value = CayoConfig.val_cash
	end
	if cayo_refs.weed_value_slider then
		cayo_refs.weed_value_slider.value = CayoConfig.val_weed
	end
	if cayo_refs.coke_value_slider then
		cayo_refs.coke_value_slider.value = CayoConfig.val_coke
	end
	if cayo_refs.gold_value_slider then
		cayo_refs.gold_value_slider.value = CayoConfig.val_gold
	end
	if cayo_refs.art_value_slider then
		cayo_refs.art_value_slider.value = CayoConfig.val_art
	end
	if cayo_refs.womans_bag_toggle then
		cayo_refs.womans_bag_toggle.state = cayo_flags.womans_bag_enabled
	end
	if cayo_refs.remove_crew_cuts_toggle then
		cayo_refs.remove_crew_cuts_toggle.state = cayo_flags.remove_crew_cuts_enabled
	end
	if cayo_refs.max_payout_toggle then
		cayo_refs.max_payout_toggle.state = cayo_flags.max_payout_enabled
	end
	if cayo_refs.host_slider then
		cayo_refs.host_slider.value = CayoCutsValues.host
	end
	if cayo_refs.p2_slider then
		cayo_refs.p2_slider.value = CayoCutsValues.player2
	end
	if cayo_refs.p3_slider then
		cayo_refs.p3_slider.value = CayoCutsValues.player3
	end
	if cayo_refs.p4_slider then
		cayo_refs.p4_slider.value = CayoCutsValues.player4
	end
	if cayo_flags.max_payout_enabled and type(cayo_callbacks.refresh_max_payout) == "function" then
		cayo_callbacks.refresh_max_payout(true, false)
	end

	return true
end

local function hp_collect_casino_preset_data()
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
		remove_crew_cuts = casino_flags.remove_crew_cuts_enabled and true or false,
		autograbber = casino_flags.autograbber_enabled and true or false,
		max_payout = casino_flags.max_payout_enabled and true or false,
		player1 = { enabled = true, cut = CutsValues.host },
		player2 = { enabled = (CutsValues.player2 > 0), cut = CutsValues.player2 },
		player3 = { enabled = (CutsValues.player3 > 0), cut = CutsValues.player3 },
		player4 = { enabled = (CutsValues.player4 > 0), cut = CutsValues.player4 },
	}
	return preps
end

local function hp_apply_casino_preset_data(preps)
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
		if type(casino_callbacks.set_remove_crew_cuts) == "function" then
			casino_callbacks.set_remove_crew_cuts(preps.remove_crew_cuts, true)
		else
			casino_flags.remove_crew_cuts_enabled = preps.remove_crew_cuts
		end
	end
	if type(preps.autograbber) == "boolean" then
		if type(casino_callbacks.set_autograbber) == "function" then
			casino_callbacks.set_autograbber(preps.autograbber, true)
		else
			casino_flags.autograbber_enabled = preps.autograbber
		end
	end
	if type(preps.max_payout) == "boolean" then
		if type(casino_callbacks.set_max_payout) == "function" then
			casino_callbacks.set_max_payout(preps.max_payout, true)
		else
			casino_flags.max_payout_enabled = preps.max_payout
		end
	end

	CutsValues.host = hp_read_player_cut(preps, "player1", "host_cut", CutsValues.host, hp_clamp_cut_percent)
	CutsValues.player2 = hp_read_player_cut(preps, "player2", "player2_cut", CutsValues.player2, hp_clamp_cut_percent)
	CutsValues.player3 = hp_read_player_cut(preps, "player3", "player3_cut", CutsValues.player3, hp_clamp_cut_percent)
	CutsValues.player4 = hp_read_player_cut(preps, "player4", "player4_cut", CutsValues.player4, hp_clamp_cut_percent)

	if casino_refs.manual_difficulty_dropdown then
		casino_refs.manual_difficulty_dropdown.value =
			hp_option_index_by_value(CasinoPrepOptions.difficulties, CasinoManualPreps.difficulty, 1)
	end
	if casino_refs.manual_approach_dropdown then
		casino_refs.manual_approach_dropdown.value =
			hp_option_index_by_value(CasinoPrepOptions.approaches, CasinoManualPreps.approach, 1)
	end
	if casino_refs.manual_gunman_dropdown then
		casino_refs.manual_gunman_dropdown.value =
			hp_option_index_by_value(CasinoPrepOptions.gunmen, CasinoManualPreps.crew_weapon, 1)
	end
	if casino_refs.manual_driver_dropdown then
		casino_refs.manual_driver_dropdown.value =
			hp_option_index_by_value(CasinoPrepOptions.drivers, CasinoManualPreps.crew_driver, 1)
	end
	if casino_refs.manual_hacker_dropdown then
		casino_refs.manual_hacker_dropdown.value =
			hp_option_index_by_value(CasinoPrepOptions.hackers, CasinoManualPreps.crew_hacker, 1)
	end
	if casino_refs.manual_masks_dropdown then
		casino_refs.manual_masks_dropdown.value =
			hp_option_index_by_value(CasinoPrepOptions.masks, CasinoManualPreps.masks, 1)
	end
	if casino_refs.manual_guards_dropdown then
		casino_refs.manual_guards_dropdown.value =
			hp_option_index_by_value(CasinoPrepOptions.guards, CasinoManualPreps.disrupt_shipments, 1)
	end
	if casino_refs.manual_keycards_dropdown then
		casino_refs.manual_keycards_dropdown.value =
			hp_option_index_by_value(CasinoPrepOptions.keycards, CasinoManualPreps.key_levels, 1)
	end
	if casino_refs.manual_target_dropdown then
		casino_refs.manual_target_dropdown.value =
			hp_option_index_by_value(CasinoPrepOptions.targets, CasinoManualPreps.target, 1)
	end
	if casino_refs.manual_unlock_poi_toggle then
		casino_refs.manual_unlock_poi_toggle.state = CasinoManualPreps.unlock_all_poi
	end
	if casino_refs.solo_launch_toggle then
		casino_refs.solo_launch_toggle.state = state.solo_launch.casino
	end
	if casino_refs.remove_crew_cuts_toggle then
		casino_refs.remove_crew_cuts_toggle.state = casino_flags.remove_crew_cuts_enabled
	end
	if casino_refs.max_payout_toggle then
		casino_refs.max_payout_toggle.state = casino_flags.max_payout_enabled
	end
	if casino_refs.autograbber_toggle then
		casino_refs.autograbber_toggle.state = casino_flags.autograbber_enabled
	end

	if casino_refs.manual_loadout_dropdown and casino_refs.manual_vehicles_dropdown then
		if type(casino_callbacks.update_loadout_dropdown) == "function" then
			casino_callbacks.update_loadout_dropdown(false)
		end
		if type(casino_callbacks.update_vehicle_dropdown) == "function" then
			casino_callbacks.update_vehicle_dropdown(false)
		end
		CasinoManualPreps.loadout_slot = hp_clamp_number(
			CasinoManualPreps.loadout_slot,
			1,
			math.max(1, #casino_refs.manual_loadout_dropdown.options)
		)
		CasinoManualPreps.vehicle_slot = hp_clamp_number(
			CasinoManualPreps.vehicle_slot,
			1,
			math.max(1, #casino_refs.manual_vehicles_dropdown.options)
		)
		casino_refs.manual_loadout_dropdown.value = CasinoManualPreps.loadout_slot
		casino_refs.manual_vehicles_dropdown.value = CasinoManualPreps.vehicle_slot
	end

	if casino_refs.host_slider then
		casino_refs.host_slider.value = CutsValues.host
	end
	if casino_refs.p2_slider then
		casino_refs.p2_slider.value = CutsValues.player2
	end
	if casino_refs.p3_slider then
		casino_refs.p3_slider.value = CutsValues.player3
	end
	if casino_refs.p4_slider then
		casino_refs.p4_slider.value = CutsValues.player4
	end
	if casino_flags.max_payout_enabled and type(casino_callbacks.refresh_max_payout) == "function" then
		casino_callbacks.refresh_max_payout(true, false)
	end

	return true
end

local function hp_collect_apartment_preset_data()
	local cuts = ApartmentCutsValues or {}
	local preps = {
		schema = PRESET_SCHEMA_VERSION,
		heist = "apartment",
		solo_launch = state.solo_launch.apartment and true or false,
		bonus_12mil = apartment_flags.bonus_enabled and true or false,
		double_rewards_week = apartment_flags.double_rewards_week and true or false,
		max_payout = apartment_flags.max_payout_enabled and true or false,
		preset = math.max(0, (apartment_flags.cut_preset_index or 1) - 1),
		player1 = { enabled = true, cut = cuts.player1 or 0 },
		player2 = { enabled = ((cuts.player2 or 0) > 0), cut = cuts.player2 or 0 },
		player3 = { enabled = ((cuts.player3 or 0) > 0), cut = cuts.player3 or 0 },
		player4 = { enabled = ((cuts.player4 or 0) > 0), cut = cuts.player4 or 0 },
	}
	return preps
end

local function hp_apply_apartment_preset_data(preps)
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
		if type(apartment_callbacks.set_bonus) == "function" then
			apartment_callbacks.set_bonus(bonus, true)
		else
			apartment_flags.bonus_enabled = bonus
		end
	end

	if type(preps.double_rewards_week) == "boolean" then
		apartment_flags.double_rewards_week = preps.double_rewards_week
	end
	if type(preps.max_payout) == "boolean" then
		apartment_flags.max_payout_enabled = preps.max_payout
	end

	local preset = tonumber(preps.preset)
	if not preset then
		preset = tonumber(preps.presets)
	end
	if preset then
		apartment_flags.cut_preset_index = math.floor(hp_clamp_number(preset + 1, 1, #APARTMENT_CUT_PRESET_OPTIONS))
	end

	ApartmentCutsValues.player1 =
		hp_read_player_cut(preps, "player1", "player1_cut", ApartmentCutsValues.player1, hp_clamp_apartment_cut_percent)
	ApartmentCutsValues.player2 =
		hp_read_player_cut(preps, "player2", "player2_cut", ApartmentCutsValues.player2, hp_clamp_apartment_cut_percent)
	ApartmentCutsValues.player3 =
		hp_read_player_cut(preps, "player3", "player3_cut", ApartmentCutsValues.player3, hp_clamp_apartment_cut_percent)
	ApartmentCutsValues.player4 =
		hp_read_player_cut(preps, "player4", "player4_cut", ApartmentCutsValues.player4, hp_clamp_apartment_cut_percent)

	if apartment_refs.solo_launch_toggle then
		apartment_refs.solo_launch_toggle.state = state.solo_launch.apartment
	end
	if apartment_refs.bonus_toggle then
		apartment_refs.bonus_toggle.state = apartment_flags.bonus_enabled
	end
	if apartment_refs.double_toggle then
		apartment_refs.double_toggle.state = apartment_flags.double_rewards_week
	end
	if apartment_refs.max_payout_toggle then
		apartment_refs.max_payout_toggle.state = apartment_flags.max_payout_enabled
	end
	if apartment_refs.preset_dropdown then
		apartment_refs.preset_dropdown.value = apartment_flags.cut_preset_index
	end

	if apartment_refs.p1_slider then
		apartment_refs.p1_slider.value = ApartmentCutsValues.player1
	end
	if apartment_refs.p2_slider then
		apartment_refs.p2_slider.value = ApartmentCutsValues.player2
	end
	if apartment_refs.p3_slider then
		apartment_refs.p3_slider.value = ApartmentCutsValues.player3
	end
	if apartment_refs.p4_slider then
		apartment_refs.p4_slider.value = ApartmentCutsValues.player4
	end

	if apartment_flags.max_payout_enabled then
		hp_refresh_apartment_max_payout(true, false)
	end

	return true
end

local function hp_collect_doomsday_preset_data()
	local cuts = doomsday_cuts or {}
	local enabled = doomsday_cut_enabled or {}

	local preps = {
		schema = PRESET_SCHEMA_VERSION,
		heist = "doomsday",
		act = math.max(0, (doomsday_config.act or 1) - 1),
		solo_launch = state.solo_launch.doomsday and true or false,
		max_payout = doomsday_flags.max_payout_enabled and true or false,
		presets = math.max(0, (doomsday_flags.cut_preset_index or 1) - 1),
		player1 = { enabled = enabled.player1 and true or false, cut = cuts.player1 or 0 },
		player2 = { enabled = enabled.player2 and true or false, cut = cuts.player2 or 0 },
		player3 = { enabled = enabled.player3 and true or false, cut = cuts.player3 or 0 },
		player4 = { enabled = enabled.player4 and true or false, cut = cuts.player4 or 0 },
	}

	return preps
end

local function hp_apply_doomsday_preset_data(preps)
	if type(preps) ~= "table" then
		return false
	end

	if type(preps.solo_launch) == "boolean" then
		state.solo_launch.doomsday = preps.solo_launch
	end

	local act = tonumber(preps.act)
	if act then
		local selected_act = math.floor(hp_clamp_number(act + 1, 1, 3))
		if type(doomsday_callbacks.set_selected_act) == "function" then
			doomsday_callbacks.set_selected_act(selected_act, true)
		else
			doomsday_config.act = selected_act
		end
	end

	local preset = tonumber(preps.preset)
	if not preset then
		preset = tonumber(preps.presets)
	end
	if preset then
		doomsday_flags.cut_preset_index = math.floor(hp_clamp_number(preset + 1, 1, #APARTMENT_CUT_PRESET_OPTIONS))
	end

	doomsday_cut_enabled.player1 =
		hp_read_player_enabled(preps, "player1", "player1_enabled", doomsday_cut_enabled.player1)
	doomsday_cut_enabled.player2 =
		hp_read_player_enabled(preps, "player2", "player2_enabled", doomsday_cut_enabled.player2)
	doomsday_cut_enabled.player3 =
		hp_read_player_enabled(preps, "player3", "player3_enabled", doomsday_cut_enabled.player3)
	doomsday_cut_enabled.player4 =
		hp_read_player_enabled(preps, "player4", "player4_enabled", doomsday_cut_enabled.player4)

	doomsday_cuts.player1 =
		hp_read_player_cut(preps, "player1", "player1_cut", doomsday_cuts.player1, hp_clamp_doomsday_cut_percent)
	doomsday_cuts.player2 =
		hp_read_player_cut(preps, "player2", "player2_cut", doomsday_cuts.player2, hp_clamp_doomsday_cut_percent)
	doomsday_cuts.player3 =
		hp_read_player_cut(preps, "player3", "player3_cut", doomsday_cuts.player3, hp_clamp_doomsday_cut_percent)
	doomsday_cuts.player4 =
		hp_read_player_cut(preps, "player4", "player4_cut", doomsday_cuts.player4, hp_clamp_doomsday_cut_percent)

	if doomsday_refs.act_dropdown then
		doomsday_refs.act_dropdown.value = doomsday_config.act
	end
	if doomsday_refs.solo_launch_toggle then
		doomsday_refs.solo_launch_toggle.state = state.solo_launch.doomsday
	end
	if doomsday_refs.cut_preset_dropdown then
		doomsday_refs.cut_preset_dropdown.value = doomsday_flags.cut_preset_index
	end
	if doomsday_refs.p1_toggle then
		doomsday_refs.p1_toggle.state = doomsday_cut_enabled.player1
	end
	if doomsday_refs.p2_toggle then
		doomsday_refs.p2_toggle.state = doomsday_cut_enabled.player2
	end
	if doomsday_refs.p3_toggle then
		doomsday_refs.p3_toggle.state = doomsday_cut_enabled.player3
	end
	if doomsday_refs.p4_toggle then
		doomsday_refs.p4_toggle.state = doomsday_cut_enabled.player4
	end
	if doomsday_refs.p1_slider then
		doomsday_refs.p1_slider.value = doomsday_cuts.player1
	end
	if doomsday_refs.p2_slider then
		doomsday_refs.p2_slider.value = doomsday_cuts.player2
	end
	if doomsday_refs.p3_slider then
		doomsday_refs.p3_slider.value = doomsday_cuts.player3
	end
	if doomsday_refs.p4_slider then
		doomsday_refs.p4_slider.value = doomsday_cuts.player4
	end

	if type(preps.max_payout) == "boolean" then
		if type(doomsday_callbacks.set_max_payout) == "function" then
			doomsday_callbacks.set_max_payout(preps.max_payout, true)
		else
			doomsday_flags.max_payout_enabled = preps.max_payout
		end
	end

	if doomsday_refs.max_payout_toggle then
		doomsday_refs.max_payout_toggle.state = doomsday_flags.max_payout_enabled
	end

	return true
end

local function hp_collect_agency_preset_data()
	return {
		schema = PRESET_SCHEMA_VERSION,
		heist = "agency",
		contract = hp_get_zero_based_option_index(AgencyPrepOptions.contracts, AgencyConfig.contract, 1),
		payout = math.floor(tonumber(AgencyConfig.payout) or 0),
	}
end

local function hp_apply_agency_preset_data(preps)
	if type(preps) ~= "table" then
		return false
	end

	AgencyConfig.contract = hp_resolve_option_value(AgencyPrepOptions.contracts, preps.contract, AgencyConfig.contract)
	if tonumber(preps.payout) then
		AgencyConfig.payout = math.floor(hp_clamp_number(preps.payout, 0, AGENCY_PAYOUT_MAX))
	end

	if agency_refs.contract_dropdown then
		agency_refs.contract_dropdown.value =
			hp_option_index_by_value(AgencyPrepOptions.contracts, AgencyConfig.contract, 1)
	end
	if agency_refs.payout_slider then
		agency_refs.payout_slider.value = AgencyConfig.payout
	end

	return true
end

local function hp_collect_autoshop_preset_data()
	return {
		schema = PRESET_SCHEMA_VERSION,
		heist = "auto_shop",
		contract = hp_get_zero_based_option_index(AutoshopPrepOptions.contracts, AutoshopConfig.contract, 1),
		payout = math.floor(tonumber(AutoshopConfig.payout) or 0),
	}
end

local function hp_apply_autoshop_preset_data(preps)
	if type(preps) ~= "table" then
		return false
	end

	AutoshopConfig.contract =
		hp_resolve_option_value(AutoshopPrepOptions.contracts, preps.contract, AutoshopConfig.contract)
	AutoshopConfig.contract_index = hp_option_index_by_value(
		AutoshopPrepOptions.contracts,
		AutoshopConfig.contract,
		AutoshopConfig.contract_index or 1
	)

	if tonumber(preps.payout) then
		AutoshopConfig.payout = math.floor(hp_clamp_number(preps.payout, 0, AUTOSHOP_PAYOUT_MAX))
	end

	if autoshop_refs.contract_dropdown then
		autoshop_refs.contract_dropdown.value = AutoshopConfig.contract_index
	end
	if autoshop_refs.payout_slider then
		autoshop_refs.payout_slider.value = AutoshopConfig.payout
	end

	return true
end

local function hp_collect_salvage_slot_data(slot_cfg)
	return {
		robbery = hp_get_zero_based_option_index(SalvagePrepOptions.robberies, slot_cfg.robbery, 1),
		vehicle = hp_get_zero_based_option_index(SalvagePrepOptions.vehicles, slot_cfg.vehicle, 1),
		modification = hp_get_zero_based_option_index(SalvagePrepOptions.modifications, slot_cfg.modification, 1),
		keep = hp_get_zero_based_option_index(SalvagePrepOptions.keep_statuses, slot_cfg.keep, 1),
	}
end

local function hp_apply_salvage_slot_from_preset(slot_cfg, slot_preps)
	if type(slot_cfg) ~= "table" or type(slot_preps) ~= "table" then
		return
	end

	slot_cfg.robbery = hp_resolve_option_value(SalvagePrepOptions.robberies, slot_preps.robbery, slot_cfg.robbery)
	slot_cfg.vehicle = hp_resolve_option_value(SalvagePrepOptions.vehicles, slot_preps.vehicle, slot_cfg.vehicle)
	slot_cfg.modification =
		hp_resolve_option_value(SalvagePrepOptions.modifications, slot_preps.modification, slot_cfg.modification)
	slot_cfg.keep = hp_resolve_option_value(SalvagePrepOptions.keep_statuses, slot_preps.keep, slot_cfg.keep)
end

local function hp_collect_salvageyard_preset_data()
	local slot1 = SalvageConfig.slot1 or {}
	local slot2 = SalvageConfig.slot2 or {}
	local slot3 = SalvageConfig.slot3 or {}
	return {
		schema = PRESET_SCHEMA_VERSION,
		heist = "salvage_yard",
		slot1 = hp_collect_salvage_slot_data(slot1),
		slot2 = hp_collect_salvage_slot_data(slot2),
		slot3 = hp_collect_salvage_slot_data(slot3),
		free_setup = salvage_flags.free_setup and true or false,
		free_claim = salvage_flags.free_claim and true or false,
		salvage_multiplier = tonumber(SalvageConfig.salvage_multiplier) or 0.0,
		sell_value_slot1 = math.floor(tonumber(SalvageConfig.sell_value_slot1) or 0),
		sell_value_slot2 = math.floor(tonumber(SalvageConfig.sell_value_slot2) or 0),
		sell_value_slot3 = math.floor(tonumber(SalvageConfig.sell_value_slot3) or 0),
	}
end

local function hp_apply_salvageyard_preset_data(preps)
	if type(preps) ~= "table" then
		return false
	end

	SalvageConfig.slot1 = SalvageConfig.slot1 or { robbery = 0, vehicle = 1, modification = 0, keep = 1 }
	SalvageConfig.slot2 = SalvageConfig.slot2 or { robbery = 1, vehicle = 2, modification = 0, keep = 1 }
	SalvageConfig.slot3 = SalvageConfig.slot3 or { robbery = 2, vehicle = 3, modification = 0, keep = 1 }

	hp_apply_salvage_slot_from_preset(SalvageConfig.slot1, preps.slot1)
	hp_apply_salvage_slot_from_preset(SalvageConfig.slot2, preps.slot2)
	hp_apply_salvage_slot_from_preset(SalvageConfig.slot3, preps.slot3)

	if tonumber(preps.salvage_multiplier) then
		SalvageConfig.salvage_multiplier =
			hp_clamp_number(preps.salvage_multiplier, SALVAGE_MULTIPLIER_MIN, SALVAGE_MULTIPLIER_MAX)
	end

	if tonumber(preps.sell_value_slot1) then
		SalvageConfig.sell_value_slot1 = math.floor(hp_clamp_number(preps.sell_value_slot1, 0, SALVAGE_SELL_VALUE_MAX))
	end
	if tonumber(preps.sell_value_slot2) then
		SalvageConfig.sell_value_slot2 = math.floor(hp_clamp_number(preps.sell_value_slot2, 0, SALVAGE_SELL_VALUE_MAX))
	end
	if tonumber(preps.sell_value_slot3) then
		SalvageConfig.sell_value_slot3 = math.floor(hp_clamp_number(preps.sell_value_slot3, 0, SALVAGE_SELL_VALUE_MAX))
	end

	if type(preps.free_setup) == "boolean" then
		if type(salvage_callbacks.set_free_setup) == "function" then
			salvage_callbacks.set_free_setup(preps.free_setup, true)
		else
			salvage_flags.free_setup = preps.free_setup
		end
	end
	if type(preps.free_claim) == "boolean" then
		if type(salvage_callbacks.set_free_claim) == "function" then
			salvage_callbacks.set_free_claim(preps.free_claim, true)
		else
			salvage_flags.free_claim = preps.free_claim
		end
	end

	if salvage_refs.slot1_robbery_dropdown then
		salvage_refs.slot1_robbery_dropdown.value =
			hp_option_index_by_value(SalvagePrepOptions.robberies, SalvageConfig.slot1.robbery, 1)
	end
	if salvage_refs.slot1_vehicle_dropdown then
		salvage_refs.slot1_vehicle_dropdown.value =
			hp_option_index_by_value(SalvagePrepOptions.vehicles, SalvageConfig.slot1.vehicle, 1)
	end
	if salvage_refs.slot1_modification_dropdown then
		salvage_refs.slot1_modification_dropdown.value =
			hp_option_index_by_value(SalvagePrepOptions.modifications, SalvageConfig.slot1.modification, 1)
	end
	if salvage_refs.slot1_keep_dropdown then
		salvage_refs.slot1_keep_dropdown.value =
			hp_option_index_by_value(SalvagePrepOptions.keep_statuses, SalvageConfig.slot1.keep, 1)
	end

	if salvage_refs.slot2_robbery_dropdown then
		salvage_refs.slot2_robbery_dropdown.value =
			hp_option_index_by_value(SalvagePrepOptions.robberies, SalvageConfig.slot2.robbery, 1)
	end
	if salvage_refs.slot2_vehicle_dropdown then
		salvage_refs.slot2_vehicle_dropdown.value =
			hp_option_index_by_value(SalvagePrepOptions.vehicles, SalvageConfig.slot2.vehicle, 1)
	end
	if salvage_refs.slot2_modification_dropdown then
		salvage_refs.slot2_modification_dropdown.value =
			hp_option_index_by_value(SalvagePrepOptions.modifications, SalvageConfig.slot2.modification, 1)
	end
	if salvage_refs.slot2_keep_dropdown then
		salvage_refs.slot2_keep_dropdown.value =
			hp_option_index_by_value(SalvagePrepOptions.keep_statuses, SalvageConfig.slot2.keep, 1)
	end

	if salvage_refs.slot3_robbery_dropdown then
		salvage_refs.slot3_robbery_dropdown.value =
			hp_option_index_by_value(SalvagePrepOptions.robberies, SalvageConfig.slot3.robbery, 1)
	end
	if salvage_refs.slot3_vehicle_dropdown then
		salvage_refs.slot3_vehicle_dropdown.value =
			hp_option_index_by_value(SalvagePrepOptions.vehicles, SalvageConfig.slot3.vehicle, 1)
	end
	if salvage_refs.slot3_modification_dropdown then
		salvage_refs.slot3_modification_dropdown.value =
			hp_option_index_by_value(SalvagePrepOptions.modifications, SalvageConfig.slot3.modification, 1)
	end
	if salvage_refs.slot3_keep_dropdown then
		salvage_refs.slot3_keep_dropdown.value =
			hp_option_index_by_value(SalvagePrepOptions.keep_statuses, SalvageConfig.slot3.keep, 1)
	end

	if salvage_refs.free_setup_toggle then
		salvage_refs.free_setup_toggle.state = salvage_flags.free_setup
	end
	if salvage_refs.free_claim_toggle then
		salvage_refs.free_claim_toggle.state = salvage_flags.free_claim
	end
	if salvage_refs.salvage_multiplier_slider then
		salvage_refs.salvage_multiplier_slider.value = SalvageConfig.salvage_multiplier
	end
	if salvage_refs.sell_value_slot1_slider then
		salvage_refs.sell_value_slot1_slider.value = SalvageConfig.sell_value_slot1
	end
	if salvage_refs.sell_value_slot2_slider then
		salvage_refs.sell_value_slot2_slider.value = SalvageConfig.sell_value_slot2
	end
	if salvage_refs.sell_value_slot3_slider then
		salvage_refs.sell_value_slot3_slider.value = SalvageConfig.sell_value_slot3
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
	doomsday = {
		collect = hp_collect_doomsday_preset_data,
		apply = hp_apply_doomsday_preset_data,
	},
	agency = {
		collect = hp_collect_agency_preset_data,
		apply = hp_apply_agency_preset_data,
	},
	autoshop = {
		collect = hp_collect_autoshop_preset_data,
		apply = hp_apply_autoshop_preset_data,
	},
	salvageyard = {
		collect = hp_collect_salvageyard_preset_data,
		apply = hp_apply_salvageyard_preset_data,
	},
}

hp_save_heist_preset = function(mode)
	local state_tbl = hp_get_preset_state(mode)
	if not state_tbl then
		return
	end

	local clean_name = hp_sanitize_preset_name(state_tbl.name)
	if clean_name == "" then
		hp_notify_presets("Enter a preset name before saving", 2200)
		return
	end

	hp_ensure_heist_preset_dirs()
	local path = hp_get_heist_preset_path(mode, clean_name)
	local handlers = HP_PRESET_MODE_HANDLERS[mode]
	if not handlers or type(handlers.collect) ~= "function" then
		hp_notify_presets("Preset mode not supported", 2000)
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
	hp_notify_presets("Saved preset: " .. clean_name, 2200)
end

hp_load_heist_preset = function(mode)
	local selected = hp_get_selected_preset_name(mode)
	if not selected then
		hp_notify_presets("Select a preset first", 2000)
		return
	end

	local path = hp_get_heist_preset_path(mode, selected)
	if not file.exists(path) then
		hp_notify_presets("Preset file not found", 2000)
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
		hp_notify_presets("Preset mode not supported", 2000)
		return
	end
	local applied = handlers.apply(preps)

	if applied then
		hp_notify_presets("Loaded preset: " .. selected, 2200)
	else
		hp_notify_presets("Failed to apply preset", 2200)
	end
end

hp_remove_heist_preset = function(mode)
	local selected = hp_get_selected_preset_name(mode)
	if not selected then
		hp_notify_presets("Select a preset first", 2000)
		return
	end

	local path = hp_get_heist_preset_path(mode, selected)
	if not file.exists(path) then
		hp_notify_presets("Preset file not found", 2000)
		hp_refresh_heist_preset_files(mode)
		return
	end

	local removed = file.remove(path)
	hp_refresh_heist_preset_files(mode)
	if removed then
		hp_notify_presets("Removed preset: " .. selected, 2000)
	else
		hp_notify_presets("Failed to remove preset", 2200)
	end
end

hp_copy_heist_preset_folder = function(mode)
	local state_tbl = hp_get_preset_state(mode)
	if not state_tbl then
		return
	end
	hp_ensure_heist_preset_dirs()
	input.set_clipboard_text(state_tbl.dir)
	hp_notify_presets("Preset folder path copied", 2000)
end

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
	if type(ApartmentCutsValues) ~= "table" then
		return hp_clamp_apartment_cut_percent(cut)
	end

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
	local selected = APARTMENT_CUT_PRESET_OPTIONS[apartment_flags.cut_preset_index]
		or APARTMENT_CUT_PRESET_OPTIONS[#APARTMENT_CUT_PRESET_OPTIONS]
	local value = selected and selected.value or 100
	return hp_set_apartment_uniform_cuts(value, apply_now)
end

hp_refresh_apartment_max_payout = function(force_update, apply_now)
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
	AGENCY_PAYOUT_MAX = AGENCY_PAYOUT_MAX,
	AUTOSHOP_PAYOUT_MAX = AUTOSHOP_PAYOUT_MAX,
	AUTOSHOP_TRANSACTION_MAX = AUTOSHOP_TRANSACTION_MAX,
	SALVAGE_SELL_VALUE_MAX = SALVAGE_SELL_VALUE_MAX,
	SALVAGE_MULTIPLIER_MIN = SALVAGE_MULTIPLIER_MIN,
	SALVAGE_MULTIPLIER_MAX = SALVAGE_MULTIPLIER_MAX,
	APARTMENT_CUT_PRESET_OPTIONS = APARTMENT_CUT_PRESET_OPTIONS,
	GetMP = GetMP,
	hp_options_to_names = hp_options_to_names,
	hp_find_option_index = hp_find_option_index,
	hp_option_index_by_value = hp_option_index_by_value,
	hp_option_value_by_name = hp_option_value_by_name,
	hp_option_names_range = hp_option_names_range,
	hp_set_stat_for_all_characters = hp_set_stat_for_all_characters,
	hp_apply_casino_manual_preps = hp_apply_casino_manual_preps,
	hp_build_heist_preset_group = hp_build_heist_preset_group,
	hp_set_uniform_cuts = hp_set_uniform_cuts,
	hp_set_apartment_uniform_cuts = hp_set_apartment_uniform_cuts,
	hp_clamp_cut_percent = hp_clamp_cut_percent,
	hp_clamp_doomsday_cut_percent = hp_clamp_doomsday_cut_percent,
	hp_clamp_apartment_cut_percent = hp_clamp_apartment_cut_percent,
	hp_get_apartment_max_payout_cut = hp_get_apartment_max_payout_cut,
	hp_apply_selected_apartment_cut_preset = hp_apply_selected_apartment_cut_preset,
	hp_refresh_apartment_max_payout = hp_refresh_apartment_max_payout,
	hp_is_apartment_fleeca = hp_is_apartment_fleeca,
}

return presets
