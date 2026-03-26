local core = require("ShillenSilent_core.core.bootstrap")
local ui = require("ShillenSilent_core.core.ui")
local sc_logic = require("ShillenSilent_core.businesses.speccargo.logic")

local config = core.config

local function register(heistTab)
	if type(heistTab) ~= "table" then
		return nil
	end

	local gStock = ui.group(heistTab, "Stock", nil, nil, nil, nil, "speccargo")
	ui.label(gStock, "Special Cargo", config.colors.accent)
	ui.button(gStock, "sc_instant_sell", "Instant Sell", function()
		sc_logic.instant_sell()
	end)
	ui.button(gStock, "sc_fill", "Fill Cargo (Max 111)", function()
		sc_logic.fill_cargo()
	end)

	local gProtect = ui.group(heistTab, "Protections", nil, nil, nil, nil, "speccargo")
	ui.toggle(gProtect, "sc_raids", "Disable Raids", sc_logic.get_raids_active(), function(val)
		sc_logic.set_disable_raids(val)
	end)
	ui.toggle(gProtect, "sc_reminders", "Disable Reminders", sc_logic.get_reminders_active(), function(val)
		sc_logic.set_disable_reminders(val)
	end)

	local gTeleport = ui.group(heistTab, "Teleport", nil, nil, nil, nil, "speccargo")
	local locations = sc_logic.get_locations()
	local loc_names = {}
	for i, v in ipairs(locations) do
		loc_names[i] = v.name
	end

	if #loc_names > 0 then
		ui.dropdown(gTeleport, "sc_loc", "Location", loc_names, sc_logic.get_selected_loc(), function(opt)
			for i, v in ipairs(locations) do
				if v.name == opt then
					sc_logic.set_selected_loc(i)
					break
				end
			end
		end)
		ui.button(gTeleport, "sc_teleport", "Teleport", function()
			sc_logic.teleport()
		end)
	else
		ui.label(gTeleport, "No owned warehouses found", config.colors.muted_text)
	end

	return heistTab
end

return { register = register }
