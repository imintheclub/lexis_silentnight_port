local preset_store = require("ShillenSilent_core.presets")
local i18n = require("ShillenSilent_core.i18n")
local notify_core = require("ShillenSilent_core.core.notify")

local preset_ui = {
	states = {},
	keyboard = {
		waiting = false,
		feature_id = nil,
	},
}

local native = nil
pcall(function()
	native = require("natives")
end)

local t = i18n.t

local function notify(message_key, vars, duration)
	notify_core.push("preset.title", message_key, duration or 2200, vars)
end

local function state_for(feature_id)
	local id = tostring(feature_id or "")
	local state = preset_ui.states[id]
	if not state then
		state = {
			name = "QuickPreset",
			options = { preset_store.EMPTY_LABEL },
			selected = 1,
			click = {},
			controller = {},
		}
		preset_ui.states[id] = state
	end
	return state
end

local function find_option_index(options, selected_name, fallback)
	for i = 1, #options do
		if options[i] == selected_name then
			return i
		end
	end
	return fallback or 1
end

local function selected_name(feature_id)
	local state = state_for(feature_id)
	local name = state.options[state.selected]
	if not name or name == "" or name == preset_store.EMPTY_LABEL then
		return nil
	end
	return name
end

local function clean_input_name(name)
	local clean = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
	clean = clean:gsub('[\\/:*?"<>|]', "_")
	clean = clean:gsub("%.$", "")
	return clean
end

local function update_name_label(feature_id)
	local state = state_for(feature_id)
	local label = state.click.name_label
	if label then
		label.text = t("preset.name", { name = state.name or "QuickPreset" })
	end
	if state.controller.name_breaker then
		state.controller.name_breaker.name = t("preset.name", { name = state.name or "QuickPreset" })
	end
end

function preset_ui.refresh_files(feature_id, preferred_name)
	local state = state_for(feature_id)
	local previous = preferred_name
	if not previous and state.options[state.selected] ~= preset_store.EMPTY_LABEL then
		previous = state.options[state.selected]
	end

	state.options = preset_store.list(feature_id)
	state.selected = find_option_index(state.options, previous, 1)

	local dropdown = state.click.dropdown
	if dropdown then
		dropdown.options = state.options
		dropdown.value = state.selected
	end

	local combo = state.controller.combo
	if combo and combo.list then
		for i = 1, #state.options do
			local entry = combo.list:at(i)
			if entry then
				entry.name = state.options[i]
				entry.value = i
			end
		end
		combo.value = state.selected
	end
	return state.options
end

local function save(feature_id, adapter)
	local state = state_for(feature_id)
	local name = preset_store.sanitize_name(state.name)
	if name == "" then
		notify("preset.notify.name_empty", nil, 2000)
		return false
	end
	local ok, err = preset_store.save(feature_id, adapter.collect(), name)
	preset_ui.refresh_files(feature_id, name)
	notify(
		ok and "preset.notify.save_ok" or "preset.notify.save_failed",
		ok and { name = name } or { error = tostring(err) },
		2200
	)
	state.name = name
	update_name_label(feature_id)
	return ok
end

local function load(feature_id, adapter)
	local name = selected_name(feature_id)
	if not name then
		notify("preset.notify.select_first", nil, 2000)
		return false
	end
	local ok, payload = preset_store.load(feature_id, name)
	if ok and adapter.apply(payload) then
		if type(adapter.refresh) == "function" then
			adapter.refresh()
		end
		notify("preset.notify.load_ok", { name = name }, 2000)
		return true
	end
	notify("preset.notify.load_failed", { error = tostring(payload) }, 2400)
	return false
end

local function remove(feature_id)
	local name = selected_name(feature_id)
	if not name then
		notify("preset.notify.select_first", nil, 2000)
		return false
	end
	local ok, err = preset_store.remove(feature_id, name)
	preset_ui.refresh_files(feature_id)
	notify(
		ok and "preset.notify.remove_ok" or "preset.notify.remove_failed",
		ok and { name = name } or { error = tostring(err) },
		2200
	)
	return ok
end

local function copy_folder(feature_id)
	if input and input.set_clipboard_text then
		input.set_clipboard_text(preset_store.folder(feature_id))
		notify("preset.notify.folder_copied", nil, 2000)
		return true
	end
	notify("preset.notify.clipboard_unavailable", nil, 2200)
	return false
end

local function set_name(feature_id, name)
	local clean = clean_input_name(name)
	if clean == "" then
		notify("preset.notify.name_empty", nil, 2000)
		return false
	end
	local state = state_for(feature_id)
	state.name = clean
	update_name_label(feature_id)
	notify("preset.notify.name_set", { name = clean }, 2000)
	return true
end

local function set_name_from_clipboard(feature_id)
	if not (input and input.get_clipboard_text) then
		notify("preset.notify.clipboard_unavailable", nil, 2200)
		return false
	end
	local clean = clean_input_name(input.get_clipboard_text())
	if clean == "" then
		notify("preset.notify.clipboard_invalid", nil, 2000)
		return false
	end
	return set_name(feature_id, clean)
end

local function open_keyboard(feature_id)
	if not (native and native.display_onscreen_keyboard and native.update_onscreen_keyboard) then
		notify("preset.notify.keyboard_unavailable", nil, 2200)
		return false
	end
	if preset_ui.keyboard.waiting then
		notify("preset.notify.keyboard_busy", nil, 2000)
		return false
	end

	local state = state_for(feature_id)
	preset_ui.keyboard.waiting = true
	preset_ui.keyboard.feature_id = feature_id
	native.display_onscreen_keyboard(6, "FMMC_KEY_TIP8", "", state.name or "", "", "", "", 64)
	notify("preset.notify.enter_name", nil, 2200)
	return true
end

local function get_keyboard_result()
	if not (invoker and invoker.call) then
		return ""
	end
	local ok, result = pcall(invoker.call, 0x8362B09B91893647)
	if not ok or result == nil then
		return ""
	end
	if type(result) == "string" then
		return result
	end
	local s = result.str
	return type(s) == "string" and s or ""
end

pcall(function()
	util.create_thread(function()
		while true do
			util.yield(100)
			if preset_ui.keyboard.waiting then
				local status = native.update_onscreen_keyboard()
				if status == 1 then
					set_name(preset_ui.keyboard.feature_id, get_keyboard_result())
					preset_ui.keyboard.waiting = false
					preset_ui.keyboard.feature_id = nil
				elseif status == 2 then
					preset_ui.keyboard.waiting = false
					preset_ui.keyboard.feature_id = nil
					notify("preset.notify.name_canceled", nil, 1500)
				end
			end
		end
	end)
end)

function preset_ui.click_group(parent, opts)
	if type(parent) ~= "table" or type(opts) ~= "table" then
		return nil
	end
	local ui = require("ShillenSilent_core.ui.click.widgets")
	local config = require("ShillenSilent_core.ui.click.config")
	local feature_id = opts.feature_id
	local state = state_for(feature_id)
	local adapter = {
		collect = opts.collect,
		apply = opts.apply,
		refresh = opts.refresh,
	}
	local prefix = opts.id_prefix or feature_id

	local group = ui.group(parent, t("preset.group.json"), nil, nil, nil, nil, opts.subtab or feature_id)
	state.click.name_label = ui.label(group, t("preset.name", { name = state.name }), config.colors.text_sec)
	ui.button(group, prefix .. "_preset_set_name", t("preset.action.set_name_keyboard"), function()
		open_keyboard(feature_id)
	end)
	ui.button(group, prefix .. "_preset_name_clipboard", t("preset.action.set_name_clipboard"), function()
		set_name_from_clipboard(feature_id)
	end)

	preset_ui.refresh_files(feature_id)
	state.click.dropdown = ui.dropdown(
		group,
		prefix .. "_preset_file",
		t("preset.field.file"),
		state.options,
		state.selected,
		function(opt)
			state.selected = find_option_index(state.options, opt, 1)
		end
	)
	ui.button(group, prefix .. "_preset_save", t("preset.action.save"), function()
		save(feature_id, adapter)
	end)
	ui.button(group, prefix .. "_preset_load", t("preset.action.load"), function()
		load(feature_id, adapter)
	end)
	ui.button(group, prefix .. "_preset_remove", t("preset.action.remove"), function()
		remove(feature_id)
	end)
	ui.button(group, prefix .. "_preset_refresh", t("preset.action.refresh"), function()
		preset_ui.refresh_files(feature_id)
	end)
	ui.button(group, prefix .. "_preset_copy_folder", t("preset.action.copy_folder"), function()
		copy_folder(feature_id)
	end)
	return group
end

function preset_ui.controller_group(parent, opts)
	if not parent or type(opts) ~= "table" then
		return nil
	end
	local common = require("ShillenSilent_core.ui.controller.widgets")
	local feature_id = opts.feature_id
	local state = state_for(feature_id)
	local adapter = {
		collect = opts.collect,
		apply = opts.apply,
		refresh = opts.refresh,
	}
	local root = parent:submenu(t("preset.group.json"))
	state.controller.name_breaker = root:breaker(t("preset.name", { name = state.name }))
	common.add_button(root, t("preset.action.set_name_keyboard"), function()
		open_keyboard(feature_id)
	end)
	common.add_button(root, t("preset.action.set_name_clipboard"), function()
		set_name_from_clipboard(feature_id)
	end)
	preset_ui.refresh_files(feature_id)
	local entries = {}
	for i = 1, #state.options do
		entries[i] = { state.options[i], i }
	end
	state.controller.combo = common.add_combo_entries(
		opts.ctx or { syncing = false },
		root,
		t("preset.field.file"),
		entries,
		function()
			return state.selected
		end,
		function(idx)
			state.selected = idx
		end
	)
	common.add_button(root, t("preset.action.save"), function()
		save(feature_id, adapter)
	end)
	common.add_button(root, t("preset.action.load"), function()
		load(feature_id, adapter)
	end)
	common.add_button(root, t("preset.action.remove"), function()
		remove(feature_id)
	end)
	common.add_button(root, t("preset.action.refresh"), function()
		preset_ui.refresh_files(feature_id)
	end)
	common.add_button(root, t("preset.action.copy_folder"), function()
		copy_folder(feature_id)
	end)
	return root
end

return preset_ui
