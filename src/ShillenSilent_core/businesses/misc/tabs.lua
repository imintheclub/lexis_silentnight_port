local core = require("ShillenSilent_core.core.bootstrap")
local ui = require("ShillenSilent_core.core.ui")
local mf_logic = require("ShillenSilent_core.businesses.moneyfronts.logic")
local garment_logic = require("ShillenSilent_core.businesses.garment.logic")
local bailoffice_logic = require("ShillenSilent_core.businesses.bailoffice.logic")

local config = core.config

local mf_locations = mf_logic.get_locations()
local mf_loc_names = {}
for i, v in ipairs(mf_locations) do
	mf_loc_names[i] = v.name
end

local function register(heistTab)
	if type(heistTab) ~= "table" then
		return nil
	end

	-- Money Fronts card
	local gMF = ui.group(heistTab, "Money Fronts", nil, nil, nil, nil, "misc")
	ui.label(gMF, "Money Fronts", config.colors.accent)
	ui.dropdown(gMF, "mf_loc", "Location", mf_loc_names, mf_logic.get_selected_loc(), function(opt)
		for i, v in ipairs(mf_locations) do
			if v.name == opt then
				mf_logic.set_selected_loc(i)
				break
			end
		end
	end)
	ui.button(gMF, "mf_teleport", "Teleport", function()
		mf_logic.teleport()
	end)
	ui.slider(gMF, "mf_heat_value", "Heat", 0, 100, mf_logic.get_heat_editor_value(), function(val)
		mf_logic.set_heat_editor_value(val)
	end, "Set Money Front heat value", 5)
	ui.button_pair(
		gMF,
		"mf_heat_apply",
		"Apply Heat",
		function()
			mf_logic.apply_heat_editor_value()
		end,
		"mf_heat_reset",
		"Set Heat 0",
		function()
			mf_logic.reset_heat()
		end
	)
	ui.toggle(gMF, "mf_heat_lock", "Lock Heat at 0", mf_logic.get_heat_lock_active(), function(val)
		mf_logic.set_heat_lock_active(val)
	end)
	ui.button(gMF, "mf_reset_safe_prod", "Reset Safe Production State", function()
		mf_logic.reset_safe_production_state()
	end)

	-- Garment Factory card
	local gGarment = ui.group(heistTab, "Garment Factory", nil, nil, nil, nil, "misc")
	ui.label(gGarment, "Garment Factory", config.colors.accent)
	ui.button(gGarment, "garment_teleport", "Teleport to Entrance", function()
		garment_logic.teleport()
	end)

	-- Bail Office card
	local gBail = ui.group(heistTab, "Bail Office", nil, nil, nil, nil, "misc")
	ui.label(gBail, "Bail Office", config.colors.accent)
	ui.button(gBail, "bail_teleport", "Teleport", function()
		bailoffice_logic.teleport()
	end)

	return heistTab
end

return { register = register }
