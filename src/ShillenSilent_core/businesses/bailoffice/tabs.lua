local core = require("ShillenSilent_core.core.bootstrap")
local ui = require("ShillenSilent_core.core.ui")
local bailoffice_logic = require("ShillenSilent_core.businesses.bailoffice.logic")

local config = core.config
local locations = bailoffice_logic.get_locations()
local loc_names = {}
for i, v in ipairs(locations) do
	loc_names[i] = v.name
end

local function register(heistTab)
	if type(heistTab) ~= "table" then
		return nil
	end

	local gTeleport = ui.group(heistTab, "Teleport", nil, nil, nil, nil, "bailoffice")
	ui.label(gTeleport, "Bail Office", config.colors.accent)
	ui.dropdown(gTeleport, "bail_loc", "Location", loc_names, bailoffice_logic.get_selected_loc(), function(opt)
		for i, v in ipairs(locations) do
			if v.name == opt then
				bailoffice_logic.set_selected_loc(i)
				break
			end
		end
	end)
	ui.button(gTeleport, "bail_teleport", "Teleport", function()
		bailoffice_logic.teleport()
	end)

	return heistTab
end

return { register = register }
