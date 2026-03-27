local core = require("ShillenSilent_core.core.bootstrap")
local ui = require("ShillenSilent_core.core.ui")
local nc_logic = require("ShillenSilent_core.businesses.nightclub.logic")

local config = core.config

local function register(heistTab)
	if type(heistTab) ~= "table" then
		return nil
	end

	local gProd = ui.group(heistTab, "Production", nil, nil, nil, nil, "nightclub")
	ui.label(gProd, "Nightclub", config.colors.accent)
	local fast_status_label =
		ui.label(gProd, "Fast Loop Status: " .. tostring(nc_logic.get_fast_prod_status()), config.colors.text_sec)
	local target_options = nc_logic.get_fast_product_options()
	local target_names = {}
	local selected_idx = 1
	local current_target = nc_logic.get_fast_prod_target()
	for i = 1, #target_options do
		target_names[i] = target_options[i].name
		if target_options[i].value == current_target then
			selected_idx = i
		end
	end
	ui.dropdown(gProd, "nc_fast_target", "Fast NC Target", target_names, selected_idx, function(opt)
		if not opt or not opt.value then
			return
		end
		local idx = tonumber(opt.value) or 1
		local selected = target_options[idx]
		if selected then
			nc_logic.set_fast_prod_target(selected.value)
		end
	end)
	ui.toggle(
		gProd,
		"nc_tick",
		"Increased Nightclub Production (Tunables)",
		nc_logic.get_fast_prod_active(),
		function(val)
			nc_logic.set_fast_production(val)
		end
	)
	ui.button(gProd, "nc_fill", "Fill All Products", function()
		nc_logic.fill_all_products()
	end)
	if util and util.create_thread and fast_status_label then
		util.create_thread(function()
			while true do
				fast_status_label.text = "Fast Loop Status: " .. tostring(nc_logic.get_fast_prod_status())
				util.yield(250)
			end
		end)
	end

	local gSafe = ui.group(heistTab, "Safe", nil, nil, nil, nil, "nightclub")
	ui.button(gSafe, "nc_safe_collect", "Collect Safe", function()
		nc_logic.safe_collect()
	end)
	ui.button(gSafe, "nc_safe_fill", "Fill Safe ($250K)", function()
		nc_logic.safe_fill()
	end)

	local gPop = ui.group(heistTab, "Popularity", nil, nil, nil, nil, "nightclub")
	ui.button(gPop, "nc_pop_max", "Set Popularity Max", function()
		nc_logic.set_popularity_max()
	end)

	local gProtect = ui.group(heistTab, "Protections", nil, nil, nil, nil, "nightclub")
	ui.toggle(gProtect, "nc_raids", "Disable Raids", nc_logic.get_raids_active(), function(val)
		nc_logic.set_disable_raids(val)
	end)
	ui.toggle(gProtect, "nc_reminders", "Disable Reminders", nc_logic.get_reminders_active(), function(val)
		nc_logic.set_disable_reminders(val)
	end)

	local gTeleport = ui.group(heistTab, "Teleport", nil, nil, nil, nil, "nightclub")
	ui.button(gTeleport, "nc_teleport", "Teleport", function()
		nc_logic.teleport()
	end)

	return heistTab
end

return { register = register }
