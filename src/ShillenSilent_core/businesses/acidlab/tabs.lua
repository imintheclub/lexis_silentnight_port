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
	ui.button(gProd, "acidlab_tick", "Production Tick", function()
		acidlab_logic.production_tick()
	end)
	ui.button(gProd, "acidlab_refill", "Refill Supplies", function()
		acidlab_logic.refill_supplies()
	end)
	ui.button(gProd, "acidlab_sell", "Instant Sell", function()
		acidlab_logic.instant_sell()
	end)
	ui.toggle(gProd, "acidlab_fast_prod", "Fast Production", acidlab_logic.get_fast_prod_active(), function(val)
		acidlab_logic.set_fast_production(val)
	end)

	return heistTab
end

return { register = register }
