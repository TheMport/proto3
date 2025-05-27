
local myMonsters = require("myMonsters")

local M = {}

local monsters = {}
local selectedIndex = 1
local onCompleteCallback = nil

function M.start(onComplete)
    onCompleteCallback = onComplete
    selectedIndex = 1
    monsters = {}  
    monsters = myMonsters.getMonsters()
end


function M.update(dt)
    if #monsters == 0 then
        if love.keyboard.isDown("return") and onCompleteCallback then
            onCompleteCallback()
        end
        return
    end

    if love.keyboard.isDown("left") and selectedIndex > 1 then
        selectedIndex = selectedIndex - 1
    elseif love.keyboard.isDown("right") and selectedIndex < #monsters then
        selectedIndex = selectedIndex + 1
    end

    if love.keyboard.isDown("return") then
        local removed = myMonsters.removeMonster(selectedIndex)
        if removed then
            print("Removed monster at index " .. selectedIndex)
        end
        if onCompleteCallback then
            onCompleteCallback()
        end
    end
end

function M.draw()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    if #monsters == 0 then
        love.graphics.printf("Misfortune! But you have no monsters to lose.", 0, screenH / 2 - 20, screenW, "center")
        love.graphics.printf("Press Enter to continue.", 0, screenH / 2 + 10, screenW, "center")
        return
    end

    -- preload images 
    local images = {}
    local imgW, imgH = 0, 0

    for i, m in ipairs(monsters) do
        local image = love.graphics.newImage(m.spritePath)
        images[i] = image
        imgW = image:getWidth() * 2
        imgH = image:getHeight() * 2
    end

    local spacing = 150
    local totalWidth = (#monsters - 1) * spacing
    local startX = (screenW - totalWidth) / 2

    -- center message
    local messageY = screenH / 2 - imgH / 2 - 40
    love.graphics.printf("Misfortune! Choose one monster to lose.", 0, messageY, screenW, "center")

    for i, m in ipairs(monsters) do
        local x = startX + (i - 1) * spacing
        local y = screenH / 2 - imgH / 2
        local image = images[i]

        love.graphics.draw(image, x, y, 0, 2, 2)

        if i == selectedIndex then
            love.graphics.setColor(1, 0, 0)
            love.graphics.rectangle("line", x - 10, y - 10, imgW + 20, imgH + 20)
            love.graphics.setColor(1, 1, 1)
        end

        love.graphics.printf(m.name, x - 25, y + imgH + 10, spacing, "center")
    end
end



return M
