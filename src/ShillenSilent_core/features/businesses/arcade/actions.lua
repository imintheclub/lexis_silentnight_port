local safe_access = require("ShillenSilent_core.core.safe_access")
local notify_core = require("ShillenSilent_core.core.notify")
local i18n = require("ShillenSilent_core.i18n")
local offsets = require("ShillenSilent_core.data.offsets.current")
local blip_teleport = require("ShillenSilent_core.shared.blip_teleport")
local data = require("ShillenSilent_core.features.businesses.arcade.data")

local actions = {}

local function cfg()
	return offsets[data.feature_id] or {}
end

local t = i18n.t

local push = notify_core.feature("feature.arcade.name")

function actions.is_owned()
	local stats = cfg().stats or {}
	return (safe_access.get_mp_stat_int(stats.owned, 0) or 0) ~= 0
end

function actions.teleport()
	if not actions.is_owned() then
		push("arcade.notify.not_owned", 2000)
		return false
	end

	local offsets_cfg = cfg()
	return blip_teleport.teleport_to_blip_with_job(
		offsets_cfg.blips and offsets_cfg.blips.entrance,
		t("feature.arcade.name"),
		t("arcade.notify.teleported"),
		t("arcade.notify.entrance_missing"),
		{ relay_if_interior = true }
	)
end

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
