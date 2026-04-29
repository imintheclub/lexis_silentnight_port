local storage = require("ShillenSilent_core.presets.storage")

local presets = {}

function presets.save(feature_id, data, name)
	return storage.save(feature_id, name or "QuickPreset", data)
end

function presets.load(feature_id, name)
	return storage.load(feature_id, name or "QuickPreset")
end

function presets.list(feature_id)
	return storage.list(feature_id)
end

function presets.remove(feature_id, name)
	return storage.remove(feature_id, name)
end

function presets.folder(feature_id)
	return storage.folder(feature_id)
end

function presets.sanitize_name(name)
	return storage.sanitize_name(name)
end

presets.EMPTY_LABEL = storage.EMPTY_LABEL

return presets
