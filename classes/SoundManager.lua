-- JeriCraft: Dungeon Crawler
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local SoundManager = {}
SoundManager.__index = SoundManager

function SoundManager.new()
    local instance = setmetatable({
        sounds = {
            walk = love.audio.newSource("assets/sounds/walk.mp3", "static"),
            attack = love.audio.newSource("assets/sounds/attack.mp3", "static"),
            monster_hit = love.audio.newSource("assets/sounds/monster_hit.mp3", "static"),
            player_hit = love.audio.newSource("assets/sounds/player_hit.mp3", "static"),
            pickup = love.audio.newSource("assets/sounds/pickup.mp3", "static"),
            level_up = love.audio.newSource("assets/sounds/level_up.mp3", "static"),
            bump = love.audio.newSource("assets/sounds/bump.mp3", "static"),
            next_level = love.audio.newSource("assets/sounds/next_level.mp3", "static"),
            heal = love.audio.newSource("assets/sounds/heal.mp3", "static"),
            unlock = love.audio.newSource("assets/sounds/unlock.mp3", "static"),
            locked = love.audio.newSource("assets/sounds/locked.mp3", "static"),
            ambience = love.audio.newSource("assets/sounds/ambience.mp3", "stream")
        }
    }, SoundManager)

    for name, sound in pairs(instance.sounds) do
        if name == "ambience" then
            sound:setVolume(1)
            sound:play(true)
        else
            sound:setVolume(0.5)
        end
    end
    return instance
end

function SoundManager:play(soundName, loop)
    if loop then self.sounds[soundName]:setLooping(true) end

    if not self.sounds[soundName] then return end

    self.sounds[soundName]:stop()
    self.sounds[soundName]:play()
end

function SoundManager:setVolume(sound, volume) sound:setVolume(volume) end

return SoundManager
