local term = require("term")
local event = require("event")

-------------------------------

local gpu = term.gpu()
local rx, ry = gpu.getResolution()

-------------------------------

local level = {}

for cx = 1, rx do
    level[cx] = {}
    for cy = 1, ry do
        level[cx][cy] = false
    end
end

local function getState(states, x, y)
    local thisState = false
    if x > 1 and x <= rx and y > 1 and y <= ry then
        thisState = states[x][y]
    end
    return thisState
end

local edit = false
local count = 0

while true do
    count = count + 1
    local eventData = {event.pull(0.1)}
    if (eventData[1] == "touch" or eventData[1] == "drag") and eventData[2] == term.screen() then
        edit = true
        count = 1
        local posX = eventData[3]
        local posY = eventData[4]
        local button = eventData[5]

        local newstate
        if button == 0 then
            newstate = true
        elseif button == 1 then
            newstate = false
        end

        level[posX][posY] = newstate
        gpu.setBackground((level[posX][posY] and 0xFFFFFF) or 0)
        gpu.set(posX, posY, " ")
    elseif eventData[1] == "drop" and eventData[2] == term.screen() then
        edit = false
        count = 1
    end

    if not edit and count % 15 == 0 then
        local level2 = {}
        for cx = 1, rx do
            level2[cx] = {}
            for cy = 1, ry do
                level2[cx][cy] = level[cx][cy]
            end
        end
        for cx = 1, rx do
            for cy = 1, ry do
                local counts = 0

                if getState(level, cx, cy + 1) then counts = counts + 1 end
                if getState(level, cx, cy - 1) then counts = counts + 1 end
                if getState(level, cx + 1, cy) then counts = counts + 1 end
                if getState(level, cx - 1, cy) then counts = counts + 1 end

                if getState(level, cx + 1, cy + 1) then counts = counts + 1 end
                if getState(level, cx - 1, cy - 1) then counts = counts + 1 end
                if getState(level, cx + 1, cy - 1) then counts = counts + 1 end
                if getState(level, cx - 1, cy + 1) then counts = counts + 1 end

                if counts == 3 then level2[cx][cy] = true; end
                if counts < 2 or counts > 3 then level2[cx][cy] = false; end
            end
        end
        for cx = 1, rx do
            for cy = 1, ry do
                level[cx][cy] = level2[cx][cy]
            end
        end
        gpu.setBackground(0)
        gpu.fill(1, 1, rx, ry, " ")
        gpu.setBackground(0xFFFFFF)
        for cx = 1, rx do
            for cy = 1, ry do
                if level[cx][cy] then
                    gpu.set(cx, cy, " ")
                end
            end
        end
    end
end