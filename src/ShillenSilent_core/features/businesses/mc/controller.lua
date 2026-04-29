local common = require("ShillenSilent_core.ui.controller.widgets")
local i18n = require("ShillenSilent_core.i18n")
local data = require("ShillenSilent_core.features.businesses.mc.data")
local state = require("ShillenSilent_core.features.businesses.mc.state")
local actions = require("ShillenSilent_core.features.businesses.mc.actions")

local controller = {
	ctx = { syncing = false },
	controls = {
		sub_toggles = {},
		sub_status = {},
	},
}

local t = i18n.t

function controller.refresh_controls()
	local ctx = controller.ctx
	local controls = controller.controls
	if controls.fast_status_breaker then
		controls.fast_status_breaker.name = t("mc.status.fast_loop", { status = actions.get_fast_prod_status() })
	end
	common.set_control_value(ctx, controls.fast_toggle, state.fast_production.active == true)
	common.set_control_value(ctx, controls.reminders_toggle, state.protections.reminders_active == true)
	common.set_control_value(ctx, controls.raids_toggle, state.protections.raids_active == true)
	for i = 1, #data.subs do
		local key = data.subs[i].key
		if controls.sub_status[key] then
			controls.sub_status[key].name =
				t("mc.status.loop", { status = actions.get_sub_production_loop_status(key) })
		end
		common.set_control_value(ctx, controls.sub_toggles[key], state.sub_production.active[key] == true)
	end
	return true
end

function controller.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local ctx = controller.ctx
	local controls = controller.controls

	local root = parent_menu:submenu(t("feature.mc.name"))
	root:breaker(t("feature.mc.name"))

	local global = root:submenu(t("mc.group.all_businesses"))
	controls.fast_status_breaker = global:breaker(t("mc.status.fast_loop", { status = actions.get_fast_prod_status() }))
	common.add_button(global, t("mc.action.refill_all"), actions.refill_all_supplies)
	common.add_button(global, t("mc.action.instant_sell"), actions.instant_sell)
	controls.fast_toggle = common.add_toggle(ctx, global, t("mc.action.production_tick_loop"), function()
		return actions.get_fast_prod_active()
	end, function(enabled)
		actions.set_fast_production(enabled)
		controller.refresh_controls()
	end)
	controls.reminders_toggle = common.add_toggle(ctx, global, t("mc.action.disable_reminders"), function()
		return actions.get_reminders_active()
	end, function(enabled)
		actions.set_disable_reminders(enabled)
		controller.refresh_controls()
	end)
	controls.raids_toggle = common.add_toggle(ctx, global, t("mc.action.disable_raids"), function()
		return actions.get_raids_active()
	end, function(enabled)
		actions.set_disable_raids(enabled)
		controller.refresh_controls()
	end)
	common.add_button(global, t("mc.action.kill_black_screen"), actions.kill_black_screen)

	for i = 1, #data.subs do
		local sub = data.subs[i]
		local sub_menu = root:submenu(t(sub.label_key))
		sub_menu:breaker(t(sub.label_key))
		controls.sub_status[sub.key] =
			sub_menu:breaker(t("mc.status.loop", { status = actions.get_sub_production_loop_status(sub.key) }))
		controls.sub_toggles[sub.key] = common.add_toggle(ctx, sub_menu, t("mc.action.production_tick_loop"), function()
			return actions.get_sub_production_loop_active(sub.key)
		end, function(enabled)
			actions.set_sub_production_loop(sub.key, enabled)
			controller.refresh_controls()
		end)
		common.add_button(sub_menu, t("mc.action.refill_supplies"), function()
			actions.refill_supplies(sub.key)
		end)
		common.add_button(sub_menu, t("mc.action.teleport"), function()
			actions.teleport(sub.key)
		end)
	end

	controller.refresh_controls()
	return root
end

return controller
