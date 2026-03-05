CasinoPrepOptions = {
    difficulties = {
        { name = "Normal", value = 0 },
        { name = "Hard", value = 1 }
    },
    approaches = {
        { name = "Silent & Sneaky", value = 1 },
        { name = "The Big Con", value = 2 },
        { name = "Aggressive", value = 3 }
    },
    gunmen = {
        { name = "Karl Abolaji", value = 1 },
        { name = "Charlie Reed", value = 3 },
        { name = "Patrick McReary", value = 5 },
        { name = "Gustavo Mota", value = 2 },
        { name = "Chester McCoy", value = 4 }
    },
    loadouts = {
        { name = "Micro SMG (S)", value = 1 },
        { name = "Machine Pistol (S)", value = 1 },
        { name = "Micro SMG", value = 1 },
        { name = "Double Barrel", value = 1 },
        { name = "Sawed-Off", value = 1 },
        { name = "Heavy Revolver", value = 1 },
        { name = "Assault SMG (S)", value = 3 },
        { name = "Bullpup Shotgun (S)", value = 3 },
        { name = "Machine Pistol", value = 3 },
        { name = "Sweeper Shotgun", value = 3 },
        { name = "Assault SMG", value = 3 },
        { name = "Pump Shotgun", value = 3 },
        { name = "Combat PDW", value = 5 },
        { name = "Assault Rifle (S)", value = 5 },
        { name = "Sawed-Off", value = 5 },
        { name = "Compact Rifle", value = 5 },
        { name = "Heavy Shotgun", value = 5 },
        { name = "Combat MG", value = 5 },
        { name = "Carbine Rifle (S)", value = 2 },
        { name = "Assault Shotgun (S)", value = 2 },
        { name = "Carbine Rifle", value = 2 },
        { name = "Assault Shotgun", value = 2 },
        { name = "Carbine Rifle", value = 2 },
        { name = "Assault Shotgun", value = 2 },
        { name = "Pump Shotgun Mk II (S)", value = 4 },
        { name = "Carbine Rifle Mk II (S)", value = 4 },
        { name = "SMG Mk II", value = 4 },
        { name = "Bullpup Rifle Mk II", value = 4 },
        { name = "Pump Shotgun Mk II", value = 4 },
        { name = "Assault Rifle Mk II", value = 4 }
    },
    drivers = {
        { name = "Karim Denz", value = 1 },
        { name = "Zach Nelson", value = 4 },
        { name = "Taliana Martinez", value = 2 },
        { name = "Eddie Toh", value = 3 },
        { name = "Chester McCoy", value = 5 }
    },
    vehicles = {
        { name = "Issi Classic", value = 1 },
        { name = "Asbo", value = 1 },
        { name = "Blista Kanjo", value = 1 },
        { name = "Sentinel Classic", value = 1 },
        { name = "Manchez", value = 4 },
        { name = "Stryder", value = 4 },
        { name = "Defiler", value = 4 },
        { name = "Lectro", value = 4 },
        { name = "Retinue Mk II", value = 2 },
        { name = "Drift Yosemite", value = 2 },
        { name = "Sugoi", value = 2 },
        { name = "Jugular", value = 2 },
        { name = "Sultan Classic", value = 3 },
        { name = "Gauntlet Classic", value = 3 },
        { name = "Ellie", value = 3 },
        { name = "Komoda", value = 3 },
        { name = "Zhaba", value = 5 },
        { name = "Vagrant", value = 5 },
        { name = "Outlaw", value = 5 },
        { name = "Everon", value = 5 }
    },
    hackers = {
        { name = "Rickie Lukens", value = 1 },
        { name = "Yohan Blair", value = 3 },
        { name = "Christian Feltz", value = 2 },
        { name = "Paige Harris", value = 5 },
        { name = "Avi Schwartzman", value = 4 }
    },
    masks = {
        { name = "None", value = 0 },
        { name = "Geometric Set", value = 1 },
        { name = "Hunter Set", value = 2 },
        { name = "Oni Half Mask Set", value = 3 },
        { name = "Emoji Set", value = 4 },
        { name = "Ornate Skull Set", value = 5 },
        { name = "Lucky Fruit Set", value = 6 },
        { name = "Guerilla Set", value = 7 },
        { name = "Clown Set", value = 8 },
        { name = "Animal Set", value = 9 },
        { name = "Riot Set", value = 10 },
        { name = "Oni Full Mask Set", value = 11 },
        { name = "Hockey Set", value = 12 }
    },
    guards = {
        { name = "Elite", value = 0 },
        { name = "Pro", value = 1 },
        { name = "Unit", value = 2 },
        { name = "Rookie", value = 3 }
    },
    keycards = {
        { name = "None", value = 0 },
        { name = "Level 1", value = 1 },
        { name = "Level 2", value = 2 }
    },
    targets = {
        { name = "Cash", value = 0 },
        { name = "Artwork", value = 2 },
        { name = "Gold", value = 1 },
        { name = "Diamonds", value = 3 }
    }
}

CasinoLoadoutRangesByApproach = {
    [1] = { 1, 2 },
    [2] = { 3, 4 },
    [3] = { 5, 6 }
}

CasinoLoadoutRangesByGunmanAndApproach = {
    [1] = { [1] = { 1, 2 }, [2] = { 3, 4 }, [3] = { 5, 6 } },
    [3] = { [1] = { 7, 8 }, [2] = { 9, 10 }, [3] = { 11, 12 } },
    [5] = { [1] = { 13, 14 }, [2] = { 15, 16 }, [3] = { 17, 18 } },
    [2] = { [1] = { 19, 20 }, [2] = { 21, 22 }, [3] = { 23, 24 } },
    [4] = { [1] = { 25, 26 }, [2] = { 27, 28 }, [3] = { 29, 30 } }
}

CasinoVehicleRangesByDriver = {
    [1] = { 1, 4 },
    [4] = { 5, 8 },
    [2] = { 9, 12 },
    [3] = { 13, 16 },
    [5] = { 17, 20 }
}

-- Casino Manual Preps storage
CasinoManualPreps = {
    difficulty = 0,
    approach = 1,
    crew_weapon = 1,
    loadout_slot = 1, -- 1-based in filtered list (stat uses slot - 1)
    crew_driver = 1,
    vehicle_slot = 1, -- 1-based in filtered list (stat uses slot - 1)
    crew_hacker = 1,
    masks = 4,
    disrupt_shipments = 3,
    key_levels = 2,
    target = 3,
    unlock_all_poi = true
}

manualApproachDropdown = nil
manualGunmanDropdown = nil
manualLoadoutDropdown = nil
manualDriverDropdown = nil
manualVehiclesDropdown = nil

function hp_get_casino_loadout_range(approach, gunman)
    local gunman_ranges = CasinoLoadoutRangesByGunmanAndApproach[gunman]
    if gunman_ranges and gunman_ranges[approach] then
        return gunman_ranges[approach]
    end
    return CasinoLoadoutRangesByApproach[approach] or { 1, 2 }
end

function hp_update_casino_loadout_dropdown(reset_selection)
    local range = hp_get_casino_loadout_range(CasinoManualPreps.approach, CasinoManualPreps.crew_weapon)
    local names = hp_option_names_range(CasinoPrepOptions.loadouts, range[1], range[2])

    if reset_selection then
        CasinoManualPreps.loadout_slot = 1
    end
    if CasinoManualPreps.loadout_slot < 1 or CasinoManualPreps.loadout_slot > #names then
        CasinoManualPreps.loadout_slot = 1
    end

    if manualLoadoutDropdown then
        manualLoadoutDropdown.options = names
        manualLoadoutDropdown.value = CasinoManualPreps.loadout_slot
    end
end

function hp_update_casino_vehicle_dropdown(reset_selection)
    local range = CasinoVehicleRangesByDriver[CasinoManualPreps.crew_driver] or { 1, 4 }
    local names = hp_option_names_range(CasinoPrepOptions.vehicles, range[1], range[2])

    if reset_selection then
        CasinoManualPreps.vehicle_slot = 1
    end
    if CasinoManualPreps.vehicle_slot < 1 or CasinoManualPreps.vehicle_slot > #names then
        CasinoManualPreps.vehicle_slot = 1
    end

    if manualVehiclesDropdown then
        manualVehiclesDropdown.options = names
        manualVehiclesDropdown.value = CasinoManualPreps.vehicle_slot
    end
end

function hp_reload_casino_planning_board()
    script.locals("gb_casino_heist_planning", 210).int32 = 2
    script.locals("gb_casino_heist_planning", 212).int32 = 2
end

-- Function to apply manual preps
local function apply_casino_manual_preps()
    if CasinoManualPreps.unlock_all_poi then
        hp_set_stat_for_all_characters("H3OPT_POI", -1)
        hp_set_stat_for_all_characters("H3OPT_ACCESSPOINTS", -1)
        hp_set_stat_for_all_characters("CAS_HEIST_NOTS", -1)
        hp_set_stat_for_all_characters("CAS_HEIST_FLOW", -1)
    end

    hp_set_stat_for_all_characters("H3_LAST_APPROACH", 0)
    hp_set_stat_for_all_characters("H3_HARD_APPROACH", (CasinoManualPreps.difficulty == 0) and 0 or CasinoManualPreps.approach)
    hp_set_stat_for_all_characters("H3OPT_APPROACH", CasinoManualPreps.approach)
    hp_set_stat_for_all_characters("H3OPT_CREWWEAP", CasinoManualPreps.crew_weapon)
    hp_set_stat_for_all_characters("H3OPT_WEAPS", CasinoManualPreps.loadout_slot - 1)
    hp_set_stat_for_all_characters("H3OPT_CREWDRIVER", CasinoManualPreps.crew_driver)
    hp_set_stat_for_all_characters("H3OPT_VEHS", CasinoManualPreps.vehicle_slot - 1)
    hp_set_stat_for_all_characters("H3OPT_CREWHACKER", CasinoManualPreps.crew_hacker)
    hp_set_stat_for_all_characters("H3OPT_TARGET", CasinoManualPreps.target)
    hp_set_stat_for_all_characters("H3OPT_MASKS", CasinoManualPreps.masks)
    hp_set_stat_for_all_characters("H3OPT_DISRUPTSHIP", CasinoManualPreps.disrupt_shipments)
    hp_set_stat_for_all_characters("H3OPT_KEYLEVELS", CasinoManualPreps.key_levels)
    hp_set_stat_for_all_characters("H3OPT_BODYARMORLVL", -1)
    hp_set_stat_for_all_characters("H3OPT_BITSET0", -1)
    hp_set_stat_for_all_characters("H3OPT_BITSET1", -1)
    hp_set_stat_for_all_characters("H3OPT_COMPLETEDPOSIX", -1)

    hp_reload_casino_planning_board()
    if notify then notify.push("Casino Manual Preps", "Applied Granular Configuration", 2000) end
end

local cooldown_danger_warning_lines = {
    "WARNING: DO NOT USE THIS. IF YOU GET BANNED GG",
    "I WARNED YOU. Only use this if you know what you're doing",
    "but honestly still don't."
}

local function build_skip_cooldown_danger_group(tab_ref, heist_subtab, button_id, on_click)
    local group = ui.group(tab_ref, "DANGER", nil, nil, nil, nil, heist_subtab)
    for i = 1, #cooldown_danger_warning_lines do
        ui.label(group, cooldown_danger_warning_lines[i], config.colors.danger_text)
    end
    ui.button(group, button_id, "Skip Heist Cooldown", on_click, nil, false, "danger")
    return group
end

-- Casino Tab Content
local heistTab = ui.tabs[1]
local gCasinoInfo = ui.group(heistTab, "Info", nil, nil, nil, 140, "casino")
ui.label(gCasinoInfo, "Diamond Casino Heist", config.colors.accent)
ui.label(gCasinoInfo, "Max transaction: $3,619,000", config.colors.text_main)
ui.label(gCasinoInfo, "Transaction cooldown: 30 min", config.colors.text_sec)
ui.label(gCasinoInfo, "Heist cooldown: ~45 min (skip)", config.colors.text_sec)

casinoPresetsGroup = hp_build_heist_preset_group(heistTab, "casino", "casino", "casino")

local gTools = ui.group(heistTab, "Tools", nil, nil, nil, nil, "casino")
ui.button_pair(
    gTools,
    "tool_finger", "Fingerprint Hack", function() casino_fingerprint_hack() end,
    "tool_keypad", "Keypad Hack", function() casino_instant_keypad_hack() end
)
ui.button_pair(
    gTools,
    "tool_vault", "Vault Drill", function() casino_instant_vault_drill() end,
    "tool_finish", "Instant Finish", function() casino_instant_finish() end
)
ui.button_pair(
    gTools,
    "tool_keycards", "Fix Keycards", function() casino_fix_stuck_keycards() end,
    "tool_objective", "Skip Objective", function() casino_skip_objective() end
)
ui.button_pair(
    gTools,
    "casino_skip_cutscene", "Skip Cutscene", function() heist_skip_cutscene("Casino") end,
    "tool_lives", "Set Team Lives", function() casino_set_team_lives() end
)
casinoAutograbberToggle = ui.toggle(gTools, "casino_autograbber", "Autograbber", casino_autograbber_enabled, function(val)
    casino_set_autograbber(val)
end)

build_skip_cooldown_danger_group(
    heistTab,
    "casino",
    "casino_skip_heist_cooldown",
    function() casino_remove_cooldown() end
)

-- Launch group
local gLaunch = ui.group(heistTab, "Launch", nil, nil, nil, nil, "casino")
casinoSoloLaunchToggle = ui.toggle(gLaunch, "launch_solo", "Solo Launch", state.solo_launch.casino, function(val)
    state.solo_launch.casino = val
end)
ui.button_pair(
    gLaunch,
    "launch_force_ready", "Force Ready", function() casino_force_ready() end,
    "launch_skip_setup", "Skip Setup", function() casino_skip_arcade_setup() end
)

-- Manual Preps group
local gManualPreps = ui.group(heistTab, "Preps", nil, nil, nil, nil, "casino")
manualUnlockPoiToggle = ui.toggle(gManualPreps, "manual_unlock_poi", "Unlock All POI on Apply", CasinoManualPreps.unlock_all_poi, function(val)
    CasinoManualPreps.unlock_all_poi = val
end)
manualDifficultyDropdown = ui.dropdown(
    gManualPreps,
    "manual_difficulty",
    "Difficulty",
    hp_options_to_names(CasinoPrepOptions.difficulties),
    hp_option_index_by_value(CasinoPrepOptions.difficulties, CasinoManualPreps.difficulty, 1),
    function(opt)
        CasinoManualPreps.difficulty = hp_option_value_by_name(CasinoPrepOptions.difficulties, opt, 0)
    end
)
manualApproachDropdown = ui.dropdown(
    gManualPreps,
    "manual_approach",
    "Approach",
    hp_options_to_names(CasinoPrepOptions.approaches),
    hp_option_index_by_value(CasinoPrepOptions.approaches, CasinoManualPreps.approach, 1),
    function(opt)
        CasinoManualPreps.approach = hp_option_value_by_name(CasinoPrepOptions.approaches, opt, 1)
        CasinoManualPreps.crew_weapon = CasinoPrepOptions.gunmen[1].value
        if manualGunmanDropdown then
            manualGunmanDropdown.value = 1
        end
        hp_update_casino_loadout_dropdown(true)
    end
)
manualGunmanDropdown = ui.dropdown(
    gManualPreps,
    "manual_crew_weapon",
    "Crew Gunman",
    hp_options_to_names(CasinoPrepOptions.gunmen),
    hp_option_index_by_value(CasinoPrepOptions.gunmen, CasinoManualPreps.crew_weapon, 1),
    function(opt)
        CasinoManualPreps.crew_weapon = hp_option_value_by_name(CasinoPrepOptions.gunmen, opt, 1)
        hp_update_casino_loadout_dropdown(true)
    end
)
manualLoadoutDropdown = ui.dropdown(
    gManualPreps,
    "manual_weapons",
    "Loadout",
    { "Micro SMG (S)", "Machine Pistol (S)" },
    1,
    function(opt)
        for i = 1, #manualLoadoutDropdown.options do
            if manualLoadoutDropdown.options[i] == opt then
                CasinoManualPreps.loadout_slot = i
                break
            end
        end
    end
)
manualDriverDropdown = ui.dropdown(
    gManualPreps,
    "manual_crew_driver",
    "Crew Driver",
    hp_options_to_names(CasinoPrepOptions.drivers),
    hp_option_index_by_value(CasinoPrepOptions.drivers, CasinoManualPreps.crew_driver, 1),
    function(opt)
        CasinoManualPreps.crew_driver = hp_option_value_by_name(CasinoPrepOptions.drivers, opt, 1)
        hp_update_casino_vehicle_dropdown(true)
    end
)
manualVehiclesDropdown = ui.dropdown(
    gManualPreps,
    "manual_vehicles",
    "Vehicles",
    { "Issi Classic", "Asbo", "Blista Kanjo", "Sentinel Classic" },
    1,
    function(opt)
        for i = 1, #manualVehiclesDropdown.options do
            if manualVehiclesDropdown.options[i] == opt then
                CasinoManualPreps.vehicle_slot = i
                break
            end
        end
    end
)
manualHackerDropdown = ui.dropdown(
    gManualPreps,
    "manual_crew_hacker",
    "Crew Hacker",
    hp_options_to_names(CasinoPrepOptions.hackers),
    hp_option_index_by_value(CasinoPrepOptions.hackers, CasinoManualPreps.crew_hacker, 1),
    function(opt)
        CasinoManualPreps.crew_hacker = hp_option_value_by_name(CasinoPrepOptions.hackers, opt, 1)
    end
)
manualMasksDropdown = ui.dropdown(
    gManualPreps,
    "manual_masks",
    "Masks",
    hp_options_to_names(CasinoPrepOptions.masks),
    hp_option_index_by_value(CasinoPrepOptions.masks, CasinoManualPreps.masks, 1),
    function(opt)
        CasinoManualPreps.masks = hp_option_value_by_name(CasinoPrepOptions.masks, opt, 4)
    end
)
manualGuardsDropdown = ui.dropdown(
    gManualPreps,
    "manual_disrupt",
    "Guards Strength",
    hp_options_to_names(CasinoPrepOptions.guards),
    hp_option_index_by_value(CasinoPrepOptions.guards, CasinoManualPreps.disrupt_shipments, 1),
    function(opt)
        CasinoManualPreps.disrupt_shipments = hp_option_value_by_name(CasinoPrepOptions.guards, opt, 3)
    end
)
manualKeycardsDropdown = ui.dropdown(
    gManualPreps,
    "manual_key_levels",
    "Keycards",
    hp_options_to_names(CasinoPrepOptions.keycards),
    hp_option_index_by_value(CasinoPrepOptions.keycards, CasinoManualPreps.key_levels, 1),
    function(opt)
        CasinoManualPreps.key_levels = hp_option_value_by_name(CasinoPrepOptions.keycards, opt, 2)
    end
)
manualTargetDropdown = ui.dropdown(
    gManualPreps,
    "manual_target",
    "Target",
    hp_options_to_names(CasinoPrepOptions.targets),
    hp_option_index_by_value(CasinoPrepOptions.targets, CasinoManualPreps.target, 1),
    function(opt)
        CasinoManualPreps.target = hp_option_value_by_name(CasinoPrepOptions.targets, opt, 3)
    end
)
ui.button_pair(
    gManualPreps,
    "manual_reset_preps", "Reset Preps", function() reset_heist_preps() end,
    "manual_apply", "Apply Preps", function() apply_casino_manual_preps() end
)
hp_update_casino_loadout_dropdown(true)
hp_update_casino_vehicle_dropdown(true)

local gCuts = ui.group(heistTab, "Cuts", nil, nil, nil, nil, "casino")
casinoRemoveCrewCutsToggle = ui.toggle(gCuts, "casino_remove_crew_cuts", "Remove Crew Cuts", casino_remove_crew_cuts_enabled, function(val)
    casino_set_remove_crew_cuts(val)
end)
casinoHostSliderRef = ui.slider(gCuts, "cut_host", "Host Cut %", 0, 300, 100, function(val)
    CutsValues.host = math.floor(val)
end, nil, 5)
casinoP2SliderRef = ui.slider(gCuts, "cut_p2", "Player 2 Cut %", 0, 300, 0, function(val)
    CutsValues.player2 = math.floor(val)
end, nil, 5)
casinoP3SliderRef = ui.slider(gCuts, "cut_p3", "Player 3 Cut %", 0, 300, 0, function(val)
    CutsValues.player3 = math.floor(val)
end, nil, 5)
casinoP4SliderRef = ui.slider(gCuts, "cut_p4", "Player 4 Cut %", 0, 300, 0, function(val)
    CutsValues.player4 = math.floor(val)
end, nil, 5)
ui.button_pair(
    gCuts,
    "cuts_max", "Apply Preset (100%)", function()
        hp_set_uniform_cuts(
            CutsValues,
            { "host", "player2", "player3", "player4" },
            { casinoHostSliderRef, casinoP2SliderRef, casinoP3SliderRef, casinoP4SliderRef },
            100,
            apply_casino_cuts
        )
    end,
    "cuts_max_instant", "Apply Preset (Max Payout)", function()
        hp_set_uniform_cuts(
            CutsValues,
            { "host", "player2", "player3", "player4" },
            { casinoHostSliderRef, casinoP2SliderRef, casinoP3SliderRef, casinoP4SliderRef },
            hp_get_casino_max_payout_cut(),
            apply_casino_cuts
        )
    end
)
ui.button(gCuts, "cuts_apply", "Apply Cuts", function() apply_casino_cuts() end)

-- Casino Teleport functions
local function casino_teleport_tunnel()
    -- Tunnel coordinates (Casino Heist - Outside Casino)
    -- Coordinates: 968, -73, 75
    run_coords_teleport("Casino Teleport", "Teleported to Tunnel", 968.0, -73.0, 75.0)
end

local function casino_teleport_staff_lobby()
    -- Staff Lobby coordinates (Casino Heist - Outside Casino)
    -- Coordinates: 982, 16, 82
    run_coords_teleport("Casino Teleport", "Teleported to Staff Lobby", 982.0, 16.0, 82.0)
end

local function casino_teleport_staff_lobby_inside()
    -- Staff Lobby coordinates (Casino Heist - In Casino)
    -- Coordinates: 2547, -270, -58
    run_coords_teleport("Casino Teleport", "Teleported to Staff Lobby", 2547.0, -270.0, -58.0)
end

local function casino_teleport_side_safe()
    -- Side Safe coordinates (Casino Heist - In Casino)
    -- Coordinates: 2522, -287, -58
    run_coords_teleport("Casino Teleport", "Teleported to Side Safe", 2522.0, -287.0, -58.0)
end

local function casino_teleport_tunnel_door()
    -- Tunnel Door coordinates (Casino Heist - In Casino)
    -- Coordinates: 2469, -279, -70
    run_coords_teleport("Casino Teleport", "Teleported to Tunnel Door", 2469.0, -279.0, -70.0)
end

-- Teleport section - Outside Casino
local gCasinoTeleportOutside = ui.group(heistTab, "Teleport - Outside Casino", nil, nil, nil, nil, "casino")
ui.button_pair(
    gCasinoTeleportOutside,
    "casino_tp_tunnel", "Tunnel", function() casino_teleport_tunnel() end,
    "casino_tp_staff_lobby", "Staff Lobby", function() casino_teleport_staff_lobby() end
)

-- Teleport section - In Casino (moved below Outside Casino)
local gCasinoTeleportInside = ui.group(heistTab, "Teleport - In Casino", nil, nil, nil, nil, "casino")
ui.button_pair(
    gCasinoTeleportInside,
    "casino_tp_staff_lobby_inside", "Staff Lobby", function() casino_teleport_staff_lobby_inside() end,
    "casino_tp_side_safe", "Side Safe", function() casino_teleport_side_safe() end
)
ui.button(gCasinoTeleportInside, "casino_tp_tunnel_door", "Tunnel Door", function() casino_teleport_tunnel_door() end)

-- Cayo Tab Content
