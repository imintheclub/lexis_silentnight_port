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
        cayo_enforce_heist_toggles()
        casino_enforce_heist_toggles()
        
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
            disable_control_action(CONTROL_ACTION_BLOCK_LIST)
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
