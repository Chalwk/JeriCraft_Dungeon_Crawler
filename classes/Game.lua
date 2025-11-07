-- JeriCraft: Dungeon Crawler
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
local DungeonManager = require("classes.DungeonManager")
local ItemManager = require("classes.ItemManager")

local Game = {}
Game.__index = Game

-- UI constants
local UI_WIDTH = 200
local UI_PADDING = 8

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
    self.sounds:play("level_up")
end

local function calculateTileSize(self)
    local availableWidth = self.screenWidth - UI_WIDTH - 20
    local availableHeight = self.screenHeight - 100

    -- Calculate tile size based on available space
    local tileWidth = availableWidth / self.dungeonManager.DUNGEON_WIDTH
    local tileHeight = availableHeight / self.dungeonManager.DUNGEON_HEIGHT

    -- Use the smaller dimension to maintain aspect ratio, and ensure integer size
    self.tileSize = math_max(8, math_floor(math_min(tileWidth, tileHeight)))

    -- Force integer tile size for crisp rendering
    self.tileSize = math_max(8, self.tileSize) -- Minimum 8 pixels

    -- Calculate offsets to center the dungeon
    local dungeonPixelWidth = self.dungeonManager.DUNGEON_WIDTH * self.tileSize
    local dungeonPixelHeight = self.dungeonManager.DUNGEON_HEIGHT * self.tileSize

    self.dungeonOffsetX = UI_WIDTH + (availableWidth - dungeonPixelWidth) / 2
    self.dungeonOffsetY = 50 + (availableHeight - dungeonPixelHeight) / 2
end

local function drawDungeon(self)
    -- Recalculate tile size in case screen was resized
    calculateTileSize(self)

    local tileSize = self.tileSize
    local offsetX = self.dungeonOffsetX
    local offsetY = self.dungeonOffsetY

    if not self.dungeonFont or self.dungeonFont:getHeight() ~= tileSize then
        self.dungeonFont = self.fonts:getFontOfSize(tileSize)
    end
    self.fonts:setFont(self.dungeonFont)

    -- Draw entire dungeon
    for y = 1, self.dungeonManager.DUNGEON_HEIGHT do
        for x = 1, self.dungeonManager.DUNGEON_WIDTH do
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
    local gridWidth = self.dungeonManager.DUNGEON_WIDTH * tileSize
    local gridHeight = self.dungeonManager.DUNGEON_HEIGHT * tileSize

    lg.setColor(1, 1, 1, 0.8)
    lg.setLineWidth(2)
    lg.rectangle("line", offsetX, offsetY, gridWidth, gridHeight)
    lg.setLineWidth(1)
end

local function drawSpecialRoom(self)
    -- Recalculate tile size in case screen was resized
    calculateTileSize(self)

    local tileSize = self.tileSize
    local offsetX = self.dungeonOffsetX
    local offsetY = self.dungeonOffsetY

    if not self.dungeonFont or self.dungeonFont:getHeight() ~= tileSize then
        self.dungeonFont = self.fonts:getFontOfSize(tileSize)
    end
    self.fonts:setFont(self.dungeonFont)

    -- Draw special room
    for y = 1, self.dungeonManager.DUNGEON_HEIGHT do
        for x = 1, self.dungeonManager.DUNGEON_WIDTH do
            local tile = self.specialRoomDungeon[y][x]
            local screenX = offsetX + (x - 1) * tileSize
            local screenY = offsetY + (y - 1) * tileSize

            if self.specialRoomVisibleTiles[y][x] then
                lg.setColor(tile.color)
                lg.print(tile.char, screenX, screenY)
            end
        end
    end

    -- Draw special room items
    for _, item in ipairs(self.specialRoomItems) do
        if self.specialRoomVisibleTiles[item.y][item.x] then
            local screenX = offsetX + (item.x - 1) * tileSize
            local screenY = offsetY + (item.y - 1) * tileSize
            lg.setColor(item.color)
            lg.print(item.char, screenX, screenY)
        end
    end

    -- Draw special room monsters
    for _, monster in ipairs(self.specialRoomMonsters) do
        if self.specialRoomVisibleTiles[monster.y][monster.x] then
            local screenX = offsetX + (monster.x - 1) * tileSize
            local screenY = offsetY + (monster.y - 1) * tileSize
            lg.setColor(monster.color)
            lg.print(monster.char, screenX, screenY)
        end
    end

    -- Draw player in special room
    local playerScreenX = offsetX + (self.player.x - 1) * tileSize
    local playerScreenY = offsetY + (self.player.y - 1) * tileSize
    lg.setColor(self.player.color)
    lg.print(self.player.char, playerScreenX, playerScreenY)

    -- Draw white border around the grid with special color
    local gridWidth = self.dungeonManager.DUNGEON_WIDTH * tileSize
    local gridHeight = self.dungeonManager.DUNGEON_HEIGHT * tileSize

    lg.setColor(0.8, 0.6, 0.2, 0.8) -- Gold border for special room
    lg.setLineWidth(3)
    lg.rectangle("line", offsetX, offsetY, gridWidth, gridHeight)
    lg.setLineWidth(1)
end

local function drawUI(self)
    local x = UI_PADDING
    local y = UI_PADDING

    -- Header
    self.fonts:setFont("mediumFont")
    lg.print("STATUS", x, y)
    y = y + 28

    -- Player stats
    self.fonts:setFont("smallFont")
    lg.print("Level: " .. self.dungeonLevel, x, y); y = y + 24
    lg.print("HP: " .. self.player.hp .. "/" .. self.player.maxHp, x, y); y = y + 24
    lg.print("Atk: " .. self.player.attack, x, y); y = y + 20
    lg.print("Def: " .. self.player.defense, x, y); y = y + 20
    lg.print("Gold: " .. self.player.gold, x, y); y = y + 20
    lg.print("XP: " .. self.player.xp .. "/" .. (self.player.level * 10), x, y); y = y + 20
    lg.print("Turn: " .. self.turn, x, y); y = y + 28

    -- Location indicator
    if self.inSpecialRoom then
        lg.setColor(0.8, 0.6, 0.2) -- Gold color for special room
        lg.print("Location: Special Room", x, y); y = y + 20
        lg.setColor(1, 1, 1)       -- Reset to white
    else
        lg.print("Location: Dungeon Level " .. self.dungeonLevel, x, y); y = y + 20
    end

    -- Controls block
    lg.setColor(0.75, 0.75, 0.75)

    self.fonts:setFont("mediumFont")
    lg.print("CONTROLS", x, y); y = y + 18

    local controlsYOffset = 10
    self.fonts:setFont("smallFont")

    lg.print("Move: Arrow / WASD", x, y + controlsYOffset); y = y + 18
    lg.print("Wait: Space", x, y + controlsYOffset); y = y + 18
    lg.print("Rest: R", x, y + controlsYOffset); y = y + 18
    lg.print("Inventory: I", x, y + controlsYOffset); y = y + 18
    lg.print("Menu: ESC", x, y + controlsYOffset); y = y + 26

    -- Message log box
    local boxWidth = UI_WIDTH - UI_PADDING * 2 + 130
    local boxHeight = 6 * 20 + 4
    local boxX = x
    local boxY = self.screenHeight - UI_PADDING - boxHeight - 2 * 26

    -- Draw background box
    lg.setColor(0, 0, 0, 0.6)
    lg.rectangle("fill", boxX, boxY, boxWidth, boxHeight)
    lg.setColor(1, 1, 1, 0.8)
    lg.setLineWidth(2)
    lg.rectangle("line", boxX, boxY, boxWidth, boxHeight)
    lg.setLineWidth(1)

    -- Draw messages inside box (most recent at top)
    lg.setColor(0.85, 0.85, 0.85)
    self.fonts:setFont("smallFont")
    local lineHeight = 18
    local maxMessages = math_floor(boxHeight / lineHeight)
    for i = 1, math_min(#self.messageLog, maxMessages) do
        local message = self.messageLog[i]
        lg.print(message, boxX + 4, boxY + 4 + (i - 1) * lineHeight)
    end
end

local function drawInventory(self)
    local panelX, panelY = 345, 75
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
    self.fonts:setFont("largeFont")

    lg.setColor(1, 0.9, 0.5)
    lg.printf("INVENTORY", panelX, panelY + 15, panelW, "center")

    -- Divider line
    lg.setColor(1, 0.85, 0.3, 0.3)
    lg.rectangle("fill", panelX + 20, panelY + 55, panelW - 40, 1)

    -- Inventory list area
    self.fonts:setFont("listFont")

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
    self.fonts:setFont("mediumFont")
    lg.setColor(0.75, 0.75, 0.75, 1)
    lg.printf("Press I to close", panelX, panelY + panelH - 35, panelW, "center")
end

local function drawGameOver(self)
    lg.setColor(0, 0, 0, 0.7)
    lg.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)

    self.fonts:setFont("largeFont")

    if self.won then
        lg.setColor(0.2, 0.8, 0.2)
        lg.printf("VICTORY!", 0, self.screenHeight / 2 - 80, self.screenWidth, "center")
    else
        lg.setColor(0.8, 0.2, 0.2)
        lg.printf("GAME OVER", 0, self.screenHeight / 2 - 80, self.screenWidth, "center")
    end

    lg.setColor(1, 1, 1)
    self.fonts:setFont("mediumFont")
    lg.printf("You reached dungeon level " .. self.dungeonLevel,
        0, self.screenHeight / 2, self.screenWidth, "center")
    lg.printf("Click anywhere to continue",
        0, self.screenHeight / 2 + 60, self.screenWidth, "center")
end

local function attackMonster(self, monsterIndex, inSpecialRoom)
    local monsters = inSpecialRoom and self.specialRoomMonsters or self.monsters
    local monster = monsters[monsterIndex]
    local damage = math_max(1, self.player.attack - math_random(0, 2))

    monster.hp = monster.hp - damage

    addMessage(self, "You hit the " .. monster.name .. " for " .. damage .. " damage!")
    self.sounds:play("monster_hit")

    if monster.hp <= 0 then
        addMessage(self, "You killed the " .. monster.name .. "!")
        self.player.xp = self.player.xp + monster.xp
        self.player.gold = self.player.gold + math_random(1, 5)
        table_remove(monsters, monsterIndex)

        -- Check level up
        if self.player.xp >= self.player.level * 10 then levelUp(self) end
    else
        -- Monster counterattack
        local playerDamage = math_max(1, monster.attack - math_random(0, self.player.defense))
        self.player.hp = self.player.hp - playerDamage
        addMessage(self, "The " .. monster.name .. " hits you for " .. playerDamage .. " damage!")
        self.sounds:play("player_hit")

        if self.player.hp <= 0 then self:setGameOver(false) end
    end
end

local function pickupItem(self, itemIndex, inSpecialRoom)
    local items = inSpecialRoom and self.specialRoomItems or self.items
    local item = items[itemIndex]

    if item.char == self.dungeonManager.TILES.GOLD then
        local gold = math_random(1, 10)
        self.player.gold = self.player.gold + gold
        addMessage(self, "You found " .. gold .. " gold pieces!")
    elseif item.char == self.dungeonManager.TILES.FOOD then
        local heal = math_random(2, 5)
        self.player.hp = math_min(self.player.maxHp, self.player.hp + heal)
        addMessage(self, "You eat some food and heal " .. heal .. " HP!")
    elseif item.char == self.dungeonManager.TILES.POTION then
        local heal = math_random(5, 10)
        self.player.hp = math_min(self.player.maxHp, self.player.hp + heal)
        addMessage(self, "You drink a healing potion and restore " .. heal .. " HP!")
    else
        table_insert(self.player.inventory, item.name)
        addMessage(self, "You pick up " .. item.name)
    end

    table_remove(items, itemIndex)
end

local function attackPlayer(self, monsterIndex, inSpecialRoom)
    local monsters = inSpecialRoom and self.specialRoomMonsters or self.monsters
    local monster = monsters[monsterIndex]
    local damage = math_max(1, monster.attack - math_random(0, self.player.defense))

    self.player.hp = self.player.hp - damage
    addMessage(self, "The " .. monster.name .. " hits you for " .. damage .. " damage!")
    self.sounds:play("player_hit")

    if self.player.hp <= 0 then self:setGameOver(false) end
end

local function updateFOV(self)
    if self.inSpecialRoom then
        self.dungeonManager:updateFOV(self.player, self.specialRoomVisibleTiles, self.specialRoomVisibleTiles)
    else
        self.dungeonManager:updateFOV(self.player, self.visibleTiles, self.exploredTiles)
    end
end

local function generateDungeon(self)
    local dungeon, monsters, items, visibleTiles, specialDoors = self.dungeonManager:generateDungeon(self.player)

    self.dungeon = dungeon
    self.monsters = monsters
    self.items = items
    self.visibleTiles = visibleTiles
    self.specialDoors = specialDoors or {}

    updateFOV(self)
end

local function enterSpecialRoom(self, doorX, doorY)
    -- Create a unique key for this special door
    local cacheKey = doorX .. "," .. doorY

    -- Check if we already have a cached room for this door
    if self.specialRoomCache[cacheKey] then
        -- Load from cache
        local cached = self.specialRoomCache[cacheKey]
        self.specialRoomDungeon = cached.dungeon
        self.specialRoomMonsters = cached.monsters
        self.specialRoomItems = cached.items
        self.specialRoomVisibleTiles = cached.visibleTiles
        self.specialRoomExitX = cached.exitX
        self.specialRoomExitY = cached.exitY
        self.specialRoom = cached.room

        addMessage(self, "You return to the mysterious chamber!")
    else
        -- Generate new special room and cache it
        local specialDungeon, monsters, items, visibleTiles, exitX, exitY, room =
            self.dungeonManager:generateSpecialRoom()

        self.specialRoomDungeon = specialDungeon
        self.specialRoomMonsters = monsters
        self.specialRoomItems = items
        self.specialRoomVisibleTiles = visibleTiles
        self.specialRoomExitX = exitX
        self.specialRoomExitY = exitY
        self.specialRoom = room

        -- Cache the special room
        self.specialRoomCache[cacheKey] = {
            dungeon = specialDungeon,
            monsters = monsters,
            items = items,
            visibleTiles = visibleTiles,
            exitX = exitX,
            exitY = exitY,
            room = room
        }

        addMessage(self, "You enter a mysterious chamber!")
    end

    -- Save return position and door
    self.specialRoomReturnX = self.player.x
    self.specialRoomReturnY = self.player.y
    self.specialRoomDoorX = doorX
    self.specialRoomDoorY = doorY

    -- Place player near the center of the special room
    self.player.x = math_floor(self.specialRoom.x + self.specialRoom.w / 2)
    self.player.y = math_floor(self.specialRoom.y + self.specialRoom.h / 2)

    -- Set state
    self.inSpecialRoom = true

    self.sounds:play("unlock")

    -- Make entire special room visible
    for y = self.specialRoom.y, self.specialRoom.y + self.specialRoom.h do
        for x = self.specialRoom.x, self.specialRoom.x + self.specialRoom.w do
            if y >= 1 and y <= self.dungeonManager.DUNGEON_HEIGHT and
                x >= 1 and x <= self.dungeonManager.DUNGEON_WIDTH then
                self.specialRoomVisibleTiles[y][x] = true
            end
        end
    end
end

local function leaveSpecialRoom(self)
    if not self.inSpecialRoom then return end

    -- Update the cache with current state before leaving
    local cacheKey = self.specialRoomDoorX .. "," .. self.specialRoomDoorY
    if self.specialRoomCache[cacheKey] then
        self.specialRoomCache[cacheKey] = {
            dungeon = self.specialRoomDungeon,
            monsters = self.specialRoomMonsters,
            items = self.specialRoomItems,
            visibleTiles = self.specialRoomVisibleTiles,
            exitX = self.specialRoomExitX,
            exitY = self.specialRoomExitY,
            room = self.specialRoom
        }
    end

    -- Return player to original position (next to the special door)
    self.player.x = self.specialRoomReturnX
    self.player.y = self.specialRoomReturnY

    -- Reset state
    self.inSpecialRoom = false
    self.specialRoomReturnX = nil
    self.specialRoomReturnY = nil
    self.specialRoomDoorX = nil
    self.specialRoomDoorY = nil
    self.specialRoomDungeon = nil
    self.specialRoomMonsters = nil
    self.specialRoomItems = nil
    self.specialRoomVisibleTiles = nil
    self.specialRoomExitX = nil
    self.specialRoomExitY = nil
    self.specialRoom = nil

    addMessage(self, "You return to the dungeon.")
    self.sounds:play("walk")

    updateFOV(self)
end

local function nextLevel(self)
    self.dungeonLevel = self.dungeonLevel + 1
    addMessage(self, "You descend deeper into the dungeon...")
    self.sounds:play("next_level")
    generateDungeon(self)
end

local function monsterTurns(self, inSpecialRoom)
    local monsters = inSpecialRoom and self.specialRoomMonsters or self.monsters
    local visibleTiles = inSpecialRoom and self.specialRoomVisibleTiles or self.visibleTiles

    for i, monster in ipairs(monsters) do
        if visibleTiles[monster.y][monster.x] then
            -- Simple AI: move toward player if visible
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

            if not self.dungeonManager:isBlocked(
                    inSpecialRoom and self.specialRoomDungeon or self.dungeon,
                    inSpecialRoom and self.specialRoomMonsters or self.monsters,
                    self.player, newX, newY
                ) then
                monster.x = newX
                monster.y = newY
            elseif newX == self.player.x and newY == self.player.y then
                attackPlayer(self, i, inSpecialRoom)
            end
        end
    end
end

-- up, right, down, left
local directions = { { 0, -1 }, { 1, 0 }, { 0, 1 }, { -1, 0 } }
local function tryOpenDoor(self)
    for _, dir in ipairs(directions) do
        local checkX = self.player.x + dir[1]
        local checkY = self.player.y + dir[2]

        -- Check bounds
        if checkX >= 1 and checkX <= self.dungeonManager.DUNGEON_WIDTH and
            checkY >= 1 and checkY <= self.dungeonManager.DUNGEON_HEIGHT then
            local tile = self.dungeon[checkY][checkX]

            if tile.type == "locked_door" then
                -- Check if player has key
                local hasKey = false
                local keyIndex = nil
                for i, itemName in ipairs(self.player.inventory) do
                    if itemName == "Special Key" then
                        hasKey = true
                        keyIndex = i
                        break
                    end
                end

                if hasKey then
                    -- Unlock the door
                    tile.type = "unlocked_door"
                    tile.char = self.dungeonManager.TILES.UNLOCKED_DOOR
                    tile.color = { 0.7, 0.7, 0.7 } -- Gray for unlocked door

                    -- Remove key from inventory
                    table_remove(self.player.inventory, keyIndex)

                    addMessage(self, "You unlock the door with the special key!")
                    self.sounds:play("unlock")
                else
                    addMessage(self, "The door is locked. You need a special key to open it.")
                    self.sounds:play("locked")
                end
                return
            elseif tile.type == "unlocked_door" then
                addMessage(self, "The door is already unlocked.")
                return
            elseif tile.type == "special_door" then
                -- Enter the special room
                enterSpecialRoom(self, checkX, checkY)
                return
            end
        end
    end

    addMessage(self, "There's no door nearby to interact with.")
end

function Game.new(fontManager)
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

    instance.itemManager = ItemManager.new()
    instance.dungeonManager = DungeonManager.new(ItemManager)

    -- Player state
    instance.player = {
        x = 1,
        y = 1,
        char = instance.dungeonManager.TILES.PLAYER,
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
    instance.specialDoors = {}

    -- Special room state
    instance.inSpecialRoom = false
    instance.specialRoomReturnX = nil
    instance.specialRoomReturnY = nil
    instance.specialRoomDoorX = nil
    instance.specialRoomDoorY = nil
    instance.specialRoomDungeon = nil
    instance.specialRoomMonsters = nil
    instance.specialRoomItems = nil
    instance.specialRoomVisibleTiles = nil
    instance.specialRoomExitX = nil
    instance.specialRoomExitY = nil
    instance.specialRoom = nil
    instance.specialRoomCache = {}

    instance.screenShake = { intensity = 0, duration = 0, timer = 0, active = false }
    instance.buttonHover = nil
    instance.time = 0

    -- Initialize tile size and offsets
    instance.tileSize = 16
    instance.dungeonOffsetX = UI_WIDTH + 10
    instance.dungeonOffsetY = 50
    instance.dungeonFont = nil
    instance.fonts = fontManager

    local soundManager = SoundManager.new()
    instance.sounds = soundManager

    return instance
end

function Game:tryOpenDoor() tryOpenDoor(self) end

function Game:movePlayer(dx, dy)
    if self.gameOver then return end

    local newX = self.player.x + dx
    local newY = self.player.y + dy

    -- Check bounds
    if newX < 1 or newX > self.dungeonManager.DUNGEON_WIDTH or newY < 1 or newY > self.dungeonManager.DUNGEON_HEIGHT then
        addMessage(self, "You can't go that way!")
        self.sounds:play("bump")
        return
    end

    if self.inSpecialRoom then
        -- Special room movement logic
        local tile = self.specialRoomDungeon[newY][newX]

        -- Check for walls
        if tile.type == "wall" then
            addMessage(self, "You bump into a wall.")
            self.sounds:play("bump")
            return
        end

        -- Check for special exit (back to main dungeon)
        if tile.type == "special_exit" then
            leaveSpecialRoom(self)
            return
        end

        -- Check for monsters in special room
        local attackedMonster = nil
        for i, monster in ipairs(self.specialRoomMonsters) do
            if monster.x == newX and monster.y == newY then
                self.sounds:play("attack")
                attackMonster(self, i, true)
                attackedMonster = monster
                break
            end
        end

        if attackedMonster then return end

        -- Check for items in special room
        local pickedUpItem = false
        for i, item in ipairs(self.specialRoomItems) do
            if item.x == newX and item.y == newY then
                self.sounds:play("pickup")
                pickupItem(self, i, true)
                pickedUpItem = true
                break
            end
        end

        if not pickedUpItem then self.sounds:play("walk") end

        self.player.x = newX
        self.player.y = newY

        updateFOV(self)
        monsterTurns(self, true)
        self.turn = self.turn + 1
    else
        -- Main dungeon movement logic
        local tile = self.dungeon[newY][newX]

        -- Check for walls
        if tile.type == "wall" then
            addMessage(self, "You bump into a wall.")
            self.sounds:play("bump")
            return
        end

        -- Check for special doors
        if tile.type == "special_door" then
            addMessage(self, "You see a mysterious door. Press 'E' to enter.")
            self.sounds:play("bump")
            return
        end

        -- Check for monsters
        local attackedMonster = nil
        for i, monster in ipairs(self.monsters) do
            if monster.x == newX and monster.y == newY then
                self.sounds:play("attack")
                attackMonster(self, i, false)
                attackedMonster = monster
                break
            end
        end

        if attackedMonster then return end

        -- Check for stairs
        if tile.type == "EXIT" then
            nextLevel(self)
            return
        end

        -- Check for items
        local pickedUpItem = false
        for i, item in ipairs(self.items) do
            if item.x == newX and item.y == newY then
                self.sounds:play("pickup")
                pickupItem(self, i, false)
                pickedUpItem = true
                break
            end
        end

        if not pickedUpItem then self.sounds:play("walk") end

        self.player.x = newX
        self.player.y = newY

        updateFOV(self)
        monsterTurns(self, false)
        self.turn = self.turn + 1
    end
end

function Game:waitTurn()
    addMessage(self, "You wait a moment...")
    self.turn = self.turn + 1
    if self.inSpecialRoom then
        monsterTurns(self, true)
    else
        monsterTurns(self, false)
    end
end

function Game:rest()
    local heal = math_random(1, 3)
    self.player.hp = math_min(self.player.maxHp, self.player.hp + heal)
    addMessage(self, "You rest and heal " .. heal .. " HP")
    self.sounds:play("heal")
    self.turn = self.turn + 1
    if self.inSpecialRoom then
        monsterTurns(self, true)
    else
        monsterTurns(self, false)
    end
end

-- Replace your current toggleInventory function with:
function Game:toggleInventory()
    self.showInventory = not self.showInventory
    if self.showInventory then
        self.selectedItem = 1
    end
end

function Game:useSelectedItem()
    if not self.showInventory or not self.selectedItem then return end

    local itemName = self.player.inventory[self.selectedItem]
    if not itemName then return end

    local result = self.itemManager:useItem(itemName, self.player, self)

    -- Remove the item from inventory after use (except for equipment)
    if not self.itemManager:isEquipment(itemName) then
        table.remove(self.player.inventory, self.selectedItem)
        if #self.player.inventory == 0 then
            self.showInventory = false
        else
            self.selectedItem = math_min(self.selectedItem, #self.player.inventory)
        end
    end

    addMessage(self, result)
end

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
        offsetX = math_random(-currentIntensity, currentIntensity)
        offsetY = math_random(-currentIntensity, currentIntensity)
    end

    lg.push()
    lg.translate(offsetX, offsetY)

    if self.inSpecialRoom then
        drawSpecialRoom(self)
    else
        drawDungeon(self)
    end

    drawUI(self)

    if self.showInventory then drawInventory(self) end

    if self.gameOver then drawGameOver(self) end

    lg.pop()
end

function Game:update(dt)
    self.time = self.time + dt

    local expiredEffects = self.itemManager:updateEffects(self.player, self.turn)
    for _, effectName in ipairs(expiredEffects) do
        addMessage(self, effectName .. " effect has worn off!")
    end

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
    calculateTileSize(self)
end

function Game:startNewGame(difficulty, character)
    self.difficulty = difficulty or "medium"
    self.character = character or "warrior"

    self.inSpecialRoom = false
    self.specialRoomReturnX = nil
    self.specialRoomReturnY = nil
    self.specialRoomDoorX = nil
    self.specialRoomDoorY = nil
    self.specialRoomDungeon = nil
    self.specialRoomMonsters = nil
    self.specialRoomItems = nil
    self.specialRoomVisibleTiles = nil
    self.specialRoomExitX = nil
    self.specialRoomExitY = nil
    self.specialRoom = nil
    self.specialRoomCache = {}

    -- Set up player based on character class
    if self.character == "warrior" then
        self.player = {
            x = 1,
            y = 1,
            char = self.dungeonManager.TILES.PLAYER,
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
    elseif self.character == "jc" then
        self.player = {
            x = 1,
            y = 1,
            char = self.dungeonManager.TILES.PLAYER,
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
            char = self.dungeonManager.TILES.PLAYER,
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
    for y = 1, self.dungeonManager.DUNGEON_HEIGHT do
        self.exploredTiles[y] = {}
        for x = 1, self.dungeonManager.DUNGEON_WIDTH do
            self.exploredTiles[y][x] = false
        end
    end

    generateDungeon(self)
    addMessage(self, "Welcome to the dungeon! Good luck, adventurer!")
end

function Game:handleClick(x, y) if self.gameOver then return end end

return Game
