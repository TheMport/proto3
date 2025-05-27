local M = {}
local onCompleteCallback = nil

-- state management
local battleState = "intro"  -- intro, playerTurn, enemyTurn, victory, defeat
local battleTimer = 0
local messageTimer = 0
local currentMessage = ""
local messageQueue = {}
local animationTimer = 0

-- Sprite loaders ( needs updating )
local enemySprite = love.graphics.newImage("sprites/Forest_Monsters_FREE/Mushroom/Mushroom without VFX/Mushroom-Idle.png")
local heroSprite = love.graphics.newImage("sprites/heroSprites/1 Pink_Monster/Pink_Monster_Idle_4.png")

-- Will be altered to display different sprites later
local player = {
    name = "Pink Monster",
    hp = 100,
    maxHp = 100,
    level = 12,
    x = 150,
    y = 350,
    sprite = heroSprite,
    scale = 3,
    moves = {
        {name = "Tackle", power = 20, type = "Normal"},
        {name = "Quick Attack", power = 15, type = "Normal"},
        {name = "Thunder Shock", power = 25, type = "Electric"},
        {name = "Rest", power = 0, type = "Normal"}
    }
}

local enemy = {
    name = "Wild Mushroom",
    hp = 80,
    maxHp = 80,
    level = 10,
    x = 550,
    y = 200,
    sprite = enemySprite,
    scale = 3,
    moves = {
        {name = "Spore", power = 0, type = "Grass"},
        {name = "Tackle", power = 18, type = "Normal"},
        {name = "Poison Powder", power = 0, type = "Poison"},
        {name = "Headbutt", power = 22, type = "Normal"}
    }
}

-- UI
local selectedMove = 1
local showMoveMenu = false
local battleBackground = {r = 0.4, g = 0.7, b = 0.4}
local textBox = {x = 50, y = 450, width = 700, height = 120}

-- Battle effects
local damageNumbers = {}
local shakeTimer = 0
local shakeIntensity = 0

function M.start(onComplete)
    onCompleteCallback = onComplete
    battleState = "intro"
    battleTimer = 0
    messageTimer = 0
    currentMessage = ""
    messageQueue = {}
    
    -- Reset health
    player.hp = player.maxHp
    enemy.hp = enemy.maxHp
    

    addMessage("A wild " .. enemy.name .. " appeared!")
    addMessage("Go! " .. player.name .. "!")
    
    print("Pokemon-style battle starts!")
end

function addMessage(msg)
    table.insert(messageQueue, msg)
end

function processMessageQueue(dt)
    if #messageQueue > 0 and currentMessage == "" then
        currentMessage = messageQueue[1]
        table.remove(messageQueue, 1)
        messageTimer = 0
    end
    
    if currentMessage ~= "" then
        messageTimer = messageTimer + dt
        if messageTimer > 2.0 then  
            currentMessage = ""
            messageTimer = 0
            
            -- countinue battle state after intro 
            if battleState == "intro" and #messageQueue == 0 then
                battleState = "playerTurn"
                showMoveMenu = true
            elseif battleState == "enemyTurn" and #messageQueue == 0 then
                performEnemyTurn()
            elseif (battleState == "victory" or battleState == "defeat") and #messageQueue == 0 then
                if onCompleteCallback then
                    onCompleteCallback()
                end
            end
        end
    end
end

function performPlayerMove(moveIndex)
    local move = player.moves[moveIndex]
    showMoveMenu = false
    
    addMessage(player.name .. " used " .. move.name .. "!")
    
    if move.name == "Rest" then
        local healAmount = math.min(50, player.maxHp - player.hp)
        player.hp = player.hp + healAmount
        addMessage(player.name .. " restored " .. healAmount .. " HP!")
    else
        local damage = calculateDamage(move.power, player.level, enemy.level)
        enemy.hp = math.max(0, enemy.hp - damage)
        
        -- damage number effect
        table.insert(damageNumbers, {
            value = damage,
            x = enemy.x + 32,
            y = enemy.y,
            timer = 1.0,
            color = {1, 1, 1}
        })
        

        shakeTimer = 0.3
        shakeIntensity = 5
        
        if damage > 20 then
            addMessage("It's super effective!")
        elseif damage < 10 then
            addMessage("It's not very effective...")
        end
    end
    
    if enemy.hp <= 0 then
        battleState = "victory"
        addMessage(enemy.name .. " fainted!")
        addMessage(player.name .. " gained experience!")
        addMessage("You won the battle!")
    else
        battleState = "enemyTurn"
    end
end

function performEnemyTurn()
    local moveIndex = love.math.random(1, #enemy.moves)
    local move = enemy.moves[moveIndex]
    
    addMessage(enemy.name .. " used " .. move.name .. "!")
    
    if move.power > 0 then
        local damage = calculateDamage(move.power, enemy.level, player.level)
        player.hp = math.max(0, player.hp - damage)
        
        -- damage number effect
        table.insert(damageNumbers, {
            value = damage,
            x = player.x + 32,
            y = player.y,
            timer = 1.0,
            color = {1, 0.5, 0.5}
        })
        

        shakeTimer = 0.2
        shakeIntensity = 3
    else
        addMessage("But nothing happened...")
    end
    
    if player.hp <= 0 then
        battleState = "defeat"
        addMessage(player.name .. " fainted!")
        addMessage("You lost the battle!")
    else
        battleState = "playerTurn"
        showMoveMenu = true
    end
end

function calculateDamage(power, attackerLevel, defenderLevel)
    local baseDamage = (power * attackerLevel / defenderLevel) / 2
    local variance = love.math.random(0.8, 1.2)
    return math.floor(baseDamage * variance)
end

function M.update(dt)
    battleTimer = battleTimer + dt
    animationTimer = animationTimer + dt
    

    if shakeTimer > 0 then
        shakeTimer = shakeTimer - dt
    end
    
    -- damage #s
    for i = #damageNumbers, 1, -1 do
        local dmg = damageNumbers[i]
        dmg.timer = dmg.timer - dt
        dmg.y = dmg.y - 50 * dt  -- Float upward
        
        if dmg.timer <= 0 then
            table.remove(damageNumbers, i)
        end
    end
    
    processMessageQueue(dt)
end

function love.keypressed(key)
    if battleState == "playerTurn" and showMoveMenu then
        if key == "up" and selectedMove > 1 then
            selectedMove = selectedMove - 1
        elseif key == "down" and selectedMove < #player.moves then
            selectedMove = selectedMove + 1
        elseif key == "return" or key == "space" then
            performPlayerMove(selectedMove)
        end
    elseif currentMessage ~= "" then
        if key == "return" or key == "space" then
            -- Skip message display
            currentMessage = ""
            messageTimer = 0
        end
    end
end

function drawHealthBar(x, y, width, height, currentHp, maxHp, isPlayer)
    -- Background
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Health bar
    local hpPercent = currentHp / maxHp
    local barColor = {0.2, 0.8, 0.2}  -- Green
    if hpPercent < 0.5 then
        barColor = {1, 1, 0}  -- Yellow
    end
    if hpPercent < 0.2 then
        barColor = {1, 0.2, 0.2}  -- Red
    end
    
    love.graphics.setColor(barColor)
    love.graphics.rectangle("fill", x, y, width * hpPercent, height)
    
    -- Border
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- HP text
    local name = isPlayer and player.name or enemy.name
    local level = isPlayer and player.level or enemy.level
    love.graphics.print(name .. " Lv." .. level, x, y - 25)
    love.graphics.print("HP: " .. currentHp .. "/" .. maxHp, x, y + height + 5)
end

function drawMoveMenu()
    if not showMoveMenu then return end
    
    local menuX, menuY = 450, 300
    local menuWidth, menuHeight = 300, 200
    
    -- Menu background
    love.graphics.setColor(0.1, 0.1, 0.3, 0.9)
    love.graphics.rectangle("fill", menuX, menuY, menuWidth, menuHeight)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", menuX, menuY, menuWidth, menuHeight)
    
    -- Title
    love.graphics.print("Choose a move:", menuX + 10, menuY + 10)
    
    -- Moves
    for i, move in ipairs(player.moves) do
        local y = menuY + 40 + (i - 1) * 30
        local color = (i == selectedMove) and {1, 1, 0} or {1, 1, 1}
        love.graphics.setColor(color)
        
        local prefix = (i == selectedMove) and "> " or "  "
        love.graphics.print(prefix .. move.name .. " (Power: " .. move.power .. ")", menuX + 10, y)
    end
end


    -- will implement this box to other scenes later
function drawTextBox()
    -- Text box background
    love.graphics.setColor(0.1, 0.1, 0.3, 0.9)
    love.graphics.rectangle("fill", textBox.x, textBox.y, textBox.width, textBox.height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", textBox.x, textBox.y, textBox.width, textBox.height)
    
    -- Current message
    if currentMessage ~= "" then
        love.graphics.print(currentMessage, textBox.x + 20, textBox.y + 20)
        
        -- Blinker indicator
        if math.floor(messageTimer * 3) % 2 == 0 then
            love.graphics.print("▼", textBox.x + textBox.width - 40, textBox.y + textBox.height - 40)
        end
    end
end

function M.draw()

    local shakeX, shakeY = 0, 0
    if shakeTimer > 0 then
        shakeX = (love.math.random() - 0.5) * shakeIntensity
        shakeY = (love.math.random() - 0.5) * shakeIntensity
    end
    
    love.graphics.push()
    love.graphics.translate(shakeX, shakeY)
    
    -- Battle background
    love.graphics.setColor(battleBackground.r, battleBackground.g, battleBackground.b)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Ground/platform effects
    love.graphics.setColor(0.3, 0.5, 0.3)
    love.graphics.rectangle("fill", 0, 400, love.graphics.getWidth(), 200)
    love.graphics.setColor(0.6, 0.4, 0.2)
    love.graphics.rectangle("fill", 0, 250, love.graphics.getWidth(), 150)
    
    -- sprites
    if player.hp > 0 then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(player.sprite, player.x, player.y, 0, player.scale, player.scale)
    end
    
    if enemy.hp > 0 then
        love.graphics.setColor(1, 1, 1)
        -- flip enemy sprite horizontally
        love.graphics.draw(enemy.sprite, enemy.x + enemy.sprite:getWidth() * enemy.scale, enemy.y, 0, -enemy.scale, enemy.scale)
    end
    
    -- health bars
    love.graphics.setColor(1, 1, 1)
    drawHealthBar(50, 50, 200, 20, player.hp, player.maxHp, true)   -- Player health (top-left)
    drawHealthBar(550, 150, 200, 20, enemy.hp, enemy.maxHp, false)  -- Enemy health (top-right)
    
    -- damage numbers
    for _, dmg in ipairs(damageNumbers) do
        love.graphics.setColor(dmg.color)
        love.graphics.print("-" .. dmg.value, dmg.x, dmg.y)
    end
    
    love.graphics.pop()
    
    -- UI
    love.graphics.setColor(1, 1, 1)
    drawTextBox()
    drawMoveMenu()
    
    -- Debugger
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Battle State: " .. battleState, 10, 10)
    love.graphics.print("Use ARROW KEYS + ENTER to select moves", 10, love.graphics.getHeight() - 60)
    love.graphics.print("Press ENTER/SPACE to continue text", 10, love.graphics.getHeight() - 40)
end

return M