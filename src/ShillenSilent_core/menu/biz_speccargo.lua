local sc_logic = require("ShillenSilent_core.businesses.speccargo.logic")
local common = require("ShillenSilent_core.menu.common")

local biz_speccargo = { ctx = { syncing = false } }

function biz_speccargo.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local root = parent_menu:submenu("Special Cargo")
	root:breaker("Special Cargo")

	local stock = root:submenu("Stock")
	common.add_button(stock, "Instant Sell", function()
		sc_logic.instant_sell()
	end)
	common.add_button(stock, "Fill Cargo (Max 111)", function()
		sc_logic.fill_cargo()
	end)

	local protect = root:submenu("Protections")
	common.add_toggle(biz_speccargo.ctx, protect, "Disable Raids", function()
		return sc_logic.get_raids_active()
	end, function(enabled)
		sc_logic.set_disable_raids(enabled)
	end)
	common.add_toggle(biz_speccargo.ctx, protect, "Disable Reminders", function()
		return sc_logic.get_reminders_active()
	end, function(enabled)
		sc_logic.set_disable_reminders(enabled)
	end)

	local teleport = root:submenu("Teleport")
	local locations = sc_logic.get_locations()
	for i = 1, #locations do
		local idx = i
		local loc = locations[idx]
		common.add_button(teleport, loc.name, function()
			sc_logic.set_selected_loc(idx)
			sc_logic.teleport()
		end)
	end

	return root
end

return biz_speccargo
