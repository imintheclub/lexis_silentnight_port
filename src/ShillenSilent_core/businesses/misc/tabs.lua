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
