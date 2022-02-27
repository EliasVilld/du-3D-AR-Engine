
-- To place in a system update filter to visualize the grid bufffer if installed.
-- only for debugging purpose impact drasticly performances.
--==================================================

local sV, vX, vY, vZ = _model.shapes[1], _model.vertices[1], _model.vertices[2], _model.vertices[3]
local buffer, depth = _model.buffer, _model.depth
local dot = _model.shapes[3]
local nd = #depth

local mMax, mMin = math.max, math.min

local w2, h2 = _width*0.5, _height*0.5

local size = 100
local grid = {}
local visible = {}

for y = 1, _height/size do
    grid[y] = {}
    visible[y] = {}
    for x = 1, _width/size do
        grid[y][x] = _far
        visible[y][x] = false
    end 
end

local sx2, sy2 = _width/(2*size), _height/(2*size)
local min, max = 9999, -9999

local count = 0
for i =1,nd do
    local d = depth[i]
    if d then
        local shapeId = buffer[depth[i]]
        local vIds = sV[shapeId]
        local n = #vIds
        local disp = false

        if n == 3 then
            local id1, id2, id3 = vIds[1], vIds[2], vIds[3]
            local v0x, v1x, v2x = (vX[id1] +1)*sx2 +1, (vX[id2] +1)*sx2 +1, (vX[id3] +1)*sx2 +1
            local v0y, v1y, v2y = (vY[id1] +1)*sy2 +1, (vY[id2] +1)*sy2 +1, (vY[id3] +1)*sy2 +1

            local minX, maxX, minY, maxY = 1,-1, 1,-1
            for j=1,3 do
                local id = vIds[j]
                local vx, vy = vX[id], vY[id]

                if vx < minX then minX = vx end
                if vx > maxX then maxX = vx end

                if vy < minY then minY = vy end
                if vy > maxY then maxY = vy end
            end
            minX = (minX +1)*sx2 +1
            minX = minX - minX%1 +0.5
            maxX = (maxX +1)*sx2 +1
            maxX = maxX - maxX%1 +0.5

            minY = (minY +1)*sy2 +1
            minY = minY - minY%1 +0.5
            maxY = (maxY +1)*sy2 +1
            maxY = maxY - maxY%1 +0.5

            for y = minY, maxY do
                for x = minX, maxX do

                    local gx, gy = x-0.5, y-0.5
                    if grid[gy] and grid[gy][gx] then

                        if grid[gy][gx] -d >= 1 then
                            local inside = (x-v0x)*(v1y-v0y)-(y-v0y)*(v1x-v0x) >= 0 and (x-v1x)*(v2y-v1y)-(y-v1y)*(v2x-v1x) >= 0 and (x-v2x)*(v0y-v2y)-(y-v2y)*(v0x-v2x) >= 0
                            if inside then grid[gy][gx] = d end

                            if not disp then
                                count = count+1
                                disp = true
                                
                                if d < min then min = d end
                                if d > max then max = d end
                            end
                        end
                    end
                end
            end
        end
    end
end


local html = {string.format([[<style>
        #buffer {}
        #buffer rect {stroke:#000; stroke-width:0.1; width:%dpx; height:%dpx; opacity:0.6}
        #buffer text { font: 8px sans-serif; text-anchor: middle}
        #buffer text.thick { font: bold 10px sans-serif}
        </style>
        <svg id="buffer" width=100%% height=100%% style="position: absolute; left:0px; top:0px" viewBox="0 0 %.1f %.1f" >
]], size, size, _width, _height)}

if true then
    for y = 1, _height/size do
        for x = 1, _width/size do
            if grid[y][x] ~= _far then
                local s = 1-(grid[y][x]-min)/(max-min)
                local c = 255*s
                html[#html+1] = string.format([[<rect x=%.0f y=%d fill=rgb(%.0f,%.0f,%.0f) />]], (x-1)*size, (y-1)*size, c,c,c)
                --html[#html+1] = string.format([[<text x=%.0f y=%.0f fill=%s >%.2f</text>]], (x-1)*size, (y-1)*size, visible[y][x] and "#fff" or [[#f00  class="thick"]], grid[y][x])
            end
        end 
    end
end

html[#html+1] = string.format([[<text x=6 y=96 >Tri. : %.0f/%.0f/%.0f</text></svg>]], count, nd,#_mesh.shapes[1])

_htmlBuffer = table.concat(html)