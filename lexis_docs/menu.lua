-- ============================================================
-- # Menu
-- ============================================================
--
-- > **Tip:** Combo and number options have their states indexed when
-- > added in a player root (see example below).
--
-- ## Functions
--
-- ### root
-- Returns the submenu instance for your scripts dedicated submenu inside
-- of the Scripts submenu.
-- function menu.root(): submenu_target
--
-- ### player_root
-- Returns the submenu instance for your scripts dedicated submenu for
-- each player.
-- function menu.player_root(): submenu_target
--
-- ## Types
--
-- ### submenu_target
-- ---@param name string
-- function submenu_target:submenu(name): submenu_target
-- ---@param name string
-- function submenu_target:toggle(name): toggle
-- ---@param name string
-- ---@param key? integer
-- function submenu_target:hotkey(name, key?): hotkey
-- ---@param name string
-- function submenu_target:textbox(name): textbox
-- ---@param name string
-- function submenu_target:button(name): button
-- ---@param name string
-- function submenu_target:breaker(name): breaker
-- ---@param name string
-- ---@param type? menu.type|integer
-- function submenu_target:number_int(name, type?): number_int
-- ---@param name string
-- ---@param type? menu.type|integer
-- function submenu_target:number_float(name, type?): number_float
-- ---@param name string
-- ---@param values table
-- ---@param type menu.type|integer
-- ---@param multi? bool
-- function submenu_target:combo_int(name, values, type, multi?): combo_int
-- ---@param name string
-- ---@param values table
-- ---@param type menu.type|integer
-- ---@param multi? bool
-- function submenu_target:combo_float(name, values, type, multi?): combo_float
-- ---@param name string
-- ---@param values table
-- ---@param type menu.type|integer
-- ---@param multi? bool
-- function submenu_target:combo_str(name, values, type, multi?): combo_str
-- ---@param new_size integer
-- function submenu_target:resize(new_size): nil
--
-- ### textbox
-- | Type   | Name  |
-- |--------|-------|
-- | string | name  |
-- | string | value |
-- ---@param text string
-- function textbox:tooltip(text): textbox
-- ---@param flag menu.flags
-- function textbox:flags(flags): textbox
-- ---@param event menu.event
-- ---@param fn function(textbox)
-- function textbox:event(event, fn): textbox
-- ---@param chars integer
-- function textbox:max_chars(chars): textbox
--
-- ### toggle
-- | Type   | Name  |
-- |--------|-------|
-- | string | name  |
-- | bool   | value |
-- ---@param text string
-- function toggle:tooltip(text): toggle
-- ---@param flag menu.flags
-- function toggle:flags(flags): toggle
-- ---@param event menu.event
-- ---@param fn function(toggle)
-- function toggle:event(event, fn): toggle
--
-- ### hotkey
-- | Type    | Name  |
-- |---------|-------|
-- | string  | name  |
-- | integer | value |
-- ---@param text string
-- function hotkey:tooltip(text): hotkey
-- ---@param flag menu.flags
-- function hotkey:flags(flags): hotkey
-- ---@param event menu.event
-- ---@param fn function
-- function hotkey:event(event, fn): hotkey
--
-- ### breaker
-- | Type   | Name |
-- |--------|------|
-- | string | name |
-- ---@param text string
-- function breaker:tooltip(text): breaker
-- ---@param flag menu.flags
-- function breaker:flags(flags): breaker
-- ---@param event menu.event
-- ---@param fn function(breaker)
-- function breaker:event(event, fn): breaker
--
-- ### button
-- | Type   | Name |
-- |--------|------|
-- | string | name |
-- ---@param text string
-- function button:tooltip(text): button
-- ---@param flag menu.flags
-- function button:flags(flags): button
-- ---@param event menu.event
-- ---@param fn function(button)
-- function button:event(event, fn): button
--
-- ### number_int
-- | Type    | Name   |
-- |---------|--------|
-- | string  | name   |
-- | integer | value  |
-- | bool    | toggle |
-- ---@param text string
-- function number_int:tooltip(text): number_int
-- ---@param flag menu.flags
-- function number_int:flags(flags): number_int
-- ---@param event menu.event
-- ---@param fn function(number_int)
-- function number_int:event(event, fn): number_int
-- ---@param fmt string
-- ---@param min integer
-- ---@param max integer
-- ---@param step? integer
-- function number_int:fmt(fmt, min, max, step?): number_int
-- ---@param step integer
-- function number_int:step(step): number_int
--
-- ### number_float
-- | Type   | Name   |
-- |--------|--------|
-- | string | name   |
-- | number | value  |
-- | bool   | toggle |
-- ---@param text string
-- function number_float:tooltip(text): number_float
-- ---@param flag menu.flags
-- function number_float:flags(flags): number_float
-- ---@param event menu.event
-- ---@param fn function(number_float)
-- function number_float:event(event, fn): number_float
-- ---@param fmt string
-- ---@param min number
-- ---@param max number
-- ---@param step? number
-- function number_float:fmt(fmt, min, max, step?): number_float
-- ---@param step number
-- function number_float:step(step): number_float
--
-- ### combo_int
-- | Type           | Name   |
-- |----------------|--------|
-- | string         | name   |
-- | integer        | value  |
-- | bool           | toggle |
-- | combo_list_int | list   |
-- | combo_multi_list | multi |
-- ---@param text string
-- function combo_int:tooltip(text): combo_int
-- ---@param flag menu.flags
-- function combo_int:flags(flags): combo_int
-- ---@param event menu.event
-- ---@param fn function(combo_int)
-- function combo_int:event(event, fn): combo_int
--
-- ### combo_float
-- | Type             | Name   |
-- |------------------|--------|
-- | string           | name   |
-- | number           | value  |
-- | bool             | toggle |
-- | combo_list_float | list   |
-- | combo_multi_list | multi  |
-- ---@param text string
-- function combo_float:tooltip(text): combo_float
-- ---@param flag menu.flags
-- function combo_float:flags(flags): combo_float
-- ---@param event menu.event
-- ---@param fn function(combo_float)
-- function combo_float:event(event, fn): combo_float
--
-- ### combo_str
-- | Type           | Name   |
-- |----------------|--------|
-- | string         | name   |
-- | string         | value  |
-- | bool           | toggle |
-- | combo_list_str | list   |
-- | combo_multi_list | multi |
-- ---@param text string
-- function combo_str:tooltip(text): combo_str
-- ---@param flag menu.flags
-- function combo_str:flags(flags): combo_str
-- ---@param event menu.event
-- ---@param fn function(combo_str)
-- function combo_str:event(event, fn): combo_str
--
-- ### combo_list_int
-- | Type    | Name  |
-- |---------|-------|
-- | string  | name  |
-- | integer | value |
-- ---@param index integer
-- function combo_list_int:at(index): combo_list_int
--
-- ### combo_list_float
-- | Type   | Name  |
-- |--------|-------|
-- | string | name  |
-- | number | value |
-- ---@param index integer
-- function combo_list_float:at(index): combo_list_float
--
-- ### combo_list_str
-- | Type   | Name  |
-- |--------|-------|
-- | string | name  |
-- | string | value |
-- ---@param index integer
-- function combo_list_str:at(index): combo_list_str
--
-- ### combo_multi_list
-- | Type    | Name  |
-- |---------|-------|
-- | integer | count |
-- ---@param index integer
-- function combo_multi_list:is_set(index): bool
-- ---@param index integer
-- ---@param value bool
-- function combo_multi_list:set(index, value): nil
-- ---@param index integer
-- function combo_multi_list:is_disabled(index): bool
-- ---@param index integer
-- ---@param value bool
-- function combo_multi_list:disable(index, value): nil
--
-- ## Constants
--
-- ### flags
-- menu.flags.in_game
-- menu.flags.hotkey
-- menu.flags.host_only
-- menu.flags.scr_host_only
-- menu.flags.risky
--
-- ### event
-- menu.event.click
-- menu.event.completed
-- menu.event.enter
-- menu.event.leave
--
-- ### type
-- menu.type.scroll
-- menu.type.press
-- menu.type.toggle
--
-- ## Example
-- ```lua
-- local root = menu.root()
-- local player_root = menu.player_root()
--
-- player_root:button('notify')
--     :event(menu.event.click, function(opt)
--         if players.is_target_session() then
--             notify.push('cool script', 'session is selected', { icon = notify.icon.hazard })
--         else
--             notify.push('cool script', players.target().name, { icon = notify.icon.hazard })
--         end
--     end)
--
-- local self_menu = root:submenu('Self')
--
-- self_menu:button('resize')
--     :event(menu.event.click, function(opt)
--         self_menu:resize(2)
--     end)
--
-- self_menu:button('test loop')
--     :event(menu.event.click, function(opt)
--         local start_time = os.clock()
--         while true do
--             print('test')
--             if os.clock() - start_time >= 3 then return end
--             util:yield()
--         end
--     end)
--
-- self_menu:number_int('int number opt', menu.type.scroll)
--     :fmt('%i', 0, 100)
--     :event(menu.event.click, function(opt)
--         print('value was changed to ' .. opt.value)
--     end)
--
-- self_menu:number_float('float number opt', menu.type.scroll)
--     :fmt('%.2f', 0.0, 100.0)
--     :event(menu.event.click, function(opt)
--         print('value was changed to ' .. opt.value)
--     end)
--
-- local combo_int_list = { { 'name1', 123 }, { 'name2', 43 } }
-- self_menu:combo_int('int combo opt', combo_int_list, menu.type.press)
--     :event(menu.event.click, function(opt)
--         print('index: ' .. opt.value)
--         print('pressed: ' .. opt.list:at(opt.value).name)
--     end)
--
-- local combo_float_list = { { 'n1', 12.34 }, { 'n2', 99.19 }, { 'n3', 12.44 } }
-- self_menu:combo_float('float combo multi opt', combo_float_list, menu.type.press, true)
--     -- true signals that this combo is a "multi" type, where each index can be toggled
--     :event(menu.event.click, function(opt)
--         print('index: ' .. opt.value)
--         print('count: ' .. #combo_float_list)
--         for i = 1, #combo_float_list do
--             print(type(i))
--             print('i:' .. i)
--             print('index: ', i, 'set: ', opt.multi:is_set(i))
--             if opt.multi:is_set(i) then
--                 print(' name: ', combo_float_list[i][1])
--             end
--         end
--     end)
-- ```
---@class menu_flags
---@field in_game       integer
---@field hotkey        integer
---@field host_only     integer
---@field scr_host_only integer
---@field risky         integer
---@class menu_event
---@field click     integer
---@field completed integer
---@field enter     integer
---@field leave     integer
---@class menu_type
---@field scroll integer
---@field press  integer
---@field toggle integer
---@class combo_multi_list
---@field count integer
combo_multi_list = {}
---@param index integer
---@return boolean
function combo_multi_list:is_set(index) end
---@param index integer
---@param value boolean
---@return nil
function combo_multi_list:set(index, value) end
---@param index integer
---@return boolean
function combo_multi_list:is_disabled(index) end
---@param index integer
---@param value boolean
---@return nil
function combo_multi_list:disable(index, value) end
---@class combo_list_int
---@field name  string
---@field value integer
combo_list_int = {}
---@param index integer
---@return combo_list_int
function combo_list_int:at(index) end
---@class combo_list_float
---@field name  string
---@field value number
combo_list_float = {}
---@param index integer
---@return combo_list_float
function combo_list_float:at(index) end
---@class combo_list_str
---@field name  string
---@field value string
combo_list_str = {}
---@param index integer
---@return combo_list_str
function combo_list_str:at(index) end
---@class textbox
---@field name  string
---@field value string
textbox = {}
---@param txt string
---@return textbox
function textbox:tooltip(txt) end
---@param flag integer
---@return textbox
function textbox:flags(flag) end
---@param event integer
---@param fn fun(opt: textbox)
---@return textbox
function textbox:event(event, fn) end
---@param chars integer
---@return textbox
function textbox:max_chars(chars) end
---@class toggle
---@field name  string
---@field value boolean
toggle = {}
---@param txt string
---@return toggle
function toggle:tooltip(txt) end
---@param flag integer
---@return toggle
function toggle:flags(flag) end
---@param event integer
---@param fn fun(opt: toggle)
---@return toggle
function toggle:event(event, fn) end
---@class hotkey
---@field name  string
---@field value integer
hotkey = {}
---@param txt string
---@return hotkey
function hotkey:tooltip(txt) end
---@param flag integer
---@return hotkey
function hotkey:flags(flag) end
---@param event integer
---@param fn fun()
---@return hotkey
function hotkey:event(event, fn) end
---@class breaker
---@field name string
breaker = {}
---@param txt string
---@return breaker
function breaker:tooltip(txt) end
---@param flag integer
---@return breaker
function breaker:flags(flag) end
---@param event integer
---@param fn fun(opt: breaker)
---@return breaker
function breaker:event(event, fn) end
---@class button
---@field name string
button = {}
---@param txt string
---@return button
function button:tooltip(txt) end
---@param flag integer
---@return button
function button:flags(flag) end
---@param event integer
---@param fn fun(opt: button)
---@return button
function button:event(event, fn) end
---@class number_int
---@field name   string
---@field value  integer
---@field toggle boolean
number_int = {}
---@param txt string
---@return number_int
function number_int:tooltip(txt) end
---@param flag integer
---@return number_int
function number_int:flags(flag) end
---@param event integer
---@param fn fun(opt: number_int)
---@return number_int
function number_int:event(event, fn) end
---@param fmt string
---@param min integer
---@param max integer
---@param step? integer
---@return number_int
function number_int:fmt(fmt, min, max, step) end
---@param step integer
---@return number_int
function number_int:step(step) end
---@class number_float
---@field name   string
---@field value  number
---@field toggle boolean
number_float = {}
---@param txt string
---@return number_float
function number_float:tooltip(txt) end
---@param flag integer
---@return number_float
function number_float:flags(flag) end
---@param event integer
---@param fn fun(opt: number_float)
---@return number_float
function number_float:event(event, fn) end
---@param fmt string
---@param min number
---@param max number
---@param step? number
---@return number_float
function number_float:fmt(fmt, min, max, step) end
---@param step number
---@return number_float
function number_float:step(step) end
---@class combo_int
---@field name   string
---@field value  integer
---@field toggle boolean
---@field list   combo_list_int
---@field multi  combo_multi_list
combo_int = {}
---@param txt string
---@return combo_int
function combo_int:tooltip(txt) end
---@param flag integer
---@return combo_int
function combo_int:flags(flag) end
---@param event integer
---@param fn fun(opt: combo_int)
---@return combo_int
function combo_int:event(event, fn) end
---@class combo_float
---@field name   string
---@field value  number
---@field toggle boolean
---@field list   combo_list_float
---@field multi  combo_multi_list
combo_float = {}
---@param txt string
---@return combo_float
function combo_float:tooltip(txt) end
---@param flag integer
---@return combo_float
function combo_float:flags(flag) end
---@param event integer
---@param fn fun(opt: combo_float)
---@return combo_float
function combo_float:event(event, fn) end
---@class combo_str
---@field name   string
---@field value  string
---@field toggle boolean
---@field list   combo_list_str
---@field multi  combo_multi_list
combo_str = {}
---@param txt string
---@return combo_str
function combo_str:tooltip(txt) end
---@param flag integer
---@return combo_str
function combo_str:flags(flag) end
---@param event integer
---@param fn fun(opt: combo_str)
---@return combo_str
function combo_str:event(event, fn) end
---@class submenu_target
submenu_target = {}
---@param name string
---@return submenu_target
function submenu_target:submenu(name) end
---@param name string
---@return toggle
function submenu_target:toggle(name) end
---@param name string
---@param key? integer
---@return hotkey
function submenu_target:hotkey(name, key) end
---@param name string
---@return textbox
function submenu_target:textbox(name) end
---@param name string
---@return button
function submenu_target:button(name) end
---@param name string
---@return breaker
function submenu_target:breaker(name) end
---@param name string
---@param type? integer
---@return number_int
function submenu_target:number_int(name, type) end
---@param name string
---@param type? integer
---@return number_float
function submenu_target:number_float(name, type) end
---@param name string
---@param values table
---@param type integer
---@param multi? boolean
---@return combo_int
function submenu_target:combo_int(name, values, type, multi) end
---@param name string
---@param values table
---@param type integer
---@param multi? boolean
---@return combo_float
function submenu_target:combo_float(name, values, type, multi) end
---@param name string
---@param values table
---@param type integer
---@param multi? boolean
---@return combo_str
function submenu_target:combo_str(name, values, type, multi) end
---@param new_size integer
---@return nil
function submenu_target:resize(new_size) end
---@class menu
---@field flags menu_flags
---@field event menu_event
---@field type  menu_type
menu = {}
--- Returns the submenu instance for your scripts dedicated submenu inside of the Scripts submenu.
---@return submenu_target
function menu.root() end
--- Returns the submenu instance for your scripts dedicated submenu for each player.
---@return submenu_target
function menu.player_root() end
