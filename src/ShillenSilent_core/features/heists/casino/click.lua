local core_state = require("ShillenSilent_core.shared.runtime_state")
local ui = require("ShillenSilent_core.ui.click.widgets")
local i18n = require("ShillenSilent_core.i18n")
local preset_ui = require("ShillenSilent_core.presets.ui")
local data = require("ShillenSilent_core.features.heists.casino.data")
local state = require("ShillenSilent_core.features.heists.casino.state")
local actions = require("ShillenSilent_core.features.heists.casino.actions")
local casino_presets = require("ShillenSilent_core.features.heists.casino.presets")

local click = {}
local refs = {}
local config = require("ShillenSilent_core.ui.click.config")

local t = i18n.t

local function localized_options(options)
	return data.localized_options(options, t)
end

local function update_loadout_dropdown(reset_selection)
	local range = data.loadout_range(state.config.approach, state.config.crew_weapon)
	local options = localized_options(data.options.loadouts)
	local names = data.option_names_range(options, range[1], range[2])
	if reset_selection then
		state.config.loadout_slot = 1
	end
	state.clamp_loadout_slot()
	if refs.loadout_dropdown then
		refs.loadout_dropdown.options = names
		refs.loadout_dropdown.value = state.config.loadout_slot
	end
end

local function update_vehicle_dropdown(reset_selection)
	local range = data.vehicle_range(state.config.crew_driver)
	local options = localized_options(data.options.vehicles)
	local names = data.option_names_range(options, range[1], range[2])
	if reset_selection then
		state.config.vehicle_slot = 1
	end
	state.clamp_vehicle_slot()
	if refs.vehicle_dropdown then
		refs.vehicle_dropdown.options = names
		refs.vehicle_dropdown.value = state.config.vehicle_slot
	end
end

function click.refresh()
	local options = data.options
	if refs.autograbber_toggle then
		refs.autograbber_toggle.state = state.flags.autograbber_enabled
	end
	if refs.solo_launch_toggle then
		refs.solo_launch_toggle.state = core_state.solo_launch.casino
	end
	if refs.unlock_poi_toggle then
		refs.unlock_poi_toggle.state = state.config.unlock_all_poi
	end
	if refs.difficulty_dropdown then
		refs.difficulty_dropdown.value = data.option_index_by_value(options.difficulties, state.config.difficulty, 1)
	end
	if refs.approach_dropdown then
		refs.approach_dropdown.value = data.option_index_by_value(options.approaches, state.config.approach, 1)
	end
	if refs.gunman_dropdown then
		refs.gunman_dropdown.value = data.option_index_by_value(options.gunmen, state.config.crew_weapon, 1)
	end
	if refs.driver_dropdown then
		refs.driver_dropdown.value = data.option_index_by_value(options.drivers, state.config.crew_driver, 1)
	end
	if refs.hacker_dropdown then
		refs.hacker_dropdown.value = data.option_index_by_value(options.hackers, state.config.crew_hacker, 1)
	end
	if refs.masks_dropdown then
		refs.masks_dropdown.value = data.option_index_by_value(options.masks, state.config.masks, 1)
	end
	if refs.guards_dropdown then
		refs.guards_dropdown.value = data.option_index_by_value(options.guards, state.config.disrupt_shipments, 1)
	end
	if refs.keycards_dropdown then
		refs.keycards_dropdown.value = data.option_index_by_value(options.keycards, state.config.key_levels, 1)
	end
	if refs.target_dropdown then
		refs.target_dropdown.value = data.option_index_by_value(options.targets, state.config.target, 1)
	end
	update_loadout_dropdown(false)
	update_vehicle_dropdown(false)

	if refs.remove_crew_toggle then
		refs.remove_crew_toggle.state = state.flags.remove_crew_cuts_enabled
		refs.remove_crew_toggle.disabled = state.flags.max_payout_enabled
		refs.remove_crew_toggle.label = t(
			state.flags.max_payout_enabled and "casino.action.remove_crew_cuts_locked"
				or "casino.action.remove_crew_cuts"
		)
	end
	if refs.max_payout_toggle then
		refs.max_payout_toggle.state = state.flags.max_payout_enabled
	end
	for i = 1, #data.player_keys do
		local key = data.player_keys[i]
		if refs[key .. "_slider"] then
			refs[key .. "_slider"].value = state.cuts[key]
		end
		if refs[key .. "_toggle"] then
			refs[key .. "_toggle"].state = state.cut_enabled[key]
		end
	end
	return true
end

local function bind_dropdown(group, ref_key, id, label_key, options, get_value, set_value, on_change)
	local localized = localized_options(options)
	refs[ref_key] = ui.dropdown(
		group,
		id,
		t(label_key),
		data.option_names(localized),
		data.option_index_by_value(options, get_value(), 1),
		function(opt)
			set_value(data.option_value_by_name(localized, opt, get_value()))
			if on_change then
				on_change()
			end
			click.refresh()
		end
	)
end

function click.register(heist_tab)
	if type(heist_tab) ~= "table" then
		return nil
	end

	local info = ui.group(heist_tab, t("casino.group.info"), nil, nil, nil, nil, "casino")
	ui.label(info, t("casino.info.title"), config.colors.accent)
	ui.label(info, t("casino.info.max_transaction"), config.colors.text_main)
	ui.label(info, t("casino.info.transaction_cooldown"), config.colors.text_sec)
	ui.label(info, t("casino.info.heist_cooldown"), config.colors.text_sec)
	ui.info(info, t("casino.tip.autograbber"), config.colors.text_sec)
	ui.info(info, t("casino.tip.fix_keycards"), config.colors.text_sec)
	ui.info(info, t("casino.tip.team_lives"), config.colors.text_sec)
	ui.info(info, t("casino.tip.max_payout"), config.colors.text_sec)
	ui.info(info, t("casino.tip.force_ready"), config.colors.text_sec)
	ui.spacer(info, config.space.x2)

	preset_ui.click_group(heist_tab, {
		feature_id = data.feature_id,
		id_prefix = "casino",
		subtab = "casino",
		collect = casino_presets.collect,
		apply = casino_presets.apply,
		refresh = click.refresh,
	})

	local tools = ui.group(heist_tab, t("casino.group.tools"), nil, nil, nil, nil, "casino")
	ui.button(tools, "casino_fingerprint", t("casino.action.fingerprint"), actions.fingerprint_hack)
	ui.button(tools, "casino_keypad", t("casino.action.keypad"), actions.instant_keypad_hack)
	ui.button(tools, "casino_vault_drill", t("casino.action.vault_drill"), actions.instant_vault_drill)
	ui.button(tools, "casino_instant_finish", t("casino.action.instant_finish"), actions.instant_finish)
	ui.button(tools, "casino_fix_keycards", t("casino.action.fix_keycards"), actions.fix_stuck_keycards)
	ui.button(tools, "casino_skip_objective", t("casino.action.skip_objective"), actions.skip_objective)
	ui.button(tools, "casino_team_lives", t("casino.action.team_lives"), actions.set_team_lives)
	refs.autograbber_toggle = ui.toggle(
		tools,
		"casino_autograbber",
		t("casino.action.autograbber"),
		state.flags.autograbber_enabled,
		function(enabled)
			actions.set_autograbber(enabled)
			click.refresh()
		end
	)
	ui.button(tools, "casino_skip_cutscene", t("casino.action.skip_cutscene"), actions.skip_cutscene)

	local launch = ui.group(heist_tab, t("casino.group.launch"), nil, nil, nil, nil, "casino")
	ui.button(launch, "casino_tp_arcade_launch", t("casino.action.teleport_arcade"), actions.teleport_arcade)
	refs.solo_launch_toggle = ui.toggle(
		launch,
		"casino_solo_launch",
		t("casino.action.solo_launch"),
		core_state.solo_launch.casino,
		function(enabled)
			core_state.solo_launch.casino = enabled and true or false
			click.refresh()
		end
	)
	ui.button(launch, "casino_force_ready", t("casino.action.force_ready"), actions.force_ready)

	local preps = ui.group(heist_tab, t("casino.group.preps"), nil, nil, nil, nil, "casino")
	refs.unlock_poi_toggle = ui.toggle(
		preps,
		"casino_unlock_poi",
		t("casino.action.unlock_on_apply"),
		state.config.unlock_all_poi,
		function(enabled)
			state.config.unlock_all_poi = enabled and true or false
			click.refresh()
		end
	)
	bind_dropdown(
		preps,
		"difficulty_dropdown",
		"casino_difficulty",
		"casino.field.difficulty",
		data.options.difficulties,
		function()
			return state.config.difficulty
		end,
		function(value)
			state.config.difficulty = value
		end
	)
	bind_dropdown(
		preps,
		"approach_dropdown",
		"casino_approach",
		"casino.field.approach",
		data.options.approaches,
		function()
			return state.config.approach
		end,
		function(value)
			state.config.approach = value
			state.config.crew_weapon = data.options.gunmen[1].value
		end,
		function()
			update_loadout_dropdown(true)
		end
	)
	bind_dropdown(preps, "gunman_dropdown", "casino_gunman", "casino.field.gunman", data.options.gunmen, function()
		return state.config.crew_weapon
	end, function(value)
		state.config.crew_weapon = value
	end, function()
		update_loadout_dropdown(true)
	end)
	refs.loadout_dropdown = ui.dropdown(preps, "casino_loadout", t("casino.field.loadout"), {}, 1, function(opt)
		for i = 1, #(refs.loadout_dropdown.options or {}) do
			if refs.loadout_dropdown.options[i] == opt then
				state.config.loadout_slot = i
				break
			end
		end
		click.refresh()
	end)
	bind_dropdown(preps, "driver_dropdown", "casino_driver", "casino.field.driver", data.options.drivers, function()
		return state.config.crew_driver
	end, function(value)
		state.config.crew_driver = value
	end, function()
		update_vehicle_dropdown(true)
	end)
	refs.vehicle_dropdown = ui.dropdown(preps, "casino_vehicle", t("casino.field.vehicle"), {}, 1, function(opt)
		for i = 1, #(refs.vehicle_dropdown.options or {}) do
			if refs.vehicle_dropdown.options[i] == opt then
				state.config.vehicle_slot = i
				break
			end
		end
		click.refresh()
	end)
	bind_dropdown(preps, "hacker_dropdown", "casino_hacker", "casino.field.hacker", data.options.hackers, function()
		return state.config.crew_hacker
	end, function(value)
		state.config.crew_hacker = value
	end)
	bind_dropdown(preps, "masks_dropdown", "casino_masks", "casino.field.masks", data.options.masks, function()
		return state.config.masks
	end, function(value)
		state.config.masks = value
	end)
	bind_dropdown(preps, "guards_dropdown", "casino_guards", "casino.field.guards", data.options.guards, function()
		return state.config.disrupt_shipments
	end, function(value)
		state.config.disrupt_shipments = value
	end)
	bind_dropdown(
		preps,
		"keycards_dropdown",
		"casino_keycards",
		"casino.field.keycards",
		data.options.keycards,
		function()
			return state.config.key_levels
		end,
		function(value)
			state.config.key_levels = value
		end
	)
	bind_dropdown(preps, "target_dropdown", "casino_target", "casino.field.target", data.options.targets, function()
		return state.config.target
	end, function(value)
		state.config.target = value
	end)
	ui.button(preps, "casino_reset_preps", t("casino.action.reset_preps"), actions.reset_preps)
	ui.button(preps, "casino_apply_preps", t("casino.action.apply_preps"), actions.apply_preps)

	local cuts = ui.group(heist_tab, t("casino.group.cuts"), nil, nil, nil, nil, "casino")
	refs.remove_crew_toggle = ui.toggle(
		cuts,
		"casino_remove_crew_cuts",
		t("casino.action.remove_crew_cuts"),
		state.flags.remove_crew_cuts_enabled,
		function(enabled)
			actions.set_remove_crew_cuts(enabled)
			click.refresh()
		end
	)
	refs.max_payout_toggle = ui.toggle(
		cuts,
		"casino_max_payout",
		t("casino.action.max_payout"),
		state.flags.max_payout_enabled,
		function(enabled)
			actions.set_max_payout(enabled)
			click.refresh()
		end
	)
	refs.host_slider = ui.slider(
		cuts,
		"casino_cut_host",
		t("casino.field.host_cut"),
		0,
		300,
		state.cuts.host,
		function(val)
			state.set_cut("host", val)
		end,
		nil,
		data.cuts.step
	)
	refs.host_toggle = ui.toggle(
		cuts,
		"casino_cut_host_enabled",
		t("casino.field.host_enabled"),
		state.cut_enabled.host,
		function(enabled)
			state.set_cut_enabled("host", enabled)
		end
	)
	refs.player2_slider = ui.slider(
		cuts,
		"casino_cut_p2",
		t("casino.field.p2_cut"),
		0,
		300,
		state.cuts.player2,
		function(val)
			state.set_cut("player2", val)
		end,
		nil,
		data.cuts.step
	)
	refs.player2_toggle = ui.toggle(
		cuts,
		"casino_cut_p2_enabled",
		t("casino.field.p2_enabled"),
		state.cut_enabled.player2,
		function(enabled)
			state.set_cut_enabled("player2", enabled)
		end
	)
	refs.player3_slider = ui.slider(
		cuts,
		"casino_cut_p3",
		t("casino.field.p3_cut"),
		0,
		300,
		state.cuts.player3,
		function(val)
			state.set_cut("player3", val)
		end,
		nil,
		data.cuts.step
	)
	refs.player3_toggle = ui.toggle(
		cuts,
		"casino_cut_p3_enabled",
		t("casino.field.p3_enabled"),
		state.cut_enabled.player3,
		function(enabled)
			state.set_cut_enabled("player3", enabled)
		end
	)
	refs.player4_slider = ui.slider(
		cuts,
		"casino_cut_p4",
		t("casino.field.p4_cut"),
		0,
		300,
		state.cuts.player4,
		function(val)
			state.set_cut("player4", val)
		end,
		nil,
		data.cuts.step
	)
	refs.player4_toggle = ui.toggle(
		cuts,
		"casino_cut_p4_enabled",
		t("casino.field.p4_enabled"),
		state.cut_enabled.player4,
		function(enabled)
			state.set_cut_enabled("player4", enabled)
		end
	)
	ui.button(cuts, "casino_cuts_100", t("casino.action.preset_100"), function()
		state.set_uniform_cuts(100)
		click.refresh()
	end)
	ui.button(cuts, "casino_cuts_apply", t("casino.action.apply_cuts"), actions.apply_cuts)

	local danger = ui.group(heist_tab, t("casino.group.danger"), nil, nil, nil, nil, "casino")
	ui.label(danger, t("casino.warning.use_with_caution"), config.colors.danger_text)
	ui.button(danger, "casino_skip_heist_cooldown", t("casino.action.skip_cooldown"), actions.remove_cooldown)

	local outside = ui.group(heist_tab, t("casino.group.teleport_outside"), nil, nil, nil, nil, "casino")
	ui.button(outside, "casino_tp_tunnel", t("casino.teleport.tunnel"), actions.teleport_tunnel)
	ui.button(outside, "casino_tp_staff_lobby", t("casino.teleport.staff_lobby"), actions.teleport_staff_lobby)

	local inside = ui.group(heist_tab, t("casino.group.teleport_inside"), nil, nil, nil, nil, "casino")
	ui.button(
		inside,
		"casino_tp_staff_lobby_inside",
		t("casino.teleport.staff_lobby"),
		actions.teleport_staff_lobby_inside
	)
	ui.button(inside, "casino_tp_side_safe", t("casino.teleport.side_safe"), actions.teleport_side_safe)
	ui.button(inside, "casino_tp_tunnel_door", t("casino.teleport.tunnel_door"), actions.teleport_tunnel_door)

	click.refresh()
	if state.flags.max_payout_enabled then
		actions.refresh_max_payout(true)
		click.refresh()
	else
		actions.set_remove_crew_cuts(state.flags.remove_crew_cuts_enabled, true)
	end
	return heist_tab
end

return click
