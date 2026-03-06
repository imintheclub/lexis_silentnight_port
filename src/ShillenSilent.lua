-- ============================================================================
-- ShillenSilent Modular Loader
-- ============================================================================
-- This loader assembles split source modules from:
--   ShillenSilent_core/
-- and executes them as a single Lua chunk to preserve original local-scope
-- behavior while keeping the source modularized.

local function normalize_base_path(path)
	if type(path) ~= "string" then
		return "."
	end
	local drive, rest = path:match("^([A-Z]:)(.*)")
	if drive then
		return drive:lower() .. rest
	end
	return path
end

local function choose_path_separator(path)
	if tostring(path or ""):find("\\", 1, true) then
		return "\\"
	end
	return "/"
end

local function join_path(base, tail)
	base = tostring(base or "")
	tail = tostring(tail or "")
	local sep = choose_path_separator(base)

	if sep == "\\" then
		tail = tail:gsub("/", "\\")
	else
		tail = tail:gsub("\\", "/")
	end

	tail = tail:gsub("^[\\/]+", "")

	if base:sub(-1) == "\\" or base:sub(-1) == "/" then
		return base .. tail
	end
	return base .. sep .. tail
end

local function read_text_file(path)
	if io and type(io.open) == "function" then
		local fh, err = io.open(path, "rb")
		if fh then
			local content = fh:read("*a")
			fh:close()
			return content
		end
		return nil, err
	end

	if file and type(file.open) == "function" then
		local handle = file.open(path, { append = false, create_if_not_exists = false })
		if handle and handle.valid then
			if type(handle.text) == "string" and handle.text ~= "" then
				return handle.text
			end
			if type(handle.json) == "string" and handle.json ~= "" then
				return handle.json
			end
			return ""
		end
		return nil, "file handle invalid"
	end

	return nil, "no readable file API available"
end

local script_root = normalize_base_path((paths and paths.script) or ".")
local modules_root = join_path(script_root, "ShillenSilent_core")

local module_files = {
	"core/bootstrap.lua",
	"core/ui.lua",
	"core/native_api.lua",
	"shared/presets_and_shared.lua",
	"heists/casino/logic.lua",
	"heists/cayo/logic.lua",
	"heists/apartment/base.lua",
	"heists/casino/tabs.lua",
	"heists/cayo/tabs.lua",
	"shared/blip_teleport.lua",
	"heists/apartment/tabs.lua",
	"heists/doomsday/all.lua",
	"heists/cluckin/all.lua",
	"runtime/main_loop.lua",
}

local assembled = {}
for i = 1, #module_files do
	local name = module_files[i]
	local path = join_path(modules_root, name)
	local content, err = read_text_file(path)
	if content == nil then
		error(string.format("ShillenSilent loader failed to read module '%s': %s", path, tostring(err)))
	end

	assembled[#assembled + 1] = string.format("\n-- <module:%s>\n", name)
	assembled[#assembled + 1] = content
	assembled[#assembled + 1] = "\n"
end

local code = table.concat(assembled)
local fn, load_err

if _VERSION == "Lua 5.1" and type(loadstring) == "function" then
	fn, load_err = loadstring(code, "@ShillenSilent.modules.lua")
	if fn and type(setfenv) == "function" then
		setfenv(fn, _G)
	end
else
	fn, load_err = load(code, "@ShillenSilent.modules.lua", "t", _ENV or _G)
end

if not fn then
	error(string.format("ShillenSilent loader failed to compile modules: %s", tostring(load_err)))
end

fn()
