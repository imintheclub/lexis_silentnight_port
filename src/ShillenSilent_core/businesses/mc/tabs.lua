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
	local fast_status_label =
		ui.label(gGlobal, "Fast Loop Status: " .. tostring(mc_logic.get_fast_prod_status()), config.colors.text_sec)
	ui.button(gGlobal, "mc_refill_all", "Refill All Supplies", function()
		mc_logic.refill_all_supplies()
	end)
	ui.button(gGlobal, "mc_sell", "Instant Sell", function()
		mc_logic.instant_sell()
	end)
	ui.toggle(gGlobal, "mc_fast_prod", "Production Tick (Loop)", mc_logic.get_fast_prod_active(), function(val)
		mc_logic.set_fast_production(val)
	end)
	if util and util.create_thread and fast_status_label then
		util.create_thread(function()
			while true do
				fast_status_label.text = "Fast Loop Status: " .. tostring(mc_logic.get_fast_prod_status())
				util.yield(250)
			end
		end)
	end
	ui.toggle(gGlobal, "mc_reminders", "Disable Reminders", mc_logic.get_reminders_active(), function(val)
		mc_logic.set_disable_reminders(val)
	end)

	-- Per-sub-business groups.
	for _, sub in ipairs(subs) do
		local sub_key = sub.key

		local gSub = ui.group(heistTab, sub.name, nil, nil, nil, nil, "mc")
		ui.label(gSub, sub.name, config.colors.text_sec)
		local sub_status_label = ui.label(
			gSub,
			"Loop Status: " .. tostring(mc_logic.get_sub_production_loop_status(sub_key)),
			config.colors.text_sec
		)
		ui.toggle(
			gSub,
			"mc_tick_" .. sub_key,
			"Production Tick (Loop)",
			mc_logic.get_sub_production_loop_active(sub_key),
			function(val)
				mc_logic.set_sub_production_loop(sub_key, val)
			end
		)
		ui.button(gSub, "mc_refill_" .. sub_key, "Refill Supplies", function()
			mc_logic.refill_supplies(sub_key)
		end)
		if util and util.create_thread and sub_status_label then
			util.create_thread(function()
				while true do
					sub_status_label.text = "Loop Status: "
						.. tostring(mc_logic.get_sub_production_loop_status(sub_key))
					util.yield(250)
				end
			end)
		end
	end

	return heistTab
end

return { register = register }
