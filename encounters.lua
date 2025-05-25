
local M = {}

local onCompleteCallback = nil

function M.start(onComplete)
    onCompleteCallback = onComplete
    print("NEW MONSTER ENCOUNTER!") 
end

function M.update(dt)


    if onCompleteCallback then
        onCompleteCallback()
    end
end

function M.draw()
    love.graphics.print("Do you wish to add this monster to your crew?", 300, 300)
end

return M
