local M = {}
local myMonsters = require("myMonsters")

local onCompleteCallback = nil
local battleState = "intro"  -- intro, playerTurn, enemyTurn, victory, defeat
local battleTimer = 0
local messageTimer = 0
local currentMessage = ""
local messageQueue = {}
local animationTimer = 0

-- Battle participants
local playerTeam = {}
local currentPlayerMonster = nil
local enemy = nil
local selectedMove = 1
local showMoveMenu = false

-- UI elements
local battleBackground = {r = 0.4, g = 0.7, b = 0.4}
local textBox = {x = 50, y = 450, width = 700, height = 120}
local damageNumbers = {}
local shakeTimer = 0
local shakeIntensity = 0

-- Type effectiveness chart
local typeChart = {
    Normal = {Rock = 0.5, Ghost = 0},
    Fighting = {Normal = 2, Rock = 2, Flying = 0.5, Poison = 0.5},
    Flying = {Fighting = 2, Grass = 2, Bug = 2, Rock = 0.5},
    Poison = {Grass = 2, Poison = 0.5, Ground = 0.5},
    Ground = {Poison = 2, Rock = 2, Electric = 2, Grass = 0.5},
    Rock = {Flying = 2, Bug = 2, Fire = 2, Fighting = 0.5, Ground = 0.5},
    Bug = {Grass = 2, Poison = 2, Flying = 0.5, Fire = 0.5},
    Ghost = {Ghost = 2, Psychic = 0},
    Fire = {Grass = 2, Bug = 2, Ice = 2, Fire = 0.5, Water = 0.5, Rock = 0.5},
    Water = {Fire = 2, Ground = 2, Rock = 2, Water = 0.5, Grass = 0.5},
    Grass = {Water = 2, Ground = 2, Rock = 2, Fire = 0.5, Grass = 0.5, Flying = 0.5, Bug = 0.5},
    Electric = {Water = 2, Flying = 2, Ground = 0, Electric = 0.5},
    Psychic = {Fighting = 2, Poison = 2, Psychic = 0.5},
    Ice = {Flying = 2, Ground = 2, Grass = 2, Fire = 0.5, Water = 0.5, Ice = 0.5},
    Dragon = {Dragon = 2}
}

function M.start(onComplete)
    onCompleteCallback = onComplete
    battleState = "intro"
    battleTimer = 0
    messageTimer = 0
    currentMessage = ""
    messageQueue = {}
    
    -- Initialize enemy first to prevent nil access
    enemy = {
        name = "Wild Mushroom",
        hp = 80,
        maxHp = 80,
        attack = 12,
        defense = 10,
        speed = 8,
        level = 10,
        x = 550,
        y = 200,
        sprite = love.graphics.newImage("sprites/Forest_Monsters_FREE/Mushroom/Mushroom without VFX/Mushroom-Idle.png"),
        scale = 3,
        moves = {
            {name = "Spore", power = 0, type = "Grass", pp = 10},
            {name = "Tackle", power = 18, type = "Normal", pp = 15},
            {name = "Poison Powder", power = 0, type = "Poison", pp = 10},
            {name = "Headbutt", power = 22, type = "Normal", pp = 10}
        },
        type = "Grass"
    }
    
    -- Setup player team
    playerTeam = myMonsters.getMonsters()
    if #playerTeam == 0 then
        addMessage("You have no monsters to battle with!")
        battleState = "defeat"
        return
    end
    
    -- Find first alive monster
    currentPlayerMonster = nil
    for _, monster in ipairs(playerTeam) do
        if monster.hp > 0 then
            currentPlayerMonster = monster
            break
        end
    end
    
    if not currentPlayerMonster then
        addMessage("All your monsters have fainted!")
        battleState = "defeat"
        return
    end
    
    -- Initialize battle position properties
    currentPlayerMonster.x = 150
    currentPlayerMonster.y = 350
    currentPlayerMonster.scale = 3
    
    addMessage("A wild " .. enemy.name .. " appeared!")
    addMessage("Go! " .. currentPlayerMonster.name .. "!")
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
    local move = currentPlayerMonster.moves[moveIndex]
    if move.pp <= 0 then
        addMessage("No PP left for this move!")
        return
    end
    
    showMoveMenu = false
    move.pp = move.pp - 1
    
    addMessage(currentPlayerMonster.name .. " used " .. move.name .. "!")
    
    if move.power > 0 then
        local damage = calculateDamage(
            move.power, 
            currentPlayerMonster.attack, 
            enemy.defense, 
            currentPlayerMonster.level, 
            enemy.level,
            move.type,
            enemy.type
        )
        
        enemy.hp = math.max(0, enemy.hp - damage)
        
        table.insert(damageNumbers, {
            value = damage,
            x = enemy.x + 32,
            y = enemy.y,
            timer = 1.0,
            color = {1, 1, 1}
        })
        
        shakeTimer = 0.3
        shakeIntensity = 5
        
        if damage > move.power * 1.5 then
            addMessage("It's super effective!")
        elseif damage < move.power * 0.5 then
            addMessage("It's not very effective...")
        end
    elseif move.effect then
        -- Handle status effects here
        addMessage("It had an effect!")
    end
    
    if enemy.hp <= 0 then
        battleState = "victory"
        addMessage(enemy.name .. " fainted!")
        awardXP()
        addMessage(currentPlayerMonster.name .. " gained " .. calculateXP() .. " XP!")
        checkLevelUp()
        addMessage("You won the battle!")
    else
        battleState = "enemyTurn"
    end
end

function calculateDamage(power, attack, defense, attackerLevel, defenderLevel, moveType, enemyType)
    -- Calculate type effectiveness
    local effectiveness = 1
    if typeChart[moveType] and typeChart[moveType][enemyType] then
        effectiveness = typeChart[moveType][enemyType]
    end
    
    local baseDamage = (((2 * attackerLevel / 5 + 2) * power * (attack / defense)) / 50 + 2)
    local variance = love.math.random(0.85, 1.0)
    return math.floor(baseDamage * variance * effectiveness)
end

function calculateXP()
    return math.floor(enemy.level * 10 / currentPlayerMonster.level)
end

function awardXP()
    currentPlayerMonster.xp = currentPlayerMonster.xp + calculateXP()
end

function checkLevelUp()
    if currentPlayerMonster.xp >= currentPlayerMonster.nextLevelXp then
        currentPlayerMonster.level = currentPlayerMonster.level + 1
        currentPlayerMonster.xp = currentPlayerMonster.xp - currentPlayerMonster.nextLevelXp
        currentPlayerMonster.nextLevelXp = math.floor(currentPlayerMonster.nextLevelXp * 1.2)
        
        -- Increase stats
        currentPlayerMonster.maxHp = currentPlayerMonster.maxHp + 5
        currentPlayerMonster.hp = currentPlayerMonster.maxHp
        currentPlayerMonster.attack = currentPlayerMonster.attack + 2
        currentPlayerMonster.defense = currentPlayerMonster.defense + 2
        currentPlayerMonster.speed = currentPlayerMonster.speed + 1
        
        addMessage(currentPlayerMonster.name .. " grew to level " .. currentPlayerMonster.level .. "!")
    end
end

function performEnemyTurn()
    local availableMoves = {}
    for _, move in ipairs(enemy.moves) do
        if move.pp > 0 then
            table.insert(availableMoves, move)
        end
    end
    
    if #availableMoves == 0 then
        addMessage(enemy.name .. " has no moves left!")
        battleState = "playerTurn"
        showMoveMenu = true
        return
    end
    
    local moveIndex = love.math.random(1, #availableMoves)
    local move = availableMoves[moveIndex]
    move.pp = move.pp - 1
    
    addMessage(enemy.name .. " used " .. move.name .. "!")
    
    if move.power > 0 then
        local damage = calculateDamage(
            move.power, 
            enemy.attack, 
            currentPlayerMonster.defense, 
            enemy.level, 
            currentPlayerMonster.level,
            move.type,
            currentPlayerMonster.type
        )
        
        currentPlayerMonster.hp = math.max(0, currentPlayerMonster.hp - damage)
        
        table.insert(damageNumbers, {
            value = damage,
            x = currentPlayerMonster.x + 32,  
            y = currentPlayerMonster.y,       
            timer = 1.0,
            color = {1, 0.5, 0.5}
        })
        
        shakeTimer = 0.2
        shakeIntensity = 3
        
        if damage > move.power * 1.5 then
            addMessage("It's super effective!")
        elseif damage < move.power * 0.5 then
            addMessage("It's not very effective...")
        end
    else
        addMessage("But nothing happened...")
    end
    
    if currentPlayerMonster.hp <= 0 then
        addMessage(currentPlayerMonster.name .. " fainted!")
        -- Find next alive monster
        local nextMonster = nil
        for _, monster in ipairs(playerTeam) do
            if monster.hp > 0 then
                nextMonster = monster
                break
            end
        end
        
        if nextMonster then
            currentPlayerMonster = nextMonster
            -- Initialize position for new monster
            currentPlayerMonster.x = 150
            currentPlayerMonster.y = 350
            currentPlayerMonster.scale = 3
            
            addMessage("Go! " .. currentPlayerMonster.name .. "!")
            battleState = "playerTurn"
            showMoveMenu = true
        else
            battleState = "defeat"
            addMessage("All your monsters have fainted!")
            addMessage("You lost the battle!")
        end
    else
        battleState = "playerTurn"
        showMoveMenu = true
    end
end

function M.update(dt)
    battleTimer = battleTimer + dt
    animationTimer = animationTimer + dt
    
    if shakeTimer > 0 then
        shakeTimer = shakeTimer - dt
    end
    
    -- Update damage numbers
    for i = #damageNumbers, 1, -1 do
        local dmg = damageNumbers[i]
        dmg.timer = dmg.timer - dt
        dmg.y = dmg.y - 50 * dt
        
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
        elseif key == "down" and selectedMove < #currentPlayerMonster.moves then
            selectedMove = selectedMove + 1
        elseif key == "return" or key == "space" then
            performPlayerMove(selectedMove)
        end
    elseif currentMessage ~= "" then
        if key == "return" or key == "space" then
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
    local name = isPlayer and currentPlayerMonster.name or enemy.name
    local level = isPlayer and currentPlayerMonster.level or enemy.level
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
    
    -- Moves with PP
    for i, move in ipairs(currentPlayerMonster.moves) do
        local y = menuY + 40 + (i - 1) * 30
        local color = (i == selectedMove) and {1, 1, 0} or {1, 1, 1}
        love.graphics.setColor(color)
        
        local prefix = (i == selectedMove) and "> " or "  "
        love.graphics.print(prefix .. move.name .. " (PP: " .. move.pp .. "/" .. move.maxPp .. ")", menuX + 10, y)
    end
end

function drawTextBox()
    love.graphics.setColor(0.1, 0.1, 0.3, 0.9)
    love.graphics.rectangle("fill", textBox.x, textBox.y, textBox.width, textBox.height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", textBox.x, textBox.y, textBox.width, textBox.height)
    
    if currentMessage ~= "" then
        love.graphics.print(currentMessage, textBox.x + 20, textBox.y + 20)
        
        if math.floor(messageTimer * 3) % 2 == 0 then
            love.graphics.print("▼", textBox.x + textBox.width - 40, textBox.y + textBox.height - 40)
        end
    end
end

function M.draw()

    if not enemy then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Battle loading...", 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center")
        return
    end

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
    
    -- Ground/platform
    love.graphics.setColor(0.3, 0.5, 0.3)
    love.graphics.rectangle("fill", 0, 400, love.graphics.getWidth(), 200)
    love.graphics.setColor(0.6, 0.4, 0.2)
    love.graphics.rectangle("fill", 0, 250, love.graphics.getWidth(), 150)
    
    -- Player monster
    if currentPlayerMonster and currentPlayerMonster.hp > 0 then
        local img = love.graphics.newImage(currentPlayerMonster.spritePath)
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(img, 150, 350, 0, 3, 3)
    end
    
    -- Enemy
    if enemy and enemy.hp > 0 then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(enemy.sprite, enemy.x + enemy.sprite:getWidth() * enemy.scale, enemy.y, 0, -enemy.scale, enemy.scale)
    end
    
    -- Health bars
    if currentPlayerMonster then
        drawHealthBar(50, 50, 200, 20, currentPlayerMonster.hp, currentPlayerMonster.maxHp, true)
    end
    if enemy then
        drawHealthBar(550, 150, 200, 20, enemy.hp, enemy.maxHp, false)
    end
    
    -- Damage numbers
    for _, dmg in ipairs(damageNumbers) do
        love.graphics.setColor(dmg.color)
        love.graphics.print("-" .. dmg.value, dmg.x, dmg.y)
    end
    
    love.graphics.pop()
    
    -- UI
    love.graphics.setColor(1, 1, 1)
    drawTextBox()
    drawMoveMenu()
    
    -- Debug info
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Battle State: " .. battleState, 10, 10)
    love.graphics.print("Use ARROW KEYS + ENTER to select moves", 10, love.graphics.getHeight() - 60)
    love.graphics.print("Press ENTER/SPACE to continue text", 10, love.graphics.getHeight() - 40)
end

return M