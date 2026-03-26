local mc_logic = require("ShillenSilent_core.businesses.mc.logic")
local common = require("ShillenSilent_core.menu.common")

local biz_mc = { ctx = { syncing = false } }

function biz_mc.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local root = parent_menu:submenu("Moto Club")
	root:breaker("Moto Club")

	local global_sub = root:submenu("All Businesses")
	common.add_button(global_sub, "Refill All Supplies", function()
		mc_logic.refill_all_supplies()
	end)
	common.add_button(global_sub, "Instant Sell", function()
		mc_logic.instant_sell()
	end)
	common.add_toggle(biz_mc.ctx, global_sub, "Fast Production", function()
		return mc_logic.get_fast_prod_active()
	end, function(enabled)
		mc_logic.set_fast_production(enabled)
	end)
	common.add_toggle(biz_mc.ctx, global_sub, "Disable Reminders", function()
		return mc_logic.get_reminders_active()
	end, function(enabled)
		mc_logic.set_disable_reminders(enabled)
	end)

	local subs = mc_logic.get_subs()
	for _, sub in ipairs(subs) do
		local sub_key = sub.key
		local sub_menu = root:submenu(sub.name)
		sub_menu:breaker(sub.name)

		common.add_button(sub_menu, "Production Tick", function()
			mc_logic.production_tick(sub_key)
		end)
		common.add_button(sub_menu, "Refill Supplies", function()
			mc_logic.refill_supplies(sub_key)
		end)

		common.add_button(sub_menu, "Teleport", function()
			mc_logic.teleport(sub_key)
		end)
	end

	return root
end

return biz_mc
