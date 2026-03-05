-- ---------------------------------------------------------

-- Globals for Cayo Perico
local CayoGlobals = {
    Host = 1980923,
    P2 = 1980924,
    P3 = 1980925,
    P4 = 1980926,
    ReadyBase = 1981147
}

local CayoReady = {
    PLAYER1 = 1981156,
    PLAYER2 = 1981184,
    PLAYER3 = 1981211,
    PLAYER4 = 1981238
}

-- Cayo cuts values storage
CayoCutsValues = {
    host = 100,
    player2 = 100,
    player3 = 100,
    player4 = 100
}

-- Cayo prep options (aligned with SilentNight behavior)
CayoPrepOptions = {
    difficulties = {
        { name = "Normal", value = 126823 },
        { name = "Hard", value = 131055 }
    },
    approaches = {
        { name = "Kosatka", value = 65283 },
        { name = "Alkonost", value = 65413 },
        { name = "Velum", value = 65289 },
        { name = "Stealth Annihilator", value = 65425 },
        { name = "Patrol Boat", value = 65313 },
        { name = "Longfin", value = 65345 },
        { name = "All Ways", value = 65535 }
    },
    loadouts = {
        { name = "Aggressor", value = 1 },
        { name = "Conspirator", value = 2 },
        { name = "Crackshot", value = 3 },
        { name = "Saboteur", value = 4 },
        { name = "Marksman", value = 5 }
    },
    primary_targets = {
        { name = "Sinsimito Tequila", value = 0 },
        { name = "Ruby Necklace", value = 1 },
        { name = "Bearer Bonds", value = 2 },
        { name = "Pink Diamond", value = 3 },
        { name = "Madrazo Files", value = 4 },
        { name = "Panther Statue", value = 5 }
    },
    secondary_targets = {
        { name = "None", value = "NONE" },
        { name = "Cash", value = "CASH" },
        { name = "Weed", value = "WEED" },
        { name = "Coke", value = "COKE" },
        { name = "Gold", value = "GOLD" }
    },
    compound_amounts = {
        { name = "Empty", value = 0 },
        { name = "Full", value = 255 },
        { name = "1", value = 128 },
        { name = "2", value = 64 },
        { name = "3", value = 196 },
        { name = "4", value = 204 },
        { name = "5", value = 220 },
        { name = "6", value = 252 },
        { name = "7", value = 253 }
    },
    island_amounts = {
        { name = "Empty", value = 0 },
        { name = "Full", value = 16777215 },
        { name = "1", value = 8388608 },
        { name = "2", value = 12582912 },
        { name = "3", value = 12845056 },
        { name = "4", value = 12976128 },
        { name = "5", value = 13500416 },
        { name = "6", value = 14548992 },
        { name = "7", value = 16646144 },
        { name = "8", value = 16711680 },
        { name = "9", value = 16744448 },
        { name = "10", value = 16760832 },
        { name = "11", value = 16769024 },
        { name = "12", value = 16769536 },
        { name = "13", value = 16770560 },
        { name = "14", value = 16770816 },
        { name = "15", value = 16770880 },
        { name = "16", value = 16771008 },
        { name = "17", value = 16773056 },
        { name = "18", value = 16777152 },
        { name = "19", value = 16777184 },
        { name = "20", value = 16777200 },
        { name = "21", value = 16777202 },
        { name = "22", value = 16777203 },
        { name = "23", value = 16777211 }
    },
    arts_amounts = {
        { name = "Empty", value = 0 },
        { name = "Full", value = 127 },
        { name = "1", value = 64 },
        { name = "2", value = 96 },
        { name = "3", value = 112 },
        { name = "4", value = 120 },
        { name = "5", value = 122 },
        { name = "6", value = 126 }
    },
    default_values = {
        cash = 83250,
        weed = 135000,
        coke = 202500,
        gold = 333333,
        art = 180000
    }
}

-- Cayo configuration storage
CayoConfig = {
    diff = 131055,         -- Hard
    app = 65535,           -- All ways
    wep = 1,               -- Aggressor
    tgt = 5,               -- Panther
    sec_comp = "GOLD",
    sec_isl = "GOLD",
    amt_comp = 255,        -- Full
    amt_isl = 16777215,    -- Full
    paint = 127,           -- Full
    val_cash = CayoPrepOptions.default_values.cash,
    val_weed = CayoPrepOptions.default_values.weed,
    val_coke = CayoPrepOptions.default_values.coke,
    val_gold = CayoPrepOptions.default_values.gold,
    val_art = CayoPrepOptions.default_values.art,
    advanced = false,
    unlock_all_poi = true
}

local CAYO_TUNABLE_DEFAULTS = {
    bag_max_capacity = 1800,
    pavel_cut = -0.02,
    fencing_fee = -0.1
}

local cayo_tunable_backup = {
    bag_max_capacity = nil,
    pavel_cut = nil,
    fencing_fee = nil
}

cayo_womans_bag_enabled = false
cayo_remove_crew_cuts_enabled = false

cayoWomansBagToggle = nil
cayoRemoveCrewCutsToggle = nil

local function hp_tunable_int(name)
    return script.tunables(name).int32
end

local function hp_tunable_float(name)
    return script.tunables(name).float
end

local function hp_set_tunable_int(name, value)
    script.tunables(name).int32 = value
end

local function hp_set_tunable_float(name, value)
    script.tunables(name).float = value
end

function cayo_set_womans_bag(enable, silent)
    local enabled = enable and true or false
    local changed = (cayo_womans_bag_enabled ~= enabled)

    if enabled and cayo_tunable_backup.bag_max_capacity == nil then
        cayo_tunable_backup.bag_max_capacity = hp_tunable_int("HEIST_BAG_MAX_CAPACITY")
    end

    if enabled then
        hp_set_tunable_int("HEIST_BAG_MAX_CAPACITY", 99999)
    else
        local restore = cayo_tunable_backup.bag_max_capacity
        if restore == nil then
            restore = CAYO_TUNABLE_DEFAULTS.bag_max_capacity
        end
        hp_set_tunable_int("HEIST_BAG_MAX_CAPACITY", restore)
    end

    cayo_womans_bag_enabled = enabled
    if cayoWomansBagToggle then cayoWomansBagToggle.state = enabled end
    if changed and not silent and notify then
        notify.push("Cayo Perico", enabled and "Woman's Bag Enabled" or "Woman's Bag Disabled", 2000)
    end
end

function cayo_set_remove_crew_cuts(enable, silent)
    local enabled = enable and true or false
    local changed = (cayo_remove_crew_cuts_enabled ~= enabled)

    if enabled then
        if cayo_tunable_backup.pavel_cut == nil then
            cayo_tunable_backup.pavel_cut = hp_tunable_float("IH_DEDUCTION_PAVEL_CUT")
        end
        if cayo_tunable_backup.fencing_fee == nil then
            cayo_tunable_backup.fencing_fee = hp_tunable_float("IH_DEDUCTION_FENCING_FEE")
        end

        hp_set_tunable_float("IH_DEDUCTION_PAVEL_CUT", 0.0)
        hp_set_tunable_float("IH_DEDUCTION_FENCING_FEE", 0.0)
    else
        local restore_pavel = cayo_tunable_backup.pavel_cut
        local restore_fee = cayo_tunable_backup.fencing_fee
        if restore_pavel == nil then restore_pavel = CAYO_TUNABLE_DEFAULTS.pavel_cut end
        if restore_fee == nil then restore_fee = CAYO_TUNABLE_DEFAULTS.fencing_fee end

        hp_set_tunable_float("IH_DEDUCTION_PAVEL_CUT", restore_pavel)
        hp_set_tunable_float("IH_DEDUCTION_FENCING_FEE", restore_fee)
    end

    cayo_remove_crew_cuts_enabled = enabled
    if cayoRemoveCrewCutsToggle then cayoRemoveCrewCutsToggle.state = enabled end
    if changed and not silent and notify then
        notify.push("Cayo Perico", enabled and "Crew Cuts Removed" or "Crew Cuts Restored", 2000)
    end
end

local function cayo_enforce_heist_toggles()
    if cayo_womans_bag_enabled then
        hp_set_tunable_int("HEIST_BAG_MAX_CAPACITY", 99999)
    end
    if cayo_remove_crew_cuts_enabled then
        hp_set_tunable_float("IH_DEDUCTION_PAVEL_CUT", 0.0)
        hp_set_tunable_float("IH_DEDUCTION_FENCING_FEE", 0.0)
    end
end

-- Apply Cayo Preps
local function cayo_apply_preps()
    local p = GetMP()

    if CayoConfig.unlock_all_poi then
        account.stats(p .. "H4CNF_BS_GEN").int32 = -1
        account.stats(p .. "H4CNF_BS_ENTR").int32 = 63
        account.stats(p .. "H4CNF_BS_ABIL").int32 = 63
        account.stats(p .. "H4CNF_APPROACH").int32 = -1
        account.stats(p .. "H4_PLAYTHROUGH_STATUS").int32 = 10
    end

    account.stats(p .. "H4_PROGRESS").int32 = CayoConfig.diff
    account.stats(p .. "H4_MISSIONS").int32 = CayoConfig.app
    account.stats(p .. "H4CNF_WEAPONS").int32 = CayoConfig.wep
    account.stats(p .. "H4CNF_TARGET").int32 = CayoConfig.tgt

    local has_secondary_target = (CayoConfig.sec_comp ~= "NONE") or (CayoConfig.sec_isl ~= "NONE")
    local value_map = {
        CASH = CayoConfig.val_cash,
        WEED = CayoConfig.val_weed,
        COKE = CayoConfig.val_coke,
        GOLD = CayoConfig.val_gold
    }

    local loots = { "CASH", "WEED", "COKE", "GOLD" }
    for _, loot in ipairs(loots) do
        local compound_value = (CayoConfig.sec_comp == loot) and CayoConfig.amt_comp or 0
        local island_value = (CayoConfig.sec_isl == loot) and CayoConfig.amt_isl or 0
        local value_stat = has_secondary_target and value_map[loot] or 0

        account.stats(p .. "H4LOOT_" .. loot .. "_C").int32 = compound_value
        account.stats(p .. "H4LOOT_" .. loot .. "_C_SCOPED").int32 = compound_value
        account.stats(p .. "H4LOOT_" .. loot .. "_I").int32 = island_value
        account.stats(p .. "H4LOOT_" .. loot .. "_I_SCOPED").int32 = island_value
        account.stats(p .. "H4LOOT_" .. loot .. "_V").int32 = value_stat
    end

    account.stats(p .. "H4LOOT_PAINT").int32 = CayoConfig.paint
    account.stats(p .. "H4LOOT_PAINT_SCOPED").int32 = CayoConfig.paint
    account.stats(p .. "H4LOOT_PAINT_V").int32 = (CayoConfig.paint ~= 0) and CayoConfig.val_art or 0
    account.stats(p .. "H4CNF_UNIFORM").int32 = -1
    account.stats(p .. "H4CNF_GRAPPEL").int32 = -1
    account.stats(p .. "H4CNF_TROJAN").int32 = 5
    account.stats(p .. "H4CNF_WEP_DISRP").int32 = 3
    account.stats(p .. "H4CNF_ARM_DISRP").int32 = 3
    account.stats(p .. "H4CNF_HEL_DISRP").int32 = 3
    script.locals("heist_island_planning", 1570).int32 = 2
    if notify then notify.push("Cayo Perico", "Preps Applied (Granular)", 2000) end
end

-- Apply Cayo Cuts
local function hp_get_cayo_max_payout_cut()
    local p = GetMP()
    local target = account.stats(p .. "H4CNF_TARGET").int32 or 0
    local difficulty = (account.stats(p .. "H4_PROGRESS").int32 == 131055) and 2 or 1

    local payouts = {
        [0] = { 630000, 693000 },   -- Tequila
        [1] = { 700000, 770000 },   -- Ruby Necklace
        [2] = { 770000, 847000 },   -- Bearer Bonds
        [3] = { 1300000, 1430000 }, -- Pink Diamond
        [4] = { 1100000, 1210000 }, -- Madrazo Files
        [5] = { 1900000, 2090000 }  -- Panther Statue
    }

    local payout_by_target = payouts[target]
    if not payout_by_target then
        return 100
    end

    local payout = payout_by_target[difficulty] or payout_by_target[1]
    local max_payout = SAFE_PAYOUT_TARGETS.cayo
    local initial_cut = math.floor(max_payout / (payout / 100))
    local cut = initial_cut
    local difference = 1000
    local tries = 0

    while tries < 10000 do
        local final_payout = math.floor(payout * (cut / 100))
        local pavel_fee = math.floor(final_payout * 0.02)
        local fencing_fee = math.floor(final_payout * 0.10)
        local fee_payout = final_payout - (pavel_fee + fencing_fee)

        if fee_payout >= (max_payout - difference) and fee_payout <= max_payout then
            break
        end

        cut = cut + 1
        if cut > 500 then
            cut = initial_cut
            difference = difference + 1000
        end
        tries = tries + 1
    end

    return hp_clamp_cut_percent(cut)
end

local function cayo_apply_cuts()
    script.globals(CayoGlobals.Host).int32 = CayoCutsValues.host
    script.globals(CayoGlobals.P2).int32 = CayoCutsValues.player2
    script.globals(CayoGlobals.P3).int32 = CayoCutsValues.player3
    script.globals(CayoGlobals.P4).int32 = CayoCutsValues.player4
    if notify then notify.push("Cayo Perico", "Cuts Applied", 2000) end
end

-- Force Ready
local function cayo_force_ready()
    util.create_job(function()
        if script and script.force_host then
            script.force_host("fm_mission_controller_2020")
        end
        util.yield(1000)
        
        script.globals(CayoReady.PLAYER2).int32 = 1
        script.globals(CayoReady.PLAYER3).int32 = 1  -- READY_STATE_HEIST = 1
        script.globals(CayoReady.PLAYER4).int32 = 1  -- READY_STATE_HEIST = 1
        
        if notify then notify.push("Cayo Perico", "All players ready", 2000) end
    end)
    return true
end

-- Cayo Tools functions
local function cayo_unlock_all_poi()
    local p = GetMP()
    -- Unlock all POIs (set to -1 to unlock all)
    account.stats(p .. "H4CNF_BS_GEN").int32 = -1
    -- Unlock all entry points
    account.stats(p .. "H4CNF_BS_ENTR").int32 = 63
    -- Unlock all abilities/equipment
    account.stats(p .. "H4CNF_BS_ABIL").int32 = 63
    account.stats(p .. "H4CNF_APPROACH").int32 = -1
    account.stats(p .. "H4_PLAYTHROUGH_STATUS").int32 = 10
    -- Reload planning board if script is running
    if script.running("heist_island_planning") then
        script.locals("heist_island_planning", 1570).int32 = 2
    end
    if notify then notify.push("Cayo Tools", "All POI Unlocked", 2000) end
end

local function cayo_reset_preps()
    local p = GetMP()
    account.stats(p .. "H4_PROGRESS").int32 = 0
    account.stats(p .. "H4_MISSIONS").int32 = 0
    account.stats(p .. "H4CNF_APPROACH").int32 = 0
    account.stats(p .. "H4CNF_TARGET").int32 = -1
    account.stats(p .. "H4CNF_BS_GEN").int32 = 0
    account.stats(p .. "H4CNF_BS_ENTR").int32 = 0
    account.stats(p .. "H4CNF_BS_ABIL").int32 = 0
    account.stats(p .. "H4_PLAYTHROUGH_STATUS").int32 = 0
    script.locals("heist_island_planning", 1570).int32 = 2
    if notify then notify.push("Cayo Tools", "Preps Reset (Full)", 2000) end
end

local function cayo_instant_voltlab_hack()
    if not script.running("fm_content_island_heist") then
        if notify then notify.push("Cayo Tools", "Mission Not Running", 2000) end
        return
    end
    script.locals("fm_content_island_heist", 10166 + 24).int32 = 5
    if notify then notify.push("Cayo Tools", "Voltlab Hack Completed", 2000) end
end

local function cayo_instant_password_hack()
    script.locals("fm_mission_controller_2020", 26486).int32 = 5
    if notify then notify.push("Cayo Tools", "Password Hack Completed", 2000) end
end

local function cayo_bypass_plasma_cutter()
    script.locals("fm_mission_controller_2020", 32589 + 3).float = 100.0
    if notify then notify.push("Cayo Tools", "Plasma Cutter Bypassed", 2000) end
end

local function cayo_bypass_drainage_pipe()
    script.locals("fm_mission_controller_2020", 31349).int32 = 6
    if notify then notify.push("Cayo Tools", "Drainage Pipe Bypassed", 2000) end
end

local function cayo_reload_planning_screen()
    script.locals("heist_island_planning", 1570).int32 = 2
    if notify then notify.push("Cayo Tools", "Planning Screen Reloaded", 2000) end
end

local function cayo_remove_cooldown()
    local p = GetMP()
    account.stats(p .. "H4_TARGET_POSIX").int32 = 1659643454
    account.stats(p .. "H4_COOLDOWN").int32 = 0
    account.stats(p .. "H4_COOLDOWN_HARD").int32 = 0
    if notify then notify.push("Cayo Tools", "Cooldown Removed (Solo)", 2000) end
end

local function cayo_remove_cooldown_team()
    local p = GetMP()
    account.stats(p .. "H4_TARGET_POSIX").int32 = 1659429119
    account.stats(p .. "H4_COOLDOWN").int32 = 0
    account.stats(p .. "H4_COOLDOWN_HARD").int32 = 0
    if notify then notify.push("Cayo Tools", "Cooldown Removed (Team)", 2000) end
end

local function cayo_instant_finish()
    util.create_job(function()
        if script.force_host("fm_mission_controller_2020") then
            util.yield(1000)
            script.locals("fm_mission_controller_2020", 56223).int32 = 9
            script.locals("fm_mission_controller_2020", 58000).int32 = 50
            if notify then notify.push("Cayo Tools", "Cayo Perico instant finish", 2000) end
        else
            if notify then notify.push("Cayo Tools", "Failed to force host", 2000) end
        end
    end)
end

-- Cayo Teleport functions using Lexis API
-- Documentation: https://docs.lexis.re/
local function teleport_to_coords(x, y, z)
    local success = false
    local error_msg = nil
    
    local ok, err = pcall(function()
        local ped = nil
        
        -- Method 1: Try using invoker directly to get player ped (most reliable)
        if invoker and invoker.call then
            local result = invoker.call(0xD80958FC74E988A6) -- PLAYER_PED_ID
            if result and result.int and result.int ~= 0 then
                ped = result.int
            end
        end
        
        -- Method 2: Try using native.player_ped_id() (fallback)
        if not ped then
            local native_ok, native_result = pcall(function()
                local native_api = require("natives")
                if native_api and native_api.player_ped_id then
                    return native_api.player_ped_id()
                end
                return nil
            end)
            
            if native_ok and native_result and native_result ~= 0 then
                ped = native_result
            end
        end
        
        if ped and ped ~= 0 then
            -- Check if player is in a vehicle
            local vehicle = nil
            if invoker and invoker.call then
                -- IS_PED_IN_ANY_VEHICLE native (0x997ABD671D25CA0B)
                local in_vehicle = invoker.call(0x997ABD671D25CA0B, ped, false)
                if in_vehicle and in_vehicle.bool then
                    -- GET_VEHICLE_PED_IS_IN native (0x9A9112A0FE9A4713)
                    local veh_result = invoker.call(0x9A9112A0FE9A4713, ped, false)
                    if veh_result and veh_result.int and veh_result.int ~= 0 then
                        vehicle = veh_result.int
                    end
                end
            end
            
            -- Teleport vehicle first if player is in one
            if vehicle and vehicle ~= 0 then
                -- Request network control of vehicle for better sync with passengers
                if invoker and invoker.call then
                    -- NETWORK_REQUEST_CONTROL_OF_ENTITY (0xB69317BF5E782347)
                    invoker.call(0xB69317BF5E782347, vehicle) -- NETWORK_REQUEST_CONTROL_OF_ENTITY
                    -- Wait for network control (important for sync with passengers)
                    util.yield(150)
                    
                    -- Try multiple times if needed for network sync
                    for _ = 1, 10 do
                        local has_control = invoker.call(0x01BF60A500E28887, vehicle) -- NETWORK_HAS_CONTROL_OF_ENTITY
                        if has_control and has_control.bool then
                            break
                        end
                        invoker.call(0xB69317BF5E782347, vehicle) -- NETWORK_REQUEST_CONTROL_OF_ENTITY
                        util.yield(50)
                    end
                end
                
                -- Get current vehicle heading to preserve it
                local heading_result = nil
                if invoker and invoker.call then
                    heading_result = invoker.call(0xE83D4F9BA2A38914, vehicle) -- GET_ENTITY_HEADING
                end
                local heading = (heading_result and heading_result.float) or 0.0
                
                -- Freeze vehicle during teleport for better sync
                if invoker and invoker.call then
                    invoker.call(0x428CA6DBD1094446, vehicle, true) -- FREEZE_ENTITY_POSITION
                end
                
                -- SET_ENTITY_COORDS for vehicle (better network sync than NO_OFFSET)
                invoker.call(0x06843DA7060A026B, vehicle, x, y, z, false, false, false, true)
                
                -- Restore vehicle heading
                if invoker and invoker.call then
                    invoker.call(0x8E2530AA8ADA980E, vehicle, heading) -- SET_ENTITY_HEADING
                end
                
                -- Longer delay for network sync, especially with passengers
                util.yield(250)
                
                -- Unfreeze vehicle
                if invoker and invoker.call then
                    invoker.call(0x428CA6DBD1094446, vehicle, false) -- FREEZE_ENTITY_POSITION
                end
                
                -- Teleport player (ped) to same location
                if invoker and invoker.call then
                    invoker.call(0x06843DA7060A026B, ped, x, y, z, false, false, false, true)
                    util.yield(150)
                    
                    -- Set player back as driver using TASK_WARP_PED_INTO_VEHICLE
                    -- Parameters: ped, vehicle, seat (-1 = driver seat)
                    invoker.call(0x9A7D091411C5F684, ped, vehicle, -1)
                    -- Additional delay for network sync
                    util.yield(150)
                    success = true
                else
                    error_msg = "Invoker not available"
                end
            else
                -- Teleport player (ped) if not in vehicle
                if invoker and invoker.call then
                    -- Use SET_ENTITY_COORDS native (0x06843DA7060A026B)
                    -- Parameters: entity, x, y, z, xAxis, yAxis, zAxis, clearArea
                    invoker.call(0x06843DA7060A026B, ped, x, y, z, false, false, false, true)
                    success = true
                else
                    error_msg = "Invoker not available"
                end
            end
        else
            error_msg = "Could not get player ped (ped=" .. tostring(ped) .. ")"
        end
    end)
    
    if not ok then
        error_msg = "pcall error: " .. tostring(err)
    end
    
    return success, error_msg
end

-- Teleport cooldown to prevent spam
local teleport_cooldown_tick = 0
local teleport_in_progress = false

local function try_begin_teleport_cooldown()
    local current_tick = util.get_tick_count()
    if current_tick < teleport_cooldown_tick then
        return false
    end
    teleport_cooldown_tick = current_tick + 1000
    return true
end

local function run_coords_teleport(title, success_message, x, y, z, include_error_details, on_success)
    if not try_begin_teleport_cooldown() then
        return false
    end

    util.create_job(function()
        local success, error_msg = teleport_to_coords(x, y, z)
        if success then
            if on_success then
                on_success()
            end
            if notify then notify.push(title, success_message, 2000) end
            return
        end

        local msg = "Failed to teleport"
        if include_error_details and error_msg then
            msg = msg .. ": " .. error_msg
        end
        if notify then
            notify.push(title, msg, include_error_details and 3000 or 2000)
        end
    end)
    return true
end

local function cayo_teleport_residence()
    -- Residence/Mansion coordinates (Cayo Perico)
    -- Coordinates: 5010, -5753, 30
    run_coords_teleport("Cayo Teleport", "Teleported to Residence", 5010.0, -5753.0, 30.0)
end

local function cayo_teleport_main_target()
    -- Main target location (inside compound vault, Cayo Perico)
    -- Coordinates: 5006, -5754, 16
    run_coords_teleport("Cayo Teleport", "Teleported to Main Target", 5006.0, -5754.0, 16.0)
end

local function cayo_teleport_gate()
    -- Gate entrance coordinates (Cayo Perico compound main gate)
    -- Coordinates: 4992, -5720, 21
    run_coords_teleport("Cayo Teleport", "Teleported to Gate", 4992.0, -5720.0, 21.0)
end

local function cayo_teleport_center()
    -- Center coordinates (Cayo Perico)
    -- Coordinates: 4971, -5136, 4
    run_coords_teleport("Cayo Teleport", "Teleported to Center", 4971.0, -5136.0, 4.0)
end

local function cayo_teleport_loot1()
    -- Loot #1 coordinates (Cayo Perico - In Residence)
    -- Coordinates: 5002, -5751, 16
    run_coords_teleport("Cayo Teleport", "Teleported to Loot #1", 5002.0, -5751.0, 16.0)
end

local function cayo_teleport_loot2()
    -- Loot #2 coordinates (Cayo Perico - In Residence)
    -- Coordinates: 5031, -5737, 19
    run_coords_teleport("Cayo Teleport", "Teleported to Loot #2", 5031.0, -5737.0, 19.0)
end

local function cayo_teleport_loot3()
    -- Loot #3 coordinates (Cayo Perico - In Residence)
    -- Coordinates: 5081, -5756, 17
    run_coords_teleport("Cayo Teleport", "Teleported to Loot #3", 5081.0, -5756.0, 17.0)
end

local function cayo_teleport_gate_outside()
    -- Gate coordinates (Cayo Perico - Outside Residence)
    -- Coordinates: 4977, -5706, 20
    run_coords_teleport("Cayo Teleport", "Teleported to Gate", 4977.0, -5706.0, 20.0)
end

local function cayo_teleport_airport()
    -- Airport coordinates (Cayo Perico - Outside Residence)
    -- Coordinates: 4443, -4510, 5
    run_coords_teleport("Cayo Teleport", "Teleported to Airport", 4443.0, -4510.0, 5.0)
end

local function cayo_teleport_escape()
    -- Escape coordinates (Cayo Perico - Outside Residence)
    -- Coordinates: 3698, -6133, -5
    run_coords_teleport("Cayo Teleport", "Teleported to Escape", 3698.0, -6133.0, -5.0)
end

local function cayo_teleport_kosatka()
    if teleport_in_progress then
        return false
    end
    if not try_begin_teleport_cooldown() then
        return false
    end

    local MAZE_RELAY = { x = -75.146, y = -818.687, z = 326.175, heading = 357.531 }
    local KOSATKA_INTERIOR = { x = 1561.087, y = 386.610, z = -49.685, heading = 179.884 }
    local BLIP_SPRITE_HEIST = 428
    local LOOP_TIMEOUT_MS = 30000
    local LOOP_STEP_MS = 100
    local MAX_WAIT_ATTEMPTS = math.floor(LOOP_TIMEOUT_MS / LOOP_STEP_MS)
    local KOSATKA_REQUEST_GLOBALS = {
        2733138 + 613, -- EE
        2733002 + 613  -- Legacy
    }

    local function get_local_player_id()
        if players and players.user then
            local id = players.user()
            if type(id) == "number" and id >= 0 then
                return id
            end
        end
        local me = players and players.me and players.me() or nil
        if me and type(me.id) == "number" and me.id >= 0 then
            return me.id
        end
        return 0
    end

    local function player_owns_kosatka()
        local p = GetMP()
        return (account.stats(p .. "IH_SUB_OWNED").int32 or 0) ~= 0
    end

    local function request_kosatka_spawn()
        for i = 1, #KOSATKA_REQUEST_GLOBALS do
            script.globals(KOSATKA_REQUEST_GLOBALS[i]).int32 = 1
        end
    end

    local function is_kosatka_in_ocean()
        local player_id = get_local_player_id()
        local status_ee = script.globals(2658294 + 1 + (player_id * 468) + 325 + 4).int32 or 0
        if (status_ee & (1 << 31)) ~= 0 then
            return true
        end
        local status_legacy = script.globals(2658291 + 1 + (player_id * 468) + 325 + 4).int32 or 0
        return (status_legacy & (1 << 31)) ~= 0
    end

    local function has_heist_blip()
        local result = invoker.call(0xD484BF71050CA1EE, BLIP_SPRITE_HEIST) -- GET_CLOSEST_BLIP_INFO_ID
        return result and result.int and result.int ~= 0
    end

    if not player_owns_kosatka() then
        if notify then notify.push("Cayo Teleport", "You do not own a Kosatka", 2200) end
        return false
    end

    teleport_in_progress = true
    local me = players.me()
    if not me then
        teleport_in_progress = false
        if notify then notify.push("Cayo Teleport", "Player not found", 2000) end
        return false
    end

    local ped = me.ped
    local entity = ped

    local function set_coords(coords)
        invoker.call(0x239A3351AC1DA385, entity, coords.x, coords.y, coords.z, false, false, false) -- SET_ENTITY_COORDS_NO_OFFSET
    end

    local function set_heading(heading)
        invoker.call(0x8E2530AA8ADA980E, entity, heading) -- SET_ENTITY_HEADING
    end

    local function move_to_maze_bank()
        set_coords(MAZE_RELAY)
        set_heading(MAZE_RELAY.heading)
    end

    local ok, err = pcall(function()
        invoker.call(0x428CA6DBD1094446, entity, true) -- FREEZE_ENTITY_POSITION
        move_to_maze_bank()
        util.yield(700)

        local announced_request = false
        local spawned = is_kosatka_in_ocean()
        if not spawned then
            for _ = 1, MAX_WAIT_ATTEMPTS do
                if is_kosatka_in_ocean() then
                    spawned = true
                    break
                end
                request_kosatka_spawn()
                if not announced_request and notify then
                    notify.push("Cayo Teleport", "Requesting Kosatka...", 1200)
                    announced_request = true
                end
                util.yield(LOOP_STEP_MS)
            end
        end

        if not spawned then
            move_to_maze_bank()
            if notify then notify.push("Cayo Teleport", "Kosatka not ready after 30s. Stayed at Maze Bank.", 3000) end
            invoker.call(0x428CA6DBD1094446, entity, false) -- FREEZE_ENTITY_POSITION
            return
        end

        set_coords(KOSATKA_INTERIOR)
        set_heading(KOSATKA_INTERIOR.heading)

        local interior_loaded = false
        for _ = 1, MAX_WAIT_ATTEMPTS do
            if has_heist_blip() then
                interior_loaded = true
                break
            end
            util.yield(LOOP_STEP_MS)
        end

        if interior_loaded then
            if notify then notify.push("Cayo Teleport", "Teleported to Kosatka (Interior)", 2000) end
        else
            move_to_maze_bank()
            if notify then notify.push("Cayo Teleport", "Kosatka interior not ready after 30s. Stayed at Maze Bank.", 3000) end
        end

        invoker.call(0x428CA6DBD1094446, entity, false) -- FREEZE_ENTITY_POSITION
    end)

    teleport_in_progress = false
    if not ok then
        pcall(function()
            invoker.call(0x428CA6DBD1094446, entity, false) -- FREEZE_ENTITY_POSITION
        end)
        if notify then notify.push("Cayo Teleport", "Kosatka teleport failed: " .. tostring(err), 3000) end
        return false
    end

    return true
end
