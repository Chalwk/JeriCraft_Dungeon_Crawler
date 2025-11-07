-- JeriCraft: Dungeon Crawler
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local FontManager = {}
FontManager.__index = FontManager

local font_path = "assets/fonts/segoe-ui-symbol.ttf"
local lg = love.graphics

function FontManager.new()
    local instance = setmetatable({}, FontManager)

    local success, font = pcall(function() return lg.newFont(font_path, 24) end)

    if success then
        instance.customFont = font
        instance.customFont:setFilter("nearest", "nearest")
        instance.fontCache = {}
        print("Font 'NotoColorEmoji-Regular.ttf loaded successfully")
    else
        print("Font 'NotoColorEmoji-Regular.ttf' not found, using fallback")
        instance.customFont = nil
        instance.fontCache = {}
    end

    return instance
end

function FontManager:getFont(size)
    -- Check cache first
    if self.fontCache[size] then return self.fontCache[size] end

    if self.customFont then
        -- Create new font at requested size and cache it
        local font = lg.newFont(font_path, size)
        font:setFilter("nearest", "nearest")
        self.fontCache[size] = font
        return font
    else
        -- Fallback to default font
        local font = lg.newFont(size)
        font:setFilter("nearest", "nearest")
        self.fontCache[size] = font
        return font
    end
end

function FontManager:getSmallFont()
    return self:getFont(14)
end

function FontManager:getMediumFont()
    return self:getFont(24)
end

function FontManager:getLargeFont()
    return self:getFont(48)
end

function FontManager:getSectionFont()
    return self:getFont(20)
end

function FontManager:getTitleFont()
    return self:getFont(64)
end

return FontManager