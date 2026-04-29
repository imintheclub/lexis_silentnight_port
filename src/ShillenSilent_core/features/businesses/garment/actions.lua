local safe_access = require("ShillenSilent_core.core.safe_access")
local notify_core = require("ShillenSilent_core.core.notify")
local i18n = require("ShillenSilent_core.i18n")
local offsets = require("ShillenSilent_core.data.offsets.resolver")
local blip_teleport = require("ShillenSilent_core.shared.blip_teleport")
local data = require("ShillenSilent_core.features.businesses.garment.data")
local state = require("ShillenSilent_core.features.businesses.garment.state")

local actions = {}

local function cfg()
	return offsets.feature(data.feature_id)
end

local t = i18n.t

local push = notify_core.feature("feature.garment.name")

function actions.get_locations()
	return data.locations
end

function actions.get_selected_loc()
	return state.config.location_index
end

function actions.set_selected_loc(idx)
	state.set_location_index(idx)
end

function actions.teleport()
	local loc = data.locations[state.config.location_index]
	if not loc then
		return false
	end

	local offsets_cfg = cfg()
	return blip_teleport.teleport_to_blip_with_job(
		offsets_cfg.blips and offsets_cfg.blips.entrance,
		t("feature.garment.name"),
		t("garment.notify.teleported"),
		t("garment.notify.entrance_missing"),
		{
			fallback_coords = loc,
			fallback_message = t("garment.notify.teleported"),
		}
	)
end

function actions.collect_safe()
	local globals = cfg().globals or {}
	local ok = safe_access.set_global_int(globals.safe_collect, 1)
	push(ok and "garment.notify.safe_collect_ok" or "garment.notify.safe_collect_failed", 2000)
	return ok
end

function actions.apply_current_state()
	state.set_location_index(state.config.location_index)
	return true
end

return actions
