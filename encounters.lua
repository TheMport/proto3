local myMonsters = require("myMonsters")

local M = {}

local heroes = {
    {
        name = "Pink Monster",
        folder = "1 Pink_Monster",
        file = "Pink_Monster.png"
    },
    {
        name = "Owlet Monster",
        folder = "2 Owlet_Monster",
        file = "Owlet_Monster.png"
    },
    {
        name = "Dude Monster",
        folder = "3 Dude_Monster",
        file = "Dude_Monster.png"
    }
}

local selectedHero = nil
local heroImage = nil
local choiceIndex = 1 -- 1 = Yes, 2 = No
local onCompleteCallback = nil

function M.start(onComplete)
    onCompleteCallback = onComplete
    choiceIndex = 1
    selectedHero = nil
    heroImage = nil

    local hero = heroes[love.math.random(1, #heroes)]
    selectedHero = {
        name = hero.name,
        folder = hero.folder,
        file = hero.file,
        spritePath = "sprites/heroSprites/" .. hero.folder .. "/" .. hero.file
    }

    heroImage = love.graphics.newImage(selectedHero.spritePath)
end

function M.update(dt)
    if love.keyboard.isDown("left") then
        choiceIndex = 1
    elseif love.keyboard.isDown("right") then
        choiceIndex = 2
    end

    if love.keyboard.isDown("return") then
        if choiceIndex == 1 then -- Yes
            if not myMonsters.isFull() then
                -- Pass the complete monster data including sprite path
                if myMonsters.addMonster({
                    name = selectedHero.name,
                    spritePath = selectedHero.spritePath
                }) then
                    print(selectedHero.name .. " added to your crew!")
                else
                    print("Failed to add monster")
                end
            else
                print("Crew is full! Cannot add " .. selectedHero.name)
            end
        else
            print("You chose not to add the monster.")
        end

        if onCompleteCallback then
            onCompleteCallback()
        end
    end
end

function M.draw()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    if not selectedHero or not heroImage then
        love.graphics.printf("Loading encounter...", 0, screenH / 2, screenW, "center")
        return
    end

    -- Image size and center
    local scale = 2
    local imgW, imgH = heroImage:getWidth() * scale, heroImage:getHeight() * scale
    local centerX = screenW / 2
    local centerY = screenH / 2

    -- Layout vertical spacing
    local spacing = 30
    local imgY = centerY - imgH / 2
    local textY = imgY - spacing * 1.5
    local optionY = imgY + imgH + spacing

    -- Draw monster image centered
    love.graphics.draw(heroImage, centerX - imgW / 2, imgY, 0, scale, scale)

    -- Title above monster
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(
        "You found a wild " .. selectedHero.name .. "! Add to your crew?",
        0, textY, screenW, "center"
    )

    -- YES / NO options centered below monster
    local yesColor = choiceIndex == 1 and {1, 1, 0} or {1, 1, 1}
    local noColor = choiceIndex == 2 and {1, 1, 0} or {1, 1, 1}

    love.graphics.setColor(yesColor)
    love.graphics.printf("YES", -100, optionY, screenW, "center")

    love.graphics.setColor(noColor)
    love.graphics.printf("NO", 100, optionY, screenW, "center")

    -- Team status
    if myMonsters.isFull() then
        love.graphics.setColor(1, 0.5, 0.5)
        love.graphics.printf("Your team is full!", 0, optionY + 40, screenW, "center")
    end

    love.graphics.setColor(1, 1, 1)
end

return M