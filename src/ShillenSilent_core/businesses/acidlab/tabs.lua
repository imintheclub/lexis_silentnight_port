local core = require("ShillenSilent_core.core.bootstrap")
local ui = require("ShillenSilent_core.core.ui")
local acidlab_logic = require("ShillenSilent_core.businesses.acidlab.logic")

local config = core.config

local function register(heistTab)
	if type(heistTab) ~= "table" then
		return nil
	end

	local gProd = ui.group(heistTab, "Production", nil, nil, nil, nil, "acidlab")
	ui.label(gProd, "Acid Lab", config.colors.accent)
	local fast_status_label =
		ui.label(gProd, "Fast Loop Status: " .. tostring(acidlab_logic.get_fast_prod_status()), config.colors.text_sec)
	ui.toggle(gProd, "acidlab_fast_prod", "Production Tick (Loop)", acidlab_logic.get_fast_prod_active(), function(val)
		acidlab_logic.set_fast_production(val)
	end)
	ui.button(gProd, "acidlab_refill", "Refill Supplies", function()
		acidlab_logic.refill_supplies()
	end)
	ui.button(gProd, "acidlab_sell", "Instant Sell", function()
		acidlab_logic.instant_sell()
	end)
	if util and util.create_thread and fast_status_label then
		util.create_thread(function()
			while true do
				fast_status_label.text = "Fast Loop Status: " .. tostring(acidlab_logic.get_fast_prod_status())
				util.yield(250)
			end
		end)
	end

	return heistTab
end

return { register = register }
