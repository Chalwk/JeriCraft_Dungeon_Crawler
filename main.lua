-- JeriCraft: Dungeon Crawler
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local Game = require("classes.Game")
local Menu = require("classes.Menu")
local FontManager = require("classes.FontManager")
local BackgroundManager = require("classes.BackgroundManager")

local math_sin = math.sin
local math_cos = math.cos
local math_min = math.min
local math_pi = math.pi
local math_floor = math.floor
local table_insert = table.insert

local math_random = love.math.random
local lg = love.graphics

local game, menu, backgroundManager, fontManager
local screenWidth, screenHeight
local gameState = "menu" -- Start with loading state todo: set this to "loading"
local stateTransition = { alpha = 0, duration = 0.5, timer = 0, active = false }

-- Loading screen variables
local loadingScreen = {
    progress = 0,
    duration = 4.0, -- Total loading time in seconds
    timer = 0,
    complete = false,
    particles = {},
    torchFlicker = 0,
    subtitlePhase = 0
}

local runes = { "†", "‡", "¶", "§", "¤", "•" }

local function updateScreenSize()
    screenWidth = lg.getWidth()
    screenHeight = lg.getHeight()
end

local function startStateTransition(newState)
    stateTransition = {
        alpha = 0,
        duration = 0.3,
        timer = 0,
        active = true,
        targetState = newState
    }
end

local function initLoadingParticles()
    loadingScreen.particles = {}
    for _ = 1, 30 do
        table_insert(loadingScreen.particles, {
            x = math_random(0, screenWidth),
            y = math_random(0, screenHeight),
            size = math_random(2, 6),
            speed = math_random(20, 60),
            life = math_random(1, 3),
            timer = 0,
            alpha = math_random(0.3, 0.8)
        })
    end
end

local function drawLoadingScreen()
    local time = love.timer.getTime()

    -- Dark dungeon background
    lg.setColor(0.02, 0.02, 0.05)
    lg.rectangle("fill", 0, 0, screenWidth, screenHeight)

    -- Subtle stone wall pattern
    lg.setColor(0.08, 0.08, 0.12, 0.6)
    local gridSize = 80
    for x = 0, screenWidth, gridSize do
        for y = 0, screenHeight, gridSize do
            lg.rectangle("line", x + 5, y + 5, gridSize - 10, gridSize - 10)
        end
    end

    -- Animated torch light effect in center
    local centerX, centerY = screenWidth / 2, screenHeight / 2
    loadingScreen.torchFlicker = math_sin(time * 8) * 0.1 + 0.9

    -- Torch glow
    for i = 1, 3 do
        local radius = 150 + i * 50
        local alpha = 0.1 - i * 0.03
        lg.setColor(0.8, 0.4, 0.1, alpha * loadingScreen.torchFlicker)
        lg.circle("fill", centerX, centerY, radius)
    end

    -- Main title with dramatic entrance effect
    local titleScale = 1.0
    if loadingScreen.timer < 1.5 then
        titleScale = math_min(1.0, loadingScreen.timer / 1.5)
    end

    lg.push()
    lg.translate(centerX, centerY - 100)
    lg.scale(titleScale, titleScale)

    -- Title shadow
    lg.setColor(0, 0, 0, 0.8)
    lg.setFont(lg.newFont(72))
    lg.printf("JeriCraft", -200, 2, 400, "center")

    -- Main title with fiery gradient
    local titleProgress = math_min(1.0, loadingScreen.timer / 2.0)
    local r = 0.8 + 0.2 * math_sin(time * 3)
    local g = 0.2 + 0.1 * titleProgress
    local b = 0.1

    lg.setColor(r, g, b, titleProgress)
    lg.printf("JeriCraft", -200, 0, 400, "center")

    lg.pop()

    -- Subtitle with typewriter effect
    if loadingScreen.timer > 1.0 then
        local subtitle = "A DUNGEON CRAWLING LEGACY REBORN"
        local maxChars = math_min(#subtitle, math_floor((loadingScreen.timer - 1.0) * 20))
        local displayText = subtitle:sub(1, maxChars)

        lg.setFont(lg.newFont(18))
        lg.setColor(0.7, 0.7, 0.8, math_min(1.0, (loadingScreen.timer - 1.0) * 2))
        lg.printf(displayText, 0, centerY - 20, screenWidth, "center")
    end

    -- Loading bar background
    local barWidth, barHeight = 400, 20
    local barX, barY = centerX - barWidth / 2, centerY + 80

    lg.setColor(0.1, 0.1, 0.15, 0.8)
    lg.rectangle("fill", barX, barY, barWidth, barHeight, 5)
    lg.setColor(0.3, 0.3, 0.4, 0.6)
    lg.rectangle("line", barX, barY, barWidth, barHeight, 5)

    -- Animated loading bar
    local progressWidth = barWidth * loadingScreen.progress
    local pulse = math_sin(time * 8) * 0.2 + 0.8

    lg.setColor(0.8, 0.3, 0.1, 0.9 * pulse)
    lg.rectangle("fill", barX, barY, progressWidth, barHeight, 5)

    lg.setColor(1, 0.6, 0.2, 1)
    lg.rectangle("line", barX, barY, progressWidth, barHeight, 5)

    -- Loading text with ellipsis animation
    local ellipsis = string.rep(".", math_floor(time * 3) % 4)
    lg.setFont(lg.newFont(16))
    lg.setColor(0.8, 0.8, 0.9, 0.8)
    lg.printf("ENTERING THE DUNGEON" .. ellipsis, 0, barY + 30, screenWidth, "center")

    -- Progress percentage
    lg.printf(math_floor(loadingScreen.progress * 100) .. "%", 0, barY + 55, screenWidth, "center")

    -- Ancient runes decoration
    lg.setFont(lg.newFont(24))
    lg.setColor(0.4, 0.3, 0.2, 0.3)
    for i = 1, 6 do
        local angle = (time * 0.5 + i * math_pi / 3) % (math_pi * 2)
        local radius = 200
        local x = centerX + math_cos(angle) * radius
        local y = centerY + math_sin(angle) * radius
        lg.print(runes[i], x, y)
    end

    -- Copyright text
    lg.setFont(lg.newFont(12))
    lg.setColor(0.5, 0.5, 0.6, 0.6)
    lg.printf("© 2025 Chalwk - JeriCraft: Dungeon Crawler", 0, screenHeight - 30, screenWidth, "center")
end

local function updateLoadingScreen(dt)
    loadingScreen.timer = loadingScreen.timer + dt

    -- Update loading progress
    if not loadingScreen.complete then
        loadingScreen.progress = math_min(1.0, loadingScreen.timer / loadingScreen.duration)

        -- Simulate variable loading speeds
        if loadingScreen.timer > loadingScreen.duration * 0.7 then
            loadingScreen.progress = math_min(1.0, loadingScreen.progress + dt * 0.3)
        elseif loadingScreen.timer > loadingScreen.duration * 0.3 then
            loadingScreen.progress = math_min(0.9, loadingScreen.progress + dt * 0.5)
        end

        -- Check if loading is complete
        if loadingScreen.timer >= loadingScreen.duration then
            loadingScreen.complete = true
            loadingScreen.progress = 1.0
            startStateTransition("menu")
        end
    end

    -- Update particles
    for i, particle in ipairs(loadingScreen.particles) do
        particle.timer = particle.timer + dt
        particle.y = particle.y - particle.speed * dt

        if particle.timer > particle.life or particle.y < -particle.size then
            particle.timer = 0
            particle.y = screenHeight + particle.size
            particle.x = math_random(0, screenWidth)
        end
    end
end

function love.load()
    lg.setDefaultFilter("nearest", "nearest")
    lg.setLineStyle("smooth")

    fontManager = FontManager.new()

    updateScreenSize()
    initLoadingParticles()

    game = Game.new(fontManager)
    menu = Menu.new(fontManager)
    backgroundManager = BackgroundManager.new()

    menu:setScreenSize(screenWidth, screenHeight)
    game:setScreenSize(screenWidth, screenHeight)
end

function love.update(dt)
    updateScreenSize()

    -- Update transitions regardless of state
    if stateTransition.active then
        stateTransition.timer = stateTransition.timer + dt
        stateTransition.alpha = math_min(stateTransition.timer / stateTransition.duration, 1)

        if stateTransition.timer >= stateTransition.duration then
            gameState = stateTransition.targetState
            stateTransition.active = false
            stateTransition.alpha = 0
        end
    end

    if gameState == "loading" then
        updateLoadingScreen(dt)
        return
    end

    if gameState == "menu" then
        menu:update(dt, screenWidth, screenHeight)
    elseif gameState == "playing" then
        game:update(dt)
    elseif gameState == "options" then
        menu:update(dt, screenWidth, screenHeight)
    end

    backgroundManager:update(dt)
end

function love.draw()
    local time = love.timer.getTime()

    if gameState == "loading" then
        drawLoadingScreen()
        return
    end

    -- Draw background based on state
    if gameState == "menu" or gameState == "options" then
        backgroundManager:drawMenuBackground(screenWidth, screenHeight, time)
    elseif gameState == "playing" then
        backgroundManager:drawGameBackground(screenWidth, screenHeight, time)
    end

    -- Draw game content
    if gameState == "menu" or gameState == "options" then
        menu:draw(screenWidth, screenHeight, gameState)
    elseif gameState == "playing" then
        game:draw()
    end

    -- Draw transition overlay
    if stateTransition.active then
        lg.setColor(0, 0, 0, stateTransition.alpha)
        lg.rectangle("fill", 0, 0, screenWidth, screenHeight)
    end
end

function love.mousepressed(x, y, button, istouch)
    if button == 1 then
        if gameState == "menu" then
            local action = menu:handleClick(x, y, "menu")
            if action == "start" then
                startStateTransition("playing")
                game:startNewGame(menu:getDifficulty(), menu:getCharacter())
            elseif action == "options" then
                startStateTransition("options")
            elseif action == "quit" then
                love.event.quit()
            end
        elseif gameState == "options" then
            local action = menu:handleClick(x, y, "options")
            if not action then return end
            if action == "back" then
                startStateTransition("menu")
            elseif action:sub(1, 4) == "diff" then
                local difficulty = action:sub(6)
                menu:setDifficulty(difficulty)
            elseif action:sub(1, 4) == "char" then
                local character = action:sub(6)
                menu:setCharacter(character)
            end
        elseif gameState == "playing" then
            if game:isGameOver() then
                startStateTransition("menu")
            else
                game:handleClick(x, y)
            end
        end
    end
end

function love.keypressed(key)
    if key == "escape" then
        if gameState == "playing" or gameState == "options" then
            startStateTransition("menu")
        else
            love.event.quit()
        end
    elseif key == "f11" then
        local fullscreen = love.window.getFullscreen()
        love.window.setFullscreen(not fullscreen)
    elseif gameState == "playing" and not game:isGameOver() then
        -- Movement keys
        if key == "up" or key == "w" then
            game:movePlayer(0, -1)
        elseif key == "down" or key == "s" then
            game:movePlayer(0, 1)
        elseif key == "left" or key == "a" then
            game:movePlayer(-1, 0)
        elseif key == "right" or key == "d" then
            game:movePlayer(1, 0)
        elseif key == "space" then
            game:waitTurn()
        elseif key == "r" then
            game:rest()
        elseif key == "i" then
            game:toggleInventory()
        end
    end
end

function love.resize(w, h)
    updateScreenSize()
    if gameState == "loading" then
        initLoadingParticles()
    else
        menu:setScreenSize(screenWidth, screenHeight)
        game:setScreenSize(screenWidth, screenHeight)
    end
end
