local safe_access = require("ShillenSilent_core.core.safe_access")
local notify_core = require("ShillenSilent_core.core.notify")
local ui_mode = require("ShillenSilent_core.app.ui_mode")
local i18n = require("ShillenSilent_core.i18n")
local click_config = require("ShillenSilent_core.ui.click.config")
local click_theme = require("ShillenSilent_core.ui.click.theme")
local offsets = require("ShillenSilent_core.data.offsets.resolver")
local data = require("ShillenSilent_core.features.heists.info.data")
local state = require("ShillenSilent_core.features.heists.info.state")

local actions = {}

local function config()
	return offsets.feature("info")
end

local function should_notify(opts)
	return not (type(opts) == "table" and opts.notify == false)
end

function actions.refresh_state()
	state.set_ui_mode(ui_mode.get_mode_for_next_load())
	state.set_theme_mode(click_config.theme_mode or click_theme.read_theme_mode())
	state.set_language(i18n.get_configured_language())
	return true
end

function actions.set_ui_mode(mode, opts)
	local normalized = data.normalize_ui_mode(mode, state.config.ui_mode)
	local ok, result = ui_mode.set_mode_for_next_load(normalized)
	if ok then
		state.set_ui_mode(result)
		if should_notify(opts) then
			notify_core.push("info.title.ui_mode", "notify.next_load_mode", 2600, { mode = tostring(result) })
		end
		return true, result
	end
	if should_notify(opts) then
		notify_core.push("info.title.ui_mode", "notify.mode_failed", 3200, { error = tostring(result) })
	end
	return false, result
end

function actions.toggle_ui_mode(opts)
	actions.refresh_state()
	local next_mode = (state.config.ui_mode == "controller") and "click" or "controller"
	return actions.set_ui_mode(next_mode, opts)
end

function actions.set_theme_mode(mode, opts)
	local normalized = data.normalize_theme_mode(mode, state.config.theme_mode)
	local applied_mode = click_theme.apply_theme(click_config, normalized)
	local wrote = click_theme.write_theme_mode(applied_mode)
	state.set_theme_mode(applied_mode)
	if should_notify(opts) then
		notify_core.push(
			"info.title.theme",
			wrote and "info.notify.theme_set" or "info.notify.theme_set_save_failed",
			wrote and 2600 or 3200,
			{ mode = tostring(applied_mode) }
		)
	end
	return wrote, applied_mode
end

local function language_name(language)
	for i = 1, #data.languages do
		local option = data.languages[i]
		if option.value == language then
			return i18n.t(option.label_key)
		end
	end
	return tostring(language)
end

function actions.set_language(language, opts)
	local normalized = data.normalize_language(language, state.config.language)
	local wrote, applied_language = i18n.write_language(normalized)
	state.set_language(applied_language)
	if should_notify(opts) then
		notify_core.push(
			"info.title.language",
			wrote and "info.notify.language_set" or "info.notify.language_set_save_failed",
			wrote and 2600 or 3200,
			{ language = language_name(applied_language) }
		)
	end
	return wrote, applied_language
end

function actions.unlock_gta_plus(opts)
	local cfg = config()
	local ok, result = pcall(function()
		local s = memory.scan(data.gta_plus.pattern)
		if not s or s.value == 0 then
			if should_notify(opts) then
				notify_core.push("info.title.gta_plus", "notify.gta_plus_pattern_missing", 3000)
			end
			return false
		end

		local a = s:rip(3, 7)
		if a then
			a.int32 = 1
		end

		local global = cfg.globals.gta_plus
		local rank = cfg.gta_plus
		local global_ok = safe_access.set_global_bool(global, true)
		local rank_ok = safe_access.set_global_at_int(global, rank.rank_offset, rank.rank_value)
		return global_ok and rank_ok
	end)
	if not ok then
		if should_notify(opts) then
			notify_core.push("info.title.gta_plus", "notify.gta_plus_error", 3000, { error = tostring(result) })
		end
		return false
	end
	if result ~= true then
		return false
	end
	if should_notify(opts) then
		notify_core.push("info.title.gta_plus", "notify.gta_plus_unlocked", 3000)
	end
	return true
end

actions.refresh_state()

return actions
