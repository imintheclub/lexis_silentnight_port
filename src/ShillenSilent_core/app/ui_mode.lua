local ui_mode = {}

local DEFAULT_MODE = "click"
local VALID_MODES = {
	click = true,
	controller = true,
}

local function get_mode_file_path()
	local base = paths.script
	local drive, rest = base:match("^([A-Z]:)(.*)")
	if drive then
		base = drive:lower() .. rest
	end
	return base .. "\\ShillenSilent_core\\ui_mode.txt"
end

local function normalize_mode(mode)
	if type(mode) ~= "string" then
		return nil
	end
	local normalized = mode:lower():gsub("^%s+", ""):gsub("%s+$", "")
	if VALID_MODES[normalized] then
		return normalized
	end
	return nil
end

local function read_mode_file()
	local path = get_mode_file_path()
	local ok, result = pcall(function()
		local handle = file.open(path, { append = false, create_if_not_exists = false })
		if not handle or not handle.valid then
			return nil
		end
		return handle.text
	end)
	if not ok then
		return nil
	end
	return normalize_mode(result)
end

local function write_mode_file(mode)
	local path = get_mode_file_path()
	local ok, err = pcall(function()
		local handle = file.open(path, { create_if_not_exists = true })
		if not handle or not handle.valid then
			error("Invalid file handle")
		end
		handle.text = mode
	end)
	return ok, err
end

function ui_mode.resolve_active_mode()
	local override_mode = normalize_mode(_G.ShillenSilent_UIMode)
	if override_mode then
		return override_mode, "override"
	end

	local file_mode = read_mode_file()
	if file_mode then
		return file_mode, "file"
	end

	return DEFAULT_MODE, "default"
end

function ui_mode.set_mode_for_next_load(mode)
	local normalized = normalize_mode(mode)
	if not normalized then
		return false, "Invalid mode. Expected 'click' or 'controller'."
	end

	local ok, err = write_mode_file(normalized)
	if not ok then
		return false, tostring(err)
	end

	return true, normalized
end

function ui_mode.get_mode_for_next_load()
	local mode = read_mode_file()
	return mode or DEFAULT_MODE
end

function ui_mode.list_modes()
	return { "click", "controller" }
end

return ui_mode
