local safe_access = require("ShillenSilent_core.core.safe_access")
local notify_core = require("ShillenSilent_core.core.notify")
local offsets = require("ShillenSilent_core.data.offsets.current")
local data = require("ShillenSilent_core.features.businesses.arcade.data")

local actions = {}

local function cfg()
	return offsets[data.feature_id] or {}
end

local push = notify_core.feature("feature.arcade.name")

function actions.collect_safe()
	local offsets_cfg = cfg()
	local stats = offsets_cfg.stats or {}
	local value = safe_access.get_mp_stat_int(stats.safe_cash_value, 0) or 0
	if value <= 0 then
		push("arcade.notify.safe_empty", 2000)
		return false
	end

	local globals = offsets_cfg.globals or {}
	local ok = safe_access.set_global_bool(globals.safe_collect, true)
	push(ok and "arcade.notify.safe_collect_ok" or "arcade.notify.safe_collect_failed", 2000)
	return ok
end

return actions
