-- JeriCraft: Dungeon Crawler
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local ItemManager = {}
ItemManager.__index = ItemManager

local ipairs = ipairs
local pairs = pairs

local math_random = love.math.random
local math_min = math.min

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

    -- Scrolls
    ["Scroll of Strength"] = {
        type = "scroll",
        use = function(player, game)
            local bonus = math_random(2, 5)
            player.attack = player.attack + bonus
            return "You read the scroll of strength! Attack +" .. bonus .. " (temporary)"
        end,
        duration = 20 -- turns
    },
    ["Scroll of Protection"] = {
        type = "scroll",
        use = function(player, game)
            local bonus = math_random(2, 4)
            player.defense = player.defense + bonus
            return "You read the scroll of protection! Defense +" .. bonus .. " (temporary)"
        end,
        duration = 15 -- turns
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
            -- Find a random floor tile to teleport to
            local possiblePositions = {}
            for y = 1, #game.dungeon do
                for x = 1, #game.dungeon[y] do
                    local tile = game.dungeon[y][x]
                    if tile.type == "floor" and not game:isPositionBlocked(x, y) then
                        table.insert(possiblePositions, { x = x, y = y })
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

    -- Potions (enhanced versions)
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
    }
}

local ITEM_APPEARANCE = {
    -- Basic items
    ["Gold"] = { char = "♦", color = { 1, 0.8, 0.2 } },
    ["Food"] = { char = "♠", color = { 0.9, 0.7, 0.3 } },
    ["Dagger"] = { char = "⚔", color = { 0.8, 0.8, 0.8 } },
    ["Leather Armor"] = { char = "🛡", color = { 0.6, 0.4, 0.2 } },
    ["Healing Potion"] = { char = "♣", color = { 1, 0.2, 0.2 } },
    ["Scroll"] = { char = "⁂", color = { 0.8, 0.8, 1 } },
    ["Key"] = { char = "⚷", color = { 1, 1, 0 } },

    -- Enhanced items
    ["Iron Sword"] = { char = "⚔", color = { 0.9, 0.9, 0.9 } },
    ["Chain Mail"] = { char = "🛡", color = { 0.7, 0.7, 0.7 } },
    ["Greater Healing Potion"] = { char = "♣", color = { 1, 0.5, 0.5 } },
    ["Potion of Might"] = { char = "♣", color = { 0.5, 0.5, 1 } },
    ["Scroll of Strength"] = { char = "⁂", color = { 1, 0.8, 0.8 } },
    ["Scroll of Protection"] = { char = "⁂", color = { 0.8, 0.8, 1 } },
    ["Scroll of Healing"] = { char = "⁂", color = { 0.8, 1, 0.8 } },
    ["Scroll of Teleportation"] = { char = "⁂", color = { 1, 0.8, 1 } }
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

function ItemManager:getItemDefinition(itemName)
    return ITEM_APPEARANCE[itemName]
end

function ItemManager.new()
    local instance = setmetatable({}, ItemManager)
    instance.activeEffects = {}
    return instance
end

function ItemManager:useItem(itemName, player, game)
    local effect = ITEM_EFFECTS[itemName]

    if not effect then return "You can't use the " .. itemName .. " right now." end

    local result = effect.use(player, game)

    -- Handle temporary effects
    if effect.duration then
        addTemporaryEffect(self, itemName, effect, player, game.turn)
    end

    -- Play appropriate sound
    if game.sounds then
        if effect.type == "potion" then
            game.sounds:play("heal")
        elseif effect.type == "scroll" then
            game.sounds:play("unlock") -- Using unlock sound for scrolls
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
            table.insert(expiredEffects, effectName)
        end
    end

    -- Remove expired effects
    for _, effectName in ipairs(expiredEffects) do self.activeEffects[effectName] = nil end

    return expiredEffects
end

function ItemManager:isEquipment(itemName)
    local effect = ITEM_EFFECTS[itemName]
    return effect and (effect.type == "weapon" or effect.type == "armor")
end

function ItemManager:getRandomEnhancedItem()
    local enhancedItems = {
        "Iron Sword", "Chain Mail", "Greater Healing Potion",
        "Potion of Might", "Scroll of Strength", "Scroll of Protection",
        "Scroll of Healing", "Scroll of Teleportation"
    }
    return enhancedItems[math_random(#enhancedItems)]
end

return ItemManager
