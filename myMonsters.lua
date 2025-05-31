local M = {}

local maxMonsters = 3
local monsters = {}

-- Base stats for each monster type
local monsterTemplates = {
    ["Pink Monster"] = {
        baseHp = 30,
        baseAttack = 10,
        baseDefense = 8,
        baseSpeed = 12,
        moves = {
            {name = "Tackle", power = 20, type = "Normal", pp = 15},
            {name = "Growl", power = 0, type = "Normal", pp = 20, effect = "lowerAttack"}
        },
        type = "Normal"
    },
    ["Owlet Monster"] = {
        baseHp = 25,
        baseAttack = 12,
        baseDefense = 6,
        baseSpeed = 15,
        moves = {
            {name = "Peck", power = 25, type = "Flying", pp = 15},
            {name = "Sand Attack", power = 0, type = "Ground", pp = 20, effect = "lowerAccuracy"}
        },
        type = "Flying"
    },
    ["Dude Monster"] = {
        baseHp = 35,
        baseAttack = 8,
        baseDefense = 12,
        baseSpeed = 8,
        moves = {
            {name = "Punch", power = 18, type = "Fighting", pp = 20},
            {name = "Defense Curl", power = 0, type = "Normal", pp = 15, effect = "raiseDefense"}
        },
        type = "Fighting"
    }
}

function M.addMonster(monsterData)
    if #monsters >= maxMonsters then return false end
    
    local template = monsterTemplates[monsterData.name]
    if not template then return false end
    
    local monster = {
        name = monsterData.name,
        spritePath = monsterData.spritePath, -- Use the provided sprite path
        level = 5, -- Starting level
        hp = template.baseHp,
        maxHp = template.baseHp,
        attack = template.baseAttack,
        defense = template.baseDefense,
        speed = template.baseSpeed,
        moves = {},
        type = template.type,
        xp = 0,
        nextLevelXp = 100
    }
    
    -- Copy moves
    for _, move in ipairs(template.moves) do
        table.insert(monster.moves, {
            name = move.name,
            power = move.power,
            type = move.type,
            maxPp = move.pp,
            pp = move.pp,
            effect = move.effect
        })
    end
    
    table.insert(monsters, monster)
    return true
end

function M.getMonsters()
    return monsters
end

function M.getMonster(index)
    return monsters[index]
end

function M.isFull()
    return #monsters >= maxMonsters
end

function M.removeMonster(index)
    if monsters[index] then
        table.remove(monsters, index)
        return true
    else
        return false
    end
end

function M.clear()
    monsters = {}
end

return M
