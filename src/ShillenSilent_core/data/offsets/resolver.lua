local current = require("ShillenSilent_core.data.offsets.current")
local legacy = require("ShillenSilent_core.data.offsets.legacy")

local resolver = {
	mode = "current",
}

local function merge(base, overlay)
	local out = {}
	for k, v in pairs(base or {}) do
		out[k] = v
	end
	for k, v in pairs(overlay or {}) do
		if type(v) == "table" and type(out[k]) == "table" then
			out[k] = merge(out[k], v)
		else
			out[k] = v
		end
	end
	return out
end

function resolver.set_mode(mode)
	if mode == "legacy" then
		resolver.mode = "legacy"
	else
		resolver.mode = "current"
	end
	return resolver.mode
end

function resolver.feature(feature_id)
	local base = current[feature_id] or {}
	if resolver.mode ~= "legacy" then
		return base
	end
	return merge(base, legacy[feature_id])
end

return resolver
