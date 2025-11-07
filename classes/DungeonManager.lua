-- JeriCraft: Dungeon Crawler
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local DungeonManager = {}
DungeonManager.__index = DungeonManager

local ipairs = ipairs
local math_floor = math.floor
local table_insert = table.insert
local math_max = math.max
local math_min = math.min
local math_random = love.math.random

-- Dungeon generation constants
local DUNGEON_WIDTH = 60
local DUNGEON_HEIGHT = 40
local ROOM_MIN_SIZE = 4
local ROOM_MAX_SIZE = 10
local MAX_ROOMS = 20

-- ASCII characters for display
local TILES = {
    WALL = "█",
    FLOOR = "·",
    DOOR = "π",
    STAIRS_UP = "⮝",
    STAIRS_DOWN = "⮟",
    PLAYER = "⛑",
    GOLD = "♦",
    FOOD = "♠",
    WEAPON = "⚔",
    ARMOR = "🛡",
    POTION = "♣",
    SCROLL = "⁂",
    TRAP = "⌂"
}

local MONSTERS = {
    { char = "†", name = "Kobold", color = { 0.6, 0.6, 0.2 }, hp = 5, attack = 2, xp = 5 },
    { char = "‡", name = "Orc", color = { 0.3, 0.7, 0.3 }, hp = 10, attack = 4, xp = 15 },
    { char = "¶", name = "Snake", color = { 0.3, 0.8, 0.3 }, hp = 3, attack = 1, xp = 3 },
    { char = "§", name = "Zombie", color = { 0.4, 0.6, 0.4 }, hp = 15, attack = 3, xp = 20 },
    { char = "¤", name = "Bat", color = { 0.7, 0.5, 0.7 }, hp = 2, attack = 1, xp = 2 },
    { char = "•", name = "Spider", color = { 0.5, 0.4, 0.6 }, hp = 4, attack = 2, xp = 4 }
}

local ITEMS = {
    { char = TILES.GOLD,   name = "Gold",           color = { 1, 0.8, 0.2 } },
    { char = TILES.FOOD,   name = "Food",           color = { 0.9, 0.7, 0.3 } },
    { char = TILES.WEAPON, name = "Dagger",         color = { 0.8, 0.8, 0.8 } },
    { char = TILES.ARMOR,  name = "Leather Armor",  color = { 0.6, 0.4, 0.2 } },
    { char = TILES.POTION, name = "Healing Potion", color = { 1, 0.2, 0.2 } },
    { char = TILES.SCROLL, name = "Scroll",         color = { 0.8, 0.8, 1 } }
}

local function roomsIntersect(room1, room2)
    return room1.x <= room2.x + room2.w + 1
        and room1.x + room1.w + 1 >= room2.x
        and room1.y <= room2.y + room2.h + 1
        and room1.y + room1.h + 1 >= room2.y
end

local function createTunnel(dungeon, room1, room2)
    local x1 = math_floor(room1.x + room1.w / 2)
    local y1 = math_floor(room1.y + room1.h / 2)
    local x2 = math_floor(room2.x + room2.w / 2)
    local y2 = math_floor(room2.y + room2.h / 2)

    -- Horizontal tunnel then vertical
    for x = math_min(x1, x2), math_max(x1, x2) do
        dungeon[y1][x] = { type = "floor", char = TILES.FLOOR, color = { 0.5, 0.5, 0.5 } }
    end
    for y = math_min(y1, y2), math_max(y1, y2) do
        dungeon[y][x2] = { type = "floor", char = TILES.FLOOR, color = { 0.5, 0.5, 0.5 } }
    end
end

local function isBlocked(dungeon, monsters, player, x, y)
    -- Check if position is blocked by wall
    if dungeon[y][x].type == "wall" then return true end

    -- Check monsters
    for _, monster in ipairs(monsters) do
        if monster.x == x and monster.y == y then return true end
    end

    -- Check player
    if player.x == x and player.y == y then return true end

    return false
end

local function placeEntities(dungeon, monsters, items, player, room)
    -- Place monsters
    local numMonsters = math_random(0, 2)
    for _ = 1, numMonsters do
        local x = math_random(room.x + 1, room.x + room.w - 2)
        local y = math_random(room.y + 1, room.y + room.h - 2)

        if not isBlocked(dungeon, monsters, player, x, y) then
            local monster = MONSTERS[math_random(#MONSTERS)]
            table_insert(monsters, {
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

        if not isBlocked(dungeon, monsters, player, x, y) then
            local item = ITEMS[math_random(#ITEMS)]
            table_insert(items, {
                x = x,
                y = y,
                char = item.char,
                color = item.color,
                name = item.name
            })
        end
    end
end

local function createRoom(dungeon, room)
    for y = room.y, room.y + room.h do
        for x = room.x, room.x + room.w do
            dungeon[y][x] = { type = "floor", char = TILES.FLOOR, color = { 0.5, 0.5, 0.5 } }
        end
    end
end

function DungeonManager:generateDungeon(player)
    local dungeon = {}
    local monsters = {}
    local items = {}
    local visibleTiles = {}

    -- Initialize dungeon with walls
    for y = 1, DUNGEON_HEIGHT do
        dungeon[y] = {}
        visibleTiles[y] = {}
        -- Ensure exploredTiles has proper structure
        if not self.exploredTiles[y] then self.exploredTiles[y] = {} end
        for x = 1, DUNGEON_WIDTH do
            dungeon[y][x] = { type = "wall", char = TILES.WALL, color = { 0.3, 0.3, 0.5 } }
            visibleTiles[y][x] = false
            -- Initialize exploredTiles if not already set
            if self.exploredTiles[y][x] == nil then self.exploredTiles[y][x] = false end
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
            createRoom(dungeon, newRoom)

            -- Place player in first room
            if #rooms == 0 then
                player.x = math_floor(newRoom.x + newRoom.w / 2)
                player.y = math_floor(newRoom.y + newRoom.h / 2)
            else
                -- Connect to previous room with tunnel
                local prevRoom = rooms[#rooms]
                createTunnel(dungeon, prevRoom, newRoom)
            end

            -- Place monsters and items
            placeEntities(dungeon, monsters, items, player, newRoom)

            table_insert(rooms, newRoom)
        end
    end

    -- Place stairs down in last room
    if #rooms > 0 then
        local lastRoom = rooms[#rooms]
        local sx = math_random(lastRoom.x + 1, lastRoom.x + lastRoom.w - 2)
        local sy = math_random(lastRoom.y + 1, lastRoom.y + lastRoom.h - 2)
        dungeon[sy][sx] = { type = "stairs_down", char = TILES.STAIRS_DOWN, color = { 0.8, 0.8, 0.2 } }
    end

    return dungeon, monsters, items, visibleTiles
end

function DungeonManager:updateFOV(player, visibleTiles, exploredTiles)
    local radius = 8

    -- Reset visibility
    for y = 1, DUNGEON_HEIGHT do
        for x = 1, DUNGEON_WIDTH do
            visibleTiles[y][x] = false
        end
    end

    -- Simple FOV - mark explored tiles
    for y = math_max(1, player.y - radius), math_min(DUNGEON_HEIGHT, player.y + radius) do
        for x = math_max(1, player.x - radius), math_min(DUNGEON_WIDTH, player.x + radius) do
            local dx = x - player.x
            local dy = y - player.y
            if dx * dx + dy * dy <= radius * radius then
                visibleTiles[y][x] = true
                if exploredTiles[y] then exploredTiles[y][x] = true end
            end
        end
    end
end

function DungeonManager:isBlocked(dungeon, monsters, player, x, y)
    return isBlocked(dungeon, monsters, player, x, y)
end

function DungeonManager.new()
    local instance = setmetatable({}, DungeonManager)
    instance.TILES = TILES
    instance.MONSTERS = MONSTERS
    instance.ITEMS = ITEMS
    instance.DUNGEON_WIDTH = DUNGEON_WIDTH
    instance.DUNGEON_HEIGHT = DUNGEON_HEIGHT
    instance.ROOM_MIN_SIZE = ROOM_MIN_SIZE
    instance.ROOM_MAX_SIZE = ROOM_MAX_SIZE
    instance.MAX_ROOMS = MAX_ROOMS
    instance.exploredTiles = {}
    return instance
end

return DungeonManager
