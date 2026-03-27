local core = require("ShillenSilent_core.core.bootstrap")
local ui = require("ShillenSilent_core.core.ui")
local bunker_logic = require("ShillenSilent_core.businesses.bunker.logic")

local config = core.config

local function register(heistTab)
	if type(heistTab) ~= "table" then
		return nil
	end

	local gProd = ui.group(heistTab, "Production", nil, nil, nil, nil, "bunker")
	ui.label(gProd, "Bunker", config.colors.accent)
	local fast_status_label =
		ui.label(gProd, "Fast Loop Status: " .. tostring(bunker_logic.get_fast_prod_status()), config.colors.text_sec)
	ui.toggle(gProd, "bunker_fast_prod", "Production Tick (Loop)", bunker_logic.get_fast_prod_active(), function(val)
		bunker_logic.set_fast_production(val)
	end)
	ui.button(gProd, "bunker_refill", "Refill Supplies", function()
		bunker_logic.refill_supplies()
	end)
	if util and util.create_thread and fast_status_label then
		util.create_thread(function()
			while true do
				fast_status_label.text = "Fast Loop Status: " .. tostring(bunker_logic.get_fast_prod_status())
				util.yield(250)
			end
		end)
	end
	ui.button(gProd, "bunker_sell", "Instant Sell", function()
		bunker_logic.instant_sell()
	end)

	local gProtect = ui.group(heistTab, "Protections", nil, nil, nil, nil, "bunker")
	ui.toggle(gProtect, "bunker_raids", "Disable Raids", bunker_logic.get_raids_active(), function(val)
		bunker_logic.set_disable_raids(val)
	end)
	ui.toggle(gProtect, "bunker_reminders", "Disable Reminders", bunker_logic.get_reminders_active(), function(val)
		bunker_logic.set_disable_reminders(val)
	end)

	local gTeleport = ui.group(heistTab, "Teleport", nil, nil, nil, nil, "bunker")
	ui.button(gTeleport, "bunker_teleport", "Teleport", function()
		bunker_logic.teleport()
	end)

	return heistTab
end

return { register = register }
