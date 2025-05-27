
-- needs updating 
local M = {}

local maxMonsters = 3
local monsters = {}

function M.addMonster(monster)
    if #monsters < maxMonsters then
        table.insert(monsters, monster)
        return true
    else
        return false
    end
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
