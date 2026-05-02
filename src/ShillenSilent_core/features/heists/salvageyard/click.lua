local ui = require("ShillenSilent_core.ui.click.widgets")
local i18n = require("ShillenSilent_core.i18n")
local notify_core = require("ShillenSilent_core.core.notify")
local preset_ui = require("ShillenSilent_core.presets.ui")
local data = require("ShillenSilent_core.features.heists.salvageyard.data")
local state = require("ShillenSilent_core.features.heists.salvageyard.state")
local actions = require("ShillenSilent_core.features.heists.salvageyard.actions")
local salvage_presets = require("ShillenSilent_core.features.heists.salvageyard.presets")

local click = {}
local refs = {}
local config = require("ShillenSilent_core.ui.click.config")

local t = i18n.t

local push = notify_core.feature("feature.salvageyard.name")

local function slot_ref(slot, field)
	return "slot" .. tostring(slot) .. "_" .. field
end

local function localized_options(options)
	return data.localized_options(options, t)
end

local function refresh_slot(slot)
	local slot_cfg = state.slot(slot)
	if not slot_cfg then
		return
	end
	local option_sets = {
		robbery = data.options.robberies,
		vehicle = data.options.vehicles,
		modification = data.options.modifications,
		keep = data.options.keep_statuses,
	}
	for field, options in pairs(option_sets) do
		local ref = refs[slot_ref(slot, field)]
		if ref then
			ref.value = data.option_index_by_value(options, slot_cfg[field], 1)
		end
	end
end

function click.refresh()
	for slot = 1, 3 do
		refresh_slot(slot)
	end
	if refs.free_setup_toggle then
		refs.free_setup_toggle.state = state.flags.free_setup
	end
	if refs.free_claim_toggle then
		refs.free_claim_toggle.state = state.flags.free_claim
	end
	if refs.collect_safe_button then
		refs.collect_safe_button.disabled = not state.flags.collect_safe_ee_only
	end
	if refs.salvage_multiplier_slider then
		refs.salvage_multiplier_slider.value = state.config.salvage_multiplier
	end
	for slot = 1, 3 do
		local ref = refs["sell_value_slot" .. tostring(slot) .. "_slider"]
		if ref then
			ref.value = state.sell_value(slot)
		end
	end
	return true
end

local function bind_slot_dropdown(group, slot, field, label_key, options)
	local option_list = localized_options(options)
	refs[slot_ref(slot, field)] = ui.dropdown(
		group,
		"salvage_slot" .. tostring(slot) .. "_" .. field,
		t(label_key),
		data.option_names(option_list),
		state.option_index(slot, field, options, 1),
		function(opt)
			state.set_slot_value(slot, field, data.option_value_by_name(option_list, opt, state.slot(slot)[field]))
			click.refresh()
		end
	)
end

local function build_slot_group(heist_tab, slot)
	local group =
		ui.group(heist_tab, t("salvageyard.group.slot", { slot = tostring(slot) }), nil, nil, nil, nil, "salvageyard")
	bind_slot_dropdown(group, slot, "robbery", "salvageyard.field.robbery", data.options.robberies)
	bind_slot_dropdown(group, slot, "vehicle", "salvageyard.field.vehicle", data.options.vehicles)
	bind_slot_dropdown(group, slot, "modification", "salvageyard.field.modification", data.options.modifications)
	bind_slot_dropdown(group, slot, "keep", "salvageyard.field.status", data.options.keep_statuses)
	ui.button(
		group,
		"salvage_slot" .. tostring(slot) .. "_available",
		t("salvageyard.action.make_available"),
		function()
			actions.make_slot_available(slot)
		end
	)
	ui.button(group, "salvage_slot" .. tostring(slot) .. "_apply", t("salvageyard.action.apply_changes"), function()
		actions.apply_slot(slot)
	end)
end

function click.register(heist_tab)
	if type(heist_tab) ~= "table" then
		return nil
	end

	actions.refresh_collect_safe_state()

	local info = ui.group(heist_tab, t("salvageyard.group.info"), nil, nil, nil, nil, "salvageyard")
	ui.label(info, t("feature.salvageyard.name"), config.colors.accent)
	ui.label(info, t("salvageyard.info.max_transaction"), config.colors.text_main)
	ui.label(info, t("salvageyard.info.cooldown"), config.colors.text_sec)
	ui.label(info, t("salvageyard.info.planning_controls"), config.colors.text_sec)
	ui.info(info, t("salvageyard.tip.status"), config.colors.text_sec)
	ui.info(info, t("salvageyard.tip.make_available"), config.colors.text_sec)
	ui.info(info, t("salvageyard.tip.force_error"), config.colors.text_sec)
	ui.info(info, t("salvageyard.tip.sell_values"), config.colors.text_sec)
	ui.info(info, t("salvageyard.tip.multiplier"), config.colors.text_sec)
	ui.info(info, t("salvageyard.tip.instant_sell"), config.colors.text_sec)
	ui.spacer(info, config.space.x2)

	preset_ui.click_group(heist_tab, {
		feature_id = "salvageyard",
		id_prefix = "salvage",
		subtab = "salvageyard",
		collect = salvage_presets.collect,
		apply = salvage_presets.apply,
		refresh = click.refresh,
	})

	for slot = 1, 3 do
		build_slot_group(heist_tab, slot)
	end

	local preps = ui.group(heist_tab, t("salvageyard.group.preps"), nil, nil, nil, nil, "salvageyard")
	ui.button(preps, "salvage_tp_entrance", t("salvageyard.action.teleport_entrance"), actions.teleport_entrance)
	ui.button(preps, "salvage_apply_all_changes", t("salvageyard.action.apply_all_changes"), actions.apply_all_changes)
	ui.button(preps, "salvage_reload_screen", t("salvageyard.action.reload_screen"), actions.reload_screen)
	ui.button(preps, "salvage_complete_preps", t("salvageyard.action.complete_preps"), actions.complete_preps)
	ui.button(preps, "salvage_reset_preps", t("salvageyard.action.reset_preps"), actions.reset_preps)
	refs.free_setup_toggle = ui.toggle(
		preps,
		"salvage_free_setup",
		t("salvageyard.action.free_setup"),
		state.flags.free_setup,
		function(enabled)
			actions.set_free_setup(enabled, false)
			click.refresh()
		end
	)
	refs.free_claim_toggle = ui.toggle(
		preps,
		"salvage_free_claim",
		t("salvageyard.action.free_claim"),
		state.flags.free_claim,
		function(enabled)
			actions.set_free_claim(enabled, false)
			click.refresh()
		end
	)

	local tools = ui.group(heist_tab, t("salvageyard.group.tools"), nil, nil, nil, nil, "salvageyard")
	ui.button(tools, "salvage_tp_board", t("salvageyard.action.teleport_board"), actions.teleport_board)
	ui.button(tools, "salvage_instant_finish", t("salvageyard.action.instant_finish"), actions.instant_finish)
	ui.button(tools, "salvage_instant_sell", t("salvageyard.action.instant_sell"), actions.instant_sell)
	ui.button(
		tools,
		"salvage_tow_truck_instant_finish",
		t("salvageyard.action.tow_finish"),
		actions.tow_truck_instant_finish
	)
	ui.button(tools, "salvage_force_through_error", t("salvageyard.action.force_error"), actions.force_through_error)
	refs.collect_safe_button =
		ui.button(tools, "salvage_collect_safe", t("salvageyard.action.collect_safe"), actions.collect_safe)
	ui.button(tools, "salvage_skip_cutscene", t("salvageyard.action.skip_cutscene"), actions.skip_cutscene)

	local popularity = ui.group(heist_tab, t("salvageyard.group.popularity"), nil, nil, nil, nil, "salvageyard")
	ui.slider(
		popularity,
		"salvage_popularity_value",
		t("salvageyard.field.popularity"),
		data.popularity.min,
		data.popularity.max,
		actions.get_popularity_editor_value(),
		actions.set_popularity_editor_value,
		nil,
		data.popularity.step
	)
	ui.button(
		popularity,
		"salvage_popularity_apply",
		t("salvageyard.action.apply_popularity"),
		actions.apply_popularity_editor_value
	)
	ui.toggle(
		popularity,
		"salvage_popularity_lock",
		t("salvageyard.action.lock_popularity"),
		actions.get_popularity_lock_active(),
		actions.set_popularity_lock_active
	)

	local danger = ui.group(heist_tab, t("salvageyard.group.danger"), nil, nil, nil, nil, "salvageyard")
	ui.label(danger, t("salvageyard.warning.use_with_caution"), config.colors.danger_text)
	ui.button(
		danger,
		"salvage_skip_weekly_cooldown",
		t("salvageyard.action.skip_weekly_cooldown"),
		actions.skip_weekly_cooldown
	)

	local payout = ui.group(heist_tab, t("salvageyard.group.payout"), nil, nil, nil, nil, "salvageyard")
	refs.salvage_multiplier_slider = ui.slider(
		payout,
		"salvage_multiplier",
		t("salvageyard.field.multiplier"),
		data.multiplier.min,
		data.multiplier.max,
		state.config.salvage_multiplier,
		state.set_multiplier,
		nil,
		data.multiplier.step
	)
	for slot = 1, 3 do
		refs["sell_value_slot" .. tostring(slot) .. "_slider"] = ui.slider(
			payout,
			"salvage_sell_value_slot" .. tostring(slot),
			t("salvageyard.field.sell_value_slot", { slot = tostring(slot) }),
			data.sell_value.min,
			data.sell_value.max,
			state.sell_value(slot),
			function(val)
				state.set_sell_value(slot, val)
			end,
			nil,
			data.sell_value.step
		)
	end
	ui.button(payout, "salvage_apply_sell_values", t("salvageyard.action.apply_sell_values"), actions.apply_sell_values)

	actions.set_free_setup(state.flags.free_setup, true)
	actions.set_free_claim(state.flags.free_claim, true)
	click.refresh()
	if not state.flags.collect_safe_ee_only then
		push("salvageyard.notify.collect_safe_disabled", 2200)
	end

	return heist_tab
end

return click
