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

local function initTorchMotes(self)
    self.torchMotes = {}
    local moteCount = 50

    for _ = 1, moteCount do
        table_insert(self.torchMotes, {
            x = math_random() * 1000,
            y = math_random() * 1000,
            size = math_random(1.5, 3.5),
            speedX = math_random(-5, 5),
            speedY = math_random(-10, -3),
            alpha = math_random(0.2, 0.5),
            flickerSpeed = math_random(2, 4),
            flickerPhase = math_random() * math_pi * 2,
            warmTone = math_random() > 0.4
        })
    end
end

local function initShadowWisps(self)
    self.shadowWisps = {}
    local wispCount = 10

    for _ = 1, wispCount do
        table_insert(self.shadowWisps, {
            x = math_random() * 1000,
            y = math_random() * 1000,
            size = math_random(0.5, 1.5),
            speedX = math_random(-10, 10),
            speedY = math_random(-5, 5),
            rotation = math_random() * math_pi * 2,
            rotationSpeed = (math_random() - 0.5) * 0.3,
            alpha = math_random(0.08, 0.2),
            pulseSpeed = math_random(0.3, 0.8),
            pulsePhase = math_random() * math_pi * 2,
        })
    end
end

function BackgroundManager.new(fontManager)
    local instance = setmetatable({}, BackgroundManager)
    instance.time = 0
    instance.fonts = fontManager

    initTorchMotes(instance)
    initShadowWisps(instance)
    return instance
end

function BackgroundManager:update(dt)
    self.time = self.time + dt

    for _, mote in ipairs(self.torchMotes) do
        mote.x = mote.x + mote.speedX * dt
        mote.y = mote.y + mote.speedY * dt

        if mote.y < -20 then mote.y = 1020 end
        if mote.x < -20 then mote.x = 1020 end
        if mote.x > 1020 then mote.x = -20 end
    end

    for _, wisp in ipairs(self.shadowWisps) do
        wisp.x = wisp.x + wisp.speedX * dt
        wisp.y = wisp.y + wisp.speedY * dt
        wisp.rotation = wisp.rotation + wisp.rotationSpeed * dt

        if wisp.x < -100 then wisp.x = 1100 end
        if wisp.x > 1100 then wisp.x = -100 end
        if wisp.y < -100 then wisp.y = 1100 end
        if wisp.y > 1100 then wisp.y = -100 end
    end
end

function BackgroundManager:drawMenuBackground(screenWidth, screenHeight, time)
    -- Warm torchlight gradient
    local cx, cy = screenWidth / 2, screenHeight / 2
    for r = 0, screenWidth * 0.8, 4 do
        local progress = r / (screenWidth * 0.8)
        local flicker = math_sin(time * 3 + progress * 10) * 0.02
        lg.setColor(0.15 + flicker, 0.08 + flicker, 0.02, 0.9 - progress * 0.9)
        lg.circle("fill", cx, cy, r)
    end

    -- Draw shadow wisps (soft ghosts)
    for _, wisp in ipairs(self.shadowWisps) do
        local pulse = (math_sin(wisp.pulsePhase + time * wisp.pulseSpeed) + 1) * 0.5
        local alpha = wisp.alpha * (0.5 + pulse * 0.5)

        lg.push()
        lg.translate(wisp.x, wisp.y)
        lg.rotate(wisp.rotation)
        lg.scale(wisp.size, wisp.size)
        lg.setColor(0.1, 0.1, 0.15, alpha)
        lg.print("☯", 0, 0, 0, 3)
        lg.pop()
    end

    -- Draw torch motes
    for _, mote in ipairs(self.torchMotes) do
        local flicker = (math_sin(time * mote.flickerSpeed + mote.flickerPhase) + 1) * 0.5
        local alpha = mote.alpha * (0.5 + flicker * 0.5)

        lg.setColor(
            mote.warmTone and (0.9) or (0.8),
            mote.warmTone and (0.7) or (0.5),
            mote.warmTone and (0.4) or (0.3),
            alpha
        )
        lg.circle("fill", mote.x, mote.y, mote.size)
    end
end

function BackgroundManager:drawGameBackground(screenWidth, screenHeight, time)
    -- Cool stone dungeon atmosphere
    for y = 0, screenHeight, 2 do
        local progress = y / screenHeight
        local flicker = math_sin(time * 1.2 + progress * 8) * 0.015
        local r = 0.05 + flicker
        local g = 0.05 + progress * 0.05 + flicker
        local b = 0.07 + progress * 0.08 + flicker
        lg.setColor(r, g, b, 1)
        lg.rectangle("fill", 0, y, screenWidth, 2)
    end

    -- Subtle stone block outlines
    lg.setColor(0.1, 0.1, 0.12, 0.3)
    local gridSize = 45
    for x = 0, screenWidth, gridSize do
        for y = 0, screenHeight, gridSize do
            lg.rectangle("line", x, y, gridSize, gridSize)
        end
    end
end

return BackgroundManager
