
local M = {}

local onCompleteCallback = nil

function M.start(onComplete)
    onCompleteCallback = onComplete
    print("Upgrade Avaliable!") 
end

function M.update(dt)


    if onCompleteCallback then
        onCompleteCallback()
    end
end

function M.draw()
    love.graphics.print("PLEASE SELECT UPGRADE", 300, 300)
end

return M
