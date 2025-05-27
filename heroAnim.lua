
local pinkHero = {}

local owlletHero = {}

local dudeHero = {}

pinkHero.frames = {}
owlletHero.frames = {}
dudeHero.frames = {}

pinkHero.totalFrames = 4
pinkHero.currentFrame = 1
pinkHero.timePerFrame = 0.2

for i = 1, pinkHero.totalFrames do
    local filename = string.format("sprites/heroSprites/1 Pink_Hero/Pink_Monster_Idle_4.png", i)
    table.insert(pinkHero.frames, love.graphics.newImage(filename))
end

function pinkHero.update(dt)
    pinkHero.timer = pinkHero.timer + dt
    if pinkHero.timer >= pinkHero.timePerFrame then
        pinkHero.timer = pinkHero.timer - pinkHero.timePerFrame
        pinkHero.currentFrame = pinkHero.currentFrame + 1
        if pinkHero.currentFrame > pinkHero.totalFrames then
            pinkHero.currentFrame = 1
        end
    end
end
function pinkHero.draw(x, y)
    love.graphics.draw(pinkHero.frames[pinkHero.currentFrame], x, y)
end

return pinkHero