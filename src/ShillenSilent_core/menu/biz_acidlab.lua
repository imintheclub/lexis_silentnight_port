local acidlab_logic = require("ShillenSilent_core.businesses.acidlab.logic")
local common = require("ShillenSilent_core.menu.common")

local biz_acidlab = { ctx = { syncing = false } }

function biz_acidlab.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local root = parent_menu:submenu("Acid Lab")
	root:breaker("Acid Lab")

	local prod = root:submenu("Production")
	common.add_button(prod, "Production Tick", function()
		acidlab_logic.production_tick()
	end)
	common.add_button(prod, "Refill Supplies", function()
		acidlab_logic.refill_supplies()
	end)
	common.add_button(prod, "Instant Sell", function()
		acidlab_logic.instant_sell()
	end)
	common.add_toggle(biz_acidlab.ctx, prod, "Fast Production", function()
		return acidlab_logic.get_fast_prod_active()
	end, function(enabled)
		acidlab_logic.set_fast_production(enabled)
	end)

	return root
end

return biz_acidlab
