-- JeriCraft: Dungeon Crawler
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local font_path = "assets/fonts/segoe-ui-symbol.ttf"
local lg = love.graphics

local FontManager = {}
FontManager.__index = FontManager

local fonts = {
    smallFont = 14,
    mediumFont = 24,
    largeFont = 48,
    sectionFont = 20,
    listFont = 18,
}

function FontManager.new()
    local instance = setmetatable({}, FontManager)

    instance.fonts = {}
    instance.dynamicFonts = {}

    for name, size in pairs(fonts) do
        local success, font = pcall(function() return lg.newFont(font_path, size) end)

        if success and font then
            instance.fonts[name] = font
            instance.fonts[name]:setFilter("nearest", "nearest")
        else
            error("Failed to load font '" .. name .. "' with size " .. size .. ", using fallback")
        end
    end

    return instance
end

function FontManager:getFontOfSize(size)
    -- Check if we already have this size cached
    if self.dynamicFonts[size] then return self.dynamicFonts[size] end

    -- Create new font of the specified size
    local success, font = pcall(function() return lg.newFont(font_path, size) end)

    if success and font then
        font:setFilter("nearest", "nearest")
        self.dynamicFonts[size] = font
        return font
    else
        -- Fallback to medium font if creation fails
        print("Warning: Failed to create font of size " .. size .. ", using medium font")
        return self.fonts.mediumFont
    end
end

function FontManager:setFont(fontOrName)
    if type(fontOrName) == "string" then
        lg.setFont(self.fonts[fontOrName])
    elseif type(fontOrName) == "userdata" and fontOrName.setFilter then
        lg.setFont(fontOrName)
    end
end

function FontManager:getFont(name) return self.fonts[name] end

return FontManager
