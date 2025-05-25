
local M = {}

local onCompleteCallback = nil

function M.start(onComplete)
    onCompleteCallback = onComplete
    print("Battle starts!")
end

function M.update(dt)


    if onCompleteCallback then
        onCompleteCallback()
    end
end

function M.draw()
    love.graphics.print("BATTLE IN PROGRESS", 300, 300)
end

return M
