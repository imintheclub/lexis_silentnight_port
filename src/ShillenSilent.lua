-- ============================================================================
-- ShillenSilent Bootstrap (native require)
-- ============================================================================

local function prepend_package_pattern(pattern)
	if not package then
		error("ShillenSilent bootstrap: package table unavailable")
	end
	local current = package.path or ""
	if current:find(pattern, 1, true) then
		return
	end
	package.path = (current == "") and pattern or (pattern .. ";" .. current)
end

local script_root = tostring((paths and paths.script) or "."):gsub("\\", "/"):gsub("/+$", "")
if script_root == "" then
	script_root = "."
end

prepend_package_pattern(script_root .. "/?.lua")
prepend_package_pattern(script_root .. "/?/init.lua")

-- Bump the generation so any mid-iteration render thread from a previous load exits
-- on its next loop check, even if ForceStop has already been cleared by that point.
_G.ShillenSilent_Generation = (_G.ShillenSilent_Generation or 0) + 1
_G.ShillenSilent_ForceStop = true
util.yield(0)

-- Drop cached GUI handles and started flags so each load re-acquires fresh fonts/images
-- and re-invokes service start. Lexis rebuilds its font atlas on script load, which
-- invalidates handles cached by the previous generation; carrying them forward yields
-- a null-deref inside the Lexis text renderer.
local function patch_loaded(module_name, mutator)
	local mod = package.loaded and package.loaded[module_name]
	if type(mod) == "table" then
		pcall(mutator, mod)
	end
end

patch_loaded("ShillenSilent_core.ui.click.state", function(state)
	state.fonts = {}
	state.images = {}
	state.logo = nil
	state.font_load_attempted = false
end)
patch_loaded("ShillenSilent_core.ui.click.splash", function(s)
	s.started = false
	s.finished = true
	s.thread_running = false
	s.gen = nil
end)
patch_loaded("ShillenSilent_core.app.router", function(m)
	m.started = false
	m.active_mode = nil
end)
patch_loaded("ShillenSilent_core.app.main", function(m)
	m.started = false
	m.heistTab = nil
end)
patch_loaded("ShillenSilent_core.runtime.main_loop", function(m)
	m.started = false
end)
patch_loaded("ShillenSilent_core.presets.ui", function(m)
	m.keyboard_watcher_gen = nil
	if type(m.keyboard) == "table" then
		m.keyboard.waiting = false
		m.keyboard.feature_id = nil
	end
end)

require("ShillenSilent_core.app.router")
