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

    return {
        font_path = "/Users/shiv/dev/projects/personal/lexis_silentnight_port/InterVariable.ttf",

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
        
        content_margin = tw(6),
        
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
    window = { x = config.origin_x, y = config.origin_y, is_dragging = false, drag_offset = { x = 0, y = 0 } },
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

-- ---------------------------------------------------------
-- 2. Core Rendering Helpers
-- ---------------------------------------------------------

local function ensure_assets()
    if state.font_load_attempted then return end
    state.font_load_attempted = true
    
    if config.font_path and config.font_path ~= "" then
        local status, font = pcall(gui.load_font, config.font_path, 50.0)
        if status and font then
            state.fonts.regular = font
        end
    end
end

local function vec(x, y) return vec2(x, y) end

local function get_win_offset()
    local anim_y_offset = (1.0 - state.animation.progress) * config.motion.open_y_offset
    return state.window.x - config.origin_x, (state.window.y - config.origin_y) + anim_y_offset
end

local function is_hovered(x, y, w, h)
    if state.animation.progress < 0.9 then return false end
    local ox, oy = get_win_offset()
    return input.is_mouse_within(vec(x + ox, y + oy), vec(w, h))
end

local function is_hovered_content(item_x, item_y, w, h)
    local ox, oy = get_win_offset()

    local cx, cy = config.content_area.x + ox, config.content_area.y + oy
    local cw, ch = config.content_area.w, config.content_area.h
    
    if not input.is_mouse_within(vec(cx, cy), vec(cw, ch)) then return false end
    
    return input.is_mouse_within(vec(item_x + ox, item_y + oy), vec(w, h))
end

local function update_input()
    local m_pos = input.mouse_position()
    local m_click = input.mouse(1)
    state.mouse.x = m_pos.x
    state.mouse.y = m_pos.y
    state.mouse.down = m_click.pressed
    state.mouse.clicked = m_click.just_pressed
    
    if not state.mouse.down then
        state.dragging_slider = nil
        state.window.is_dragging = false
        state.scroll.is_dragging = false
    end
end

local function to_gui_color(c, use_anim)
    if not c then return color(255, 255, 255, 255) end
    local r, g, b, a = c.r or 255, c.g or 255, c.b or 255, c.a or 255
    if use_anim and state.animation then
        a = math.floor(a * state.animation.progress)
    end
    return color(r, g, b, a)
end

local function render_rect(x, y, w, h, col, rounding)
    if state.animation.progress < 0.01 then return end
    local ox, oy = get_win_offset()
    local r = gui.rect(vec(x + ox, y + oy), vec(w, h))
    r:color(to_gui_color(col, true))
    r:filled()
    if rounding then r:rounding(rounding) end
    r:draw()
end

local function render_outline(x, y, w, h, col, thickness, rounding)
    if state.animation.progress < 0.01 then return end
    local ox, oy = get_win_offset()
    local r = gui.rect(vec(x + ox, y + oy), vec(w, h))
    r:color(to_gui_color(col, true))
    r:outline(thickness or 1, to_gui_color(col, true))
    if rounding then r:rounding(rounding) end
    r:draw()
end

local function render_text(str, x, y, size, col, align)
    if not str or state.animation.progress < 0.01 then return end
    local ox, oy = get_win_offset()
    local t = gui.text(tostring(str)):position(vec(x + ox, y + oy)):color(to_gui_color(col, true)):scale(size or 1.0)
    
    if state.fonts.regular then
        t:font(state.fonts.regular)
    end

    if align == "center" and gui.justify then t:justify(gui.justify.center)
    elseif align == "right" and gui.justify then t:justify(gui.justify.right) end
    t:draw()
    return t
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function manage_particles(w, h)
    -- Init
    if #state.particles == 0 then
        for i = 1, 60 do
            table.insert(state.particles, {
                x = math.random(0, w),
                y = math.random(0, h),
                vx = (math.random() - 0.5) * 0.8,
                vy = (math.random() - 0.5) * 0.8,
                size = math.random(1, 3),
                alpha = math.random(20, 100)
            })
        end
    end

    -- Update
    for _, p in ipairs(state.particles) do
        p.x = p.x + p.vx
        p.y = p.y + p.vy
        
        if p.x < 0 then p.x = w end
        if p.x > w then p.x = 0 end
        if p.y < 0 then p.y = h end
        if p.y > h then p.y = 0 end
    end
end

local function draw_particles(x, y, w, h)
    local ox, oy = get_win_offset()
    gui.push_clip(vec(x + ox, y + oy), vec(w, h))
    for _, p in ipairs(state.particles) do
        -- Draw particles relative to menu origin
        local px = config.origin_x + p.x
        local py = config.origin_y + p.y
        
        -- Helper render_rect handles win_offset
        render_rect(px, py, p.size, p.size, {r=config.colors.text_on_accent.r, g=config.colors.text_on_accent.g, b=config.colors.text_on_accent.b, a=p.alpha}, config.radius.sm)
    end
    gui.pop_clip()
end

-- ---------------------------------------------------------
-- 3. UI Structure
-- ---------------------------------------------------------
ui.tabs = {}
ui.currentTab = nil

ui.tab = function(id, label, icon_path, hidden)
    local icon = icon_path and load_tab_icon(icon_path) or nil
    local tab = { id = id, label = label, icon = icon, icon_path = icon_path, groups = {}, hidden = hidden or false }
    table.insert(ui.tabs, tab)
    if #ui.tabs == 1 and not tab.hidden then ui.currentTab = tab end
    return tab
end

ui.group = function(tabRef, label, x, y, w, min_h, heist_subtab)
    local group = { label = label, items = {}, rect = { x = x, y = y, w = w, h = min_h or 100 }, heist_subtab = heist_subtab }
    table.insert(tabRef.groups, group)
    return group
end

ui.toggle = function(groupRef, configKey, label, defaultState, onChange, tooltip)
    local item = { type = "toggle", id = configKey, label = label, state = defaultState, onChange = onChange, tooltip = tooltip, hotkey = nil, anim = defaultState and 1.0 or 0.0 }
    table.insert(groupRef.items, item)
    return item
end

ui.slider = function(groupRef, configKey, label, min, max, defaultVal, onChange, tooltip, step)
    -- Round default value to step if specified
    local initialValue = defaultVal
    if step and step > 0 then
        initialValue = math.floor((defaultVal + step / 2) / step) * step
    end
    local item = { type = "slider", id = configKey, label = label, min = min, max = max, value = initialValue, onChange = onChange, tooltip = tooltip, anim = 0.0, step = step }
    table.insert(groupRef.items, item)
    return item
end

ui.button = function(groupRef, id, label, onClick, tooltip, disabled, color)
    local item = { type = "button", id = id, label = label, onClick = onClick, tooltip = tooltip, disabled = disabled or false, color = color }
    table.insert(groupRef.items, item)
    return item
end

ui.button_pair = function(
    groupRef,
    left_id, left_label, left_onClick,
    right_id, right_label, right_onClick,
    left_tooltip, right_tooltip,
    left_disabled, right_disabled,
    left_color, right_color
)
    local item = {
        type = "button_pair",
        left = {
            id = left_id, label = left_label, onClick = left_onClick,
            tooltip = left_tooltip, disabled = left_disabled or false, color = left_color
        },
        right = {
            id = right_id, label = right_label, onClick = right_onClick,
            tooltip = right_tooltip, disabled = right_disabled or false, color = right_color
        }
    }
    table.insert(groupRef.items, item)
    return item
end

ui.dropdown = function(groupRef, configKey, label, options, defaultIdx, onChange, tooltip)
    local item = { type = "dropdown", id = configKey, label = label, options = options, value = defaultIdx, onChange = onChange, isOpen = false, tooltip = tooltip }
    table.insert(groupRef.items, item)
    return item
end

ui.label = function(groupRef, text, color)
    local item = { type = "label", text = text, color = color }
    table.insert(groupRef.items, item)
    return item
end

local function render_card(x, y, w, h, bg_col, border_col, rounding)
    local r = rounding or config.radius.md
    local shadow_y = config.space.x1
    render_rect(x, y + shadow_y, w, h, config.colors.card_shadow, r)
    render_rect(x, y, w, h, bg_col or config.colors.bg_panel, r)
    render_outline(x, y, w, h, border_col or config.colors.border, 1, r)
end

local function button_variant_for(btn)
    if btn.color == "green" then return "success" end
    if btn.color == "danger" then return "danger" end
    if btn.color == "ghost" then return "ghost" end
    if btn.color == "primary" then return "primary" end

    local id = string.lower(tostring(btn.id or ""))
    if id == "" then
        return "outline"
    end

    if id:find("preset_copy", 1, true)
        or id:find("preset_refresh", 1, true)
        or id:find("preset_set_name", 1, true)
        or id:find("preset_name_clip", 1, true)
    then
        return "outline"
    end

    if id:find("preset_remove", 1, true) then
        return "ghost_danger"
    end

    if id:find("_tp_", 1, true) or id:find("teleport", 1, true) then
        return "outline"
    end

    if id == "doomsday_preset_apply" then
        return "outline"
    end

    if id:find("cuts_apply", 1, true)
        or id:find("_apply", 1, true)
        or id:find("preset_save", 1, true)
        or id:find("preset_load", 1, true)
    then
        return "primary"
    end

    return "outline"
end

local function is_preset_file_dropdown(item)
    if type(item) ~= "table" then return false end
    if type(item.id) ~= "string" then return false end
    return item.id:find("_preset_file", 1, true) ~= nil
end

local function get_dropdown_item_height(item)
    if is_preset_file_dropdown(item) then
        return config.item_height.dropdown + config.space.x4
    end
    return config.item_height.dropdown
end

local function button_colors_for(btn, hovered)
    local variant = button_variant_for(btn)

    if btn.disabled then
        return {
            bg = hovered and config.colors.danger_hover or config.colors.danger,
            border = hovered and config.colors.danger_hover or config.colors.danger,
            text = config.colors.text_on_accent
        }
    end

    if variant == "primary" then
        return {
            bg = hovered and config.colors.accent_hover or config.colors.accent,
            border = hovered and config.colors.accent_hover or config.colors.accent,
            text = config.colors.text_on_accent
        }
    elseif variant == "success" then
        return {
            bg = hovered and config.colors.success_hover or config.colors.success,
            border = hovered and config.colors.success_hover or config.colors.success,
            text = config.colors.text_on_accent
        }
    elseif variant == "danger" then
        return {
            bg = hovered and config.colors.danger_hover or config.colors.danger,
            border = hovered and config.colors.danger_hover or config.colors.danger,
            text = config.colors.text_on_accent
        }
    elseif variant == "ghost" then
        return {
            bg = hovered and config.colors.bg_ghost_hover or config.colors.transparent,
            border = config.colors.transparent,
            text = config.colors.text_main
        }
    elseif variant == "ghost_danger" then
        return {
            bg = hovered and config.colors.danger_soft or config.colors.transparent,
            border = config.colors.transparent,
            text = config.colors.danger_text
        }
    else
        return {
            bg = hovered and config.colors.bg_control_hover or config.colors.bg_control,
            border = hovered and config.colors.border_strong or config.colors.border,
            text = config.colors.text_main
        }
    end
end

-- ---------------------------------------------------------
-- 4. Rendering Implementations
-- ---------------------------------------------------------

local function get_group_actual_height(group)
    local h = config.item_height.header_padding + config.space.x5
    for _, item in ipairs(group.items) do
        if item.type == "toggle" then h = h + config.item_height.toggle
        elseif item.type == "button" then h = h + config.item_height.button
        elseif item.type == "button_pair" then h = h + config.item_height.button
        elseif item.type == "slider" then h = h + config.item_height.slider
        elseif item.type == "dropdown" then h = h + get_dropdown_item_height(item)
        elseif item.type == "label" then h = h + config.space.x6 end
    end
    return math.max(group.rect.h, h)
end

local function draw_toggle_item(item, x, y, w, original_y)
    local pad_x = config.space.x5
    local hitbox_h = config.item_height.toggle - config.space.x1
    local hovered = is_hovered_content(x, original_y, w, hitbox_h)

    if hovered and state.mouse.clicked and not state.active_dropdown then
        item.state = not item.state
        if item.onChange then item.onChange(item.state) end
        state.window.is_dragging = false  
    end

    -- Animation
    local target = item.state and 1.0 or 0.0
    if not item.anim then item.anim = target end
    item.anim = lerp(item.anim, target, 0.15)

    local switchW = config.space.x12
    local switchH = config.space.x6
    local switchX = x + w - switchW - pad_x
    local switchY = y + config.space.x3

    local inactiveCol = { r = 148, g = 163, b = 184, a = 255 } -- slate-400
    local activeCol = config.colors.accent
    
    local trackR = math.floor(inactiveCol.r + (activeCol.r - inactiveCol.r) * item.anim)
    local trackG = math.floor(inactiveCol.g + (activeCol.g - inactiveCol.g) * item.anim)
    local trackB = math.floor(inactiveCol.b + (activeCol.b - inactiveCol.b) * item.anim)
    
    render_rect(switchX, switchY, switchW, switchH, {r=trackR, g=trackG, b=trackB, a=255}, config.radius.full)
    render_outline(switchX, switchY, switchW, switchH, config.colors.border_strong, config.control.toggle_track_border_thickness, config.radius.full)
    
    local thumbPadding = math.max(1, math.floor(config.space.x1 / 2))
    local thumbSize = math.max(2, switchH - (thumbPadding * 2))
    local minX = switchX + thumbPadding
    local maxX = switchX + switchW - thumbSize - thumbPadding
    local thumbX = lerp(minX, maxX, item.anim)
    local thumbY = switchY + (switchH - thumbSize)/2
    
    render_rect(thumbX, thumbY, thumbSize, thumbSize, config.colors.white, config.radius.full)
    render_outline(thumbX, thumbY, thumbSize, thumbSize, config.colors.accent_hover, config.control.toggle_thumb_border_thickness, config.radius.full)

    -- Center text vertically with switch
    local textY = switchY + (switchH - config.font_scale_body)/2
    render_text(item.label, x + pad_x, textY, config.font_scale_body, config.colors.text_main)
end

local function draw_button_item(item, x, y, w, original_y)
    local pad_x = config.space.x5
    local btnH = config.item_height.button - config.space.x1
    local btnW = w - (pad_x * 2)
    local btnX = x + pad_x
    local btnY = y + config.space.x1

    local hovered = is_hovered_content(btnX, original_y + config.space.x1, btnW, btnH)
    
    if hovered and state.mouse.clicked and not state.active_dropdown then
        if item.disabled then
            -- Show error message for disabled buttons
            if notify then notify.push("Error", "Instant Finish function has been disabled", 3000) end
        elseif item.onClick then
            item.onClick()
        end
        state.window.is_dragging = false  -- Prevent window dragging
    end

    local style = button_colors_for(item, hovered)
    render_rect(btnX, btnY, btnW, btnH, style.bg, config.radius.md)
    if style.border.a and style.border.a > 0 then
        render_outline(btnX, btnY, btnW, btnH, style.border, 1, config.radius.md)
    end
    -- Center text both horizontally and vertically
    local textSize = config.font_scale_small
    local textHeight = textSize * 0.7
    local textY = btnY + (btnH / 2) - (textHeight / 2)
    render_text(item.label, btnX + btnW / 2, textY, textSize, style.text, "center")
end

local function draw_button_pair_item(item, x, y, w, original_y)
    local pad_x = config.space.x5
    local btnH = config.item_height.button - config.space.x1
    local totalW = w - (pad_x * 2)
    local baseX = x + pad_x
    local btnY = y + config.space.x1
    local gap = config.space.x2_5
    local btnW = (totalW - gap) / 2

    local function draw_half(btn, btnX)
        local hovered = is_hovered_content(btnX, original_y + config.space.x1, btnW, btnH)

        if hovered and state.mouse.clicked and not state.active_dropdown then
            if btn.disabled then
                if notify then notify.push("Error", "This action is disabled", 3000) end
            elseif btn.onClick then
                btn.onClick()
            end
            state.window.is_dragging = false
        end

        local style = button_colors_for(btn, hovered)
        render_rect(btnX, btnY, btnW, btnH, style.bg, config.radius.md)
        if style.border.a and style.border.a > 0 then
            render_outline(btnX, btnY, btnW, btnH, style.border, 1, config.radius.md)
        end

        -- Stability-first: fixed smaller font for split buttons (no dynamic measurement).
        local drawSize = config.font_scale_small
        local textStr = tostring(btn.label or "")
        local textHeight = drawSize * 0.7
        local textY = btnY + (btnH / 2) - (textHeight / 2)
        render_text(textStr, btnX + btnW / 2, textY, drawSize, style.text, "center")
    end

    draw_half(item.left, baseX)
    draw_half(item.right, baseX + btnW + gap)
end

local function draw_slider_item(item, x, y, w, original_y)
    local pad_x = config.space.x5
    local barW = w - (pad_x * 2)
    local barH = config.space.x1
    local barX = x + pad_x
    local barY = y + config.space.x8

    local hovered = is_hovered_content(x, original_y, w, config.item_height.slider)
    
    if hovered and state.mouse.clicked and not state.active_dropdown then
        state.dragging_slider = item.id
        state.window.is_dragging = false  -- Prevent window dragging when slider clicked
    end

    if state.dragging_slider == item.id and state.mouse.down then
        local mx = state.mouse.x
        local ox = get_win_offset()
        local relative_mx = mx - ox
        local ratio = math.max(0, math.min(1, (relative_mx - barX) / barW))
        local rawValue = item.min + ratio * (item.max - item.min)
        
        -- Round to step if specified (e.g., 5 for cuts sliders)
        if item.step and item.step > 0 then
            item.value = math.floor((rawValue + item.step / 2) / item.step) * item.step
        else
            item.value = rawValue
        end
        
        if item.onChange then item.onChange(item.value) end
    end
    
    -- Animation
    local target = (state.dragging_slider == item.id) and 1.0 or 0.0
    if not item.anim then item.anim = 0.0 end
    item.anim = lerp(item.anim, target, 0.2)

    render_text(item.label, x + pad_x, y + config.space.x1, config.font_scale_body, config.colors.text_main)
    -- Display integer value (no decimals)
    local displayValue = math.floor(item.value)
    render_text(tostring(displayValue), x + w - pad_x, y + config.space.x1, config.font_scale_body, config.colors.accent, "right")

    render_rect(barX, barY, barW, barH, config.colors.bg_control, config.radius.full)
    
    local fillRatio = (item.value - item.min) / (item.max - item.min)
    if fillRatio > 0 then
        render_rect(barX, barY, barW * fillRatio, barH, config.colors.accent, config.radius.full)
    end
    
    local baseSize = config.control.slider_thumb_base
    local growSize = config.control.slider_thumb_grow
    local thumbSize = math.floor(baseSize + (growSize * item.anim))
    local thumbX = barX + (barW * fillRatio) - thumbSize/2
    local thumbY = barY - thumbSize/2 + barH/2
    
    if item.anim > 0.01 then
        local glowSize = thumbSize + math.floor(config.space.x2 * item.anim)
        local glowX = thumbX - (glowSize - thumbSize)/2
        local glowY = thumbY - (glowSize - thumbSize)/2
        local glowAlpha = math.floor(90 * item.anim)
        render_rect(glowX, glowY, glowSize, glowSize, {r=config.colors.accent.r, g=config.colors.accent.g, b=config.colors.accent.b, a=glowAlpha}, glowSize/2)
    end
    
    -- Main circle
    render_rect(thumbX, thumbY, thumbSize, thumbSize, config.colors.text_on_accent, config.radius.full)
end

local function draw_dropdown_item(item, x, y, w, original_y)
    local pad_x = config.space.x5
    local is_preset_file = is_preset_file_dropdown(item)
    local boxW = is_preset_file and (w - (pad_x * 2)) or config.control.dropdown_w
    local boxH = config.space.x9
    local boxX = is_preset_file and (x + pad_x) or (x + w - boxW - pad_x)
    local boxY = is_preset_file and (y + config.space.x5) or (y + config.space.x1_5)
    
    local hovered = is_hovered_content(boxX, original_y + config.space.x1, boxW, boxH)

    if hovered and state.mouse.clicked then
        state.window.is_dragging = false  -- Prevent window dragging
        if state.active_dropdown == item.id then
            item.isOpen = false
            state.active_dropdown = nil
        elseif not state.active_dropdown then
            item.isOpen = true
            state.active_dropdown = item.id
            state.dropdown_just_opened = true
        end
    end

    render_text(item.label, x + pad_x, y + config.space.x1, config.font_scale_body, config.colors.text_main)
    
    local box_active = hovered or item.isOpen
    local boxBg = box_active and config.colors.accent or config.colors.bg_control
    local boxBorder = box_active and config.colors.accent_hover or config.colors.border
    local boxText = box_active and config.colors.text_on_accent or config.colors.text_sec
    local boxArrow = box_active and config.colors.text_on_accent or config.colors.text_dim
    render_rect(boxX, boxY, boxW, boxH, boxBg, config.radius.md)
    render_outline(boxX, boxY, boxW, boxH, boxBorder, 1, config.radius.md)
    local selected = item.options[item.value] or ""
    if is_preset_file then
        render_text(selected, boxX + config.space.x3, boxY + config.space.x1_5, config.font_scale_body, boxText)
    else
        -- Center the selected option text in normal dropdown boxes
        render_text(selected, boxX + boxW / 2, boxY + config.space.x1_5, config.font_scale_body, boxText, "center")
    end
    
    -- Dropdown Arrow
    render_text("v", boxX + boxW - config.space.x4, boxY + config.space.x1_5, config.font_scale_small, boxArrow)

    if item.isOpen then
        return {
            item = item,
            x = boxX,
            y = boxY + boxH + config.space.x1,
            w = boxW,
            align = is_preset_file and "left" or "center"
        }
    end
end

-- ---------------------------------------------------------
-- 5. Main Render Loop
-- ---------------------------------------------------------

ui.render = function()
    ensure_assets()
    update_input()

    -- Heist-only layout: always keep the Heist tab selected.
    ui.currentTab = ui.tabs[1]

    -- Animation
    local diff = state.animation.target - state.animation.progress
    if math.abs(diff) > 0.001 then
        state.animation.progress = state.animation.progress + diff * state.animation.speed
    else
        state.animation.progress = state.animation.target
    end
    if state.animation.progress < 0.01 and state.animation.target == 0.0 then return end

    local ox, oy = get_win_offset()

    local dynamicBodyH = config.menu_height

    -- Full-width content panel (no sidebar/tab navigation).
    local bodyY = config.origin_y
    local bodyH = dynamicBodyH
    config.content_area.x = config.origin_x
    config.content_area.y = bodyY
    config.content_area.w = config.menu_width
    config.content_area.h = bodyH

    if config.enable_particles then
        manage_particles(config.menu_width, dynamicBodyH)
    end

    -- Window Dragging
    if state.mouse.clicked and not state.active_dropdown and not state.dragging_slider then
        local menuStartY = config.origin_y
        -- Check if hovering entire menu area
        if is_hovered(config.origin_x, menuStartY, config.menu_width, dynamicBodyH) then
            state.window.is_dragging = true
            state.window.drag_offset.x = state.mouse.x - state.window.x
            state.window.drag_offset.y = state.mouse.y - state.window.y
        end
    end
    
    if state.dragging_slider then
        state.window.is_dragging = false
    end
    
    if state.window.is_dragging and state.mouse.down and not state.dragging_slider then
        state.window.x = state.mouse.x - state.window.drag_offset.x
        state.window.y = state.mouse.y - state.window.drag_offset.y
    end

    render_card(config.origin_x, bodyY, config.menu_width, bodyH, config.colors.bg_main, config.colors.border_strong, config.radius.xl)
    if config.enable_particles then
        draw_particles(config.origin_x, bodyY, config.menu_width, bodyH)
    end


    local contentX = config.content_area.x + config.content_margin
    local contentY = config.content_area.y + config.content_margin
    local contentW = config.content_area.w - (config.content_margin * 2)
    local contentH = config.content_area.h - (config.content_margin * 2)
    
    -- Render subtabs for Heist tab (BEFORE clip, so they stay fixed at top)
    local subtab_bar_height = 0
    local groups_start_y = contentY
    if ui.currentTab and ui.currentTab.id == "heist" then
        local subtab_names = {"Cayo", "Casino", "Doomsday", "Apartment", "Cluckin"}
        local subtab_count = #subtab_names
        local subtab_h = config.space.x9
        local subtab_gap = config.space.x2
        local subtab_w = (contentW - (subtab_count - 1) * subtab_gap) / subtab_count
        local subtab_y = contentY
        
        for i, name in ipairs(subtab_names) do
            local subtab_x = contentX + (i - 1) * (subtab_w + subtab_gap)
            local is_active = (state.heist_subtab == i)
            local hovered = is_hovered(subtab_x, subtab_y, subtab_w, subtab_h)
            
            if hovered and state.mouse.clicked and not state.active_dropdown then
                state.heist_subtab = i
                state.scroll.y = 0
                state.window.is_dragging = false
            end
            
            local bg_col = is_active and config.colors.accent or config.colors.bg_control
            if hovered and not is_active then
                bg_col = config.colors.bg_control_hover
            end
            render_rect(subtab_x, subtab_y, subtab_w, subtab_h, bg_col, config.radius.md)
            render_outline(subtab_x, subtab_y, subtab_w, subtab_h, is_active and config.colors.accent_hover or config.colors.border, 1, config.radius.md)
            local text_col = is_active and config.colors.text_on_accent or config.colors.text_main
            render_text(name, subtab_x + subtab_w / 2, subtab_y + subtab_h / 2 - config.space.x2, config.font_scale_body, text_col, "center")
        end
        
        subtab_bar_height = subtab_h + config.space.x2
        groups_start_y = contentY + subtab_bar_height
    end
    
    -- Push clip for scrollable content area (excluding subtab bar)
    local clip_y = ui.currentTab and ui.currentTab.id == "heist" and groups_start_y or contentY
    local clip_h = contentH - subtab_bar_height
    gui.push_clip(vec(contentX + ox, clip_y + oy), vec(contentW, clip_h))

    local pendingDropdown = nil

    local activeGroups = {}
    if ui.currentTab then
        if ui.currentTab.id == "heist" then
            -- Filter groups based on subtab (1=Cayo, 2=Casino, 3=Doomsday, 4=Apartment)
            for _, group in ipairs(ui.currentTab.groups) do
                local show = false
                if state.heist_subtab == 1 and group.heist_subtab == "cayo" then show = true end
                if state.heist_subtab == 2 and group.heist_subtab == "casino" then show = true end
                if state.heist_subtab == 3 and group.heist_subtab == "doomsday" then show = true end
                if state.heist_subtab == 4 and group.heist_subtab == "apartment" then show = true end
                if state.heist_subtab == 5 and group.heist_subtab == "cluckin" then show = true end
                if show then
                    table.insert(activeGroups, group)
                end
            end
        else
            activeGroups = ui.currentTab.groups
        end
    end
    
    if #activeGroups > 0 then
        local column_count = 3
        local column_gap = config.space.x4
        local col_w = (contentW - ((column_count - 1) * column_gap)) / column_count
        local col_x = {}
        local base_y = groups_start_y - state.scroll.y

        for col = 1, column_count do
            col_x[col] = contentX + ((col - 1) * (col_w + column_gap))
        end

        local groups_by_column = { {}, {}, {} }
        local custom_layout_used = false

        if ui.currentTab and ui.currentTab.id == "heist" then
            local layout = nil
            if state.heist_subtab == 1 then -- Cayo
                layout = {
                    ["Info"] = { col = 1, order = 1 },
                    ["Presets (JSON)"] = { col = 1, order = 2 },
                    ["Preps"] = { col = 2, order = 1 },
                    ["Cuts"] = { col = 1, order = 3 },
                    ["Tools"] = { col = 3, order = 1 },
                    ["Teleport - Outside Residence"] = { col = 3, order = 2 },
                    ["Teleport - In Residence"] = { col = 3, order = 3 },
                    ["DANGER"] = { col = 3, order = 4 }
                }
            elseif state.heist_subtab == 2 then -- Casino
                layout = {
                    ["Info"] = { col = 1, order = 1 },
                    ["Presets (JSON)"] = { col = 1, order = 2 },
                    ["Preps"] = { col = 2, order = 1 },
                    ["Launch"] = { col = 2, order = 2 },
                    ["Cuts"] = { col = 2, order = 3 },
                    ["Tools"] = { col = 3, order = 1 },
                    ["Teleport - Outside Casino"] = { col = 3, order = 2 },
                    ["Teleport - In Casino"] = { col = 3, order = 3 },
                    ["DANGER"] = { col = 3, order = 4 }
                }
            elseif state.heist_subtab == 3 then -- Doomsday
                layout = {
                    ["Info"] = { col = 1, order = 1 },
                    ["Prep Presets"] = { col = 1, order = 2 },
                    ["Launch"] = { col = 2, order = 1 },
                    ["Cuts"] = { col = 2, order = 2 },
                    ["Tools"] = { col = 3, order = 1 },
                    ["Teleport"] = { col = 3, order = 2 }
                }
            elseif state.heist_subtab == 4 then -- Apartment
                layout = {
                    ["Info"] = { col = 1, order = 1 },
                    ["Presets (JSON)"] = { col = 1, order = 2 },
                    ["Cuts"] = { col = 1, order = 3 },
                    ["Preps"] = { col = 2, order = 1 },
                    ["Launch"] = { col = 2, order = 2 },
                    ["Bonuses"] = { col = 2, order = 3 },
                    ["Tools"] = { col = 3, order = 1 },
                    ["Instant Finish"] = { col = 3, order = 2 },
                    ["Teleport"] = { col = 3, order = 3 },
                    ["DANGER"] = { col = 3, order = 4 }
                }
            end

            if layout then
                custom_layout_used = true
                local fallback_col = 1
                for _, group in ipairs(activeGroups) do
                    local spec = layout[group.label]
                    if spec then
                        table.insert(groups_by_column[spec.col], { group = group, order = spec.order })
                    else
                        table.insert(groups_by_column[fallback_col], { group = group, order = 1000 + #groups_by_column[fallback_col] })
                        fallback_col = (fallback_col % column_count) + 1
                    end
                end

                for col = 1, column_count do
                    table.sort(groups_by_column[col], function(a, b)
                        return a.order < b.order
                    end)
                end
            end
        end

        if not custom_layout_used then
            for i, group in ipairs(activeGroups) do
                local col = ((i - 1) % column_count) + 1
                table.insert(groups_by_column[col], { group = group, order = i })
            end
        end

        local max_col_y = base_y
        for col = 1, column_count do
            local gX = col_x[col]
            local col_y = base_y

            for _, entry in ipairs(groups_by_column[col]) do
                local group = entry.group
                local gY = col_y
                local actual_h = get_group_actual_height(group)

                local available_height = contentH - subtab_bar_height
                local clip_start = groups_start_y
                if (gY + actual_h > clip_start) and (gY < clip_start + available_height) then
                    local pad_x = config.space.x5
                    render_card(gX, gY, col_w, actual_h, config.colors.bg_panel, config.colors.border, config.radius.lg)
                    -- Group Header Label
                    render_text(group.label, gX + pad_x, gY + config.space.x3, config.font_scale_header, config.colors.text_main)
                    local dividerY = gY + config.item_height.header_padding - config.space.x1
                    render_rect(gX + pad_x, dividerY, col_w - (pad_x * 2), config.space.x1, config.colors.border, config.radius.full)

                    local itemY = gY + config.item_height.header_padding + config.space.x3
                    for _, item in ipairs(group.items) do
                        if item.type == "toggle" then
                            draw_toggle_item(item, gX, itemY, col_w, itemY)
                            itemY = itemY + config.item_height.toggle
                        elseif item.type == "button" then
                            draw_button_item(item, gX, itemY, col_w, itemY)
                            itemY = itemY + config.item_height.button
                        elseif item.type == "button_pair" then
                            draw_button_pair_item(item, gX, itemY, col_w, itemY)
                            itemY = itemY + config.item_height.button
                        elseif item.type == "slider" then
                            draw_slider_item(item, gX, itemY, col_w, itemY)
                            itemY = itemY + config.item_height.slider
                        elseif item.type == "dropdown" then
                            local dd = draw_dropdown_item(item, gX, itemY, col_w, itemY)
                            if dd then pendingDropdown = dd end
                            itemY = itemY + get_dropdown_item_height(item)
                        elseif item.type == "label" then
                            local labelCol = item.color or config.colors.text_sec
                            render_text(item.text, gX + pad_x, itemY + config.space.x3, config.font_scale_small, labelCol)
                            itemY = itemY + config.space.x6
                        end
                    end
                end

                col_y = col_y + actual_h + config.space.x4
            end

            if col_y > max_col_y then
                max_col_y = col_y
            end
        end

        local total_h = max_col_y - base_y
        local available_height = contentH - subtab_bar_height
        state.scroll.max_y = math.max(0, total_h - available_height)
    end
    
    gui.pop_clip()

    -- Scrollbar
    if state.scroll.max_y > 0 then
        local sb = config.scrollbar
        local sbH = contentH - subtab_bar_height
        local sbY = groups_start_y
        
        local thumbH = math.max(config.control.scrollbar_min_thumb, (sbH / (sbH + state.scroll.max_y)) * sbH)
        local thumbY = sbY + (state.scroll.y / state.scroll.max_y) * (sbH - thumbH)
        
        render_rect(sb.x, sbY, sb.w, sbH, config.colors.scroll_track, config.radius.full)
        render_rect(sb.x, thumbY, sb.w, thumbH, config.colors.accent, config.radius.full)
        
        if is_hovered(sb.x - config.control.scrollbar_grab_pad, sbY, sb.w + (config.control.scrollbar_grab_pad * 2), sbH) and state.mouse.clicked then
            state.scroll.is_dragging = true
        end
        if state.scroll.is_dragging and state.mouse.down then
            local my = state.mouse.y - oy
            local ratio = math.max(0, math.min(1, (my - sbY) / sbH))
            state.scroll.y = ratio * state.scroll.max_y
        end
    end

    if pendingDropdown then
        local dd = pendingDropdown
        local itemHeight = config.space.x9
        local optsH = #dd.item.options * itemHeight
        render_card(dd.x, dd.y, dd.w, optsH, config.colors.bg_panel, config.colors.border, config.radius.md)
        
        for i, opt in ipairs(dd.item.options) do
            local optY = dd.y + (i-1)*itemHeight
            local optTextCol = config.colors.text_main
            if is_hovered(dd.x, optY, dd.w, itemHeight) then
                render_rect(dd.x, optY, dd.w, itemHeight, config.colors.accent, config.radius.none)
                if state.mouse.clicked and not state.dropdown_just_opened then
                    dd.item.value = i
                    dd.item.isOpen = false
                    state.active_dropdown = nil
                    state.window.is_dragging = false
                    if dd.item.onChange then dd.item.onChange(opt) end
                end
                optTextCol = config.colors.text_on_accent
            end
            if dd.align == "left" then
                render_text(opt, dd.x + config.space.x3, optY + config.space.x1, config.font_scale_body, optTextCol)
            else
                render_text(opt, dd.x + dd.w / 2, optY + config.space.x1, config.font_scale_body, optTextCol, "center")
            end
        end
        
        if state.mouse.clicked and not state.dropdown_just_opened and not is_hovered(dd.x, dd.y, dd.w, optsH) then
            dd.item.isOpen = false
            state.active_dropdown = nil
            state.window.is_dragging = false  
        end
        state.dropdown_just_opened = false
    end
end

-- ---------------------------------------------------------
-- 6. native api
-- ---------------------------------------------------------
local function disable_control_action(...)
    local keys = {...}
    for group = 0, 1 do
        for k, v in pairs(keys) do
            invoker.call(0xFE99B66D079CF6BC, group, v, true)
        end
    end
end

local function heist_skip_cutscene(heist_name)
    local ok = pcall(function()
        invoker.call(0xD220BDD222AC4A1E) -- STOP_CUTSCENE_IMMEDIATELY
    end)

    if notify then
        local title = (heist_name and heist_name ~= "") and (heist_name .. " Tools") or "Heist Tools"
        if ok then
            notify.push(title, "Cutscene skip requested", 2000)
        else
            notify.push(title, "Failed to skip cutscene", 2000)
        end
    end
end

-- ---------------------------------------------------------
-- 6.5. Heist Functions (Casino)
-- ---------------------------------------------------------

-- Globals for Casino Heist
local CasinoGlobals = {
    Host = 1975557,
    P2 = 1975558,
    P3 = 1975559,
    P4 = 1975560,
    ReadyBase = 1977593
}
local MPGlobal = 1574927

-- Cuts values storage
local CutsValues = {
    host = 100,
    player2 = 0,
    player3 = 0,
    player4 = 0
}

-- GetMP function
local function GetMP()
    local mp_idx = script.globals(MPGlobal).int32
    return mp_idx == 1 and "MP1_" or "MP0_"
end

function hp_options_to_names(options)
    local names = {}
    for i = 1, #options do
        names[i] = options[i].name
    end
    return names
end

function hp_option_index_by_value(options, value, default_index)
    for i = 1, #options do
        if options[i].value == value then
            return i
        end
    end
    return default_index or 1
end

function hp_option_value_by_name(options, name, default_value)
    for i = 1, #options do
        if options[i].name == name then
            return options[i].value
        end
    end
    return default_value
end

function hp_option_names_range(options, first, last)
    local names = {}
    for i = first, last do
        if options[i] then
            names[#names + 1] = options[i].name
        end
    end
    return names
end

function hp_set_stat_for_all_characters(stat_name, value)
    account.stats("MP0_" .. stat_name).int32 = value
    account.stats("MP1_" .. stat_name).int32 = value
end

hp_keyboard_guard = nil

hp_heist_presets = {
    root = paths.script .. "\\HeistPresets",
    apartment = {
        dir = "",
        name = "QuickPreset",
        options = { "(empty)" },
        selected = 1,
        dropdown = nil,
        name_label = nil
    },
    cayo = {
        dir = "",
        name = "QuickPreset",
        options = { "(empty)" },
        selected = 1,
        dropdown = nil,
        name_label = nil
    },
    casino = {
        dir = "",
        name = "QuickPreset",
        options = { "(empty)" },
        selected = 1,
        dropdown = nil,
        name_label = nil
    },
    keyboard = { waiting = false, mode = nil }
}

hp_heist_presets.apartment.dir = hp_heist_presets.root .. "\\Apartment"
hp_heist_presets.cayo.dir = hp_heist_presets.root .. "\\CayoPerico"
hp_heist_presets.casino.dir = hp_heist_presets.root .. "\\DiamondCasino"

function hp_trim_text(text)
    if type(text) ~= "string" then
        return ""
    end
    local trimmed = text:gsub("^%s+", ""):gsub("%s+$", "")
    return trimmed
end

function hp_sanitize_preset_name(name)
    local clean = hp_trim_text(name)
    clean = clean:gsub("[<>:\"/\\|%?%*]", "_")
    clean = clean:gsub("%.$", "")
    return clean
end

function hp_get_preset_state(mode)
    if mode == "apartment" then
        return hp_heist_presets.apartment
    end
    if mode == "cayo" then
        return hp_heist_presets.cayo
    end
    if mode == "casino" then
        return hp_heist_presets.casino
    end
    return nil
end

function hp_get_invoker_string(result)
    if not result then
        return ""
    end

    if type(result.str) == "string" and result.str ~= "" then
        return result.str
    end
    if type(result.ptr_string) == "string" and result.ptr_string ~= "" then
        return result.ptr_string
    end
    if type(result.as_str) == "string" and result.as_str ~= "" then
        return result.as_str
    end
    return ""
end

function hp_update_preset_name_label(mode)
    local state_tbl = hp_get_preset_state(mode)
    if not state_tbl or not state_tbl.name_label then
        return
    end
    local shown_name = state_tbl.name
    if shown_name == nil or shown_name == "" then
        shown_name = "(not set)"
    end
    state_tbl.name_label.text = "Name: " .. shown_name
end

function hp_find_option_index(option_names, selected_name, fallback)
    local i
    for i = 1, #option_names do
        if option_names[i] == selected_name then
            return i
        end
    end
    return fallback or 1
end

function hp_resolve_option_value(options, raw_value, fallback_value)
    local numeric = tonumber(raw_value)
    if numeric then
        local int_numeric = math.floor(numeric)
        local zero_based = options[int_numeric + 1]
        if zero_based then
            return zero_based.value
        end
        local one_based = options[int_numeric]
        if one_based then
            return one_based.value
        end
    end

    local i
    for i = 1, #options do
        local option_value = options[i].value
        if option_value == raw_value then
            return option_value
        end
        if numeric and type(option_value) == "number" and option_value == numeric then
            return option_value
        end
    end

    return fallback_value
end

local PRESET_SCHEMA_VERSION = 1
local PRESET_HEIST_MODE_TO_ID = {
    apartment = "apartment",
    cayo = "cayo_perico",
    casino = "diamond_casino"
}

local function hp_validate_heist_preset(mode, preps)
    if type(preps) ~= "table" then
        return false, "Invalid preset JSON"
    end

    local expected_heist = PRESET_HEIST_MODE_TO_ID[mode]
    if expected_heist and preps.heist ~= expected_heist then
        return false, "Preset/heist mismatch"
    end

    local schema = tonumber(preps.schema)
    if schema ~= PRESET_SCHEMA_VERSION then
        return false, "Unsupported preset schema"
    end

    return true, nil
end

function hp_get_zero_based_option_index(options, value, default_index)
    local idx = hp_option_index_by_value(options, value, default_index or 1)
    return idx - 1
end

function hp_clamp_number(value, min_value, max_value)
    local number = tonumber(value)
    if not number then
        return min_value
    end
    if number < min_value then
        return min_value
    end
    if number > max_value then
        return max_value
    end
    return number
end

local function hp_clamp_cut_percent(value)
    return math.floor(hp_clamp_number(value, 0, 300))
end

local function hp_clamp_apartment_cut_percent(value)
    return math.floor(hp_clamp_number(value, 0, 300))
end

local function hp_set_uniform_cuts(state_tbl, keys, sliders, cut, apply_fn)
    local value = hp_clamp_cut_percent(cut)

    for i = 1, 4 do
        local key = keys[i]
        if key then
            state_tbl[key] = value
        end

        local slider = sliders[i]
        if slider then
            slider.value = value
        end
    end

    if apply_fn then
        apply_fn()
    end

    return value
end

local SAFE_PAYOUT_TARGETS = {
    apartment = 3000000,
    cayo = 2500000,
    casino = 3550000,
    doomsday = 2500000
}

local APARTMENT_HEIST_IDS = {
    fleeca = "hK5OgJk1BkinXGGXghhTMg",
    prison_break = "7-w96-PU4kSevhtG5YwUHQ",
    humane_labs = "BWsCWtmnvEWXBrprK9hDHA",
    series_a = "20Lu41Px20OJMPdZ6wXG3g",
    pacific_standard = "zCxFg29teE2ReKGnr0L4Bg"
}

local APARTMENT_HEIST_IDS_BY_INDEX = {
    [1] = APARTMENT_HEIST_IDS.fleeca,
    [2] = APARTMENT_HEIST_IDS.prison_break,
    [3] = APARTMENT_HEIST_IDS.humane_labs,
    [4] = APARTMENT_HEIST_IDS.series_a,
    [5] = APARTMENT_HEIST_IDS.pacific_standard
}

local APARTMENT_PAYOUTS = {
    [APARTMENT_HEIST_IDS.fleeca] = { 100625, 201250, 251563 },
    [APARTMENT_HEIST_IDS.prison_break] = { 350000, 700000, 875000 },
    [APARTMENT_HEIST_IDS.humane_labs] = { 472500, 945000, 1181250 },
    [APARTMENT_HEIST_IDS.series_a] = { 353500, 707000, 883750 },
    [APARTMENT_HEIST_IDS.pacific_standard] = { 750000, 1500000, 1875000 }
}

local APARTMENT_CUT_PRESET_OPTIONS = {
    { name = "All - 0%", value = 0 },
    { name = "All - 25%", value = 25 },
    { name = "All - 85%", value = 85 },
    { name = "All - 100%", value = 100 }
}

function hp_extract_preset_name(file_entry)
    local name = tostring(file_entry or "")
    name = name:gsub("/", "\\")
    name = name:match("([^\\]+)$") or name
    name = name:gsub("%.json$", "")
    return name
end

function hp_ensure_heist_preset_dirs()
    if not dirs.exists(hp_heist_presets.root) then
        dirs.create(hp_heist_presets.root)
    end
    if not dirs.exists(hp_heist_presets.apartment.dir) then
        dirs.create(hp_heist_presets.apartment.dir)
    end
    if not dirs.exists(hp_heist_presets.cayo.dir) then
        dirs.create(hp_heist_presets.cayo.dir)
    end
    if not dirs.exists(hp_heist_presets.casino.dir) then
        dirs.create(hp_heist_presets.casino.dir)
    end
end

function hp_refresh_heist_preset_files(mode, preferred_name)
    local state_tbl = hp_get_preset_state(mode)
    if not state_tbl then
        return
    end

    hp_ensure_heist_preset_dirs()
    local files = dirs.list(state_tbl.dir, ".json") or {}
    local names = {}
    local previous = preferred_name
    local i

    if not previous and state_tbl.options[state_tbl.selected] ~= "(empty)" then
        previous = state_tbl.options[state_tbl.selected]
    end

    for i = 1, #files do
        local extracted = hp_extract_preset_name(files[i])
        if extracted ~= "" then
            names[#names + 1] = extracted
        end
    end

    table.sort(names, function(a, b)
        return string.lower(a) < string.lower(b)
    end)

    if #names == 0 then
        names[1] = "(empty)"
    end

    state_tbl.options = names
    state_tbl.selected = hp_find_option_index(names, previous, 1)

    if state_tbl.dropdown then
        state_tbl.dropdown.options = names
        state_tbl.dropdown.value = state_tbl.selected
    end
end

function hp_get_selected_preset_name(mode)
    local state_tbl = hp_get_preset_state(mode)
    if not state_tbl then
        return nil
    end
    local selected = state_tbl.options[state_tbl.selected]
    if not selected or selected == "" or selected == "(empty)" then
        return nil
    end
    return selected
end

function hp_get_heist_preset_path(mode, preset_name)
    local state_tbl = hp_get_preset_state(mode)
    if not state_tbl then
        return nil
    end
    return state_tbl.dir .. "\\" .. preset_name .. ".json"
end

function hp_open_heist_preset_name_keyboard(mode)
    local state_tbl = hp_get_preset_state(mode)
    if not state_tbl then
        return
    end

    if hp_keyboard_guard then
        if notify then notify.push("Heist Presets", "Keyboard already in use", 2000) end
        return
    end

    hp_keyboard_guard = "heist_presets"
    hp_heist_presets.keyboard.waiting = true
    hp_heist_presets.keyboard.mode = mode

    local default_name = state_tbl.name
    if default_name == nil then
        default_name = ""
    end

    native.display_onscreen_keyboard(6, "FMMC_KEY_TIP8", "", default_name, "", "", "", 64)
    if notify then notify.push("Heist Presets", "Enter preset name...", 2200) end
end

util.create_thread(function()
    while true do
        util.yield(100)

        if hp_heist_presets.keyboard.waiting then
            local status = native.update_onscreen_keyboard()
            if status == 1 then
                local result = invoker.call(0x8362B09B91893647)
                local raw_name = hp_get_invoker_string(result)
                local mode = hp_heist_presets.keyboard.mode
                local state_tbl = hp_get_preset_state(mode)

                local clean_name = hp_sanitize_preset_name(raw_name)
                if state_tbl then
                    if clean_name ~= "" then
                        state_tbl.name = clean_name
                        hp_update_preset_name_label(mode)
                        if notify then notify.push("Heist Presets", "Name set: " .. clean_name, 2000) end
                    else
                        if notify then notify.push("Heist Presets", "Preset name cannot be empty", 2000) end
                    end
                end

                hp_heist_presets.keyboard.waiting = false
                hp_heist_presets.keyboard.mode = nil
                hp_keyboard_guard = nil
            elseif status == 2 then
                hp_heist_presets.keyboard.waiting = false
                hp_heist_presets.keyboard.mode = nil
                hp_keyboard_guard = nil
                if notify then notify.push("Heist Presets", "Name entry canceled", 1500) end
            end
        end
    end
end)

function hp_read_json_file(path)
    local ok, result = pcall(function()
        local handle = file.open(path, { append = false, create_if_not_exists = false })
        if not handle or not handle.valid then
            return nil
        end

        if handle.json ~= nil then
            local ok_decode, decoded = pcall(json.decode, handle.json)
            if ok_decode and type(decoded) == "table" then
                return decoded
            end

            if type(handle.json) == "table" then
                return handle.json
            end
        end

        if handle.text and handle.text ~= "" then
            local ok_decode_text, decoded_text = pcall(json.decode, handle.text)
            if ok_decode_text and type(decoded_text) == "table" then
                return decoded_text
            end
        end
        return nil
    end)

    if not ok then
        return nil
    end
    return result
end

function hp_write_json_file(path, content)
    local ok, err = pcall(function()
        local handle = file.open(path, { create_if_not_exists = true })
        if not handle or not handle.valid then
            error("Invalid file handle")
        end
        handle.json = json.encode(content)
    end)
    return ok, err
end

function hp_collect_cayo_preset_data()
    local preps = {
        schema = PRESET_SCHEMA_VERSION,
        heist = "cayo_perico",
        difficulty = hp_get_zero_based_option_index(CayoPrepOptions.difficulties, CayoConfig.diff, 1),
        approach = hp_get_zero_based_option_index(CayoPrepOptions.approaches, CayoConfig.app, 1),
        loadout = hp_get_zero_based_option_index(CayoPrepOptions.loadouts, CayoConfig.wep, 1),
        primary_target = hp_get_zero_based_option_index(CayoPrepOptions.primary_targets, CayoConfig.tgt, 1),
        compound_target = hp_get_zero_based_option_index(CayoPrepOptions.secondary_targets, CayoConfig.sec_comp, 1),
        compound_amount = hp_get_zero_based_option_index(CayoPrepOptions.compound_amounts, CayoConfig.amt_comp, 1),
        arts_amount = hp_get_zero_based_option_index(CayoPrepOptions.arts_amounts, CayoConfig.paint, 1),
        island_target = hp_get_zero_based_option_index(CayoPrepOptions.secondary_targets, CayoConfig.sec_isl, 1),
        island_amount = hp_get_zero_based_option_index(CayoPrepOptions.island_amounts, CayoConfig.amt_isl, 1),
        advanced = CayoConfig.advanced and true or false,
        cash_value = CayoConfig.val_cash,
        weed_value = CayoConfig.val_weed,
        coke_value = CayoConfig.val_coke,
        gold_value = CayoConfig.val_gold,
        arts_value = CayoConfig.val_art,
        womans_bag = cayo_womans_bag_enabled and true or false,
        remove_crew_cuts = cayo_remove_crew_cuts_enabled and true or false,
        unlock_all_poi = CayoConfig.unlock_all_poi and true or false,
        player1 = { enabled = true, cut = CayoCutsValues.host },
        player2 = { enabled = (CayoCutsValues.player2 > 0), cut = CayoCutsValues.player2 },
        player3 = { enabled = (CayoCutsValues.player3 > 0), cut = CayoCutsValues.player3 },
        player4 = { enabled = (CayoCutsValues.player4 > 0), cut = CayoCutsValues.player4 }
    }
    return preps
end

function hp_apply_cayo_preset_data(preps)
    if type(preps) ~= "table" then
        return false
    end

    CayoConfig.diff = hp_resolve_option_value(CayoPrepOptions.difficulties, preps.difficulty, CayoConfig.diff)
    CayoConfig.app = hp_resolve_option_value(CayoPrepOptions.approaches, preps.approach, CayoConfig.app)
    CayoConfig.wep = hp_resolve_option_value(CayoPrepOptions.loadouts, preps.loadout, CayoConfig.wep)
    CayoConfig.tgt = hp_resolve_option_value(CayoPrepOptions.primary_targets, preps.primary_target, CayoConfig.tgt)
    CayoConfig.sec_comp = hp_resolve_option_value(CayoPrepOptions.secondary_targets, preps.compound_target, CayoConfig.sec_comp)
    CayoConfig.amt_comp = hp_resolve_option_value(CayoPrepOptions.compound_amounts, preps.compound_amount, CayoConfig.amt_comp)
    CayoConfig.paint = hp_resolve_option_value(CayoPrepOptions.arts_amounts, preps.arts_amount, CayoConfig.paint)
    CayoConfig.sec_isl = hp_resolve_option_value(CayoPrepOptions.secondary_targets, preps.island_target, CayoConfig.sec_isl)
    CayoConfig.amt_isl = hp_resolve_option_value(CayoPrepOptions.island_amounts, preps.island_amount, CayoConfig.amt_isl)

    if type(preps.advanced) == "boolean" then
        CayoConfig.advanced = preps.advanced
    end
    if type(preps.unlock_all_poi) == "boolean" then
        CayoConfig.unlock_all_poi = preps.unlock_all_poi
    end
    if type(preps.womans_bag) == "boolean" then
        cayo_set_womans_bag(preps.womans_bag, true)
    end
    if type(preps.remove_crew_cuts) == "boolean" then
        cayo_set_remove_crew_cuts(preps.remove_crew_cuts, true)
    end

    if tonumber(preps.cash_value) then CayoConfig.val_cash = math.floor(tonumber(preps.cash_value)) end
    if tonumber(preps.weed_value) then CayoConfig.val_weed = math.floor(tonumber(preps.weed_value)) end
    if tonumber(preps.coke_value) then CayoConfig.val_coke = math.floor(tonumber(preps.coke_value)) end
    if tonumber(preps.gold_value) then CayoConfig.val_gold = math.floor(tonumber(preps.gold_value)) end
    if tonumber(preps.arts_value) then CayoConfig.val_art = math.floor(tonumber(preps.arts_value)) end

    if type(preps.player1) == "table" and tonumber(preps.player1.cut) then
        CayoCutsValues.host = math.floor(tonumber(preps.player1.cut))
    elseif tonumber(preps.host_cut) then
        CayoCutsValues.host = math.floor(tonumber(preps.host_cut))
    end

    if type(preps.player2) == "table" and tonumber(preps.player2.cut) then
        CayoCutsValues.player2 = math.floor(tonumber(preps.player2.cut))
    elseif tonumber(preps.player2_cut) then
        CayoCutsValues.player2 = math.floor(tonumber(preps.player2_cut))
    end

    if type(preps.player3) == "table" and tonumber(preps.player3.cut) then
        CayoCutsValues.player3 = math.floor(tonumber(preps.player3.cut))
    elseif tonumber(preps.player3_cut) then
        CayoCutsValues.player3 = math.floor(tonumber(preps.player3_cut))
    end

    if type(preps.player4) == "table" and tonumber(preps.player4.cut) then
        CayoCutsValues.player4 = math.floor(tonumber(preps.player4.cut))
    elseif tonumber(preps.player4_cut) then
        CayoCutsValues.player4 = math.floor(tonumber(preps.player4_cut))
    end

    if cayoUnlockOnApplyToggle then cayoUnlockOnApplyToggle.state = CayoConfig.unlock_all_poi end
    if cayoDifficultyDropdown then cayoDifficultyDropdown.value = hp_option_index_by_value(CayoPrepOptions.difficulties, CayoConfig.diff, 1) end
    if cayoApproachDropdown then cayoApproachDropdown.value = hp_option_index_by_value(CayoPrepOptions.approaches, CayoConfig.app, 1) end
    if cayoLoadoutDropdown then cayoLoadoutDropdown.value = hp_option_index_by_value(CayoPrepOptions.loadouts, CayoConfig.wep, 1) end
    if cayoPrimaryTargetDropdown then cayoPrimaryTargetDropdown.value = hp_option_index_by_value(CayoPrepOptions.primary_targets, CayoConfig.tgt, 1) end
    if cayoCompoundTargetDropdown then cayoCompoundTargetDropdown.value = hp_option_index_by_value(CayoPrepOptions.secondary_targets, CayoConfig.sec_comp, 1) end
    if cayoCompoundAmountDropdown then cayoCompoundAmountDropdown.value = hp_option_index_by_value(CayoPrepOptions.compound_amounts, CayoConfig.amt_comp, 1) end
    if cayoArtsAmountDropdown then cayoArtsAmountDropdown.value = hp_option_index_by_value(CayoPrepOptions.arts_amounts, CayoConfig.paint, 1) end
    if cayoIslandTargetDropdown then cayoIslandTargetDropdown.value = hp_option_index_by_value(CayoPrepOptions.secondary_targets, CayoConfig.sec_isl, 1) end
    if cayoIslandAmountDropdown then cayoIslandAmountDropdown.value = hp_option_index_by_value(CayoPrepOptions.island_amounts, CayoConfig.amt_isl, 1) end
    if cayoAdvancedToggle then cayoAdvancedToggle.state = CayoConfig.advanced end
    if cayoCashValueSlider then cayoCashValueSlider.value = CayoConfig.val_cash end
    if cayoWeedValueSlider then cayoWeedValueSlider.value = CayoConfig.val_weed end
    if cayoCokeValueSlider then cayoCokeValueSlider.value = CayoConfig.val_coke end
    if cayoGoldValueSlider then cayoGoldValueSlider.value = CayoConfig.val_gold end
    if cayoArtValueSlider then cayoArtValueSlider.value = CayoConfig.val_art end
    if cayoWomansBagToggle then cayoWomansBagToggle.state = cayo_womans_bag_enabled end
    if cayoRemoveCrewCutsToggle then cayoRemoveCrewCutsToggle.state = cayo_remove_crew_cuts_enabled end
    if cayoHostSliderRef then cayoHostSliderRef.value = CayoCutsValues.host end
    if cayoP2SliderRef then cayoP2SliderRef.value = CayoCutsValues.player2 end
    if cayoP3SliderRef then cayoP3SliderRef.value = CayoCutsValues.player3 end
    if cayoP4SliderRef then cayoP4SliderRef.value = CayoCutsValues.player4 end

    return true
end

function hp_collect_casino_preset_data()
    local preps = {
        schema = PRESET_SCHEMA_VERSION,
        heist = "diamond_casino",
        difficulty = hp_get_zero_based_option_index(CasinoPrepOptions.difficulties, CasinoManualPreps.difficulty, 1),
        approach = hp_get_zero_based_option_index(CasinoPrepOptions.approaches, CasinoManualPreps.approach, 1),
        gunman = hp_get_zero_based_option_index(CasinoPrepOptions.gunmen, CasinoManualPreps.crew_weapon, 1),
        driver = hp_get_zero_based_option_index(CasinoPrepOptions.drivers, CasinoManualPreps.crew_driver, 1),
        hacker = hp_get_zero_based_option_index(CasinoPrepOptions.hackers, CasinoManualPreps.crew_hacker, 1),
        masks = hp_get_zero_based_option_index(CasinoPrepOptions.masks, CasinoManualPreps.masks, 1),
        guards = hp_get_zero_based_option_index(CasinoPrepOptions.guards, CasinoManualPreps.disrupt_shipments, 1),
        keycards = hp_get_zero_based_option_index(CasinoPrepOptions.keycards, CasinoManualPreps.key_levels, 1),
        target = hp_get_zero_based_option_index(CasinoPrepOptions.targets, CasinoManualPreps.target, 1),
        loadout = CasinoManualPreps.loadout_slot - 1,
        vehicles = CasinoManualPreps.vehicle_slot - 1,
        unlock_all_poi = CasinoManualPreps.unlock_all_poi and true or false,
        solo_launch = state.solo_launch.casino and true or false,
        remove_crew_cuts = casino_remove_crew_cuts_enabled and true or false,
        autograbber = casino_autograbber_enabled and true or false,
        player1 = { enabled = true, cut = CutsValues.host },
        player2 = { enabled = (CutsValues.player2 > 0), cut = CutsValues.player2 },
        player3 = { enabled = (CutsValues.player3 > 0), cut = CutsValues.player3 },
        player4 = { enabled = (CutsValues.player4 > 0), cut = CutsValues.player4 }
    }
    return preps
end

function hp_apply_casino_preset_data(preps)
    if type(preps) ~= "table" then
        return false
    end

    CasinoManualPreps.difficulty = hp_resolve_option_value(CasinoPrepOptions.difficulties, preps.difficulty, CasinoManualPreps.difficulty)
    CasinoManualPreps.approach = hp_resolve_option_value(CasinoPrepOptions.approaches, preps.approach, CasinoManualPreps.approach)
    CasinoManualPreps.crew_weapon = hp_resolve_option_value(CasinoPrepOptions.gunmen, preps.gunman, CasinoManualPreps.crew_weapon)
    CasinoManualPreps.crew_driver = hp_resolve_option_value(CasinoPrepOptions.drivers, preps.driver, CasinoManualPreps.crew_driver)
    CasinoManualPreps.crew_hacker = hp_resolve_option_value(CasinoPrepOptions.hackers, preps.hacker, CasinoManualPreps.crew_hacker)
    CasinoManualPreps.masks = hp_resolve_option_value(CasinoPrepOptions.masks, preps.masks, CasinoManualPreps.masks)
    CasinoManualPreps.disrupt_shipments = hp_resolve_option_value(CasinoPrepOptions.guards, preps.guards, CasinoManualPreps.disrupt_shipments)
    CasinoManualPreps.key_levels = hp_resolve_option_value(CasinoPrepOptions.keycards, preps.keycards, CasinoManualPreps.key_levels)
    CasinoManualPreps.target = hp_resolve_option_value(CasinoPrepOptions.targets, preps.target, CasinoManualPreps.target)

    local loadout_slot = tonumber(preps.loadout)
    local vehicle_slot = tonumber(preps.vehicles)
    if loadout_slot then
        CasinoManualPreps.loadout_slot = math.floor(loadout_slot) + 1
    end
    if vehicle_slot then
        CasinoManualPreps.vehicle_slot = math.floor(vehicle_slot) + 1
    end

    if type(preps.unlock_all_poi) == "boolean" then
        CasinoManualPreps.unlock_all_poi = preps.unlock_all_poi
    end
    if type(preps.solo_launch) == "boolean" then
        state.solo_launch.casino = preps.solo_launch
    end
    if type(preps.remove_crew_cuts) == "boolean" then
        casino_set_remove_crew_cuts(preps.remove_crew_cuts, true)
    end
    if type(preps.autograbber) == "boolean" then
        casino_set_autograbber(preps.autograbber, true)
    end

    if type(preps.player1) == "table" and tonumber(preps.player1.cut) then
        CutsValues.host = math.floor(tonumber(preps.player1.cut))
    elseif tonumber(preps.host_cut) then
        CutsValues.host = math.floor(tonumber(preps.host_cut))
    end
    if type(preps.player2) == "table" and tonumber(preps.player2.cut) then
        CutsValues.player2 = math.floor(tonumber(preps.player2.cut))
    elseif tonumber(preps.player2_cut) then
        CutsValues.player2 = math.floor(tonumber(preps.player2_cut))
    end
    if type(preps.player3) == "table" and tonumber(preps.player3.cut) then
        CutsValues.player3 = math.floor(tonumber(preps.player3.cut))
    elseif tonumber(preps.player3_cut) then
        CutsValues.player3 = math.floor(tonumber(preps.player3_cut))
    end
    if type(preps.player4) == "table" and tonumber(preps.player4.cut) then
        CutsValues.player4 = math.floor(tonumber(preps.player4.cut))
    elseif tonumber(preps.player4_cut) then
        CutsValues.player4 = math.floor(tonumber(preps.player4_cut))
    end

    if manualDifficultyDropdown then
        manualDifficultyDropdown.value = hp_option_index_by_value(CasinoPrepOptions.difficulties, CasinoManualPreps.difficulty, 1)
    end
    if manualApproachDropdown then
        manualApproachDropdown.value = hp_option_index_by_value(CasinoPrepOptions.approaches, CasinoManualPreps.approach, 1)
    end
    if manualGunmanDropdown then
        manualGunmanDropdown.value = hp_option_index_by_value(CasinoPrepOptions.gunmen, CasinoManualPreps.crew_weapon, 1)
    end
    if manualDriverDropdown then
        manualDriverDropdown.value = hp_option_index_by_value(CasinoPrepOptions.drivers, CasinoManualPreps.crew_driver, 1)
    end
    if manualHackerDropdown then
        manualHackerDropdown.value = hp_option_index_by_value(CasinoPrepOptions.hackers, CasinoManualPreps.crew_hacker, 1)
    end
    if manualMasksDropdown then
        manualMasksDropdown.value = hp_option_index_by_value(CasinoPrepOptions.masks, CasinoManualPreps.masks, 1)
    end
    if manualGuardsDropdown then
        manualGuardsDropdown.value = hp_option_index_by_value(CasinoPrepOptions.guards, CasinoManualPreps.disrupt_shipments, 1)
    end
    if manualKeycardsDropdown then
        manualKeycardsDropdown.value = hp_option_index_by_value(CasinoPrepOptions.keycards, CasinoManualPreps.key_levels, 1)
    end
    if manualTargetDropdown then
        manualTargetDropdown.value = hp_option_index_by_value(CasinoPrepOptions.targets, CasinoManualPreps.target, 1)
    end
    if manualUnlockPoiToggle then
        manualUnlockPoiToggle.state = CasinoManualPreps.unlock_all_poi
    end
    if casinoSoloLaunchToggle then
        casinoSoloLaunchToggle.state = state.solo_launch.casino
    end
    if casinoRemoveCrewCutsToggle then
        casinoRemoveCrewCutsToggle.state = casino_remove_crew_cuts_enabled
    end
    if casinoAutograbberToggle then
        casinoAutograbberToggle.state = casino_autograbber_enabled
    end

    if manualLoadoutDropdown and manualVehiclesDropdown then
        hp_update_casino_loadout_dropdown(false)
        hp_update_casino_vehicle_dropdown(false)
        CasinoManualPreps.loadout_slot = hp_clamp_number(CasinoManualPreps.loadout_slot, 1, math.max(1, #manualLoadoutDropdown.options))
        CasinoManualPreps.vehicle_slot = hp_clamp_number(CasinoManualPreps.vehicle_slot, 1, math.max(1, #manualVehiclesDropdown.options))
        manualLoadoutDropdown.value = CasinoManualPreps.loadout_slot
        manualVehiclesDropdown.value = CasinoManualPreps.vehicle_slot
    end

    if casinoHostSliderRef then casinoHostSliderRef.value = CutsValues.host end
    if casinoP2SliderRef then casinoP2SliderRef.value = CutsValues.player2 end
    if casinoP3SliderRef then casinoP3SliderRef.value = CutsValues.player3 end
    if casinoP4SliderRef then casinoP4SliderRef.value = CutsValues.player4 end

    return true
end

function hp_collect_apartment_preset_data()
    local cuts = ApartmentCutsValues or {}
    local preps = {
        schema = PRESET_SCHEMA_VERSION,
        heist = "apartment",
        solo_launch = state.solo_launch.apartment and true or false,
        bonus_12mil = apartment_bonus_enabled and true or false,
        double_rewards_week = apartment_double_rewards_week and true or false,
        max_payout = apartment_max_payout_enabled and true or false,
        preset = math.max(0, (apartment_cut_preset_index or 1) - 1),
        player1 = { enabled = true, cut = cuts.player1 or 0 },
        player2 = { enabled = ((cuts.player2 or 0) > 0), cut = cuts.player2 or 0 },
        player3 = { enabled = ((cuts.player3 or 0) > 0), cut = cuts.player3 or 0 },
        player4 = { enabled = ((cuts.player4 or 0) > 0), cut = cuts.player4 or 0 }
    }
    return preps
end

function hp_apply_apartment_preset_data(preps)
    if type(preps) ~= "table" then
        return false
    end

    if type(preps.solo_launch) == "boolean" then
        state.solo_launch.apartment = preps.solo_launch
    end

    local bonus = preps.bonus_12mil
    if type(bonus) ~= "boolean" and type(preps.bonus) == "boolean" then
        bonus = preps.bonus
    end
    if type(bonus) == "boolean" then
        if type(apartment_12mil_bonus) == "function" then
            apartment_12mil_bonus(bonus, true)
        else
            apartment_bonus_enabled = bonus
        end
    end

    if type(preps.double_rewards_week) == "boolean" then
        apartment_double_rewards_week = preps.double_rewards_week
    end
    if type(preps.max_payout) == "boolean" then
        apartment_max_payout_enabled = preps.max_payout
    end

    local preset = tonumber(preps.preset)
    if not preset then
        preset = tonumber(preps.presets)
    end
    if preset then
        apartment_cut_preset_index = math.floor(hp_clamp_number(preset + 1, 1, #APARTMENT_CUT_PRESET_OPTIONS))
    end

    local function read_cut(player_tbl, legacy_key, fallback)
        local value = fallback
        if type(player_tbl) == "table" and tonumber(player_tbl.cut) then
            value = tonumber(player_tbl.cut)
        elseif tonumber(preps[legacy_key]) then
            value = tonumber(preps[legacy_key])
        end
        return hp_clamp_apartment_cut_percent(value or 0)
    end

    ApartmentCutsValues.player1 = read_cut(preps.player1, "player1_cut", ApartmentCutsValues.player1)
    ApartmentCutsValues.player2 = read_cut(preps.player2, "player2_cut", ApartmentCutsValues.player2)
    ApartmentCutsValues.player3 = read_cut(preps.player3, "player3_cut", ApartmentCutsValues.player3)
    ApartmentCutsValues.player4 = read_cut(preps.player4, "player4_cut", ApartmentCutsValues.player4)

    if apartmentSoloLaunchToggle then apartmentSoloLaunchToggle.state = state.solo_launch.apartment end
    if apartmentBonusToggleRef then apartmentBonusToggleRef.state = apartment_bonus_enabled end
    if apartmentDoubleToggleRef then apartmentDoubleToggleRef.state = apartment_double_rewards_week end
    if apartmentMaxPayoutToggleRef then apartmentMaxPayoutToggleRef.state = apartment_max_payout_enabled end
    if apartmentPresetDropdownRef then apartmentPresetDropdownRef.value = apartment_cut_preset_index end

    if apartmentP1SliderRef then apartmentP1SliderRef.value = ApartmentCutsValues.player1 end
    if apartmentP2SliderRef then apartmentP2SliderRef.value = ApartmentCutsValues.player2 end
    if apartmentP3SliderRef then apartmentP3SliderRef.value = ApartmentCutsValues.player3 end
    if apartmentP4SliderRef then apartmentP4SliderRef.value = ApartmentCutsValues.player4 end

    if apartment_max_payout_enabled then
        hp_refresh_apartment_max_payout(true, false)
    end

    return true
end

function hp_save_heist_preset(mode)
    local state_tbl = hp_get_preset_state(mode)
    if not state_tbl then
        return
    end

    local clean_name = hp_sanitize_preset_name(state_tbl.name)
    if clean_name == "" then
        if notify then notify.push("Heist Presets", "Failed to save. Name is empty.", 2200) end
        return
    end

    hp_ensure_heist_preset_dirs()
    local path = hp_get_heist_preset_path(mode, clean_name)
    local content
    if mode == "apartment" then
        content = hp_collect_apartment_preset_data()
    elseif mode == "cayo" then
        content = hp_collect_cayo_preset_data()
    elseif mode == "casino" then
        content = hp_collect_casino_preset_data()
    else
        if notify then notify.push("Heist Presets", "Unsupported preset mode", 2000) end
        return
    end

    local ok = hp_write_json_file(path, content)
    if not ok then
        if notify then notify.push("Heist Presets", "Failed to save preset", 2200) end
        return
    end

    state_tbl.name = ""
    hp_update_preset_name_label(mode)
    hp_refresh_heist_preset_files(mode, clean_name)
    if notify then notify.push("Heist Presets", "Saved: " .. clean_name, 2200) end
end

function hp_load_heist_preset(mode)
    local selected = hp_get_selected_preset_name(mode)
    if not selected then
        if notify then notify.push("Heist Presets", "No preset selected", 2000) end
        return
    end

    local path = hp_get_heist_preset_path(mode, selected)
    if not file.exists(path) then
        if notify then notify.push("Heist Presets", "Preset does not exist", 2000) end
        hp_refresh_heist_preset_files(mode)
        return
    end

    local preps = hp_read_json_file(path)
    local ok_preset, err_message = hp_validate_heist_preset(mode, preps)
    if not ok_preset then
        if notify then notify.push("Heist Presets", err_message or "Invalid preset JSON", 2200) end
        return
    end

    local applied = false
    if mode == "apartment" then
        applied = hp_apply_apartment_preset_data(preps)
    elseif mode == "cayo" then
        applied = hp_apply_cayo_preset_data(preps)
    elseif mode == "casino" then
        applied = hp_apply_casino_preset_data(preps)
    else
        if notify then notify.push("Heist Presets", "Unsupported preset mode", 2000) end
        return
    end

    if applied then
        if notify then notify.push("Heist Presets", "Loaded: " .. selected, 2200) end
    else
        if notify then notify.push("Heist Presets", "Failed to apply preset", 2200) end
    end
end

function hp_remove_heist_preset(mode)
    local selected = hp_get_selected_preset_name(mode)
    if not selected then
        if notify then notify.push("Heist Presets", "No preset selected", 2000) end
        return
    end

    local path = hp_get_heist_preset_path(mode, selected)
    if not file.exists(path) then
        if notify then notify.push("Heist Presets", "Preset does not exist", 2000) end
        hp_refresh_heist_preset_files(mode)
        return
    end

    local removed = file.remove(path)
    hp_refresh_heist_preset_files(mode)
    if removed then
        if notify then notify.push("Heist Presets", "Removed: " .. selected, 2000) end
    else
        if notify then notify.push("Heist Presets", "Failed to remove preset", 2200) end
    end
end

function hp_copy_heist_preset_folder(mode)
    local state_tbl = hp_get_preset_state(mode)
    if not state_tbl then
        return
    end
    hp_ensure_heist_preset_dirs()
    input.set_clipboard_text(state_tbl.dir)
    if notify then notify.push("Heist Presets", "Folder path copied", 2000) end
end

apartment_bonus_enabled = false
apartment_double_rewards_week = false
apartment_max_payout_enabled = false
apartment_cut_preset_index = 4

apartmentP1SliderRef = nil
apartmentP2SliderRef = nil
apartmentP3SliderRef = nil
apartmentP4SliderRef = nil
apartmentBonusToggleRef = nil
apartmentDoubleToggleRef = nil
apartmentMaxPayoutToggleRef = nil
apartmentPresetDropdownRef = nil
apartmentSoloLaunchToggle = nil

local apartment_max_payout_cache = {
    heist = nil,
    difficulty = nil,
    double = nil,
    cut = nil
}

local function hp_get_apartment_heist_id()
    local stat = account.stats("HEIST_MISSION_RCONT_ID_1")
    local heist = ""

    if stat and type(stat.str) == "string" then
        heist = stat.str
    end

    if heist ~= "" then
        return heist
    end

    local legacy_index = (stat and stat.int32) or nil
    if legacy_index and APARTMENT_HEIST_IDS_BY_INDEX[legacy_index] then
        return APARTMENT_HEIST_IDS_BY_INDEX[legacy_index]
    end

    return nil
end

function hp_is_apartment_fleeca()
    return hp_get_apartment_heist_id() == APARTMENT_HEIST_IDS.fleeca
end

local function hp_get_apartment_difficulty_index()
    local raw = script.globals(4718592 + 3538).int32 or 1
    local difficulty = math.floor(raw) + 1
    if difficulty < 1 then difficulty = 1 end
    if difficulty > 3 then difficulty = 3 end
    return difficulty
end

local function hp_get_apartment_max_payout_cut(double_rewards)
    local heist = hp_get_apartment_heist_id()
    local payout_by_heist = heist and APARTMENT_PAYOUTS[heist] or nil
    if not payout_by_heist then
        return nil, heist, nil
    end

    local difficulty = hp_get_apartment_difficulty_index()
    local payout = payout_by_heist[difficulty] or payout_by_heist[#payout_by_heist]
    if not payout or payout <= 0 then
        return nil, heist, difficulty
    end

    local divisor = (double_rewards and true or false) and 2 or 1
    local cut = math.floor(SAFE_PAYOUT_TARGETS.apartment / (payout / 100) / divisor)
    return hp_clamp_apartment_cut_percent(cut), heist, difficulty
end

function hp_set_apartment_uniform_cuts(cut, apply_now)
    local value = hp_clamp_apartment_cut_percent(cut)

    if type(ApartmentCutsValues) ~= "table" then
        return value
    end

    ApartmentCutsValues.player1 = value
    ApartmentCutsValues.player2 = value
    ApartmentCutsValues.player3 = value
    ApartmentCutsValues.player4 = value

    if apartmentP1SliderRef then apartmentP1SliderRef.value = value end
    if apartmentP2SliderRef then apartmentP2SliderRef.value = value end
    if apartmentP3SliderRef then apartmentP3SliderRef.value = value end
    if apartmentP4SliderRef then apartmentP4SliderRef.value = value end

    if apply_now and type(apply_apartment_cuts) == "function" then
        apply_apartment_cuts()
    end

    return value
end

function hp_apply_selected_apartment_cut_preset(apply_now)
    local selected = APARTMENT_CUT_PRESET_OPTIONS[apartment_cut_preset_index] or APARTMENT_CUT_PRESET_OPTIONS[#APARTMENT_CUT_PRESET_OPTIONS]
    local value = selected and selected.value or 100
    return hp_set_apartment_uniform_cuts(value, apply_now)
end

function hp_refresh_apartment_max_payout(force_update, apply_now)
    if not apartment_max_payout_enabled then
        apartment_max_payout_cache.heist = nil
        apartment_max_payout_cache.difficulty = nil
        apartment_max_payout_cache.double = nil
        apartment_max_payout_cache.cut = nil
        return false
    end

    local cut, heist, difficulty = hp_get_apartment_max_payout_cut(apartment_double_rewards_week)
    if not cut then
        return false
    end

    local changed = force_update
        or apartment_max_payout_cache.heist ~= heist
        or apartment_max_payout_cache.difficulty ~= difficulty
        or apartment_max_payout_cache.double ~= apartment_double_rewards_week
        or apartment_max_payout_cache.cut ~= cut

    if changed then
        hp_set_apartment_uniform_cuts(cut, apply_now)
        apartment_max_payout_cache.heist = heist
        apartment_max_payout_cache.difficulty = difficulty
        apartment_max_payout_cache.double = apartment_double_rewards_week
        apartment_max_payout_cache.cut = cut
    end

    return changed
end

-- Apply cuts for Casino Heist
local function hp_get_casino_max_payout_cut()
    local p = GetMP()
    local approach = account.stats(p .. "H3OPT_APPROACH").int32 or 1
    local hard_approach = account.stats(p .. "H3_HARD_APPROACH").int32 or 0
    local difficulty = (approach ~= 0 and approach == hard_approach) and 2 or 1
    local target = account.stats(p .. "H3OPT_TARGET").int32 or 0

    local payouts = {
        [0] = { 2115000, 2326500 }, -- Cash
        [2] = { 2350000, 2585000 }, -- Artwork
        [1] = { 2585000, 2843500 }, -- Gold
        [3] = { 3290000, 3619000 }  -- Diamonds
    }

    local payout_by_target = payouts[target]
    if not payout_by_target then
        return 100
    end

    local max_payout = SAFE_PAYOUT_TARGETS.casino
    local payout = (payout_by_target[difficulty] or payout_by_target[1]) + 819000
    local cut = math.floor(max_payout / (payout / 100))

    local buyer = script.globals(1975747).int32 or 0 -- DiamondCasino.Board.Buyer
    local gunman = account.stats(p .. "H3OPT_CREWWEAP").int32 or 1
    local driver = account.stats(p .. "H3OPT_CREWDRIVER").int32 or 1
    local hacker = account.stats(p .. "H3OPT_CREWHACKER").int32 or 1

    local buyer_fees = {
        [0] = 0.10,
        [3] = 0.05,
        [6] = 0.00
    }
    local gunman_cuts = {
        [1] = 0.05, [3] = 0.07, [5] = 0.08, [2] = 0.09, [4] = 0.10
    }
    local driver_cuts = {
        [1] = 0.05, [4] = 0.06, [2] = 0.07, [3] = 0.09, [5] = 0.10
    }
    local hacker_cuts = {
        [1] = 0.03, [3] = 0.05, [2] = 0.07, [5] = 0.09, [4] = 0.10
    }

    if buyer_fees[buyer] and gunman_cuts[gunman] and driver_cuts[driver] and hacker_cuts[hacker] then
        local fee_payout = payout - (payout * buyer_fees[buyer])
        local crew_ratio = 0.05 + gunman_cuts[gunman] + driver_cuts[driver] + hacker_cuts[hacker] -- + Lester
        local payout_after_crew = fee_payout - (fee_payout * crew_ratio)
        if payout_after_crew > 0 then
            cut = math.floor(max_payout / (payout_after_crew / 100))
        end
    end

    return hp_clamp_cut_percent(cut)
end

local function apply_casino_cuts()
    script.globals(CasinoGlobals.Host).int32 = CutsValues.host
    script.globals(CasinoGlobals.P2).int32 = CutsValues.player2
    script.globals(CasinoGlobals.P3).int32 = CutsValues.player3
    script.globals(CasinoGlobals.P4).int32 = CutsValues.player4
    if notify then notify.push("Casino Heist", "Cuts Applied!", 2000) end
end

local function reset_heist_preps()
    local prefix0 = "MP0_"
    local prefix1 = "MP1_"
    account.stats(prefix0 .. "H3OPT_DISRUPTSHIP").int32 = 0
    account.stats(prefix1 .. "H3OPT_DISRUPTSHIP").int32 = 0
    account.stats(prefix0 .. "H3OPT_BODYARMORLVL").int32 = 0
    account.stats(prefix1 .. "H3OPT_BODYARMORLVL").int32 = 0
    account.stats(prefix0 .. "H3OPT_CREWWEAP").int32 = 0
    account.stats(prefix1 .. "H3OPT_CREWWEAP").int32 = 0
    account.stats(prefix0 .. "H3OPT_CREWDRIVER").int32 = 0
    account.stats(prefix1 .. "H3OPT_CREWDRIVER").int32 = 0
    account.stats(prefix0 .. "H3OPT_CREWHACKER").int32 = 0
    account.stats(prefix1 .. "H3OPT_CREWHACKER").int32 = 0
    account.stats(prefix0 .. "H3OPT_KEYLEVELS").int32 = 0
    account.stats(prefix1 .. "H3OPT_KEYLEVELS").int32 = 0
    account.stats(prefix0 .. "H3OPT_MODVEH").int32 = 0
    account.stats(prefix1 .. "H3OPT_MODVEH").int32 = 0
    account.stats(prefix0 .. "H3OPT_MASKS").int32 = 0
    account.stats(prefix1 .. "H3OPT_MASKS").int32 = 0
    account.stats(prefix0 .. "H3OPT_WEAPS").int32 = 0
    account.stats(prefix1 .. "H3OPT_WEAPS").int32 = 0
    account.stats(prefix0 .. "H3OPT_VEHS").int32 = 0
    account.stats(prefix1 .. "H3OPT_VEHS").int32 = 0
    account.stats(prefix0 .. "H3OPT_APPROACH").int32 = 0
    account.stats(prefix1 .. "H3OPT_APPROACH").int32 = 0
    account.stats(prefix0 .. "H3OPT_BITSET0").int32 = 0
    account.stats(prefix1 .. "H3OPT_BITSET0").int32 = 0
    account.stats(prefix0 .. "H3OPT_ACCESSPOINTS").int32 = 0
    account.stats(prefix1 .. "H3OPT_ACCESSPOINTS").int32 = 0
    account.stats(prefix0 .. "H3OPT_TARGET").int32 = 0
    account.stats(prefix1 .. "H3OPT_TARGET").int32 = 0
    account.stats(prefix0 .. "H3OPT_POI").int32 = 0
    account.stats(prefix1 .. "H3OPT_POI").int32 = 0
    account.stats(prefix0 .. "H3OPT_BITSET1").int32 = 0
    account.stats(prefix1 .. "H3OPT_BITSET1").int32 = 0
    account.stats(prefix0 .. "H3_PARTIALPASS").int32 = 0
    account.stats(prefix1 .. "H3_PARTIALPASS").int32 = 0
    account.stats(prefix0 .. "CAS_HEIST_NOTS").int32 = 0
    account.stats(prefix1 .. "CAS_HEIST_NOTS").int32 = 0
    account.stats(prefix0 .. "CAS_HEIST_FLOW").int32 = -1
    account.stats(prefix1 .. "CAS_HEIST_FLOW").int32 = -1
    account.stats(prefix0 .. "H3_LAST_APPROACH").int32 = 0
    account.stats(prefix1 .. "H3_LAST_APPROACH").int32 = 0
    account.stats(prefix0 .. "H3_HARD_APPROACH").int32 = 0
    account.stats(prefix1 .. "H3_HARD_APPROACH").int32 = 0
    account.stats(prefix0 .. "H3_SKIPCOUNT").int32 = 0
    account.stats(prefix1 .. "H3_SKIPCOUNT").int32 = 0
    account.stats(prefix0 .. "H3_MISSIONSKIPPED").int32 = 0
    account.stats(prefix1 .. "H3_MISSIONSKIPPED").int32 = 0
    account.stats(prefix0 .. "H3_BOARD_DIALOGUE0").int32 = 0
    account.stats(prefix1 .. "H3_BOARD_DIALOGUE0").int32 = 0
    account.stats(prefix0 .. "H3_BOARD_DIALOGUE1").int32 = 0
    account.stats(prefix1 .. "H3_BOARD_DIALOGUE1").int32 = 0
    account.stats(prefix0 .. "H3_BOARD_DIALOGUE2").int32 = 0
    account.stats(prefix1 .. "H3_BOARD_DIALOGUE2").int32 = 0
    account.stats(prefix0 .. "H3_VEHICLESUSED").int32 = 0
    account.stats(prefix1 .. "H3_VEHICLESUSED").int32 = 0
    account.stats(prefix0 .. "MPPLY_H3_COOLDOWN").int32 = 0
    account.stats(prefix1 .. "MPPLY_H3_COOLDOWN").int32 = 0
    account.stats(prefix0 .. "H3_COMPLETEDPOSIX").int32 = 0
    account.stats("MP1_H3_COMPLETEDPOSIX").int32 = 0
    script.locals("gb_casino_heist_planning", 212).int32 = 2
    if notify then notify.push("Preset", "Reset preparations", 2000) end
end

-- Tools functions
local function casino_skip_arcade_setup()
    local success, result = pcall(function()
        local stat = account.stats(27227, 1)
        if stat and stat.bool ~= nil then
            stat.bool = true
            return true
        end
        return false
    end)
    
    if success and result then
        if notify then notify.push("Casino Tools", "Arcade Setup Skipped", 2000) end
    else
        if notify then notify.push("Casino Tools", "Failed to skip arcade setup", 2000) end
    end
end

local function casino_fix_stuck_keycards()
    script.locals("fm_mission_controller", 63638).int32 = 5
    if notify then notify.push("Casino Tools", "Keycards Fixed", 2000) end
end

local function casino_skip_objective()
    local v = script.locals("fm_mission_controller", 20397).int32
    script.locals("fm_mission_controller", 20397).int32 = v | (1 << 17)
    if notify then notify.push("Casino Tools", "Objective Skipped", 2000) end
end

local function casino_fingerprint_hack()
    script.locals("fm_mission_controller", 54042).int32 = 5
    if notify then notify.push("Casino Tools", "Fingerprint Hack Completed", 2000) end
end

local function casino_instant_keypad_hack()
    script.locals("fm_mission_controller", 55108).int32 = 5
    if notify then notify.push("Casino Tools", "Keypad Hack Completed", 2000) end
end

local function casino_instant_vault_drill()
    script.locals("fm_mission_controller", 10551 + 2).int32 = 7
    script.locals("fm_mission_controller", 10551).int32 = script.locals("fm_mission_controller", 10551).int32 | (1 << 12)
    if notify then notify.push("Casino Tools", "Vault Drill Completed", 2000) end
end

local function casino_remove_cooldown()
    local p = GetMP()
    account.stats(p .. "H3_COMPLETEDPOSIX").int32 = -1
    account.stats(p .. "MPPLY_H3_COOLDOWN").int32 = -1
    if notify then notify.push("Casino Tools", "Cooldown Removed", 2000) end
end

local function casino_set_team_lives()
    if script.running("fm_mission_controller") then
        script.locals("fm_mission_controller", 22126).int32 = -100
        if notify then notify.push("Casino Tools", "Team Lives Set to 100", 2000) end
    else
        if notify then notify.push("Casino Tools", "Mission Controller Not Running", 2000) end
    end
end

local function casino_instant_finish()
    if not script.running("fm_mission_controller") then
        if notify then notify.push("Casino Tools", "Casino script not running", 2000) end
        return false
    end
    
    util.create_job(function()
        if script and script.force_host then
            script.force_host("fm_mission_controller")
        end
        util.yield(1000)
        
        local p = GetMP()
        local approach = account.stats(p .. "H3OPT_APPROACH").int32 or 1
        -- CASINO_STEP4_MONEY = 10000000
        -- APARTMENT_STEP4_MONEY = 10000000
        -- APARTMENT_STEP5 = 99999
        -- APARTMENT_STEP6 = 99999
        
        if approach == 3 then
            -- Aggressive approach
            script.locals("fm_mission_controller", 20395).int32 = 12  -- APARTMENT_FINISH_STEP1 = CASINO_AGGRESSIVE_STEP1
            script.locals("fm_mission_controller", 20395 + 1740 + 1).int32 = 80  -- APARTMENT_FINISH_STEP3 = APARTMENT_STEP3
            script.locals("fm_mission_controller", 20395 + 2686).int32 = 10000000  -- APARTMENT_FINISH_STEP4 = CASINO_STEP4_MONEY
            script.locals("fm_mission_controller", 29016 + 1).int32 = 99999  -- APARTMENT_FINISH_STEP5 = APARTMENT_STEP5
            script.locals("fm_mission_controller", 32472 + 1 + 68).int32 = 99999  -- APARTMENT_FINISH_STEP6 = APARTMENT_STEP6
        else
            -- Silent & Sneaky or Big Con
            script.locals("fm_mission_controller", 20395 + 1062).int32 = 5  -- APARTMENT_FINISH_STEP2 = APARTMENT_STEP2
            script.locals("fm_mission_controller", 20395 + 1740 + 1).int32 = 80  -- APARTMENT_FINISH_STEP3 = APARTMENT_STEP3
            script.locals("fm_mission_controller", 20395 + 2686).int32 = 10000000  -- APARTMENT_FINISH_STEP4 = APARTMENT_STEP4_MONEY
            script.locals("fm_mission_controller", 29016 + 1).int32 = 99999  -- APARTMENT_FINISH_STEP5 = APARTMENT_STEP5
            script.locals("fm_mission_controller", 32472 + 1 + 68).int32 = 99999  -- APARTMENT_FINISH_STEP6 = APARTMENT_STEP6
        end
        
        if notify then notify.push("Casino Tools", "Diamond Casino instant finish", 2000) end
    end)
    
    return true
end

-- -------------------------------------------------------------------------
-- [Casino Launch Functions]
-- Solo Launch: Generic function
local function solo_launch_generic()
    if not script.running("fmmc_launcher") then
        return false
    end

    -- Get current heist value from local
    local value = script.locals("fmmc_launcher", 20056 + 34).int32
    if not value or value == 0 then
        return false
    end

    -- Set player count to solo (from data)
    -- Formula: BASE_LOBBY + 4 + 1 + (value * 95) + 75 controls player requirement
    local BASE_LOBBY = 794954
    local offset_base = 4
    local offset_multiplier = 95
    local offset_final = 75
    local player_count_global = BASE_LOBBY + offset_base + 1 + (value * offset_multiplier) + offset_final
    script.globals(player_count_global).int32 = 1  -- SOLO = 1

    -- Set launcher locals
    script.locals("fmmc_launcher", 20056 + 15).int32 = 1  -- PLAYER_COUNT = SOLO

    -- Set launcher globals (solo values)
    script.globals(4718592 + 3539).int32 = 1      -- STEP_1 = 1
    script.globals(4718592 + 3540).int32 = 1      -- STEP_2 = 1
    script.globals(4718592 + 3542 + 1).int32 = 1  -- STEP_3 = 1
    script.globals(4718592 + 192451 + 1).int32 = 0  -- STEP_4 = 0
    script.globals(4718592 + 3536).int32 = 1      -- STEP_5 = 1

    -- Set timer local
    script.locals("fmmc_launcher", 20297).int32 = 0

    return true
end

-- Solo Launch: Casino setup function
local function solo_launch_casino_setup()
    if not script.running("fm_mission_controller") then
        return false
    end

    local is_finale = script.globals(2685153 + 21).int32
    if not is_finale or is_finale ~= 1 then
        return false
    end

    -- Get approach type
    local p = GetMP()
    local approach = account.stats(p .. "H3OPT_APPROACH").int32
    if not approach then return false end

    -- Set casino-specific data for finale
    if approach == 2 then  -- Big Con
        -- Set van type for Big Con approach
        script.globals(1973219).int32 = 3  -- VAN_BIG_CON = 3
    end

    -- Set target from stat
    local target = account.stats(p .. "H3OPT_TARGET").int32 or 0
    script.globals(1973198).int32 = target  -- DATA.TARGET

    return true
end

-- Solo Launch: Reset Casino to normal (2 players)
local function solo_launch_reset_casino()
    if not script.running("fmmc_launcher") then
        return false
    end

    local value = script.locals("fmmc_launcher", 20056 + 34).int32
    if not value or value == 0 then return false end

    -- Casino: Always 2 players, use reset values from data
    local BASE_LOBBY = 794954
    local offset_base = 4
    local offset_multiplier = 95
    local offset_final = 75
    local player_count_global = BASE_LOBBY + offset_base + 1 + (value * offset_multiplier) + offset_final
    script.globals(player_count_global).int32 = 2  -- DUO = 2
    script.locals("fmmc_launcher", 20056 + 15).int32 = 2  -- PLAYER_COUNT = DUO

    -- Reset values
    script.globals(4718592 + 3539).int32 = 1      -- STEP_1 = 1
    script.globals(4718592 + 3540).int32 = 1      -- STEP_2 = 1
    script.globals(4718592 + 3542 + 1).int32 = 2  -- STEP_3 = 2
    script.globals(4718592 + 192451 + 1).int32 = 11  -- STEP_4 = 11

    return true
end

-- Casino Force Ready
local function casino_force_ready()
    util.create_job(function()
        if script and script.force_host then
            script.force_host("fm_mission_controller")
        end
        util.yield(1000)

        -- Set ready states for players 2, 3, 4
        script.globals(1977672).int32 = 1  -- CASINO_READY.PLAYER2 = READY_STATE_HEIST (1)
        script.globals(1977740).int32 = 1  -- CASINO_READY.PLAYER3 = READY_STATE_HEIST (1)
        script.globals(1977808).int32 = 1  -- CASINO_READY.PLAYER4 = READY_STATE_HEIST (1)

        if notify then notify.push("Casino Launch", "All players ready", 2000) end
    end)
    return true
end

local function doomsday_force_ready()
    util.create_job(function()
        if script and script.force_host then
            script.force_host("fm_mission_controller")
        end
        util.yield(1000)

        script.globals(1883089).int32 = 1
        script.globals(1883405).int32 = 1
        script.globals(1883721).int32 = 1

        if notify then notify.push("Doomsday Launch", "All players ready", 2000) end
    end)
    return true
end

local function solo_launch_reset_doomsday()
    if not script.running("fmmc_launcher") then
        return false
    end

    local value = script.locals("fmmc_launcher", 20056 + 34).int32
    if not value or value == 0 then return false end

    local BASE_LOBBY = 794954
    local offset_base = 4
    local offset_multiplier = 95
    local offset_final = 75
    local player_count_global = BASE_LOBBY + offset_base + 1 + (value * offset_multiplier) + offset_final
    script.globals(player_count_global).int32 = 2
    script.locals("fmmc_launcher", 20056 + 15).int32 = 2

    script.globals(4718592 + 3539).int32 = 1
    script.globals(4718592 + 3540).int32 = 1
    script.globals(4718592 + 3542 + 1).int32 = 2
    script.globals(4718592 + 192451 + 1).int32 = 11

    return true
end

-- Solo Launch: Reset Apartment to normal
local function solo_launch_reset_apartment()
    if not script.running("fmmc_launcher") then
        return false
    end

    local value = script.locals("fmmc_launcher", 20056 + 34).int32
    if not value or value == 0 then return false end

    -- Apartment: Fleeca requires 2, the rest require 4
    local is_fleeca = hp_is_apartment_fleeca()
    local required_players = is_fleeca and 2 or 4  -- FLEECA = 2, APARTMENT = 4

    local BASE_LOBBY = 794954
    local offset_base = 4
    local offset_multiplier = 95
    local offset_final = 75
    local player_count_global = BASE_LOBBY + offset_base + 1 + (value * offset_multiplier) + offset_final
    script.globals(player_count_global).int32 = required_players
    script.locals("fmmc_launcher", 20056 + 15).int32 = required_players  -- PLAYER_COUNT
    script.globals(4718592 + 3539).int32 = required_players  -- STEP_1
    script.globals(4718592 + 3540).int32 = required_players  -- STEP_2

    -- Use reset values from data
    script.globals(4718592 + 3542 + 1).int32 = 1   -- STEP_3 = 1
    script.globals(4718592 + 192451 + 1).int32 = 0  -- STEP_4 = 0
    script.locals("fmmc_launcher", 20297).int32 = 0  -- TIMER = 0
    script.globals(4718592 + 3536).int32 = 1       -- STEP_5 = 1

    return true
end

-- ---------------------------------------------------------
-- 6.6. Cayo Perico Functions
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

local CASINO_CREW_CUT_TUNABLES = {
    { name = "CH_LESTER_CUT", default = 5 },
    { name = "HEIST3_PREPBOARD_GUNMEN_KARL_CUT", default = 5 },
    { name = "HEIST3_PREPBOARD_GUNMEN_GUSTAVO_CUT", default = 9 },
    { name = "HEIST3_PREPBOARD_GUNMEN_CHARLIE_CUT", default = 7 },
    { name = "HEIST3_PREPBOARD_GUNMEN_CHESTER_CUT", default = 10 },
    { name = "HEIST3_PREPBOARD_GUNMEN_PATRICK_CUT", default = 8 },
    { name = "HEIST3_DRIVERS_KARIM_CUT", default = 5 },
    { name = "HEIST3_DRIVERS_TALIANA_CUT", default = 7 },
    { name = "HEIST3_DRIVERS_EDDIE_CUT", default = 9 },
    { name = "HEIST3_DRIVERS_ZACH_CUT", default = 6 },
    { name = "HEIST3_DRIVERS_CHESTER_CUT", default = 10 },
    { name = "HEIST3_HACKERS_RICKIE_CUT", default = 3 },
    { name = "HEIST3_HACKERS_CHRISTIAN_CUT", default = 7 },
    { name = "HEIST3_HACKERS_YOHAN_CUT", default = 5 },
    { name = "HEIST3_HACKERS_AVI_CUT", default = 10 },
    { name = "HEIST3_HACKERS_PAIGE_CUT", default = 9 }
}

local cayo_tunable_backup = {
    bag_max_capacity = nil,
    pavel_cut = nil,
    fencing_fee = nil
}

local casino_crew_cut_backup = {}

cayo_womans_bag_enabled = false
cayo_remove_crew_cuts_enabled = false
casino_remove_crew_cuts_enabled = false
casino_autograbber_enabled = false

cayoWomansBagToggle = nil
cayoRemoveCrewCutsToggle = nil
casinoRemoveCrewCutsToggle = nil
casinoAutograbberToggle = nil

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

function casino_set_remove_crew_cuts(enable, silent)
    local enabled = enable and true or false
    local changed = (casino_remove_crew_cuts_enabled ~= enabled)

    local i
    for i = 1, #CASINO_CREW_CUT_TUNABLES do
        local item = CASINO_CREW_CUT_TUNABLES[i]
        if enabled then
            if casino_crew_cut_backup[item.name] == nil then
                casino_crew_cut_backup[item.name] = hp_tunable_int(item.name)
            end
            hp_set_tunable_int(item.name, 0)
        else
            local restore = casino_crew_cut_backup[item.name]
            if restore == nil then restore = item.default end
            hp_set_tunable_int(item.name, restore)
        end
    end

    casino_remove_crew_cuts_enabled = enabled
    if casinoRemoveCrewCutsToggle then casinoRemoveCrewCutsToggle.state = enabled end
    if changed and not silent and notify then
        notify.push("Casino", enabled and "Crew Cuts Removed" or "Crew Cuts Restored", 2000)
    end
end

function casino_set_autograbber(enable, silent)
    local enabled = enable and true or false
    local changed = (casino_autograbber_enabled ~= enabled)
    casino_autograbber_enabled = enabled
    if casinoAutograbberToggle then casinoAutograbberToggle.state = enabled end

    if changed and not silent and notify then
        notify.push("Casino", enabled and "Autograbber Enabled" or "Autograbber Disabled", 2000)
    end
end

local function casino_autograbber_tick()
    if not casino_autograbber_enabled then
        return
    end
    if not script.running("fm_mission_controller") then
        return
    end

    local grab_local = script.locals("fm_mission_controller", 10295)
    local grab = grab_local.int32
    if grab == 3 then
        grab_local.int32 = 4
    elseif grab == 4 then
        script.locals("fm_mission_controller", 10295 + 14).float = 2.0
    end
end

local function hp_enforce_heist_toggles()
    if cayo_womans_bag_enabled then
        hp_set_tunable_int("HEIST_BAG_MAX_CAPACITY", 99999)
    end
    if cayo_remove_crew_cuts_enabled then
        hp_set_tunable_float("IH_DEDUCTION_PAVEL_CUT", 0.0)
        hp_set_tunable_float("IH_DEDUCTION_FENCING_FEE", 0.0)
    end
    if casino_remove_crew_cuts_enabled then
        local i
        for i = 1, #CASINO_CREW_CUT_TUNABLES do
            hp_set_tunable_int(CASINO_CREW_CUT_TUNABLES[i].name, 0)
        end
    end

    casino_autograbber_tick()
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
    if notify then notify.push("Cayo Tools", "Cooldown Removed", 2000) end
end

local function cayo_instant_finish()
    if script.force_host("fm_mission_controller_2020") then
        util.yield(1000)
        script.locals("fm_mission_controller_2020", 56223).int32 = 9
        script.locals("fm_mission_controller_2020", 58000).int32 = 50
        if notify then notify.push("Cayo Tools", "Cayo Perico instant finish", 2000) end
    else
        if notify then notify.push("Cayo Tools", "Failed to force host", 2000) end
    end
end

-- Cayo Teleport functions using Lexis API
-- Documentation: https://docs.lexis.re/
-- Teleport cooldown to prevent spam/looping
local teleport_cooldown = 0

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
                local native = require("natives")
                if native and native.player_ped_id then
                    return native.player_ped_id()
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
                    for i = 1, 10 do
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
local teleport_cooldown = 0

local function cayo_teleport_underwater_tunnel()
    -- Underwater tunnel entrance coordinates (Cayo Perico)
    -- Coordinates: 5051, -5822, 2 (Zone: Cayo Perico)
    
    -- Check cooldown to prevent spam
    local current_time = os.clock()
    if current_time < teleport_cooldown then
        return
    end
    teleport_cooldown = current_time + 1.0 -- 1 second cooldown
    
    local success, error_msg = teleport_to_coords(5051.0, -5822.0, 2.0)
    
    if success then
        -- Automatically bypass drainage pipe after teleporting to tunnel
        -- This ensures the game recognizes players are in the tunnel (especially when using Longfin)
        util.create_thread(function()
            util.yield(500)  -- Wait a bit for teleport to complete
            
            -- Bypass drainage pipe to make game recognize players in tunnel
            if script.running("fm_mission_controller_2020") then
                -- Apply bypass multiple times to ensure it's recognized
                for i = 1, 10 do
                    script.locals("fm_mission_controller_2020", 31349).int32 = 6
                    util.yield(50)
                end
            end
        end)
        
        if notify then notify.push("Cayo Teleport", "Teleported to Underwater Tunnel", 2000) end
    else
        local msg = "Failed to teleport"
        if error_msg then msg = msg .. ": " .. error_msg end
        if notify then notify.push("Cayo Teleport", msg, 3000) end
    end
end

local function cayo_teleport_residence()
    -- Residence/Mansion coordinates (Cayo Perico)
    -- Coordinates: 5010, -5753, 30
    local current_time = os.clock()
    if current_time < teleport_cooldown then
        return
    end
    teleport_cooldown = current_time + 1.0
    
    local success, error_msg = teleport_to_coords(5010.0, -5753.0, 30.0)
    if success then
        if notify then notify.push("Cayo Teleport", "Teleported to Residence", 2000) end
    else
        if notify then notify.push("Cayo Teleport", "Failed to teleport", 2000) end
    end
end

local function cayo_teleport_main_target()
    -- Main target location (inside compound vault, Cayo Perico)
    -- Coordinates: 5006, -5754, 16
    local current_time = os.clock()
    if current_time < teleport_cooldown then
        return
    end
    teleport_cooldown = current_time + 1.0
    
    local success, error_msg = teleport_to_coords(5006.0, -5754.0, 16.0)
    if success then
        if notify then notify.push("Cayo Teleport", "Teleported to Main Target", 2000) end
    else
        if notify then notify.push("Cayo Teleport", "Failed to teleport", 2000) end
    end
end

local function cayo_teleport_gate()
    -- Gate entrance coordinates (Cayo Perico compound main gate)
    -- Coordinates: 4992, -5720, 21
    local current_time = os.clock()
    if current_time < teleport_cooldown then
        return
    end
    teleport_cooldown = current_time + 1.0
    
    local success, error_msg = teleport_to_coords(4992.0, -5720.0, 21.0)
    if success then
        if notify then notify.push("Cayo Teleport", "Teleported to Gate", 2000) end
    else
        if notify then notify.push("Cayo Teleport", "Failed to teleport", 2000) end
    end
end

local function cayo_teleport_center()
    -- Center coordinates (Cayo Perico)
    -- Coordinates: 4971, -5136, 4
    local current_time = os.clock()
    if current_time < teleport_cooldown then
        return
    end
    teleport_cooldown = current_time + 1.0
    
    local success, error_msg = teleport_to_coords(4971.0, -5136.0, 4.0)
    if success then
        if notify then notify.push("Cayo Teleport", "Teleported to Center", 2000) end
    else
        if notify then notify.push("Cayo Teleport", "Failed to teleport", 2000) end
    end
end

local function cayo_teleport_loot1()
    -- Loot #1 coordinates (Cayo Perico - In Residence)
    -- Coordinates: 5002, -5751, 16
    local current_time = os.clock()
    if current_time < teleport_cooldown then
        return
    end
    teleport_cooldown = current_time + 1.0
    
    local success, error_msg = teleport_to_coords(5002.0, -5751.0, 16.0)
    if success then
        if notify then notify.push("Cayo Teleport", "Teleported to Loot #1", 2000) end
    else
        if notify then notify.push("Cayo Teleport", "Failed to teleport", 2000) end
    end
end

local function cayo_teleport_loot2()
    -- Loot #2 coordinates (Cayo Perico - In Residence)
    -- Coordinates: 5031, -5737, 19
    local current_time = os.clock()
    if current_time < teleport_cooldown then
        return
    end
    teleport_cooldown = current_time + 1.0
    
    local success, error_msg = teleport_to_coords(5031.0, -5737.0, 19.0)
    if success then
        if notify then notify.push("Cayo Teleport", "Teleported to Loot #2", 2000) end
    else
        if notify then notify.push("Cayo Teleport", "Failed to teleport", 2000) end
    end
end

local function cayo_teleport_loot3()
    -- Loot #3 coordinates (Cayo Perico - In Residence)
    -- Coordinates: 5081, -5756, 17
    local current_time = os.clock()
    if current_time < teleport_cooldown then
        return
    end
    teleport_cooldown = current_time + 1.0
    
    local success, error_msg = teleport_to_coords(5081.0, -5756.0, 17.0)
    if success then
        if notify then notify.push("Cayo Teleport", "Teleported to Loot #3", 2000) end
    else
        if notify then notify.push("Cayo Teleport", "Failed to teleport", 2000) end
    end
end

local function cayo_teleport_gate_outside()
    -- Gate coordinates (Cayo Perico - Outside Residence)
    -- Coordinates: 4977, -5706, 20
    local current_time = os.clock()
    if current_time < teleport_cooldown then
        return
    end
    teleport_cooldown = current_time + 1.0
    
    local success, error_msg = teleport_to_coords(4977.0, -5706.0, 20.0)
    if success then
        if notify then notify.push("Cayo Teleport", "Teleported to Gate", 2000) end
    else
        if notify then notify.push("Cayo Teleport", "Failed to teleport", 2000) end
    end
end

local function cayo_teleport_airport()
    -- Airport coordinates (Cayo Perico - Outside Residence)
    -- Coordinates: 4443, -4510, 5
    local current_time = os.clock()
    if current_time < teleport_cooldown then
        return
    end
    teleport_cooldown = current_time + 1.0
    
    local success, error_msg = teleport_to_coords(4443.0, -4510.0, 5.0)
    if success then
        if notify then notify.push("Cayo Teleport", "Teleported to Airport", 2000) end
    else
        if notify then notify.push("Cayo Teleport", "Failed to teleport", 2000) end
    end
end

local function cayo_teleport_escape()
    -- Escape coordinates (Cayo Perico - Outside Residence)
    -- Coordinates: 3698, -6133, -5
    local current_time = os.clock()
    if current_time < teleport_cooldown then
        return
    end
    teleport_cooldown = current_time + 1.0
    
    local success, error_msg = teleport_to_coords(3698.0, -6133.0, -5.0)
    if success then
        if notify then notify.push("Cayo Teleport", "Teleported to Escape", 2000) end
    else
        if notify then notify.push("Cayo Teleport", "Failed to teleport", 2000) end
    end
end

-- ---------------------------------------------------------
-- 6.7. Apartment Heist Functions
-- ---------------------------------------------------------

-- Apartment Globals
local ApartmentGlobals = {
    ReadyBase = 2658294,
    Ready = {
        PLAYER1 = 2658565,
        PLAYER2 = 2659033,
        PLAYER3 = 2659501,
        PLAYER4 = 2659969
    },
    Board = 1936048
}

-- Apartment Force Ready
local function apartment_force_ready()
    if script and script.force_host then
        script.force_host("fm_mission_controller")
    end

    util.create_job(function()
        util.yield(1000)

        script.globals(ApartmentGlobals.Ready.PLAYER2).int32 = 6
        script.globals(ApartmentGlobals.Ready.PLAYER3).int32 = 6
        script.globals(ApartmentGlobals.Ready.PLAYER4).int32 = 6

        if notify then notify.push("Apartment Launch", "All Players Ready", 2000) end
    end)
    return true
end

local function apartment_redraw_board()
    script.globals(ApartmentGlobals.Board).int32 = 22
    if notify then notify.push("Apartment Launch", "Board Redrawn", 2000) end
end

local function apartment_complete_preps()
    account.stats("HEIST_PLANNING_STAGE").int32 = -1
    if notify then notify.push("Apartment Preps", "Preps Completed", 2000) end
end

local function apartment_kill_cooldown()
    local player_id = (players and players.user and players.user()) or 0
    local cooldown_global = 1877303 + 1 + (player_id * 77) + 76
    script.globals(cooldown_global).int32 = -1
    if notify then notify.push("Apartment Preps", "Cooldown Reset", 2000) end
end

-- ---------------------------------------------------------
-- 7. Setup Data (Example)
-- ---------------------------------------------------------
ui.tab("heist", "HEIST", "ui/components/network.png")

-- Casino granular prep options (aligned with SilentNight behavior)
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

casinoPresetsGroup = ui.group(heistTab, "Presets (JSON)", nil, nil, nil, nil, "casino")
hp_heist_presets.casino.name_label = ui.label(casinoPresetsGroup, "Name: QuickPreset", config.colors.text_sec)
ui.button(casinoPresetsGroup, "casino_preset_set_name", "Set Name From Keyboard", function()
    hp_open_heist_preset_name_keyboard("casino")
end)
ui.button(casinoPresetsGroup, "casino_preset_name_clip", "Set Name From Clipboard", function()
    local clip = input.get_clipboard_text()
    local clean = hp_sanitize_preset_name(clip)
    if clean == "" then
        if notify then notify.push("Heist Presets", "Clipboard is empty/invalid", 2000) end
        return
    end
    hp_heist_presets.casino.name = clean
    hp_update_preset_name_label("casino")
    if notify then notify.push("Heist Presets", "Name set: " .. clean, 2000) end
end)
hp_heist_presets.casino.dropdown = ui.dropdown(
    casinoPresetsGroup,
    "casino_preset_file",
    "Preset File",
    hp_heist_presets.casino.options,
    hp_heist_presets.casino.selected,
    function(opt)
        hp_heist_presets.casino.selected = hp_find_option_index(hp_heist_presets.casino.options, opt, 1)
    end
)
ui.button_pair(
    casinoPresetsGroup,
    "casino_preset_save", "Save", function() hp_save_heist_preset("casino") end,
    "casino_preset_load", "Load", function() hp_load_heist_preset("casino") end
)
ui.button_pair(
    casinoPresetsGroup,
    "casino_preset_remove", "Remove", function() hp_remove_heist_preset("casino") end,
    "casino_preset_refresh", "Refresh", function() hp_refresh_heist_preset_files("casino") end
)
ui.button(casinoPresetsGroup, "casino_preset_copy", "Copy Folder Path", function() hp_copy_heist_preset_folder("casino") end)
hp_update_preset_name_label("casino")
hp_refresh_heist_preset_files("casino")

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
    "tool_arcade", "Skip Arcade Setup", function() casino_skip_arcade_setup() end,
    "tool_keycards", "Fix Keycards", function() casino_fix_stuck_keycards() end
)
ui.button_pair(
    gTools,
    "casino_skip_cutscene", "Skip Cutscene", function() heist_skip_cutscene("Casino") end,
    "tool_lives", "Set Team Lives", function() casino_set_team_lives() end
)
ui.button(gTools, "tool_objective", "Skip Objective", function() casino_skip_objective() end)
casinoAutograbberToggle = ui.toggle(gTools, "casino_autograbber", "Autograbber", casino_autograbber_enabled, function(val)
    casino_set_autograbber(val)
end)

local gCasinoDanger = build_skip_cooldown_danger_group(
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
    local current_time = os.clock()
    if current_time < teleport_cooldown then
        return
    end
    teleport_cooldown = current_time + 1.0
    
    local success, error_msg = teleport_to_coords(968.0, -73.0, 75.0)
    if success then
        if notify then notify.push("Casino Teleport", "Teleported to Tunnel", 2000) end
    else
        if notify then notify.push("Casino Teleport", "Failed to teleport", 2000) end
    end
end

local function casino_teleport_staff_lobby()
    -- Staff Lobby coordinates (Casino Heist - Outside Casino)
    -- Coordinates: 982, 16, 82
    local current_time = os.clock()
    if current_time < teleport_cooldown then
        return
    end
    teleport_cooldown = current_time + 1.0
    
    local success, error_msg = teleport_to_coords(982.0, 16.0, 82.0)
    if success then
        if notify then notify.push("Casino Teleport", "Teleported to Staff Lobby", 2000) end
    else
        if notify then notify.push("Casino Teleport", "Failed to teleport", 2000) end
    end
end

local function casino_teleport_staff_lobby_inside()
    -- Staff Lobby coordinates (Casino Heist - In Casino)
    -- Coordinates: 2547, -270, -58
    local current_time = os.clock()
    if current_time < teleport_cooldown then
        return
    end
    teleport_cooldown = current_time + 1.0
    
    local success, error_msg = teleport_to_coords(2547.0, -270.0, -58.0)
    if success then
        if notify then notify.push("Casino Teleport", "Teleported to Staff Lobby", 2000) end
    else
        if notify then notify.push("Casino Teleport", "Failed to teleport", 2000) end
    end
end

local function casino_teleport_side_safe()
    -- Side Safe coordinates (Casino Heist - In Casino)
    -- Coordinates: 2522, -287, -58
    local current_time = os.clock()
    if current_time < teleport_cooldown then
        return
    end
    teleport_cooldown = current_time + 1.0
    
    local success, error_msg = teleport_to_coords(2522.0, -287.0, -58.0)
    if success then
        if notify then notify.push("Casino Teleport", "Teleported to Side Safe", 2000) end
    else
        if notify then notify.push("Casino Teleport", "Failed to teleport", 2000) end
    end
end

local function casino_teleport_tunnel_door()
    -- Tunnel Door coordinates (Casino Heist - In Casino)
    -- Coordinates: 2469, -279, -70
    local current_time = os.clock()
    if current_time < teleport_cooldown then
        return
    end
    teleport_cooldown = current_time + 1.0
    
    local success, error_msg = teleport_to_coords(2469.0, -279.0, -70.0)
    if success then
        if notify then notify.push("Casino Teleport", "Teleported to Tunnel Door", 2000) end
    else
        if notify then notify.push("Casino Teleport", "Failed to teleport", 2000) end
    end
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
local gCayoInfo = ui.group(heistTab, "Info", nil, nil, nil, 140, "cayo")
ui.label(gCayoInfo, "Cayo Perico Heist", config.colors.accent)
ui.label(gCayoInfo, "Max transaction: $2,550,000", config.colors.text_main)
ui.label(gCayoInfo, "Transaction cooldown: 30 min", config.colors.text_sec)
ui.label(gCayoInfo, "Heist cooldown: 45 min (skip)", config.colors.text_sec)

local gCayoPreps = ui.group(heistTab, "Preps", nil, nil, nil, nil, "cayo")
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
cayoAdvancedToggle = ui.toggle(gCayoPreps, "cayo_advanced", "Advanced Value Editing", CayoConfig.advanced, function(val)
    CayoConfig.advanced = val
end)
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

cayoPresetsGroup = ui.group(heistTab, "Presets (JSON)", nil, nil, nil, nil, "cayo")
hp_heist_presets.cayo.name_label = ui.label(cayoPresetsGroup, "Name: QuickPreset", config.colors.text_sec)
ui.button(cayoPresetsGroup, "cayo_preset_set_name", "Set Name From Keyboard", function()
    hp_open_heist_preset_name_keyboard("cayo")
end)
ui.button(cayoPresetsGroup, "cayo_preset_name_clip", "Set Name From Clipboard", function()
    local clip = input.get_clipboard_text()
    local clean = hp_sanitize_preset_name(clip)
    if clean == "" then
        if notify then notify.push("Heist Presets", "Clipboard is empty/invalid", 2000) end
        return
    end
    hp_heist_presets.cayo.name = clean
    hp_update_preset_name_label("cayo")
    if notify then notify.push("Heist Presets", "Name set: " .. clean, 2000) end
end)
hp_heist_presets.cayo.dropdown = ui.dropdown(
    cayoPresetsGroup,
    "cayo_preset_file",
    "Preset File",
    hp_heist_presets.cayo.options,
    hp_heist_presets.cayo.selected,
    function(opt)
        hp_heist_presets.cayo.selected = hp_find_option_index(hp_heist_presets.cayo.options, opt, 1)
    end
)
ui.button_pair(
    cayoPresetsGroup,
    "cayo_preset_save", "Save", function() hp_save_heist_preset("cayo") end,
    "cayo_preset_load", "Load", function() hp_load_heist_preset("cayo") end
)
ui.button_pair(
    cayoPresetsGroup,
    "cayo_preset_remove", "Remove", function() hp_remove_heist_preset("cayo") end,
    "cayo_preset_refresh", "Refresh", function() hp_refresh_heist_preset_files("cayo") end
)
ui.button(cayoPresetsGroup, "cayo_preset_copy", "Copy Folder Path", function() hp_copy_heist_preset_folder("cayo") end)
hp_update_preset_name_label("cayo")
hp_refresh_heist_preset_files("cayo")

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

local gCayoDanger = build_skip_cooldown_danger_group(
    heistTab,
    "cayo",
    "cayo_skip_heist_cooldown",
    function() cayo_remove_cooldown() end
)

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
    "cayo_tp_tunnel", "Underwater Tunnel", function() cayo_teleport_underwater_tunnel() end,
    "cayo_tp_center", "Center", function() cayo_teleport_center() end
)
ui.button_pair(
    gCayoTeleportOutside,
    "cayo_tp_gate_outside", "Gate", function() cayo_teleport_gate_outside() end,
    "cayo_tp_airport", "Airport", function() cayo_teleport_airport() end
)
ui.button(gCayoTeleportOutside, "cayo_tp_escape", "Escape", function() cayo_teleport_escape() end, nil, false, "green")

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

-- Cuts storage (defined before do blocks so they're accessible everywhere)
local DoomsdayCutsValues = {
    player1 = 100,
    player2 = 100,
    player3 = 100,
    player4 = 100,
}

ApartmentCutsValues = {
    player1 = 100,
    player2 = 0,
    player3 = 0,
    player4 = 0
}

-- Teleport constants and helper function (defined before do blocks for accessibility)
local TELEPORT_COORDS_MAZEBANK = {x = -75.146, y = -818.687, z = 326.175}
local BLIP_SPRITES_FACILITY = 590
local BLIP_SPRITES_APARTMENT = 40
local BLIP_SPRITES_HEIST = 428

local function get_blip_coords(blip_sprite)
    local blip = invoker.call(0x1BEDE233E6CD2A1F, blip_sprite) -- GET_FIRST_BLIP_INFO_ID
    if not blip or not blip.int or blip.int == 0 then
        return nil
    end
    
    local blip_handle = blip.int
    while blip_handle and blip_handle ~= 0 do
        local exists = invoker.call(0xA6DB27D19ECBB7DA, blip_handle) -- DOES_BLIP_EXIST
        if exists and exists.bool then
            local color = invoker.call(0xDF729E8D20CF7327, blip_handle) -- GET_BLIP_COLOUR
            if not color or color.int ~= 3 then
                -- GET_BLIP_COORDS - returns scr_vec3
                local coords = invoker.call(0x586AFE3FF72D996E, blip_handle) -- GET_BLIP_COORDS
                if coords and coords.scr_vec3 then
                    return {x = coords.scr_vec3.x, y = coords.scr_vec3.y, z = coords.scr_vec3.z + 1.0}
                end
            end
        end
        local next_blip = invoker.call(0x14F96AA50D6FBEA7, blip_sprite) -- GET_NEXT_BLIP_INFO_ID
        if next_blip and next_blip.int and next_blip.int ~= blip_handle then
            blip_handle = next_blip.int
        else
            break
        end
    end
    return nil
end

-- Apartment Tab Content (wrapped in do...end to reduce local variable count)
do
local gApartmentInfo = ui.group(heistTab, "Info", nil, nil, nil, 160, "apartment")
ui.label(gApartmentInfo, "Apartment Heist", config.colors.accent)
ui.label(gApartmentInfo, "Max transaction: $3,000,000", config.colors.text_main)
ui.label(gApartmentInfo, "Transaction cooldown: 3 min", config.colors.text_sec)
ui.label(gApartmentInfo, "15M possible (Criminal Mastermind)", config.colors.text_sec)
ui.label(gApartmentInfo, "Heist cooldown: unknown", config.colors.text_sec)

local gApartmentLaunch = ui.group(heistTab, "Launch", nil, nil, nil, nil, "apartment")
apartmentSoloLaunchToggle = ui.toggle(gApartmentLaunch, "apartment_launch_solo", "Solo Launch", state.solo_launch.apartment, function(val)
    state.solo_launch.apartment = val
end)
ui.button(gApartmentLaunch, "apartment_force_ready", "Force Ready", function() apartment_force_ready() end)
ui.button(gApartmentLaunch, "apartment_redraw_board", "Redraw Board", function() apartment_redraw_board() end)

local gApartmentPreps = ui.group(heistTab, "Preps", nil, nil, nil, nil, "apartment")
ui.button(gApartmentPreps, "apartment_complete_preps", "Complete Preps", function() apartment_complete_preps() end)
ui.button(gApartmentPreps, "apartment_change_session", "Change Session", function() apartment_change_session() end)

local apartmentPresetsGroup = ui.group(heistTab, "Presets (JSON)", nil, nil, nil, nil, "apartment")
hp_heist_presets.apartment.name_label = ui.label(apartmentPresetsGroup, "Name: QuickPreset", config.colors.text_sec)
ui.button(apartmentPresetsGroup, "apartment_preset_set_name", "Set Name From Keyboard", function()
    hp_open_heist_preset_name_keyboard("apartment")
end)
ui.button(apartmentPresetsGroup, "apartment_preset_name_clip", "Set Name From Clipboard", function()
    local clip = input.get_clipboard_text()
    local clean = hp_sanitize_preset_name(clip)
    if clean == "" then
        if notify then notify.push("Heist Presets", "Clipboard is empty/invalid", 2000) end
        return
    end
    hp_heist_presets.apartment.name = clean
    hp_update_preset_name_label("apartment")
    if notify then notify.push("Heist Presets", "Name set: " .. clean, 2000) end
end)
hp_heist_presets.apartment.dropdown = ui.dropdown(
    apartmentPresetsGroup,
    "apartment_preset_file",
    "Preset File",
    hp_heist_presets.apartment.options,
    hp_heist_presets.apartment.selected,
    function(opt)
        hp_heist_presets.apartment.selected = hp_find_option_index(hp_heist_presets.apartment.options, opt, 1)
    end
)
ui.button_pair(
    apartmentPresetsGroup,
    "apartment_preset_save", "Save", function() hp_save_heist_preset("apartment") end,
    "apartment_preset_load", "Load", function() hp_load_heist_preset("apartment") end
)
ui.button_pair(
    apartmentPresetsGroup,
    "apartment_preset_remove", "Remove", function() hp_remove_heist_preset("apartment") end,
    "apartment_preset_refresh", "Refresh", function() hp_refresh_heist_preset_files("apartment") end
)
ui.button(apartmentPresetsGroup, "apartment_preset_copy", "Copy Folder Path", function() hp_copy_heist_preset_folder("apartment") end)
hp_update_preset_name_label("apartment")
hp_refresh_heist_preset_files("apartment")

local function apartment_fleeca_hack()
    if script.running("fm_mission_controller") then
        script.locals("fm_mission_controller", 12223 + 24).int32 = 7
        if notify then notify.push("Apartment Tools", "Fleeca Hack Completed", 2000) end
    else
        if notify then notify.push("Apartment Tools", "Hack Not Active", 2000) end
    end
end

local function apartment_fleeca_drill()
    if script.running("fm_mission_controller") then
        script.locals("fm_mission_controller", 10511 + 11).float = 100.0
        if notify then notify.push("Apartment Tools", "Fleeca Drill Completed", 2000) end
    else
        if notify then notify.push("Apartment Tools", "Drill Not Active", 2000) end
    end
end

local function apartment_pacific_hack()
    if script.running("fm_mission_controller") then
        script.locals("fm_mission_controller", 10217).int32 = 9
        if notify then notify.push("Apartment Tools", "Pacific Hack Completed", 2000) end
    else
        if notify then notify.push("Apartment Tools", "Hack Not Active", 2000) end
    end
end

-- Instant Finish (Pacific Standard)
local function apartment_instant_finish_pacific()
    if script.force_host("fm_mission_controller") then
        util.yield(1000)
        script.locals("fm_mission_controller", 21457).int32 = 5
        script.locals("fm_mission_controller", 22136).int32 = 80
        script.locals("fm_mission_controller", 23081).int32 = 10000000
        script.locals("fm_mission_controller", 29017).int32 = 99999
        script.locals("fm_mission_controller", 32541).int32 = 99999
        if notify then notify.push("Apartment", "Instant Finish (Pacific Standard)", 2000) end
    else
        if notify then notify.push("Apartment", "Failed to force host", 2000) end
    end
end

-- Instant Finish (Other Classics)
local function apartment_instant_finish_other()
    if script.force_host("fm_mission_controller") then
        util.yield(1000)
        script.locals("fm_mission_controller", 20395).int32 = 12
        script.locals("fm_mission_controller", 23081).int32 = 99999
        script.locals("fm_mission_controller", 29017).int32 = 99999
        script.locals("fm_mission_controller", 32541).int32 = 99999
        if notify then notify.push("Apartment", "Instant Finish (Other Classics)", 2000) end
    else
        if notify then notify.push("Apartment", "Failed to force host", 2000) end
    end
end

local function apartment_play_unavailable()
    local player_id = (players and players.user and players.user()) or 0
    local cooldown_global = 1877303 + 1 + (player_id * 77) + 76
    script.globals(cooldown_global).int32 = -1
    if notify then notify.push("Apartment Tools", "Unavailable Jobs Now Playable", 2000) end
end

function apartment_change_session()
    local started = false

    local result = invoker.call(0xED34C0C02C098BB7, 0, 32) -- NETWORK_SESSION_HOST_CLOSED
    if result and result.bool then
        started = true
    else
        local fallback = invoker.call(0x6F3D4ED9BEE4E61D, 0, 32, true) -- NETWORK_SESSION_HOST
        started = (fallback and fallback.bool) and true or false
    end

    if started then
        if notify then notify.push("Apartment Tools", "Started invite-only session", 2000) end
    else
        if notify then notify.push("Apartment Tools", "Could not change session. Please change manually.", 2800) end
    end

    return started
end

local function apartment_unlock_all_jobs()
    local p = GetMP()
    local function hash_text(text)
        if type(joaat) == "function" then
            return joaat(text)
        end
        local hashed = invoker.call(0xD24D37CC275948CC, text) -- GET_HASH_KEY
        return (hashed and hashed.int) or 0
    end

    local root_hashes = {
        hash_text("33TxqLipLUintwlU_YDzMg"),
        hash_text("A6UBSyF61kiveglc58lm2Q"),
        hash_text("a_hWnpMUz0-7Yd_Rc5pJ4w"),
        hash_text("7r5AKL5aB0qe9HiDy3nW8w"),
        hash_text("hKSf9RCT8UiaZlykyGrMwg")
    }

    for i = 0, 4 do
        account.stats(p .. "HEIST_SAVED_STRAND_" .. i).int32 = root_hashes[i + 1]
        account.stats(p .. "HEIST_SAVED_STRAND_" .. i .. "_L").int32 = 5
    end

    script.globals(ApartmentGlobals.Board).int32 = 22
    if notify then notify.push("Apartment Tools", "All Jobs Unlocked. Change session to apply.", 2600) end
end

local function apartment_teleport_to_entrance()
    local me = players.me()
    if not me then
        if notify then notify.push("Teleport", "Player not found", 2000) end
        return false
    end
    
    util.create_job(function()
        local ped = me.ped
        local veh = me.vehicle
        local entity = (veh and veh ~= 0) and veh or ped
        
        -- Freeze entity position
        invoker.call(0x428CA6DBD1094446, entity, true) -- FREEZE_ENTITY_POSITION
        
        -- Smart relay: Transit via outdoor safe point if in interior
        if me.in_interior then
            local transit_point = {x = -75.146, y = -818.687, z = 326.175} -- MAZEBANK
            invoker.call(0x239A3351AC1DA385, entity, transit_point.x, transit_point.y, transit_point.z, false, false, false) -- SET_ENTITY_COORDS_NO_OFFSET
            util.yield(800)
        end
        
        local BLIP_SPRITES_APARTMENT = 40
        local coords = get_blip_coords(BLIP_SPRITES_APARTMENT)
        if coords then
            invoker.call(0x239A3351AC1DA385, entity, coords.x, coords.y, coords.z, false, false, false) -- SET_ENTITY_COORDS_NO_OFFSET
            util.yield(500)
            if notify then notify.push("Teleport", "Teleported to Entrance", 2000) end
        else
            if notify then notify.push("Teleport", "Entrance blip not found", 2000) end
        end
        
        -- Unfreeze entity position
        invoker.call(0x428CA6DBD1094446, entity, false) -- FREEZE_ENTITY_POSITION
    end)
    return true
end

local function apartment_teleport_to_heist_board()
    local me = players.me()
    if not me then
        if notify then notify.push("Teleport", "Player not found", 2000) end
        return false
    end
    
    util.create_job(function()
        local ped = me.ped
        local veh = me.vehicle
        local entity = (veh and veh ~= 0) and veh or ped
        
        -- Freeze entity position
        invoker.call(0x428CA6DBD1094446, entity, true) -- FREEZE_ENTITY_POSITION
        
        local BLIP_SPRITES_HEIST = 428
        local coords = get_blip_coords(BLIP_SPRITES_HEIST)
        if coords then
            invoker.call(0x239A3351AC1DA385, entity, coords.x, coords.y, coords.z, false, false, false) -- SET_ENTITY_COORDS_NO_OFFSET
            invoker.call(0x8E2530AA8ADA980E, entity, 173.376) -- SET_ENTITY_HEADING
            util.yield(500)
            if notify then notify.push("Teleport", "Teleported to Heist Board", 2000) end
        else
            if notify then notify.push("Teleport", "Heist board blip not found (enter property first)", 2000) end
        end
        
        -- Unfreeze entity position
        invoker.call(0x428CA6DBD1094446, entity, false) -- FREEZE_ENTITY_POSITION
    end)
    return true
end

local gApartmentTools = ui.group(heistTab, "Tools", nil, nil, nil, nil, "apartment")
ui.button_pair(
    gApartmentTools,
    "apartment_fleeca_hack", "Fleeca Hack", function() apartment_fleeca_hack() end,
    "apartment_fleeca_drill", "Fleeca Drill", function() apartment_fleeca_drill() end
)
ui.button_pair(
    gApartmentTools,
    "apartment_pacific_hack", "Pacific Hack", function() apartment_pacific_hack() end,
    "apartment_play_unavailable", "Play Unavailable", function() apartment_play_unavailable() end
)
ui.button_pair(
    gApartmentTools,
    "apartment_unlock_all", "Unlock All Jobs", function() apartment_unlock_all_jobs() end,
    "apartment_skip_cutscene", "Skip Cutscene", function() heist_skip_cutscene("Apartment") end
)

local gApartmentInstantFinish = ui.group(heistTab, "Instant Finish", nil, nil, nil, nil, "apartment")
ui.button(gApartmentInstantFinish, "apartment_instant_finish_pacific", "Instant Finish (Pacific Standard)", function() apartment_instant_finish_pacific() end)
ui.button(gApartmentInstantFinish, "apartment_instant_finish_other", "Instant Finish (Other)", function() apartment_instant_finish_other() end)

local gApartmentTeleport = ui.group(heistTab, "Teleport", nil, nil, nil, nil, "apartment")
ui.button(gApartmentTeleport, "apartment_tp_entrance", "Teleport to Entrance", function() apartment_teleport_to_entrance() end)
ui.button(gApartmentTeleport, "apartment_tp_heist_board", "Teleport to Heist Board", function() apartment_teleport_to_heist_board() end)

local gApartmentDanger = build_skip_cooldown_danger_group(
    heistTab,
    "apartment",
    "apartment_skip_heist_cooldown",
    function() apartment_kill_cooldown() end
)

-- Apply Apartment Cuts
function apply_apartment_cuts()
    local base_global = 1936013
    local base_local = 1937981
    local total_cut = ApartmentCutsValues.player1 + ApartmentCutsValues.player2 + ApartmentCutsValues.player3 + ApartmentCutsValues.player4
    
    -- Calculate over_cap - if total > 100, we need to compensate
    local over_cap = total_cut - 100
    if over_cap > 0 then 
        script.globals(base_global + 1 + 1).int32 = -over_cap 
    else 
        script.globals(base_global + 1 + 1).int32 = 0 
    end
    
    -- Set globals for players 2, 3, 4
    script.globals(base_global + 1 + 2).int32 = ApartmentCutsValues.player2
    script.globals(base_global + 1 + 3).int32 = ApartmentCutsValues.player3
    script.globals(base_global + 1 + 4).int32 = ApartmentCutsValues.player4
    
    -- Set locals for ALL players (critical fix!)
    script.globals(base_local + 3008 + 1).int32 = ApartmentCutsValues.player1
    script.globals(base_local + 3008 + 2).int32 = ApartmentCutsValues.player2
    script.globals(base_local + 3008 + 3).int32 = ApartmentCutsValues.player3
    script.globals(base_local + 3008 + 4).int32 = ApartmentCutsValues.player4
    
    if notify then notify.push("Apartment Cuts", "Cuts Applied!", 2000) end
end

local gApartmentCuts = ui.group(heistTab, "Cuts", nil, nil, nil, nil, "apartment")
apartmentP1SliderRef = ui.slider(gApartmentCuts, "apartment_cut_p1", "Host Cut %", 0, 300, ApartmentCutsValues.player1, function(val)
    ApartmentCutsValues.player1 = math.floor(val)
end, nil, 10)
apartmentP2SliderRef = ui.slider(gApartmentCuts, "apartment_cut_p2", "Player 2 Cut %", 0, 300, ApartmentCutsValues.player2, function(val)
    ApartmentCutsValues.player2 = math.floor(val)
end, nil, 10)
apartmentP3SliderRef = ui.slider(gApartmentCuts, "apartment_cut_p3", "Player 3 Cut %", 0, 300, ApartmentCutsValues.player3, function(val)
    ApartmentCutsValues.player3 = math.floor(val)
end, nil, 10)
apartmentP4SliderRef = ui.slider(gApartmentCuts, "apartment_cut_p4", "Player 4 Cut %", 0, 300, ApartmentCutsValues.player4, function(val)
    ApartmentCutsValues.player4 = math.floor(val)
end, nil, 10)

local apartmentCutPresetNames = hp_options_to_names(APARTMENT_CUT_PRESET_OPTIONS)
apartmentPresetDropdownRef = ui.dropdown(
    gApartmentCuts,
    "apartment_cut_preset",
    "Preset",
    apartmentCutPresetNames,
    apartment_cut_preset_index,
    function(opt)
        apartment_cut_preset_index = hp_find_option_index(apartmentCutPresetNames, opt, apartment_cut_preset_index)
    end
)

apartmentMaxPayoutToggleRef = ui.toggle(gApartmentCuts, "apartment_max_payout", "3mil Payout", apartment_max_payout_enabled, function(val)
    apartment_max_payout_enabled = val
    if val then
        if not hp_refresh_apartment_max_payout(true, false) then
            if notify then notify.push("Apartment Cuts", "Unknown heist. Load an Apartment finale first.", 2400) end
        end
    end
end)

apartmentDoubleToggleRef = ui.toggle(gApartmentCuts, "apartment_double_rewards", "Double Rewards Week", apartment_double_rewards_week, function(val)
    apartment_double_rewards_week = val
    if apartment_max_payout_enabled then
        hp_refresh_apartment_max_payout(true, false)
    end
end)

ui.button_pair(
    gApartmentCuts,
    "apartment_apply_selected_preset", "Apply Selected Preset", function()
        hp_apply_selected_apartment_cut_preset(true)
    end,
    "apartment_cuts_max_instant", "Apply Preset (Max Payout)", function()
        local cut = hp_get_apartment_max_payout_cut(apartment_double_rewards_week)
        if not cut then
            if notify then notify.push("Apartment Cuts", "Unknown heist. Load an Apartment finale first.", 2400) end
            return
        end
        hp_set_apartment_uniform_cuts(cut, true)
    end
)
ui.button(gApartmentCuts, "apartment_cuts_apply", "Apply Cuts", function() apply_apartment_cuts() end)

-- 12M Bonus Function 
function apartment_12mil_bonus(enable, silent)
    if enable then
        account.stats("MPPLY_HEISTFLOWORDERPROGRESS").int32 = 268435455
        account.stats("MPPLY_AWD_HST_ORDER").bool = false
        
        account.stats("MPPLY_HEISTTEAMPROGRESSBITSET").int32 = 268435455
        account.stats("MPPLY_AWD_HST_SAME_TEAM").bool = false
        
        account.stats("MPPLY_HEISTNODEATHPROGREITSET").int32 = 268435455
        account.stats("MPPLY_AWD_HST_ULT_CHAL").bool = false
        if not silent and notify then notify.push("Apartment Bonuses", "12M Bonus Enabled", 2000) end
    else
        account.stats("MPPLY_HEISTFLOWORDERPROGRESS").int32 = 134217727
        account.stats("MPPLY_AWD_HST_ORDER").bool = true
        
        account.stats("MPPLY_HEISTTEAMPROGRESSBITSET").int32 = 134217727
        account.stats("MPPLY_AWD_HST_SAME_TEAM").bool = true
        
        account.stats("MPPLY_HEISTNODEATHPROGREITSET").int32 = 134217727
        account.stats("MPPLY_AWD_HST_ULT_CHAL").bool = true
        if not silent and notify then notify.push("Apartment Bonuses", "12M Bonus Disabled", 2000) end
    end
    apartment_bonus_enabled = enable
    return true
end

-- Bonuses Group
local gApartmentBonuses = ui.group(heistTab, "Bonuses", nil, nil, nil, nil, "apartment")
apartmentBonusToggleRef = ui.toggle(gApartmentBonuses, "apartment_12m_bonus", "Enable 12M Bonus", apartment_bonus_enabled, function(val)
    apartment_12mil_bonus(val)
end)

end -- End Apartment Tab do block

-- -------------------------------------------------------------------------
-- [Doomsday Functions]
-- -------------------------------------------------------------------------

-- Doomsday section (wrapped in do...end to reduce local variable count)
do
local function doomsday_complete_preps(act)
    local prefix0 = "MP0_"
    local prefix1 = "MP1_"
    
    local flow, status, notifications
    
    if act == 1 then
        -- Act I: The Data Breaches
        flow = 503
        status = -229383
        notifications = 1557
    elseif act == 2 then
        -- Act II: The Bogdan Problem
        flow = 240
        status = -229378
        notifications = 1557
    elseif act == 3 then
        -- Act III: The Doomsday Scenario
        flow = 16368
        status = -229380
        notifications = 1557
    else
        if notify then notify.push("Doomsday", "Invalid Act", 2000) end
        return false
    end
    
    account.stats(prefix0 .. "GANGOPS_FLOW_MISSION_PROG").int32 = flow
    account.stats(prefix1 .. "GANGOPS_FLOW_MISSION_PROG").int32 = flow
    account.stats(prefix0 .. "GANGOPS_HEIST_STATUS").int32 = status
    account.stats(prefix1 .. "GANGOPS_HEIST_STATUS").int32 = status
    account.stats(prefix0 .. "GANGOPS_FLOW_NOTIFICATIONS").int32 = notifications
    account.stats(prefix1 .. "GANGOPS_FLOW_NOTIFICATIONS").int32 = notifications
    
    -- Reload board
    script.locals("gb_gang_ops_planning", 211).int32 = 6
    
    if notify then notify.push("Doomsday", "Preps Completed", 2000) end
    return true
end

local function doomsday_reset_progress()
    local prefix0 = "MP0_"
    local prefix1 = "MP1_"
    
    account.stats(prefix0 .. "GANGOPS_FLOW_MISSION_PROG").int32 = 503
    account.stats(prefix1 .. "GANGOPS_FLOW_MISSION_PROG").int32 = 503
    account.stats(prefix0 .. "GANGOPS_HEIST_STATUS").int32 = 0
    account.stats(prefix1 .. "GANGOPS_HEIST_STATUS").int32 = 0
    account.stats(prefix0 .. "GANGOPS_FLOW_NOTIFICATIONS").int32 = 1557
    account.stats(prefix1 .. "GANGOPS_FLOW_NOTIFICATIONS").int32 = 1557
    
    -- Reload board
    script.locals("gb_gang_ops_planning", 211).int32 = 6
    
    if notify then notify.push("Doomsday", "Progress Reset", 2000) end
end

local function doomsday_reset_preps()
    local prefix0 = "MP0_"
    local prefix1 = "MP1_"
    
    account.stats(prefix0 .. "GANGOPS_FLOW_MISSION_PROG").int32 = 0
    account.stats(prefix1 .. "GANGOPS_FLOW_MISSION_PROG").int32 = 0
    account.stats(prefix0 .. "GANGOPS_HEIST_STATUS").int32 = 0
    account.stats(prefix1 .. "GANGOPS_HEIST_STATUS").int32 = 0
    account.stats(prefix0 .. "GANGOPS_FLOW_NOTIFICATIONS").int32 = 0
    account.stats(prefix1 .. "GANGOPS_FLOW_NOTIFICATIONS").int32 = 0
    
    if script.running("gb_gang_ops_planning") then
        script.locals("gb_gang_ops_planning", 211).int32 = 6
    end
    
    if notify then notify.push("Doomsday", "Preps Reset", 2000) end
end

local function doomsday_reload_board()
    if script.running("gb_gang_ops_planning") then
        script.locals("gb_gang_ops_planning", 211).int32 = 6
        if notify then notify.push("Doomsday", "Board Redrawn", 2000) end
        return true
    else
        if notify then notify.push("Doomsday", "Not in Facility", 2000) end
        return false
    end
end

-- Doomsday Teleportation
local function doomsday_teleport_to_entrance()
    local me = players.me()
    if not me then
        if notify then notify.push("Teleport", "Player not found", 2000) end
        return false
    end

    util.create_job(function()
        local ped = me.ped
        local veh = me.vehicle
        local entity = (veh and veh ~= 0) and veh or ped

        -- Freeze entity position
        invoker.call(0x428CA6DBD1094446, entity, true) -- FREEZE_ENTITY_POSITION

        -- Smart relay: Transit via outdoor safe point if in interior
        if me.in_interior then
            invoker.call(0x239A3351AC1DA385, entity, TELEPORT_COORDS_MAZEBANK.x, TELEPORT_COORDS_MAZEBANK.y, TELEPORT_COORDS_MAZEBANK.z, false, false, false) -- SET_ENTITY_COORDS_NO_OFFSET
            util.yield(800)
        end

        local coords = get_blip_coords(BLIP_SPRITES_FACILITY)
        if coords then
            invoker.call(0x239A3351AC1DA385, entity, coords.x, coords.y, coords.z, false, false, false) -- SET_ENTITY_COORDS_NO_OFFSET
            util.yield(500)
            if notify then notify.push("Teleport", "Teleported to Facility", 2000) end
        else
            if notify then notify.push("Teleport", "Facility blip not found", 2000) end
        end

        -- Unfreeze entity position
        invoker.call(0x428CA6DBD1094446, entity, false) -- FREEZE_ENTITY_POSITION
    end)
    return true
end

local function doomsday_teleport_to_screen()
    local me = players.me()
    if not me then
        if notify then notify.push("Teleport", "Player not found", 2000) end
        return false
    end

    util.create_job(function()
        local ped = me.ped
        local veh = me.vehicle
        local entity = (veh and veh ~= 0) and veh or ped

        -- Freeze entity position
        invoker.call(0x428CA6DBD1094446, entity, true) -- FREEZE_ENTITY_POSITION

        local coords = get_blip_coords(BLIP_SPRITES_HEIST)
        if coords then
            invoker.call(0x239A3351AC1DA385, entity, coords.x, coords.y, coords.z, false, false, false) -- SET_ENTITY_COORDS_NO_OFFSET
            invoker.call(0x8E2530AA8ADA980E, entity, 325.726) -- SET_ENTITY_HEADING (Doomsday screen heading)
            util.yield(500)
            if notify then notify.push("Teleport", "Teleported to Doomsday Screen", 2000) end
        else
            if notify then notify.push("Teleport", "Heist board blip not found (enter Facility first)", 2000) end
        end

        -- Unfreeze entity position
        invoker.call(0x428CA6DBD1094446, entity, false) -- FREEZE_ENTITY_POSITION
    end)
    return true
end

-- Doomsday Tab Content
local gDoomsdayInfo = ui.group(heistTab, "Info", nil, nil, nil, 160, "doomsday")
ui.label(gDoomsdayInfo, "Doomsday Heist", config.colors.accent)
ui.label(gDoomsdayInfo, "Max transaction: $2,550,000", config.colors.text_main)
ui.label(gDoomsdayInfo, "Transaction cooldown: 30 min", config.colors.text_sec)
ui.label(gDoomsdayInfo, "2 transactions in 30 min possible", config.colors.text_sec)
ui.label(gDoomsdayInfo, "Heist cooldown: unknown", config.colors.text_sec)

local gDoomsdayPreps = ui.group(heistTab, "Prep Presets", nil, nil, nil, nil, "doomsday")

ui.button(gDoomsdayPreps, "doomsday_preset_act1", "Preset Act I: The Data Breaches", function()
    doomsday_complete_preps(1)
end)
ui.button(gDoomsdayPreps, "doomsday_preset_act2", "Preset Act II: The Bogdan Problem", function()
    doomsday_complete_preps(2)
end)
ui.button(gDoomsdayPreps, "doomsday_preset_act3", "Preset Act III: The Doomsday Scenario", function()
    doomsday_complete_preps(3)
end)
ui.button(gDoomsdayPreps, "doomsday_reset", "Reset Doomsday Heist", function()
    doomsday_reset_progress()
end)

-- Doomsday Launch group
local gDoomsdayLaunch = ui.group(heistTab, "Launch", nil, nil, nil, nil, "doomsday")
ui.toggle(gDoomsdayLaunch, "doomsday_launch_solo", "Solo Launch", state.solo_launch.doomsday, function(val)
    state.solo_launch.doomsday = val
end)
ui.button(gDoomsdayLaunch, "doomsday_launch_force_ready", "Force Ready", function()
    doomsday_force_ready()
end)

-- Doomsday Teleport group
local gDoomsdayTeleport = ui.group(heistTab, "Teleport", nil, nil, nil, nil, "doomsday")
ui.button_pair(
    gDoomsdayTeleport,
    "doomsday_teleport_entrance", "Teleport to Entrance", function()
        doomsday_teleport_to_entrance()
    end,
    "doomsday_teleport_screen", "Teleport to Screen", function()
        doomsday_teleport_to_screen()
    end
)

local function apply_doomsday_cuts(cuts)
    if not cuts then return false end

    script.globals(1969406).int32 = cuts[1] or 100
    script.globals(1969407).int32 = cuts[2] or 100
    script.globals(1969408).int32 = cuts[3] or 100
    script.globals(1969409).int32 = cuts[4] or 100

    if notify then notify.push("Doomsday Cuts", "Cuts Applied", 2000) end
    return true
end

local function hp_get_doomsday_max_payout_cut()
    local p = GetMP()
    local heist = account.stats(p .. "GANGOPS_FLOW_MISSION_PROG").int32 or 503
    local difficulty_raw = script.globals(4718592 + 3538).int32 -- Heist.Generic.Difficulty
    local difficulty = 1

    -- Support both observed encodings:
    -- 0/1 = Normal/Hard and 1/2 = Normal/Hard
    if difficulty_raw ~= nil then
        if difficulty_raw <= 1 then
            difficulty = difficulty_raw + 1
        else
            difficulty = difficulty_raw
        end
    end

    if difficulty < 1 then difficulty = 1 end
    if difficulty > 2 then difficulty = 2 end

    local payouts = {
        [503] = { 975000, 1218750 },   -- Act I: Data Breaches
        [240] = { 1425000, 1771250 },  -- Act II: Bogdan Problem
        [16368] = { 1800000, 2250000 } -- Act III: Doomsday Scenario
    }

    local payout_by_heist = payouts[heist] or payouts[503]
    local payout = payout_by_heist[difficulty] or payout_by_heist[1]
    local cut = math.floor(SAFE_PAYOUT_TARGETS.doomsday / (payout / 100))
    return hp_clamp_cut_percent(cut)
end

local gDoomsdayCuts = ui.group(heistTab, "Cuts", nil, nil, nil, nil, "doomsday")
local doomsdayP1Slider = ui.slider(gDoomsdayCuts, "doomsday_cut_p1", "Player 1", 0, 300, DoomsdayCutsValues.player1, function(val)
    DoomsdayCutsValues.player1 = math.floor(val)
end, nil, 10)
local doomsdayP2Slider = ui.slider(gDoomsdayCuts, "doomsday_cut_p2", "Player 2", 0, 300, DoomsdayCutsValues.player2, function(val)
    DoomsdayCutsValues.player2 = math.floor(val)
end, nil, 10)
local doomsdayP3Slider = ui.slider(gDoomsdayCuts, "doomsday_cut_p3", "Player 3", 0, 300, DoomsdayCutsValues.player3, function(val)
    DoomsdayCutsValues.player3 = math.floor(val)
end, nil, 10)
local doomsdayP4Slider = ui.slider(gDoomsdayCuts, "doomsday_cut_p4", "Player 4", 0, 300, DoomsdayCutsValues.player4, function(val)
    DoomsdayCutsValues.player4 = math.floor(val)
end, nil, 10)

-- Preset row
ui.button_pair(
    gDoomsdayCuts,
    "doomsday_preset_apply", "Apply Preset (100%)", function()
        hp_set_uniform_cuts(
            DoomsdayCutsValues,
            { "player1", "player2", "player3", "player4" },
            { doomsdayP1Slider, doomsdayP2Slider, doomsdayP3Slider, doomsdayP4Slider },
            100
        )
    end,
    "doomsday_preset_max_instant", "Apply Preset (Max Payout)", function()
        hp_set_uniform_cuts(
            DoomsdayCutsValues,
            { "player1", "player2", "player3", "player4" },
            { doomsdayP1Slider, doomsdayP2Slider, doomsdayP3Slider, doomsdayP4Slider },
            hp_get_doomsday_max_payout_cut()
        )
    end
)

ui.button(gDoomsdayCuts, "doomsday_cuts_apply", "Apply Cuts", function()
    apply_doomsday_cuts({
        DoomsdayCutsValues.player1,
        DoomsdayCutsValues.player2,
        DoomsdayCutsValues.player3,
        DoomsdayCutsValues.player4
    })
end)

local function doomsday_data_hack()
    if script.running("fm_mission_controller") then
        script.locals("fm_mission_controller", 1541).int32 = 2
        if notify then notify.push("Doomsday Tools", "Data hack completed", 2000) end
        return true
    else
        if notify then notify.push("Doomsday Tools", "Hack not active", 2000) end
        return false
    end
end

local function doomsday_doomsday_hack()
    if script.running("fm_mission_controller") then
        script.locals("fm_mission_controller", 1298 + 135).int32 = 3
        if notify then notify.push("Doomsday Tools", "Doomsday hack completed", 2000) end
        return true
    else
        if notify then notify.push("Doomsday Tools", "Hack not active", 2000) end
        return false
    end
end

-- Instant Finish
local function doomsday_instant_finish()
    if script.force_host("fm_mission_controller") then
        util.yield(1000)
        script.locals("fm_mission_controller", 20395).int32 = 12
        script.locals("fm_mission_controller", 22136).int32 = 150
        script.locals("fm_mission_controller", 29017).int32 = 99999
        script.locals("fm_mission_controller", 32541).int32 = 99999
        script.locals("fm_mission_controller", 32569).int32 = 80
    end
end

local gDoomsdayTools = ui.group(heistTab, "Tools", nil, nil, nil, nil, "doomsday")
ui.button_pair(
    gDoomsdayTools,
    "doomsday_data_hack", "Data Hack", function()
        doomsday_data_hack()
    end,
    "doomsday_doomsday_hack", "Doomsday Hack", function()
        doomsday_doomsday_hack()
    end
)
ui.button_pair(
    gDoomsdayTools,
    "doomsday_instant_finish", "Instant Finish", function()
        doomsday_instant_finish()
    end,
    "doomsday_skip_cutscene", "Skip Cutscene", function() heist_skip_cutscene("Doomsday") end
)
end -- End Doomsday section do block

-- -------------------------------------------------------------------------
-- [Cluckin Bell Farm Raid] - 1:1 from HeistTool.lua
-- -------------------------------------------------------------------------

-- Cluckin Bell Functions
local function cluckin_skip_to_finale()
    account.stats("MP0_SALV23_INST_PROG").int32 = 31
    account.stats("MP1_SALV23_INST_PROG").int32 = 31
    
    local other_stats = { "SALV23_GEN_BS", "SALV23_SCOPE_BS", "SALV23_FM_PROG" }
    for _, stat in ipairs(other_stats) do
        account.stats("MP0_" .. stat).int32 = -1
        account.stats("MP1_" .. stat).int32 = -1
    end
end

local function cluckin_remove_cooldown()
    account.stats("MP0_SALV23_CFR_COOLDOWN").int32 = -1
    account.stats("MP1_SALV23_CFR_COOLDOWN").int32 = -1
    if notify then notify.push("Cluckin Bell", "Cooldown Removed", 2000) end
end

local function cluckin_reset_progress()
    account.stats("MP0_SALV23_INST_PROG").int32 = 0
    account.stats("MP1_SALV23_INST_PROG").int32 = 0
end

local function cluckin_instant_finish()
    local action_taken = false

    if script.running("circuitblockhack") then
        script.locals("circuitblockhack", 62).int32 = 2
        action_taken = true
    end

    if script.running("word_hack") then
        script.locals("word_hack", 106).int32 = 5
        action_taken = true
    end

    if not action_taken and script.running("fm_mission_controller_2020") then
        local base = 56223
        local cash_take_offset = 55173
        script.locals("fm_mission_controller_2020", cash_take_offset).int32 = 4000000
        script.locals("fm_mission_controller_2020", base + 1777).int32 = 999999
        script.locals("fm_mission_controller_2020", base + 1062).int32 = 5
        script.locals("fm_mission_controller_2020", 48794).int32 = script.locals("fm_mission_controller_2020", 48794).int32 | (1 << 7)
        local win_flags = (1 << 9) | (1 << 10) | (1 << 11) | (1 << 12) | (1 << 16)
        script.locals("fm_mission_controller_2020", base + 1).int32 = script.locals("fm_mission_controller_2020", base + 1).int32 | win_flags
        action_taken = true
    end
end

-- Cluckin Bell Tab Content
local gCluckinInfo = ui.group(heistTab, "Info", nil, nil, nil, 140, "cluckin")
ui.label(gCluckinInfo, "Cluckin Bell Farm Raid", config.colors.accent)
ui.label(gCluckinInfo, "Farm Raid Heist", config.colors.text_main)

local gCluckinTools = ui.group(heistTab, "Tools", nil, nil, nil, nil, "cluckin")
ui.button_pair(
    gCluckinTools,
    "cluckin_skip_finale", "Skip to Finale", function()
        cluckin_skip_to_finale()
    end,
    "cluckin_remove_cooldown", "Remove Cooldown", function()
        cluckin_remove_cooldown()
    end
)
ui.button_pair(
    gCluckinTools,
    "cluckin_reset_progress", "Reset Progress", function()
        cluckin_reset_progress()
    end,
    "cluckin_instant_finish", "Instant Finish", function()
        cluckin_instant_finish()
    end
)

-- ---------------------------------------------------------
-- 8. Loop
-- ---------------------------------------------------------

if events.event.scroll then
    events.subscribe(events.event.scroll, function(e)
        if not state.animation.open and state.animation.progress < 0.01 then return end
        local scroll_speed = 30
        local delta = e.offset * scroll_speed
        
        local m = input.mouse_position()
        local mx, my = m.x, m.y
        
        local win_x = state.window.x
        local win_y = state.window.y
        local menu_w = config.menu_width
        
        local bodyY_local = config.sidebar_gap
        local bodyY_abs = win_y + bodyY_local
        
        if my < bodyY_abs then return end -- Above menu

        if mx >= win_x and mx <= win_x + menu_w then
             if state.scroll.max_y > 0 then
                 state.scroll.y = state.scroll.y + delta
                 if state.scroll.y < 0 then state.scroll.y = 0 end
                 if state.scroll.y > state.scroll.max_y then state.scroll.y = state.scroll.max_y end
             end
        end
    end)
end

util.create_thread(function()
    while true do
        -- Solo Launch: Diamond Casino
        if state.solo_launch.casino then
            solo_launch_generic()
            solo_launch_casino_setup()
        elseif state.solo_launch_prev.casino then
            -- Just turned off, reset to normal
            solo_launch_reset_casino()
        end

        -- Solo Launch: Apartment Heist
        if state.solo_launch.apartment then
            solo_launch_generic()
        elseif state.solo_launch_prev.apartment then
            -- Just turned off, reset to normal
            solo_launch_reset_apartment()
        end

        -- Solo Launch: Doomsday
        if state.solo_launch.doomsday then
            solo_launch_generic()
        elseif state.solo_launch_prev.doomsday then
            -- Just turned off, reset to normal
            solo_launch_reset_doomsday()
        end

        hp_refresh_apartment_max_payout(false, false)
        hp_enforce_heist_toggles()
        
        -- Update previous state
        state.solo_launch_prev.casino = state.solo_launch.casino
        state.solo_launch_prev.apartment = state.solo_launch.apartment
        state.solo_launch_prev.doomsday = state.solo_launch.doomsday
        
        if input.key(84).just_pressed then -- T
            state.animation.open = not state.animation.open
            state.animation.target = state.animation.open and 1.0 or 0.0
            input.show_cursor(state.animation.open)
            -- Center cursor on screen when menu opens (with safety check)
            if state.animation.open then
                if native and native.set_cursor_position then
                    pcall(native.set_cursor_position, 0.5, 0.5)
                end
            end
        end
        
        if state.animation.open or state.animation.progress > 0.01 then
            ui.render()
        end

        if state.animation.open or state.animation.progress > 0.01 then
            -- Disable mouse controls (group 2)
            invoker.call(0x5F4B6931816E599B, 2)
            
            -- Disable player firing
            if players and players.user then
                local player_id = players.user()
                invoker.call(0x5E6CC07646BBEAB8, player_id, true)
            end
            
            -- Disable shooting and other actions
            disable_control_action(
                0, 1, 2, 3, 4, 5, 6, -- Movement
                24, 25, -- Attack (Left/Right Mouse)
                30, 31, 32, 33, 34, 35, -- Move
                37, -- Weapon Wheel
                44, 45, 47, 58, -- Cover
                59, 60, -- Veh Move
                71, 72, -- Veh Accel/Brake
                75, -- Veh Exit
                140, 141, 142, 143, -- Melee
                257, 258, 261, 262, 263, 264, 265, -- Attack variants
                266, 267, 268, -- More attack
                27 -- ESC
            )
        else
            -- Enable player firing
            if players and players.user then
                local player_id = players.user()
                invoker.call(0x5E6CC07646BBEAB8, player_id, false)
            end
        end
        
        util.yield(0)
    end
end)
