-- ---------------------------------------------------------
-- 2. Core Rendering Helpers
-- ---------------------------------------------------------

local function ensure_assets()
    if state.font_load_attempted then return end
    state.font_load_attempted = true
    ensure_core_dirs()

    local font_candidates = {}
    if config.font_path and config.font_path ~= "" then
        font_candidates[#font_candidates + 1] = config.font_path
    end
    if type(config.font_fallback_paths) == "table" then
        for i = 1, #config.font_fallback_paths do
            local path = config.font_fallback_paths[i]
            if path and path ~= "" then
                font_candidates[#font_candidates + 1] = path
            end
        end
    end

    for i = 1, #font_candidates do
        local status, font = pcall(gui.load_font, font_candidates[i], 50.0)
        if status and font then
            state.fonts.regular = font
            break
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
        state.window.is_resizing = false
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
        for _ = 1, 60 do
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

local BUTTON_COLOR_STYLES = {
    disabled = {
        normal = { bg = config.colors.danger, border = config.colors.danger, text = config.colors.text_on_accent },
        hover = { bg = config.colors.danger_hover, border = config.colors.danger_hover, text = config.colors.text_on_accent }
    },
    primary = {
        normal = { bg = config.colors.accent, border = config.colors.accent, text = config.colors.text_on_accent },
        hover = { bg = config.colors.accent_hover, border = config.colors.accent_hover, text = config.colors.text_on_accent }
    },
    success = {
        normal = { bg = config.colors.success, border = config.colors.success, text = config.colors.text_on_accent },
        hover = { bg = config.colors.success_hover, border = config.colors.success_hover, text = config.colors.text_on_accent }
    },
    danger = {
        normal = { bg = config.colors.danger, border = config.colors.danger, text = config.colors.text_on_accent },
        hover = { bg = config.colors.danger_hover, border = config.colors.danger_hover, text = config.colors.text_on_accent }
    },
    ghost = {
        normal = { bg = config.colors.transparent, border = config.colors.transparent, text = config.colors.text_main },
        hover = { bg = config.colors.bg_ghost_hover, border = config.colors.transparent, text = config.colors.text_main }
    },
    ghost_danger = {
        normal = { bg = config.colors.transparent, border = config.colors.transparent, text = config.colors.danger_text },
        hover = { bg = config.colors.danger_soft, border = config.colors.transparent, text = config.colors.danger_text }
    },
    outline = {
        normal = { bg = config.colors.bg_ghost_hover, border = config.colors.transparent, text = config.colors.text_main },
        hover = { bg = config.colors.bg_panel, border = config.colors.transparent, text = config.colors.text_main }
    }
}

local HEIST_SUBTAB_NAMES = { "Cayo", "Casino", "Doomsday", "Apartment", "Cluckin" }
local HEIST_SUBTAB_KEYS = { "cayo", "casino", "doomsday", "apartment", "cluckin" }

-- Legacy visual order hints. Used only to flatten groups into a stable sequence.
local HEIST_GROUP_LAYOUTS = {
    [1] = { -- Cayo
        ["Info"] = { col = 1, order = 1 },
        ["Presets (JSON)"] = { col = 1, order = 2 },
        ["Preps"] = { col = 2, order = 1 },
        ["Cuts"] = { col = 1, order = 3 },
        ["Tools"] = { col = 3, order = 1 },
        ["Teleport - Outside Residence"] = { col = 3, order = 2 },
        ["Teleport - In Residence"] = { col = 3, order = 3 },
        ["DANGER"] = { col = 3, order = 4 }
    },
    [2] = { -- Casino
        ["Info"] = { col = 1, order = 1 },
        ["Presets (JSON)"] = { col = 1, order = 2 },
        ["Preps"] = { col = 2, order = 1 },
        ["Launch"] = { col = 2, order = 2 },
        ["Cuts"] = { col = 2, order = 3 },
        ["Tools"] = { col = 3, order = 1 },
        ["Teleport - Outside Casino"] = { col = 3, order = 2 },
        ["Teleport - In Casino"] = { col = 3, order = 3 },
        ["DANGER"] = { col = 3, order = 4 }
    },
    [3] = { -- Doomsday
        ["Info"] = { col = 1, order = 1 },
        ["Prep Presets"] = { col = 1, order = 2 },
        ["Launch"] = { col = 2, order = 1 },
        ["Cuts"] = { col = 2, order = 2 },
        ["Tools"] = { col = 3, order = 1 },
        ["Teleport"] = { col = 3, order = 2 }
    },
    [4] = { -- Apartment
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
}

local function clear_array(tbl)
    for i = #tbl, 1, -1 do
        tbl[i] = nil
    end
end

local render_cache = {
    active_groups = {},
    col_x = {},
    groups_by_column = { {}, {}, {} },
    ordered_groups = {}
}

local function flatten_groups_by_order(activeGroups, heist_subtab)
    local ordered = render_cache.ordered_groups
    clear_array(ordered)

    local layout = HEIST_GROUP_LAYOUTS[heist_subtab]
    for i, group in ipairs(activeGroups) do
        local rank = 1000000 + i
        if layout then
            local spec = layout[group.label]
            if spec then
                rank = ((spec.col - 1) * 1000) + spec.order
            end
        end
        ordered[#ordered + 1] = { group = group, rank = rank, idx = i }
    end

    table.sort(ordered, function(a, b)
        if a.rank == b.rank then
            return a.idx < b.idx
        end
        return a.rank < b.rank
    end)

    return ordered
end

local function get_group_actual_height(group)
    local h = config.item_height.header_padding + config.space.x5
    local items = group and group.items or {}

    for _, item in ipairs(items) do
        if item.type == "toggle" then
            h = h + config.item_height.toggle
        elseif item.type == "button" then
            h = h + config.item_height.button
        elseif item.type == "button_pair" then
            h = h + config.item_height.button
        elseif item.type == "slider" then
            h = h + config.item_height.slider
        elseif item.type == "dropdown" then
            h = h + get_dropdown_item_height(item)
        elseif item.type == "label" then
            h = h + config.space.x6
        end
    end

    local min_h = (group and group.rect and group.rect.h) or 0
    if h < min_h then
        h = min_h
    end
    return h
end

local function distribute_groups_by_column(flattened, groups_by_column, column_count)
    for col = 1, column_count do
        clear_array(groups_by_column[col])
    end

    local total = #flattened
    if total == 0 then
        return
    end

    local cols = math.max(1, math.min(column_count, total))
    local gap = config.space.x3_5

    if cols == 1 then
        for i = 1, total do
            local entry = flattened[i]
            groups_by_column[1][#groups_by_column[1] + 1] = { group = entry.group, order = i }
        end
        return
    end

    local weights = {}
    local prefix = { [0] = 0 }
    for i = 1, total do
        local group_h = get_group_actual_height(flattened[i].group)
        weights[i] = group_h + gap
        prefix[i] = prefix[i - 1] + weights[i]
    end

    -- Linear partition DP: keep group order stable, split into contiguous columns,
    -- minimize the tallest column.
    local dp = {}
    local split = {}
    dp[1] = {}
    for i = 1, total do
        dp[1][i] = prefix[i]
    end

    for k = 2, cols do
        dp[k] = {}
        split[k] = {}
        for i = k, total do
            local best_cost = math.huge
            local best_x = k - 1

            for x = k - 1, i - 1 do
                local left = dp[k - 1][x]
                if left then
                    local right = prefix[i] - prefix[x]
                    local cost = (left > right) and left or right
                    if cost < best_cost then
                        best_cost = cost
                        best_x = x
                    end
                end
            end

            dp[k][i] = best_cost
            split[k][i] = best_x
        end
    end

    local ranges = {}
    local k = cols
    local i = total
    while k > 1 do
        local x = split[k][i] or (k - 1)
        ranges[k] = { s = x + 1, e = i }
        i = x
        k = k - 1
    end
    ranges[1] = { s = 1, e = i }

    for col = 1, cols do
        local range = ranges[col]
        if range then
            for idx = range.s, range.e do
                local entry = flattened[idx]
                groups_by_column[col][#groups_by_column[col] + 1] = { group = entry.group, order = idx }
            end
        end
    end
end

local TOGGLE_INACTIVE_COLOR = { r = 148, g = 163, b = 184, a = 255 }
local toggle_track_color = { r = 148, g = 163, b = 184, a = 255 }
local slider_glow_color = { r = 255, g = 255, b = 255, a = 0 }

local function button_colors_for(btn, hovered)
    if btn.disabled then
        return hovered and BUTTON_COLOR_STYLES.disabled.hover or BUTTON_COLOR_STYLES.disabled.normal
    end

    local variant = button_variant_for(btn)
    if variant == "primary" then
        return hovered and BUTTON_COLOR_STYLES.primary.hover or BUTTON_COLOR_STYLES.primary.normal
    elseif variant == "success" then
        return hovered and BUTTON_COLOR_STYLES.success.hover or BUTTON_COLOR_STYLES.success.normal
    elseif variant == "danger" then
        return hovered and BUTTON_COLOR_STYLES.danger.hover or BUTTON_COLOR_STYLES.danger.normal
    elseif variant == "ghost" then
        return hovered and BUTTON_COLOR_STYLES.ghost.hover or BUTTON_COLOR_STYLES.ghost.normal
    elseif variant == "ghost_danger" then
        return hovered and BUTTON_COLOR_STYLES.ghost_danger.hover or BUTTON_COLOR_STYLES.ghost_danger.normal
    else
        return hovered and BUTTON_COLOR_STYLES.outline.hover or BUTTON_COLOR_STYLES.outline.normal
    end
end

-- ---------------------------------------------------------
-- 4. Rendering Implementations
-- ---------------------------------------------------------

local function draw_toggle_item(item, x, y, w, original_y)
    local pad_x = config.space.x5
    local hitbox_h = config.item_height.toggle - config.space.x1
    local hovered = (not state.active_dropdown) and is_hovered_content(x, original_y, w, hitbox_h)

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

    local activeCol = config.colors.accent
    
    local trackR = math.floor(TOGGLE_INACTIVE_COLOR.r + (activeCol.r - TOGGLE_INACTIVE_COLOR.r) * item.anim)
    local trackG = math.floor(TOGGLE_INACTIVE_COLOR.g + (activeCol.g - TOGGLE_INACTIVE_COLOR.g) * item.anim)
    local trackB = math.floor(TOGGLE_INACTIVE_COLOR.b + (activeCol.b - TOGGLE_INACTIVE_COLOR.b) * item.anim)
    toggle_track_color.r = trackR
    toggle_track_color.g = trackG
    toggle_track_color.b = trackB
    
    render_rect(switchX, switchY, switchW, switchH, toggle_track_color, config.radius.full)
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

local function is_button_hovered(btnX, btnY, btnW, btnH)
    if state.active_dropdown then
        return false
    end

    if is_hovered_content(btnX, btnY, btnW, btnH) then
        return true
    end

    local ox, oy = get_win_offset()
    return input.is_mouse_within(vec(btnX + ox, btnY + oy), vec(btnW, btnH))
end

local function draw_button_surface(btn, btnX, btnY, btnW, btnH, disabled_message)
    local hovered = is_button_hovered(btnX, btnY, btnW, btnH)

    if hovered and state.mouse.clicked and not state.active_dropdown then
        if btn.disabled then
            if disabled_message and notify then
                notify.push("Error", disabled_message, 3000)
            end
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

    return style
end

local function render_button_label_center(label, btnX, btnY, btnW, btnH, textSize, textColor)
    local textHeight = textSize * 0.7
    local textY = btnY + (btnH / 2) - (textHeight / 2)
    render_text(tostring(label or ""), btnX + btnW / 2, textY, textSize, textColor, "center")
end

local function draw_button_item(item, x, y, w)
    local pad_x = config.space.x5
    local btnH = config.item_height.button - config.space.x1
    local btnW = w - (pad_x * 2)
    local btnX = x + pad_x
    local btnY = y + config.space.x1

    local style = draw_button_surface(
        item,
        btnX,
        btnY,
        btnW,
        btnH,
        "Instant Finish function has been disabled"
    )

    local textSize = config.font_scale_small
    render_button_label_center(item.label, btnX, btnY, btnW, btnH, textSize, style.text)
end

local function draw_button_pair_item(item, x, y, w)
    local pad_x = config.space.x5
    local btnH = config.item_height.button - config.space.x1
    local totalW = w - (pad_x * 2)
    local baseX = x + pad_x
    local btnY = y + config.space.x1
    local gap = config.space.x2_5
    local btnW = (totalW - gap) / 2

    local function draw_half(btn, btnX)
        local style = draw_button_surface(
            btn,
            btnX,
            btnY,
            btnW,
            btnH,
            "This action is disabled"
        )

        -- Stability-first: fixed smaller font for split buttons (no dynamic measurement).
        local drawSize = config.font_scale_small
        render_button_label_center(btn.label, btnX, btnY, btnW, btnH, drawSize, style.text)
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

    local hovered = (not state.active_dropdown) and is_hovered_content(x, original_y, w, config.item_height.slider)
    
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
        slider_glow_color.r = config.colors.accent.r
        slider_glow_color.g = config.colors.accent.g
        slider_glow_color.b = config.colors.accent.b
        slider_glow_color.a = math.floor(90 * item.anim)
        render_rect(glowX, glowY, glowSize, glowSize, slider_glow_color, glowSize/2)
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
    
    local allow_hover = (not state.active_dropdown) or (state.active_dropdown == item.id)
    local hovered = allow_hover and is_hovered_content(boxX, original_y + config.space.x1, boxW, boxH)

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
    local selectedTextH = config.font_scale_body * 0.7
    local selectedTextY = boxY + (boxH / 2) - (selectedTextH / 2)
    if is_preset_file then
        render_text(selected, boxX + config.space.x3, selectedTextY, config.font_scale_body, boxText)
    else
        -- Center the selected option text in normal dropdown boxes
        render_text(selected, boxX + boxW / 2, selectedTextY, config.font_scale_body, boxText, "center")
    end
    
    -- Dropdown Arrow
    local arrowTextH = config.font_scale_small * 0.7
    local arrowTextY = boxY + (boxH / 2) - (arrowTextH / 2)
    render_text("v", boxX + boxW - config.space.x4, arrowTextY, config.font_scale_small, boxArrow)

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

local function draw_label_item(item, x, y, pad_x)
    local labelCol = item.color or config.colors.text_sec
    render_text(item.text, x + pad_x, y + config.space.x3, config.font_scale_small, labelCol)
    return y + config.space.x6
end

local function render_group_item(item, group_x, item_y, group_w, pad_x)
    if item.type == "toggle" then
        draw_toggle_item(item, group_x, item_y, group_w, item_y)
        return item_y + config.item_height.toggle, nil
    end
    if item.type == "button" then
        draw_button_item(item, group_x, item_y, group_w)
        return item_y + config.item_height.button, nil
    end
    if item.type == "button_pair" then
        draw_button_pair_item(item, group_x, item_y, group_w)
        return item_y + config.item_height.button, nil
    end
    if item.type == "slider" then
        draw_slider_item(item, group_x, item_y, group_w, item_y)
        return item_y + config.item_height.slider, nil
    end
    if item.type == "dropdown" then
        local dd = draw_dropdown_item(item, group_x, item_y, group_w, item_y)
        return item_y + get_dropdown_item_height(item), dd
    end
    if item.type == "label" then
        return draw_label_item(item, group_x, item_y, pad_x), nil
    end
    return item_y, nil
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

    local bodyY = config.origin_y
    local bodyH = dynamicBodyH
    local resize_hit_w = config.resize.edge_hit_w
    local resize_hit_h = config.resize.edge_hit_h or config.space.x6
    local resize_hit_x = config.origin_x + config.menu_width - resize_hit_w
    local resize_hit_y = bodyY + bodyH - resize_hit_h
    local resize_hovered = (not state.active_dropdown)
        and is_hovered(
            resize_hit_x - config.space.x1,
            resize_hit_y - config.space.x1,
            resize_hit_w + config.space.x2,
            resize_hit_h + config.space.x2
        )

    if state.mouse.clicked and not state.active_dropdown and not state.dragging_slider then
        local menuStartY = config.origin_y
        if resize_hovered then
            state.window.is_resizing = true
            state.window.is_dragging = false
            state.window.resize_start.x = state.mouse.x
            state.window.resize_start.width = config.menu_width
        elseif is_hovered(config.origin_x, menuStartY, config.menu_width, dynamicBodyH) then
            state.window.is_dragging = true
            state.window.drag_offset.x = state.mouse.x - state.window.x
            state.window.drag_offset.y = state.mouse.y - state.window.y
        end
    end
    
    if state.dragging_slider then
        state.window.is_dragging = false
        state.window.is_resizing = false
    end

    if state.window.is_resizing and state.mouse.down and not state.dragging_slider then
        local delta_x = state.mouse.x - state.window.resize_start.x
        local next_w = state.window.resize_start.width + delta_x
        local max_w_screen = math.floor(game.resolution().x - config.resize.max_screen_margin)
        local max_w_cfg = config.resize.max_menu_width or max_w_screen
        local max_w = math.min(max_w_cfg, max_w_screen)
        if max_w < config.resize.min_menu_width then
            max_w = config.resize.min_menu_width
        end
        config.menu_width = math.max(config.resize.min_menu_width, math.min(max_w, next_w))
    elseif state.window.is_dragging and state.mouse.down and not state.dragging_slider then
        state.window.x = state.mouse.x - state.window.drag_offset.x
        state.window.y = state.mouse.y - state.window.drag_offset.y
    end

    -- Full-width content panel (no sidebar/tab navigation).
    config.content_area.x = config.origin_x
    config.content_area.y = bodyY
    config.content_area.w = config.menu_width
    config.content_area.h = bodyH
    config.scrollbar.x = config.origin_x + config.menu_width - config.space.x2
    config.scrollbar.y = config.content_area.y + config.content_margin
    config.scrollbar.h = config.content_area.h - (config.content_margin * 2)

    if config.enable_particles then
        manage_particles(config.menu_width, dynamicBodyH)
    end

    render_card(config.origin_x, bodyY, config.menu_width, bodyH, config.colors.bg_main, config.colors.border_strong, config.radius.xl)
    if config.enable_particles then
        draw_particles(config.origin_x, bodyY, config.menu_width, bodyH)
    end

    -- Bottom-right corner grip to indicate draggable resize area.
    local grip_color = config.colors.accent
    local grip_right = config.origin_x + config.menu_width - config.space.x1
    local grip_bottom = bodyY + bodyH - config.space.x1
    render_rect(grip_right - config.space.x7, grip_bottom - config.space.x1, config.space.x5, config.space.x1, grip_color, config.radius.full)
    render_rect(grip_right - config.space.x5, grip_bottom - config.space.x3, config.space.x4, config.space.x1, grip_color, config.radius.full)
    render_rect(grip_right - config.space.x3, grip_bottom - config.space.x5, config.space.x3, config.space.x1, grip_color, config.radius.full)


    local contentX = config.content_area.x + config.content_margin
    local contentY = config.content_area.y + config.content_margin
    local contentW = config.content_area.w - (config.content_margin * 2)
    local contentH = config.content_area.h - (config.content_margin * 2)
    
    -- Render subtabs for Heist tab (BEFORE clip, so they stay fixed at top)
    local subtab_bar_height = 0
    local groups_start_y = contentY
    if ui.currentTab and ui.currentTab.id == "heist" then
        local subtab_names = HEIST_SUBTAB_NAMES
        local subtab_count = #subtab_names
        local subtab_h = config.space.x9
        local subtab_gap = config.space.x2
        local subtab_w = (contentW - (subtab_count - 1) * subtab_gap) / subtab_count
        local subtab_y = contentY
        
        for i, name in ipairs(subtab_names) do
            local subtab_x = contentX + (i - 1) * (subtab_w + subtab_gap)
            local is_active = (state.heist_subtab == i)
            local hovered = (not state.active_dropdown) and is_hovered(subtab_x, subtab_y, subtab_w, subtab_h)
            
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

    local activeGroups = render_cache.active_groups
    clear_array(activeGroups)
    if ui.currentTab then
        if ui.currentTab.id == "heist" then
            -- Filter groups based on active heist subtab.
            local selected_heist_key = HEIST_SUBTAB_KEYS[state.heist_subtab]
            for _, group in ipairs(ui.currentTab.groups) do
                if selected_heist_key and group.heist_subtab == selected_heist_key then
                    table.insert(activeGroups, group)
                end
            end
        else
            for i = 1, #ui.currentTab.groups do
                activeGroups[#activeGroups + 1] = ui.currentTab.groups[i]
            end
        end
    end
    
    if #activeGroups > 0 then
        local layout_cfg = config.layout or {}
        local column_gap = layout_cfg.column_gap or config.space.x4
        local fixed_col_w = layout_cfg.fixed_column_w or math.max(1, math.floor((contentW - (2 * column_gap)) / 3))
        local max_columns = layout_cfg.max_columns or 3
        local column_count = math.floor((contentW + column_gap) / (fixed_col_w + column_gap))
        if column_count < 1 then column_count = 1 end
        if column_count > max_columns then column_count = max_columns end

        local col_w = fixed_col_w
        local used_w = (column_count * col_w) + ((column_count - 1) * column_gap)
        local start_x = contentX + math.max(0, math.floor((contentW - used_w) / 2))
        local col_x = render_cache.col_x
        clear_array(col_x)
        local base_y = groups_start_y - state.scroll.y

        for col = 1, column_count do
            col_x[col] = start_x + ((col - 1) * (col_w + column_gap))
        end

        local groups_by_column = render_cache.groups_by_column
        local ordered = flatten_groups_by_order(activeGroups, state.heist_subtab)
        distribute_groups_by_column(ordered, groups_by_column, column_count)

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
                        local dd = nil
                        itemY, dd = render_group_item(item, gX, itemY, col_w, pad_x)
                        if dd then
                            pendingDropdown = dd
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
        
        if (not state.active_dropdown) and is_hovered(sb.x - config.control.scrollbar_grab_pad, sbY, sb.w + (config.control.scrollbar_grab_pad * 2), sbH) and state.mouse.clicked then
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
            local optTextH = config.font_scale_body * 0.7
            local optTextY = optY + (itemHeight / 2) - (optTextH / 2)
            if dd.align == "left" then
                render_text(opt, dd.x + config.space.x3, optTextY, config.font_scale_body, optTextCol)
            else
                render_text(opt, dd.x + dd.w / 2, optTextY, config.font_scale_body, optTextCol, "center")
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
