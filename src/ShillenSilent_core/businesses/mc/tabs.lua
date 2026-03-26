local core = require("ShillenSilent_core.core.bootstrap")
local ui = require("ShillenSilent_core.core.ui")
local mc_logic = require("ShillenSilent_core.businesses.mc.logic")

local config = core.config

local subs = mc_logic.get_subs()

local function register(heistTab)
	if type(heistTab) ~= "table" then
		return nil
	end

	-- All-businesses actions.
	local gGlobal = ui.group(heistTab, "All Businesses", nil, nil, nil, nil, "mc")
	ui.label(gGlobal, "Moto Club", config.colors.accent)
	ui.button(gGlobal, "mc_refill_all", "Refill All Supplies", function()
		mc_logic.refill_all_supplies()
	end)
	ui.button(gGlobal, "mc_sell", "Instant Sell", function()
		mc_logic.instant_sell()
	end)
	ui.toggle(gGlobal, "mc_fast_prod", "Fast Production", mc_logic.get_fast_prod_active(), function(val)
		mc_logic.set_fast_production(val)
	end)
	ui.toggle(gGlobal, "mc_reminders", "Disable Reminders", mc_logic.get_reminders_active(), function(val)
		mc_logic.set_disable_reminders(val)
	end)

	-- Per-sub-business groups.
	for _, sub in ipairs(subs) do
		local sub_key = sub.key

		local gSub = ui.group(heistTab, sub.name, nil, nil, nil, nil, "mc")
		ui.label(gSub, sub.name, config.colors.text_sec)
		ui.button(gSub, "mc_tick_" .. sub_key, "Production Tick", function()
			mc_logic.production_tick(sub_key)
		end)
		ui.button(gSub, "mc_refill_" .. sub_key, "Refill Supplies", function()
			mc_logic.refill_supplies(sub_key)
		end)
	end

	return heistTab
end

return { register = register }
