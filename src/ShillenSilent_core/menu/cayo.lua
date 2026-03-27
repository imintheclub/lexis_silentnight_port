local cayo_logic = require("ShillenSilent_core.heists.cayo.logic")
local native_api = require("ShillenSilent_core.core.native_api")

local CayoConfig = cayo_logic.CayoConfig
local CayoPrepOptions = cayo_logic.CayoPrepOptions
local CayoCutsValues = cayo_logic.CayoCutsValues
local cayo_flags = cayo_logic.cayo_flags

local cayo_menu = {
	controls = {},
	syncing = false,
}

local function clamp_int(value, min_value, max_value)
	local number = tonumber(value)
	if not number then
		return min_value
	end
	local floored = math.floor(number)
	if floored < min_value then
		return min_value
	end
	if floored > max_value then
		return max_value
	end
	return floored
end

local function find_index_by_value(options, value, default_index)
	for i = 1, #options do
		if options[i].value == value then
			return i
		end
	end
	return default_index or 1
end

local function with_sync(fn)
	cayo_menu.syncing = true
	local ok, err = pcall(fn)
	cayo_menu.syncing = false
	if not ok and notify then
		notify.push("ShillenSilent Menu", tostring(err), 3000)
	end
	return ok
end

local function safe_call(fn, ...)
	local ok, err = pcall(fn, ...)
	if not ok and notify then
		notify.push("ShillenSilent Menu", tostring(err), 3000)
	end
	return ok
end

local function bind_change_event(option, fn)
	option:event(menu.event.click, function(opt)
		if cayo_menu.syncing then
			return
		end
		safe_call(fn, opt)
	end)
end

local function bind_click_event(option, fn)
	option:event(menu.event.click, function(opt)
		safe_call(fn, opt)
	end)
end

local function set_control_value(control, value)
	if control == nil then
		return
	end
	with_sync(function()
		control.value = value
	end)
end

local function add_combo_option(parent_menu, label, options, get_value, set_value)
	local entries = {}
	for i = 1, #options do
		entries[i] = { options[i].name, i }
	end

	local combo = parent_menu:combo_int(label, entries, menu.type.scroll)
	combo.value = find_index_by_value(options, get_value(), 1)

	bind_change_event(combo, function(opt)
		local idx = clamp_int(opt and opt.value or combo.value, 1, #options)
		local selected = options[idx]
		if selected then
			set_value(selected.value, idx, selected.name)
		end
	end)

	return combo
end

local function add_number_option(parent_menu, label, min_value, max_value, step, get_value, set_value)
	local number = parent_menu:number_int(label, menu.type.scroll):fmt("%i", min_value, max_value, step)
	number.value = clamp_int(get_value(), min_value, max_value)

	bind_change_event(number, function(opt)
		local value = clamp_int(opt and opt.value or number.value, min_value, max_value)
		set_value(value)
	end)

	return number
end

local function add_toggle_option(parent_menu, label, get_value, set_value)
	local toggle = parent_menu:toggle(label)
	toggle.value = get_value() and true or false

	bind_change_event(toggle, function(opt)
		local enabled = (opt and opt.value) and true or false
		set_value(enabled)
	end)

	return toggle
end

local function add_button(parent_menu, label, fn)
	local button = parent_menu:button(label)
	bind_click_event(button, fn)
	return button
end

local function add_cayo_preps_menu(cayo_root)
	local preps_menu = cayo_root:submenu("Preps")
	local controls = cayo_menu.controls

	add_button(preps_menu, "Unlock All POI", function()
		cayo_logic.cayo_unlock_all_poi()
	end)

	controls.womans_bag_toggle = add_toggle_option(preps_menu, "Woman's Bag", function()
		return cayo_flags.womans_bag_enabled
	end, function(enabled)
		cayo_logic.cayo_set_womans_bag(enabled)
	end)

	controls.unlock_on_apply_toggle = add_toggle_option(preps_menu, "Unlock All POI on Apply", function()
		return CayoConfig.unlock_all_poi
	end, function(enabled)
		CayoConfig.unlock_all_poi = enabled and true or false
	end)

	controls.difficulty_combo = add_combo_option(preps_menu, "Difficulty", CayoPrepOptions.difficulties, function()
		return CayoConfig.diff
	end, function(value)
		CayoConfig.diff = value
	end)

	controls.approach_combo = add_combo_option(preps_menu, "Approach", CayoPrepOptions.approaches, function()
		return CayoConfig.app
	end, function(value)
		CayoConfig.app = value
	end)

	controls.loadout_combo = add_combo_option(preps_menu, "Loadout", CayoPrepOptions.loadouts, function()
		return CayoConfig.wep
	end, function(value)
		CayoConfig.wep = value
	end)

	controls.primary_target_combo = add_combo_option(
		preps_menu,
		"Primary Target",
		CayoPrepOptions.primary_targets,
		function()
			return CayoConfig.tgt
		end,
		function(value)
			CayoConfig.tgt = value
		end
	)

	controls.compound_target_combo = add_combo_option(
		preps_menu,
		"Compound Target",
		CayoPrepOptions.secondary_targets,
		function()
			return CayoConfig.sec_comp
		end,
		function(value)
			CayoConfig.sec_comp = value
		end
	)

	controls.compound_amount_combo = add_combo_option(
		preps_menu,
		"Compound Amount",
		CayoPrepOptions.compound_amounts,
		function()
			return CayoConfig.amt_comp
		end,
		function(value)
			CayoConfig.amt_comp = value
		end
	)

	controls.arts_amount_combo = add_combo_option(preps_menu, "Arts Amount", CayoPrepOptions.arts_amounts, function()
		return CayoConfig.paint
	end, function(value)
		CayoConfig.paint = value
	end)

	controls.island_target_combo = add_combo_option(
		preps_menu,
		"Island Target",
		CayoPrepOptions.secondary_targets,
		function()
			return CayoConfig.sec_isl
		end,
		function(value)
			CayoConfig.sec_isl = value
		end
	)

	controls.island_amount_combo = add_combo_option(
		preps_menu,
		"Island Amount",
		CayoPrepOptions.island_amounts,
		function()
			return CayoConfig.amt_isl
		end,
		function(value)
			CayoConfig.amt_isl = value
		end
	)

	controls.cash_value = add_number_option(preps_menu, "Cash Value", 0, 2550000, 50000, function()
		return CayoConfig.val_cash
	end, function(value)
		CayoConfig.val_cash = value
	end)

	controls.weed_value = add_number_option(preps_menu, "Weed Value", 0, 2550000, 50000, function()
		return CayoConfig.val_weed
	end, function(value)
		CayoConfig.val_weed = value
	end)

	controls.coke_value = add_number_option(preps_menu, "Coke Value", 0, 2550000, 50000, function()
		return CayoConfig.val_coke
	end, function(value)
		CayoConfig.val_coke = value
	end)

	controls.gold_value = add_number_option(preps_menu, "Gold Value", 0, 2550000, 50000, function()
		return CayoConfig.val_gold
	end, function(value)
		CayoConfig.val_gold = value
	end)

	controls.art_value = add_number_option(preps_menu, "Arts Value", 0, 2550000, 50000, function()
		return CayoConfig.val_art
	end, function(value)
		CayoConfig.val_art = value
	end)

	add_button(preps_menu, "Reset Value Defaults", function()
		CayoConfig.val_cash = CayoPrepOptions.default_values.cash
		CayoConfig.val_weed = CayoPrepOptions.default_values.weed
		CayoConfig.val_coke = CayoPrepOptions.default_values.coke
		CayoConfig.val_gold = CayoPrepOptions.default_values.gold
		CayoConfig.val_art = CayoPrepOptions.default_values.art
		cayo_menu.refresh_controls()
		if notify then
			notify.push("Cayo Preps", "Loot values reset", 2000)
		end
	end)

	add_button(preps_menu, "Reset Preps", function()
		cayo_logic.cayo_reset_preps()
	end)

	add_button(preps_menu, "Apply Preps", function()
		cayo_logic.cayo_apply_preps()
	end)
end

local function add_cayo_tools_menu(cayo_root)
	local tools_menu = cayo_root:submenu("Tools")

	add_button(tools_menu, "Instant Voltlab Hack", function()
		cayo_logic.cayo_instant_voltlab_hack()
	end)
	add_button(tools_menu, "Instant Password Hack", function()
		cayo_logic.cayo_instant_password_hack()
	end)
	add_button(tools_menu, "Bypass Plasma Cutter", function()
		cayo_logic.cayo_bypass_plasma_cutter()
	end)
	add_button(tools_menu, "Bypass Drainage Pipe", function()
		cayo_logic.cayo_bypass_drainage_pipe()
	end)
	add_button(tools_menu, "Instant Finish", function()
		cayo_logic.cayo_instant_finish()
	end)
	add_button(tools_menu, "Force Ready", function()
		cayo_logic.cayo_force_ready()
	end)
	add_button(tools_menu, "Reload Planning Screen", function()
		cayo_logic.cayo_reload_planning_screen()
	end)
	add_button(tools_menu, "Skip Cutscene", function()
		native_api.heist_skip_cutscene("Cayo")
	end)
end

local function add_cayo_teleport_start_button(cayo_root)
	add_button(cayo_root, "Teleport to Kosatka", function()
		cayo_logic.cayo_teleport_kosatka()
	end)
end

local function add_cayo_teleport_in_heist_menu(cayo_root)
	local tp_menu = cayo_root:submenu("Teleport (In Heist)")

	tp_menu:breaker("Inside Residence")
	add_button(tp_menu, "Main Target", function()
		cayo_logic.cayo_teleport_main_target()
	end)
	add_button(tp_menu, "Gate (Inside)", function()
		cayo_logic.cayo_teleport_gate()
	end)
	add_button(tp_menu, "Residence", function()
		cayo_logic.cayo_teleport_residence()
	end)
	add_button(tp_menu, "Loot #1", function()
		cayo_logic.cayo_teleport_loot1()
	end)
	add_button(tp_menu, "Loot #2", function()
		cayo_logic.cayo_teleport_loot2()
	end)
	add_button(tp_menu, "Loot #3", function()
		cayo_logic.cayo_teleport_loot3()
	end)

	tp_menu:breaker("Outside Residence")
	add_button(tp_menu, "Center", function()
		cayo_logic.cayo_teleport_center()
	end)
	add_button(tp_menu, "Gate (Outside)", function()
		cayo_logic.cayo_teleport_gate_outside()
	end)
	add_button(tp_menu, "Airport", function()
		cayo_logic.cayo_teleport_airport()
	end)
	add_button(tp_menu, "Escape", function()
		cayo_logic.cayo_teleport_escape()
	end)
end

local function add_cayo_cuts_menu(cayo_root)
	local cuts_menu = cayo_root:submenu("Cuts")
	local controls = cayo_menu.controls

	controls.remove_crew_cuts_toggle = add_toggle_option(cuts_menu, "Remove Crew Cuts", function()
		return cayo_flags.remove_crew_cuts_enabled
	end, function(enabled)
		cayo_logic.cayo_set_remove_crew_cuts(enabled)
		cayo_menu.refresh_controls()
	end)

	controls.max_payout_toggle = add_toggle_option(cuts_menu, "Max Payout", function()
		return cayo_flags.max_payout_enabled
	end, function(enabled)
		cayo_logic.cayo_set_max_payout(enabled)
		cayo_logic.cayo_refresh_max_payout(true, false)
		cayo_menu.refresh_controls()
	end)

	controls.host_cut = add_number_option(cuts_menu, "Host Cut %", 0, 300, 5, function()
		return CayoCutsValues.host
	end, function(value)
		CayoCutsValues.host = value
	end)
	controls.p2_cut = add_number_option(cuts_menu, "Player 2 Cut %", 0, 300, 5, function()
		return CayoCutsValues.player2
	end, function(value)
		CayoCutsValues.player2 = value
	end)
	controls.p3_cut = add_number_option(cuts_menu, "Player 3 Cut %", 0, 300, 5, function()
		return CayoCutsValues.player3
	end, function(value)
		CayoCutsValues.player3 = value
	end)
	controls.p4_cut = add_number_option(cuts_menu, "Player 4 Cut %", 0, 300, 5, function()
		return CayoCutsValues.player4
	end, function(value)
		CayoCutsValues.player4 = value
	end)

	add_button(cuts_menu, "Apply Preset (100%)", function()
		CayoCutsValues.host = 100
		CayoCutsValues.player2 = 100
		CayoCutsValues.player3 = 100
		CayoCutsValues.player4 = 100
		cayo_logic.cayo_apply_cuts()
		cayo_menu.refresh_controls()
	end)

	add_button(cuts_menu, "Apply Cuts", function()
		cayo_logic.cayo_apply_cuts()
	end)
end

local function add_cayo_danger_menu(cayo_root)
	local danger_menu = cayo_root:submenu("Danger")

	danger_menu:breaker("Warning: use with caution")

	add_button(danger_menu, "Skip Heist Cooldown (Solo)", function()
		cayo_logic.cayo_remove_cooldown()
	end)
	add_button(danger_menu, "Skip Heist Cooldown (Team)", function()
		cayo_logic.cayo_remove_cooldown_team()
	end)
end

function cayo_menu.refresh_controls()
	local controls = cayo_menu.controls

	set_control_value(controls.womans_bag_toggle, cayo_flags.womans_bag_enabled and true or false)
	set_control_value(controls.unlock_on_apply_toggle, CayoConfig.unlock_all_poi and true or false)
	set_control_value(controls.remove_crew_cuts_toggle, cayo_flags.remove_crew_cuts_enabled and true or false)
	set_control_value(controls.max_payout_toggle, cayo_flags.max_payout_enabled and true or false)

	set_control_value(controls.difficulty_combo, find_index_by_value(CayoPrepOptions.difficulties, CayoConfig.diff, 1))
	set_control_value(controls.approach_combo, find_index_by_value(CayoPrepOptions.approaches, CayoConfig.app, 1))
	set_control_value(controls.loadout_combo, find_index_by_value(CayoPrepOptions.loadouts, CayoConfig.wep, 1))
	set_control_value(
		controls.primary_target_combo,
		find_index_by_value(CayoPrepOptions.primary_targets, CayoConfig.tgt, 1)
	)
	set_control_value(
		controls.compound_target_combo,
		find_index_by_value(CayoPrepOptions.secondary_targets, CayoConfig.sec_comp, 1)
	)
	set_control_value(
		controls.compound_amount_combo,
		find_index_by_value(CayoPrepOptions.compound_amounts, CayoConfig.amt_comp, 1)
	)
	set_control_value(
		controls.arts_amount_combo,
		find_index_by_value(CayoPrepOptions.arts_amounts, CayoConfig.paint, 1)
	)
	set_control_value(
		controls.island_target_combo,
		find_index_by_value(CayoPrepOptions.secondary_targets, CayoConfig.sec_isl, 1)
	)
	set_control_value(
		controls.island_amount_combo,
		find_index_by_value(CayoPrepOptions.island_amounts, CayoConfig.amt_isl, 1)
	)

	set_control_value(controls.cash_value, clamp_int(CayoConfig.val_cash, 0, 2550000))
	set_control_value(controls.weed_value, clamp_int(CayoConfig.val_weed, 0, 2550000))
	set_control_value(controls.coke_value, clamp_int(CayoConfig.val_coke, 0, 2550000))
	set_control_value(controls.gold_value, clamp_int(CayoConfig.val_gold, 0, 2550000))
	set_control_value(controls.art_value, clamp_int(CayoConfig.val_art, 0, 2550000))

	set_control_value(controls.host_cut, clamp_int(CayoCutsValues.host, 0, 300))
	set_control_value(controls.p2_cut, clamp_int(CayoCutsValues.player2, 0, 300))
	set_control_value(controls.p3_cut, clamp_int(CayoCutsValues.player3, 0, 300))
	set_control_value(controls.p4_cut, clamp_int(CayoCutsValues.player4, 0, 300))

	return true
end

function cayo_menu.register(parent_menu)
	if parent_menu == nil then
		return nil
	end

	local cayo_root = parent_menu:submenu("Cayo Perico Heist")
	cayo_root:breaker("Cayo Perico Heist")
	cayo_root:breaker("Max transaction: $2,550,000")
	cayo_root:breaker("Transaction cooldown: 30 min")
	cayo_root:breaker("Heist cooldown: 45 min (skip)")

	add_cayo_teleport_start_button(cayo_root)
	add_cayo_preps_menu(cayo_root)
	add_cayo_cuts_menu(cayo_root)
	add_cayo_tools_menu(cayo_root)
	add_cayo_teleport_in_heist_menu(cayo_root)
	add_cayo_danger_menu(cayo_root)

	cayo_menu.refresh_controls()
	return cayo_root
end

return cayo_menu
