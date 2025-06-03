

-- import modules
local chestAnimation = require("chestAnim")

local rngRedirect = {
    "encounters",   -- will be when you can add a monster to your crew
    "misfortune",   --  you need to remove a monster from your crew
    "battle"    -- will be when you can battle an enemy
}

local gameState = "map"
local nextModule = nil
local chestTimer = 0
local currentModule = nil
local animatingChest = nil

-- Window Settings
SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600

-- player (temp)
local player = { x = SCREEN_WIDTH/2, y = SCREEN_HEIGHT/2, size = 32, speed = 200 }

-- camera 
local cam = { x = 0, y = 0 }

-- rng spawn multiple chests
local chests = {}
local chestImage = love.graphics.newImage("sprites/Chest/Chest.png")

function spawnChests(count)
    for i = 1, count do
        table.insert(chests, {
            image = chestImage,
            x = love.math.random(0, SCREEN_WIDTH),
            y = love.math.random(0, SCREEN_HEIGHT),
            width = 64,
            height = 64,
            opened = false
        })
    end
end

function love.load()
    spawnChests(20)
    love.window.setTitle("Hidden Fates")
    love.graphics.setBackgroundColor(0.5, 0.5, 0.5)
    love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT, { resizable = true, vsync = true })
    love.mouse.setVisible(true)
end

function isChestClicked(x, y)
    for i, chest in ipairs(chests) do
        if not chest.opened and
           x > chest.x - cam.x and x < chest.x - cam.x + chest.width and
           y > chest.y - cam.y and y < chest.y - cam.y + chest.height then
            return i
        end
    end
    return nil
end

function love.mousepressed(x, y, button)
    if button == 2 and gameState == "map" then
        player.targetX = x + cam.x
        player.targetY = y + cam.y
    elseif button == 1 and gameState == "map" then
        local chestIndex = isChestClicked(x, y)
        if chestIndex then
            chests[chestIndex].opened = true
            animatingChest = chests[chestIndex]
            nextModule = rngRedirect[love.math.random(1, #rngRedirect)]
            gameState = "chestAnimation"
            chestTimer = 0
            chestAnimation.reset()  
            print("Chest clicked! Redirecting to: " .. nextModule)
        end
    end
end

function love.keypressed(key)
    if gameState == "module" and currentModule and currentModule.keypressed then
        currentModule.keypressed(key)
    end
end

function love.update(dt)
    -- Move player
    if player.targetX and player.targetY then
        local dx = player.targetX - player.x
        local dy = player.targetY - player.y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist > 1 then
            local dirX = dx / dist
            local dirY = dy / dist
            player.x = player.x + dirX * player.speed * dt
            player.y = player.y + dirY * player.speed * dt
        end
    end

    -- Camera follows player
    -- cam.x = player.x - love.graphics.getWidth() / 2
    -- cam.y = player.y - love.graphics.getHeight() / 2

    if gameState == "chestAnimation" then
        chestAnimation.update(dt)
        if chestAnimation.isFinished() then
            currentModule = require(nextModule)
            if currentModule and currentModule.start then
                package.loaded[nextModule] = nil
                currentModule = require(nextModule)

                currentModule.start(onModuleComplete)
            end
            gameState = "module"
        end
    elseif gameState == "module" and currentModule and currentModule.update then
        currentModule.update(dt)
    end
end

function love.draw()
    love.graphics.push()
    love.graphics.translate(-cam.x, -cam.y)

    if gameState == "map" then
        -- Draw player(temp)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", player.x, player.y, player.size, player.size)

        -- spawn rng chests
        for _, chest in ipairs(chests) do
            if not chest.opened then
                love.graphics.draw(chest.image, chest.x, chest.y)
            end
        end
    elseif gameState == "chestAnimation" and animatingChest then
        chestAnimation.draw(animatingChest.x, animatingChest.y)
    elseif gameState == "module" and currentModule and currentModule.draw then
        currentModule.draw()
    end

    love.graphics.pop()
end

function onModuleComplete()
    currentModule = nil
    nextModule = nil
    animatingChest = nil
    gameState = "map"
end
