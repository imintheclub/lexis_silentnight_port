local mf_logic = require("ShillenSilent_core.businesses.moneyfronts.logic")
local garment_logic = require("ShillenSilent_core.businesses.garment.logic")
local bailoffice_logic = require("ShillenSilent_core.businesses.bailoffice.logic")
local common = require("ShillenSilent_core.menu.common")

local biz_misc = { ctx = { syncing = false } }

function biz_misc.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local root = parent_menu:submenu("Misc")
	root:breaker("Misc")

	-- Money Fronts
	local mf_root = root:submenu("Money Fronts")
	mf_root:breaker("Money Fronts")
	local mf_teleport = mf_root:submenu("Teleport")
	local mf_locs = mf_logic.get_locations()
	for i = 1, #mf_locs do
		local idx = i
		local loc = mf_locs[idx]
		common.add_button(mf_teleport, loc.name, function()
			mf_logic.set_selected_loc(idx)
			mf_logic.teleport()
		end)
	end
	local mf_heat = mf_root:submenu("Heat")
	common.add_number_int(biz_misc.ctx, mf_heat, "Heat Value", 0, 100, 5, function()
		return mf_logic.get_heat_editor_value()
	end, function(value)
		mf_logic.set_heat_editor_value(value)
	end)
	common.add_button(mf_heat, "Apply Heat", function()
		mf_logic.apply_heat_editor_value()
	end)
	common.add_button(mf_heat, "Set Heat 0", function()
		mf_logic.reset_heat()
	end)
	common.add_toggle(biz_misc.ctx, mf_heat, "Lock Heat at 0", function()
		return mf_logic.get_heat_lock_active()
	end, function(enabled)
		mf_logic.set_heat_lock_active(enabled)
	end)

	-- Garment Factory
	local garment_root = root:submenu("Garment Factory")
	garment_root:breaker("Garment Factory")
	common.add_button(garment_root, "Teleport", function()
		garment_logic.teleport()
	end)

	-- Bail Office
	local bail_root = root:submenu("Bail Office")
	bail_root:breaker("Bail Office")
	common.add_button(bail_root, "Teleport", function()
		bailoffice_logic.teleport()
	end)

	return root
end

return biz_misc
