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

require("ShillenSilent_noclick_core.menu.main")
