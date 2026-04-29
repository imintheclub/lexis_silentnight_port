local paths = require("ShillenSilent_core.core.paths")
local schema = require("ShillenSilent_core.presets.schema")

local storage = {}

local function sanitize_name(name)
	local cleaned = tostring(name or "QuickPreset"):gsub("^%s+", ""):gsub("%s+$", "")
	cleaned = cleaned:gsub('[\\/:*?"<>|]', "_")
	cleaned = cleaned:gsub("%.$", "")
	if cleaned == "" then
		cleaned = "QuickPreset"
	end
	return cleaned
end

local function extract_name(file_entry)
	local name = tostring(file_entry or ""):gsub("/", "\\")
	name = name:match("([^\\]+)$") or name
	name = name:gsub("%.json$", "")
	return name
end

local function feature_dir(feature_id)
	paths.ensure()
	local root = paths.join(paths.preset_dir, tostring(feature_id))
	if dirs and not dirs.exists(root) then
		dirs.create(root)
	end
	return root
end

local function read_json_file(path)
	local handle = file.open(path, { append = false, create_if_not_exists = false })
	if not handle or not handle.valid then
		return false, "missing"
	end

	if handle.json ~= nil then
		local ok, payload = pcall(json.decode, handle.json)
		if ok and type(payload) == "table" then
			return true, payload
		end
		if type(handle.json) == "table" then
			return true, handle.json
		end
	end

	local text = handle.text or ""
	if text ~= "" then
		local ok, payload = pcall(json.decode, text)
		if ok and type(payload) == "table" then
			return true, payload
		end
	end
	return false, "invalid json"
end

local function unwrap_payload(feature_id, payload)
	local valid, result = schema.validate(feature_id, payload)
	return valid, result
end

storage.EMPTY_LABEL = "(empty)"

function storage.sanitize_name(name)
	return sanitize_name(name)
end

function storage.folder(feature_id)
	return feature_dir(feature_id)
end

function storage.list(feature_id)
	local root = feature_dir(feature_id)
	local files = dirs.list(root, ".json") or {}
	local names = {}
	for i = 1, #files do
		local name = extract_name(files[i])
		if name ~= "" then
			names[#names + 1] = name
		end
	end
	table.sort(names, function(a, b)
		return string.lower(a) < string.lower(b)
	end)
	if #names == 0 then
		names[1] = storage.EMPTY_LABEL
	end
	return names
end

function storage.path(feature_id, name)
	return paths.join(feature_dir(feature_id), sanitize_name(name) .. ".json")
end

function storage.save(feature_id, name, data)
	local payload = schema.wrap(feature_id, data)
	local handle = file.open(storage.path(feature_id, name), { create_if_not_exists = true })
	if not handle or not handle.valid then
		return false, "file open failed"
	end
	handle.json = json.encode(payload)
	return true
end

function storage.load(feature_id, name)
	local ok, payload = read_json_file(storage.path(feature_id, name))
	if not ok then
		return false, payload
	end
	return unwrap_payload(feature_id, payload)
end

function storage.remove(feature_id, name)
	local path = storage.path(feature_id, name)
	if not file.exists(path) then
		return false, "missing"
	end
	if file.remove(path) then
		return true
	end
	return false, "remove failed"
end

return storage
