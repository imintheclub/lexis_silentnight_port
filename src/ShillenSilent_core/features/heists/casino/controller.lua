local core_state = require("ShillenSilent_core.shared.runtime_state")
local common = require("ShillenSilent_core.ui.controller.widgets")
local i18n = require("ShillenSilent_core.i18n")
local preset_ui = require("ShillenSilent_core.presets.ui")
local data = require("ShillenSilent_core.features.heists.casino.data")
local state = require("ShillenSilent_core.features.heists.casino.state")
local actions = require("ShillenSilent_core.features.heists.casino.actions")
local casino_presets = require("ShillenSilent_core.features.heists.casino.presets")

local controller = {
	ctx = { syncing = false },
	controls = {},
}

local t = i18n.t

local function localized_options(options)
	return data.localized_options(options, t)
end

function controller.refresh_controls()
	local ctx = controller.ctx
	local controls = controller.controls
	local options = data.options

	common.set_control_value(ctx, controls.autograbber, state.flags.autograbber_enabled and true or false)
	common.set_control_value(ctx, controls.solo_launch, core_state.solo_launch.casino and true or false)
	common.set_control_value(ctx, controls.unlock_poi, state.config.unlock_all_poi and true or false)
	common.set_control_value(
		ctx,
		controls.difficulty,
		common.find_index_by_value(options.difficulties, state.config.difficulty, 1)
	)
	common.set_control_value(
		ctx,
		controls.approach,
		common.find_index_by_value(options.approaches, state.config.approach, 1)
	)
	common.set_control_value(
		ctx,
		controls.gunman,
		common.find_index_by_value(options.gunmen, state.config.crew_weapon, 1)
	)
	common.set_control_value(
		ctx,
		controls.driver,
		common.find_index_by_value(options.drivers, state.config.crew_driver, 1)
	)
	common.set_control_value(
		ctx,
		controls.hacker,
		common.find_index_by_value(options.hackers, state.config.crew_hacker, 1)
	)
	common.set_control_value(ctx, controls.masks, common.find_index_by_value(options.masks, state.config.masks, 1))
	common.set_control_value(
		ctx,
		controls.guards,
		common.find_index_by_value(options.guards, state.config.disrupt_shipments, 1)
	)
	common.set_control_value(
		ctx,
		controls.keycards,
		common.find_index_by_value(options.keycards, state.config.key_levels, 1)
	)
	common.set_control_value(ctx, controls.target, common.find_index_by_value(options.targets, state.config.target, 1))
	common.set_control_value(ctx, controls.loadout_slot, common.clamp_int(state.config.loadout_slot, 1, 2))
	common.set_control_value(ctx, controls.vehicle_slot, common.clamp_int(state.config.vehicle_slot, 1, 4))

	common.set_control_value(ctx, controls.remove_crew, state.flags.remove_crew_cuts_enabled and true or false)
	common.set_control_value(ctx, controls.max_payout, state.flags.max_payout_enabled and true or false)
	common.set_control_value(ctx, controls.host_cut, common.clamp_int(state.cuts.host, 0, 300))
	common.set_control_value(ctx, controls.host_enabled, state.cut_enabled.host and true or false)
	common.set_control_value(ctx, controls.p2_cut, common.clamp_int(state.cuts.player2, 0, 300))
	common.set_control_value(ctx, controls.p2_enabled, state.cut_enabled.player2 and true or false)
	common.set_control_value(ctx, controls.p3_cut, common.clamp_int(state.cuts.player3, 0, 300))
	common.set_control_value(ctx, controls.p3_enabled, state.cut_enabled.player3 and true or false)
	common.set_control_value(ctx, controls.p4_cut, common.clamp_int(state.cuts.player4, 0, 300))
	common.set_control_value(ctx, controls.p4_enabled, state.cut_enabled.player4 and true or false)
	return true
end

function controller.register(parent_menu)
	if not parent_menu then
		return nil
	end

	local ctx = controller.ctx
	local controls = controller.controls
	local root = parent_menu:submenu(t("feature.casino.name"))

	root:breaker(t("casino.info.title"))
	root:breaker(t("casino.info.max_transaction"))
	root:breaker(t("casino.info.transaction_cooldown"))
	root:breaker(t("casino.info.heist_cooldown"))

	common.add_button(root, t("casino.action.teleport_arcade"), actions.teleport_arcade)

	local launch = root:submenu(t("casino.group.launch"))
	controls.solo_launch = common.add_toggle(ctx, launch, t("casino.action.solo_launch"), function()
		return core_state.solo_launch.casino
	end, function(enabled)
		core_state.solo_launch.casino = enabled and true or false
		controller.refresh_controls()
	end)
	common.add_button(launch, t("casino.action.force_ready"), actions.force_ready)
	common.add_button(launch, t("casino.action.skip_setup"), actions.skip_arcade_setup)

	local preps = root:submenu(t("casino.group.preps"))
	controls.unlock_poi = common.add_toggle(ctx, preps, t("casino.action.unlock_on_apply"), function()
		return state.config.unlock_all_poi
	end, function(enabled)
		state.config.unlock_all_poi = enabled and true or false
	end)
	controls.difficulty = common.add_combo_options(
		ctx,
		preps,
		t("casino.field.difficulty"),
		localized_options(data.options.difficulties),
		function()
			return state.config.difficulty
		end,
		function(value)
			state.config.difficulty = value
		end
	)
	controls.approach = common.add_combo_options(
		ctx,
		preps,
		t("casino.field.approach"),
		localized_options(data.options.approaches),
		function()
			return state.config.approach
		end,
		function(value)
			state.config.approach = value
			state.config.crew_weapon = data.options.gunmen[1].value
			state.config.loadout_slot = 1
			controller.refresh_controls()
		end
	)
	controls.gunman = common.add_combo_options(
		ctx,
		preps,
		t("casino.field.gunman"),
		localized_options(data.options.gunmen),
		function()
			return state.config.crew_weapon
		end,
		function(value)
			state.config.crew_weapon = value
			state.config.loadout_slot = 1
			controller.refresh_controls()
		end
	)
	controls.loadout_slot = common.add_number_int(ctx, preps, t("casino.field.loadout_slot"), 1, 2, 1, function()
		return state.config.loadout_slot
	end, function(value)
		state.config.loadout_slot = value
		state.clamp_loadout_slot()
	end)
	controls.driver = common.add_combo_options(
		ctx,
		preps,
		t("casino.field.driver"),
		localized_options(data.options.drivers),
		function()
			return state.config.crew_driver
		end,
		function(value)
			state.config.crew_driver = value
			state.config.vehicle_slot = 1
			controller.refresh_controls()
		end
	)
	controls.vehicle_slot = common.add_number_int(ctx, preps, t("casino.field.vehicle_slot"), 1, 4, 1, function()
		return state.config.vehicle_slot
	end, function(value)
		state.config.vehicle_slot = value
		state.clamp_vehicle_slot()
	end)
	controls.hacker = common.add_combo_options(
		ctx,
		preps,
		t("casino.field.hacker"),
		localized_options(data.options.hackers),
		function()
			return state.config.crew_hacker
		end,
		function(value)
			state.config.crew_hacker = value
		end
	)
	controls.masks = common.add_combo_options(
		ctx,
		preps,
		t("casino.field.masks"),
		localized_options(data.options.masks),
		function()
			return state.config.masks
		end,
		function(value)
			state.config.masks = value
		end
	)
	controls.guards = common.add_combo_options(
		ctx,
		preps,
		t("casino.field.guards"),
		localized_options(data.options.guards),
		function()
			return state.config.disrupt_shipments
		end,
		function(value)
			state.config.disrupt_shipments = value
		end
	)
	controls.keycards = common.add_combo_options(
		ctx,
		preps,
		t("casino.field.keycards"),
		localized_options(data.options.keycards),
		function()
			return state.config.key_levels
		end,
		function(value)
			state.config.key_levels = value
		end
	)
	controls.target = common.add_combo_options(
		ctx,
		preps,
		t("casino.field.target"),
		localized_options(data.options.targets),
		function()
			return state.config.target
		end,
		function(value)
			state.config.target = value
		end
	)
	common.add_button(preps, t("casino.action.reset_preps"), actions.reset_preps)
	common.add_button(preps, t("casino.action.apply_preps"), actions.apply_preps)

	local cuts = root:submenu(t("casino.group.cuts"))
	controls.remove_crew = common.add_toggle(ctx, cuts, t("casino.action.remove_crew_cuts"), function()
		return state.flags.remove_crew_cuts_enabled
	end, function(enabled)
		actions.set_remove_crew_cuts(enabled)
		controller.refresh_controls()
	end)
	controls.max_payout = common.add_toggle(ctx, cuts, t("casino.action.max_payout"), function()
		return state.flags.max_payout_enabled
	end, function(enabled)
		actions.set_max_payout(enabled)
		controller.refresh_controls()
	end)
	controls.host_cut = common.add_number_int(ctx, cuts, t("casino.field.host_cut"), 0, 300, 5, function()
		return state.cuts.host
	end, function(value)
		state.set_cut("host", value)
	end)
	controls.host_enabled = common.add_toggle(ctx, cuts, t("casino.field.host_enabled"), function()
		return state.cut_enabled.host
	end, function(enabled)
		state.set_cut_enabled("host", enabled)
	end)
	controls.p2_cut = common.add_number_int(ctx, cuts, t("casino.field.p2_cut"), 0, 300, 5, function()
		return state.cuts.player2
	end, function(value)
		state.set_cut("player2", value)
	end)
	controls.p2_enabled = common.add_toggle(ctx, cuts, t("casino.field.p2_enabled"), function()
		return state.cut_enabled.player2
	end, function(enabled)
		state.set_cut_enabled("player2", enabled)
	end)
	controls.p3_cut = common.add_number_int(ctx, cuts, t("casino.field.p3_cut"), 0, 300, 5, function()
		return state.cuts.player3
	end, function(value)
		state.set_cut("player3", value)
	end)
	controls.p3_enabled = common.add_toggle(ctx, cuts, t("casino.field.p3_enabled"), function()
		return state.cut_enabled.player3
	end, function(enabled)
		state.set_cut_enabled("player3", enabled)
	end)
	controls.p4_cut = common.add_number_int(ctx, cuts, t("casino.field.p4_cut"), 0, 300, 5, function()
		return state.cuts.player4
	end, function(value)
		state.set_cut("player4", value)
	end)
	controls.p4_enabled = common.add_toggle(ctx, cuts, t("casino.field.p4_enabled"), function()
		return state.cut_enabled.player4
	end, function(enabled)
		state.set_cut_enabled("player4", enabled)
	end)
	common.add_button(cuts, t("casino.action.preset_100"), function()
		state.set_uniform_cuts(100)
		controller.refresh_controls()
	end)
	common.add_button(cuts, t("casino.action.apply_cuts"), actions.apply_cuts)

	local tools = root:submenu(t("casino.group.tools"))
	common.add_button(tools, t("casino.action.fingerprint"), actions.fingerprint_hack)
	common.add_button(tools, t("casino.action.keypad"), actions.instant_keypad_hack)
	common.add_button(tools, t("casino.action.vault_drill"), actions.instant_vault_drill)
	common.add_button(tools, t("casino.action.instant_finish"), actions.instant_finish)
	common.add_button(tools, t("casino.action.fix_keycards"), actions.fix_stuck_keycards)
	common.add_button(tools, t("casino.action.skip_objective"), actions.skip_objective)
	common.add_button(tools, t("casino.action.skip_cutscene"), actions.skip_cutscene)
	common.add_button(tools, t("casino.action.team_lives"), actions.set_team_lives)
	controls.autograbber = common.add_toggle(ctx, tools, t("casino.action.autograbber"), function()
		return state.flags.autograbber_enabled
	end, function(enabled)
		actions.set_autograbber(enabled)
	end)

	local teleport = root:submenu(t("casino.group.teleport"))
	teleport:breaker(t("casino.group.teleport_inside"))
	common.add_button(teleport, t("casino.teleport.staff_lobby_inside"), actions.teleport_staff_lobby_inside)
	common.add_button(teleport, t("casino.teleport.side_safe"), actions.teleport_side_safe)
	common.add_button(teleport, t("casino.teleport.tunnel_door"), actions.teleport_tunnel_door)
	teleport:breaker(t("casino.group.teleport_outside"))
	common.add_button(teleport, t("casino.teleport.tunnel"), actions.teleport_tunnel)
	common.add_button(teleport, t("casino.teleport.staff_lobby_outside"), actions.teleport_staff_lobby)

	preset_ui.controller_group(root, {
		feature_id = data.feature_id,
		ctx = controller.ctx,
		collect = casino_presets.collect,
		apply = casino_presets.apply,
		refresh = controller.refresh_controls,
	})

	local danger = root:submenu(t("casino.group.danger"))
	danger:breaker(t("casino.warning.use_with_caution"))
	common.add_button(danger, t("casino.action.skip_cooldown"), actions.remove_cooldown)

	controller.refresh_controls()
	if state.flags.max_payout_enabled then
		actions.refresh_max_payout(true)
		controller.refresh_controls()
	end
	return root
end

return controller
