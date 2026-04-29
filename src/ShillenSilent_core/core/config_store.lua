local paths = require("ShillenSilent_core.core.paths")

local config_store = {}

local function decode_json_payload(handle)
	if handle.json ~= nil then
		local ok_decode, decoded = pcall(json.decode, handle.json)
		if ok_decode and type(decoded) == "table" then
			return decoded
		end
		if type(handle.json) == "table" then
			return handle.json
		end
	end

	if handle.text and handle.text ~= "" then
		local ok_decode_text, decoded_text = pcall(json.decode, handle.text)
		if ok_decode_text and type(decoded_text) == "table" then
			return decoded_text
		end
	end

	return {}
end

function config_store.read()
	local ok, payload = pcall(function()
		local handle = file.open(paths.config_path, { append = false, create_if_not_exists = false })
		if not handle or not handle.valid then
			return {}
		end
		return decode_json_payload(handle)
	end)

	if ok and type(payload) == "table" then
		return payload
	end
	return {}
end

function config_store.write(payload)
	if type(payload) ~= "table" then
		payload = {}
	end

	paths.ensure()
	local ok, err = pcall(function()
		local handle = file.open(paths.config_path, { create_if_not_exists = true })
		if not handle or not handle.valid then
			error("Invalid config file handle")
		end
		handle.json = json.encode(payload)
	end)

	return ok, err
end

function config_store.get(key, fallback)
	local payload = config_store.read()
	local value = payload[key]
	if value == nil then
		return fallback
	end
	return value
end

function config_store.set(key, value)
	local payload = config_store.read()
	payload[key] = value
	return config_store.write(payload)
end

return config_store
