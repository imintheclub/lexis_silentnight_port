local safe_access = require("ShillenSilent_core.core.safe_access")
local notify_core = require("ShillenSilent_core.core.notify")
local offsets = require("ShillenSilent_core.data.offsets.resolver")
local data = require("ShillenSilent_core.features.businesses.arcade.data")

local actions = {}

local function cfg()
	return offsets.feature(data.feature_id)
end

local push = notify_core.feature("feature.arcade.name")

function actions.collect_safe()
	local globals = cfg().globals or {}
	local ok = safe_access.set_global_int(globals.safe_collect, 1)
	push(ok and "arcade.notify.safe_collect_ok" or "arcade.notify.safe_collect_failed", 2000)
	return ok
end

return actions
