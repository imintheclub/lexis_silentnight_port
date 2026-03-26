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
	common.add_button(prod, "Production Tick (All)", function()
		nc_logic.production_tick_all()
	end)
	common.add_button(prod, "Fill All Products", function()
		nc_logic.fill_all_products()
	end)

	local safe = root:submenu("Safe")
	common.add_button(safe, "Collect Safe", function()
		nc_logic.safe_collect()
	end)
	common.add_button(safe, "Fill Safe ($250K)", function()
		nc_logic.safe_fill()
	end)

	local pop = root:submenu("Popularity")
	common.add_button(pop, "Set Popularity Max", function()
		nc_logic.set_popularity_max()
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
