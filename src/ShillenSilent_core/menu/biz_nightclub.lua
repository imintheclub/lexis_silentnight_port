local nc_logic = require("ShillenSilent_core.businesses.nightclub.logic")
local common = require("ShillenSilent_core.menu.common")

local biz_nightclub = { ctx = { syncing = false } }

function biz_nightclub.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local root = parent_menu:submenu("Nightclub")
	root:breaker("Nightclub")

	local prod = root:submenu("Production")
	local fast_status_breaker = prod:breaker("Fast Loop Status: " .. tostring(nc_logic.get_fast_prod_status()))
	common.add_combo_options(biz_nightclub.ctx, prod, "Fast NC Target", nc_logic.get_fast_product_options(), function()
		return nc_logic.get_fast_prod_target()
	end, function(value)
		nc_logic.set_fast_prod_target(value)
	end)
	common.add_toggle(biz_nightclub.ctx, prod, "Increased Nightclub Production (Tunables)", function()
		return nc_logic.get_fast_prod_active()
	end, function(enabled)
		nc_logic.set_fast_production(enabled)
	end)
	common.add_button(prod, "Fill All Products", function()
		nc_logic.fill_all_products()
	end)
	if util and util.create_thread and fast_status_breaker then
		util.create_thread(function()
			while true do
				fast_status_breaker.name = "Fast Loop Status: " .. tostring(nc_logic.get_fast_prod_status())
				util.yield(250)
			end
		end)
	end

	local safe = root:submenu("Safe")
	common.add_button(safe, "Collect Safe", function()
		nc_logic.safe_collect()
	end)
	common.add_button(safe, "Fill Safe ($250K)", function()
		nc_logic.safe_fill()
	end)
	common.add_button(safe, "Unbrick Safe", function()
		nc_logic.safe_unbrick()
	end)

	local pop = root:submenu("Popularity")
	common.add_number_int(biz_nightclub.ctx, pop, "Popularity", 0, 1000, 10, function()
		return nc_logic.get_popularity_editor_value()
	end, function(value)
		nc_logic.set_popularity_editor_value(value)
	end)
	common.add_button(pop, "Apply Popularity", function()
		nc_logic.apply_popularity_editor_value()
	end)
	common.add_toggle(biz_nightclub.ctx, pop, "Lock Popularity", function()
		return nc_logic.get_popularity_lock_active()
	end, function(enabled)
		nc_logic.set_popularity_lock_active(enabled)
	end)

	local protect = root:submenu("Protections")
	common.add_toggle(biz_nightclub.ctx, protect, "Disable Raids", function()
		return nc_logic.get_raids_active()
	end, function(enabled)
		nc_logic.set_disable_raids(enabled)
	end)
	common.add_toggle(biz_nightclub.ctx, protect, "Disable Reminders", function()
		return nc_logic.get_reminders_active()
	end, function(enabled)
		nc_logic.set_disable_reminders(enabled)
	end)

	common.add_button(root, "Teleport", function()
		nc_logic.teleport()
	end)

	return root
end

return biz_nightclub
