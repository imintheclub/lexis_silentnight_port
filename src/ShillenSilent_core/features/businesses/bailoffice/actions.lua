local safe_access = require("ShillenSilent_core.core.safe_access")
local notify_core = require("ShillenSilent_core.core.notify")
local i18n = require("ShillenSilent_core.i18n")
local offsets = require("ShillenSilent_core.data.offsets.current")
local blip_teleport = require("ShillenSilent_core.shared.blip_teleport")
local coords_teleport = require("ShillenSilent_core.shared.coords_teleport")
local data = require("ShillenSilent_core.features.businesses.bailoffice.data")
local state = require("ShillenSilent_core.features.businesses.bailoffice.state")

local actions = {}

local function cfg()
	return offsets[data.feature_id] or {}
end

local t = i18n.t

local push = notify_core.feature("feature.bailoffice.name")

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
		t("feature.bailoffice.name"),
		t("bailoffice.notify.teleported"),
		t("bailoffice.notify.entrance_missing"),
		{
			fallback_coords = loc,
			fallback_message = t("bailoffice.notify.teleported"),
		}
	)
end

function actions.teleport_computer()
	local coords = cfg().coords and cfg().coords.computer
	if not coords then
		return false
	end
	return coords_teleport.run_coords_teleport(
		t("feature.bailoffice.name"),
		t("bailoffice.notify.teleported_computer"),
		coords.x,
		coords.y,
		coords.z,
		false,
		nil
	)
end

function actions.collect_safe()
	local offsets_cfg = cfg()
	local stats = offsets_cfg.stats or {}
	local value = safe_access.get_mp_stat_int(stats.safe_cash_value, 0) or 0
	if value <= 0 then
		push("bailoffice.notify.safe_empty", 2000)
		return false
	end
	local globals = offsets_cfg.globals or {}
	local ok = safe_access.set_global_bool(globals.safe_collect, true)
	push(ok and "bailoffice.notify.safe_collect_ok" or "bailoffice.notify.safe_collect_failed", 2000)
	return ok
end

function actions.apply_current_state()
	state.set_location_index(state.config.location_index)
	return true
end

return actions
