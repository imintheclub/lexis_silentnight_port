local core = require("ShillenSilent_core.core.bootstrap")
local ui = require("ShillenSilent_core.core.ui")
local garment_logic = require("ShillenSilent_core.businesses.garment.logic")

local config = core.config

local function register(heistTab)
	if type(heistTab) ~= "table" then
		return nil
	end

	local gTeleport = ui.group(heistTab, "Teleport", nil, nil, nil, nil, "garment")
	ui.label(gTeleport, "Garment Factory", config.colors.accent)
	ui.button(gTeleport, "garment_teleport", "Teleport to Entrance", function()
		garment_logic.teleport()
	end)

	return heistTab
end

return { register = register }
