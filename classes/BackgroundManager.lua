-- JeriCraft: Dungeon Crawler
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local ipairs = ipairs
local math_pi = math.pi
local math_sin = math.sin
local table_insert = table.insert

local math_random = love.math.random
local lg = love.graphics

local BackgroundManager = {}
BackgroundManager.__index = BackgroundManager

local function initFloatingSymbols(self)
    self.floatingSymbols = {}
    local symbolCount = 40

    for _ = 1, symbolCount do
        table_insert(self.floatingSymbols, {
            x = math_random() * 1000,
            y = math_random() * 1000,
            size = math_random(16, 24),
            speedX = math_random(-20, 20),
            speedY = math_random(-20, 20),
            rotation = math_random() * math_pi * 2,
            rotationSpeed = (math_random() - 0.5) * 2,
            bobSpeed = math_random(1, 3),
            bobAmount = math_random(2, 8),
            -- Cool dungeon symbols
            char = math_random() > 0.5 and "█" or "·",
            alpha = math_random(0.3, 0.7),
            isRevealed = math_random() > 0.7,
            isGhost = math_random() > 0.8,
            color = {
                math_random(0.4, 0.6),
                math_random(0.3, 0.5),
                math_random(0.5, 0.7)
            }
        })
    end
end

local function initFloatingMonsters(self)
    self.floatingMonsters = {}
    local monsterCount = 8

    for _ = 1, monsterCount do
        table_insert(self.floatingMonsters, {
            x = math_random() * 1000,
            y = math_random() * 1000,
            size = math_random(0.3, 0.8),
            speedX = math_random(-15, 15),
            speedY = math_random(-15, 15),
            rotation = math_random() * math_pi * 2,
            rotationSpeed = (math_random() - 0.5) * 1,
            bobSpeed = math_random(0.5, 2),
            bobAmount = math_random(1, 4),
            alpha = math_random(0.1, 0.3),
            pulseSpeed = math_random(0.5, 1.5),
            pulsePhase = math_random() * math_pi * 2,
            -- Cool monster symbols
            char = math_random() > 0.5 and "†" or "‡"
        })
    end
end

function BackgroundManager.new()
    local instance = setmetatable({}, BackgroundManager)
    instance.floatingSymbols = {}
    instance.floatingMonsters = {}
    instance.time = 0
    instance.pulseValue = 0

    initFloatingSymbols(instance)
    initFloatingMonsters(instance)

    return instance
end

function BackgroundManager:update(dt)
    self.time = self.time + dt
    self.pulseValue = math_sin(self.time * 2) * 0.5 + 0.5

    -- Update floating symbols
    for _, symbol in ipairs(self.floatingSymbols) do
        symbol.x = symbol.x + symbol.speedX * dt
        symbol.y = symbol.y + symbol.speedY * dt

        -- Bobbing motion
        symbol.y = symbol.y + math_sin(self.time * symbol.bobSpeed) * symbol.bobAmount * dt
        symbol.rotation = symbol.rotation + symbol.rotationSpeed * dt

        -- Wrap around screen edges
        if symbol.x < -50 then symbol.x = 1050 end
        if symbol.x > 1050 then symbol.x = -50 end
        if symbol.y < -50 then symbol.y = 1050 end
        if symbol.y > 1050 then symbol.y = -50 end

        -- Occasionally change revealed state
        if math_random() < 0.01 then
            symbol.isRevealed = not symbol.isRevealed
        end
    end

    -- Update floating monsters
    for _, monster in ipairs(self.floatingMonsters) do
        monster.x = monster.x + monster.speedX * dt
        monster.y = monster.y + monster.speedY * dt

        -- Bobbing motion
        monster.y = monster.y + math_sin(self.time * monster.bobSpeed) * monster.bobAmount * dt
        monster.rotation = monster.rotation + monster.rotationSpeed * dt

        -- Wrap around screen edges
        if monster.x < -100 then monster.x = 1100 end
        if monster.x > 1100 then monster.x = -100 end
        if monster.y < -100 then monster.y = 1100 end
        if monster.y > 1100 then monster.y = -100 end
    end
end

function BackgroundManager:drawMenuBackground(screenWidth, screenHeight, time)
    -- Dark, dungeon-like gradient
    for y = 0, screenHeight, 2 do
        local progress = y / screenHeight
        local pulse = (math_sin(time * 2 + progress * 4) + 1) * 0.05
        local wave = math_sin(progress * 8 + time * 3) * 0.03

        local r = 0.05 + progress * 0.2 + pulse + wave
        local g = 0.03 + progress * 0.1 + pulse
        local b = 0.08 + progress * 0.15 + pulse

        lg.setColor(r, g, b, 0.8)
        lg.rectangle("fill", 0, y, screenWidth, 2)
    end

    -- Draw floating monsters
    for _, monster in ipairs(self.floatingMonsters) do
        local pulse = (math_sin(monster.pulsePhase + time * monster.pulseSpeed) + 1) * 0.5
        local currentAlpha = monster.alpha * (0.7 + pulse * 0.3)

        lg.push()
        lg.translate(monster.x, monster.y)
        lg.rotate(monster.rotation)
        lg.scale(monster.size, monster.size)

        lg.setColor(0.6, 0.2, 0.2, currentAlpha)
        lg.setLineWidth(2)
        lg.print(monster.char, 0, 0, 0, 2)
        lg.setLineWidth(1)
        lg.pop()
    end

    -- Draw floating symbols
    for _, symbol in ipairs(self.floatingSymbols) do
        local bobOffset = math_sin(time * symbol.bobSpeed) * symbol.bobAmount
        local currentY = symbol.y + bobOffset
        local currentAlpha = symbol.alpha

        if symbol.isGhost then
            currentAlpha = currentAlpha * (0.3 + math_sin(time * 2) * 0.2)
        end

        lg.push()
        lg.translate(symbol.x, currentY)
        lg.rotate(symbol.rotation)

        if symbol.isRevealed then
            lg.setColor(0.3, 0.9, 0.4, currentAlpha)
        else
            lg.setColor(symbol.color[1], symbol.color[2], symbol.color[3], currentAlpha)
        end

        lg.print(symbol.char, 0, 0, 0, symbol.size / 18)
        lg.pop()
    end

    -- Dungeon entrance silhouette in center background
    lg.setColor(0.3, 0.3, 0.5, 0.15 + self.pulseValue * 0.1)
    local centerX = screenWidth / 2
    local centerY = screenHeight / 2 - 5

    -- Dungeon entrance
    lg.setLineWidth(6)
    lg.rectangle("line", centerX - 100, centerY - 60, 200, 120, 10)
    lg.setLineWidth(3)
    lg.rectangle("line", centerX - 80, centerY - 40, 160, 80, 5)
    lg.setLineWidth(1)
end

function BackgroundManager:drawGameBackground(screenWidth, screenHeight, time)
    -- Dark, atmospheric dungeon gradient
    for y = 0, screenHeight, 1.5 do
        local progress = y / screenHeight
        local wave = math_sin(progress * 12 + time * 0.8) * 0.02
        local pulse = math_sin(progress * 6 + time) * 0.01

        local r = 0.02 + wave + pulse
        local g = 0.02 + progress * 0.05 + wave
        local b = 0.05 + progress * 0.08 + pulse

        lg.setColor(r, g, b, 0.9)
        lg.rectangle("fill", 0, y, screenWidth, 1.5)
    end

    -- Subtle stone wall pattern
    lg.setColor(0.1, 0.1, 0.15, 0.5)
    local gridSize = 40
    local offset = math_sin(time * 0.3) * 2

    for x = -offset, screenWidth + offset, gridSize do
        for y = -offset, screenHeight + offset, gridSize do
            lg.push()
            lg.translate(x, y)
            lg.rectangle("line", 2, 2, gridSize - 4, gridSize - 4)
            lg.pop()
        end
    end
end

return BackgroundManager
