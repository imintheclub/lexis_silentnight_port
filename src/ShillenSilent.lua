-- ============================================================================
-- ShillenSilent Module Loader
-- ============================================================================
-- Loads split source modules from:
--   ShillenSilent_core/
-- as individual chunks with module caching (require-style behavior).

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
	"shared/heist_state.lua",
	"shared/danger_groups.lua",
	"shared/coords_teleport.lua",
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
	"runtime/solo_launch.lua",
	"runtime/main_loop.lua",
	"app/main.lua",
}

local function normalize_module_name(name)
	local normalized = tostring(name or "")
	normalized = normalized:gsub("\\", "/")
	normalized = normalized:gsub("^%./", "")
	normalized = normalized:gsub("%.lua$", "")
	return normalized
end

local module_index = {}
for i = 1, #module_files do
	local rel_path = module_files[i]
	module_index[normalize_module_name(rel_path)] = rel_path
end

local module_loading = {}
local module_cache = {}
local builtin_require = rawget(_G, "require")

local function load_module_chunk(path, module_name)
	local content, err = read_text_file(path)
	if content == nil then
		error(string.format("ShillenSilent loader failed to read module '%s': %s", path, tostring(err)))
	end

	local chunk_name = "@ShillenSilent_core/" .. module_name .. ".lua"
	local fn, load_err
	if _VERSION == "Lua 5.1" and type(loadstring) == "function" then
		fn, load_err = loadstring(content, chunk_name)
		if fn and type(setfenv) == "function" then
			setfenv(fn, _G)
		end
	else
		fn, load_err = load(content, chunk_name, "t", _G)
	end

	if not fn then
		error(string.format("ShillenSilent loader failed to compile module '%s': %s", module_name, tostring(load_err)))
	end

	local ok, result = pcall(fn)
	if not ok then
		error(string.format("ShillenSilent module '%s' runtime error: %s", module_name, tostring(result)))
	end

	if result == nil then
		return true
	end
	return result
end

local function shillen_require(name)
	local module_name = normalize_module_name(name)
	local rel_path = module_index[module_name]
	if not rel_path then
		if builtin_require then
			return builtin_require(name)
		end
		error(string.format("ShillenSilent module not found: %s", tostring(name)))
	end

	if module_cache[module_name] ~= nil then
		return module_cache[module_name]
	end

	if module_loading[module_name] then
		error(string.format("ShillenSilent circular module load detected: %s", module_name))
	end

	module_loading[module_name] = true
	local module_path = join_path(modules_root, rel_path)
	local result = load_module_chunk(module_path, module_name)
	module_cache[module_name] = result
	module_loading[module_name] = nil
	return result
end

_G.shillen_require = shillen_require
_G.require_module = shillen_require

shillen_require("app/main")
