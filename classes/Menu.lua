-- JeriCraft: Dungeon Crawler
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local ipairs = ipairs
local math_sin = math.sin
local math_floor = math.floor

local helpText = {
    "Welcome to JeriCraft: Dungeon Crawler!",
    "",
    "Gameplay:",
    "• Explore randomly generated dungeons",
    "• Fight monsters and collect treasure",
    "• Find the doors to descend deeper",
    "• Survive as long as you can!",
    "",
    "Controls:",
    "• Movement: Arrow Keys / WASD",
    "• Wait: Spacebar",
    "• Rest: R (heals slowly)",
    "• Inventory: I",
    "• Menu: ESC",
    "",
    "Symbols:",
    "♜ - You",
    "▥ - Walls",
    "▩ - Floor",
    "🚪 - Doors",
    "Click anywhere to close"
}

local lg = love.graphics

local Menu = {}
Menu.__index = Menu

local function updateOptionsButtonPositions(self)
    local centerX = self.screenWidth / 2
    local totalSectionsHeight = 280
    local startY = (self.screenHeight - totalSectionsHeight) / 2

    -- Difficulty buttons
    local diffButtonW, diffButtonH, diffSpacing = 110, 40, 20
    local diffTotalW = 3 * diffButtonW + 2 * diffSpacing
    local diffStartX = centerX - diffTotalW / 2
    local diffY = startY + 40

    -- Character buttons (2x2 grid)
    local charButtonW, charButtonH, charSpacing = 130, 40, 20
    local charTotalW = 2 * charButtonW + charSpacing
    local charStartX = centerX - charTotalW / 2
    local charY = startY + 120

    -- Navigation
    local navY = startY + 278

    local diffIndex, charIndex = 0, 0
    for _, button in ipairs(self.optionsButtons) do
        if button.section == "difficulty" then
            button.x = diffStartX + diffIndex * (diffButtonW + diffSpacing)
            button.y = diffY
            diffIndex = diffIndex + 1
        elseif button.section == "character" then
            button.x = charStartX + (charIndex % 2) * (charButtonW + charSpacing)
            button.y = charY + math_floor(charIndex / 2) * (charButtonH + 15)
            charIndex = charIndex + 1
        elseif button.section == "navigation" then
            button.x = centerX - button.width / 2
            button.y = navY
        end
    end
end

local function updateButtonPositions(self)
    local startY = self.screenHeight / 2 - 80
    for i, button in ipairs(self.menuButtons) do
        button.x = (self.screenWidth - button.width) / 2
        button.y = startY + (i - 1) * 70
    end

    -- Update help button position
    self.helpButton.y = self.screenHeight - 60
end

local function createMenuButtons(self)
    self.menuButtons = {
        {
            text = "Start Game",
            action = "start",
            width = 240,
            height = 55,
            x = 0,
            y = 0,
            color = { 0.2, 0.7, 0.3 }
        },
        {
            text = "Options",
            action = "options",
            width = 240,
            height = 55,
            x = 0,
            y = 0,
            color = { 0.3, 0.5, 0.8 }
        },
        {
            text = "Quit Game",
            action = "quit",
            width = 240,
            height = 55,
            x = 0,
            y = 0,
            color = { 0.8, 0.3, 0.3 }
        }
    }

    -- Help button
    self.helpButton = {
        text = "?",
        action = "help",
        width = 50,
        height = 50,
        x = 10,
        y = self.screenHeight - 30,
        color = { 0.3, 0.6, 0.9 }
    }

    updateButtonPositions(self)
end

local function createOptionsButtons(self)
    self.optionsButtons = {
        -- Difficulty Section
        {
            text = "Easy",
            action = "diff easy",
            width = 110,
            height = 40,
            x = 0,
            y = 0,
            section = "difficulty",
            color = { 0.3, 0.8, 0.4 }
        },
        {
            text = "Medium",
            action = "diff medium",
            width = 110,
            height = 40,
            x = 0,
            y = 0,
            section = "difficulty",
            color = { 0.9, 0.7, 0.2 }
        },
        {
            text = "Hard",
            action = "diff hard",
            width = 110,
            height = 40,
            x = 0,
            y = 0,
            section = "difficulty",
            color = { 0.8, 0.3, 0.3 }
        },

        -- Character Section
        {
            text = "Warrior",
            action = "char warrior",
            width = 130,
            height = 40,
            x = 0,
            y = 0,
            section = "character",
            color = { 0.8, 0.3, 0.3 }
        },
        {
            text = "jc",
            action = "char jc",
            width = 130,
            height = 40,
            x = 0,
            y = 0,
            section = "character",
            color = { 0.3, 0.7, 0.3 }
        },
        {
            text = "Wizard",
            action = "char wizard",
            width = 130,
            height = 40,
            x = 0,
            y = 0,
            section = "character",
            color = { 0.3, 0.5, 0.8 }
        },

        -- Navigation
        {
            text = "Back to Menu",
            action = "back",
            width = 180,
            height = 45,
            x = 0,
            y = 0,
            section = "navigation",
            color = { 0.6, 0.6, 0.6 }
        }
    }
    updateOptionsButtonPositions(self)
end

local function drawButton(self, button)
    local isHovered = self.buttonHover == button.action
    local pulse = math_sin(self.time * 6) * 0.1 + 0.9

    -- Button background with hover effect
    lg.setColor(button.color[1], button.color[2], button.color[3], isHovered and 0.9 or 0.7)
    lg.rectangle("fill", button.x, button.y, button.width, button.height, 10)

    -- Button border
    lg.setColor(1, 1, 1, isHovered and 1 or 0.8)
    lg.setLineWidth(isHovered and 3 or 2)
    lg.rectangle("line", button.x, button.y, button.width, button.height, 10)

    -- Button text with shadow
    local font = self.fonts:getFont("mediumFont")
    self.fonts:setFont(font)

    local textWidth = font:getWidth(button.text)
    local textHeight = font:getHeight()

    -- Text shadow
    lg.setColor(0, 0, 0, 0.5)
    lg.print(button.text, button.x + (button.width - textWidth) / 2 + 2,
        button.y + (button.height - textHeight) / 2 + 2)

    -- Main text
    lg.setColor(1, 1, 1, pulse)
    lg.print(button.text, button.x + (button.width - textWidth) / 2,
        button.y + (button.height - textHeight) / 2)

    lg.setLineWidth(1)
end

local function drawMenuButtons(self)
    for _, button in ipairs(self.menuButtons) do
        drawButton(self, button)
    end
end

local function drawHelpButton(self)
    local button = self.helpButton
    local isHovered = self.buttonHover == "help"
    local pulse = math_sin(self.time * 5) * 0.2 + 0.8

    -- Button background with hover effect
    lg.setColor(button.color[1], button.color[2], button.color[3], isHovered and 0.9 or 0.7)
    lg.circle("fill", button.x + button.width / 2, button.y + button.height / 2, button.width / 2)

    -- Button border with glow
    lg.setColor(1, 1, 1, isHovered and 1 or 0.8)
    lg.setLineWidth(isHovered and 3 or 2)
    lg.circle("line", button.x + button.width / 2, button.y + button.height / 2, button.width / 2)

    -- Question mark with pulse
    lg.setColor(1, 1, 1, pulse)

    local font = self.fonts:getFont("mediumFont")
    self.fonts:setFont(font)

    local textWidth = font:getWidth(button.text)
    local textHeight = font:getHeight()

    lg.print(button.text,
        button.x + (button.width - textWidth) / 2,
        button.y + (button.height - textHeight) / 2)

    lg.setLineWidth(1)
end

local function drawOptionSection(self, section)
    for _, button in ipairs(self.optionsButtons) do
        if button.section == section then
            drawButton(self, button)

            if button.action:sub(1, 4) == "diff" then
                local difficulty = button.action:sub(6)
                if difficulty == self.difficulty then
                    lg.setColor(0.2, 0.8, 0.2, 0.3)
                    lg.rectangle("fill", button.x - 5, button.y - 5, button.width + 10, button.height + 10, 8)
                    lg.setColor(0.2, 1, 0.2, 0.8)
                    lg.setLineWidth(3)
                    lg.rectangle("line", button.x - 5, button.y - 5, button.width + 10, button.height + 10, 8)
                    lg.setLineWidth(1)
                end
            elseif button.action:sub(1, 4) == "char" then
                local character = button.action:sub(6)
                if character == self.character then
                    lg.setColor(0.2, 0.8, 0.2, 0.3)
                    lg.rectangle("fill", button.x - 5, button.y - 5, button.width + 10, button.height + 10, 8)
                    lg.setColor(0.2, 1, 0.2, 0.8)
                    lg.setLineWidth(3)
                    lg.rectangle("line", button.x - 5, button.y - 5, button.width + 10, button.height + 10, 8)
                    lg.setLineWidth(1)
                end
            end
        end
    end
end

local function drawOptionsInterface(self)
    local totalSectionsHeight = 280
    local startY = (self.screenHeight - totalSectionsHeight) / 2

    -- Draw section headers with icons
    self.fonts:setFont("sectionFont")

    lg.setColor(0.8, 0.9, 1)
    lg.printf("Difficulty", 0, startY + 10, self.screenWidth, "center")
    lg.printf("Character Class", 0, startY + 90, self.screenWidth, "center")

    updateOptionsButtonPositions(self)
    drawOptionSection(self, "difficulty")
    drawOptionSection(self, "character")
    drawOptionSection(self, "navigation")
end

local function drawHelpOverlay(self, screenWidth, screenHeight)
    -- Overlay with blur effect
    for i = 1, 3 do
        local alpha = 0.9 - (i * 0.2)
        lg.setColor(0, 0, 0, alpha)
        lg.rectangle("fill", -i, -i, screenWidth + i * 2, screenHeight + i * 2)
    end

    -- Help box with modern design
    local boxWidth = 650
    local boxHeight = 700
    local boxX = (screenWidth - boxWidth) / 2
    local boxY = (screenHeight - boxHeight) / 2

    -- Box background with gradient
    for y = boxY, boxY + boxHeight do
        local progress = (y - boxY) / boxHeight
        local r = 0.08 + progress * 0.1
        local g = 0.1 + progress * 0.1
        local b = 0.15 + progress * 0.1
        lg.setColor(r, g, b, 0.98)
        lg.line(boxX, y, boxX + boxWidth, y)
    end

    -- Box border with glow
    lg.setColor(0.3, 0.6, 0.9, 0.8)
    lg.setLineWidth(4)
    lg.rectangle("line", boxX, boxY, boxWidth, boxHeight, 12)

    -- Title with icon
    lg.setColor(1, 1, 1)
    self.fonts:setFont("mediumFont")
    lg.printf("JeriCraft: Dungeon Crawler - How to Play", boxX, boxY + 25, boxWidth, "center")

    -- Help text with better formatting
    lg.setColor(0.9, 0.9, 0.9)
    self.fonts:setFont("smallFont")

    local lineHeight = 20
    for i, line in ipairs(helpText) do
        local y = boxY + 90 + (i - 1) * lineHeight
        if line:sub(1, 2) == "• " then
            lg.setColor(0.5, 0.8, 1)
        else
            lg.setColor(0.9, 0.9, 0.9)
        end
        lg.printf(line, boxX + 40, y, boxWidth - 80, "left")
    end

    lg.setLineWidth(1)
end

local function drawDungeonTitle(self, screenWidth, screenHeight)
    local centerX = screenWidth / 2
    local centerY = screenHeight / 5

    lg.push()
    lg.translate(centerX, centerY)
    lg.scale(1.6, 1.6)

    local font = self.fonts:getFont("largeFont")
    self.fonts:setFont(font)

    local height_offset = 55

    -- Title shadow
    lg.setColor(0, 0, 0, 0.5)
    lg.printf(self.title.text, -300 + 4, -font:getHeight() / 2 + 4 - height_offset, 600, "center")

    -- Title main with glow
    lg.setColor(0.9, 0.2, 0.2, self.title.glow)
    lg.printf(self.title.text, -300, -font:getHeight() / 2 - height_offset, 600, "center")
    lg.pop()
end

function Menu.new(fontManager)
    local instance = setmetatable({}, Menu)

    instance.screenWidth = 800
    instance.screenHeight = 600
    instance.difficulty = "medium"
    instance.character = "warrior"
    instance.title = {
        text = "JeriCraft: Dungeon Crawler",
        subtitle =
        "Explore dungeons, fight monsters, and find treasure!\nSurvive as long as you can in this dungeon crawler!",
        scale = 1,
        scaleDirection = 1,
        scaleSpeed = 0.4,
        minScale = 0.92,
        maxScale = 1.08,
        rotation = 0,
        rotationSpeed = 0.15,
        glow = 0
    }
    instance.showHelp = false
    instance.time = 0
    instance.buttonHover = nil
    instance.fonts = fontManager

    createMenuButtons(instance)
    createOptionsButtons(instance)

    return instance
end

function Menu:update(dt, screenWidth, screenHeight)
    self.time = self.time + dt

    if screenWidth ~= self.screenWidth or screenHeight ~= self.screenHeight then
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        updateButtonPositions(self)
        updateOptionsButtonPositions(self)
    end

    -- Title animation
    self.title.scale = self.title.scale + self.title.scaleDirection * self.title.scaleSpeed * dt
    self.title.glow = math_sin(self.time * 3) * 0.3 + 0.7

    if self.title.scale > self.title.maxScale then
        self.title.scale = self.title.maxScale
        self.title.scaleDirection = -1
    elseif self.title.scale < self.title.minScale then
        self.title.scale = self.title.minScale
        self.title.scaleDirection = 1
    end

    self.title.rotation = math_sin(self.time * self.title.rotationSpeed) * 0.1

    -- Update button hover state
    self:updateButtonHover(love.mouse.getX(), love.mouse.getY())
end

function Menu:updateButtonHover(x, y)
    self.buttonHover = nil

    local buttons = self.showHelp and {} or (self.state == "options" and self.optionsButtons or self.menuButtons)

    for _, button in ipairs(buttons) do
        if x >= button.x and x <= button.x + button.width and
            y >= button.y and y <= button.y + button.height then
            self.buttonHover = button.action
            return
        end
    end

    -- Check help button
    if not self.showHelp and self.helpButton and
        x >= self.helpButton.x and x <= self.helpButton.x + self.helpButton.width and
        y >= self.helpButton.y and y <= self.helpButton.y + self.helpButton.height then
        self.buttonHover = "help"
    end
end

function Menu:draw(screenWidth, screenHeight, state)
    self.state = state

    -- Draw the dungeon title
    drawDungeonTitle(self, screenWidth, screenHeight)

    if state == "menu" then
        if self.showHelp then
            drawHelpOverlay(self, screenWidth, screenHeight)
        else
            drawMenuButtons(self)
            lg.setColor(0.9, 0.9, 0.9, 0.8)
            self.fonts:setFont("mediumFont")
            lg.printf(self.title.subtitle, 0, screenHeight / 2 - 350, screenWidth, "center")

            -- Draw help button
            drawHelpButton(self)
        end
    elseif state == "options" then
        drawOptionsInterface(self)
    end

    -- Copyright
    lg.setColor(1, 1, 1, 0.6)
    self.fonts:setFont("smallFont")
    lg.printf("© 2025 Jericho Crosby - JeriCraft: Dungeon Crawler", 10, screenHeight - 30, screenWidth - 20, "right")
end

function Menu:handleClick(x, y, state)
    local buttons = state == "menu" and self.menuButtons or self.optionsButtons

    for _, button in ipairs(buttons) do
        if x >= button.x and x <= button.x + button.width and
            y >= button.y and y <= button.y + button.height then
            return button.action
        end
    end

    -- Check help button in menu state
    if state == "menu" then
        if self.helpButton and x >= self.helpButton.x and x <= self.helpButton.x + self.helpButton.width and
            y >= self.helpButton.y and y <= self.helpButton.y + self.helpButton.height then
            self.showHelp = true
            return "help"
        end

        -- If help is showing, any click closes it
        if self.showHelp then
            self.showHelp = false
            return "help_close"
        end
    end

    return nil
end

function Menu:setDifficulty(difficulty) self.difficulty = difficulty end

function Menu:getDifficulty() return self.difficulty end

function Menu:setCharacter(character) self.character = character end

function Menu:getCharacter() return self.character end

function Menu:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
    updateButtonPositions(self)
    updateOptionsButtonPositions(self)
end

return Menu
