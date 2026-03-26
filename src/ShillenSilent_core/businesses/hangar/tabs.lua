local core = require("ShillenSilent_core.core.bootstrap")
local ui = require("ShillenSilent_core.core.ui")
local hangar_logic = require("ShillenSilent_core.businesses.hangar.logic")

local config = core.config

local function register(heistTab)
	if type(heistTab) ~= "table" then
		return nil
	end

	local gStock = ui.group(heistTab, "Stock", nil, nil, nil, nil, "hangar")
	ui.label(gStock, "Hangar", config.colors.accent)
	ui.button(gStock, "hangar_fill", "Fill Cargo (Max)", function()
		hangar_logic.fill_cargo()
	end)

	local gTeleport = ui.group(heistTab, "Teleport", nil, nil, nil, nil, "hangar")
	ui.button(gTeleport, "hangar_teleport", "Teleport", function()
		hangar_logic.teleport()
	end)

	return heistTab
end

return { register = register }
