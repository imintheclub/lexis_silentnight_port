local gCayoInfo = ui.group(heistTab, "Info", nil, nil, nil, 140, "cayo")
ui.label(gCayoInfo, "Cayo Perico Heist", config.colors.accent)
ui.label(gCayoInfo, "Max transaction: $2,550,000", config.colors.text_main)
ui.label(gCayoInfo, "Transaction cooldown: 30 min", config.colors.text_sec)
ui.label(gCayoInfo, "Heist cooldown: 45 min (skip)", config.colors.text_sec)

local gCayoPreps = ui.group(heistTab, "Preps", nil, nil, nil, nil, "cayo")
ui.button(gCayoPreps, "cayo_tp_kosatka", "Teleport to Kosatka", function() cayo_teleport_kosatka() end)
ui.button(gCayoPreps, "cayo_unlock_poi", "Unlock All POI", function() cayo_unlock_all_poi() end)
cayoWomansBagToggle = ui.toggle(gCayoPreps, "cayo_womans_bag", "Woman's Bag", cayo_womans_bag_enabled, function(val)
    cayo_set_womans_bag(val)
end)
cayoUnlockOnApplyToggle = ui.toggle(gCayoPreps, "cayo_unlock_on_apply", "Unlock All POI on Apply", CayoConfig.unlock_all_poi, function(val)
    CayoConfig.unlock_all_poi = val
end)
cayoDifficultyDropdown = ui.dropdown(
    gCayoPreps,
    "cayo_difficulty",
    "Difficulty",
    hp_options_to_names(CayoPrepOptions.difficulties),
    hp_option_index_by_value(CayoPrepOptions.difficulties, CayoConfig.diff, 1),
    function(opt)
        CayoConfig.diff = hp_option_value_by_name(CayoPrepOptions.difficulties, opt, CayoConfig.diff)
    end
)
cayoApproachDropdown = ui.dropdown(
    gCayoPreps,
    "cayo_approach",
    "Approach",
    hp_options_to_names(CayoPrepOptions.approaches),
    hp_option_index_by_value(CayoPrepOptions.approaches, CayoConfig.app, 1),
    function(opt)
        CayoConfig.app = hp_option_value_by_name(CayoPrepOptions.approaches, opt, CayoConfig.app)
    end
)
cayoLoadoutDropdown = ui.dropdown(
    gCayoPreps,
    "cayo_loadout",
    "Loadout",
    hp_options_to_names(CayoPrepOptions.loadouts),
    hp_option_index_by_value(CayoPrepOptions.loadouts, CayoConfig.wep, 1),
    function(opt)
        CayoConfig.wep = hp_option_value_by_name(CayoPrepOptions.loadouts, opt, CayoConfig.wep)
    end
)
cayoPrimaryTargetDropdown = ui.dropdown(
    gCayoPreps,
    "cayo_target",
    "Primary Target",
    hp_options_to_names(CayoPrepOptions.primary_targets),
    hp_option_index_by_value(CayoPrepOptions.primary_targets, CayoConfig.tgt, 1),
    function(opt)
        CayoConfig.tgt = hp_option_value_by_name(CayoPrepOptions.primary_targets, opt, CayoConfig.tgt)
    end
)
cayoCompoundTargetDropdown = ui.dropdown(
    gCayoPreps,
    "cayo_compound",
    "Compound Target",
    hp_options_to_names(CayoPrepOptions.secondary_targets),
    hp_option_index_by_value(CayoPrepOptions.secondary_targets, CayoConfig.sec_comp, 1),
    function(opt)
        CayoConfig.sec_comp = hp_option_value_by_name(CayoPrepOptions.secondary_targets, opt, CayoConfig.sec_comp)
    end
)
cayoCompoundAmountDropdown = ui.dropdown(
    gCayoPreps,
    "cayo_compound_amount",
    "Compound Amount",
    hp_options_to_names(CayoPrepOptions.compound_amounts),
    hp_option_index_by_value(CayoPrepOptions.compound_amounts, CayoConfig.amt_comp, 1),
    function(opt)
        CayoConfig.amt_comp = hp_option_value_by_name(CayoPrepOptions.compound_amounts, opt, CayoConfig.amt_comp)
    end
)
cayoArtsAmountDropdown = ui.dropdown(
    gCayoPreps,
    "cayo_arts_amount",
    "Arts Amount",
    hp_options_to_names(CayoPrepOptions.arts_amounts),
    hp_option_index_by_value(CayoPrepOptions.arts_amounts, CayoConfig.paint, 1),
    function(opt)
        CayoConfig.paint = hp_option_value_by_name(CayoPrepOptions.arts_amounts, opt, CayoConfig.paint)
    end
)
cayoIslandTargetDropdown = ui.dropdown(
    gCayoPreps,
    "cayo_island",
    "Island Target",
    hp_options_to_names(CayoPrepOptions.secondary_targets),
    hp_option_index_by_value(CayoPrepOptions.secondary_targets, CayoConfig.sec_isl, 1),
    function(opt)
        CayoConfig.sec_isl = hp_option_value_by_name(CayoPrepOptions.secondary_targets, opt, CayoConfig.sec_isl)
    end
)
cayoIslandAmountDropdown = ui.dropdown(
    gCayoPreps,
    "cayo_island_amount",
    "Island Amount",
    hp_options_to_names(CayoPrepOptions.island_amounts),
    hp_option_index_by_value(CayoPrepOptions.island_amounts, CayoConfig.amt_isl, 1),
    function(opt)
        CayoConfig.amt_isl = hp_option_value_by_name(CayoPrepOptions.island_amounts, opt, CayoConfig.amt_isl)
    end
)
cayoAdvancedToggle = nil
cayoCashValueSlider = ui.slider(gCayoPreps, "cayo_cash_value", "Cash Value", 0, 2550000, CayoConfig.val_cash, function(val)
    CayoConfig.val_cash = math.floor(val)
end, nil, 50000)
cayoWeedValueSlider = ui.slider(gCayoPreps, "cayo_weed_value", "Weed Value", 0, 2550000, CayoConfig.val_weed, function(val)
    CayoConfig.val_weed = math.floor(val)
end, nil, 50000)
cayoCokeValueSlider = ui.slider(gCayoPreps, "cayo_coke_value", "Coke Value", 0, 2550000, CayoConfig.val_coke, function(val)
    CayoConfig.val_coke = math.floor(val)
end, nil, 50000)
cayoGoldValueSlider = ui.slider(gCayoPreps, "cayo_gold_value", "Gold Value", 0, 2550000, CayoConfig.val_gold, function(val)
    CayoConfig.val_gold = math.floor(val)
end, nil, 50000)
cayoArtValueSlider = ui.slider(gCayoPreps, "cayo_art_value", "Arts Value", 0, 2550000, CayoConfig.val_art, function(val)
    CayoConfig.val_art = math.floor(val)
end, nil, 50000)
ui.button(gCayoPreps, "cayo_reset_values", "Reset Value Defaults", function()
    CayoConfig.val_cash = CayoPrepOptions.default_values.cash
    CayoConfig.val_weed = CayoPrepOptions.default_values.weed
    CayoConfig.val_coke = CayoPrepOptions.default_values.coke
    CayoConfig.val_gold = CayoPrepOptions.default_values.gold
    CayoConfig.val_art = CayoPrepOptions.default_values.art
    cayoCashValueSlider.value = CayoConfig.val_cash
    cayoWeedValueSlider.value = CayoConfig.val_weed
    cayoCokeValueSlider.value = CayoConfig.val_coke
    cayoGoldValueSlider.value = CayoConfig.val_gold
    cayoArtValueSlider.value = CayoConfig.val_art
end)
ui.button_pair(
    gCayoPreps,
    "cayo_reset_preps", "Reset Preps", function() cayo_reset_preps() end,
    "cayo_apply_preps", "Apply Preps", function() cayo_apply_preps() end
)

cayoPresetsGroup = hp_build_heist_preset_group(heistTab, "cayo", "cayo", "cayo")

local gCayoTools = ui.group(heistTab, "Tools", nil, nil, nil, nil, "cayo")
ui.button_pair(
    gCayoTools,
    "cayo_tool_voltlab", "Instant Voltlab Hack", function() cayo_instant_voltlab_hack() end,
    "cayo_tool_password", "Instant Password Hack", function() cayo_instant_password_hack() end
)
ui.button_pair(
    gCayoTools,
    "cayo_tool_plasma", "Bypass Plasma Cutter", function() cayo_bypass_plasma_cutter() end,
    "cayo_tool_drainage", "Bypass Drainage Pipe", function() cayo_bypass_drainage_pipe() end
)
ui.button_pair(
    gCayoTools,
    "cayo_tool_finish", "Instant Finish", function() cayo_instant_finish() end,
    "cayo_force_ready", "Force Ready", function() cayo_force_ready() end
)
ui.button_pair(
    gCayoTools,
    "cayo_fix_board", "Fix White Board", function() cayo_reload_planning_screen() end,
    "cayo_skip_cutscene", "Skip Cutscene", function() heist_skip_cutscene("Cayo") end
)
ui.button(gCayoTools, "cayo_tool_reload", "Reload Planning Screen", function() cayo_reload_planning_screen() end)

do
    local gCayoDanger = ui.group(heistTab, "DANGER", nil, nil, nil, nil, "cayo")
    for i = 1, #cooldown_danger_warning_lines do
        ui.label(gCayoDanger, cooldown_danger_warning_lines[i], config.colors.danger_text)
    end
    ui.button(gCayoDanger, "cayo_skip_heist_cooldown_solo", "Skip Heist Cooldown (Solo)", function()
        cayo_remove_cooldown()
    end, nil, false, "danger")
    ui.button(gCayoDanger, "cayo_skip_heist_cooldown_team", "Skip Heist Cooldown (Team)", function()
        cayo_remove_cooldown_team()
    end, nil, false, "danger")
end

-- Teleport section - In Residence
local gCayoTeleportInResidence = ui.group(heistTab, "Teleport - In Residence", nil, nil, nil, nil, "cayo")
ui.button_pair(
    gCayoTeleportInResidence,
    "cayo_tp_target", "Main Target", function() cayo_teleport_main_target() end,
    "cayo_tp_gate", "Gate", function() cayo_teleport_gate() end
)
ui.button_pair(
    gCayoTeleportInResidence,
    "cayo_tp_residence", "Residence", function() cayo_teleport_residence() end,
    "cayo_tp_loot1", "Loot #1", function() cayo_teleport_loot1() end
)
ui.button_pair(
    gCayoTeleportInResidence,
    "cayo_tp_loot2", "Loot #2", function() cayo_teleport_loot2() end,
    "cayo_tp_loot3", "Loot #3", function() cayo_teleport_loot3() end
)

-- Teleport section - Outside Residence
local gCayoTeleportOutside = ui.group(heistTab, "Teleport - Outside Residence", nil, nil, nil, nil, "cayo")
ui.button_pair(
    gCayoTeleportOutside,
    "cayo_tp_center", "Center", function() cayo_teleport_center() end,
    "cayo_tp_gate_outside", "Gate", function() cayo_teleport_gate_outside() end
)
ui.button_pair(
    gCayoTeleportOutside,
    "cayo_tp_airport", "Airport", function() cayo_teleport_airport() end,
    "cayo_tp_escape", "Escape", function() cayo_teleport_escape() end,
    nil, nil, false, false, nil, "green"
)

local gCayoCuts = ui.group(heistTab, "Cuts", nil, nil, nil, nil, "cayo")
cayoRemoveCrewCutsToggle = ui.toggle(gCayoCuts, "cayo_remove_crew_cuts", "Remove Crew Cuts", cayo_remove_crew_cuts_enabled, function(val)
    cayo_set_remove_crew_cuts(val)
end)
cayoHostSliderRef = ui.slider(gCayoCuts, "cayo_cut_host", "Host Cut %", 0, 300, 100, function(val)
    CayoCutsValues.host = math.floor(val)
end, nil, 5)
cayoP2SliderRef = ui.slider(gCayoCuts, "cayo_cut_p2", "Player 2 Cut %", 0, 300, 100, function(val)
    CayoCutsValues.player2 = math.floor(val)
end, nil, 5)
cayoP3SliderRef = ui.slider(gCayoCuts, "cayo_cut_p3", "Player 3 Cut %", 0, 300, 100, function(val)
    CayoCutsValues.player3 = math.floor(val)
end, nil, 5)
cayoP4SliderRef = ui.slider(gCayoCuts, "cayo_cut_p4", "Player 4 Cut %", 0, 300, 100, function(val)
    CayoCutsValues.player4 = math.floor(val)
end, nil, 5)
ui.button_pair(
    gCayoCuts,
    "cayo_cuts_max", "Apply Preset (100%)", function()
        hp_set_uniform_cuts(
            CayoCutsValues,
            { "host", "player2", "player3", "player4" },
            { cayoHostSliderRef, cayoP2SliderRef, cayoP3SliderRef, cayoP4SliderRef },
            100,
            cayo_apply_cuts
        )
    end,
    "cayo_cuts_max_instant", "Apply Preset (Max Payout)", function()
        hp_set_uniform_cuts(
            CayoCutsValues,
            { "host", "player2", "player3", "player4" },
            { cayoHostSliderRef, cayoP2SliderRef, cayoP3SliderRef, cayoP4SliderRef },
            hp_get_cayo_max_payout_cut(),
            cayo_apply_cuts
        )
    end
)
ui.button(gCayoCuts, "cayo_cuts_apply", "Apply Cuts", function() cayo_apply_cuts() end)
