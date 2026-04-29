local paths_core = {}

local function script_path(path)
	local base = paths.script
	local drive, rest = base:match("^([A-Z]:)(.*)")
	if drive then
		base = drive:lower() .. rest
	end
	return base .. tostring(path or "")
end

paths_core.script_path = script_path
paths_core.core_dir = script_path("\\ShillenSilent_core")
paths_core.fonts_dir = paths_core.core_dir .. "\\fonts"
paths_core.preset_dir = script_path("\\ShillenSilent_HeistPresets")
paths_core.config_path = paths_core.core_dir .. "\\config.json"

function paths_core.ensure()
	if not dirs.exists(paths_core.core_dir) then
		dirs.create(paths_core.core_dir)
	end
	if not dirs.exists(paths_core.fonts_dir) then
		dirs.create(paths_core.fonts_dir)
	end
	if not dirs.exists(paths_core.preset_dir) then
		dirs.create(paths_core.preset_dir)
	end
end

function paths_core.join(base, ...)
	local out = tostring(base or "")
	local parts = { ... }
	for i = 1, #parts do
		local part = tostring(parts[i] or "")
		if part ~= "" then
			out = out:gsub("[/\\]+$", "") .. "\\" .. part:gsub("^[/\\]+", "")
		end
	end
	return out
end

return paths_core
