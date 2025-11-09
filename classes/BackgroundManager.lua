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

local TWO_PI = math_pi * 2
local GRID_SIZE = 45
local MOTE_COUNT = 50
local WISP_COUNT = 10
local SCREEN_BOUNDS = 1000
local SCREEN_BOUNDS_EXTENDED = 1100

local WARM_COLORS = {
    {0.9, 0.7, 0.4},  -- warm tone
    {0.8, 0.5, 0.3}   -- cool tone
}

local function initTorchMotes(self)
    self.torchMotes = {}

    for _ = 1, MOTE_COUNT do
        table_insert(self.torchMotes, {
            x = math_random() * SCREEN_BOUNDS,
            y = math_random() * SCREEN_BOUNDS,
            size = math_random(1.5, 3.5),
            speedX = math_random(-5, 5),
            speedY = math_random(-10, -3),
            alpha = math_random(0.2, 0.5),
            flickerSpeed = math_random(2, 4),
            flickerPhase = math_random() * TWO_PI,
            warmTone = math_random() > 0.4
        })
    end
end

local function initShadowWisps(self)
    self.shadowWisps = {}

    for _ = 1, WISP_COUNT do
        table_insert(self.shadowWisps, {
            x = math_random() * SCREEN_BOUNDS,
            y = math_random() * SCREEN_BOUNDS,
            size = math_random(0.5, 1.5),
            speedX = math_random(-10, 10),
            speedY = math_random(-5, 5),
            rotation = math_random() * TWO_PI,
            rotationSpeed = (math_random() - 0.5) * 0.3,
            alpha = math_random(0.08, 0.2),
            pulseSpeed = math_random(0.3, 0.8),
            pulsePhase = math_random() * TWO_PI,
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

    -- Update torch motes with boundary checking
    for _, mote in ipairs(self.torchMotes) do
        mote.x = mote.x + mote.speedX * dt
        mote.y = mote.y + mote.speedY * dt

        -- Wrap around boundaries
        if mote.y < -20 then mote.y = SCREEN_BOUNDS + 20 end
        if mote.x < -20 then mote.x = SCREEN_BOUNDS + 20 end
        if mote.x > SCREEN_BOUNDS + 20 then mote.x = -20 end
    end

    -- Update shadow wisps with boundary checking
    for _, wisp in ipairs(self.shadowWisps) do
        wisp.x = wisp.x + wisp.speedX * dt
        wisp.y = wisp.y + wisp.speedY * dt
        wisp.rotation = wisp.rotation + wisp.rotationSpeed * dt

        -- Wrap around extended boundaries
        if wisp.x < -100 then wisp.x = SCREEN_BOUNDS_EXTENDED end
        if wisp.x > SCREEN_BOUNDS_EXTENDED then wisp.x = -100 end
        if wisp.y < -100 then wisp.y = SCREEN_BOUNDS_EXTENDED end
        if wisp.y > SCREEN_BOUNDS_EXTENDED then wisp.y = -100 end
    end
end

function BackgroundManager:drawMenuBackground(screenWidth, screenHeight, time)
    local cx, cy = screenWidth * 0.5, screenHeight * 0.5
    local maxRadius = screenWidth * 0.8

    local t = time * 3

    -- Warm torchlight gradient
    for r = 0, maxRadius, 4 do
        local progress = r / maxRadius
        local flicker = math_sin(t + progress * 10) * 0.02
        local alpha = 0.9 - progress * 0.9

        lg.setColor(0.15 + flicker, 0.08 + flicker, 0.02, alpha)
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

    -- Draw torch motes with precomputed colors
    for _, mote in ipairs(self.torchMotes) do
        local flicker = (math_sin(time * mote.flickerSpeed + mote.flickerPhase) + 1) * 0.5
        local alpha = mote.alpha * (0.5 + flicker * 0.5)
        local color = WARM_COLORS[mote.warmTone and 1 or 2]

        lg.setColor(color[1], color[2], color[3], alpha)
        lg.circle("fill", mote.x, mote.y, mote.size)
    end
end

function BackgroundManager:drawGameBackground(screenWidth, screenHeight, time)
    local t = time * 1.2

    -- Cool stone dungeon atmosphere
    for y = 0, screenHeight, 2 do
        local progress = y / screenHeight
        local flicker = math_sin(t + progress * 8) * 0.015
        local r = 0.05 + flicker
        local g = 0.05 + progress * 0.05 + flicker
        local b = 0.07 + progress * 0.08 + flicker

        lg.setColor(r, g, b, 1)
        lg.rectangle("fill", 0, y, screenWidth, 2)
    end

    -- Subtle stone block outlines
    lg.setColor(0.1, 0.1, 0.12, 0.3)
    for x = 0, screenWidth, GRID_SIZE do
        for y = 0, screenHeight, GRID_SIZE do
            lg.rectangle("line", x, y, GRID_SIZE, GRID_SIZE)
        end
    end
end

return BackgroundManager