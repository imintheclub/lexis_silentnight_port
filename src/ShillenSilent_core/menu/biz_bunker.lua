local bunker_logic = require("ShillenSilent_core.businesses.bunker.logic")
local common = require("ShillenSilent_core.menu.common")

local biz_bunker = { ctx = { syncing = false } }

function biz_bunker.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local root = parent_menu:submenu("Bunker")
	root:breaker("Bunker")

	local prod = root:submenu("Production")
	common.add_button(prod, "Production Tick", function()
		bunker_logic.production_tick()
	end)
	common.add_button(prod, "Refill Supplies", function()
		bunker_logic.refill_supplies()
	end)
	common.add_button(prod, "Instant Sell", function()
		bunker_logic.instant_sell()
	end)

	local protect = root:submenu("Protections")
	common.add_toggle(biz_bunker.ctx, protect, "Disable Raids", function()
		return bunker_logic.get_raids_active()
	end, function(enabled)
		bunker_logic.set_disable_raids(enabled)
	end)
	common.add_toggle(biz_bunker.ctx, protect, "Disable Reminders", function()
		return bunker_logic.get_reminders_active()
	end, function(enabled)
		bunker_logic.set_disable_reminders(enabled)
	end)

	common.add_button(root, "Teleport", function()
		bunker_logic.teleport()
	end)

	return root
end

return biz_bunker
