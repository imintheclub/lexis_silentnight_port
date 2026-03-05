-- ============================================================================
-- "ShillenSilent" 
-- based off of ShillenLua - Modern UI Menu for GTA V (Version: 1.7.1)
-- ============================================================================
-- Attribution (SilentNight upstream)
-- Portions of heist logic/data are adapted from SilentNight by SilentSalo:
--   Source: https://github.com/SilentSalo/SilentNight
--   License: Creative Commons Attribution-NonCommercial 4.0 (CC BY-NC 4.0)
--   License file: https://raw.githubusercontent.com/SilentSalo/SilentNight/refs/heads/main/LICENSE.md
-- This file is modified from upstream content (Lexis port + additional changes).
-- Keep attribution and license notice with redistributions; non-commercial use only.
--[[
High-level
- This fork is now heist-focused, removed original top-level non-heist tabs
    - (INFO, SPAWNER, VEHICLE, OBJECTS)
- UI architecture is simplified
    - no sidebar tab stack
    - full-width heist layout
    - 3-column card placement. 
    - Various button widths and font sizes and such have been changed.
- Cayo/Casino prep control depth expanded to level of SilentNight.

Apartment + Cayo + Casino JSON Preset System
- Added full JSON preset subsystem for all three heists:
  - Name input from keyboard/clipboard.
  - Save, load, remove, refresh, copy preset folder path.
  - Directory model under script path with heist-specific folders.

Preset IO / Validation Changes
- JSON reader made tolerant of both handle.json and raw handle.text decode paths.
- Added preset validation guard before apply:
  - Enforces expected heist id per mode.
  - Enforces supported schema.

Payout Preset Changes
- Added Apply Preset (Max Payout) flows for Casino/Cayo/Doomsday.
- Kept standard 100% preset + Max Payout preset + manual Apply Cuts behavior.
]]




-- INSTRUCTIONS:
-- 1. Press 'T' key to open/close the menu
-- ============================================================================

local ui = {}
local native = require("natives")

local function get_path(path)
    local base = paths.script
    local drive, rest = base:match("^([A-Z]:)(.*)")
    if drive then
        base = drive:lower() .. rest
    end
    return base .. path
end

local SHILLENSILENT_CORE_DIR = get_path("\\ShillenSilent_core")
local SHILLENSILENT_CORE_FONTS_DIR = SHILLENSILENT_CORE_DIR .. "\\fonts"
local SHILLENSILENT_CORE_PRESETS_DIR = SHILLENSILENT_CORE_DIR .. "\\HeistPresets"

local function ensure_core_dirs()
    if not dirs.exists(SHILLENSILENT_CORE_DIR) then
        dirs.create(SHILLENSILENT_CORE_DIR)
    end
    if not dirs.exists(SHILLENSILENT_CORE_FONTS_DIR) then
        dirs.create(SHILLENSILENT_CORE_FONTS_DIR)
    end
end

-- ---------------------------------------------------------
-- 1. Configuration & Assets
-- ---------------------------------------------------------

local BASE_WIDTH = 1920
local BASE_HEIGHT = 1080

local function get_screen_scale()
    local res = game.resolution()
    local scale_x = res.x / BASE_WIDTH
    local scale_y = res.y / BASE_HEIGHT
    return math.min(scale_x, scale_y)
end

local function load_tab_icon(path)
    if not path or path == "" then return nil end
    
    local full_path = path
        
    local status, img = pcall(gui.load_image, full_path)
    if status and img then 
        return img 
    end
    
    if not path:match("^[A-Za-z]:") then
        full_path = get_path(path:match("ui/components/.*") or path)
        status, img = pcall(gui.load_image, full_path)
        if status and img then return img end
    end
    
    return nil
end

local function init_config()
    local scale = get_screen_scale()
    local function s(px)
        return math.max(1, math.floor(px * scale))
    end
    local function tw(units)
        return s(units * 4)
    end

    local menu_width = tw(356)
    local menu_height = tw(150)
    local content_margin = tw(6)
    local column_gap = tw(4)
    local default_content_w = menu_width - (content_margin * 2)
    local fixed_column_w = math.floor((default_content_w - (2 * column_gap)) / 3)
    local min_column_side_pad = tw(6)
    local subtab_count = 5
    local min_subtab_w = tw(18)
    local subtab_gap = tw(2)
    local min_w_from_subtabs = (content_margin * 2) + (subtab_count * min_subtab_w) + ((subtab_count - 1) * subtab_gap)
    local min_w_from_columns = (content_margin * 2) + fixed_column_w + (min_column_side_pad * 2)

        return {
            font_path = SHILLENSILENT_CORE_FONTS_DIR .. "\\InterVariable.ttf",

        -- Typography scale tuned for Inter.
        font_scale_title = 24.0 * scale,
        font_scale_header = 18.0 * scale,
        font_scale_body = 16.0 * scale,
        font_scale_small = 14.0 * scale,

        origin_x = math.floor((game.resolution().x - menu_width) / 2),
        origin_y = math.floor((game.resolution().y - menu_height) / 2),
        menu_width = menu_width,
        menu_height = menu_height,

        sidebar_width = tw(25),
        sidebar_gap = tw(4),
        
        content_margin = content_margin,
        
        layout = {
            fixed_column_w = fixed_column_w,
            column_gap = column_gap,
            max_columns = 3
        },

        resize = {
            edge_hit_w = tw(3),
            edge_hit_h = tw(6),
            min_menu_width = math.max(min_w_from_subtabs, min_w_from_columns),
            max_menu_width = menu_width,
            max_screen_margin = tw(10)
        },
        
        content_area = {
            x = 0, y = 0, w = 0, h = 0
        },

        item_height = {
            toggle = tw(12),
            button = tw(12),
            slider = tw(15),
            dropdown = tw(12),
            header_padding = tw(10)
        },

        space = {
            x1 = tw(1),      -- 4px
            x1_5 = tw(1.5),  -- 6px
            x2 = tw(2),      -- 8px
            x2_5 = tw(2.5),  -- 10px
            x3 = tw(3),      -- 12px
            x3_5 = tw(3.5),  -- 14px
            x4 = tw(4),      -- 16px
            x5 = tw(5),      -- 20px
            x6 = tw(6),      -- 24px
            x7 = tw(7),      -- 28px
            x8 = tw(8),      -- 32px
            x9 = tw(9),      -- 36px
            x10 = tw(10),    -- 40px
            x11 = tw(11),    -- 44px
            x12 = tw(12),    -- 48px
            x15 = tw(15)     -- 60px
        },

        radius = {
            none = 0,
            sm = s(2),
            md = s(4),
            lg = s(6),
            xl = s(8),
            full = s(999)
        },

        control = {
            dropdown_w = tw(45),        -- 180px
            slider_thumb_base = tw(4),  -- 16px
            slider_thumb_grow = tw(2),  -- 8px
            scrollbar_min_thumb = tw(8),
            scrollbar_grab_pad = tw(1),
            toggle_track_border_thickness = s(2),
            toggle_thumb_border_thickness = s(1.25)
        },

        motion = {
            open_y_offset = tw(7.5) -- 30px
        },

        scale = scale,
        enable_particles = false,

        -- Light theme palette: white surfaces with dark primary actions.
        colors = {
            bg_main = { r = 255, g = 255, b = 255, a = 255 },       -- white
            bg_panel = { r = 255, g = 255, b = 255, a = 255 },      -- white
            bg_control = { r = 255, g = 255, b = 255, a = 255 },    -- white
            bg_control_hover = { r = 226, g = 232, b = 240, a = 255 }, -- slate-200
            bg_ghost_hover = { r = 226, g = 232, b = 240, a = 255 }, -- slate-200

            accent = { r = 15, g = 23, b = 42, a = 255 },           -- slate-900
            accent_hover = { r = 2, g = 6, b = 23, a = 255 },       -- slate-950

            text_main = { r = 15, g = 23, b = 42, a = 255 },        -- slate-900
            text_sec = { r = 51, g = 65, b = 85, a = 255 },         -- slate-700
            text_dim = { r = 100, g = 116, b = 139, a = 240 },      -- slate-500
            text_on_accent = { r = 248, g = 250, b = 252, a = 255 }, -- slate-50

            white = { r = 255, g = 255, b = 255, a = 255 },         -- white
            border = { r = 226, g = 232, b = 240, a = 255 },        -- slate-200
            border_strong = { r = 203, g = 213, b = 225, a = 255 }, -- slate-300
            scroll_track = { r = 226, g = 232, b = 240, a = 220 },  -- slate-200
            card_shadow = { r = 2, g = 6, b = 23, a = 0 },          -- disabled to keep cards pure white
            transparent = { r = 255, g = 255, b = 255, a = 0 },

            danger = { r = 220, g = 38, b = 38, a = 255 },          -- red-600
            danger_hover = { r = 185, g = 28, b = 28, a = 255 },    -- red-700
            danger_soft = { r = 254, g = 242, b = 242, a = 255 },   -- red-50
            danger_text = { r = 153, g = 27, b = 27, a = 255 },     -- red-800
            success = { r = 5, g = 150, b = 105, a = 255 },         -- emerald-600
            success_hover = { r = 4, g = 120, b = 87, a = 255 }     -- emerald-700
        }
    }
end

local config = init_config()

-- Heist-only mode: no sidebar tab navigation.
config.sidebar_width = 0
config.sidebar_gap = 0

local body_offset = config.sidebar_gap
config.content_area.x = config.origin_x + config.sidebar_width + config.sidebar_gap
config.content_area.y = config.origin_y + body_offset
config.content_area.w = config.menu_width - config.sidebar_width - config.sidebar_gap
config.content_area.h = config.menu_height - body_offset
config.scrollbar = {
    x = config.origin_x + config.menu_width - config.space.x2,
    y = config.content_area.y + config.content_margin,
    w = config.space.x1,
    h = config.content_area.h - (config.content_margin * 2)
}

-- State
local state = {
    fonts = {},
    logo = nil,
    font_load_attempted = false,
    active_dropdown = nil,
    dropdown_just_opened = false,
    dragging_slider = nil,
    scroll = { y = 0, max_y = 0, is_dragging = false },
    window = {
        x = config.origin_x,
        y = config.origin_y,
        is_dragging = false,
        is_resizing = false,
        drag_offset = { x = 0, y = 0 },
        resize_start = { x = 0, width = config.menu_width }
    },
    animation = { open = false, progress = 0.0, target = 1.0, speed = 0.15 },
    active_tab_y = nil,
    particles = {},
    mouse = { x = 0, y = 0, down = false, clicked = false },
    heist_subtab = 1,  -- 1=Cayo, 2=Casino, 3=Doomsday, 4=Apartment, 5=Cluckin
    solo_launch = {
        casino = false,
        apartment = false,
        doomsday = false
    },
    solo_launch_prev = {
        casino = false,
        apartment = false,
        doomsday = false
    }
}
