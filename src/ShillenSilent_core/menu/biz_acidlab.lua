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
	local fast_status_breaker = prod:breaker("Fast Loop Status: " .. tostring(acidlab_logic.get_fast_prod_status()))
	common.add_toggle(biz_acidlab.ctx, prod, "Production Tick (Loop)", function()
		return acidlab_logic.get_fast_prod_active()
	end, function(enabled)
		acidlab_logic.set_fast_production(enabled)
	end)
	common.add_button(prod, "Refill Supplies", function()
		acidlab_logic.refill_supplies()
	end)
	common.add_button(prod, "Instant Sell", function()
		acidlab_logic.instant_sell()
	end)
	if util and util.create_thread and fast_status_breaker then
		util.create_thread(function()
			while true do
				fast_status_breaker.name = "Fast Loop Status: " .. tostring(acidlab_logic.get_fast_prod_status())
				util.yield(250)
			end
		end)
	end

	return root
end

return biz_acidlab
