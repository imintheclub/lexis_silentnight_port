-- ============================================================================
-- ShillenLua - Modern UI Menu for GTA V
-- Version: 1.7.1
-- ============================================================================
--
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

    return {
        font_path = nil,

        font_scale_title = 26.0 * scale,
        font_scale_header = 18.0 * scale,
        font_scale_body = 16.0 * scale,
        font_scale_small = 14.0 * scale,

        origin_x = math.floor((game.resolution().x - 950 * scale) / 2),
        origin_y = math.floor((game.resolution().y - 600 * scale) / 2),
        menu_width = math.floor(950 * scale),
        menu_height = math.floor(600 * scale),

        sidebar_width = math.floor(100 * scale),
        sidebar_gap = math.floor(18 * scale),
        
        content_margin = math.floor(30 * scale),
        
        content_area = {
            x = 0, y = 0, w = 0, h = 0
        },

        item_height = {
            toggle = math.floor(42 * scale),
            button = math.floor(45 * scale),
            slider = math.floor(58 * scale),
            dropdown = math.floor(45 * scale),
            header_padding = math.floor(36 * scale)
        },

        scale = scale,

        -- Theme: Midnight Blue
        colors = {
            bg_main = { r = 12, g = 15, b = 25, a = 250 },      -- Deep midnight blue background
            bg_sidebar = { r = 15, g = 20, b = 35, a = 255 },   -- Sidebar background
            bg_panel = { r = 18, g = 25, b = 40, a = 255 },     -- Group Panel background
            
            accent = { r = 52, g = 152, b = 219, a = 255 },     -- Bright blue accent
            accent_dim = { r = 52, g = 152, b = 219, a = 80 },  -- Dim blue accent
            
            text_main = { r = 250, g = 250, b = 255, a = 255 },
            text_sec = { r = 180, g = 190, b = 210, a = 255 },
            text_dim = { r = 120, g = 130, b = 150, a = 220 },
            
            white = { r = 255, g = 255, b = 255, a = 255 },
            btn_hover = { r = 255, g = 255, b = 255, a = 15 },
            border = { r = 30, g = 45, b = 65, a = 255 },
            scroll_track = { r = 0, g = 0, b = 0, a = 0 } -- Invisible track
        }
    }
end

local config = init_config()


local body_offset = config.sidebar_gap
config.content_area.x = config.origin_x + config.sidebar_width + config.sidebar_gap
config.content_area.y = config.origin_y + body_offset
config.content_area.w = config.menu_width - config.sidebar_width - config.sidebar_gap
config.content_area.h = config.menu_height - body_offset
config.scrollbar = {
    x = config.origin_x + config.menu_width - math.floor(8 * config.scale),
    y = config.content_area.y + config.content_margin,
    w = math.floor(4 * config.scale),
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
    sidebar_scroll = { y = 0, max_y = 0 },
    window = { x = config.origin_x, y = config.origin_y, is_dragging = false, drag_offset = { x = 0, y = 0 } },
    animation = { open = false, progress = 0.0, target = 1.0, speed = 0.15 },
    active_tab_y = nil,
    particles = {},
    mouse = { x = 0, y = 0, down = false, clicked = false },
    heist_subtab = 1,  -- 1=Cayo, 2=Casino, 3=Apartment, 4=Doomsday, 5=Cluckin
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
    local anim_y_offset = (1.0 - state.animation.progress) * (30 * config.scale)
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
        render_rect(px, py, p.size, p.size, {r=255, g=255, b=255, a=p.alpha}, 1)
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

-- ---------------------------------------------------------
-- 4. Rendering Implementations
-- ---------------------------------------------------------

local function get_group_actual_height(group)
    local h = config.item_height.header_padding + math.floor(10 * config.scale)
    for _, item in ipairs(group.items) do
        if item.type == "toggle" then h = h + config.item_height.toggle
        elseif item.type == "button" then h = h + config.item_height.button
        elseif item.type == "slider" then h = h + config.item_height.slider
        elseif item.type == "dropdown" then h = h + config.item_height.dropdown
        elseif item.type == "label" then h = h + math.floor(25 * config.scale) end
    end
    return math.max(group.rect.h, h)
end

local function draw_toggle_item(item, x, y, w, original_y)
    local hitbox_h = config.item_height.toggle - 2
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

    local switchW = math.floor(42 * config.scale)
    local switchH = math.floor(22 * config.scale)
    local switchX = x + w - switchW - math.floor(18 * config.scale)
    local switchY = y + math.floor(8 * config.scale)

    local inactiveCol = {r=40, g=40, b=50, a=255}
    local activeCol = config.colors.accent
    
    local trackR = math.floor(inactiveCol.r + (activeCol.r - inactiveCol.r) * item.anim)
    local trackG = math.floor(inactiveCol.g + (activeCol.g - inactiveCol.g) * item.anim)
    local trackB = math.floor(inactiveCol.b + (activeCol.b - inactiveCol.b) * item.anim)
    
    render_rect(switchX, switchY, switchW, switchH, {r=trackR, g=trackG, b=trackB, a=255}, switchH/2)
    
    local thumbSize = math.floor(16 * config.scale)
    local thumbPadding = math.floor(3 * config.scale)
    local minX = switchX + thumbPadding
    local maxX = switchX + switchW - thumbSize - thumbPadding
    local thumbX = lerp(minX, maxX, item.anim)
    local thumbY = switchY + (switchH - thumbSize)/2
    
    render_rect(thumbX, thumbY, thumbSize, thumbSize, config.colors.white, thumbSize/2)

    -- Center text vertically with switch
    local textY = switchY + (switchH - config.font_scale_body)/2
    render_text(item.label, x + math.floor(15 * config.scale), textY, config.font_scale_body, config.colors.text_main)
end

local function draw_button_item(item, x, y, w, original_y)
    local btnH = config.item_height.button - math.floor(6 * config.scale)
    local btnW = w - math.floor(30 * config.scale)
    local btnX = x + math.floor(15 * config.scale)
    local btnY = y + math.floor(3 * config.scale)

    local hovered = is_hovered_content(btnX, original_y + 3, btnW, btnH)
    
    if hovered and state.mouse.clicked and not state.active_dropdown then
        if item.disabled then
            -- Show error message for disabled buttons
            if notify then notify.push("Error", "Instant Finish function has been disabled", 3000) end
        elseif item.onClick then
            item.onClick()
        end
        state.window.is_dragging = false  -- Prevent window dragging
    end

    -- Red color for disabled buttons, custom color for special buttons, normal colors for enabled
    local bgCol
    local textCol
    if item.disabled then
        bgCol = hovered and {r = 200, g = 50, b = 50, a = 255} or {r = 150, g = 30, b = 30, a = 255}
        textCol = hovered and config.colors.white or {r = 255, g = 200, b = 200, a = 255}
    elseif item.color == "green" then
        -- Green color for escape button
        bgCol = hovered and {r = 50, g = 200, b = 50, a = 255} or {r = 30, g = 150, b = 30, a = 255}
        textCol = config.colors.white
    else
        bgCol = hovered and config.colors.accent or config.colors.bg_sidebar
        textCol = hovered and config.colors.white or config.colors.text_main
    end
    
    render_rect(btnX, btnY, btnW, btnH, bgCol, 6)
    -- Center text both horizontally and vertically
    -- Approximate text height based on font scale (roughly 0.7 * scale for most fonts)
    local textHeight = config.font_scale_body * 0.7
    local textY = btnY + (btnH / 2) - (textHeight / 2)
    render_text(item.label, btnX + btnW / 2, textY, config.font_scale_body, textCol, "center")
end

local function draw_slider_item(item, x, y, w, original_y)
    local barW = w - math.floor(36 * config.scale)
    local barH = math.floor(4 * config.scale)
    local barX = x + math.floor(18 * config.scale)
    local barY = y + math.floor(32 * config.scale)

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

    render_text(item.label, x + math.floor(15 * config.scale), y + math.floor(5 * config.scale), config.font_scale_body, config.colors.text_main)
    -- Display integer value (no decimals)
    local displayValue = math.floor(item.value)
    render_text(tostring(displayValue), x + w - math.floor(15 * config.scale), y + math.floor(5 * config.scale), config.font_scale_body, config.colors.accent, "right")

    render_rect(barX, barY, barW, barH, config.colors.bg_sidebar, barH/2)
    
    local fillRatio = (item.value - item.min) / (item.max - item.min)
    if fillRatio > 0 then
        render_rect(barX, barY, barW * fillRatio, barH, config.colors.accent, barH/2)
    end
    
    local baseSize = 16
    local growSize = 6
    local thumbSize = math.floor((baseSize + growSize * item.anim) * config.scale)
    local thumbX = barX + (barW * fillRatio) - thumbSize/2
    local thumbY = barY - thumbSize/2 + barH/2
    
    if item.anim > 0.01 then
        local glowSize = thumbSize + math.floor(6 * config.scale * item.anim)
        local glowX = thumbX - (glowSize - thumbSize)/2
        local glowY = thumbY - (glowSize - thumbSize)/2
        local glowAlpha = math.floor(60 * item.anim)
        render_rect(glowX, glowY, glowSize, glowSize, {r=config.colors.accent.r, g=config.colors.accent.g, b=config.colors.accent.b, a=glowAlpha}, glowSize/2)
    end
    
    -- Main circle
    render_rect(thumbX, thumbY, thumbSize, thumbSize, config.colors.white, thumbSize/2)
end

local function draw_dropdown_item(item, x, y, w, original_y)
    local boxW = math.floor(180 * config.scale)
    local boxH = math.floor(36 * config.scale)
    local boxX = x + w - boxW - math.floor(18 * config.scale)
    local boxY = y + math.floor(6 * config.scale)
    
    local hovered = is_hovered_content(boxX, original_y + 5, boxW, boxH)

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

    render_text(item.label, x + math.floor(15 * config.scale), y + math.floor(8 * config.scale), config.font_scale_body, config.colors.text_main)
    
    render_rect(boxX, boxY, boxW, boxH, config.colors.bg_sidebar, 4)
    -- Center the selected option text in the dropdown box
    render_text(item.options[item.value] or "", boxX + boxW / 2, boxY + math.floor(6 * config.scale), config.font_scale_body, config.colors.text_sec, "center")
    
    -- Dropdown Arrow
    render_text("v", boxX + boxW - math.floor(15 * config.scale), boxY + math.floor(6 * config.scale), config.font_scale_small, config.colors.text_dim)

    if item.isOpen then
        return { item = item, x = boxX, y = boxY + boxH + 2, w = boxW }
    end
end

-- ---------------------------------------------------------
-- 5. Main Render Loop
-- ---------------------------------------------------------

ui.render = function()
    ensure_assets()
    update_input()

    -- Ensure currentTab is not hidden or set first visible tab
    if not ui.currentTab or ui.currentTab.hidden then
        for _, tab in ipairs(ui.tabs) do
            if not tab.hidden then
                ui.currentTab = tab
                break
            end
        end
    end

    -- Animation
    local diff = state.animation.target - state.animation.progress
    if math.abs(diff) > 0.001 then
        state.animation.progress = state.animation.progress + diff * state.animation.speed
    else
        state.animation.progress = state.animation.target
    end
    if state.animation.progress < 0.01 and state.animation.target == 0.0 then return end

    local ox, oy = get_win_offset()

    -- Fixed Height Calculation (independent of tabs count)
    -- Use fixed height from config instead of calculating from tabs
    local dynamicBodyH = config.menu_height - config.sidebar_gap
    
    -- No scroll needed for sidebar since tabs are centered
    state.sidebar_scroll.max_y = 0
    state.sidebar_scroll.y = 0
    
    config.content_area.h = dynamicBodyH

    -- No Title Bar - Menu starts from top
    manage_particles(config.menu_width, dynamicBodyH + config.sidebar_gap)

    -- Sidebar & Content Panel
    local bodyY = config.origin_y + config.sidebar_gap
    local bodyH = dynamicBodyH

    -- Window Dragging
    if state.mouse.clicked and not state.active_dropdown and not state.dragging_slider then
        local menuStartY = config.origin_y + config.sidebar_gap
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

    -- Tabs - centered (calculate first to get tab area)
    local tabH = math.floor(65 * config.scale)
    local tabSpacing = math.floor(6 * config.scale)
    
    -- Count visible tabs
    local numVisibleTabs = 0
    for _, tab in ipairs(ui.tabs) do
        if not tab.hidden then numVisibleTabs = numVisibleTabs + 1 end
    end
    
    -- Calculate total height of all tabs
    local totalTabsHeight = numVisibleTabs * tabH + (numVisibleTabs - 1) * tabSpacing
    
    -- Center tabs vertically in sidebar
    local tabStartY = bodyY + (bodyH - totalTabsHeight) / 2
    local tabEndY = tabStartY + totalTabsHeight
    
    -- Sidebar Panel - only in tabs area
    if numVisibleTabs > 0 then
        render_rect(config.origin_x, tabStartY, config.sidebar_width, totalTabsHeight, config.colors.bg_main, 15)
        draw_particles(config.origin_x, tabStartY, config.sidebar_width, totalTabsHeight)
    end
    
    -- Content Panel
    local contentBgX = config.origin_x + config.sidebar_width + config.sidebar_gap
    local contentBgW = config.menu_width - config.sidebar_width - config.sidebar_gap
    render_rect(contentBgX, bodyY, contentBgW, bodyH, config.colors.bg_main, 15)
    draw_particles(contentBgX, bodyY, contentBgW, bodyH)

    gui.push_clip(vec(config.origin_x + ox, bodyY + oy), vec(config.sidebar_width, bodyH))
    
    -- Only render tabs area if there are visible tabs
    if numVisibleTabs > 0 then
        local targetY = tabStartY
        local visibleIndex = 0
        for i, tab in ipairs(ui.tabs) do
            if not tab.hidden then
                visibleIndex = visibleIndex + 1
                if ui.currentTab and ui.currentTab.id == tab.id then
                    targetY = tabStartY + (visibleIndex-1) * (tabH + tabSpacing)
                    break
                end
            end
        end
        
        if not state.active_tab_y then state.active_tab_y = targetY end
        state.active_tab_y = lerp(state.active_tab_y, targetY, 0.2)
        -- Clamp active_tab_y to tabs area
        state.active_tab_y = math.max(tabStartY, math.min(state.active_tab_y, tabEndY - tabH))
        
        local tabX = config.origin_x
        local selectedW = config.sidebar_width - 16  
        -- Only render indicator if it's within tabs area and tabs exist
        local indicatorY = state.active_tab_y
        if indicatorY >= tabStartY and indicatorY + tabH <= tabEndY then
            render_rect(tabX + 8, indicatorY + 4, selectedW, tabH - 8, {r=255, g=255, b=255, a=10}, 6)
            local barW = math.floor(4 * config.scale)
            local barH = math.floor(28 * config.scale)
            local barY_ind = indicatorY + (tabH - barH)/2
            -- Clamp bar position to tabs area
            barY_ind = math.max(tabStartY, math.min(barY_ind, tabEndY - barH))
            -- Only render bar if it's within tabs area
            if barY_ind >= tabStartY and barY_ind + barH <= tabEndY then
                render_rect(tabX + 5, barY_ind, barW, barH, config.colors.accent, 2)
            end
        end
        
        -- Render tabs
        local visibleIndex = 0
        for i, tab in ipairs(ui.tabs) do
            if not tab.hidden then
                visibleIndex = visibleIndex + 1
                local isActive = (ui.currentTab and ui.currentTab.id == tab.id)
                local tabY = tabStartY + (visibleIndex-1) * (tabH + tabSpacing)
                
                if tabY + tabH > bodyY and tabY < bodyY + bodyH then
                    if is_hovered(tabX, tabY, config.sidebar_width, tabH) and state.mouse.clicked then
                        ui.currentTab = tab
                        state.scroll.y = 0
                        state.window.is_dragging = false  
                    end
                end

                local txtCol = isActive and config.colors.white or config.colors.text_sec
                local iconSize = math.floor(24 * config.scale)
                local textHeight = math.floor(14 * config.scale)  
                local gap = math.floor(6 * config.scale)  
                
                local contentHeight = iconSize + gap + textHeight
                local startY = tabY + (tabH - contentHeight)/2
                local iconY = startY
                local textY = iconY + iconSize + gap
                
                -- Render icon (image or text fallback)
                if tab.icon then
                    local iconCol = isActive and config.colors.accent or config.colors.text_sec
                    gui.image(tab.icon, vec(tabX + (config.sidebar_width - iconSize)/2 + ox, iconY + oy), vec(iconSize, iconSize), to_gui_color(iconCol, true))
                else
                    render_text(string.sub(tab.label, 1, 1), tabX + config.sidebar_width/2, iconY, config.font_scale_header, txtCol, "center")
                end
                
                render_text(tab.label, tabX + config.sidebar_width/2, textY, config.font_scale_small, txtCol, "center")
            end
        end
    end
    gui.pop_clip()


    local contentX = config.content_area.x + config.content_margin
    local contentY = config.content_area.y + config.content_margin
    local contentW = config.content_area.w - (config.content_margin * 2)
    local contentH = config.content_area.h - (config.content_margin * 2)
    
    -- Render subtabs for Heist tab (BEFORE clip, so they stay fixed at top)
    local subtab_bar_height = 0
    local groups_start_y = contentY
    if ui.currentTab and ui.currentTab.id == "heist" then
        local subtab_names = {"Cayo", "Casino", "Apartment", "Doomsday", "Cluckin"}
        local subtab_count = #subtab_names
        local subtab_h = math.floor(35 * config.scale)
        local subtab_gap = math.floor(6 * config.scale)
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
            
            local bg_col = is_active and config.colors.accent or config.colors.bg_sidebar
            if hovered and not is_active then
                bg_col = config.colors.btn_hover
            end
            render_rect(subtab_x, subtab_y, subtab_w, subtab_h, bg_col, 6)
            local text_col = is_active and config.colors.white or config.colors.text_main
            render_text(name, subtab_x + subtab_w / 2, subtab_y + subtab_h / 2 - math.floor(8 * config.scale), config.font_scale_body, text_col, "center")
        end
        
        subtab_bar_height = subtab_h + math.floor(10 * config.scale)
        groups_start_y = contentY + subtab_bar_height
    end
    
    -- Push clip for scrollable content area (excluding subtab bar)
    local clip_y = ui.currentTab and ui.currentTab.id == "heist" and groups_start_y or contentY
    local clip_h = contentH - subtab_bar_height
    gui.push_clip(vec(contentX + ox, clip_y + oy), vec(contentW, clip_h))

    local pendingDropdown = nil
    
    -- Custom rendering for Info tab
    if ui.currentTab and ui.currentTab.id == "info" then
        local centerX = contentX + contentW / 2
        local centerY = contentY + contentH / 2
        
        -- Animated pulse effect using sine wave
        local time = os.clock() * 2
        local pulse = (math.sin(time) + 1) / 2  -- 0 to 1
        local alpha = 200 + math.floor(pulse * 55)  -- 200 to 255
        
        -- Huge blue "ShillenLua" text
        local titleSize = math.floor(96 * config.scale)  -- Much larger
        local titleColor = {r = config.colors.accent.r, g = config.colors.accent.g, b = config.colors.accent.b, a = alpha}
        render_text("ShillenLua", centerX, centerY - 50, titleSize, titleColor, "center")
        
        -- Version text below - proportional to title size
        local versionSize = math.floor(titleSize * 0.25)  -- 25% of title size
        render_text("Version 1.7.1", centerX, centerY + 60, versionSize, config.colors.text_sec, "center")
        
        -- Money Limits text at the bottom
        local limitsSize = math.floor(versionSize * 0.8)
        local bottomY = contentY + contentH - math.floor(80 * config.scale)
        render_text("Money Limits:", centerX, bottomY, limitsSize, config.colors.accent, "center")
        render_text("Maximum 20-30M per day", centerX, bottomY + math.floor(25 * config.scale), limitsSize, config.colors.text_sec, "center")
        render_text("Maximum 120-130M per week", centerX, bottomY + math.floor(50 * config.scale), limitsSize, config.colors.text_sec, "center")
    end
    
    -- Custom rendering for Objects tab (removed - now has content)
    
    local activeGroups = {}
    if ui.currentTab then
        if ui.currentTab.id == "heist" then
            -- Filter groups based on subtab (1=Cayo, 2=Casino, 3=Apartment, 4=Doomsday)
            for _, group in ipairs(ui.currentTab.groups) do
                local show = false
                if state.heist_subtab == 1 and group.heist_subtab == "cayo" then show = true end
                if state.heist_subtab == 2 and group.heist_subtab == "casino" then show = true end
                if state.heist_subtab == 3 and group.heist_subtab == "apartment" then show = true end
                if state.heist_subtab == 4 and group.heist_subtab == "doomsday" then show = true end
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
        local col1_x = contentX
        local col2_x = contentX + contentW/2 + 10
        local col_w = contentW/2 - 10
        local col1_y = groups_start_y - state.scroll.y
        local col2_y = groups_start_y - state.scroll.y
        
        local total_h = 0
        
        for i, group in ipairs(activeGroups) do
            local use_col2 = (i % 2 == 0)
            local gX = use_col2 and col2_x or col1_x
            local gY = use_col2 and col2_y or col1_y
            
            local actual_h = get_group_actual_height(group)
            
            local available_height = contentH - subtab_bar_height
            local clip_start = groups_start_y
            if (gY + actual_h > clip_start) and (gY < clip_start + available_height) then
                render_rect(gX, gY, col_w, actual_h, config.colors.bg_panel, 8)
                -- Group Header Label
                render_text(group.label, gX + 15, gY + 12, config.font_scale_header, config.colors.accent)
                
                local itemY = gY + config.item_height.header_padding + 5
                for _, item in ipairs(group.items) do
                    
                    if item.type == "toggle" then
                        draw_toggle_item(item, gX, itemY, col_w, itemY)
                        itemY = itemY + config.item_height.toggle
                    elseif item.type == "button" then
                        draw_button_item(item, gX, itemY, col_w, itemY)
                        itemY = itemY + config.item_height.button
                    elseif item.type == "slider" then
                        draw_slider_item(item, gX, itemY, col_w, itemY)
                        itemY = itemY + config.item_height.slider
                    elseif item.type == "dropdown" then
                        local dd = draw_dropdown_item(item, gX, itemY, col_w, itemY)
                        if dd then pendingDropdown = dd end
                        itemY = itemY + config.item_height.dropdown
                    elseif item.type == "label" then
                        local labelCol = item.color or config.colors.text_sec
                        render_text(item.text, gX + math.floor(15 * config.scale), itemY + math.floor(12 * config.scale), config.font_scale_small, labelCol)
                        itemY = itemY + math.floor(25 * config.scale)
                    end
                end
            end
            
            if use_col2 then col2_y = col2_y + actual_h + 15
            else col1_y = col1_y + actual_h + 15 end
            
            total_h = math.max(col1_y, col2_y) - (groups_start_y - state.scroll.y)
        end
        
        local available_height = contentH - subtab_bar_height
        state.scroll.max_y = math.max(0, total_h - available_height)
    end
    
    -- Disable scroll for info tab (no content to scroll)
    if ui.currentTab and ui.currentTab.id == "info" then
        state.scroll.max_y = 0
        state.scroll.y = 0
    end
    
    gui.pop_clip()

    -- Scrollbar
    if state.scroll.max_y > 0 then
        local sb = config.scrollbar
        local sbH = contentH - subtab_bar_height
        local sbY = groups_start_y
        
        local thumbH = math.max(30, (sbH / (sbH + state.scroll.max_y)) * sbH)
        local thumbY = sbY + (state.scroll.y / state.scroll.max_y) * (sbH - thumbH)
        
        render_rect(sb.x, thumbY, sb.w, thumbH, config.colors.accent, 2)
        
        if is_hovered(sb.x - 5, sbY, sb.w + 10, sbH) and state.mouse.clicked then
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
        local itemHeight = math.floor(36 * config.scale)
        local optsH = #dd.item.options * itemHeight
        render_rect(dd.x, dd.y, dd.w, optsH, config.colors.bg_panel, 4)
        render_outline(dd.x, dd.y, dd.w, optsH, config.colors.border, 1, 4)
        
        for i, opt in ipairs(dd.item.options) do
            local optY = dd.y + (i-1)*itemHeight
            if is_hovered(dd.x, optY, dd.w, itemHeight) then
                render_rect(dd.x, optY, dd.w, itemHeight, config.colors.accent_dim, 0)
                if state.mouse.clicked and not state.dropdown_just_opened then
                    dd.item.value = i
                    dd.item.isOpen = false
                    state.active_dropdown = nil
                    state.window.is_dragging = false
                    if dd.item.onChange then dd.item.onChange(opt) end
                end
            end
            -- Center the option text in the dropdown menu
            render_text(opt, dd.x + dd.w / 2, optY + 5, config.font_scale_body, config.colors.text_main, "center")
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

local function enable_control_action(...)
    local keys = {...}
    for group = 0, 1 do
        for k, v in pairs(keys) do
            invoker.call(0x351220255D64C155, group, v, true)
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

-- Apply cuts for Casino Heist
local function apply_casino_cuts()
    script.globals(CasinoGlobals.Host).int32 = CutsValues.host
    script.globals(CasinoGlobals.P2).int32 = CutsValues.player2
    script.globals(CasinoGlobals.P3).int32 = CutsValues.player3
    script.globals(CasinoGlobals.P4).int32 = CutsValues.player4
    if notify then notify.push("Casino Heist", "Cuts Applied!", 2000) end
end

-- Preset functions
local function apply_silent_sneaky()
    account.stats("MP0_H3OPT_MASKS").int32 = 4
    account.stats("MP1_H3OPT_MASKS").int32 = 4
    account.stats("MP0_H3OPT_WEAPS").int32 = 1
    account.stats("MP1_H3OPT_WEAPS").int32 = 1
    account.stats("MP0_H3OPT_VEHS").int32 = 3
    account.stats("MP1_H3OPT_VEHS").int32 = 3
    account.stats("MP0_CAS_HEIST_FLOW").int32 = -1
    account.stats("MP1_CAS_HEIST_FLOW").int32 = -1
    account.stats("MP0_H3_LAST_APPROACH").int32 = 0
    account.stats("MP1_H3_LAST_APPROACH").int32 = 0
    account.stats("MP0_H3OPT_APPROACH").int32 = 1
    account.stats("MP1_H3OPT_APPROACH").int32 = 1
    account.stats("MP0_H3_HARD_APPROACH").int32 = 1
    account.stats("MP1_H3_HARD_APPROACH").int32 = 1
    account.stats("MP0_H3OPT_TARGET").int32 = 3
    account.stats("MP1_H3OPT_TARGET").int32 = 3
    account.stats("MP0_H3OPT_POI").int32 = 1023
    account.stats("MP1_H3OPT_POI").int32 = 1023
    account.stats("MP0_H3OPT_ACCESSPOINTS").int32 = 2047
    account.stats("MP1_H3OPT_ACCESSPOINTS").int32 = 2047
    account.stats("MP0_H3OPT_CREWWEAP").int32 = 4
    account.stats("MP1_H3OPT_CREWWEAP").int32 = 4
    account.stats("MP0_H3OPT_CREWDRIVER").int32 = 3
    account.stats("MP1_H3OPT_CREWDRIVER").int32 = 3
    account.stats("MP0_H3OPT_CREWHACKER").int32 = 4
    account.stats("MP1_H3OPT_CREWHACKER").int32 = 4
    account.stats("MP0_H3OPT_DISRUPTSHIP").int32 = 3
    account.stats("MP1_H3OPT_DISRUPTSHIP").int32 = 3
    account.stats("MP0_H3OPT_BODYARMORLVL").int32 = -1
    account.stats("MP1_H3OPT_BODYARMORLVL").int32 = -1
    account.stats("MP0_H3OPT_KEYLEVELS").int32 = 2
    account.stats("MP1_H3OPT_KEYLEVELS").int32 = 2
    account.stats("MP0_H3OPT_BITSET1").int32 = 127
    account.stats("MP1_H3OPT_BITSET1").int32 = 127
    account.stats("MP0_H3OPT_BITSET0").int32 = 262270
    account.stats("MP1_H3OPT_BITSET0").int32 = 262270
    account.stats("MP0_CAS_HEIST_FLOW").int32 = -1
    account.stats("MP1_CAS_HEIST_FLOW").int32 = -1
    script.locals("gb_casino_heist_planning", 210).int32 = 2
    if notify then notify.push("Preset", "Applied Silent & Sneaky", 2000) end
end

local function apply_big_con()
    local prefix0 = "MP0_"
    local prefix1 = "MP1_"
    account.stats(prefix0 .. "H3OPT_MASKS").int32 = 2
    account.stats(prefix1 .. "H3OPT_MASKS").int32 = 2
    account.stats(prefix0 .. "H3OPT_WEAPS").int32 = 1
    account.stats(prefix1 .. "H3OPT_WEAPS").int32 = 1
    account.stats(prefix0 .. "H3OPT_VEHS").int32 = 3
    account.stats(prefix1 .. "H3OPT_VEHS").int32 = 3
    account.stats(prefix0 .. "CAS_HEIST_FLOW").int32 = -1
    account.stats(prefix1 .. "CAS_HEIST_FLOW").int32 = -1
    account.stats(prefix0 .. "H3_LAST_APPROACH").int32 = 0
    account.stats(prefix1 .. "H3_LAST_APPROACH").int32 = 0
    account.stats(prefix0 .. "H3OPT_APPROACH").int32 = 2
    account.stats(prefix1 .. "H3OPT_APPROACH").int32 = 2
    account.stats(prefix0 .. "H3_HARD_APPROACH").int32 = 2
    account.stats(prefix1 .. "H3_HARD_APPROACH").int32 = 2
    account.stats(prefix0 .. "H3OPT_TARGET").int32 = 3
    account.stats(prefix1 .. "H3OPT_TARGET").int32 = 3
    account.stats(prefix0 .. "H3OPT_POI").int32 = 1023
    account.stats(prefix1 .. "H3OPT_POI").int32 = 1023
    account.stats(prefix0 .. "H3OPT_ACCESSPOINTS").int32 = 2047
    account.stats(prefix1 .. "H3OPT_ACCESSPOINTS").int32 = 2047
    account.stats(prefix0 .. "H3OPT_CREWWEAP").int32 = 4
    account.stats(prefix1 .. "H3OPT_CREWWEAP").int32 = 4
    account.stats(prefix0 .. "H3OPT_CREWDRIVER").int32 = 3
    account.stats(prefix1 .. "H3OPT_CREWDRIVER").int32 = 3
    account.stats(prefix0 .. "H3OPT_CREWHACKER").int32 = 4
    account.stats(prefix1 .. "H3OPT_CREWHACKER").int32 = 4
    account.stats(prefix0 .. "H3OPT_DISRUPTSHIP").int32 = 3
    account.stats(prefix1 .. "H3OPT_DISRUPTSHIP").int32 = 3
    account.stats(prefix0 .. "H3OPT_BODYARMORLVL").int32 = -1
    account.stats(prefix1 .. "H3OPT_BODYARMORLVL").int32 = -1
    account.stats(prefix0 .. "H3OPT_KEYLEVELS").int32 = 2
    account.stats(prefix1 .. "H3OPT_KEYLEVELS").int32 = 2
    account.stats(prefix0 .. "H3OPT_BITSET1").int32 = 159
    account.stats(prefix1 .. "H3OPT_BITSET1").int32 = 159
    account.stats(prefix0 .. "H3OPT_BITSET0").int32 = 524118
    account.stats(prefix1 .. "H3OPT_BITSET0").int32 = 524118
    account.stats(prefix0 .. "CAS_HEIST_FLOW").int32 = -1
    account.stats(prefix1 .. "CAS_HEIST_FLOW").int32 = -1
    script.locals("gb_casino_heist_planning", 212).int32 = 2
    if notify then notify.push("Preset", "Applied The Big Con", 2000) end
end

local function apply_aggressive()
    local prefix0 = "MP0_"
    local prefix1 = "MP1_"
    account.stats(prefix0 .. "H3OPT_MASKS").int32 = 4
    account.stats(prefix1 .. "H3OPT_MASKS").int32 = 4
    account.stats(prefix0 .. "H3OPT_WEAPS").int32 = 1
    account.stats(prefix1 .. "H3OPT_WEAPS").int32 = 1
    account.stats(prefix0 .. "H3OPT_VEHS").int32 = 3
    account.stats(prefix1 .. "H3OPT_VEHS").int32 = 3
    account.stats(prefix0 .. "CAS_HEIST_FLOW").int32 = -1
    account.stats(prefix1 .. "CAS_HEIST_FLOW").int32 = -1
    account.stats(prefix0 .. "H3_LAST_APPROACH").int32 = 0
    account.stats(prefix1 .. "H3_LAST_APPROACH").int32 = 0
    account.stats(prefix0 .. "H3OPT_APPROACH").int32 = 3
    account.stats(prefix1 .. "H3OPT_APPROACH").int32 = 3
    account.stats(prefix0 .. "H3_HARD_APPROACH").int32 = 3
    account.stats(prefix1 .. "H3_HARD_APPROACH").int32 = 3
    account.stats(prefix0 .. "H3OPT_TARGET").int32 = 3
    account.stats(prefix1 .. "H3OPT_TARGET").int32 = 3
    account.stats(prefix0 .. "H3OPT_POI").int32 = 1023
    account.stats(prefix1 .. "H3OPT_POI").int32 = 1023
    account.stats(prefix0 .. "H3OPT_ACCESSPOINTS").int32 = 2047
    account.stats(prefix1 .. "H3OPT_ACCESSPOINTS").int32 = 2047
    account.stats(prefix0 .. "H3OPT_CREWWEAP").int32 = 4
    account.stats(prefix1 .. "H3OPT_CREWWEAP").int32 = 4
    account.stats(prefix0 .. "H3OPT_CREWDRIVER").int32 = 3
    account.stats(prefix1 .. "H3OPT_CREWDRIVER").int32 = 3
    account.stats(prefix0 .. "H3OPT_CREWHACKER").int32 = 4
    account.stats(prefix1 .. "H3OPT_CREWHACKER").int32 = 4
    account.stats(prefix0 .. "H3OPT_DISRUPTSHIP").int32 = 3
    account.stats(prefix1 .. "H3OPT_DISRUPTSHIP").int32 = 3
    account.stats(prefix0 .. "H3OPT_BODYARMORLVL").int32 = -1
    account.stats(prefix1 .. "H3OPT_BODYARMORLVL").int32 = -1
    account.stats(prefix0 .. "H3OPT_KEYLEVELS").int32 = 2
    account.stats(prefix1 .. "H3OPT_KEYLEVELS").int32 = 2
    account.stats(prefix0 .. "H3OPT_BITSET1").int32 = 799
    account.stats(prefix1 .. "H3OPT_BITSET1").int32 = 799
    account.stats(prefix0 .. "H3OPT_BITSET0").int32 = 3670102
    account.stats(prefix1 .. "H3OPT_BITSET0").int32 = 3670102
    account.stats(prefix0 .. "CAS_HEIST_FLOW").int32 = -1
    account.stats(prefix1 .. "CAS_HEIST_FLOW").int32 = -1
    script.locals("gb_casino_heist_planning", 212).int32 = 2
    if notify then notify.push("Preset", "Applied Aggressive", 2000) end
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

    -- Apartment: Check if it's Fleeca or others (use player count from data)
    local stat = account.stats("HEIST_MISSION_RCONT_ID_1").int32
    local is_fleeca = (stat == 1)
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
local CayoCutsValues = {
    host = 100,
    player2 = 100,
    player3 = 100,
    player4 = 100
}

-- Cayo configuration storage
local CayoConfig = {
    diff = 126823,  -- Normal difficulty
    app = 65535,    -- All Approaches
    wep = 1,        -- Weapon
    tgt = 5,        -- Panther Statue
    sec_comp = "GOLD",  -- Compound Loot
    sec_isl = "GOLD",   -- Island Loot
    amt_comp = 255,
    amt_isl = 16777215,
    paint = 127,
    val_cash = 83250,
    val_weed = 135000,
    val_coke = 202500,
    val_gold = 333333,
    val_art = 180000
}

-- Apply Cayo Preps
local function cayo_apply_preps()
    local p = GetMP()
    account.stats(p .. "H4_PROGRESS").int32 = CayoConfig.diff
    account.stats(p .. "H4_MISSIONS").int32 = CayoConfig.app
    account.stats(p .. "H4CNF_WEAPONS").int32 = CayoConfig.wep
    account.stats(p .. "H4CNF_TARGET").int32 = CayoConfig.tgt
    
    local loots = {"CASH", "WEED", "COKE", "GOLD"}
    for _, l in ipairs(loots) do
        local val = (CayoConfig.sec_comp == l) and CayoConfig.amt_comp or 0
        account.stats(p .. "H4LOOT_" .. l .. "_C").int32 = val
        account.stats(p .. "H4LOOT_" .. l .. "_C_SCOPED").int32 = val
        local val2 = (CayoConfig.sec_isl == l) and CayoConfig.amt_isl or 0
        account.stats(p .. "H4LOOT_" .. l .. "_I").int32 = val2
        account.stats(p .. "H4LOOT_" .. l .. "_I_SCOPED").int32 = val2
        local money = (l == "CASH" and CayoConfig.val_cash) or (l == "WEED" and CayoConfig.val_weed) or (l == "COKE" and CayoConfig.val_coke) or (l == "GOLD" and CayoConfig.val_gold) or 0
        account.stats(p .. "H4LOOT_" .. l .. "_V").int32 = money
    end
    account.stats(p .. "H4LOOT_PAINT").int32 = CayoConfig.paint
    account.stats(p .. "H4LOOT_PAINT_SCOPED").int32 = CayoConfig.paint
    account.stats(p .. "H4LOOT_PAINT_V").int32 = CayoConfig.val_art
    script.locals("heist_island_planning", 1570).int32 = 2
    if notify then notify.push("Cayo Perico", "Preps Applied", 2000) end
end

-- Apply Cayo Cuts
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
    -- Reload planning board if script is running
    if script.running("heist_island_planning") then
        script.locals("heist_island_planning", 1570).int32 = 2
    end
    if notify then notify.push("Cayo Tools", "All POI Unlocked", 2000) end
end

local function cayo_reset_preps()
    local p = GetMP()
    account.stats(p .. "H4_PROGRESS").int32 = 0
    script.locals("heist_island_planning", 1570).int32 = 2
    if notify then notify.push("Cayo Tools", "Preps Reset", 2000) end
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
    script.globals(1877303).int32 = -1
    if notify then notify.push("Apartment Preps", "Cooldown Reset", 2000) end
end

-- ---------------------------------------------------------
-- 7. Setup Data (Example)
-- ---------------------------------------------------------
ui.tab("info", "INFO", "ui/components/player.png")
ui.tab("heist", "HEIST", "ui/components/network.png")
ui.tab("spawner", "SPAWNER", "ui/components/spawner.png")
ui.tab("vehicle", "VEHICLE", "ui/components/spawner.png")
ui.tab("other", "OBJECTS", "ui/components/network.png")

-- Info Tab Content (empty - custom rendering)

-- Casino Manual Preps storage
local CasinoManualPreps = {
    approach = 1,      -- 1=Silent, 2=Big Con, 3=Aggressive
    target = 3,        -- 0=Cash, 1=Gold, 2=Artwork, 3=Diamonds
    masks = 4,         -- 1=Geometric, 2=Hunter, 3=Oni Half, 4=Emoji
    weapons = 1,       -- 1=Micro SMG, 2=Assault Rifle, 3=Shotgun
    vehicles = 3,      -- 1=Sentinel Classic, 2=Gauntlet Classic, 3=Sultan Classic
    crew_weapon = 4,   -- 1=Karl Abolaji, 2=Gustavo Mota, 3=Charlie Reed, 4=Chester McCoy, 5=Patrick McReary
    crew_driver = 3,   -- 1=Karim Denz, 2=Taliana Martinez, 3=Eddie Toh, 4=Zach Nelson, 5=Chester McCoy
    crew_hacker = 4,   -- 1=Rickie Lukens, 2=Christian Feltz, 3=Yohan Blair, 4=Avi Schwartzman, 5=Paige Harris
    disrupt_shipments = 3,  -- 0=None, 1=Armor, 2=Weapons, 3=Both
    body_armor = -1,   -- -1=All, 0=None, 1-3=Level 1-3
    key_levels = 2     -- 0=None, 1=Level 1, 2=Level 2
}

-- Function to apply manual preps
local function apply_casino_manual_preps()
    local p = GetMP()
    local prefix0 = "MP0_"
    local prefix1 = "MP1_"
    
    -- Approach
    account.stats(prefix0 .. "H3OPT_APPROACH").int32 = CasinoManualPreps.approach
    account.stats(prefix1 .. "H3OPT_APPROACH").int32 = CasinoManualPreps.approach
    account.stats(prefix0 .. "H3_HARD_APPROACH").int32 = CasinoManualPreps.approach
    account.stats(prefix1 .. "H3_HARD_APPROACH").int32 = CasinoManualPreps.approach
    account.stats(prefix0 .. "H3_LAST_APPROACH").int32 = 0
    account.stats(prefix1 .. "H3_LAST_APPROACH").int32 = 0
    
    -- Target
    account.stats(prefix0 .. "H3OPT_TARGET").int32 = CasinoManualPreps.target
    account.stats(prefix1 .. "H3OPT_TARGET").int32 = CasinoManualPreps.target
    
    -- Masks
    account.stats(prefix0 .. "H3OPT_MASKS").int32 = CasinoManualPreps.masks
    account.stats(prefix1 .. "H3OPT_MASKS").int32 = CasinoManualPreps.masks
    
    -- Weapons
    account.stats(prefix0 .. "H3OPT_WEAPS").int32 = CasinoManualPreps.weapons
    account.stats(prefix1 .. "H3OPT_WEAPS").int32 = CasinoManualPreps.weapons
    
    -- Vehicles
    account.stats(prefix0 .. "H3OPT_VEHS").int32 = CasinoManualPreps.vehicles
    account.stats(prefix1 .. "H3OPT_VEHS").int32 = CasinoManualPreps.vehicles
    
    -- Crew
    account.stats(prefix0 .. "H3OPT_CREWWEAP").int32 = CasinoManualPreps.crew_weapon
    account.stats(prefix1 .. "H3OPT_CREWWEAP").int32 = CasinoManualPreps.crew_weapon
    account.stats(prefix0 .. "H3OPT_CREWDRIVER").int32 = CasinoManualPreps.crew_driver
    account.stats(prefix1 .. "H3OPT_CREWDRIVER").int32 = CasinoManualPreps.crew_driver
    account.stats(prefix0 .. "H3OPT_CREWHACKER").int32 = CasinoManualPreps.crew_hacker
    account.stats(prefix1 .. "H3OPT_CREWHACKER").int32 = CasinoManualPreps.crew_hacker
    
    -- Disrupt Shipments
    account.stats(prefix0 .. "H3OPT_DISRUPTSHIP").int32 = CasinoManualPreps.disrupt_shipments
    account.stats(prefix1 .. "H3OPT_DISRUPTSHIP").int32 = CasinoManualPreps.disrupt_shipments
    
    -- Body Armor Level
    account.stats(prefix0 .. "H3OPT_BODYARMORLVL").int32 = CasinoManualPreps.body_armor
    account.stats(prefix1 .. "H3OPT_BODYARMORLVL").int32 = CasinoManualPreps.body_armor
    
    -- Key Levels
    account.stats(prefix0 .. "H3OPT_KEYLEVELS").int32 = CasinoManualPreps.key_levels
    account.stats(prefix1 .. "H3OPT_KEYLEVELS").int32 = CasinoManualPreps.key_levels
    
    -- Standard unlocks
    account.stats(prefix0 .. "H3OPT_POI").int32 = 1023
    account.stats(prefix1 .. "H3OPT_POI").int32 = 1023
    account.stats(prefix0 .. "H3OPT_ACCESSPOINTS").int32 = 2047
    account.stats(prefix1 .. "H3OPT_ACCESSPOINTS").int32 = 2047
    account.stats(prefix0 .. "CAS_HEIST_FLOW").int32 = -1
    account.stats(prefix1 .. "CAS_HEIST_FLOW").int32 = -1
    
    if CasinoManualPreps.approach == 1 then
        -- Silent & Sneaky
        account.stats(prefix0 .. "H3OPT_BITSET0").int32 = 262270
        account.stats(prefix1 .. "H3OPT_BITSET0").int32 = 262270
        account.stats(prefix0 .. "H3OPT_BITSET1").int32 = 127
        account.stats(prefix1 .. "H3OPT_BITSET1").int32 = 127
        script.locals("gb_casino_heist_planning", 210).int32 = 2
    elseif CasinoManualPreps.approach == 2 then
        -- Big Con
        account.stats(prefix0 .. "H3OPT_BITSET0").int32 = 524118
        account.stats(prefix1 .. "H3OPT_BITSET0").int32 = 524118
        account.stats(prefix0 .. "H3OPT_BITSET1").int32 = 159
        account.stats(prefix1 .. "H3OPT_BITSET1").int32 = 159
        script.locals("gb_casino_heist_planning", 212).int32 = 2
    else
        -- Aggressive
        account.stats(prefix0 .. "H3OPT_BITSET0").int32 = 3670102
        account.stats(prefix1 .. "H3OPT_BITSET0").int32 = 3670102
        account.stats(prefix0 .. "H3OPT_BITSET1").int32 = 799
        account.stats(prefix1 .. "H3OPT_BITSET1").int32 = 799
        script.locals("gb_casino_heist_planning", 212).int32 = 2
    end
    
    if notify then notify.push("Casino Manual Preps", "Applied Manual Configuration", 2000) end
end

-- Casino Tab Content
local heistTab = ui.tabs[2]
local gCasinoInfo = ui.group(heistTab, "Info", nil, nil, nil, 140, "casino")
ui.label(gCasinoInfo, "Diamond Casino Heist", config.colors.accent)
ui.label(gCasinoInfo, "Max transaction: $3,619,000", config.colors.text_main)
ui.label(gCasinoInfo, "Transaction cooldown: 30 min", config.colors.text_sec)
ui.label(gCasinoInfo, "Heist cooldown: ~45 min (skip)", config.colors.text_sec)

local gPreset = ui.group(heistTab, "Preset", nil, nil, nil, nil, "casino")
ui.button(gPreset, "preset_silent", "Silent & Sneaky", function() apply_silent_sneaky() end)
ui.button(gPreset, "preset_big", "The Big Con", function() apply_big_con() end)
ui.button(gPreset, "preset_aggressive", "Aggressive", function() apply_aggressive() end)
ui.button(gPreset, "preset_reset", "Reset Preparations", function() reset_heist_preps() end)

local gTools = ui.group(heistTab, "Tools", nil, nil, nil, nil, "casino")
ui.button(gTools, "tool_finger", "Fingerprint Hack", function() casino_fingerprint_hack() end)
ui.button(gTools, "tool_keypad", "Keypad Hack", function() casino_instant_keypad_hack() end)
ui.button(gTools, "tool_vault", "Vault Drill", function() casino_instant_vault_drill() end)
ui.button(gTools, "tool_finish", "Instant Finish", function() casino_instant_finish() end)
ui.button(gTools, "tool_arcade", "Skip Arcade Setup", function() casino_skip_arcade_setup() end)
ui.button(gTools, "tool_keycards", "Fix Keycards", function() casino_fix_stuck_keycards() end)
ui.button(gTools, "tool_objective", "Skip Objective", function() casino_skip_objective() end)
ui.button(gTools, "tool_cooldown", "Remove Cooldown", function() casino_remove_cooldown() end)
ui.button(gTools, "tool_lives", "Set Team Lives", function() casino_set_team_lives() end)

-- Launch group
local gLaunch = ui.group(heistTab, "Launch", nil, nil, nil, nil, "casino")
ui.toggle(gLaunch, "launch_solo", "Solo Launch", state.solo_launch.casino, function(val)
    state.solo_launch.casino = val
end)
ui.button(gLaunch, "launch_force_ready", "Force Ready", function() casino_force_ready() end)
ui.button(gLaunch, "launch_skip_setup", "Skip Setup", function() casino_skip_arcade_setup() end)

-- Manual Preps group
local gManualPreps = ui.group(heistTab, "Manual Preps", nil, nil, nil, nil, "casino")
ui.dropdown(gManualPreps, "manual_approach", "Approach", {"Silent & Sneaky", "The Big Con", "Aggressive"}, 1, function(opt)
    if opt == "Silent & Sneaky" then CasinoManualPreps.approach = 1
    elseif opt == "The Big Con" then CasinoManualPreps.approach = 2
    elseif opt == "Aggressive" then CasinoManualPreps.approach = 3 end
end)
ui.dropdown(gManualPreps, "manual_target", "Target", {"Cash", "Artwork", "Gold", "Diamonds"}, 4, function(opt)
    local targets = {Cash = 0, Artwork = 2, Gold = 1, Diamonds = 3}
    CasinoManualPreps.target = targets[opt] or 3
end)
ui.dropdown(gManualPreps, "manual_masks", "Masks", {"Geometric", "Hunter", "Oni Half", "Emoji"}, 4, function(opt)
    local masks = {Geometric = 1, Hunter = 2, ["Oni Half"] = 3, Emoji = 4}
    CasinoManualPreps.masks = masks[opt] or 4
end)
-- Weapons: Standard Casino Heist weapons
ui.dropdown(gManualPreps, "manual_weapons", "Weapons", {"Micro SMG", "Assault Rifle", "Shotgun"}, 1, function(opt)
    local weapons = {["Micro SMG"] = 1, ["Assault Rifle"] = 2, Shotgun = 3}
    CasinoManualPreps.weapons = weapons[opt] or 1
end)
-- Vehicles: Standard Casino Heist vehicles
ui.dropdown(gManualPreps, "manual_vehicles", "Vehicles", {"Sentinel Classic", "Gauntlet Classic", "Sultan Classic"}, 3, function(opt)
    local vehicles = {["Sentinel Classic"] = 1, ["Gauntlet Classic"] = 2, ["Sultan Classic"] = 3}
    CasinoManualPreps.vehicles = vehicles[opt] or 3
end)
ui.dropdown(gManualPreps, "manual_crew_weapon", "Crew Gunman", {"Karl Abolaji", "Gustavo Mota", "Charlie Reed", "Chester McCoy", "Patrick McReary"}, 4, function(opt)
    local gunmen = {["Karl Abolaji"] = 1, ["Gustavo Mota"] = 2, ["Charlie Reed"] = 3, ["Chester McCoy"] = 4, ["Patrick McReary"] = 5}
    CasinoManualPreps.crew_weapon = gunmen[opt] or 4
end)
ui.dropdown(gManualPreps, "manual_crew_driver", "Crew Driver", {"Karim Denz", "Taliana Martinez", "Eddie Toh", "Zach Nelson", "Chester McCoy"}, 3, function(opt)
    local drivers = {["Karim Denz"] = 1, ["Taliana Martinez"] = 2, ["Eddie Toh"] = 3, ["Zach Nelson"] = 4, ["Chester McCoy"] = 5}
    CasinoManualPreps.crew_driver = drivers[opt] or 3
end)
ui.dropdown(gManualPreps, "manual_crew_hacker", "Crew Hacker", {"Rickie Lukens", "Christian Feltz", "Yohan Blair", "Avi Schwartzman", "Paige Harris"}, 4, function(opt)
    local hackers = {["Rickie Lukens"] = 1, ["Christian Feltz"] = 2, ["Yohan Blair"] = 3, ["Avi Schwartzman"] = 4, ["Paige Harris"] = 5}
    CasinoManualPreps.crew_hacker = hackers[opt] or 4
end)
ui.dropdown(gManualPreps, "manual_disrupt", "Disrupt Shipments", {"None", "Armor", "Weapons", "Both"}, 4, function(opt)
    local disrupts = {None = 0, Armor = 1, Weapons = 2, Both = 3}
    CasinoManualPreps.disrupt_shipments = disrupts[opt] or 3
end)
ui.dropdown(gManualPreps, "manual_body_armor", "Body Armor", {"All", "None", "Level 1", "Level 2", "Level 3"}, 1, function(opt)
    local armors = {All = -1, None = 0, ["Level 1"] = 1, ["Level 2"] = 2, ["Level 3"] = 3}
    CasinoManualPreps.body_armor = armors[opt] or -1
end)
ui.dropdown(gManualPreps, "manual_key_levels", "Keycards", {"None", "Level 1", "Level 2"}, 3, function(opt)
    local keys = {None = 0, ["Level 1"] = 1, ["Level 2"] = 2}
    CasinoManualPreps.key_levels = keys[opt] or 2
end)
ui.button(gManualPreps, "manual_apply", "Apply Manual Preps", function() apply_casino_manual_preps() end)

local gCuts = ui.group(heistTab, "Cuts", nil, nil, nil, nil, "casino")
local cutHostSlider = ui.slider(gCuts, "cut_host", "Host Cut %", 0, 300, 100, function(val)
    CutsValues.host = math.floor(val)
end, nil, 5)
local cutP2Slider = ui.slider(gCuts, "cut_p2", "Player 2 Cut %", 0, 300, 0, function(val)
    CutsValues.player2 = math.floor(val)
end, nil, 5)
local cutP3Slider = ui.slider(gCuts, "cut_p3", "Player 3 Cut %", 0, 300, 0, function(val)
    CutsValues.player3 = math.floor(val)
end, nil, 5)
local cutP4Slider = ui.slider(gCuts, "cut_p4", "Player 4 Cut %", 0, 300, 0, function(val)
    CutsValues.player4 = math.floor(val)
end, nil, 5)
ui.button(gCuts, "cuts_max", "Apply Preset (100%)", function()
    CutsValues.host = 100
    CutsValues.player2 = 100
    CutsValues.player3 = 100
    CutsValues.player4 = 100
    if cutHostSlider then cutHostSlider.value = 100 end
    if cutP2Slider then cutP2Slider.value = 100 end
    if cutP3Slider then cutP3Slider.value = 100 end
    if cutP4Slider then cutP4Slider.value = 100 end
    apply_casino_cuts()
end)
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
ui.button(gCasinoTeleportOutside, "casino_tp_tunnel", "Tunnel", function() casino_teleport_tunnel() end)
ui.button(gCasinoTeleportOutside, "casino_tp_staff_lobby", "Staff Lobby", function() casino_teleport_staff_lobby() end)

-- Teleport section - In Casino (moved below Outside Casino)
local gCasinoTeleportInside = ui.group(heistTab, "Teleport - In Casino", nil, nil, nil, nil, "casino")
ui.button(gCasinoTeleportInside, "casino_tp_staff_lobby_inside", "Staff Lobby", function() casino_teleport_staff_lobby_inside() end)
ui.button(gCasinoTeleportInside, "casino_tp_side_safe", "Side Safe", function() casino_teleport_side_safe() end)
ui.button(gCasinoTeleportInside, "casino_tp_tunnel_door", "Tunnel Door", function() casino_teleport_tunnel_door() end)

-- Vehicle Spawner Data
-- Vehicle settings grouped to reduce local variables
local vehicle_settings = {
    selected2Seater = "adder",
    selected4Seater = "baller",
    maxUpgrades = false,
    rainbow = false,
    boostEnabled = false,
    boostStrength = 50,
    godmodeEnabled = false,
    godmodeVehicles = {},
    rainbowVehicles = {},
    rainbowColorIndex = 0
}

-- Vehicle spawner state (improved from Spawn.lua)
local spawn_state = {
    spawned_objects = {}, -- List of spawned objects: {handle, name, model, spawn_pos}
    selected_object_index = 0, -- Index in spawned_objects array (0 = none selected)
    last_spawned_object = nil,  -- Store last spawned object for movement
    loading = false,
    last_spawned = nil,
    delete_old_vehicle = true,
    spawn_in_air = false,
    engine_on = true,
}

-- 2-Seater Vehicles List (Supercars only - max 10)
local vehicles2Seater = {
    "adder",
    "zentorno",
    "t20",
    "reaper",
    "nero",
    "osiris",
    "fmj",
    "vagner",
    "visione",
    "xa21"
}

-- 4-Seater Vehicles List (SUVs only - max 10)
local vehicles4Seater = {
    "baller",
    "dubsta",
    "granger",
    "huntley",
    "landstalker",
    "mesa",
    "patriot",
    "radi",
    "rocoto",
    "serrano"
}

-- Function to apply maximum vehicle upgrades
local function apply_max_vehicle_upgrades(vehicle)
    if not vehicle or vehicle == 0 then return end
    if not invoker or not invoker.call then return end
    
    -- Set vehicle mod kit FIRST (required for mods to work) - use 0, not 1!
    invoker.call(0x1F2AA07F00B3217A, vehicle, 0) -- SET_VEHICLE_MOD_KIT (0 = default mod kit)
    util.yield(50) -- Wait for mod kit to be set
    
    -- Vehicle mod types (0-49+)
    local modTypes = {
        0,  -- Spoiler
        1,  -- Front Bumper
        2,  -- Rear Bumper
        3,  -- Side Skirt
        4,  -- Exhaust
        5,  -- Frame
        6,  -- Grille
        7,  -- Hood
        8,  -- Fender
        9,  -- Right Fender
        10, -- Roof
        11, -- Engine
        12, -- Brakes
        13, -- Transmission
        14, -- Horns
        15, -- Suspension
        16, -- Armor
        18, -- Turbo (toggle - use 1 to enable)
        22, -- Xenon Headlights
        23, -- Front Wheels
        24, -- Back Wheels
        25, -- Plate Holders
        26, -- Vanity Plates
        27, -- Trim A
        28, -- Trim B
        30, -- Dial Design
        31, -- Door Speakers
        32, -- Seats
        33, -- Steering Wheel
        34, -- Shift Knob
        35, -- Plaques
        38, -- Hydraulics
        39, -- Engine Block
        40, -- Air Filter
        41, -- Struts
        42, -- Arch Cover
        43, -- Antenna
        44, -- Exterior Parts
        45, -- Tank
        46, -- Windows
        48  -- Livery
    }
    
    -- Apply each mod type with maximum value
    for _, modType in ipairs(modTypes) do
        if modType == 18 then
            -- Turbo - use TOGGLE_VEHICLE_MOD instead of SET_VEHICLE_MOD
            invoker.call(0x2A1F4F37F95BAD08, vehicle, modType, true) -- TOGGLE_VEHICLE_MOD (true = enable)
        else
            -- Get number of available mods for this type
            local numMods = invoker.call(0xE38E9162A2500646, vehicle, modType) -- GET_NUM_VEHICLE_MODS
            if numMods and numMods.int and numMods.int > 0 then
                -- Apply max mod (numMods includes stock, so max is numMods - 1)
                invoker.call(0x6AF0636DDEDCB6DD, vehicle, modType, numMods.int - 1, false) -- SET_VEHICLE_MOD
            end
        end
        util.yield(20) -- Delay between mods to ensure they apply correctly
    end
    
    -- Enable neon lights on all sides
    for i = 0, 3 do
        invoker.call(0x2AA720E4287BF269, vehicle, i, true) -- SET_VEHICLE_NEON_ENABLED
    end
    
    -- Force apply all important upgrades again to ensure they stick
    util.yield(100) -- Wait longer before reapplying
    
    -- Re-apply mod kit to ensure it's active (use 0, not 1!)
    invoker.call(0x1F2AA07F00B3217A, vehicle, 0) -- SET_VEHICLE_MOD_KIT (0 = default mod kit)
    util.yield(50)
    
    -- Engine (11) - critical upgrade - try multiple times
    for i = 1, 3 do
        local engineMods = invoker.call(0xE38E9162A2500646, vehicle, 11) -- GET_NUM_VEHICLE_MODS for engine
        if engineMods and engineMods.int and engineMods.int > 0 then
            local maxEngine = engineMods.int - 1
            if maxEngine >= 0 then
                invoker.call(0x6AF0636DDEDCB6DD, vehicle, 11, maxEngine, false) -- SET_VEHICLE_MOD for engine
            end
        end
        util.yield(20)
    end
    
    -- Brakes (12)
    local brakeMods = invoker.call(0xE38E9162A2500646, vehicle, 12) -- GET_NUM_VEHICLE_MODS for brakes
    if brakeMods and brakeMods.int and brakeMods.int > 0 then
        local maxBrakes = brakeMods.int - 1
        if maxBrakes >= 0 then
            invoker.call(0x6AF0636DDEDCB6DD, vehicle, 12, maxBrakes, false) -- SET_VEHICLE_MOD for brakes
        end
    end
    util.yield(20)
    
    -- Transmission (13)
    local transMods = invoker.call(0xE38E9162A2500646, vehicle, 13) -- GET_NUM_VEHICLE_MODS for transmission
    if transMods and transMods.int and transMods.int > 0 then
        local maxTrans = transMods.int - 1
        if maxTrans >= 0 then
            invoker.call(0x6AF0636DDEDCB6DD, vehicle, 13, maxTrans, false) -- SET_VEHICLE_MOD for transmission
        end
    end
    util.yield(20)
    
    -- Suspension (15)
    local suspMods = invoker.call(0xE38E9162A2500646, vehicle, 15) -- GET_NUM_VEHICLE_MODS for suspension
    if suspMods and suspMods.int and suspMods.int > 0 then
        local maxSusp = suspMods.int - 1
        if maxSusp >= 0 then
            invoker.call(0x6AF0636DDEDCB6DD, vehicle, 15, maxSusp, false) -- SET_VEHICLE_MOD for suspension
        end
    end
    util.yield(20)
    
    -- Armor (16)
    local armorMods = invoker.call(0xE38E9162A2500646, vehicle, 16) -- GET_NUM_VEHICLE_MODS for armor
    if armorMods and armorMods.int and armorMods.int > 0 then
        local maxArmor = armorMods.int - 1
        if maxArmor >= 0 then
            invoker.call(0x6AF0636DDEDCB6DD, vehicle, 16, maxArmor, false) -- SET_VEHICLE_MOD for armor
        end
    end
    util.yield(20)
    
    -- Turbo (18) - force apply multiple times using TOGGLE_VEHICLE_MOD
    for i = 1, 3 do
        invoker.call(0x2A1F4F37F95BAD08, vehicle, 18, true) -- TOGGLE_VEHICLE_MOD for turbo (true = enable)
        util.yield(20)
    end
    
    -- Set vehicle color to blue (primary and secondary)
    -- Blue color: R=0, G=100, B=255 (bright blue)
    invoker.call(0x7141766F91D15BEA, vehicle, 0, 100, 255) -- SET_VEHICLE_CUSTOM_PRIMARY_COLOUR (blue)
    invoker.call(0x36CED73BFED89754, vehicle, 0, 100, 255) -- SET_VEHICLE_CUSTOM_SECONDARY_COLOUR (blue)
    
    -- Set neon color to blue
    invoker.call(0x8E0A582209A62695, vehicle, 0, 100, 255) -- SET_VEHICLE_NEON_COLOUR (blue)
    
    -- Set number plate text to "Shillen"
    invoker.call(0x95A88F0B409CDA47, vehicle, "Shillen") -- SET_VEHICLE_NUMBER_PLATE_TEXT
    
    -- Set max engine and other upgrades
    util.yield(50)
end

-- Rainbow color thread for vehicles
util.create_thread(function()
    while true do
        if #vehicle_settings.rainbowVehicles > 0 then
            vehicle_settings.rainbowColorIndex = (vehicle_settings.rainbowColorIndex + 1) % 360
            
            -- Calculate RGB from HSL (hue rotation)
            local hue = vehicle_settings.rainbowColorIndex
            local h = hue / 60
            local c = 1.0
            local x = c * (1 - math.abs((h % 2) - 1))
            local r, g, b = 0, 0, 0
            
            if h < 1 then r, g, b = c, x, 0
            elseif h < 2 then r, g, b = x, c, 0
            elseif h < 3 then r, g, b = 0, c, x
            elseif h < 4 then r, g, b = 0, x, c
            elseif h < 5 then r, g, b = x, 0, c
            else r, g, b = c, 0, x
            end
            
            local red = math.floor(r * 255)
            local green = math.floor(g * 255)
            local blue = math.floor(b * 255)
            
            -- Apply rainbow color to all vehicles in list
            for i = #vehicle_settings.rainbowVehicles, 1, -1 do
                local veh = vehicle_settings.rainbowVehicles[i]
                if veh and veh ~= 0 and invoker and invoker.call then
                    -- Check if vehicle still exists
                    local exists = invoker.call(0x7239B21A38F536BA, veh) -- DOES_ENTITY_EXIST
                    if exists and exists.bool then
                        -- Set primary and secondary colors
                        invoker.call(0x7141766F91D15BEA, veh, red, green, blue) -- SET_VEHICLE_CUSTOM_PRIMARY_COLOUR
                        invoker.call(0x36CED73BFED89754, veh, red, green, blue) -- SET_VEHICLE_CUSTOM_SECONDARY_COLOUR
                        -- Set neon color
                        invoker.call(0x8E0A582209A62695, veh, red, green, blue) -- SET_VEHICLE_NEON_COLOUR
                    else
                        -- Remove from list if vehicle no longer exists
                        table.remove(vehicle_settings.rainbowVehicles, i)
                    end
                else
                    table.remove(vehicle_settings.rainbowVehicles, i)
                end
            end
        end
        
        util.yield(50) -- Update every 50ms for smooth rainbow effect
    end
end)

-- Start rainbow effect for a vehicle
local function start_rainbow_vehicle(vehicle)
    -- Vehicle is already added to rainbowVehicles list in spawn function
    -- The thread will handle the color changes
end

-- Boost thread - checks for E key press and applies boost
util.create_thread(function()
    while true do
        if vehicle_settings.boostEnabled then
            local success, err = pcall(function()
                -- Check if player is in a vehicle as driver
                local ped = nil
                if players and players.me then
                    local player = players.me()
                    if player then
                        ped = player.ped
                    end
                end
                
                -- Fallback: use native function
                if not ped or ped == 0 then
                    local ped_result = invoker.call(0xD80958FC74E988A6) -- PLAYER_PED_ID
                    if ped_result and ped_result.int then
                        ped = ped_result.int
                    end
                end
                
                if ped and ped ~= 0 then
                    -- Check if ped is in a vehicle
                    local vehicle_result = invoker.call(0x9A9112A0FE9A4713, ped, false) -- GET_VEHICLE_PED_IS_IN
                    if vehicle_result and vehicle_result.int and vehicle_result.int ~= 0 then
                        local vehicle = vehicle_result.int
                        
                        -- Check if vehicle exists
                        local exists = invoker.call(0x7239B21A38F536BA, vehicle) -- DOES_ENTITY_EXIST
                        if exists and exists.bool then
                            -- Check if ped is driver (seat -1 = driver)
                            local seat_result = invoker.call(0xBB40DD2270B65366, vehicle, -1, false) -- GET_PED_IN_VEHICLE_SEAT
                            if seat_result and seat_result.int == ped then
                                -- Check if E key is JUST pressed (not held) - only E key, no F key
                                local e_pressed = false
                                
                                -- Method 1: Try using input.key (Lexis API) - only just_pressed, not pressed (no hold)
                                -- Only check for E key (ASCII 69), not F key (ASCII 70)
                                if input and input.key then
                                    local e_key = input.key(69) -- E key ASCII code (69 = E, 70 = F)
                                    if e_key and e_key.just_pressed then
                                        e_pressed = true
                                    end
                                end
                                
                                -- Method 2: Try IS_CONTROL_JUST_PRESSED - only E key (control 38 = Context/E)
                                -- Control 51 = Enter Vehicle/F - REMOVED
                                -- Control 23 = Enter - REMOVED (might also be F)
                                if not e_pressed then
                                    local e1 = invoker.call(0x580417101DDB492F, 0, 38) -- IS_CONTROL_JUST_PRESSED (Context/E key only)
                                    
                                    -- Check if F key is NOT pressed to prevent F from triggering boost
                                    local f_key_pressed = false
                                    if input and input.key then
                                        local f_key = input.key(70) -- F key ASCII code (70 = F)
                                        if f_key and f_key.pressed then
                                            f_key_pressed = true
                                        end
                                    end
                                    
                                    -- Also check control 51 (Enter Vehicle/F) to block F
                                    local f_control = invoker.call(0x580417101DDB492F, 0, 51) -- IS_CONTROL_JUST_PRESSED (Enter Vehicle/F)
                                    if f_control and f_control.bool then
                                        f_key_pressed = true
                                    end
                                    
                                    if e1 and e1.bool and not f_key_pressed then
                                        e_pressed = true
                                    end
                                end
                                
                                if e_pressed then
                                    -- Get current vehicle speed
                                    local speed_result = invoker.call(0xD5037BA82E12416F, vehicle) -- GET_ENTITY_SPEED
                                    local current_speed = 0.0
                                    if speed_result and speed_result.float then
                                        current_speed = speed_result.float
                                    end
                                    
                                    -- Calculate boost force based on strength percentage (0-100)
                                    -- 1% = very weak boost, 100% = very strong boost
                                    -- Convert percentage to actual boost force (1% = 1.0, 100% = 100.0)
                                    local boost_force_multiplier = vehicle_settings.boostStrength / 100.0
                                    local max_boost_force = 100.0
                                    local boost_force = boost_force_multiplier * max_boost_force
                                    
                                    -- Set forward speed to current speed + boost (max 200.0 for very strong boost)
                                    local boost_speed = math.min(current_speed + boost_force, 200.0)
                                    invoker.call(0xAB54A438726D25D5, vehicle, boost_speed) -- SET_VEHICLE_FORWARD_SPEED
                                    
                                    -- Debug notification
                                    if notify then notify.push("Boost", "Boost Applied!", 500) end
                                end
                            end
                        end
                    end
                end
            end)
            
            if not success and err then
                -- Silently handle errors to prevent crashes
            end
        end
        
        util.yield(10) -- Check every 10ms instead of every frame
    end
end)

-- Helper function to delete vehicle (improved from Spawn.lua)
local function delete_vehicle_by_handle(handle)
    if not handle or handle == 0 then return false end

    local success = pcall(function()
        -- Check if entity exists
        local exists_result = invoker.call(0xD42BD6EB2E0F0537, handle) -- DOES_ENTITY_EXIST
        if not exists_result or not exists_result.bool then return end

        -- Request control if available
        if request and request.control then
            request.control(handle, true)
        end

        -- Set as mission entity
        invoker.call(0xAD738C3085FE7E11, handle, false, true) -- SET_ENTITY_AS_MISSION_ENTITY

        -- Delete vehicle
        local ptr = pointer_int()
        ptr.value = handle
        invoker.call(0xEA386986E786A54F, ptr) -- DELETE_VEHICLE
        ptr:free()
    end)

    return success
end

-- Improved vehicle spawn function (based on Spawn.lua)
local function spawn_vehicle(vehicle_name, maxUpgrades, rainbow)
    if spawn_state.loading then
        if notify then notify.push("Vehicle Spawner", "Spawning vehicle...", 2000) end
        return false
    end

    spawn_state.loading = true

    -- Save old vehicle handle for deletion
    local old_vehicle = spawn_state.delete_old_vehicle and spawn_state.last_spawned or nil

    -- Calculate hash
    local hash_result = invoker.call(0xD24D37CC275948CC, vehicle_name) -- GET_HASH_KEY
    if not hash_result or not hash_result.int then
        if notify then notify.push("Vehicle Spawner", "Invalid vehicle name: " .. tostring(vehicle_name), 2000) end
        spawn_state.loading = false
        return false
    end

    local hash = hash_result.int

    -- Use async job for spawning (improved approach from Spawn.lua)
    util.create_job(function()
        -- Delete old vehicle
        if old_vehicle then
            delete_vehicle_by_handle(old_vehicle)
            spawn_state.last_spawned = nil
        end

        -- Load model using request.model if available, otherwise fallback to native
        local model_loaded = false
        if request and request.model then
            model_loaded = request.model(hash)
        else
            -- Fallback: manual model loading
            invoker.call(0x963D27A58DF860AC, hash) -- REQUEST_MODEL
            local timeout = 0
            while timeout < 100 do
                local has_model = invoker.call(0x98A4EB5D89A0C952, hash) -- HAS_MODEL_LOADED
                if has_model and has_model.bool then
                    model_loaded = true
                    break
                end
                util.yield(100)
                timeout = timeout + 1
            end
        end

        if not model_loaded then
            if notify then notify.push("Vehicle Spawner", "Model loading failed: " .. vehicle_name, 2000) end
            spawn_state.loading = false
            return
        end

        -- Get player info
        local ped = nil
        local coords = nil
        local heading = 0.0

        -- Method 1: Try using Lexis API players.me() (recommended)
        local pos_ok = false
        local lexis_ok, lex_err = pcall(function()
            if players and players.me then
                local player = players.me()
                if player and player.coords then
                    coords = {
                        x = player.coords.x or 0.0,
                        y = player.coords.y or 0.0,
                        z = player.coords.z or 0.0
                    }
                    heading = player.heading or 0.0
                    if player.ped then
                        ped = player.ped
                    end
                    pos_ok = (coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0)
                end
            end
        end)

        -- Method 2: Try using pools.ped.get_local() and entity.position()
        if not pos_ok and pools and pools.ped then
            local pool_ok, pool_err = pcall(function()
                local player_ped = pools.ped.get_local()
                if player_ped then
                    ped = player_ped
                    if entity and entity.position then
                        local pos = entity.position(player_ped)
                        if pos and pos.x and pos.y and pos.z then
                            coords = { x = pos.x, y = pos.y, z = pos.z }
                            pos_ok = true
                        end
                    end
                end
            end)
        end

        -- Method 3: Fallback to native methods
        if not pos_ok then
            if invoker and invoker.call then
                -- Get player ped
                local result = invoker.call(0xD80958FC74E988A6) -- PLAYER_PED_ID
                if result and result.int and result.int ~= 0 then
                    ped = result.int
                end

                if ped and ped ~= 0 then
                    -- Get position
                    local pos_result = invoker.call(0x3FEF770D40960D5A, ped, true) -- GET_ENTITY_COORDS
                    if pos_result and pos_result.vec3 then
                        coords = {
                            x = pos_result.vec3.x,
                            y = pos_result.vec3.y,
                            z = pos_result.vec3.z
                        }
                        pos_ok = true
                    end

                    -- Get heading
                    if pos_ok then
                        local heading_result = invoker.call(0xE83D4F9BA2A38914, ped) -- GET_ENTITY_HEADING
                        if heading_result and heading_result.float then
                            heading = heading_result.float
                        end
                    end
                end
            end
        end

        if not pos_ok or not coords then
            if notify then notify.push("Vehicle Spawner", "Cannot get player position", 2000) end
            if not request or not request.model then
                invoker.call(0xE532F5D78798DAAB, hash) -- SET_MODEL_AS_NO_LONGER_NEEDED
            end
            spawn_state.loading = false
            return
        end

        -- Calculate spawn position (improved: 5m in front of player, not 2m to the side)
        local math_sin = math.sin
        local math_cos = math.cos
        local math_rad = math.rad
        local spawn_x = coords.x - math_sin(math_rad(heading)) * 5.0
        local spawn_y = coords.y + math_cos(math_rad(heading)) * 5.0
        local spawn_z = coords.z

        -- Aircraft spawn in air (if enabled)
        if spawn_state.spawn_in_air then
            local is_plane = invoker.call(0x9C8C3EC3970DBF9B, hash) -- IS_THIS_MODEL_A_PLANE
            local is_heli = invoker.call(0x51455483CF23ED97, hash) -- IS_THIS_MODEL_A_HELI
            if (is_plane and is_plane.bool) or (is_heli and is_heli.bool) then
                spawn_z = spawn_z + 200.0  -- Spawn 200m above player
            end
        end

        -- Create vehicle
        local vehicle_result = invoker.call(0xAF35D0D2583051B0, hash, spawn_x, spawn_y, spawn_z, heading, true, true, false) -- CREATE_VEHICLE
        if not request or not request.model then
            invoker.call(0xE532F5D78798DAAB, hash) -- SET_MODEL_AS_NO_LONGER_NEEDED
        end

        if not vehicle_result or not vehicle_result.int or vehicle_result.int == 0 then
            if notify then notify.push("Vehicle Spawner", "Vehicle spawn failed", 2000) end
            spawn_state.loading = false
            return
        end

        local vehicle = vehicle_result.int
        spawn_state.last_spawned = vehicle

        -- Set vehicle on ground properly
        invoker.call(0x49733E92263139D1, vehicle, 1) -- SET_VEHICLE_ON_GROUND_PROPERLY

        -- Prevent vehicle from being treated as stolen (fixes alarm and explosion)
        invoker.call(0x67B2C79AA7FF5738, vehicle, false) -- SET_VEHICLE_IS_STOLEN
        invoker.call(0xFBA550EA44404EE6, vehicle, false) -- SET_VEHICLE_NEEDS_TO_BE_HOTWIRED

        -- Set vehicle as mission entity to prevent deletion
        invoker.call(0xAD738C3085FE7E11, vehicle, true, false) -- SET_ENTITY_AS_MISSION_ENTITY

        -- Apply vehicle modifications if enabled
        if maxUpgrades then
            pcall(function()
                apply_max_vehicle_upgrades(vehicle)
            end)
        end

        -- Apply rainbow colors if enabled
        if rainbow then
            pcall(function()
                table.insert(vehicle_settings.rainbowVehicles, vehicle)
                start_rainbow_vehicle(vehicle)
            end)
        end

        -- Engine on (if enabled)
        if spawn_state.engine_on then
            pcall(function()
                invoker.call(0x2497C4717C8B881E, vehicle, true, true, false) -- SET_VEHICLE_ENGINE_ON
            end)
        end

        -- Teleport player into vehicle as driver
        if ped and ped ~= 0 then
            pcall(function()
                invoker.call(0x9A7D091411C5F684, ped, vehicle, -1) -- TASK_WARP_PED_INTO_VEHICLE
            end)
        end

        if notify then notify.push("Vehicle Spawner", "Spawned: " .. vehicle_name, 2000) end
        spawn_state.loading = false
    end)

    return true
end

-- Spawner Tab Content
local spawnerTab = ui.tabs[3]

-- 2-Seater Vehicles Group
local gSpawner2Seater = ui.group(spawnerTab, "2-Seater Vehicles")
ui.dropdown(gSpawner2Seater, "spawner_vehicle_2seater", "Select Vehicle", vehicles2Seater, 1, function(opt)
    vehicle_settings.selected2Seater = opt
end)
ui.button(gSpawner2Seater, "spawner_spawn_2seater", "Spawn Vehicle", function()
    spawn_vehicle(vehicle_settings.selected2Seater, vehicle_settings.maxUpgrades, vehicle_settings.rainbow)
end)

-- 4-Seater Vehicles Group
local gSpawner4Seater = ui.group(spawnerTab, "4-Seater Vehicles")
ui.dropdown(gSpawner4Seater, "spawner_vehicle_4seater", "Select Vehicle", vehicles4Seater, 1, function(opt)
    selectedVehicle4Seater = opt
end)
ui.button(gSpawner4Seater, "spawner_spawn_4seater", "Spawn Vehicle", function()
    spawn_vehicle(vehicle_settings.selected4Seater, vehicle_settings.maxUpgrades, vehicle_settings.rainbow)
end)

-- Settings Group (shared for both 2-seater and 4-seater)
local gSpawnerSettings = ui.group(spawnerTab, "Settings")
ui.toggle(gSpawnerSettings, "spawner_max_upgrades", "Maximum Upgrades", false, function(state)
    maxUpgrades = state
end)
ui.toggle(gSpawnerSettings, "spawner_rainbow", "Rainbow", false, function(state)
    vehicle_settings.rainbow = state
end)

-- Vehicle Tab Content
local vehicleTab = ui.tabs[4]  -- After spawner (index 3), vehicle is index 4

-- Boost Group in Vehicle Tab
local gVehicleBoost = ui.group(vehicleTab, "Boost")
ui.toggle(gVehicleBoost, "vehicle_boost", "Boost", false, function(state)
    vehicle_settings.boostEnabled = state
end)
ui.slider(gVehicleBoost, "vehicle_boost_strength", "Boost Strength", 0, 100, 50, function(value)
    if value and value >= 0 and value <= 100 then
        boostStrength = math.floor(value)
    end
end, nil, 1)

-- Vehicle Settings Group in Vehicle Tab
local gVehicleSettings = ui.group(vehicleTab, "Vehicle Settings")
local function repair_vehicle()
    local ped = nil
    if players and players.me then
        local player = players.me()
        if player then
            ped = player.ped
        end
    end
    
    if not ped or ped == 0 then
        local ped_result = invoker.call(0xD80958FC74E988A6) -- PLAYER_PED_ID
        if ped_result and ped_result.int then
            ped = ped_result.int
        end
    end
    
    if ped and ped ~= 0 then
        local vehicle_result = invoker.call(0x9A9112A0FE9A4713, ped, false) -- GET_VEHICLE_PED_IS_IN
        if vehicle_result and vehicle_result.int and vehicle_result.int ~= 0 then
            local vehicle = vehicle_result.int
            local exists = invoker.call(0x7239B21A38F536BA, vehicle) -- DOES_ENTITY_EXIST
            if exists and exists.bool then
                invoker.call(0x115722B1B9C14C1C, vehicle) -- SET_VEHICLE_FIXED
                if notify then notify.push("Vehicle Settings", "Vehicle Repaired", 2000) end
            else
                if notify then notify.push("Vehicle Settings", "No Vehicle", 2000) end
            end
        else
            if notify then notify.push("Vehicle Settings", "Not in Vehicle", 2000) end
        end
    end
end
ui.button(gVehicleSettings, "vehicle_repair", "Repair Vehicle", function() repair_vehicle() end)

local function max_upgrade_vehicle()
    local ped = nil
    if players and players.me then
        local player = players.me()
        if player then
            ped = player.ped
        end
    end
    
    if not ped or ped == 0 then
        local ped_result = invoker.call(0xD80958FC74E988A6) -- PLAYER_PED_ID
        if ped_result and ped_result.int then
            ped = ped_result.int
        end
    end
    
    if ped and ped ~= 0 then
        local vehicle_result = invoker.call(0x9A9112A0FE9A4713, ped, false) -- GET_VEHICLE_PED_IS_IN
        if vehicle_result and vehicle_result.int and vehicle_result.int ~= 0 then
            local vehicle = vehicle_result.int
            local exists = invoker.call(0x7239B21A38F536BA, vehicle) -- DOES_ENTITY_EXIST
            if exists and exists.bool then
                -- Use the same function as in spawn_vehicle
                apply_max_vehicle_upgrades(vehicle)
                
                if notify then notify.push("Vehicle Settings", "Vehicle Max Upgraded", 2000) end
            else
                if notify then notify.push("Vehicle Settings", "No Vehicle", 2000) end
            end
        else
            if notify then notify.push("Vehicle Settings", "Not in Vehicle", 2000) end
        end
    end
end
ui.button(gVehicleSettings, "vehicle_max_upgrade", "Max Upgrade", function() max_upgrade_vehicle() end)
ui.toggle(gVehicleSettings, "vehicle_godmode", "Godmode", false, function(state)
    vehicle_settings.godmodeEnabled = state
    local playerId = 0  -- Local player
    
    -- Enable/disable player invincibility
    if vehicle_settings.godmodeEnabled then
        invoker.call(0x239528EACDC3E7DE, playerId, true) -- SET_PLAYER_INVINCIBLE
        if notify then notify.push("Vehicle Settings", "Godmode Enabled", 2000) end
    else
        invoker.call(0x239528EACDC3E7DE, playerId, false) -- SET_PLAYER_INVINCIBLE
        -- Immediately disable godmode for all tracked vehicles
        for vehicle, _ in pairs(vehicle_settings.godmodeVehicles) do
            local exists = invoker.call(0x7239B21A38F536BA, vehicle) -- DOES_ENTITY_EXIST
            if exists and exists.bool then
                -- Disable vehicle invincibility
                invoker.call(0x3882114BDE571AD4, vehicle, false) -- SET_ENTITY_INVINCIBLE
                -- Enable vehicle can be damaged
                invoker.call(0x4C7028F78FFD3681, vehicle, true) -- SET_VEHICLE_CAN_BE_VISIBLY_DAMAGED
                -- Allow vehicle to explode
                invoker.call(0x71B0892EC081D60A, vehicle, true) -- SET_VEHICLE_EXPLODES_ON_HIGH_EXPLOSION_DAMAGE
            end
        end
        -- Clear tracking
        vehicle_settings.godmodeVehicles = {}
        if notify then notify.push("Vehicle Settings", "Godmode Disabled", 2000) end
    end
end)

-- Thread to keep vehicle invincible when godmode is enabled
util.create_thread(function()
    while true do
        local success, err = pcall(function()
            if vehicle_settings.godmodeEnabled then
                -- Get player ped
                local ped = nil
                if players and players.me then
                    local player = players.me()
                    if player then
                        ped = player.ped
                    end
                end
                
                if not ped or ped == 0 then
                    local ped_result = invoker.call(0xD80958FC74E988A6) -- PLAYER_PED_ID
                    if ped_result and ped_result.int then
                        ped = ped_result.int
                    end
                end
                
                if ped and ped ~= 0 then
                    -- Check if ped is in a vehicle
                    local vehicle_result = invoker.call(0x9A9112A0FE9A4713, ped, false) -- GET_VEHICLE_PED_IS_IN
                    if vehicle_result and vehicle_result.int and vehicle_result.int ~= 0 then
                        local vehicle = vehicle_result.int
                        local exists = invoker.call(0x7239B21A38F536BA, vehicle) -- DOES_ENTITY_EXIST
                        if exists and exists.bool then
                            -- Make vehicle invincible
                            invoker.call(0x3882114BDE571AD4, vehicle, true) -- SET_ENTITY_INVINCIBLE
                            -- Also set vehicle can be damaged to false
                            invoker.call(0x4C7028F78FFD3681, vehicle, false) -- SET_VEHICLE_CAN_BE_VISIBLY_DAMAGED
                            -- Prevent vehicle from exploding
                            invoker.call(0x71B0892EC081D60A, vehicle, false) -- SET_VEHICLE_EXPLODES_ON_HIGH_EXPLOSION_DAMAGE
                            -- Track this vehicle
                            vehicle_settings.godmodeVehicles[vehicle] = true
                        end
                    end
                end
            else
                -- When godmode is disabled, disable it for all tracked vehicles
                for vehicle, _ in pairs(vehicle_settings.godmodeVehicles) do
                    local exists = invoker.call(0x7239B21A38F536BA, vehicle) -- DOES_ENTITY_EXIST
                    if exists and exists.bool then
                        -- Disable vehicle invincibility
                        invoker.call(0x3882114BDE571AD4, vehicle, false) -- SET_ENTITY_INVINCIBLE
                        -- Enable vehicle can be damaged
                        invoker.call(0x4C7028F78FFD3681, vehicle, true) -- SET_VEHICLE_CAN_BE_VISIBLY_DAMAGED
                        -- Allow vehicle to explode
                        invoker.call(0x71B0892EC081D60A, vehicle, true) -- SET_VEHICLE_EXPLODES_ON_HIGH_EXPLOSION_DAMAGE
                    end
                    -- Remove from tracking
                    vehicle_settings.godmodeVehicles[vehicle] = nil
                end
            end
        end)
        util.yield(100) -- Check every 100ms
    end
end)

-- Objects Tab Content
local otherTab = ui.tabs[5]  -- After vehicle (index 4), other is index 5

-- Helper function for debug logging
local function debug_log(hypothesisId, location, message, data)
    local logPath = ".cursor/debug.log"
    local timestamp = os.time() * 1000
    local dataStr = ""
    if data then
        local parts = {}
        for k, v in pairs(data) do
            if type(v) == "string" then
                table.insert(parts, '"' .. k .. '":"' .. tostring(v) .. '"')
            else
                table.insert(parts, '"' .. k .. '":' .. tostring(v))
            end
        end
        dataStr = "{" .. table.concat(parts, ",") .. "}"
    else
        dataStr = "{}"
    end
    local jsonStr = string.format('{"sessionId":"debug-session","runId":"run1","hypothesisId":"%s","location":"%s","message":"%s","data":%s,"timestamp":%d}', 
        hypothesisId, location, message, dataStr, timestamp)
    local file = io.open(logPath, "a")
    if file then
        file:write(jsonStr .. "\n")
        file:close()
    end
end

-- Function to instantly enter vehicle (skip animation)
local function instant_enter_vehicle()
    util.create_job(function()
        -- Step 1: Get player ped using native
        local pedResult = invoker.call(0xD80958FC74E988A6) -- PLAYER_PED_ID
        local playerPed = pedResult and pedResult.int or 0
        
        if playerPed == 0 then
            if notify then notify.push("Vehicle Entry", "Player not found", 2000) end
            return
        end
        
        -- Step 2: Check if already in vehicle
        local inVehResult = invoker.call(0x997ABD671D25CA0B, playerPed, false) -- IS_PED_IN_ANY_VEHICLE
        local isInVehicle = inVehResult and inVehResult.bool or false
        
        if isInVehicle then
            if notify then notify.push("Vehicle Entry", "Already in vehicle", 2000) end
            return
        end
        
        -- Step 3: Get player position (AVOID GET_ENTITY_MATRIX - causes crashes)
        local playerPos = nil
        
        -- Method 1: Try players.me() from Lexis API
        if players and players.me then
            local meSuccess, meResult = pcall(function()
                local me = players.me()
                if me and me.coords then
                    return {
                        x = me.coords.x or 0.0,
                        y = me.coords.y or 0.0,
                        z = me.coords.z or 0.0
                    }
                end
                return nil
            end)
            
            if meSuccess and meResult and meResult.x and (meResult.x ~= 0 or meResult.y ~= 0 or meResult.z ~= 0) then
                playerPos = meResult
            end
        end
        
        -- Method 2: Try GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS with offset 0,0,0
        if not playerPos then
            local offsetResult = invoker.call(0x1899F328B0E12848, playerPed, 0.0, 0.0, 0.0) -- GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS
            if offsetResult then
                if offsetResult.vec3 then
                    playerPos = offsetResult.vec3
                elseif offsetResult.x then
                    playerPos = {x = offsetResult.x, y = offsetResult.y, z = offsetResult.z}
                end
            end
        end
        
        -- Method 3: Fallback to GET_ENTITY_COORDS (last resort)
        if not playerPos then
            local coordsResult = invoker.call(0x3FEF770D40960D5A, playerPed, true) -- GET_ENTITY_COORDS
            if coordsResult then
                if coordsResult.vec3 then
                    playerPos = coordsResult.vec3
                elseif coordsResult.x then
                    playerPos = {x = coordsResult.x, y = coordsResult.y, z = coordsResult.z}
                elseif type(coordsResult) == "table" and coordsResult[1] then
                    playerPos = {x = coordsResult[1], y = coordsResult[2], z = coordsResult[3]}
                end
            end
        end
        
        if not playerPos or not playerPos.x or (playerPos.x == 0 and playerPos.y == 0 and playerPos.z == 0) then
            if notify then notify.push("Vehicle Entry", "Failed to get position", 2000) end
            return
        end
        
        -- Step 4: Find closest vehicle from pool
        local closestVehicle = 0
        local minDistance = 50.0  -- Max search radius
        local vehicleCount = 0
        local checkedCount = 0
        
        -- Try multiple methods to get all vehicles
        local allVehicles = nil
        
        -- Method 1: Try pools.vehicle.get_all() (if pools is a table)
        local poolSuccess, poolError = pcall(function()
            if type(pools) == "table" and pools.vehicle and pools.vehicle.get_all then
                return pools.vehicle.get_all()
            elseif type(pools) == "function" then
                -- pools might be a function
                local poolsTable = pools()
                if poolsTable and poolsTable.vehicle and poolsTable.vehicle.get_all then
                    return poolsTable.vehicle.get_all()
                end
            end
            return nil
        end)
        
        if poolSuccess then
            allVehicles = poolError  -- pcall returns (success, result)
        end
        
        if allVehicles then
            vehicleCount = #allVehicles
            
            for _, veh in ipairs(allVehicles) do
                if veh and veh ~= 0 then
                    checkedCount = checkedCount + 1
                    -- Check vehicle exists
                    local existsResult = invoker.call(0x7239B21A38F536BA, veh) -- DOES_ENTITY_EXIST
                    if existsResult and existsResult.bool then
                        -- Check if vehicle has a driver (player or NPC)
                        local driverResult = invoker.call(0xBB40DD2270B65366, veh, -1, 0) -- GET_PED_IN_VEHICLE_SEAT
                        local driverPed = driverResult and driverResult.int or 0
                        local hasDriver = driverPed ~= 0
                        local isPlayerDriver = false
                        
                        if hasDriver then
                            local isPlayerResult = invoker.call(0x12534C348C6CB68B, driverPed) -- IS_PED_A_PLAYER
                            isPlayerDriver = isPlayerResult and isPlayerResult.bool or false
                        end
                        
                        -- Get vehicle position using GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS (safe method)
                        local vehPos = nil
                        local offsetResult = invoker.call(0x1899F328B0E12848, veh, 0.0, 0.0, 0.0) -- GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS
                        if offsetResult then
                            if offsetResult.vec3 then
                                vehPos = offsetResult.vec3
                            elseif offsetResult.x then
                                vehPos = {x = offsetResult.x, y = offsetResult.y, z = offsetResult.z}
                            end
                        end
                        
                        -- Fallback: Try GET_ENTITY_COORDS
                        if not vehPos or not vehPos.x then
                            local coordsResult = invoker.call(0x3FEF770D40960D5A, veh, true) -- GET_ENTITY_COORDS
                            if coordsResult then
                                if coordsResult.vec3 then
                                    vehPos = coordsResult.vec3
                                elseif coordsResult.x then
                                    vehPos = {x = coordsResult.x, y = coordsResult.y, z = coordsResult.z}
                                end
                            end
                        end
                        
                        if vehPos and vehPos.x then
                            -- Calculate distance
                            local dx = vehPos.x - playerPos.x
                            local dy = vehPos.y - playerPos.y
                            local dz = vehPos.z - playerPos.z
                            local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                            
                            if dist < minDistance then
                                minDistance = dist
                                closestVehicle = veh
                            end
                        end
                    end
                end
            end
        end
        
        -- Note: We'll check for player vehicles in the backup search section
        -- to avoid crashes from GET_ENTITY_MATRIX and position retrieval issues
        
        -- Backup: Use GET_CLOSEST_VEHICLE native
        if closestVehicle == 0 then
            -- Try different flags to find vehicles including player vehicles
            local flags = {0, 70, 71, 16}
            local backupVehicles = {}
            local backupVehiclesWithDist = {}  -- Store vehicles with their distances
            
            for _, flag in ipairs(flags) do
                local result = invoker.call(0xF73EB622C4F1689B, playerPos.x, playerPos.y, playerPos.z, 50.0, 0, flag) -- GET_CLOSEST_VEHICLE
                if result and result.int and result.int ~= 0 then
                    local veh = result.int
                    -- Check if already in list
                    local alreadyFound = false
                    for _, v in ipairs(backupVehicles) do
                        if v == veh then
                            alreadyFound = true
                            break
                        end
                    end
                    
                    if not alreadyFound then
                        table.insert(backupVehicles, veh)
                        
                        -- Try to get vehicle position using players.me() if it's a player vehicle
                        local vehPos = nil
                        local dist = 999999.0
                        local isPlayerVehicle = false  -- Initialize before Method 1
                        local isPlayerDriver = false  -- Initialize before Method 1
                        
                        -- Method 1: Check if this vehicle belongs to any player using natives
                        -- Use GET_NUMBER_OF_PLAYERS and GET_PLAYER_PED to find player vehicles
                        local numPlayers = invoker.call(0x407C7F91DDB46C16) -- GET_NUMBER_OF_PLAYERS
                        local numPlayersInt = numPlayers and numPlayers.int or 0
                        
                        if numPlayersInt > 0 then
                            for checkPlayerId = 0, numPlayersInt - 1 do
                                local checkPedResult = invoker.call(0x43A66C31C68491C0, checkPlayerId) -- GET_PLAYER_PED
                                local checkPlayerPed = checkPedResult and checkPedResult.int or 0
                                
                                if checkPlayerPed ~= 0 then
                                    local checkVehResult = invoker.call(0x9A9112A0FE9A4713, checkPlayerPed, false) -- GET_VEHICLE_PED_IS_IN
                                    local checkVeh = checkVehResult and checkVehResult.int or 0
                                    
                                    -- Also check if player is the driver of this vehicle
                                    local vehDriverResult = invoker.call(0xBB40DD2270B65366, veh, -1, 0) -- GET_PED_IN_VEHICLE_SEAT (driver = -1)
                                    local vehDriverPed = vehDriverResult and vehDriverResult.int or 0
                                    local isPlayerDriverOfVeh = (vehDriverPed ~= 0 and vehDriverPed == checkPlayerPed)
                                    
                                    -- Vehicle belongs to player if: player is in it OR player is the driver
                                    if checkVeh == veh or isPlayerDriverOfVeh then
                                        -- This vehicle belongs to a player, mark it as player vehicle
                                        isPlayerVehicle = true
                                        
                                        -- If player is the driver, set isPlayerDriver
                                        if isPlayerDriverOfVeh then
                                            isPlayerDriver = true
                                        end
                                        
                                        -- Use player's position from players.me() if available
                                        if players and players.me then
                                            local meSuccess, me = pcall(function() return players.me() end)
                                            if meSuccess and me and me.coords then
                                                vehPos = {x = me.coords.x, y = me.coords.y, z = me.coords.z}
                                                break
                                            end
                                        end
                                        break  -- Break even if players.me() fails
                                    end
                                end
                            end
                        end
                        
                        -- Method 2: Try GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS (may return different format)
                        if not vehPos then
                            local offsetResult = invoker.call(0x1899F328B0E12848, veh, 0.0, 0.0, 0.0) -- GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS
                            
                            if offsetResult then
                                -- Try different result formats
                                if type(offsetResult) == "table" then
                                    if offsetResult.vec3 then
                                        vehPos = offsetResult.vec3
                                    elseif offsetResult.x then
                                        vehPos = {x = offsetResult.x, y = offsetResult.y, z = offsetResult.z}
                                    elseif offsetResult[1] then
                                        vehPos = {x = offsetResult[1], y = offsetResult[2], z = offsetResult[3]}
                                    end
                                elseif type(offsetResult) == "userdata" then
                                    -- Try accessing fields directly on userdata
                                    local success, x = pcall(function() return offsetResult.x end)
                                    if success and x then
                                        local success2, y = pcall(function() return offsetResult.y end)
                                        local success3, z = pcall(function() return offsetResult.z end)
                                        if success2 and y and success3 and z then
                                            vehPos = {x = x, y = y, z = z}
                                        end
                                    end
                                    -- Try vec3 field
                                    if not vehPos then
                                        local success, vec3 = pcall(function() return offsetResult.vec3 end)
                                        if success and vec3 then
                                            vehPos = vec3
                                        end
                                    end
                                end
                            end
                        end
                        
                        -- Method 3: Try GET_ENTITY_COORDS (may return different format)
                        if not vehPos then
                            local coordsResult = invoker.call(0x3FEF770D40960D5A, veh, true) -- GET_ENTITY_COORDS
                            
                            if coordsResult then
                                if type(coordsResult) == "table" then
                                    if coordsResult.vec3 then
                                        vehPos = coordsResult.vec3
                                    elseif coordsResult.x then
                                        vehPos = {x = coordsResult.x, y = coordsResult.y, z = coordsResult.z}
                                    elseif coordsResult[1] then
                                        vehPos = {x = coordsResult[1], y = coordsResult[2], z = coordsResult[3]}
                                    end
                                elseif type(coordsResult) == "userdata" then
                                    -- Try accessing fields directly on userdata
                                    local success, x = pcall(function() return coordsResult.x end)
                                    if success and x then
                                        local success2, y = pcall(function() return coordsResult.y end)
                                        local success3, z = pcall(function() return coordsResult.z end)
                                        if success2 and y and success3 and z then
                                            vehPos = {x = x, y = y, z = z}
                                        end
                                    end
                                    -- Try vec3 field
                                    if not vehPos then
                                        local success, vec3 = pcall(function() return coordsResult.vec3 end)
                                        if success and vec3 then
                                            vehPos = vec3
                                        end
                                    end
                                end
                            end
                        end
                        
                        -- Method 4: If still no position, try using GET_CLOSEST_VEHICLE result directly
                        -- Since GET_CLOSEST_VEHICLE already returns the closest vehicle, we can use it
                        
                        -- Check if vehicle has a player driver (do this before checking position)
                        -- Only check if not already set in Method 1
                        if not isPlayerDriver then
                            local driverResult = invoker.call(0xBB40DD2270B65366, veh, -1, 0) -- GET_PED_IN_VEHICLE_SEAT
                            local driverPed = driverResult and driverResult.int or 0
                            
                            if driverPed ~= 0 then
                                local isPlayerResult = invoker.call(0x12534C348C6CB68B, driverPed) -- IS_PED_A_PLAYER
                                isPlayerDriver = isPlayerResult and isPlayerResult.bool or false
                                
                                -- Alternative check: compare driverPed with all player peds
                                if not isPlayerDriver then
                                    local numPlayers = invoker.call(0x407C7F91DDB46C16) -- GET_NUMBER_OF_PLAYERS
                                    local numPlayersInt = numPlayers and numPlayers.int or 0
                                    
                                    if numPlayersInt > 0 then
                                        for checkPlayerId = 0, numPlayersInt - 1 do
                                            local checkPedResult = invoker.call(0x43A66C31C68491C0, checkPlayerId) -- GET_PLAYER_PED
                                            local checkPlayerPed = checkPedResult and checkPedResult.int or 0
                                            
                                            if checkPlayerPed == driverPed then
                                                isPlayerDriver = true
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        
                        -- Also check if vehicle belongs to any player (even if empty) - only if not already set in Method 1
                        if not isPlayerDriver and not isPlayerVehicle then
                            local numPlayers = invoker.call(0x407C7F91DDB46C16) -- GET_NUMBER_OF_PLAYERS
                            local numPlayersInt = numPlayers and numPlayers.int or 0
                            
                            if numPlayersInt > 0 then
                                for checkPlayerId = 0, numPlayersInt - 1 do
                                    local checkPedResult = invoker.call(0x43A66C31C68491C0, checkPlayerId) -- GET_PLAYER_PED
                                    local checkPlayerPed = checkPedResult and checkPedResult.int or 0
                                    
                                    if checkPlayerPed ~= 0 then
                                        local checkVehResult = invoker.call(0x9A9112A0FE9A4713, checkPlayerPed, false) -- GET_VEHICLE_PED_IS_IN
                                        local checkVeh = checkVehResult and checkVehResult.int or 0
                                        
                                        if checkVeh == veh then
                                            isPlayerVehicle = true
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        
                        -- If we got position, calculate distance
                        if vehPos and vehPos.x then
                            local dx = vehPos.x - playerPos.x
                            local dy = vehPos.y - playerPos.y
                            local dz = vehPos.z - playerPos.z
                            dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                            
                            -- Check if vehicle is already in list and update isPlayerVehicle if needed
                            local foundExisting = false
                            for _, vehData in ipairs(backupVehiclesWithDist) do
                                if vehData.vehicle == veh then
                                    -- Update isPlayerVehicle if it's true (preserve player vehicle status)
                                    local wasPlayerVehicle = vehData.isPlayerVehicle
                                    if isPlayerVehicle then
                                        vehData.isPlayerVehicle = true
                                    end
                                    if isPlayerDriver then
                                        vehData.isPlayerDriver = true
                                    end
                                    -- Update distance if this one is closer
                                    if dist < vehData.distance then
                                        vehData.distance = dist
                                    end
                                    
                                    foundExisting = true
                                    break
                                end
                            end
                            
                            if not foundExisting then
                                -- Store vehicle with distance
                                table.insert(backupVehiclesWithDist, {vehicle = veh, distance = dist, isPlayerDriver = isPlayerDriver, isPlayerVehicle = isPlayerVehicle})
                            end
                        else
                            -- If we can't get position, store vehicle with distance 0 (will be prioritized if it's a player vehicle)
                            -- Check if vehicle is already in list and update isPlayerVehicle if needed
                            local foundExisting = false
                            for _, vehData in ipairs(backupVehiclesWithDist) do
                                if vehData.vehicle == veh then
                                    -- Update isPlayerVehicle if it's true (preserve player vehicle status)
                                    local wasPlayerVehicle = vehData.isPlayerVehicle
                                    if isPlayerVehicle then
                                        vehData.isPlayerVehicle = true
                                    end
                                    if isPlayerDriver then
                                        vehData.isPlayerDriver = true
                                    end
                                    
                                    foundExisting = true
                                    break
                                end
                            end
                            
                            if not foundExisting then
                                -- Store vehicle with distance 0 (will be prioritized if it's a player vehicle)
                                table.insert(backupVehiclesWithDist, {vehicle = veh, distance = 0.0, isPlayerDriver = isPlayerDriver, isPlayerVehicle = isPlayerVehicle})
                            end
                        end
                    end
                end
            end
            
            -- If we have vehicles with distances, prioritize player vehicles
            if #backupVehiclesWithDist > 0 then
                local playerVehicles = {}
                local otherVehicles = {}
                
                -- Separate player vehicles from other vehicles
                for _, vehData in ipairs(backupVehiclesWithDist) do
                    if vehData.isPlayerDriver or vehData.isPlayerVehicle then
                        table.insert(playerVehicles, vehData)
                    else
                        table.insert(otherVehicles, vehData)
                    end
                end
                
                -- First, find closest player vehicle (prioritize player vehicles)
                if #playerVehicles > 0 then
                    local closestPlayerVehicle = nil
                    local closestPlayerDist = 999999.0
                    
                    for _, vehData in ipairs(playerVehicles) do
                        -- Check if vehicle has a driver at selection time
                        local driverResult = invoker.call(0xBB40DD2270B65366, vehData.vehicle, -1, 0) -- GET_PED_IN_VEHICLE_SEAT
                        local currentDriverPed = driverResult and driverResult.int or 0
                        local hasDriverNow = currentDriverPed ~= 0 and currentDriverPed ~= playerPed
                        
                        -- If distance is 0, it means we couldn't get position, but it's a player vehicle - prioritize it
                        local effectiveDist = vehData.distance
                        if effectiveDist == 0.0 then
                            effectiveDist = 0.1  -- Give it a very small distance to prioritize it
                        end
                        
                        -- Prioritize player vehicles with drivers (they need to be removed)
                        if hasDriverNow then
                            effectiveDist = effectiveDist * 0.5  -- Make it even closer to prioritize vehicles with drivers
                        end
                        
                        if effectiveDist < closestPlayerDist then
                            closestPlayerDist = effectiveDist
                            closestPlayerVehicle = vehData
                            
                        end
                    end
                    
                    if closestPlayerVehicle then
                        minDistance = closestPlayerDist
                        closestVehicle = closestPlayerVehicle.vehicle
                    end
                end
                
                -- If no player vehicle found, find closest other vehicle
                if closestVehicle == 0 then
                    for _, vehData in ipairs(otherVehicles) do
                        if vehData.distance < minDistance then
                            minDistance = vehData.distance
                            closestVehicle = vehData.vehicle
                        end
                    end
                end
            end
        end
        
        if closestVehicle == 0 then
            if notify then notify.push("Vehicle Entry", "No vehicle nearby", 2000) end
            return
        end
        
        -- Step 5: Force unlock vehicle (all methods)
        invoker.call(0xB664292EAECF7FA6, closestVehicle, 1) -- SET_VEHICLE_DOORS_LOCKED = unlocked
        invoker.call(0xA2F80B8D040727CC, closestVehicle, false) -- SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS
        
        local playerIdResult = invoker.call(0x4F8644AF03D0E0D6) -- PLAYER_ID
        local playerId = playerIdResult and playerIdResult.int or 0
        if playerId ~= 0 then
            invoker.call(0x517AAF684BB50CD1, closestVehicle, playerId, false) -- SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER
        end
        
        util.yield(50)
        
        -- Step 6: Remove current driver if exists
        local driverResult = invoker.call(0xBB40DD2270B65366, closestVehicle, -1, 0) -- GET_PED_IN_VEHICLE_SEAT (driver = -1)
        local driverPed = driverResult and driverResult.int or 0
        
        if driverPed ~= 0 and driverPed ~= playerPed then
            -- Check if driver is a player using multiple methods
            local isPlayerResult = invoker.call(0x12534C348C6CB68B, driverPed) -- IS_PED_A_PLAYER
            local isPlayer = isPlayerResult and isPlayerResult.bool or false
            
            -- Alternative check: compare driverPed with all player peds
            if not isPlayer then
                local numPlayers = invoker.call(0x407C7F91DDB46C16) -- GET_NUMBER_OF_PLAYERS
                local numPlayersInt = numPlayers and numPlayers.int or 0
                
                if numPlayersInt > 0 then
                    for checkPlayerId = 0, numPlayersInt - 1 do
                        local checkPedResult = invoker.call(0x43A66C31C68491C0, checkPlayerId) -- GET_PLAYER_PED
                        local checkPlayerPed = checkPedResult and checkPedResult.int or 0
                        
                        if checkPlayerPed == driverPed then
                            isPlayer = true
                            break
                        end
                    end
                end
            end
            
            -- Clear driver tasks
            invoker.call(0xAAA34F8A7CB32098, driverPed) -- CLEAR_PED_TASKS_IMMEDIATELY
            util.yield(50)
            
            -- Try multiple methods to remove driver
            if isPlayer then
                -- For players: use more aggressive methods
                -- Method 1: Clear all tasks first
                invoker.call(0xAAA34F8A7CB32098, driverPed) -- CLEAR_PED_TASKS_IMMEDIATELY
                util.yield(100)
                
                -- Method 2: TASK_LEAVE_VEHICLE with warp flag
                invoker.call(0xD3DBCE61A490BE02, driverPed, closestVehicle, 16) -- TASK_LEAVE_VEHICLE (16 = warp out)
                util.yield(300)
                
                -- Method 3: If still in vehicle, force teleport out
                local stillInSeat = invoker.call(0xBB40DD2270B65366, closestVehicle, -1, 0)
                local stillInSeatPed = stillInSeat and stillInSeat.int or 0
                
                if stillInSeatPed == driverPed then
                    -- Force teleport driver out
                    local driverPos = nil
                    if players and players.me then
                        local me = players.me()
                        if me and me.coords then
                            driverPos = {x = me.coords.x + 5.0, y = me.coords.y + 5.0, z = me.coords.z}
                        end
                    end
                    
                    if not driverPos then
                        -- Fallback: use vehicle position
                        local vehCoords = invoker.call(0x3FEF770D40960D5A, closestVehicle, true) -- GET_ENTITY_COORDS
                        if vehCoords and vehCoords.x then
                            driverPos = {x = vehCoords.x + 5.0, y = vehCoords.y + 5.0, z = vehCoords.z}
                        end
                    end
                    
                    if driverPos then
                        invoker.call(0x06843DA7060A026B, driverPed, driverPos.x, driverPos.y, driverPos.z, false, false, false, false) -- SET_ENTITY_COORDS
                        util.yield(200)
                    end
                end
            else
                -- For NPCs: standard method
                invoker.call(0xD3DBCE61A490BE02, driverPed, closestVehicle, 16) -- TASK_LEAVE_VEHICLE (16 = warp out)
                util.yield(100)
            end
            
            -- Final check: wait for driver to leave (max 4 seconds for players, 2 seconds for NPCs)
            local maxWait = isPlayer and 80 or 40  -- 80 * 50ms = 4 seconds for players, 40 * 50ms = 2 seconds for NPCs
            local waitCount = 0
            while waitCount < maxWait do
                util.yield(50)
                local checkResult = invoker.call(0xBB40DD2270B65366, closestVehicle, -1, 0) -- GET_PED_IN_VEHICLE_SEAT
                local checkPed = checkResult and checkResult.int or 0
                
                if checkPed == 0 or checkPed ~= driverPed then
                    break  -- Driver left
                end
                waitCount = waitCount + 1
            end
            
            -- If player driver still in vehicle after waiting, try one more force eject
            if isPlayer and waitCount >= maxWait then
                local finalCheck = invoker.call(0xBB40DD2270B65366, closestVehicle, -1, 0)
                local finalCheckPed = finalCheck and finalCheck.int or 0
                
                if finalCheckPed == driverPed then
                    -- Get vehicle position and teleport driver far away
                    local vehCoords = invoker.call(0x3FEF770D40960D5A, closestVehicle, true)
                    if vehCoords and vehCoords.x then
                        invoker.call(0x06843DA7060A026B, driverPed, vehCoords.x + 10.0, vehCoords.y + 10.0, vehCoords.z + 2.0, false, false, false, false)
                        util.yield(200)
                    end
                end
            end
        end
        
        -- Step 7: Clear player tasks and warp into vehicle
        invoker.call(0xAAA34F8A7CB32098, playerPed) -- CLEAR_PED_TASKS_IMMEDIATELY
        util.yield(50)
        
        -- Warp player into driver seat
        invoker.call(0x9A7D091411C5F684, playerPed, closestVehicle, -1) -- TASK_WARP_PED_INTO_VEHICLE
        util.yield(100)
        
        -- Verify and notify
        local checkResult = invoker.call(0x9A9112A0FE9A4713, playerPed, false) -- GET_VEHICLE_PED_IS_IN
        local inVehicle = checkResult and checkResult.int and checkResult.int == closestVehicle
        
        if inVehicle then
            if notify then notify.push("Vehicle Entry", "Entered (" .. string.format("%.1f", minDistance) .. "m)", 2000) end
        else
            -- Fallback: SET_PED_INTO_VEHICLE
            invoker.call(0xF75B0D629E1C063D, playerPed, closestVehicle, -1)
            if notify then notify.push("Vehicle Entry", "Force entered", 2000) end
        end
    end)
end

-- Simplified nearest-vehicle entry (override to ensure closest vehicle is used)
instant_enter_vehicle = function()
    util.create_job(function()
        if not invoker or not invoker.call then
            if notify then notify.push("Vehicle Entry", "Invoker unavailable", 2000) end
            return
        end

        local pedResult = invoker.call(0xD80958FC74E988A6) -- PLAYER_PED_ID
        local playerPed = pedResult and pedResult.int or 0
        if playerPed == 0 then
            if notify then notify.push("Vehicle Entry", "Player not found", 2000) end
            return
        end

        local inVehResult = invoker.call(0x997ABD671D25CA0B, playerPed, false) -- IS_PED_IN_ANY_VEHICLE
        if inVehResult and inVehResult.bool then
            if notify then notify.push("Vehicle Entry", "Already in vehicle", 2000) end
            return
        end

        -- Robust player position: players.me() -> GET_ENTITY_COORDS -> GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS
        local p = nil
        if players and players.me then
            local ok, res = pcall(function()
                local me = players.me()
                if me and me.coords then
                    return {x = me.coords.x or 0.0, y = me.coords.y or 0.0, z = me.coords.z or 0.0}
                end
                return nil
            end)
            if ok and res and (res.x ~= 0 or res.y ~= 0 or res.z ~= 0) then
                p = res
            end
        end

        if not p then
            local coordsResult = invoker.call(0x3FEF770D40960D5A, playerPed, true) -- GET_ENTITY_COORDS
            if coordsResult then
                if coordsResult.vec3 then
                    p = coordsResult.vec3
                elseif coordsResult.x then
                    p = {x = coordsResult.x, y = coordsResult.y, z = coordsResult.z}
                elseif coordsResult[1] then
                    p = {x = coordsResult[1], y = coordsResult[2], z = coordsResult[3]}
                end
            end
        end

        if not p then
            local offsetResult = invoker.call(0x1899F328B0E12848, playerPed, 0.0, 0.0, 0.0) -- GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS
            if offsetResult then
                if offsetResult.vec3 then
                    p = offsetResult.vec3
                elseif offsetResult.x then
                    p = {x = offsetResult.x, y = offsetResult.y, z = offsetResult.z}
                end
            end
        end

        if not p or not p.x or (p.x == 0 and p.y == 0 and p.z == 0) then
            if notify then notify.push("Vehicle Entry", "Failed to get position", 2000) end
            return
        end

        local function get_closest(radius, flag)
            local res = invoker.call(0xF73EB622C4F1689B, p.x, p.y, p.z, radius, 0, flag) -- GET_CLOSEST_VEHICLE
            return res and res.int or 0
        end

        -- Use small radius first; include player/NPC vehicles (flag 70). Fallbacks widen search.
        local closestVehicle = get_closest(40.0, 70)
        if closestVehicle == 0 then closestVehicle = get_closest(40.0, 0) end
        if closestVehicle == 0 then closestVehicle = get_closest(80.0, 70) end
        if closestVehicle == 0 then
            if notify then notify.push("Vehicle Entry", "No vehicle nearby", 2000) end
            return
        end

        if request and request.control then
            request.control(closestVehicle, true)
        end

        local driverResult = invoker.call(0xBB40DD2270B65366, closestVehicle, -1, 0)
        local driverPed = driverResult and driverResult.int or 0
        local seatToUse = -1

        if driverPed ~= 0 then
            local isPlayerResult = invoker.call(0x12534C348C6CB68B, driverPed) -- IS_PED_A_PLAYER
            local driverIsPlayer = isPlayerResult and isPlayerResult.bool or false
            if driverIsPlayer then
                seatToUse = 0 -- ride as passenger when a player drives
            else
                invoker.call(0xD3DBCE61A490BE02, driverPed, closestVehicle, 16) -- TASK_LEAVE_VEHICLE warp out
                util.yield(200)
                seatToUse = -1 -- take driver seat
            end
        end

        invoker.call(0xAAA34F8A7CB32098, playerPed) -- CLEAR_PED_TASKS_IMMEDIATELY
        util.yield(50)
        invoker.call(0x9A7D091411C5F684, playerPed, closestVehicle, seatToUse) -- TASK_WARP_PED_INTO_VEHICLE
        util.yield(150)

        local checkResult = invoker.call(0x9A9112A0FE9A4713, playerPed, false) -- GET_VEHICLE_PED_IS_IN
        local inVehicle = checkResult and checkResult.int and checkResult.int ~= 0
        if inVehicle then
            if notify then notify.push("Vehicle Entry", seatToUse == -1 and "Entered as driver" or "Entered as passenger", 2000) end
        else
            invoker.call(0xF75B0D629E1C063D, playerPed, closestVehicle, seatToUse)
            if notify then notify.push("Vehicle Entry", "Forced entry", 2000) end
        end
    end)
end

-- Create group and button for Other tab
local gOtherTools = ui.group(otherTab, "Vehicle Tools", nil, nil, nil, nil)
ui.button(gOtherTools, "other_instant_enter", "Instant Enter Vehicle", function() instant_enter_vehicle() end, "Skips enter animation. If NPC is driving - kicks them out. If player is driving - sits as passenger.")

-- Special Objects/Props Spawner (working UFOs and special objects)
-- Define group first so it can be used in spawn_object function
local gSpecialObjects = ui.group(otherTab, "Object Spawner", nil, nil, nil, nil)

-- Forward declaration for Object Controls group (defined later in UI section)
local gObjectControls = nil

-- Object position control variables (relative to spawn position) - grouped to reduce local variables
-- MUST be defined BEFORE spawn_object function that uses it
local object_control = {
    offset_x = 0.0,
    offset_y = 0.0,
    offset_z = 0.0,
    rotation = 0.0,
    spawn_pos = {x = 0.0, y = 0.0, z = 0.0, heading = 0.0}
}

-- Store reference to dropdown for direct updates
local obj_select_dropdown_ref = nil

-- Function to update object selection dropdown
-- MUST be defined BEFORE spawn_object function that uses it
-- Wrapped in pcall for safety
local function update_object_dropdown()
    local success = pcall(function()
        -- Build options list
        local options = {"None"}
        if spawn_state and spawn_state.spawned_objects then
            for i, obj_data in ipairs(spawn_state.spawned_objects) do
                if obj_data and obj_data.name then
                    -- DON'T check does_entity_exist here - it caused crashes
                    -- Instead, just display the name
                    local option_text = "#" .. i .. ": " .. tostring(obj_data.name)
                    table.insert(options, option_text)
                end
            end
        end
        
        -- Always try to find dropdown if reference doesn't exist
        if not obj_select_dropdown_ref then
            if gObjectControls and gObjectControls.items then
                for _, item in ipairs(gObjectControls.items) do
                    if item and item.id == "obj_select" then
                        obj_select_dropdown_ref = item
                        break
                    end
                end
            end
        end
        
        -- Update dropdown if reference exists
        if obj_select_dropdown_ref then
            -- Directly replace options table - create new table to force update
            -- Clear old options first
            obj_select_dropdown_ref.options = {}
            
            -- Add new options one by one
            for i, opt in ipairs(options) do
                obj_select_dropdown_ref.options[i] = opt
            end
            
            -- Update value if valid
            local idx = spawn_state.selected_object_index or 0
            if idx >= 0 and idx <= #options - 1 then
                obj_select_dropdown_ref.value = idx
            else
                obj_select_dropdown_ref.value = 0
                spawn_state.selected_object_index = 0
            end
        end
    end)
    return success
end

-- Function to spawn objects/props (like UFO)
local function spawn_object(model_name)
    -- Reset loading flag if it's been stuck (safety check - max 5 seconds)
    if spawn_state.loading then
        local wait_count = 0
        while spawn_state.loading and wait_count < 50 do
            util.yield(100)
            wait_count = wait_count + 1
        end
        -- If still loading after 5 seconds, force reset
        if spawn_state.loading then
            if notify then notify.push("Object Spawner", "Previous spawn timed out, resetting...", 2000) end
            spawn_state.loading = false
        else
            if notify then notify.push("Object Spawner", "Previous spawn completed, spawning new object...", 1500) end
        end
    end

    spawn_state.loading = true

    -- Calculate hash (z pcall)
    local hash = nil
    local hash_ok = pcall(function()
        hash = native.get_hash_key(model_name)
    end)
    
    if not hash_ok or not hash or hash == 0 then
        if notify then notify.push("Object Spawner", "Invalid model: " .. tostring(model_name), 2000) end
        spawn_state.loading = false
        return false
    end

    -- Use util.create_job for one-time operations
    util.create_job(function()
        -- Load model (z pcall)
        local model_loaded = false
        
        pcall(function()
            if request and request.model then
                model_loaded = request.model(hash)
            else
                native.request_model(hash)
                local timeout = 0
                while timeout < 100 do
                    local loaded = false
                    pcall(function()
                        loaded = native.has_model_loaded(hash)
                    end)
                    if loaded then
                        model_loaded = true
                        break
                    end
                    util.yield(100)
                    timeout = timeout + 1
                end
            end
        end)

        if not model_loaded then
            if notify then notify.push("Object Spawner", "Model load failed: " .. tostring(model_name), 2000) end
            spawn_state.loading = false
            return
        end

        -- Get player info (same approach as spawn_vehicle)
        local ped = nil
        local coords = nil
        local heading = 0.0

        -- Method 1: Try using Lexis API players.me() (recommended)
        local pos_ok = false
        local lexis_ok, lex_err = pcall(function()
            if players and players.me then
                local player = players.me()
                if player and player.coords then
                    coords = {
                        x = player.coords.x or 0.0,
                        y = player.coords.y or 0.0,
                        z = player.coords.z or 0.0
                    }
                    heading = player.heading or 0.0
                    if player.ped then
                        ped = player.ped
                    end
                    pos_ok = (coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0)
                end
            end
        end)

        -- Method 2: Try using pools.ped.get_local() and entity.position()
        if not pos_ok and pools and pools.ped then
            local pool_ok, pool_err = pcall(function()
                local player_ped = pools.ped.get_local()
                if player_ped then
                    ped = player_ped
                    if entity and entity.position then
                        local pos = entity.position(player_ped)
                        if pos and pos.x and pos.y and pos.z then
                            coords = { x = pos.x, y = pos.y, z = pos.z }
                            pos_ok = true
                        end
                    end
                end
            end)
        end

        -- Method 3: Fallback to default position (0, 0, 0)
        if not pos_ok then
            coords = {x = 0.0, y = 0.0, z = 0.0}
            heading = 0.0
            pos_ok = true
        end

        if not pos_ok or not coords then
            if notify then notify.push("Object Spawner", "Cannot get player position", 2000) end
            spawn_state.loading = false
            return
        end

        -- Calculate spawn position (in front of player)
        local spawn_x = coords.x - math.sin(math.rad(heading)) * 5.0
        local spawn_y = coords.y + math.cos(math.rad(heading)) * 5.0
        local spawn_z = coords.z

        -- Create object as LOCAL first (for stable movement)
        -- IMPORTANT: Additional delay before creation
        util.yield(100)
        
        local object_handle = nil
        local create_ok = pcall(function()
            object_handle = native.create_object(hash, spawn_x, spawn_y, spawn_z, false, true, true)
        end)

        if not create_ok or not object_handle or object_handle == 0 then
            if notify then notify.push("Object Spawner", "Spawn failed", 2000) end
            spawn_state.loading = false
            return
        end
        
        -- IMPORTANT: Longer wait for full object creation
        util.yield(500)
        
        -- Verify object still exists after spawn (z pcall)
        local obj_exists_after_spawn = false
        pcall(function()
            obj_exists_after_spawn = native.does_entity_exist(object_handle)
        end)
        
        if not obj_exists_after_spawn then
            if notify then notify.push("Object Spawner", "Object disappeared", 2000) end
            spawn_state.loading = false
            return
        end
        
        -- Additional wait before configuration
        util.yield(100)

        -- Configure object to prevent deletion (keep as local for stable movement)
        if object_handle and object_handle ~= 0 then
            -- Object configuration wrapped in pcall for safety
            pcall(function()
                -- Mark as mission entity FIRST (critical to prevent deletion)
                native.set_entity_as_mission_entity(object_handle, true, true)
            end)
            util.yield(50)
            
            pcall(function()
                -- Make entity invincible to prevent accidental deletion
                native.set_entity_invincible(object_handle, true)
                
                -- Freeze entity and disable gravity for stable control
                native.freeze_entity_position(object_handle, true)
                native.set_entity_has_gravity(object_handle, false)
                
                -- Ensure visibility
                native.set_entity_visible(object_handle, true, false)
            end)
            
            util.yield(100) -- Wait for configuration to apply
        end

        -- Free model (z pcall)
        pcall(function()
            native.set_model_as_no_longer_needed(hash)
        end)

        -- Verify object still exists after configuration
        local obj_exists = false
        pcall(function()
            obj_exists = native.does_entity_exist(object_handle)
        end)
        
        if not obj_exists then
            if notify then notify.push("Object Spawner", "Object disappeared during configuration", 2000) end
            spawn_state.loading = false
            return
        end

        -- Get object heading
        local obj_heading = 0.0
        local heading_ok, heading_result = pcall(function()
            return native.get_entity_heading(object_handle) or 0.0
        end)
        if heading_ok and heading_result then
            obj_heading = heading_result
        end
        
        -- Use spawn position directly (no need to get actual position - it's already set)
        local actual_x = spawn_x or 0.0
        local actual_y = spawn_y or 0.0
        local actual_z = spawn_z or 0.0
        
        -- Save spawn position and reset offsets FIRST (before storing handle)
        if not object_control then
            spawn_state.loading = false
            return
        end
        
        local spawn_pos_table = {
            x = actual_x,
            y = actual_y,
            z = actual_z,
            heading = obj_heading
        }
        object_control.spawn_pos = spawn_pos_table
        
        -- Reset offsets to 0 (object is at spawn position)
        object_control.offset_x = 0.0
        object_control.offset_y = 0.0
        object_control.offset_z = 0.0
        object_control.rotation = obj_heading
        
        -- Add to spawned objects list
        local obj_entry_ok, obj_entry_err = pcall(function()
            table.insert(spawn_state.spawned_objects, {
                handle = object_handle,
                name = model_name,
                model = model_name,
                spawn_pos = {
                    x = actual_x,
                    y = actual_y,
                    z = actual_z,
                    heading = obj_heading
                }
            })
        end)
        
        if not obj_entry_ok then
            spawn_state.loading = false
            return
        end
        
        -- Select the newly spawned object
        spawn_state.selected_object_index = #spawn_state.spawned_objects
        spawn_state.last_spawned_object = object_handle
        
        -- Notification with pcall
        pcall(function()
            if notify then 
                notify.push("Object", "Spawned #" .. tostring(#spawn_state.spawned_objects), 2000) 
            end
        end)
        
        -- Update dropdown with delay
        util.yield(100)
        pcall(update_object_dropdown)
        
        -- Reset slider values
        pcall(function()
            object_control.offset_x = 0.0
            object_control.offset_y = 0.0
            object_control.offset_z = 0.0
        end)
        
        -- CRITICAL: Always reset loading flag at the end
        spawn_state.loading = false
    end)
    
    -- Safety: Reset loading flag after a timeout (in case thread crashes)
    util.create_thread(function()
        util.yield(10000) -- 10 seconds timeout
        if spawn_state.loading then
            spawn_state.loading = false
            if notify then notify.push("Object Spawner", "Spawn timeout - resetting", 2000) end
        end
    end)
end

local special_objects = {
    -- Working UFOs
    {name = "UFO", model = "p_spinning_anus_s"},
    -- Special Objects (verified from props database)
    {name = "Alien Egg", model = "prop_alien_egg_01"},
    {name = "Alien Head", model = "sum_prop_ac_alienhead_01a"},
    -- Large Objects
    {name = "Huge Block", model = "bkr_prop_biker_bblock_huge_01"},
    {name = "Arena War Huge Block", model = "ar_prop_ar_bblock_huge_01"},
    {name = "Biker Jump Ramp", model = "bkr_prop_biker_jump_01a"},
    -- Wind Turbine
    {name = "Wind Turbine (Full)", model = "prop_windmill_01"},
    {name = "Wind Turbine Blades", model = "prop_windmill_01_blade"},
    -- Fun Objects
    {name = "Giant Donut", model = "prop_donut_01"},
    {name = "Toilet", model = "prop_toilet_01"},
    {name = "Shopping Cart", model = "prop_rub_trolley01a"},
    {name = "Christmas Tree", model = "prop_xmas_tree_int"},
    {name = "Traffic Cone", model = "prop_roadcone01a"},
    {name = "Barrel", model = "prop_barrel_01a"},
    {name = "Beach Ball", model = "prop_beachball_02"},
    {name = "Ferris Wheel Cart", model = "prop_ferris_car_01"},
    {name = "Porta Potty", model = "prop_portacabin01"},
    {name = "Crashed UFO", model = "prop_crashed_heli"},
    -- Random Objects
    {name = "Dumpster", model = "prop_dumpster_01a"},
    {name = "Fire Hydrant", model = "prop_fire_hydrant_1"},
    {name = "Tire Stack", model = "prop_offroad_tyres02"},
    {name = "Gas Tank", model = "prop_gas_tank_01a"},
}

-- Thread to periodically update dropdown list (clean up deleted objects and refresh)
-- DISABLED - caused crashes during spawn
-- Instead, cleanup only happens when selecting object in get_selected_object()
--[[
util.create_thread(function()
    while true do
        util.yield(2000) -- Rzadziej - co 2 sekundy
        
        -- Skip if spawn in progress
        if spawn_state.loading then
            goto continue
        end
        
        -- Clean up deleted objects from list
        pcall(function()
            for i = #spawn_state.spawned_objects, 1, -1 do
                local obj_data = spawn_state.spawned_objects[i]
                if not obj_data or not obj_data.handle then
                    table.remove(spawn_state.spawned_objects, i)
                end
            end
        end)
        
        ::continue::
    end
end)
]]

-- Function to get currently selected object handle
local function get_selected_object()
    local idx = spawn_state.selected_object_index or 0
    local count = #spawn_state.spawned_objects
    
    if idx > 0 and idx <= count then
        local obj_data = spawn_state.spawned_objects[idx]
        if obj_data and obj_data.handle and obj_data.handle ~= 0 then
            return obj_data.handle, obj_data
        end
    end
    return nil, nil
end

-- Function to update object position directly
local function update_object_position_direct()
    local object, obj_data = get_selected_object()
    if not object or object == 0 then
        return
    end
    
    -- Use spawn_pos from object data if available
    if obj_data and obj_data.spawn_pos then
        object_control.spawn_pos = obj_data.spawn_pos
    end
    
    -- Check if object still exists (with pcall for safety)
    local exists_ok, exists = pcall(function()
        return native.does_entity_exist(object)
    end)
    if not exists_ok or not exists then
        spawn_state.last_spawned_object = nil
        return
    end
    
    -- Safe control request (only if object is networked)
    -- Wszystko opakowane w pcall aby zapobiec crashom
    pcall(function()
        local is_networked = native.network_get_entity_is_networked(object)
        if is_networked then
            if not native.network_has_control_of_entity(object) then
                for i = 1, 5 do
                    native.network_request_control_of_entity(object)
                    if native.network_has_control_of_entity(object) then break end
                end
            end
        end
    end)
    
    -- Calculate absolute position from spawn position + offset
    local base_x = object_control.spawn_pos.x or 0.0
    local base_y = object_control.spawn_pos.y or 0.0
    local base_z = object_control.spawn_pos.z or 0.0
    
    -- If spawn_pos is at origin (0,0,0), use offsets from origin
    if math.abs(base_x) < 0.01 and math.abs(base_y) < 0.01 and math.abs(base_z) < 0.01 then
        base_x = 0.0
        base_y = 0.0
        base_z = 0.0
    end
    
    -- Calculate final position
    local abs_x = base_x + (object_control.offset_x or 0.0)
    local abs_y = base_y + (object_control.offset_y or 0.0)
    local abs_z = base_z + (object_control.offset_z or 0.0)
    
    -- All entity operations wrapped in pcall for safety
    pcall(function()
        -- Ensure object is marked as mission entity (refresh it)
        native.set_entity_as_mission_entity(object, true, true)
        native.set_entity_invincible(object, true)
        
        -- Disable gravity and freeze first
        native.set_entity_has_gravity(object, false)
        
        -- Unfreeze to allow position update
        native.freeze_entity_position(object, false)
        
        -- Update position using set_entity_coords
        native.set_entity_coords(object, abs_x, abs_y, abs_z, false, false, false, false)
        
        -- Update rotation
        native.set_entity_heading(object, object_control.rotation or 0.0)
        
        -- Re-freeze immediately
        native.freeze_entity_position(object, true)
    end)
end


-- Callback for object selection dropdown
-- Dropdown returns TEXT of option (e.g. "#1: prop_name"), not index!
local function on_object_select(value)
    local index = 0
    
    -- Parse value from dropdown
    if type(value) == "string" then
        if value == "None" or value == "none" or value == "" then
            index = 0
        else
            -- Format: "#1: prop_name" - extract number after "#"
            local num_str = value:match("^#(%d+)")
            if num_str then
                index = tonumber(num_str) or 0
            else
                -- Maybe it's just a number?
                index = tonumber(value) or 0
            end
        end
    elseif type(value) == "number" then
        index = value
    end
    
    -- Set index
    spawn_state.selected_object_index = index
    
    if index > 0 and index <= #spawn_state.spawned_objects then
        local obj_data = spawn_state.spawned_objects[index]
        if obj_data then
            -- Set handle and position
            spawn_state.last_spawned_object = obj_data.handle
            
            if obj_data.spawn_pos then
                object_control.spawn_pos = obj_data.spawn_pos
                object_control.rotation = obj_data.spawn_pos.heading or 0.0
            end
            
            -- Reset offsets
            object_control.offset_x = 0.0
            object_control.offset_y = 0.0
            object_control.offset_z = 0.0
            
            -- Reset rotation
            if obj_tools and obj_tools.rotation then
                obj_tools.rotation.pitch = 0.0
                obj_tools.rotation.roll = 0.0
                obj_tools.rotation.yaw = object_control.rotation or 0.0
            end
            
            -- Notification
            pcall(function()
                if notify then 
                    notify.push("Object", "Selected #" .. tostring(index), 1500) 
                end
            end)
        end
    else
        spawn_state.last_spawned_object = nil
        spawn_state.selected_object_index = 0
    end
end

-- Slider callbacks (update values and immediately update position)
-- Wrapped in pcall for maximum safety
local function on_pos_x_change(value)
    pcall(function()
        if not object_control then return end
        object_control.offset_x = value or 0.0
        local object, obj_data = get_selected_object()
        if object and object ~= 0 and obj_data then
            if obj_data.spawn_pos then
                object_control.spawn_pos = obj_data.spawn_pos
            end
            update_object_position_direct()
        end
    end)
end

local function on_pos_y_change(value)
    pcall(function()
        if not object_control then return end
        object_control.offset_y = value or 0.0
        local object, obj_data = get_selected_object()
        if object and object ~= 0 and obj_data then
            if obj_data.spawn_pos then
                object_control.spawn_pos = obj_data.spawn_pos
            end
            update_object_position_direct()
        end
    end)
end

local function on_pos_z_change(value)
    pcall(function()
        if not object_control then return end
        object_control.offset_z = value or 0.0
        local object, obj_data = get_selected_object()
        if object and object ~= 0 and obj_data then
            if obj_data.spawn_pos then
                object_control.spawn_pos = obj_data.spawn_pos
            end
            update_object_position_direct()
        end
    end)
end

local function on_rotation_change(value)
    if not object_control then return end
    object_control.rotation = value or 0.0
    local object, obj_data = get_selected_object()
    if object and object ~= 0 and obj_data then
        if obj_data.spawn_pos then
            object_control.spawn_pos = obj_data.spawn_pos
        end
        update_object_position_direct()
    end
end

-- Function to delete selected object
-- Uses ptr_int() from Lexis API for proper entity deletion
-- For networked objects, first acquires network control
-- Documentation: https://docs.lexis.re/
local function delete_selected_object()
    if spawn_state.selected_object_index > 0 and spawn_state.selected_object_index <= #spawn_state.spawned_objects then
        local obj_data = spawn_state.spawned_objects[spawn_state.selected_object_index]
        
        -- Attempt to delete entity
        if obj_data and obj_data.handle and obj_data.handle ~= 0 then
            local handle = obj_data.handle
            local deleted = false
            
            pcall(function()
                -- Check if object exists
                local exists = native.does_entity_exist(handle)
                if not exists then 
                    deleted = true  -- Already deleted
                    return 
                end
                
                -- For networked objects - get control
                local is_networked = false
                pcall(function() is_networked = native.network_get_entity_is_networked(handle) end)
                
                if is_networked then
                    -- Multiple attempts to get control
                    for i = 1, 30 do
                        local has_control = false
                        pcall(function() has_control = native.network_has_control_of_entity(handle) end)
                        if has_control then break end
                        pcall(function() native.network_request_control_of_entity(handle) end)
                        util.yield(100)
                    end
                end
                
                -- STEP 1: Disable collision immediately
                -- SET_ENTITY_COLLISION(entity, false, false) - disables collision
                pcall(function() native.set_entity_collision(handle, false, false) end)
                
                -- SET_ENTITY_COMPLETELY_DISABLE_COLLISION(entity, true, true) - completely disables
                pcall(function() invoker.call(0x9EBC85ED0FFFE51C, handle, true, true) end)
                
                -- STEP 2: Hide locally immediately (so you don't see it)
                -- SET_ENTITY_LOCALLY_INVISIBLE - hides only for local player
                pcall(function() invoker.call(0xE135A9FF3F5D05D8, handle) end)
                
                -- SET_ENTITY_VISIBLE(entity, false, false) - hides for everyone
                pcall(function() native.set_entity_visible(handle, false, false) end)
                
                -- SET_ENTITY_ALPHA(entity, 0, false) - full transparency
                pcall(function() native.set_entity_alpha(handle, 0, false) end)
                
                -- STEP 3: Set as mission entity (allows deletion)
                pcall(function() native.set_entity_as_mission_entity(handle, true, true) end)
                
                -- STEP 4: Actual deletion
                -- Method 1: Use ptr_int from Lexis API (proper way)
                if ptr_int then
                    local entity_ptr = ptr_int()
                    entity_ptr.value = handle
                    -- DELETE_ENTITY requires a pointer
                    invoker.call(0xAE3CBE5BF394C9C9, entity_ptr)
                    entity_ptr:free()
                    deleted = true
                -- Method 2: Use entities.delete from Lexis API
                elseif entities and entities.delete then
                    entities.delete(handle)
                    deleted = true
                -- Method 3: Use entity.delete
                elseif entity and entity.delete then
                    entity.delete(handle)
                    deleted = true
                else
                    -- Method 4: Fallback - teleport under map
                    native.set_entity_as_mission_entity(handle, false, true)
                    native.set_entity_coords(handle, 0, 0, -1000, false, false, false, false)
                    deleted = true
                end
            end)
            
            if deleted then
                if notify then notify.push("Object", "Deleted from game", 1500) end
            end
        end
        
        -- Remove from list
        table.remove(spawn_state.spawned_objects, spawn_state.selected_object_index)
        
        if spawn_state.selected_object_index > #spawn_state.spawned_objects then
            spawn_state.selected_object_index = #spawn_state.spawned_objects
        end
        
        if spawn_state.selected_object_index > 0 then
            local new_obj_data = spawn_state.spawned_objects[spawn_state.selected_object_index]
            if new_obj_data then
                spawn_state.last_spawned_object = new_obj_data.handle
                if new_obj_data.spawn_pos then
                    object_control.spawn_pos = new_obj_data.spawn_pos
                    object_control.rotation = new_obj_data.spawn_pos.heading or 0.0
                end
                object_control.offset_x = 0.0
                object_control.offset_y = 0.0
                object_control.offset_z = 0.0
            end
        else
            spawn_state.last_spawned_object = nil
            spawn_state.selected_object_index = 0
        end
        
        pcall(update_object_dropdown)
        pcall(function()
            if notify then notify.push("Object", "Deleted", 1500) end
        end)
    end
end

-- Reset to spawn position button
local function reset_object_position()
    local object, obj_data = get_selected_object()
    if object and object ~= 0 and obj_data then
        object_control.offset_x = 0.0
        object_control.offset_y = 0.0
        object_control.offset_z = 0.0
        object_control.rotation = obj_data.spawn_pos.heading or 0.0
        
        -- Update sliders by finding them in the group
        for _, item in ipairs(gObjectControls.items) do
            if item.id == "obj_pos_x" then item.value = 0.0
            elseif item.id == "obj_pos_y" then item.value = 0.0
            elseif item.id == "obj_pos_z" then item.value = 0.0
            elseif item.id == "obj_rotation" then item.value = object_control.rotation
            end
        end
        
        update_object_position_direct()
        if notify then notify.push("Object Position", "Reset to spawn position", 2000) end
    else
        if notify then notify.push("Object Position", "No object selected", 2000) end
    end
end

-- ============================================
-- NEW FUNCTIONS: Enhanced object management
-- Grouped in table to reduce local variable count
-- ============================================

-- Table containing all new object functions
local obj_tools = {
    -- Variables for full rotation
    rotation = { pitch = 0.0, roll = 0.0, yaw = 0.0 },
    -- Stan klawiatury ekranowej
    keyboard = { waiting = false, action = nil }
}

-- Helper function: Safe request for control over object
-- Uses pcall to prevent crashes with invalid entities
function obj_tools.request_control(entity)
    if not entity or entity == 0 then return true end
    
    -- Check if entity exists (with pcall for safety)
    local exists_ok, exists = pcall(function()
        return native.does_entity_exist(entity)
    end)
    if not exists_ok or not exists then return false end
    
    -- Check if object is networked (with pcall for safety)
    local net_ok, is_networked = pcall(function()
        return native.network_get_entity_is_networked(entity)
    end)
    
    -- If call failed or object is not networked - we have control
    if not net_ok or not is_networked then
        return true
    end
    
    -- Check if we already have control (with pcall)
    local has_ok, has_control = pcall(function()
        return native.network_has_control_of_entity(entity)
    end)
    if has_ok and has_control then
        return true
    end
    
    -- Request control (max 5 attempts, with pcall)
    for i = 1, 5 do
        pcall(function()
            native.network_request_control_of_entity(entity)
        end)
        local check_ok, check_control = pcall(function()
            return native.network_has_control_of_entity(entity)
        end)
        if check_ok and check_control then
            return true
        end
    end
    
    return true -- Return true to continue operation even without control
end

-- Function: Place object on ground
function obj_tools.place_on_ground()
    local object, obj_data = get_selected_object()
    if object and object ~= 0 then
        -- Safely request control (only if networked)
        obj_tools.request_control(object)
        
        -- Call wrapped in pcall
        local success = false
        pcall(function()
            success = native.place_object_on_ground_properly(object)
        end)
        
        if success then
            local coords_result = nil
            pcall(function()
                coords_result = invoker.call(0x3FEF770D40960D5A, object, false)
            end)
            
            if coords_result then
                local new_x = coords_result.v3_x or 0.0
                local new_y = coords_result.v3_y or 0.0
                local new_z = coords_result.v3_z or 0.0
                
                if obj_data and obj_data.spawn_pos then
                    obj_data.spawn_pos.x = new_x
                    obj_data.spawn_pos.y = new_y
                    obj_data.spawn_pos.z = new_z
                end
                object_control.spawn_pos.x = new_x
                object_control.spawn_pos.y = new_y
                object_control.spawn_pos.z = new_z
                
                object_control.offset_x = 0.0
                object_control.offset_y = 0.0
                object_control.offset_z = 0.0
                
                for _, item in ipairs(gObjectControls.items) do
                    if item.id == "obj_pos_x" then item.value = 0.0
                    elseif item.id == "obj_pos_y" then item.value = 0.0
                    elseif item.id == "obj_pos_z" then item.value = 0.0
                    end
                end
            end
            if notify then notify.push("Object Position", "Obiekt umieszczony na ziemi", 2000) end
        else
            if notify then notify.push("Object Position", "Nie można umieścić na ziemi", 2000) end
        end
    else
        if notify then notify.push("Object Position", "Brak wybranego obiektu", 2000) end
    end
end

-- Function: Move object to player (Move to Me)
function obj_tools.move_to_player()
    local object, obj_data = get_selected_object()
    if not object or object == 0 then
        if notify then notify.push("Object Position", "Brak wybranego obiektu", 2000) end
        return
    end
    
    local ped, coords, heading = nil, nil, 0.0
    local pos_ok = false
    
    pcall(function()
        if players and players.me then
            local player = players.me()
            if player and player.coords then
                coords = { x = player.coords.x or 0.0, y = player.coords.y or 0.0, z = player.coords.z or 0.0 }
                heading = player.heading or 0.0
                ped = player.ped
                pos_ok = (coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0)
            end
        end
    end)
    
    if not pos_ok and pools and pools.ped then
        pcall(function()
            local player_ped = pools.ped.get_local()
            if player_ped then
                ped = player_ped
                if entity and entity.position then
                    local pos = entity.position(player_ped)
                    if pos and pos.x and pos.y and pos.z then
                        coords = { x = pos.x, y = pos.y, z = pos.z }
                        heading = native.get_entity_heading(player_ped) or 0.0
                        pos_ok = true
                    end
                end
            end
        end)
    end
    
    if not pos_ok or not coords then
        if notify then notify.push("Object Position", "Nie można pobrać pozycji gracza", 2000) end
        return
    end
    
    local spawn_x = coords.x - math.sin(math.rad(heading)) * 3.0
    local spawn_y = coords.y + math.cos(math.rad(heading)) * 3.0
    local spawn_z = coords.z
    
    -- Safely request control (only if networked)
    obj_tools.request_control(object)
    
    -- Operacje na entity opakowane w pcall
    pcall(function()
        native.freeze_entity_position(object, false)
        native.set_entity_coords(object, spawn_x, spawn_y, spawn_z, false, false, false, false)
        native.freeze_entity_position(object, true)
    end)
    
    if obj_data and obj_data.spawn_pos then
        obj_data.spawn_pos.x = spawn_x
        obj_data.spawn_pos.y = spawn_y
        obj_data.spawn_pos.z = spawn_z
    end
    object_control.spawn_pos.x = spawn_x
    object_control.spawn_pos.y = spawn_y
    object_control.spawn_pos.z = spawn_z
    
    object_control.offset_x = 0.0
    object_control.offset_y = 0.0
    object_control.offset_z = 0.0
    
    for _, item in ipairs(gObjectControls.items) do
        if item.id == "obj_pos_x" then item.value = 0.0
        elseif item.id == "obj_pos_y" then item.value = 0.0
        elseif item.id == "obj_pos_z" then item.value = 0.0
        end
    end
    
    if notify then notify.push("Object Position", "Obiekt przeniesiony do gracza", 2000) end
end

-- Funkcja: Przyczep obiekt do gracza (Attach to Player)
function obj_tools.attach_to_player()
    local object, obj_data = get_selected_object()
    if not object or object == 0 then
        if notify then notify.push("Object Attach", "Brak wybranego obiektu", 2000) end
        return
    end
    
    local ped = nil
    pcall(function()
        if players and players.me then
            local player = players.me()
            if player and player.ped then ped = player.ped end
        end
    end)
    if not ped and pools and pools.ped then
        pcall(function() ped = pools.ped.get_local() end)
    end
    if not ped then
        if notify then notify.push("Object Attach", "Nie można pobrać ped gracza", 2000) end
        return
    end
    
    -- Safely request control (only if networked)
    obj_tools.request_control(object)
    
    -- Operacje na entity opakowane w pcall
    pcall(function()
        native.freeze_entity_position(object, false)
        native.attach_entity_to_entity(object, ped, 0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true, false)
    end)
    if notify then notify.push("Object Attach", "Obiekt przyczepiony do gracza", 2000) end
end

function obj_tools.detach()
    local object, obj_data = get_selected_object()
    if not object or object == 0 then
        if notify then notify.push("Object Attach", "Brak wybranego obiektu", 2000) end
        return
    end
    
    -- Check if attached with pcall
    local is_attached = false
    pcall(function()
        is_attached = native.is_entity_attached(object)
    end)
    
    if not is_attached then
        if notify then notify.push("Object Attach", "Obiekt nie jest przyczepiony", 2000) end
        return
    end
    
    -- Safely request control (only if networked)
    obj_tools.request_control(object)
    
    -- Operacje na entity opakowane w pcall
    pcall(function()
        native.detach_entity(object, true, true)
        native.freeze_entity_position(object, true)
        native.set_entity_has_gravity(object, false)
    end)
    
    local coords_result = nil
    pcall(function()
        coords_result = invoker.call(0x3FEF770D40960D5A, object, false)
    end)
    
    if coords_result and obj_data then
        local new_x, new_y, new_z = coords_result.v3_x or 0.0, coords_result.v3_y or 0.0, coords_result.v3_z or 0.0
        if obj_data.spawn_pos then
            obj_data.spawn_pos.x, obj_data.spawn_pos.y, obj_data.spawn_pos.z = new_x, new_y, new_z
        end
        object_control.spawn_pos.x, object_control.spawn_pos.y, object_control.spawn_pos.z = new_x, new_y, new_z
        object_control.offset_x, object_control.offset_y, object_control.offset_z = 0.0, 0.0, 0.0
        for _, item in ipairs(gObjectControls.items) do
            if item.id == "obj_pos_x" then item.value = 0.0
            elseif item.id == "obj_pos_y" then item.value = 0.0
            elseif item.id == "obj_pos_z" then item.value = 0.0
            end
        end
    end
    if notify then notify.push("Object Attach", "Obiekt odczepiony", 2000) end
end

function obj_tools.attach_to_vehicle()
    local object, obj_data = get_selected_object()
    if not object or object == 0 then
        if notify then notify.push("Object Attach", "Brak wybranego obiektu", 2000) end
        return
    end
    
    local vehicle = nil
    pcall(function()
        if players and players.me then
            local player = players.me()
            if player and player.ped then
                local ped = player.ped
                if native.is_ped_in_any_vehicle(ped, false) then
                    vehicle = native.get_vehicle_ped_is_in(ped, false)
                end
            end
        end
    end)
    if not vehicle and pools and pools.ped then
        pcall(function()
            local ped = pools.ped.get_local()
            if ped and native.is_ped_in_any_vehicle(ped, false) then
                vehicle = native.get_vehicle_ped_is_in(ped, false)
            end
        end)
    end
    
    if not vehicle or vehicle == 0 then
        if notify then notify.push("Object Attach", "Gracz nie jest w pojeździe", 2000) end
        return
    end
    
    -- Safely request control (only if networked)
    obj_tools.request_control(object)
    
    -- Operacje na entity opakowane w pcall
    pcall(function()
        native.freeze_entity_position(object, false)
        native.attach_entity_to_entity(object, vehicle, 0, 0.0, 0.0, 1.5, 0.0, 0.0, 0.0, false, false, false, false, 2, true, false)
    end)
    if notify then notify.push("Object Attach", "Obiekt przyczepiony do pojazdu", 2000) end
end

-- Rotation functions use obj_tools.rotation defined at the beginning of obj_tools

function obj_tools.update_rotation()
    local object = get_selected_object()
    if not object or object == 0 then return end
    
    -- Safely request control (only if networked)
    obj_tools.request_control(object)
    
    -- Wrapped in pcall for safety
    pcall(function()
        native.set_entity_rotation(object, obj_tools.rotation.pitch, obj_tools.rotation.roll, obj_tools.rotation.yaw, 2, true)
    end)
end

function obj_tools.on_pitch(value)
    pcall(function()
        obj_tools.rotation.pitch = value or 0.0
        obj_tools.update_rotation()
    end)
end

function obj_tools.on_roll(value)
    pcall(function()
        obj_tools.rotation.roll = value or 0.0
        obj_tools.update_rotation()
    end)
end

function obj_tools.on_yaw(value)
    pcall(function()
        obj_tools.rotation.yaw = value or 0.0
        object_control.rotation = value or 0.0
        obj_tools.update_rotation()
    end)
end

function obj_tools.reset_rotation()
    local object = get_selected_object()
    if not object or object == 0 then
        if notify then notify.push("Object Rotation", "Brak wybranego obiektu", 2000) end
        return
    end
    obj_tools.rotation.pitch, obj_tools.rotation.roll, obj_tools.rotation.yaw = 0.0, 0.0, 0.0
    object_control.rotation = 0.0
    for _, item in ipairs(gObjectControls.items) do
        if item.id == "obj_pitch" or item.id == "obj_roll" or item.id == "obj_yaw" or item.id == "obj_rotation" then
            item.value = 0.0
        end
    end
    obj_tools.update_rotation()
    if notify then notify.push("Object Rotation", "Rotacja zresetowana", 2000) end
end

function obj_tools.open_keyboard()
    if obj_tools.keyboard.waiting then
        if notify then notify.push("Object Spawner", "Klawiatura jest już otwarta", 2000) end
        return
    end
    obj_tools.keyboard.waiting = true
    obj_tools.keyboard.action = "spawn_custom"
    native.display_onscreen_keyboard(6, "FMMC_KEY_TIP8", "", "prop_", "", "", "", 64)
    if notify then notify.push("Object Spawner", "Wpisz nazwę modelu...", 3000) end
end

-- Thread handling on-screen keyboard
util.create_thread(function()
    while true do
        util.yield(100)
        if obj_tools.keyboard.waiting then
            local status = native.update_onscreen_keyboard()
            if status == 1 then
                local result = invoker.call(0x8362B09B91893647)
                if result and result.ptr_string then
                    local model_name = result.ptr_string
                    if model_name and model_name ~= "" then
                        if obj_tools.keyboard.action == "spawn_custom" then
                            spawn_object(model_name)
                        end
                    else
                        if notify then notify.push("Object Spawner", "Pusta nazwa modelu", 2000) end
                    end
                end
                obj_tools.keyboard.waiting = false
                obj_tools.keyboard.action = nil
            elseif status == 2 then
                if notify then notify.push("Object Spawner", "Anulowano", 1500) end
                obj_tools.keyboard.waiting = false
                obj_tools.keyboard.action = nil
            end
        end
    end
end)

-- ============================================
-- KONIEC NOWYCH FUNKCJI
-- ============================================

-- Button for spawning custom model (Custom Spawn)
ui.button(gSpecialObjects, "spawn_custom_model", "Spawn Custom Model", obj_tools.open_keyboard, "Enter custom model name to spawn (e.g. prop_bench_01a)")

ui.label(gSpecialObjects, "Preset Objects", config.colors.accent)

-- Create buttons for special objects
for i, obj in ipairs(special_objects) do
    ui.button(gSpecialObjects, "special_obj_" .. i, obj.name, function() 
        spawn_object(obj.model) 
    end, "Spawn special object: " .. obj.name)
end

-- ============================================
-- OBJECT CONTROLS GROUP (separate from spawner)
-- ============================================
gObjectControls = ui.group(otherTab, "Object Controls", nil, nil, nil, nil)

-- Object Selection
ui.label(gObjectControls, "Object Selection", config.colors.accent)
obj_select_dropdown_ref = ui.dropdown(gObjectControls, "obj_select", "Select Object to Edit", {"None"}, 0, on_object_select, "Select object to edit")
-- Initialize dropdown with current objects immediately after creation
update_object_dropdown()
ui.button(gObjectControls, "obj_delete", "Delete Selected Object", delete_selected_object, "Delete selected object")

-- Position Control
ui.label(gObjectControls, "Position Control", config.colors.accent)
ui.slider(gObjectControls, "obj_pos_x", "Offset X (Left/Right)", -100.0, 100.0, 0.0, on_pos_x_change, "Move object on X axis (left/right)", 0.1)
ui.slider(gObjectControls, "obj_pos_y", "Offset Y (Forward/Back)", -100.0, 100.0, 0.0, on_pos_y_change, "Move object on Y axis (forward/back)", 0.1)
ui.slider(gObjectControls, "obj_pos_z", "Offset Z (Up/Down)", -100.0, 100.0, 0.0, on_pos_z_change, "Move object on Z axis (up/down)", 0.1)

-- Quick positioning buttons
ui.button(gObjectControls, "obj_move_to_me", "Move to Me", obj_tools.move_to_player, "Move object to player position (3m in front)")
ui.button(gObjectControls, "obj_place_ground", "Place on Ground", obj_tools.place_on_ground, "Place object on the ground")
ui.button(gObjectControls, "obj_reset_pos", "Reset Position", reset_object_position, "Reset object to spawn position")

-- Rotation Control
ui.label(gObjectControls, "Rotation Control", config.colors.accent)
ui.slider(gObjectControls, "obj_pitch", "Pitch (Front/Back Tilt)", -180.0, 180.0, 0.0, obj_tools.on_pitch, "Tilt object front/back", 1.0)
ui.slider(gObjectControls, "obj_roll", "Roll (Left/Right Tilt)", -180.0, 180.0, 0.0, obj_tools.on_roll, "Tilt object left/right", 1.0)
ui.slider(gObjectControls, "obj_yaw", "Yaw (Heading)", 0.0, 360.0, 0.0, obj_tools.on_yaw, "Rotate object (0-360 degrees)", 1.0)
ui.button(gObjectControls, "obj_reset_rot", "Reset Rotation", obj_tools.reset_rotation, "Reset rotation to 0")

-- Attach/Detach
ui.label(gObjectControls, "Attach Options", config.colors.accent)
ui.button(gObjectControls, "obj_attach_player", "Attach to Player", obj_tools.attach_to_player, "Attach object to player (above head)")
ui.button(gObjectControls, "obj_attach_vehicle", "Attach to Vehicle", obj_tools.attach_to_vehicle, "Attach object to vehicle (on roof) - must be in vehicle")
ui.button(gObjectControls, "obj_detach", "Detach Object", obj_tools.detach, "Detach object from player/vehicle")

-- Network visibility
ui.label(gObjectControls, "Network", config.colors.accent)
ui.button(gObjectControls, "obj_make_networked", "Make Visible to Others (FINAL)", function()
    -- Use SELECTED object from dropdown (not last_spawned_object)
    local object = nil
    local obj_data = nil
    
    if spawn_state.selected_object_index > 0 and spawn_state.selected_object_index <= #spawn_state.spawned_objects then
        obj_data = spawn_state.spawned_objects[spawn_state.selected_object_index]
        if obj_data and obj_data.handle and obj_data.handle ~= 0 then
            object = obj_data.handle
        end
    end
    
    if object then
        -- Check if already networked
        local already_networked = false
        pcall(function() already_networked = native.network_get_entity_is_networked(object) end)
        
        if already_networked then
            if notify then notify.push("Object", "Already visible to others!", 2000) end
            return
        end
        
        -- Check if object exists
        local exists = false
        pcall(function() exists = native.does_entity_exist(object) end)
        
        if exists then
            -- Register as networked
            pcall(function() native.network_register_entity_as_networked(object) end)
            
            -- Mark in object data as networked
            if obj_data then
                obj_data.is_networked = true
            end
            
            if notify then 
                notify.push("Object", "Object #" .. spawn_state.selected_object_index .. " visible to others!", 3000) 
            end
        else
            if notify then notify.push("Object", "Object no longer exists", 2000) end
        end
    else
        if notify then notify.push("Object", "Select an object from the list", 2000) end
    end
end, "After clicking, the object will be visible to other players!")

-- Cayo Tab Content
local gCayoInfo = ui.group(heistTab, "Info", nil, nil, nil, 140, "cayo")
ui.label(gCayoInfo, "Cayo Perico Heist", config.colors.accent)
ui.label(gCayoInfo, "Max transaction: $2,550,000", config.colors.text_main)
ui.label(gCayoInfo, "Transaction cooldown: 30 min", config.colors.text_sec)
ui.label(gCayoInfo, "Heist cooldown: 45 min (skip)", config.colors.text_sec)

local gCayoPreps = ui.group(heistTab, "Preps", nil, nil, nil, nil, "cayo")
ui.button(gCayoPreps, "cayo_unlock_poi", "Unlock All POI", function() cayo_unlock_all_poi() end)
ui.dropdown(gCayoPreps, "cayo_difficulty", "Difficulty", {"Normal", "Hard"}, 1, function(opt)
    if opt == "Normal" then CayoConfig.diff = 126823
    elseif opt == "Hard" then CayoConfig.diff = 131055 end
end)
ui.dropdown(gCayoPreps, "cayo_approach", "Approach", {"Submarine", "Longfin", "All Approaches"}, 3, function(opt)
    if opt == "Submarine" then CayoConfig.app = 65283
    elseif opt == "Longfin" then CayoConfig.app = 65345
    elseif opt == "All Approaches" then CayoConfig.app = 65535 end
end)
ui.dropdown(gCayoPreps, "cayo_target", "Target", {"Tequila", "Necklace", "Bonds", "Pink Diamond", "Madrazo Files", "Panther Statue"}, 6, function(opt)
    local targets = {Tequila = 0, Necklace = 1, Bonds = 2, ["Pink Diamond"] = 3, ["Madrazo Files"] = 4, ["Panther Statue"] = 5}
    CayoConfig.tgt = targets[opt] or 5
end)
ui.dropdown(gCayoPreps, "cayo_compound", "Compound Loot", {"Gold", "Coke", "Cash"}, 1, function(opt)
    CayoConfig.sec_comp = string.upper(opt)
end)
ui.dropdown(gCayoPreps, "cayo_island", "Island Loot", {"Gold", "Coke"}, 1, function(opt)
    CayoConfig.sec_isl = string.upper(opt)
end)
ui.button(gCayoPreps, "cayo_apply_preps", "Apply Preps", function() cayo_apply_preps() end)
ui.button(gCayoPreps, "cayo_reset_preps", "Reset Preps", function() cayo_reset_preps() end)

local gCayoTools = ui.group(heistTab, "Tools", nil, nil, nil, nil, "cayo")
ui.button(gCayoTools, "cayo_tool_voltlab", "Instant Voltlab Hack", function() cayo_instant_voltlab_hack() end)
ui.button(gCayoTools, "cayo_tool_password", "Instant Password Hack", function() cayo_instant_password_hack() end)
ui.button(gCayoTools, "cayo_tool_plasma", "Bypass Plasma Cutter", function() cayo_bypass_plasma_cutter() end)
ui.button(gCayoTools, "cayo_tool_drainage", "Bypass Drainage Pipe", function() cayo_bypass_drainage_pipe() end)
ui.button(gCayoTools, "cayo_tool_reload", "Reload Planning Screen", function() cayo_reload_planning_screen() end)
ui.button(gCayoTools, "cayo_tool_cooldown", "Remove Cooldown", function() cayo_remove_cooldown() end)
ui.button(gCayoTools, "cayo_tool_finish", "Instant Finish", function() cayo_instant_finish() end)
ui.button(gCayoTools, "cayo_force_ready", "Force Ready", function() cayo_force_ready() end)
ui.button(gCayoTools, "cayo_fix_board", "Fix White Board", function() cayo_reload_planning_screen() end)

-- Teleport section - In Residence
local gCayoTeleportInResidence = ui.group(heistTab, "Teleport - In Residence", nil, nil, nil, nil, "cayo")
ui.button(gCayoTeleportInResidence, "cayo_tp_target", "Main Target", function() cayo_teleport_main_target() end)
ui.button(gCayoTeleportInResidence, "cayo_tp_gate", "Gate", function() cayo_teleport_gate() end)
ui.button(gCayoTeleportInResidence, "cayo_tp_residence", "Residence", function() cayo_teleport_residence() end)
ui.button(gCayoTeleportInResidence, "cayo_tp_loot1", "Loot #1", function() cayo_teleport_loot1() end)
ui.button(gCayoTeleportInResidence, "cayo_tp_loot2", "Loot #2", function() cayo_teleport_loot2() end)
ui.button(gCayoTeleportInResidence, "cayo_tp_loot3", "Loot #3", function() cayo_teleport_loot3() end)

-- Teleport section - Outside Residence
local gCayoTeleportOutside = ui.group(heistTab, "Teleport - Outside Residence", nil, nil, nil, nil, "cayo")
ui.button(gCayoTeleportOutside, "cayo_tp_tunnel", "Underwater Tunnel", function() cayo_teleport_underwater_tunnel() end)
ui.button(gCayoTeleportOutside, "cayo_tp_center", "Center", function() cayo_teleport_center() end)
ui.button(gCayoTeleportOutside, "cayo_tp_gate_outside", "Gate", function() cayo_teleport_gate_outside() end)
ui.button(gCayoTeleportOutside, "cayo_tp_airport", "Airport", function() cayo_teleport_airport() end)
ui.button(gCayoTeleportOutside, "cayo_tp_escape", "Escape", function() cayo_teleport_escape() end, nil, false, "green")

local gCayoCuts = ui.group(heistTab, "Cuts", nil, nil, nil, nil, "cayo")
local cayoHostSlider = ui.slider(gCayoCuts, "cayo_cut_host", "Host Cut %", 0, 300, 100, function(val)
    CayoCutsValues.host = math.floor(val)
end, nil, 5)
local cayoP2Slider = ui.slider(gCayoCuts, "cayo_cut_p2", "Player 2 Cut %", 0, 300, 100, function(val)
    CayoCutsValues.player2 = math.floor(val)
end, nil, 5)
local cayoP3Slider = ui.slider(gCayoCuts, "cayo_cut_p3", "Player 3 Cut %", 0, 300, 100, function(val)
    CayoCutsValues.player3 = math.floor(val)
end, nil, 5)
local cayoP4Slider = ui.slider(gCayoCuts, "cayo_cut_p4", "Player 4 Cut %", 0, 300, 100, function(val)
    CayoCutsValues.player4 = math.floor(val)
end, nil, 5)
ui.button(gCayoCuts, "cayo_cuts_max", "Apply Preset (100%)", function()
    CayoCutsValues.host = 100
    CayoCutsValues.player2 = 100
    CayoCutsValues.player3 = 100
    CayoCutsValues.player4 = 100
    if cayoHostSlider then cayoHostSlider.value = 100 end
    if cayoP2Slider then cayoP2Slider.value = 100 end
    if cayoP3Slider then cayoP3Slider.value = 100 end
    if cayoP4Slider then cayoP4Slider.value = 100 end
    cayo_apply_cuts()
end)
ui.button(gCayoCuts, "cayo_cuts_apply", "Apply Cuts", function() cayo_apply_cuts() end)

-- Cuts storage (defined before do blocks so they're accessible everywhere)
local DoomsdayCutsValues = {
    player1 = 100,
    player2 = 100,
    player3 = 100,
    player4 = 100,
}

local ApartmentCutsValues = {
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
ui.toggle(gApartmentLaunch, "apartment_launch_solo", "Solo Launch", state.solo_launch.apartment, function(val)
    state.solo_launch.apartment = val
end)
ui.button(gApartmentLaunch, "apartment_force_ready", "Force Ready", function() apartment_force_ready() end)
ui.button(gApartmentLaunch, "apartment_redraw_board", "Redraw Board", function() apartment_redraw_board() end)

local gApartmentPreps = ui.group(heistTab, "Preps", nil, nil, nil, nil, "apartment")
ui.button(gApartmentPreps, "apartment_complete_preps", "Complete Preps", function() apartment_complete_preps() end)
ui.button(gApartmentPreps, "apartment_kill_cooldown", "Kill Cooldown", function() apartment_kill_cooldown() end)

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
    local player_id = 0
    local cooldown_global = 1877303 + 1 + (player_id * 77) + 76
    script.globals(cooldown_global).int32 = -1
    if notify then notify.push("Apartment Tools", "Unavailable Jobs Now Playable", 2000) end
end

local function apartment_unlock_all_jobs()
    local p = GetMP()
    local stats = {
        "HEIST_SAVED_STRAND_0", "HEIST_SAVED_STRAND_0_L",
        "HEIST_SAVED_STRAND_1", "HEIST_SAVED_STRAND_1_L",
        "HEIST_SAVED_STRAND_2", "HEIST_SAVED_STRAND_2_L",
        "HEIST_SAVED_STRAND_3", "HEIST_SAVED_STRAND_3_L",
        "HEIST_SAVED_STRAND_4", "HEIST_SAVED_STRAND_4_L"
    }
    for _, stat in ipairs(stats) do
        account.stats(p .. stat).int32 = 5  -- STRAND_COMPLETE = 5
    end
    script.globals(1936048).int32 = 2  -- Reload board
    if notify then notify.push("Apartment Tools", "All Jobs Unlocked", 2000) end
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
ui.button(gApartmentTools, "apartment_fleeca_hack", "Fleeca Hack", function() apartment_fleeca_hack() end)
ui.button(gApartmentTools, "apartment_fleeca_drill", "Fleeca Drill", function() apartment_fleeca_drill() end)
ui.button(gApartmentTools, "apartment_pacific_hack", "Pacific Hack", function() apartment_pacific_hack() end)
ui.button(gApartmentTools, "apartment_play_unavailable", "Play Unavailable", function() apartment_play_unavailable() end)
ui.button(gApartmentTools, "apartment_unlock_all", "Unlock All Jobs", function() apartment_unlock_all_jobs() end)

local gApartmentInstantFinish = ui.group(heistTab, "Instant Finish", nil, nil, nil, nil, "apartment")
ui.button(gApartmentInstantFinish, "apartment_instant_finish_pacific", "Instant Finish (Pacific Standard)", function() apartment_instant_finish_pacific() end)
ui.button(gApartmentInstantFinish, "apartment_instant_finish_other", "Instant Finish (Other)", function() apartment_instant_finish_other() end)

local gApartmentTeleport = ui.group(heistTab, "Teleport", nil, nil, nil, nil, "apartment")
ui.button(gApartmentTeleport, "apartment_tp_entrance", "Teleport to Entrance", function() apartment_teleport_to_entrance() end)
ui.button(gApartmentTeleport, "apartment_tp_heist_board", "Teleport to Heist Board", function() apartment_teleport_to_heist_board() end)

-- Apply Apartment Cuts
local function apply_apartment_cuts()
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
local apartmentP1Slider = ui.slider(gApartmentCuts, "apartment_cut_p1", "Host Cut %", 0, 1500, 100, function(val)
    ApartmentCutsValues.player1 = math.floor(val)
end, nil, 10)
local apartmentP2Slider = ui.slider(gApartmentCuts, "apartment_cut_p2", "Player 2 Cut %", 0, 1500, 0, function(val)
    ApartmentCutsValues.player2 = math.floor(val)
end, nil, 10)
local apartmentP3Slider = ui.slider(gApartmentCuts, "apartment_cut_p3", "Player 3 Cut %", 0, 1500, 0, function(val)
    ApartmentCutsValues.player3 = math.floor(val)
end, nil, 10)
local apartmentP4Slider = ui.slider(gApartmentCuts, "apartment_cut_p4", "Player 4 Cut %", 0, 1500, 0, function(val)
    ApartmentCutsValues.player4 = math.floor(val)
end, nil, 10)
ui.button(gApartmentCuts, "apartment_apply_preset", "Apply Preset (100%)", function()
    ApartmentCutsValues.player1 = 100
    ApartmentCutsValues.player2 = 100
    ApartmentCutsValues.player3 = 100
    ApartmentCutsValues.player4 = 100
    if apartmentP1Slider then apartmentP1Slider.value = 100 end
    if apartmentP2Slider then apartmentP2Slider.value = 100 end
    if apartmentP3Slider then apartmentP3Slider.value = 100 end
    if apartmentP4Slider then apartmentP4Slider.value = 100 end
end)
ui.button(gApartmentCuts, "apartment_cuts_apply", "Apply Cuts", function() apply_apartment_cuts() end)

-- 12M Bonus Function 
local apartment_bonus_enabled = false
local function apartment_12mil_bonus(enable)
    if enable then
        account.stats("MPPLY_HEISTFLOWORDERPROGRESS").int32 = 268435455
        account.stats("MPPLY_AWD_HST_ORDER").bool = false
        
        account.stats("MPPLY_HEISTTEAMPROGRESSBITSET").int32 = 268435455
        account.stats("MPPLY_AWD_HST_SAME_TEAM").bool = false
        
        account.stats("MPPLY_HEISTNODEATHPROGREITSET").int32 = 268435455
        account.stats("MPPLY_AWD_HST_ULT_CHAL").bool = false
        if notify then notify.push("Apartment Bonuses", "12M Bonus Enabled", 2000) end
    else
        account.stats("MPPLY_HEISTFLOWORDERPROGRESS").int32 = 134217727
        account.stats("MPPLY_AWD_HST_ORDER").bool = true
        
        account.stats("MPPLY_HEISTTEAMPROGRESSBITSET").int32 = 134217727
        account.stats("MPPLY_AWD_HST_SAME_TEAM").bool = true
        
        account.stats("MPPLY_HEISTNODEATHPROGREITSET").int32 = 134217727
        account.stats("MPPLY_AWD_HST_ULT_CHAL").bool = true
        if notify then notify.push("Apartment Bonuses", "12M Bonus Disabled", 2000) end
    end
    apartment_bonus_enabled = enable
    return true
end

-- Bonuses Group
local gApartmentBonuses = ui.group(heistTab, "Bonuses", nil, nil, nil, nil, "apartment")
ui.toggle(gApartmentBonuses, "apartment_12m_bonus", "Enable 12M Bonus", apartment_bonus_enabled, function(val)
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
ui.button(gDoomsdayTeleport, "doomsday_teleport_entrance", "Teleport to Entrance", function()
    doomsday_teleport_to_entrance()
end)
ui.button(gDoomsdayTeleport, "doomsday_teleport_screen", "Teleport to Screen", function()
    doomsday_teleport_to_screen()
end)

local function apply_doomsday_cuts(cuts)
    if not cuts then return false end

    script.globals(1969406).int32 = cuts[1] or 100
    script.globals(1969407).int32 = cuts[2] or 100
    script.globals(1969408).int32 = cuts[3] or 100
    script.globals(1969409).int32 = cuts[4] or 100

    if notify then notify.push("Doomsday Cuts", "Cuts Applied", 2000) end
    return true
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

-- Apply Preset button (sets all to 100%)
ui.button(gDoomsdayCuts, "doomsday_preset_apply", "Apply Preset (100%)", function()
    local val = 100
    DoomsdayCutsValues.player1 = val
    DoomsdayCutsValues.player2 = val
    DoomsdayCutsValues.player3 = val
    DoomsdayCutsValues.player4 = val
    if doomsdayP1Slider then doomsdayP1Slider.value = val end
    if doomsdayP2Slider then doomsdayP2Slider.value = val end
    if doomsdayP3Slider then doomsdayP3Slider.value = val end
    if doomsdayP4Slider then doomsdayP4Slider.value = val end
end)

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
ui.button(gDoomsdayTools, "doomsday_data_hack", "Data Hack", function()
    doomsday_data_hack()
end)
ui.button(gDoomsdayTools, "doomsday_doomsday_hack", "Doomsday Hack", function()
    doomsday_doomsday_hack()
end)
ui.button(gDoomsdayTools, "doomsday_instant_finish", "Instant Finish", function()
    doomsday_instant_finish()
end)
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
ui.button(gCluckinTools, "cluckin_skip_finale", "Skip to Finale", function()
    cluckin_skip_to_finale()
end)
ui.button(gCluckinTools, "cluckin_remove_cooldown", "Remove Cooldown", function()
    cluckin_remove_cooldown()
end)
ui.button(gCluckinTools, "cluckin_reset_progress", "Reset Progress", function()
    cluckin_reset_progress()
end)
ui.button(gCluckinTools, "cluckin_instant_finish", "Instant Finish", function()
    cluckin_instant_finish()
end)

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
        local sidebar_w = config.sidebar_width
        local menu_w = config.menu_width
        
        local bodyY_local = config.sidebar_gap
        local bodyY_abs = win_y + bodyY_local
        
        if my < bodyY_abs then return end -- Above menu

        if mx >= win_x and mx <= win_x + sidebar_w then
             if state.sidebar_scroll.max_y > 0 then
                 state.sidebar_scroll.y = state.sidebar_scroll.y + delta
                 if state.sidebar_scroll.y < 0 then state.sidebar_scroll.y = 0 end
                 if state.sidebar_scroll.y > state.sidebar_scroll.max_y then state.sidebar_scroll.y = state.sidebar_scroll.max_y end
             end
        elseif mx > win_x + sidebar_w and mx <= win_x + menu_w then
             -- Disable scroll for info tab
             if ui.currentTab and ui.currentTab.id == "info" then
                 return
             end
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
