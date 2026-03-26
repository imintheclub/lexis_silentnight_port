local core = require("ShillenSilent_core.core.bootstrap")
local ui = require("ShillenSilent_core.core.ui")
local nc_logic = require("ShillenSilent_core.businesses.nightclub.logic")

local config = core.config

local function register(heistTab)
	if type(heistTab) ~= "table" then
		return nil
	end

	local gProd = ui.group(heistTab, "Production", nil, nil, nil, nil, "nightclub")
	ui.label(gProd, "Nightclub", config.colors.accent)
	ui.button(gProd, "nc_tick", "Production Tick (All)", function()
		nc_logic.production_tick_all()
	end)
	ui.button(gProd, "nc_fill", "Fill All Products", function()
		nc_logic.fill_all_products()
	end)

	local gSafe = ui.group(heistTab, "Safe", nil, nil, nil, nil, "nightclub")
	ui.button(gSafe, "nc_safe_collect", "Collect Safe", function()
		nc_logic.safe_collect()
	end)
	ui.button(gSafe, "nc_safe_fill", "Fill Safe ($250K)", function()
		nc_logic.safe_fill()
	end)

	local gPop = ui.group(heistTab, "Popularity", nil, nil, nil, nil, "nightclub")
	ui.button(gPop, "nc_pop_max", "Set Popularity Max", function()
		nc_logic.set_popularity_max()
	end)

	local gProtect = ui.group(heistTab, "Protections", nil, nil, nil, nil, "nightclub")
	ui.toggle(gProtect, "nc_raids", "Disable Raids", nc_logic.get_raids_active(), function(val)
		nc_logic.set_disable_raids(val)
	end)
	ui.toggle(gProtect, "nc_reminders", "Disable Reminders", nc_logic.get_reminders_active(), function(val)
		nc_logic.set_disable_reminders(val)
	end)

	local gTeleport = ui.group(heistTab, "Teleport", nil, nil, nil, nil, "nightclub")
	ui.button(gTeleport, "nc_teleport", "Teleport", function()
		nc_logic.teleport()
	end)

	return heistTab
end

return { register = register }
