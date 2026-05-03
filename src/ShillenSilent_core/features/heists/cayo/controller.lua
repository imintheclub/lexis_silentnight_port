local common = require("ShillenSilent_core.ui.controller.widgets")
local i18n = require("ShillenSilent_core.i18n")
local notify_core = require("ShillenSilent_core.core.notify")
local preset_ui = require("ShillenSilent_core.presets.ui")
local data = require("ShillenSilent_core.features.heists.cayo.data")
local state = require("ShillenSilent_core.features.heists.cayo.state")
local actions = require("ShillenSilent_core.features.heists.cayo.actions")
local cayo_presets = require("ShillenSilent_core.features.heists.cayo.presets")

local controller = {
	ctx = { syncing = false },
	controls = {},
}

local t = i18n.t

local push = notify_core.feature("feature.cayo.name")

local function localized(options)
	return data.localized_options(options, t)
end

local function add_combo(parent, key, label_key, options, get_value, set_value)
	controller.controls[key] = common.add_combo_options(
		controller.ctx,
		parent,
		t(label_key),
		localized(options),
		get_value,
		function(value)
			set_value(value)
			controller.refresh_controls()
		end
	)
end

local function add_number(parent, key, label_key, min_value, max_value, step, get_value, set_value)
	controller.controls[key] = common.add_number_int(
		controller.ctx,
		parent,
		t(label_key),
		min_value,
		max_value,
		step,
		get_value,
		function(value)
			set_value(value)
			controller.refresh_controls()
		end
	)
end

local function add_toggle(parent, key, label_key, get_value, set_value)
	controller.controls[key] = common.add_toggle(controller.ctx, parent, t(label_key), get_value, function(value)
		set_value(value)
		controller.refresh_controls()
	end)
end

function controller.refresh_controls()
	local ctx = controller.ctx
	local controls = controller.controls
	local cfg = state.config
	common.set_control_value(ctx, controls.womans_bag_toggle, state.flags.womans_bag_enabled)
	common.set_control_value(ctx, controls.unlock_on_apply_toggle, cfg.unlock_all_poi)
	common.set_control_value(ctx, controls.remove_crew_cuts_toggle, state.flags.remove_crew_cuts_enabled)
	common.set_control_value(ctx, controls.max_payout_toggle, state.flags.max_payout_enabled)
	common.set_control_value(ctx, controls.difficulty_combo, data.option_index_by_value(data.difficulties, cfg.diff, 1))
	common.set_control_value(ctx, controls.approach_combo, data.option_index_by_value(data.approaches, cfg.app, 1))
	common.set_control_value(ctx, controls.loadout_combo, data.option_index_by_value(data.loadouts, cfg.wep, 1))
	common.set_control_value(
		ctx,
		controls.primary_target_combo,
		data.option_index_by_value(data.primary_targets, cfg.tgt, 1)
	)
	common.set_control_value(
		ctx,
		controls.compound_target_combo,
		data.option_index_by_value(data.secondary_targets, cfg.sec_comp, 1)
	)
	common.set_control_value(
		ctx,
		controls.compound_amount_combo,
		data.option_index_by_value(data.compound_amounts, cfg.amt_comp, 1)
	)
	common.set_control_value(
		ctx,
		controls.arts_amount_combo,
		data.option_index_by_value(data.arts_amounts, cfg.paint, 1)
	)
	common.set_control_value(
		ctx,
		controls.island_target_combo,
		data.option_index_by_value(data.secondary_targets, cfg.sec_isl, 1)
	)
	common.set_control_value(
		ctx,
		controls.island_amount_combo,
		data.option_index_by_value(data.island_amounts, cfg.amt_isl, 1)
	)
	common.set_control_value(ctx, controls.cash_value, data.clamp_value(cfg.val_cash))
	common.set_control_value(ctx, controls.weed_value, data.clamp_value(cfg.val_weed))
	common.set_control_value(ctx, controls.coke_value, data.clamp_value(cfg.val_coke))
	common.set_control_value(ctx, controls.gold_value, data.clamp_value(cfg.val_gold))
	common.set_control_value(ctx, controls.art_value, data.clamp_value(cfg.val_art))
	for i = 1, #data.player_keys do
		local key = data.player_keys[i]
		common.set_control_value(ctx, controls[key .. "_cut"], data.clamp_cut(state.cuts[key]))
		common.set_control_value(ctx, controls[key .. "_enabled"], state.cut_enabled[key])
	end
	return true
end

local function add_preps(root)
	local preps = root:submenu(t("cayo.group.preps"))
	common.add_button(preps, t("cayo.action.unlock_poi"), actions.unlock_all_poi)
	add_toggle(preps, "womans_bag_toggle", "cayo.action.womans_bag", function()
		return state.flags.womans_bag_enabled
	end, actions.set_womans_bag)
	add_toggle(preps, "unlock_on_apply_toggle", "cayo.action.unlock_on_apply", function()
		return state.config.unlock_all_poi
	end, function(enabled)
		state.config.unlock_all_poi = enabled and true or false
	end)
	add_combo(preps, "difficulty_combo", "cayo.field.difficulty", data.difficulties, function()
		return state.config.diff
	end, function(value)
		state.config.diff = value
	end)
	add_combo(preps, "approach_combo", "cayo.field.approach", data.approaches, function()
		return state.config.app
	end, function(value)
		state.config.app = value
	end)
	add_combo(preps, "loadout_combo", "cayo.field.loadout", data.loadouts, function()
		return state.config.wep
	end, function(value)
		state.config.wep = value
	end)
	add_combo(preps, "primary_target_combo", "cayo.field.primary_target", data.primary_targets, function()
		return state.config.tgt
	end, function(value)
		state.config.tgt = value
	end)
	add_combo(preps, "compound_target_combo", "cayo.field.compound_target", data.secondary_targets, function()
		return state.config.sec_comp
	end, function(value)
		state.config.sec_comp = value
	end)
	add_combo(preps, "compound_amount_combo", "cayo.field.compound_amount", data.compound_amounts, function()
		return state.config.amt_comp
	end, function(value)
		state.config.amt_comp = value
	end)
	add_combo(preps, "arts_amount_combo", "cayo.field.arts_amount", data.arts_amounts, function()
		return state.config.paint
	end, function(value)
		state.config.paint = value
	end)
	add_combo(preps, "island_target_combo", "cayo.field.island_target", data.secondary_targets, function()
		return state.config.sec_isl
	end, function(value)
		state.config.sec_isl = value
	end)
	add_combo(preps, "island_amount_combo", "cayo.field.island_amount", data.island_amounts, function()
		return state.config.amt_isl
	end, function(value)
		state.config.amt_isl = value
	end)
	add_number(preps, "cash_value", "cayo.field.cash_value", data.value.min, data.value.max, data.value.step, function()
		return state.config.val_cash
	end, function(value)
		state.config.val_cash = data.clamp_value(value)
	end)
	add_number(preps, "weed_value", "cayo.field.weed_value", data.value.min, data.value.max, data.value.step, function()
		return state.config.val_weed
	end, function(value)
		state.config.val_weed = data.clamp_value(value)
	end)
	add_number(preps, "coke_value", "cayo.field.coke_value", data.value.min, data.value.max, data.value.step, function()
		return state.config.val_coke
	end, function(value)
		state.config.val_coke = data.clamp_value(value)
	end)
	add_number(preps, "gold_value", "cayo.field.gold_value", data.value.min, data.value.max, data.value.step, function()
		return state.config.val_gold
	end, function(value)
		state.config.val_gold = data.clamp_value(value)
	end)
	add_number(preps, "art_value", "cayo.field.art_value", data.value.min, data.value.max, data.value.step, function()
		return state.config.val_art
	end, function(value)
		state.config.val_art = data.clamp_value(value)
	end)
	common.add_button(preps, t("cayo.action.reset_values"), function()
		state.reset_value_defaults()
		controller.refresh_controls()
		push("cayo.notify.values_reset", 2000)
	end)
	common.add_button(preps, t("cayo.action.reset_preps"), actions.reset_preps)
	common.add_button(preps, t("cayo.action.apply_preps"), actions.apply_preps)
end

local function add_cuts(root)
	local cuts = root:submenu(t("cayo.group.cuts"))
	add_toggle(cuts, "remove_crew_cuts_toggle", "cayo.action.remove_crew_cuts", function()
		return state.flags.remove_crew_cuts_enabled
	end, actions.set_remove_crew_cuts)
	add_toggle(cuts, "max_payout_toggle", "cayo.action.max_payout", function()
		return state.flags.max_payout_enabled
	end, actions.set_max_payout)
	add_number(cuts, "host_cut", "cayo.field.host_cut", data.cuts.min, data.cuts.max, data.cuts.step, function()
		return state.cuts.host
	end, function(value)
		state.set_cut("host", value)
	end)
	add_toggle(cuts, "host_enabled", "cayo.field.host_enabled", function()
		return state.cut_enabled.host
	end, function(enabled)
		state.set_cut_enabled("host", enabled)
	end)
	for _, player in ipairs({
		{ key = "player2", cut = "cayo.field.p2_cut", enabled = "cayo.field.p2_enabled" },
		{ key = "player3", cut = "cayo.field.p3_cut", enabled = "cayo.field.p3_enabled" },
		{ key = "player4", cut = "cayo.field.p4_cut", enabled = "cayo.field.p4_enabled" },
	}) do
		add_number(cuts, player.key .. "_cut", player.cut, data.cuts.min, data.cuts.max, data.cuts.step, function()
			return state.cuts[player.key]
		end, function(value)
			state.set_cut(player.key, value)
		end)
		add_toggle(cuts, player.key .. "_enabled", player.enabled, function()
			return state.cut_enabled[player.key]
		end, function(enabled)
			state.set_cut_enabled(player.key, enabled)
		end)
	end
	common.add_button(cuts, t("cayo.action.preset_100"), function()
		state.set_uniform_cuts(100)
		controller.refresh_controls()
	end)
	common.add_button(cuts, t("cayo.action.apply_cuts"), actions.apply_cuts)
end

local function add_tools(root)
	local tools = root:submenu(t("cayo.group.tools"))
	common.add_button(tools, t("cayo.action.reload_planning"), actions.reload_planning_screen)
	common.add_button(tools, t("cayo.action.voltlab"), actions.instant_voltlab_hack)
	common.add_button(tools, t("cayo.action.password"), actions.instant_password_hack)
	common.add_button(tools, t("cayo.action.plasma"), actions.bypass_plasma_cutter)
	common.add_button(tools, t("cayo.action.drainage"), actions.bypass_drainage_pipe)
	common.add_button(tools, t("cayo.action.force_ready"), actions.force_ready)
	common.add_button(tools, t("cayo.action.instant_finish"), actions.instant_finish)
	common.add_button(tools, t("cayo.action.skip_cutscene"), actions.skip_cutscene)
end

local function add_teleports(root)
	local tp = root:submenu(t("cayo.group.teleport"))
	tp:breaker(t("cayo.group.teleport_in_residence"))
	common.add_button(tp, t("cayo.teleport.main_target"), actions.teleport_main_target)
	common.add_button(tp, t("cayo.teleport.gate_inside"), actions.teleport_gate)
	common.add_button(tp, t("cayo.teleport.residence"), actions.teleport_residence)
	common.add_button(tp, t("cayo.teleport.loot1"), actions.teleport_loot1)
	common.add_button(tp, t("cayo.teleport.loot2"), actions.teleport_loot2)
	common.add_button(tp, t("cayo.teleport.loot3"), actions.teleport_loot3)
	tp:breaker(t("cayo.group.teleport_outside"))
	common.add_button(tp, t("cayo.teleport.center"), actions.teleport_center)
	common.add_button(tp, t("cayo.teleport.gate_outside"), actions.teleport_gate_outside)
	common.add_button(tp, t("cayo.teleport.airport"), actions.teleport_airport)
	common.add_button(tp, t("cayo.teleport.escape"), actions.teleport_escape)
end

local function add_danger(root)
	local danger = root:submenu(t("cayo.group.danger"))
	danger:breaker(t("cayo.warning.use_with_caution"))
	common.add_button(danger, t("cayo.action.skip_cooldown_solo"), actions.remove_cooldown)
	common.add_button(danger, t("cayo.action.skip_cooldown_team"), actions.remove_cooldown_team)
	common.add_button(danger, t("cayo.action.go_offline"), actions.go_offline)
	common.add_button(danger, t("cayo.action.go_online"), actions.go_online)
end

function controller.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local root = parent_menu:submenu(t("cayo.info.title"))
	root:breaker(t("cayo.info.title"))
	root:breaker(t("cayo.info.max_transaction"))
	root:breaker(t("cayo.info.transaction_cooldown"))
	root:breaker(t("cayo.info.heist_cooldown"))
	root:breaker(t("cayo.info.skip_cooldown_steps"))
	root:breaker(t("cayo.tip.force_ready"))
	common.add_button(root, t("cayo.action.teleport_kosatka"), actions.teleport_kosatka)
	add_preps(root)
	add_cuts(root)
	add_tools(root)
	add_teleports(root)
	add_danger(root)

	preset_ui.controller_group(root, {
		feature_id = "cayo",
		ctx = controller.ctx,
		collect = cayo_presets.collect,
		apply = cayo_presets.apply,
		refresh = controller.refresh_controls,
	})

	controller.refresh_controls()
	return root
end

return controller
