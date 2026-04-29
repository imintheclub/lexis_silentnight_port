local schema = {}

schema.VERSION = 1

function schema.wrap(feature_id, data)
	return {
		version = schema.VERSION,
		feature = feature_id,
		data = data or {},
	}
end

function schema.validate(feature_id, payload)
	if type(payload) ~= "table" then
		return false, "payload must be a table"
	end
	if payload.version ~= schema.VERSION then
		return false, "unsupported preset version"
	end
	if payload.feature ~= feature_id then
		return false, "preset feature mismatch"
	end
	if type(payload.data) ~= "table" then
		return false, "preset data missing"
	end
	return true, payload.data
end

return schema
