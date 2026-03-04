Console =
{
    buffer = {},
    openKey = 192,
    show = true,
    showCursor = false,
    position = vec2(300, 300),
    size = vec2(700, 450),
    scroll = 0,
    autoScroll = true,
    maxHeight = 0,
    isDragging = false,
    dragStartMouse = vec2(),
    dragStartTarget = vec2(),
    scaleFactor = 1,
    sbFont = nil,

    headerHeight = 36,
    windowPadding = 12,
    fontSize = 25,
    textPadding = 4,
    rounding = 8,
    scrollWidth = 4,
    scrollMargin = 4,

    headerColor = color(15, 15, 15, 255),
    backgroundColor = color(18, 18, 19, 255),
    scrollColor = color(255, 255, 255, 255),
    textColor = color(255, 255, 255, 255),

    Init = function(self)
        self.scaleFactor = game.resolution().y / 1440

        self.headerHeight = self:_Scale(self.headerHeight)
        self.windowPadding = self:_Scale(self.windowPadding)
        self.fontSize = self:_Scale(self.fontSize)
        self.textPadding = self:_Scale(self.textPadding)
        self.scrollWidth = self:_Scale(self.scrollWidth)
        self.scrollMargin = self:_Scale(self.scrollMargin)

        self.sbFont = gui.load_font(paths.game .. "\\ui\\fonts\\mainsb.ttf", self.fontSize)

        input.show_cursor(self.showCursor)
    end,

    SetDisplayState = function(self, state)
        self.show = state
        self.showCursor = state
        input.show_cursor(state)
    end,

    _Scale = function(self, value1, value2)
        if value2 == nil then
            return value1 * self.scaleFactor
        end

        return vec2(value1 * self.scaleFactor, value2 * self.scaleFactor)
    end,

    Clear = function(self)
        self.buffer = {}
        self.scroll = 0
        self.autoScroll = true
        self.maxHeight = 0
    end,

    _InsertAndRepeat = function(self, time, prefix, color, toInsert, toRepeat)
        table.insert(self.buffer,
        { 
            time = time,
            prefix = prefix,
            color = color,
            text = toInsert
        })
        self.maxHeight = self.maxHeight + gui.text_size(toInsert, self.fontSize, {}).y + self.textPadding

        self:Push(
        {
            time = nil,
            prefix = nil,
            color = nil,
            text = toRepeat
        })
    end,

    Push = function(self, data)
        local text = data.text
        local availableSpace = self.size.x - 2 * self.windowPadding

        local lastSpaceIndex = nil
        local currentText = data.prefix ~= nil and "[" .. string.upper(data.prefix) .. "] " or ""
        local index = 1
        for char in text:gmatch(".") do
            if char == "\n" then
                self:_InsertAndRepeat(data.time, data.prefix, data.color,
                    string.sub(text, 1, index), string.sub(text, index + 1, -1))
                return
            end
            
            if gui.text_size(currentText .. char, self.fontSize, {}).x >= availableSpace then
                local cutPosition = lastSpaceIndex or index
                self:_InsertAndRepeat(data.time, data.prefix, data.color,
                    string.sub(text, 1, cutPosition - 1),
                    string.sub(text, cutPosition + 1, -1))
                return
            end

            if char == " " then
                lastSpaceIndex = index
            end
            currentText = currentText .. char
            index = index + #char
        end
        text = string.sub(text, 1, index)
        
        table.insert(self.buffer,
        { 
            time = data.time,
            prefix = data.prefix,
            color = data.color,
            text = text
        })
        self.maxHeight = self.maxHeight + gui.text_size(text, self.fontSize, {}).y + self.textPadding

        if self.autoScroll then
            self.scroll = math.max(0, self.maxHeight - self.size.y + 2 * self.windowPadding + self.headerHeight)
        end
    end,

    BlockInput = function(self)
        if not self.show then
            return
        end

        local inputs = { 27, 348, 14, 15, 16, 17, 99, 100 }
        for i = 1, #inputs do
            invoker.call(0xFE99B66D079CF6BC, 0, inputs[i], true)
        end

        if self.showCursor then
            local inputs2 = { 24, 69, 92, 106, 122, 135, 142, 144, 176, 237, 257, 329, 346, 1, 2, 12, 13,
                66, 67, 95, 98, 270, 271, 272, 273, 282, 283, 284, 285, 286, 287, 332, 333 }
            for i = 1, #inputs2 do
                invoker.call(0xFE99B66D079CF6BC, 0, inputs2[i], true)
            end
        end
    end,

    HandleOpenKey = function(self)
        if input.key(self.openKey).just_pressed then
            self.show = not self.show
            if self.show then
                input.show_cursor(self.showCursor)
            else
                input.show_cursor(false)
            end
        end
    end,

    HandleShowCursorKey = function(self)
        if not self.show then
            return
        end

        if input.mouse(4).just_pressed then
            self.showCursor = not self.showCursor
            input.show_cursor(self.showCursor)
        end
    end,

    HandleScroll = function(self, value)
        if not self.show then
            return
        end

        local maxScrollPos = math.max(0, self.maxHeight - self.size.y + 2 * self.windowPadding + self.headerHeight)
        self.scroll = math.max(0, math.min(maxScrollPos, self.scroll + value.offset * self:_Scale(60)))
        
        self.autoScroll = self.scroll == maxScrollPos
    end,

    HandleWindowDrag = function(self)
        if not self.show or not self.showCursor then
            return
        end

        local mousePosition = input.mouse_position()
        local mouseDown = input.mouse(0x01).pressed
        if input.is_mouse_within(self.position, vec2(self.size.x, self.headerHeight))
            and input.mouse(0x01).just_pressed and not self.isDragging then
            self.isDragging = true
            self.dragStartMouse = mousePosition
            self.dragStartTarget = self.position
        end

        if not mouseDown then
            self.isDragging = false
        end

        if mouseDown and self.isDragging then
            self.position = vec2(self.dragStartTarget.x + mousePosition.x - self.dragStartMouse.x,
                self.dragStartTarget.y + mousePosition.y - self.dragStartMouse.y)
        end
    end,

    Render = function(self)
        if not self.show then
            return
        end

        gui.rect(self.position, self.size):filled():rounding(self.rounding):color(self.backgroundColor):draw()

        gui.rect(self.position, vec2(self.size.x, self.headerHeight)):filled()
            :rounding(self.rounding, gui.rounding.top_left + gui.rounding.top_right):color(self.headerColor):draw()

        local titleSize = gui.text_size("Console", self.fontSize, {font = self.sbFont})
        gui.text("Console")
            :position(vec2(self.position.x + self.size.x / 2, self.position.y + (self.headerHeight - titleSize.y) / 2))
            :justify(gui.justify.center):scale(self.fontSize):color(self.textColor):font(self.sbFont):draw()

        gui.push_clip(vec2(self.position.x, self.position.y + self.headerHeight),
            vec2(self.size.x, self.size.y - self.headerHeight))

        local availableSpace = self.size.y - 2 * self.windowPadding - self.headerHeight
        local lineHeight = self.fontSize + self.textPadding

        local startIndex = math.max(1, math.floor(self.scroll / lineHeight))
        local endIndex = math.min(#self.buffer, startIndex + math.ceil(availableSpace / lineHeight) + 1)

        local currentY = self.position.y + self.headerHeight + self.windowPadding - self.textPadding
            - (self.scroll - (startIndex - 1) * lineHeight)

        for i = startIndex, endIndex do
            local currentX = self.position.x + self.windowPadding
            local line = self.buffer[i]
            currentY = currentY + self.textPadding

            if line.prefix ~= nil then
                local prefix = "[" .. string.upper(line.prefix) .. "] "
                gui.text(prefix):position(vec2(currentX, currentY)):scale(self.fontSize)
                    :color(line.color):draw()
                currentX = currentX + gui.text_size(prefix, self.fontSize, {}).x
            end

            gui.text(line.text):position(vec2(currentX, currentY)):scale(self.fontSize)
                :color(self.textColor):draw()
            currentY = currentY + gui.text_size(line.text, self.fontSize, {}).y
        end

        gui.pop_clip()

        if self.maxHeight > availableSpace then
            local availableHeight = self.size.y - 2 * self.windowPadding - self.headerHeight
    
            local scrollHeight = math.max(self.size.y / 10, availableHeight * (availableHeight / self.maxHeight))
    
            local maxScroll = self.maxHeight - availableHeight
            local scrollRatio = math.max(0, math.min(1, self.scroll / maxScroll))
    
            local scrollTrackHeight = self.size.y - self.headerHeight - scrollHeight
            local scrollY = self.position.y + self.headerHeight + scrollRatio * scrollTrackHeight

            gui.rect(vec2(self.position.x + self.size.x + self.scrollMargin, self.position.y + self.headerHeight),
                vec2(self.scrollWidth + 2, self.size.y - self.headerHeight))
                :filled():rounding(self.rounding):color(self.backgroundColor):draw()

            gui.rect(vec2(self.position.x + self.size.x + self.scrollMargin + 1, scrollY + 1),
                vec2(self.scrollWidth, scrollHeight - 2))
                :filled():rounding(self.rounding):color(self.scrollColor):draw()
        end
    end,
}

Console:Init()

events.subscribe(events.event.log, function(data)
    Console:Push(data)
end)

events.subscribe(events.event.scroll, function(data)
    Console:HandleScroll(data)
end)

util.create_thread(function(thread)
    Console:HandleOpenKey()
    Console:HandleShowCursorKey()
    Console:HandleWindowDrag()

    Console:BlockInput()

    Console:Render()
end)


function CreateMenu()
    local root = menu.root()

    root:hotkey("Open Key", Console.openKey)
        :event(menu.event.click, function(opt)
            Console:SetDisplayState(false)
        end)
        :event(menu.event.completed, function(opt)
            Console.openKey = opt.value
            Console:SetDisplayState(true)
        end)

    root:button("Clear Console")
        :event(menu.event.click, function(opt)
            Console:Clear()
        end)
end

CreateMenu()