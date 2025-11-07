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
local SPECIAL_ROOM_CHANCE = 0.9 -- Default: 0.3 (30%) chance a room has a special door

-- ASCII characters for display
local TILES = {
    WALL = "█",
    FLOOR = "•",
    DOOR = "╬",
    STAIRS_UP = "⮝",
    STAIRS_DOWN = "⮟",
    PLAYER = "☺",
    GOLD = "♦",
    FOOD = "♠",
    WEAPON = "⚔",
    ARMOR = "🛡",
    POTION = "♣",
    SCROLL = "⁂",
    TRAP = "⌂",
    KEY = "⚷",
    LOCKED_DOOR = "🔒",
    UNLOCKED_DOOR = "🚪"
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
    { char = TILES.GOLD,   name = "Gold",           color = { 1, 0.8, 0.2 } },   -- Bright gold/yellow-orange
    { char = TILES.FOOD,   name = "Food",           color = { 0.9, 0.7, 0.3 } }, -- Warm golden-brown, slightly softer than gold
    { char = TILES.WEAPON, name = "Dagger",         color = { 0.8, 0.8, 0.8 } }, -- Light gray/silver, metallic feel
    { char = TILES.ARMOR,  name = "Leather Armor",  color = { 0.6, 0.4, 0.2 } }, -- Brown, earthy leather tone
    { char = TILES.POTION, name = "Healing Potion", color = { 1, 0.2, 0.2 } },   -- Bright red, signals health/danger
    { char = TILES.SCROLL, name = "Scroll",         color = { 0.8, 0.8, 1 } },   -- Pale blue, cool and magical
    { char = TILES.KEY,    name = "Key",            color = { 1, 1, 0 } }        -- Pure yellow, stands out as collectible
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
    -- Check if position is blocked by wall or locked door
    if dungeon[y][x].type == "wall" or dungeon[y][x].type == "locked_door" then
        return true
    end

    -- Check monsters
    for _, monster in ipairs(monsters) do
        if monster.x == x and monster.y == y then return true end
    end

    -- Check player
    if player.x == x and player.y == y then return true end

    return false
end

local function placeEntities(dungeon, monsters, items, player, room, isSpecialRoom)
    -- Place monsters (more monsters in special rooms)
    local numMonsters = math_random(0, isSpecialRoom and 3 or 2)
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

    -- Place items (better loot in special rooms)
    local numItems = math_random(isSpecialRoom and 2 or 0, isSpecialRoom and 4 or 2)
    for _ = 1, numItems do
        local x = math_random(room.x + 1, room.x + room.w - 2)
        local y = math_random(room.y + 1, room.y + room.h - 2)

        if not isBlocked(dungeon, monsters, player, x, y) then
            local item
            if isSpecialRoom then
                -- Better loot in special rooms
                local specialItems = { TILES.GOLD, TILES.POTION, TILES.WEAPON, TILES.ARMOR }
                item = ITEMS[math_random(#ITEMS)]
                -- Increase chance for good items
                if math_random() > 0.5 then
                    for _, specialItem in ipairs(ITEMS) do
                        if specialItem.char == specialItems[math_random(#specialItems)] then
                            item = specialItem
                            break
                        end
                    end
                end
            else
                item = ITEMS[math_random(#ITEMS)]
            end

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

local function createSpecialRoom(dungeon, connectedRoom)
    -- Create a smaller special room adjacent to the connected room
    local w = math_random(3, 6)
    local h = math_random(3, 6)

    -- Try different positions around the connected room
    local positions = {
        { x = connectedRoom.x + connectedRoom.w + 1, y = connectedRoom.y,                       w = w, h = h, dir = "right" },  -- right
        { x = connectedRoom.x - w - 1,               y = connectedRoom.y,                       w = w, h = h, dir = "left" },   -- left
        { x = connectedRoom.x,                       y = connectedRoom.y + connectedRoom.h + 1, w = w, h = h, dir = "bottom" }, -- bottom
        { x = connectedRoom.x,                       y = connectedRoom.y - h - 1,               w = w, h = h, dir = "top" }     -- top
    }

    -- Shuffle positions to try them in random order
    for i = #positions, 2, -1 do
        local j = math_random(i)
        positions[i], positions[j] = positions[j], positions[i]
    end

    for _, pos in ipairs(positions) do
        -- Check if room fits within dungeon bounds
        if pos.x >= 2 and pos.x + pos.w <= DUNGEON_WIDTH - 1 and
            pos.y >= 2 and pos.y + pos.h <= DUNGEON_HEIGHT - 1 then
            -- Check for overlaps - only check the room area itself, not the borders
            local overlaps = false
            for checkY = pos.y, pos.y + pos.h do
                for checkX = pos.x, pos.x + pos.w do
                    if dungeon[checkY] and dungeon[checkY][checkX] and
                        dungeon[checkY][checkX].type == "floor" then
                        overlaps = true
                        break
                    end
                end
                if overlaps then break end
            end

            if not overlaps then
                createRoom(dungeon, pos)

                -- Add a locked door between the rooms
                local doorX, doorY
                if pos.dir == "right" then -- right side
                    doorX = connectedRoom.x + connectedRoom.w
                    doorY = math_floor(connectedRoom.y + connectedRoom.h / 2)
                elseif pos.dir == "left" then -- left side
                    doorX = connectedRoom.x - 1
                    doorY = math_floor(connectedRoom.y + connectedRoom.h / 2)
                elseif pos.dir == "bottom" then -- bottom
                    doorX = math_floor(connectedRoom.x + connectedRoom.w / 2)
                    doorY = connectedRoom.y + connectedRoom.h
                else -- top
                    doorX = math_floor(connectedRoom.x + connectedRoom.w / 2)
                    doorY = connectedRoom.y - 1
                end

                -- Make sure door position is valid
                if doorX >= 1 and doorX <= DUNGEON_WIDTH and doorY >= 1 and doorY <= DUNGEON_HEIGHT then
                    dungeon[doorY][doorX] = {
                        type = "locked_door",
                        char = TILES.LOCKED_DOOR,
                        color = { 0.8, 0.6, 0.2 }, -- Bronze color for locked door
                        connectedRoom = pos
                    }

                    return pos, doorX, doorY
                end
            end
        end
    end
    return nil
end

function DungeonManager:generateDungeon(player)
    local dungeon = {}
    local monsters = {}
    local items = {}
    local visibleTiles = {}
    local specialRooms = {}

    -- Track if we've created a special room this level
    local specialRoomCreated = false

    -- Initialize dungeon with walls
    for y = 1, DUNGEON_HEIGHT do
        dungeon[y] = {}
        visibleTiles[y] = {}
        if not self.exploredTiles[y] then self.exploredTiles[y] = {} end
        for x = 1, DUNGEON_WIDTH do
            dungeon[y][x] = { type = "wall", char = TILES.WALL, color = { 0.3, 0.3, 0.5 } }
            visibleTiles[y][x] = false
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

            -- Place monsters and items in main room
            placeEntities(dungeon, monsters, items, player, newRoom, false)

            -- Only create ONE special room per level, and only if we have at least one regular room
            if #rooms > 0 and not specialRoomCreated and math_random() < SPECIAL_ROOM_CHANCE then
                print("Attempting to create special room for room #" .. #rooms)
                local specialRoom, doorX, doorY = createSpecialRoom(dungeon, newRoom)
                print("specialRoom:", specialRoom, "door at:", doorX, doorY)
                if specialRoom then
                    specialRoomCreated = true

                    -- Place better loot and monsters in special room
                    placeEntities(dungeon, monsters, items, player, specialRoom, true)

                    -- Add exactly ONE key somewhere in the dungeon (not in the special room)
                    local keyRoom = rooms[math_random(#rooms)]
                    local keyX = math_random(keyRoom.x + 1, keyRoom.x + keyRoom.w - 2)
                    local keyY = math_random(keyRoom.y + 1, keyRoom.y + keyRoom.h - 2)

                    if not isBlocked(dungeon, monsters, player, keyX, keyY) then
                        table_insert(items, {
                            x = keyX,
                            y = keyY,
                            char = TILES.KEY,
                            color = { 1, 1, 0 }, -- Yellow
                            name = "Key"
                        })
                    end

                    -- Store door information
                    table_insert(specialRooms, {
                        doorX = doorX,
                        doorY = doorY,
                        room = specialRoom
                    })
                end
            end

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

    return dungeon, monsters, items, visibleTiles, specialRooms
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
