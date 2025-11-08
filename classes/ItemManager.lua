-- JeriCraft: Dungeon Crawler
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local ItemManager = {}
ItemManager.__index = ItemManager

local ipairs = ipairs
local pairs = pairs
local table_insert = table.insert

local math_random = love.math.random
local math_min = math.min
local math_max = math.max

-- Basic item definitions for regular rooms
local BASIC_ITEMS = {
    { char = "♦", name = "Gold", color = { 1, 0.8, 0.2 } },
    { char = "♠", name = "Food", color = { 0.9, 0.7, 0.3 } },
    { char = "⚔", name = "Dagger", color = { 0.8, 0.8, 0.8 } },
    { char = "⌺", name = "Leather Armor", color = { 0.6, 0.4, 0.2 } },
    { char = "♣", name = "Healing Potion", color = { 1, 0.2, 0.2 } },
    { char = "⁂", name = "Scroll", color = { 0.8, 0.8, 1 } }
}

local ITEM_EFFECTS = {
    -- Weapons
    ["Dagger"] = {
        type = "weapon",
        use = function(player, game)
            local bonus = math_random(1, 3)
            player.attack = player.attack + bonus
            return "You equip the dagger! Attack +" .. bonus
        end
    },
    ["Iron Sword"] = {
        type = "weapon",
        use = function(player, game)
            local bonus = math_random(2, 4)
            player.attack = player.attack + bonus
            return "You equip the iron sword! Attack +" .. bonus
        end
    },
    ["Steel Sword"] = {
        type = "weapon",
        use = function(player, game)
            local bonus = math_random(3, 6)
            player.attack = player.attack + bonus
            return "You equip the steel sword! Attack +" .. bonus
        end
    },
    ["Magic Wand"] = {
        type = "weapon",
        use = function(player, game)
            local bonus = math_random(2, 5)
            player.attack = player.attack + bonus
            player.maxHp = player.maxHp + 5
            player.hp = math_min(player.maxHp, player.hp + 5)
            return "You equip the magic wand! Attack +" .. bonus .. ", Max HP +5"
        end
    },

    -- Armor
    ["Leather Armor"] = {
        type = "armor",
        use = function(player, game)
            local bonus = math_random(1, 2)
            player.defense = player.defense + bonus
            return "You equip the leather armor! Defense +" .. bonus
        end
    },
    ["Chain Mail"] = {
        type = "armor",
        use = function(player, game)
            local bonus = math_random(2, 3)
            player.defense = player.defense + bonus
            return "You equip the chain mail! Defense +" .. bonus
        end
    },
    ["Plate Armor"] = {
        type = "armor",
        use = function(player, game)
            local bonus = math_random(3, 5)
            player.defense = player.defense + bonus
            return "You equip the plate armor! Defense +" .. bonus
        end
    },
    ["Magic Robe"] = {
        type = "armor",
        use = function(player, game)
            local defenseBonus = math_random(1, 2)
            local hpBonus = math_random(5, 10)
            player.defense = player.defense + defenseBonus
            player.maxHp = player.maxHp + hpBonus
            player.hp = math_min(player.maxHp, player.hp + hpBonus)
            return "You equip the magic robe! Defense +" .. defenseBonus .. ", Max HP +" .. hpBonus
        end
    },

    -- Potions
    ["Healing Potion"] = {
        type = "potion",
        use = function(player, game)
            local heal = math_random(5, 10)
            player.hp = math_min(player.maxHp, player.hp + heal)
            return "You drink a healing potion! HP +" .. heal
        end
    },
    ["Greater Healing Potion"] = {
        type = "potion",
        use = function(player, game)
            local heal = math_random(15, 25)
            player.hp = math_min(player.maxHp, player.hp + heal)
            return "You drink a greater healing potion! HP +" .. heal
        end
    },
    ["Potion of Might"] = {
        type = "potion",
        use = function(player, game)
            local attackBonus = math_random(3, 6)
            local defenseBonus = math_random(2, 4)
            player.attack = player.attack + attackBonus
            player.defense = player.defense + defenseBonus
            return "You drink the potion of might! Attack +" ..
                attackBonus .. ", Defense +" .. defenseBonus .. " (temporary)"
        end,
        duration = 10
    },
    ["Potion of Invulnerability"] = {
        type = "potion",
        use = function(player, game)
            local defenseBonus = math_random(5, 8)
            player.defense = player.defense + defenseBonus
            return "You drink the potion of invulnerability! Defense +" .. defenseBonus .. " (temporary)"
        end,
        duration = 8
    },
    ["Potion of Berserk"] = {
        type = "potion",
        use = function(player, game)
            local attackBonus = math_random(5, 10)
            player.attack = player.attack + attackBonus
            player.defense = math_max(0, player.defense - 2) -- Small defense penalty
            return "You drink the potion of berserk! Attack +" .. attackBonus .. ", Defense -2 (temporary)"
        end,
        duration = 6
    },

    -- Scrolls
    ["Scroll of Strength"] = {
        type = "scroll",
        use = function(player, game)
            local bonus = math_random(2, 5)
            player.attack = player.attack + bonus
            return "You read the scroll of strength! Attack +" .. bonus .. " (temporary)"
        end,
        duration = 20
    },
    ["Scroll of Protection"] = {
        type = "scroll",
        use = function(player, game)
            local bonus = math_random(2, 4)
            player.defense = player.defense + bonus
            return "You read the scroll of protection! Defense +" .. bonus .. " (temporary)"
        end,
        duration = 15
    },
    ["Scroll of Healing"] = {
        type = "scroll",
        use = function(player, game)
            local heal = math_random(8, 15)
            player.hp = math_min(player.maxHp, player.hp + heal)
            return "You read the scroll of healing! HP +" .. heal
        end
    },
    ["Scroll of Teleportation"] = {
        type = "scroll",
        use = function(player, game)
            local possiblePositions = {}
            local dungeon = game.inSpecialRoom and game.specialRoomDungeon or game.dungeon
            local monsters = game.inSpecialRoom and game.specialRoomMonsters or game.monsters

            for y = 1, #dungeon do
                for x = 1, #dungeon[y] do
                    local tile = dungeon[y][x]
                    if tile.type == "floor" then
                        -- Check if position is blocked by monsters or player
                        local blocked = false
                        for _, monster in ipairs(monsters) do
                            if monster.x == x and monster.y == y then
                                blocked = true
                                break
                            end
                        end
                        if not blocked and not (player.x == x and player.y == y) then
                            table_insert(possiblePositions, { x = x, y = y })
                        end
                    end
                end
            end

            if #possiblePositions > 0 then
                local target = possiblePositions[math_random(#possiblePositions)]
                player.x = target.x
                player.y = target.y
                game:updateFOV()
                return "The scroll teleports you to another location!"
            else
                return "The scroll fizzles... nowhere safe to teleport!"
            end
        end
    },
    ["Scroll of Identify"] = {
        type = "scroll",
        use = function(player, game)
            -- Reveal entire current level for a few turns
            if game.inSpecialRoom then
                for y = 1, #game.specialRoomVisibleTiles do
                    for x = 1, #game.specialRoomVisibleTiles[y] do
                        game.specialRoomVisibleTiles[y][x] = true
                    end
                end
            else
                for y = 1, #game.visibleTiles do
                    for x = 1, #game.visibleTiles[y] do
                        game.visibleTiles[y][x] = true
                    end
                end
            end
            return "The scroll reveals the entire area around you!"
        end
    },
    ["Scroll of Monster Confusion"] = {
        type = "scroll",
        use = function(player, game)
            local monsters = game.inSpecialRoom and game.specialRoomMonsters or game.monsters
            local confusedCount = 0

            for _, monster in ipairs(monsters) do
                if math_random() < 0.6 then -- 60% chance to confuse each monster
                    -- Move monster randomly
                    local directions = { { 0, -1 }, { 1, 0 }, { 0, 1 }, { -1, 0 } }
                    local dir = directions[math_random(#directions)]
                    local newX = monster.x + dir[1]
                    local newY = monster.y + dir[2]

                    local dungeon = game.inSpecialRoom and game.specialRoomDungeon or game.dungeon
                    if dungeon[newY] and dungeon[newY][newX] and dungeon[newY][newX].type == "floor" then
                        monster.x = newX
                        monster.y = newY
                        confusedCount = confusedCount + 1
                    end
                end
            end

            return "The scroll confuses " .. confusedCount .. " monsters, making them move randomly!"
        end
    },

    -- Regular Key
    ["Key"] = {
        type = "key",
        use = function(player, game)
            return "This key is used to unlock the exit door. Move next to the locked exit door and press 'E' to use it."
        end
    },

    -- Special Key
    ["Special Key"] = {
        type = "key",
        use = function(player, game)
            return "This special key is used to unlock mysterious doors. Move next to a special door and press 'E' to use it."
        end
    },

    -- Food (now can be saved in inventory)
    ["Food"] = {
        type = "food",
        use = function(player, game)
            local heal = math_random(2, 5)
            player.hp = math_min(player.maxHp, player.hp + heal)
            return "You eat some food and heal " .. heal .. " HP!"
        end
    }
}

local ITEM_APPEARANCE = {
    ["Gold"] = { char = "♦", color = { 1, 0.8, 0.2 } },
    ["Food"] = { char = "♠", color = { 0.9, 0.7, 0.3 } },
    ["Dagger"] = { char = "⚔", color = { 0.8, 0.8, 0.8 } },
    ["Leather Armor"] = { char = "⌺", color = { 0.6, 0.4, 0.2 } },
    ["Healing Potion"] = { char = "♣", color = { 1, 0.2, 0.2 } },
    ["Scroll"] = { char = "⁂", color = { 0.8, 0.8, 1 } },

    -- Enhanced weapons
    ["Iron Sword"] = { char = "⚔", color = { 0.9, 0.9, 0.9 } },
    ["Steel Sword"] = { char = "⚔", color = { 0.7, 0.7, 1 } },
    ["Magic Wand"] = { char = "⚔", color = { 0.8, 0.2, 0.8 } },

    -- Enhanced armor
    ["Chain Mail"] = { char = "⍝", color = { 0.7, 0.7, 0.7 } },
    ["Plate Armor"] = { char = "⍝", color = { 0.9, 0.9, 0.9 } },
    ["Magic Robe"] = { char = "⍝", color = { 0.3, 0.3, 0.8 } },

    -- Enhanced potions
    ["Greater Healing Potion"] = { char = "♣", color = { 1, 0.5, 0.5 } },
    ["Potion of Might"] = { char = "♣", color = { 0.5, 0.5, 1 } },
    ["Potion of Invulnerability"] = { char = "♣", color = { 0.2, 0.8, 0.2 } },
    ["Potion of Berserk"] = { char = "♣", color = { 1, 0.3, 0.3 } },

    -- Enhanced scrolls
    ["Scroll of Strength"] = { char = "⁂", color = { 1, 0.8, 0.8 } },
    ["Scroll of Protection"] = { char = "⁂", color = { 0.8, 0.8, 1 } },
    ["Scroll of Healing"] = { char = "⁂", color = { 0.8, 1, 0.8 } },
    ["Scroll of Teleportation"] = { char = "⁂", color = { 1, 0.8, 1 } },
    ["Scroll of Identify"] = { char = "⁂", color = { 1, 1, 0.8 } },
    ["Scroll of Monster Confusion"] = { char = "⁂", color = { 0.8, 0.5, 1 } },

    -- Keys
    ["Key"] = { char = "⚷", color = { 0.8, 0.8, 0.8 } },
    ["Special Key"] = { char = "⚷", color = { 1, 0.8, 0 } },
}

local function addTemporaryEffect(self, effectName, effect, player, currentTurn)
    self.activeEffects[effectName] = {
        effect = effect,
        appliedAt = currentTurn,
        expiresAt = currentTurn + effect.duration,
        originalStats = {
            attack = player.attack,
            defense = player.defense
        }
    }
end

function ItemManager.new()
    local instance = setmetatable({}, ItemManager)
    instance.activeEffects = {}
    return instance
end

function ItemManager:getBasicItemDefinitions() return BASIC_ITEMS end

function ItemManager:getItemDefinition(itemName) return ITEM_APPEARANCE[itemName] end

function ItemManager:useItem(itemName, player, game)
    local effect = ITEM_EFFECTS[itemName]

    if not effect then return "You can't use the " .. itemName .. " right now." end

    local result = effect.use(player, game)

    if effect.duration then addTemporaryEffect(self, itemName, effect, player, game.turn) end

    if game.sounds then
        if effect.type == "potion" then
            game.sounds:play("heal")
        elseif effect.type == "scroll" then
            game.sounds:play("unlock")
        elseif effect.type == "food" then
            game.sounds:play("heal")
        else
            game.sounds:play("pickup")
        end
    end

    return result
end

function ItemManager:updateEffects(player, currentTurn)
    local expiredEffects = {}

    for effectName, effectData in pairs(self.activeEffects) do
        if currentTurn >= effectData.expiresAt then
            -- Effect expired, revert changes
            local original = effectData.originalStats
            player.attack = original.attack
            player.defense = original.defense
            table_insert(expiredEffects, effectName)
        end
    end

    -- Remove expired effects
    for _, effectName in ipairs(expiredEffects) do
        self.activeEffects[effectName] = nil
    end

    return expiredEffects
end

function ItemManager:isEquipment(itemName)
    local effect = ITEM_EFFECTS[itemName]
    return effect and (effect.type == "weapon" or effect.type == "armor")
end

function ItemManager:isConsumable(itemName)
    local effect = ITEM_EFFECTS[itemName]
    return effect and (effect.type == "potion" or effect.type == "scroll" or effect.type == "food")
end

function ItemManager:getRandomEnhancedItem()
    local enhancedItems = {
        "Iron Sword", "Steel Sword", "Magic Wand",
        "Chain Mail", "Plate Armor", "Magic Robe",
        "Greater Healing Potion", "Potion of Might",
        "Potion of Invulnerability", "Potion of Berserk",
        "Scroll of Strength", "Scroll of Protection",
        "Scroll of Healing", "Scroll of Teleportation",
        "Scroll of Identify", "Scroll of Monster Confusion"
    }
    return enhancedItems[math_random(#enhancedItems)]
end

function ItemManager:getItemDescription(itemName)
    local effect = ITEM_EFFECTS[itemName]
    if not effect then return "A mysterious item of unknown purpose." end

    local descriptions = {
        weapon = "A weapon that increases your attack power when equipped.",
        armor = "Armor that increases your defense when equipped.",
        potion = "A consumable potion with magical effects.",
        scroll = "A magical scroll that can be read for powerful effects.",
        food = "Food that restores health when consumed.",
        key = "A special key that can unlock mysterious doors."
    }

    return descriptions[effect.type] or "A useful adventuring item."
end

return ItemManager
