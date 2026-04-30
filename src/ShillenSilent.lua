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

require("ShillenSilent_core.app.router")
