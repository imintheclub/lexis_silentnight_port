local ui = require("ShillenSilent_core.ui.click.widgets")
local i18n = require("ShillenSilent_core.i18n")
local notify_core = require("ShillenSilent_core.core.notify")
local preset_ui = require("ShillenSilent_core.presets.ui")
local data = require("ShillenSilent_core.features.heists.cayo.data")
local state = require("ShillenSilent_core.features.heists.cayo.state")
local actions = require("ShillenSilent_core.features.heists.cayo.actions")
local cayo_presets = require("ShillenSilent_core.features.heists.cayo.presets")

local click = {}
local refs = {}
local config = require("ShillenSilent_core.ui.click.config")

local t = i18n.t

local push = notify_core.feature("feature.cayo.name")

local function localized(options)
	return data.localized_options(options, t)
end

local function set_dropdown(ref, options, value)
	if refs[ref] then
		refs[ref].value = data.option_index_by_value(options, value, 1)
	end
end

local function set_slider(ref, value)
	if refs[ref] then
		refs[ref].value = value
	end
end

local function set_toggle(ref, value)
	if refs[ref] then
		refs[ref].state = value and true or false
	end
end

function click.refresh()
	local cfg = state.config
	set_toggle("womans_bag_toggle", state.flags.womans_bag_enabled)
	set_toggle("unlock_on_apply_toggle", cfg.unlock_all_poi)
	set_dropdown("difficulty_dropdown", data.difficulties, cfg.diff)
	set_dropdown("approach_dropdown", data.approaches, cfg.app)
	set_dropdown("loadout_dropdown", data.loadouts, cfg.wep)
	set_dropdown("primary_target_dropdown", data.primary_targets, cfg.tgt)
	set_dropdown("compound_target_dropdown", data.secondary_targets, cfg.sec_comp)
	set_dropdown("compound_amount_dropdown", data.compound_amounts, cfg.amt_comp)
	set_dropdown("arts_amount_dropdown", data.arts_amounts, cfg.paint)
	set_dropdown("island_target_dropdown", data.secondary_targets, cfg.sec_isl)
	set_dropdown("island_amount_dropdown", data.island_amounts, cfg.amt_isl)
	set_slider("cash_value_slider", cfg.val_cash)
	set_slider("weed_value_slider", cfg.val_weed)
	set_slider("coke_value_slider", cfg.val_coke)
	set_slider("gold_value_slider", cfg.val_gold)
	set_slider("art_value_slider", cfg.val_art)
	set_toggle("remove_crew_cuts_toggle", state.flags.remove_crew_cuts_enabled)
	set_toggle("max_payout_toggle", state.flags.max_payout_enabled)
	if refs.remove_crew_cuts_toggle then
		refs.remove_crew_cuts_toggle.label = state.flags.max_payout_enabled and t("cayo.action.remove_crew_cuts_locked")
			or t("cayo.action.remove_crew_cuts")
		refs.remove_crew_cuts_toggle.disabled = state.flags.max_payout_enabled
	end
	for i = 1, #data.player_keys do
		local key = data.player_keys[i]
		set_slider(key .. "_slider", state.cuts[key])
		set_toggle(key .. "_toggle", state.cut_enabled[key])
	end
	return true
end

local function add_dropdown(group, ref, id, label_key, options, get_value, set_value)
	local opts = localized(options)
	refs[ref] = ui.dropdown(
		group,
		id,
		t(label_key),
		data.option_names(opts),
		data.option_index_by_value(options, get_value(), 1),
		function(opt)
			set_value(data.option_value_by_name(opts, opt, get_value()))
			click.refresh()
		end
	)
end

local function add_value_slider(group, ref, id, label_key, get_value, set_value)
	refs[ref] = ui.slider(group, id, t(label_key), data.value.min, data.value.max, get_value(), function(val)
		set_value(data.clamp_value(val))
	end, nil, data.value.step)
end

local function add_cut_controls(group, key, slider_id, toggle_id, slider_label_key, toggle_label_key)
	refs[key .. "_slider"] = ui.slider(
		group,
		slider_id,
		t(slider_label_key),
		data.cuts.min,
		data.cuts.max,
		state.cuts[key],
		function(val)
			state.set_cut(key, val)
		end,
		nil,
		data.cuts.step
	)
	refs[key .. "_toggle"] = ui.toggle(group, toggle_id, t(toggle_label_key), state.cut_enabled[key], function(val)
		state.set_cut_enabled(key, val)
	end)
end

function click.register(heist_tab)
	if type(heist_tab) ~= "table" then
		return nil
	end

	local info = ui.group(heist_tab, t("cayo.group.info"), nil, nil, nil, nil, "cayo")
	ui.label(info, t("cayo.info.title"), config.colors.accent)
	ui.info(info, t("cayo.info.max_transaction"), config.colors.text_main)
	ui.info(info, t("cayo.info.transaction_cooldown"), config.colors.text_sec)
	ui.info(info, t("cayo.info.heist_cooldown"), config.colors.text_sec)
	ui.info(info, t("cayo.tip.womans_bag"), config.colors.text_sec)
	ui.info(info, t("cayo.tip.poi_on_apply"), config.colors.text_sec)
	ui.info(info, t("cayo.tip.compound_island"), config.colors.text_sec)
	ui.info(info, t("cayo.tip.danger_solo_team"), config.colors.text_sec)
	ui.info(info, t("cayo.tip.max_payout"), config.colors.text_sec)
	ui.info(info, t("cayo.tip.remove_crew_cuts"), config.colors.text_sec)
	ui.spacer(info, config.space.x4)

	preset_ui.click_group(heist_tab, {
		feature_id = "cayo",
		id_prefix = "cayo",
		subtab = "cayo",
		collect = cayo_presets.collect,
		apply = cayo_presets.apply,
		refresh = click.refresh,
	})

	local preps = ui.group(heist_tab, t("cayo.group.preps"), nil, nil, nil, nil, "cayo")
	ui.button(preps, "cayo_tp_kosatka", t("cayo.action.teleport_kosatka"), actions.teleport_kosatka)
	ui.button(preps, "cayo_unlock_poi", t("cayo.action.unlock_poi"), actions.unlock_all_poi)
	refs.womans_bag_toggle = ui.toggle(
		preps,
		"cayo_womans_bag",
		t("cayo.action.womans_bag"),
		state.flags.womans_bag_enabled,
		function(val)
			actions.set_womans_bag(val)
			click.refresh()
		end
	)
	refs.unlock_on_apply_toggle = ui.toggle(
		preps,
		"cayo_unlock_on_apply",
		t("cayo.action.unlock_on_apply"),
		state.config.unlock_all_poi,
		function(val)
			state.config.unlock_all_poi = val and true or false
		end
	)
	add_dropdown(preps, "difficulty_dropdown", "cayo_difficulty", "cayo.field.difficulty", data.difficulties, function()
		return state.config.diff
	end, function(value)
		state.config.diff = value
	end)
	add_dropdown(preps, "approach_dropdown", "cayo_approach", "cayo.field.approach", data.approaches, function()
		return state.config.app
	end, function(value)
		state.config.app = value
	end)
	add_dropdown(preps, "loadout_dropdown", "cayo_loadout", "cayo.field.loadout", data.loadouts, function()
		return state.config.wep
	end, function(value)
		state.config.wep = value
	end)
	add_dropdown(
		preps,
		"primary_target_dropdown",
		"cayo_target",
		"cayo.field.primary_target",
		data.primary_targets,
		function()
			return state.config.tgt
		end,
		function(value)
			state.config.tgt = value
		end
	)
	add_dropdown(
		preps,
		"compound_target_dropdown",
		"cayo_compound",
		"cayo.field.compound_target",
		data.secondary_targets,
		function()
			return state.config.sec_comp
		end,
		function(value)
			state.config.sec_comp = value
		end
	)
	add_dropdown(
		preps,
		"compound_amount_dropdown",
		"cayo_compound_amount",
		"cayo.field.compound_amount",
		data.compound_amounts,
		function()
			return state.config.amt_comp
		end,
		function(value)
			state.config.amt_comp = value
		end
	)
	add_dropdown(
		preps,
		"arts_amount_dropdown",
		"cayo_arts_amount",
		"cayo.field.arts_amount",
		data.arts_amounts,
		function()
			return state.config.paint
		end,
		function(value)
			state.config.paint = value
		end
	)
	add_dropdown(
		preps,
		"island_target_dropdown",
		"cayo_island",
		"cayo.field.island_target",
		data.secondary_targets,
		function()
			return state.config.sec_isl
		end,
		function(value)
			state.config.sec_isl = value
		end
	)
	add_dropdown(
		preps,
		"island_amount_dropdown",
		"cayo_island_amount",
		"cayo.field.island_amount",
		data.island_amounts,
		function()
			return state.config.amt_isl
		end,
		function(value)
			state.config.amt_isl = value
		end
	)
	add_value_slider(preps, "cash_value_slider", "cayo_cash_value", "cayo.field.cash_value", function()
		return state.config.val_cash
	end, function(value)
		state.config.val_cash = value
	end)
	add_value_slider(preps, "weed_value_slider", "cayo_weed_value", "cayo.field.weed_value", function()
		return state.config.val_weed
	end, function(value)
		state.config.val_weed = value
	end)
	add_value_slider(preps, "coke_value_slider", "cayo_coke_value", "cayo.field.coke_value", function()
		return state.config.val_coke
	end, function(value)
		state.config.val_coke = value
	end)
	add_value_slider(preps, "gold_value_slider", "cayo_gold_value", "cayo.field.gold_value", function()
		return state.config.val_gold
	end, function(value)
		state.config.val_gold = value
	end)
	add_value_slider(preps, "art_value_slider", "cayo_art_value", "cayo.field.art_value", function()
		return state.config.val_art
	end, function(value)
		state.config.val_art = value
	end)
	ui.button(preps, "cayo_reset_values", t("cayo.action.reset_values"), function()
		state.reset_value_defaults()
		click.refresh()
		push("cayo.notify.values_reset", 2000)
	end)
	ui.button(preps, "cayo_reset_preps", t("cayo.action.reset_preps"), actions.reset_preps)
	ui.button(preps, "cayo_apply_preps", t("cayo.action.apply_preps"), actions.apply_preps)

	local tools = ui.group(heist_tab, t("cayo.group.tools"), nil, nil, nil, nil, "cayo")
	ui.button(tools, "cayo_tool_voltlab", t("cayo.action.voltlab"), actions.instant_voltlab_hack)
	ui.button(tools, "cayo_tool_password", t("cayo.action.password"), actions.instant_password_hack)
	ui.button(tools, "cayo_tool_plasma", t("cayo.action.plasma"), actions.bypass_plasma_cutter)
	ui.button(tools, "cayo_tool_drainage", t("cayo.action.drainage"), actions.bypass_drainage_pipe)
	ui.button(tools, "cayo_tool_finish", t("cayo.action.instant_finish"), actions.instant_finish)
	ui.button(tools, "cayo_force_ready", t("cayo.action.force_ready"), actions.force_ready)
	ui.button(tools, "cayo_skip_cutscene", t("cayo.action.skip_cutscene"), actions.skip_cutscene)
	ui.button(tools, "cayo_tool_reload", t("cayo.action.reload_planning"), actions.reload_planning_screen)

	local danger = ui.group(heist_tab, t("cayo.group.danger"), nil, nil, nil, nil, "cayo")
	ui.label(danger, t("cayo.warning.use_with_caution"), config.colors.danger_text)
	ui.button(
		danger,
		"cayo_skip_heist_cooldown_solo",
		t("cayo.action.skip_cooldown_solo"),
		actions.remove_cooldown,
		nil,
		false,
		"danger"
	)
	ui.button(
		danger,
		"cayo_skip_heist_cooldown_team",
		t("cayo.action.skip_cooldown_team"),
		actions.remove_cooldown_team,
		nil,
		false,
		"danger"
	)

	local in_residence = ui.group(heist_tab, t("cayo.group.teleport_in_residence"), nil, nil, nil, nil, "cayo")
	ui.button(in_residence, "cayo_tp_target", t("cayo.teleport.main_target"), actions.teleport_main_target)
	ui.button(in_residence, "cayo_tp_gate", t("cayo.teleport.gate"), actions.teleport_gate)
	ui.button(in_residence, "cayo_tp_residence", t("cayo.teleport.residence"), actions.teleport_residence)
	ui.button(in_residence, "cayo_tp_loot1", t("cayo.teleport.loot1"), actions.teleport_loot1)
	ui.button(in_residence, "cayo_tp_loot2", t("cayo.teleport.loot2"), actions.teleport_loot2)
	ui.button(in_residence, "cayo_tp_loot3", t("cayo.teleport.loot3"), actions.teleport_loot3)

	local outside = ui.group(heist_tab, t("cayo.group.teleport_outside"), nil, nil, nil, nil, "cayo")
	ui.button(outside, "cayo_tp_center", t("cayo.teleport.center"), actions.teleport_center)
	ui.button(outside, "cayo_tp_gate_outside", t("cayo.teleport.gate"), actions.teleport_gate_outside)
	ui.button(outside, "cayo_tp_airport", t("cayo.teleport.airport"), actions.teleport_airport, nil, false)
	ui.button(outside, "cayo_tp_escape", t("cayo.teleport.escape"), actions.teleport_escape, nil, false, "green")

	local cuts = ui.group(heist_tab, t("cayo.group.cuts"), nil, nil, nil, nil, "cayo")
	refs.remove_crew_cuts_toggle = ui.toggle(
		cuts,
		"cayo_remove_crew_cuts",
		t("cayo.action.remove_crew_cuts"),
		state.flags.remove_crew_cuts_enabled,
		function(val)
			actions.set_remove_crew_cuts(val)
			click.refresh()
		end
	)
	refs.max_payout_toggle = ui.toggle(
		cuts,
		"cayo_max_payout",
		t("cayo.action.max_payout"),
		state.flags.max_payout_enabled,
		function(val)
			actions.set_max_payout(val)
			click.refresh()
		end
	)
	add_cut_controls(
		cuts,
		"host",
		"cayo_cut_host",
		"cayo_cut_host_enabled",
		"cayo.field.host_cut",
		"cayo.field.host_enabled"
	)
	add_cut_controls(
		cuts,
		"player2",
		"cayo_cut_p2",
		"cayo_cut_p2_enabled",
		"cayo.field.p2_cut",
		"cayo.field.p2_enabled"
	)
	add_cut_controls(
		cuts,
		"player3",
		"cayo_cut_p3",
		"cayo_cut_p3_enabled",
		"cayo.field.p3_cut",
		"cayo.field.p3_enabled"
	)
	add_cut_controls(
		cuts,
		"player4",
		"cayo_cut_p4",
		"cayo_cut_p4_enabled",
		"cayo.field.p4_cut",
		"cayo.field.p4_enabled"
	)
	ui.button(cuts, "cayo_cuts_max", t("cayo.action.preset_100"), function()
		state.set_uniform_cuts(100)
		click.refresh()
	end)
	ui.button(cuts, "cayo_cuts_apply", t("cayo.action.apply_cuts"), actions.apply_cuts)

	click.refresh()
	return heist_tab
end

return click
