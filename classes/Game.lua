-- Rogue (2025) – A Modern Dungeon Crawler Adaptation
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local ipairs = ipairs
local math_floor = math.floor
local table_insert = table.insert
local table_remove = table.remove
local math_max = math.max
local math_min = math.min

local lg = love.graphics
local math_random = love.math.random

local SoundManager = require("classes.SoundManager")

local Game = {}
Game.__index = Game

-- Dungeon generation constants
local DUNGEON_WIDTH = 60
local DUNGEON_HEIGHT = 40
local ROOM_MIN_SIZE = 4
local ROOM_MAX_SIZE = 10
local MAX_ROOMS = 20
local UI_WIDTH = 200
local UI_PADDING = 8

-- ASCII characters for display
local TILES = {
    WALL = "#",
    FLOOR = ".",
    DOOR = "+",
    STAIRS_DOWN = ">",
    STAIRS_UP = "<",
    PLAYER = "@",
    GOLD = "*",
    FOOD = "%",
    WEAPON = ")",
    ARMOR = "[",
    POTION = "!",
    SCROLL = "?",
    TRAP = "^"
}

local MONSTERS = {
    { char = "k", name = "Kobold", color = { 0.6, 0.6, 0.2 }, hp = 5,  attack = 2, xp = 5 },
    { char = "o", name = "Orc",    color = { 0.3, 0.7, 0.3 }, hp = 10, attack = 4, xp = 15 },
    { char = "s", name = "Snake",  color = { 0.3, 0.8, 0.3 }, hp = 3,  attack = 1, xp = 3 },
    { char = "z", name = "Zombie", color = { 0.4, 0.6, 0.4 }, hp = 15, attack = 3, xp = 20 },
    { char = "B", name = "Bat",    color = { 0.7, 0.5, 0.7 }, hp = 2,  attack = 1, xp = 2 }
}

local ITEMS = {
    { char = TILES.GOLD,   name = "Gold",           color = { 1, 0.8, 0.2 } },
    { char = TILES.FOOD,   name = "Food",           color = { 0.9, 0.7, 0.3 } },
    { char = TILES.WEAPON, name = "Dagger",         color = { 0.8, 0.8, 0.8 } },
    { char = TILES.ARMOR,  name = "Leather Armor",  color = { 0.6, 0.4, 0.2 } },
    { char = TILES.POTION, name = "Healing Potion", color = { 1, 0.2, 0.2 } },
    { char = TILES.SCROLL, name = "Scroll",         color = { 0.8, 0.8, 1 } }
}

local function addMessage(self, text)
    table_insert(self.messageLog, 1, text)
    if #self.messageLog > 6 then
        table_remove(self.messageLog, 7)
    end
end

local function levelUp(self)
    self.player.level = self.player.level + 1
    self.player.maxHp = self.player.maxHp + 5
    self.player.hp = self.player.maxHp
    self.player.attack = self.player.attack + 2
    self.player.defense = self.player.defense + 1

    addMessage(self, "You reached level " .. self.player.level .. "! You feel stronger!")
end

local function calculateTileSize(self)
    local availableWidth = self.screenWidth - UI_WIDTH - 20
    local availableHeight = self.screenHeight - 100

    -- Calculate tile size based on available space
    local tileWidth = availableWidth / DUNGEON_WIDTH
    local tileHeight = availableHeight / DUNGEON_HEIGHT

    -- Use the smaller dimension to maintain aspect ratio, and ensure integer size
    self.tileSize = math_max(8, math_floor(math_min(tileWidth, tileHeight)))

    -- Force integer tile size for crisp rendering
    self.tileSize = math_max(8, self.tileSize) -- Minimum 8 pixels

    -- Calculate offsets to center the dungeon
    local dungeonPixelWidth = DUNGEON_WIDTH * self.tileSize
    local dungeonPixelHeight = DUNGEON_HEIGHT * self.tileSize

    self.dungeonOffsetX = UI_WIDTH + (availableWidth - dungeonPixelWidth) / 2
    self.dungeonOffsetY = 50 + (availableHeight - dungeonPixelHeight) / 2
end

local function drawDungeon(self)
    -- Recalculate tile size in case screen was resized
    calculateTileSize(self)

    local tileSize = self.tileSize
    local offsetX = self.dungeonOffsetX
    local offsetY = self.dungeonOffsetY

    -- Create and configure font once (cached for performance)
    if not self.dungeonFont or self.dungeonFont:getHeight() ~= tileSize then
        self.dungeonFont = lg.newFont(tileSize)
        self.dungeonFont:setFilter("nearest", "nearest") -- Pixel-perfect scaling
    end
    lg.setFont(self.dungeonFont)

    -- Draw dungeon
    for y = 1, DUNGEON_HEIGHT do
        for x = 1, DUNGEON_WIDTH do
            local tile = self.dungeon[y][x]
            local screenX = offsetX + (x - 1) * tileSize
            local screenY = offsetY + (y - 1) * tileSize

            if self.visibleTiles[y][x] then
                lg.setColor(tile.color)
                lg.print(tile.char, screenX, screenY)
            elseif self.exploredTiles[y][x] then
                lg.setColor(tile.color[1] * 0.3, tile.color[2] * 0.3, tile.color[3] * 0.3)
                lg.print(tile.char, screenX, screenY)
            end
        end
    end

    -- Draw items
    for _, item in ipairs(self.items) do
        if self.visibleTiles[item.y][item.x] then
            local screenX = offsetX + (item.x - 1) * tileSize
            local screenY = offsetY + (item.y - 1) * tileSize
            lg.setColor(item.color)
            lg.print(item.char, screenX, screenY)
        end
    end

    -- Draw monsters
    for _, monster in ipairs(self.monsters) do
        if self.visibleTiles[monster.y][monster.x] then
            local screenX = offsetX + (monster.x - 1) * tileSize
            local screenY = offsetY + (monster.y - 1) * tileSize
            lg.setColor(monster.color)
            lg.print(monster.char, screenX, screenY)
        end
    end

    -- Draw player
    local playerScreenX = offsetX + (self.player.x - 1) * tileSize
    local playerScreenY = offsetY + (self.player.y - 1) * tileSize
    lg.setColor(self.player.color)
    lg.print(self.player.char, playerScreenX, playerScreenY)

    -- Draw white border around the grid
    local gridWidth = DUNGEON_WIDTH * tileSize
    local gridHeight = DUNGEON_HEIGHT * tileSize

    lg.setColor(1, 1, 1, 0.8)
    lg.setLineWidth(2)
    lg.rectangle("line", offsetX, offsetY, gridWidth, gridHeight)
    lg.setLineWidth(1)
end

local function drawUI(self)
    -- Background panel flushed to the left edge
    lg.setColor(0, 0, 0, 0.85)
    lg.rectangle("fill", 0, 0, UI_WIDTH, self.screenHeight)

    -- Common font setup
    lg.setColor(1, 1, 1)
    local smallFont = lg.newFont(14)
    local medFont = lg.newFont(16)
    local titleFont = lg.newFont(18)
    lg.setFont(titleFont)

    local x = UI_PADDING
    local y = UI_PADDING

    -- Header
    lg.print("STATUS", x, y)
    y = y + 28

    -- Player stats
    lg.setFont(medFont)
    lg.print("Level: " .. self.dungeonLevel, x, y); y = y + 24
    lg.print("HP: " .. self.player.hp .. "/" .. self.player.maxHp, x, y); y = y + 24
    lg.print("Atk: " .. self.player.attack, x, y); y = y + 20
    lg.print("Def: " .. self.player.defense, x, y); y = y + 20
    lg.print("Gold: " .. self.player.gold, x, y); y = y + 20
    lg.print("XP: " .. self.player.xp .. "/" .. (self.player.level * 10), x, y); y = y + 20
    lg.print("Turn: " .. self.turn, x, y); y = y + 28

    -- Controls block
    lg.setFont(smallFont)
    lg.setColor(0.75, 0.75, 0.75)
    lg.print("Controls", x, y); y = y + 18
    lg.print("Move: Arrow / WASD", x, y); y = y + 18
    lg.print("Wait: Space", x, y); y = y + 18
    lg.print("Rest: R", x, y); y = y + 18
    lg.print("Inventory: I", x, y); y = y + 18
    lg.print("Menu: ESC", x, y); y = y + 26

    -- Message log at bottom of UI (most recent at top)
    lg.setColor(0.85, 0.85, 0.85)
    lg.setFont(smallFont)
    local logStartY = self.screenHeight - UI_PADDING - (#self.messageLog * 18)
    for i, message in ipairs(self.messageLog) do
        lg.print(message, x, logStartY + (i - 1) * 18)
    end
end

local function drawInventory(self)
    local panelX, panelY = 215, 100
    local panelW, panelH = 440, 380

    -- Background panel with border and drop shadow
    lg.setColor(0, 0, 0, 0.75)
    lg.rectangle("fill", panelX + 4, panelY + 4, panelW, panelH, 8, 8)
    lg.setColor(0.1, 0.1, 0.15, 0.9)
    lg.rectangle("fill", panelX, panelY, panelW, panelH, 8, 8)

    -- Gold border accent
    lg.setColor(1, 0.85, 0.3, 0.8)
    lg.setLineWidth(2)
    lg.rectangle("line", panelX, panelY, panelW, panelH, 8, 8)

    -- Title
    local titleFont = lg.newFont(26)
    lg.setFont(titleFont)
    lg.setColor(1, 0.9, 0.5)
    lg.printf("INVENTORY", panelX, panelY + 15, panelW, "center")

    -- Divider line
    lg.setColor(1, 0.85, 0.3, 0.3)
    lg.rectangle("fill", panelX + 20, panelY + 55, panelW - 40, 1)

    -- Inventory list area
    local listFont = lg.newFont(18)
    lg.setFont(listFont)

    if #self.player.inventory == 0 then
        lg.setColor(0.8, 0.8, 0.8)
        lg.printf("Your inventory is empty.", panelX, panelY + panelH / 2 - 10, panelW, "center")
    else
        local startY = panelY + 75
        local itemSpacing = 26

        for i, item in ipairs(self.player.inventory) do
            local y = startY + (i - 1) * itemSpacing
            local isSelected = (i == self.selectedItem)

            if isSelected then
                -- Highlight background for selected item
                lg.setColor(0.25, 0.25, 0.35, 0.8)
                lg.rectangle("fill", panelX + 24, y - 4, panelW - 48, itemSpacing - 2, 6, 6)
                lg.setColor(1, 1, 0.6)
            else
                lg.setColor(0.9, 0.9, 0.9)
            end

            lg.print("- " .. item, panelX + 36, y)
        end
    end

    -- Footer info
    local footerFont = lg.newFont(14)
    lg.setFont(footerFont)
    lg.setColor(0.75, 0.75, 0.75, 0.8)
    lg.printf("Press I to close", panelX, panelY + panelH - 35, panelW, "center")
end

local function drawGameOver(self)
    lg.setColor(0, 0, 0, 0.7)
    lg.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)

    local font = lg.newFont(48)
    lg.setFont(font)

    if self.won then
        lg.setColor(0.2, 0.8, 0.2)
        lg.printf("VICTORY!", 0, self.screenHeight / 2 - 80, self.screenWidth, "center")
    else
        lg.setColor(0.8, 0.2, 0.2)
        lg.printf("GAME OVER", 0, self.screenHeight / 2 - 80, self.screenWidth, "center")
    end

    lg.setColor(1, 1, 1)
    lg.setFont(lg.newFont(24))
    lg.printf("You reached dungeon level " .. self.dungeonLevel,
        0, self.screenHeight / 2, self.screenWidth, "center")
    lg.printf("Click anywhere to continue",
        0, self.screenHeight / 2 + 60, self.screenWidth, "center")
end

local function roomsIntersect(room1, room2)
    return room1.x <= room2.x + room2.w + 1 and
        room1.x + room1.w + 1 >= room2.x and
        room1.y <= room2.y + room2.h + 1 and
        room1.y + room1.h + 1 >= room2.y
end

local function attackMonster(self, monsterIndex)
    local monster = self.monsters[monsterIndex]
    local damage = math_max(1, self.player.attack - math_random(0, 2))

    monster.hp = monster.hp - damage

    addMessage(self, "You hit the " .. monster.name .. " for " .. damage .. " damage!")

    if monster.hp <= 0 then
        addMessage(self, "You killed the " .. monster.name .. "!")
        self.player.xp = self.player.xp + monster.xp
        self.player.gold = self.player.gold + math_random(1, 5)
        table_remove(self.monsters, monsterIndex)

        -- Check level up
        if self.player.xp >= self.player.level * 10 then levelUp(self) end
    else
        -- Monster counterattack
        local playerDamage = math_max(1, monster.attack - math_random(0, self.player.defense))
        self.player.hp = self.player.hp - playerDamage
        addMessage(self, "The " .. monster.name .. " hits you for " .. playerDamage .. " damage!")

        if self.player.hp <= 0 then self:setGameOver(false) end
    end
end

local function pickupItem(self, itemIndex)
    local item = self.items[itemIndex]

    if item.char == TILES.GOLD then
        local gold = math_random(1, 10)
        self.player.gold = self.player.gold + gold
        addMessage(self, "You found " .. gold .. " gold pieces!")
    elseif item.char == TILES.FOOD then
        local heal = math_random(2, 5)
        self.player.hp = math_min(self.player.maxHp, self.player.hp + heal)
        addMessage(self, "You eat some food and heal " .. heal .. " HP!")
    elseif item.char == TILES.POTION then
        local heal = math_random(5, 10)
        self.player.hp = math_min(self.player.maxHp, self.player.hp + heal)
        addMessage(self, "You drink a healing potion and restore " .. heal .. " HP!")
    else
        table_insert(self.player.inventory, item.name)
        addMessage(self, "You pick up " .. item.name)
    end

    table_remove(self.items, itemIndex)
end

local function attackPlayer(self, monsterIndex)
    local monster = self.monsters[monsterIndex]
    local damage = math_max(1, monster.attack - math_random(0, self.player.defense))

    self.player.hp = self.player.hp - damage
    addMessage(self, "The " .. monster.name .. " hits you for " .. damage .. " damage!")

    if self.player.hp <= 0 then self:setGameOver(false) end
end

local function updateFOV(self)
    local player = self.player
    local radius = 8

    -- Reset visibility
    for y = 1, DUNGEON_HEIGHT do
        for x = 1, DUNGEON_WIDTH do
            self.visibleTiles[y][x] = false
        end
    end

    -- Simple FOV - mark explored tiles
    for y = math_max(1, player.y - radius), math_min(DUNGEON_HEIGHT, player.y + radius) do
        for x = math_max(1, player.x - radius), math_min(DUNGEON_WIDTH, player.x + radius) do
            local dx = x - player.x
            local dy = y - player.y
            if dx * dx + dy * dy <= radius * radius then
                self.visibleTiles[y][x] = true
                self.exploredTiles[y][x] = true
            end
        end
    end
end

local function createTunnel(self, room1, room2)
    local x1 = math_floor(room1.x + room1.w / 2)
    local y1 = math_floor(room1.y + room1.h / 2)
    local x2 = math_floor(room2.x + room2.w / 2)
    local y2 = math_floor(room2.y + room2.h / 2)

    -- Horizontal tunnel then vertical
    for x = math_min(x1, x2), math_max(x1, x2) do
        self.dungeon[y1][x] = { type = "floor", char = TILES.FLOOR, color = { 0.5, 0.5, 0.5 } }
    end
    for y = math_min(y1, y2), math_max(y1, y2) do
        self.dungeon[y][x2] = { type = "floor", char = TILES.FLOOR, color = { 0.5, 0.5, 0.5 } }
    end
end

local function isBlocked(self, x, y)
    -- Check if position is blocked by wall
    if self.dungeon[y][x].type == "wall" then return true end

    -- Check monsters
    for _, monster in ipairs(self.monsters) do
        if monster.x == x and monster.y == y then return true end
    end

    -- Check player
    if self.player.x == x and self.player.y == y then return true end

    return false
end

local function placeEntities(self, room)
    -- Place monsters
    local numMonsters = math_random(0, 2)
    for _ = 1, numMonsters do
        local x = math_random(room.x + 1, room.x + room.w - 2)
        local y = math_random(room.y + 1, room.y + room.h - 2)

        if not isBlocked(self, x, y) then
            local monster = MONSTERS[math_random(#MONSTERS)]
            table_insert(self.monsters, {
                x = x,
                y = y,
                char = monster.char,
                color = monster.color,
                name = monster.name,
                hp = monster.hp,
                maxHp = monster.hp,
                attack = monster.attack,
                xp = monster.xp
            })
        end
    end

    -- Place items
    local numItems = math_random(0, 2)
    for _ = 1, numItems do
        local x = math_random(room.x + 1, room.x + room.w - 2)
        local y = math_random(room.y + 1, room.y + room.h - 2)

        if not isBlocked(self, x, y) then
            local item = ITEMS[math_random(#ITEMS)]
            table_insert(self.items, {
                x = x,
                y = y,
                char = item.char,
                color = item.color,
                name = item.name
            })
        end
    end
end

local function createRoom(self, room)
    for y = room.y, room.y + room.h do
        for x = room.x, room.x + room.w do
            self.dungeon[y][x] = { type = "floor", char = TILES.FLOOR, color = { 0.5, 0.5, 0.5 } }
        end
    end
end

local function generateDungeon(self)
    self.dungeon = {}
    self.monsters = {}
    self.items = {}
    self.visibleTiles = {}

    -- Initialize dungeon with walls
    for y = 1, DUNGEON_HEIGHT do
        self.dungeon[y] = {}
        self.visibleTiles[y] = {}
        self.exploredTiles[y] = self.exploredTiles[y] or {}
        for x = 1, DUNGEON_WIDTH do
            self.dungeon[y][x] = { type = "wall", char = TILES.WALL, color = { 0.3, 0.3, 0.5 } }
            self.visibleTiles[y][x] = false
        end
    end

    local rooms = {}

    for _ = 1, MAX_ROOMS do
        -- Random room size
        local w = math_random(ROOM_MIN_SIZE, ROOM_MAX_SIZE)
        local h = math_random(ROOM_MIN_SIZE, ROOM_MAX_SIZE)

        -- Random position without going out of bounds
        local x = math_random(2, DUNGEON_WIDTH - w - 1)
        local y = math_random(2, DUNGEON_HEIGHT - h - 1)

        local newRoom = { x = x, y = y, w = w, h = h }

        local failed = false
        for _, otherRoom in ipairs(rooms) do
            if roomsIntersect(newRoom, otherRoom) then
                failed = true
                break
            end
        end

        if not failed then
            -- Carve out the room
            createRoom(self, newRoom)

            -- Place player in first room
            if #rooms == 0 then
                self.player.x = math_floor(newRoom.x + newRoom.w / 2)
                self.player.y = math_floor(newRoom.y + newRoom.h / 2)
            else
                -- Connect to previous room with tunnel
                local prevRoom = rooms[#rooms]
                createTunnel(self, prevRoom, newRoom)
            end

            -- Place monsters and items
            placeEntities(self, newRoom)

            table_insert(rooms, newRoom)
        end
    end

    -- Place stairs down in last room
    if #rooms > 0 then
        local lastRoom = rooms[#rooms]
        local sx = math_random(lastRoom.x + 1, lastRoom.x + lastRoom.w - 2)
        local sy = math_random(lastRoom.y + 1, lastRoom.y + lastRoom.h - 2)
        self.dungeon[sy][sx] = { type = "stairs_down", char = TILES.STAIRS_DOWN, color = { 0.8, 0.8, 0.2 } }
    end

    updateFOV(self)
end

local function nextLevel(self)
    self.dungeonLevel = self.dungeonLevel + 1
    addMessage(self, "You descend deeper into the dungeon...")
    generateDungeon(self)
end

local function monsterTurns(self)
    for i, monster in ipairs(self.monsters) do
        if self.visibleTiles[monster.y][monster.x] then
            -- Simple AI: move toward player if visible
            -- Todo: Implement pathfinding
            local dx, dy = 0, 0

            if monster.x < self.player.x then
                dx = 1
            elseif monster.x > self.player.x then
                dx = -1
            end

            if monster.y < self.player.y then
                dy = 1
            elseif monster.y > self.player.y then
                dy = -1
            end

            local newX = monster.x + dx
            local newY = monster.y + dy

            if not isBlocked(self, newX, newY) then
                monster.x = newX
                monster.y = newY
            elseif newX == self.player.x and newY == self.player.y then
                attackPlayer(self, i)
            end
        end
    end
end

function Game.new()
    local instance = setmetatable({}, Game)

    instance.screenWidth = 800
    instance.screenHeight = 600
    instance.gameOver = false
    instance.won = false
    instance.difficulty = "medium"
    instance.character = "warrior"

    -- Game state
    instance.dungeonLevel = 1
    instance.turn = 0
    instance.messageLog = {}
    instance.showInventory = false

    -- Player state
    instance.player = {
        x = 1,
        y = 1,
        char = TILES.PLAYER,
        color = { 1, 1, 1 },
        hp = 20,
        maxHp = 20,
        attack = 5,
        defense = 2,
        gold = 0,
        xp = 0,
        level = 1,
        inventory = {}
    }

    instance.dungeon = {}
    instance.monsters = {}
    instance.items = {}
    instance.visibleTiles = {}
    instance.exploredTiles = {}

    instance.screenShake = { intensity = 0, duration = 0, timer = 0, active = false }
    instance.buttonHover = nil
    instance.time = 0
    instance.dungeonFont = nil

    -- Initialize tile size and offsets
    instance.tileSize = 16
    instance.dungeonOffsetX = UI_WIDTH + 10
    instance.dungeonOffsetY = 50

    local soundManager = SoundManager.new()
    instance.sounds = soundManager

    return instance
end

function Game:movePlayer(dx, dy)
    if self.gameOver then return end

    local newX = self.player.x + dx
    local newY = self.player.y + dy

    -- Check bounds
    if newX < 1 or newX > DUNGEON_WIDTH or newY < 1 or newY > DUNGEON_HEIGHT then
        addMessage(self, "You can't go that way!")
        return
    end

    -- Check for walls
    if self.dungeon[newY][newX].type == "wall" then
        addMessage(self, "You bump into a wall.")
        return
    end

    -- Check for monsters
    local attackedMonster = nil
    for i, monster in ipairs(self.monsters) do
        if monster.x == newX and monster.y == newY then
            attackMonster(self, i)
            attackedMonster = monster
            break
        end
    end

    -- Player attacked, don't move
    if attackedMonster then return end

    -- Check for stairs
    if self.dungeon[newY][newX].type == "stairs_down" then
        nextLevel(self)
        return
    end

    -- Check for items
    for i, item in ipairs(self.items) do
        if item.x == newX and item.y == newY then
            pickupItem(self, i)
            break
        end
    end

    -- Move player
    self.player.x = newX
    self.player.y = newY

    updateFOV(self)
    monsterTurns(self)
    self.turn = self.turn + 1
end

function Game:waitTurn()
    addMessage(self, "You wait a moment...")
    self.turn = self.turn + 1
    monsterTurns(self)
end

function Game:rest()
    local heal = math_random(1, 3)
    self.player.hp = math_min(self.player.maxHp, self.player.hp + heal)
    addMessage(self, "You rest and heal " .. heal .. " HP")
    self.turn = self.turn + 1
    monsterTurns(self)
end

function Game:toggleInventory() self.showInventory = not self.showInventory end

function Game:setGameOver(won)
    self.gameOver = true
    self.won = won
    if won then
        addMessage(self, "You win! Congratulations!")
    else
        addMessage(self, "You have died... Game Over!")
    end
end

function Game:draw()
    -- Apply screen shake if active
    local offsetX, offsetY = 0, 0
    if self.screenShake.active then
        local progress = self.screenShake.timer / self.screenShake.duration
        local currentIntensity = self.screenShake.intensity * (1 - progress)
        offsetX = love.math.random(-currentIntensity, currentIntensity)
        offsetY = love.math.random(-currentIntensity, currentIntensity)
    end

    lg.push()
    lg.translate(offsetX, offsetY)

    drawDungeon(self)
    drawUI(self)

    if self.showInventory then drawInventory(self) end

    if self.gameOver then drawGameOver(self) end

    lg.pop()
end

function Game:update(dt)
    self.time = self.time + dt

    -- Update screen shake
    if self.screenShake.active then
        self.screenShake.timer = self.screenShake.timer + dt
        if self.screenShake.timer >= self.screenShake.duration then
            self.screenShake.active = false
            self.screenShake.intensity = 0
        end
    end
end

function Game:isGameOver() return self.gameOver end

function Game:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
    -- Recalculate tile size when screen size changes
    calculateTileSize(self)
end

function Game:startNewGame(difficulty, character)
    self.difficulty = difficulty or "medium"
    self.character = character or "warrior"

    -- Reset player based on character class
    if self.character == "warrior" then
        self.player = {
            x = 1,
            y = 1,
            char = TILES.PLAYER,
            color = { 1, 1, 1 },
            hp = 25,
            maxHp = 25,
            attack = 6,
            defense = 3,
            gold = 0,
            xp = 0,
            level = 1,
            inventory = {}
        }
    elseif self.character == "rogue" then
        self.player = {
            x = 1,
            y = 1,
            char = TILES.PLAYER,
            color = { 1, 1, 1 },
            hp = 20,
            maxHp = 20,
            attack = 5,
            defense = 2,
            gold = 10,
            xp = 0,
            level = 1,
            inventory = {}
        }
    else -- wizard
        self.player = {
            x = 1,
            y = 1,
            char = TILES.PLAYER,
            color = { 1, 1, 1 },
            hp = 15,
            maxHp = 15,
            attack = 4,
            defense = 1,
            gold = 5,
            xp = 0,
            level = 1,
            inventory = {}
        }
    end

    self.dungeonLevel = 1
    self.turn = 0
    self.messageLog = {}
    self.showInventory = false
    self.gameOver = false
    self.won = false
    self.exploredTiles = {}

    generateDungeon(self)
    addMessage(self, "Welcome to the dungeon! Good luck, adventurer!")
end

function Game:handleClick(x, y)
    if self.gameOver then return end
end

return Game
