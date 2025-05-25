

local chest = {}

chest.frames = {}
chest.totalFrames = 9
chest.currentFrame = 1
chest.timePerFrame = 0.2
chest.timer = 0


-- Loads each image from .png files
for i = 1, chest.totalFrames do
    local filename = string.format("sprites/Chest/Open/NoDust/OpenChest%d.png", i)
    table.insert(chest.frames, love.graphics.newImage(filename))
end

function chest.update(dt)
    chest.timer = chest.timer + dt
    if chest.timer >= chest.timePerFrame then
        chest.timer = chest.timer - chest.timePerFrame
        chest.currentFrame = chest.currentFrame + 1
        if chest.currentFrame > chest.totalFrames then
            chest.currentFrame = chest.totalFrames
        end
    end
end

function chest.draw(x, y)
    love.graphics.draw(chest.frames[chest.currentFrame], x, y)
end


function chest.isFinished()
    return chest.currentFrame == chest.totalFrames
end

function chest.reset()
    chest.currentFrame = 1
    chest.timer = 0
end


return chest

