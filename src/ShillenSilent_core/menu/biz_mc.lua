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
	local fast_status_breaker = global_sub:breaker("Fast Loop Status: " .. tostring(mc_logic.get_fast_prod_status()))
	common.add_button(global_sub, "Refill All Supplies", function()
		mc_logic.refill_all_supplies()
	end)
	common.add_button(global_sub, "Instant Sell", function()
		mc_logic.instant_sell()
	end)
	common.add_toggle(biz_mc.ctx, global_sub, "Production Tick (Loop)", function()
		return mc_logic.get_fast_prod_active()
	end, function(enabled)
		mc_logic.set_fast_production(enabled)
	end)
	common.add_toggle(biz_mc.ctx, global_sub, "Disable Reminders", function()
		return mc_logic.get_reminders_active()
	end, function(enabled)
		mc_logic.set_disable_reminders(enabled)
	end)
	if util and util.create_thread and fast_status_breaker then
		util.create_thread(function()
			while true do
				fast_status_breaker.name = "Fast Loop Status: " .. tostring(mc_logic.get_fast_prod_status())
				util.yield(250)
			end
		end)
	end

	local subs = mc_logic.get_subs()
	for _, sub in ipairs(subs) do
		local sub_key = sub.key
		local sub_menu = root:submenu(sub.name)
		sub_menu:breaker(sub.name)
		local sub_status_breaker =
			sub_menu:breaker("Loop Status: " .. tostring(mc_logic.get_sub_production_loop_status(sub_key)))

		common.add_toggle(biz_mc.ctx, sub_menu, "Production Tick (Loop)", function()
			return mc_logic.get_sub_production_loop_active(sub_key)
		end, function(enabled)
			mc_logic.set_sub_production_loop(sub_key, enabled)
		end)
		common.add_button(sub_menu, "Refill Supplies", function()
			mc_logic.refill_supplies(sub_key)
		end)
		if util and util.create_thread and sub_status_breaker then
			util.create_thread(function()
				while true do
					sub_status_breaker.name = "Loop Status: "
						.. tostring(mc_logic.get_sub_production_loop_status(sub_key))
					util.yield(250)
				end
			end)
		end
	end

	return root
end

return biz_mc
