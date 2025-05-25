
local M = {}

local onCompleteCallback = nil

function M.start(onComplete)
    onCompleteCallback = onComplete
    print("Looks like your worst nightmare...") 
end

function M.update(dt)


    if onCompleteCallback then
        onCompleteCallback()
    end
end

function M.draw()
    love.graphics.print("Select one of your dream monsters to send to the void", 300, 300)
end

return M
