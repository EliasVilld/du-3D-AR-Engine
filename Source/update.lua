-- To place in an update filter
--==================================================
if not _model then return end

local logRenderTime = _logs['Rendering Compose Time']
local logConcatTime = _logs['Concat Time']
local logSVGTime = _logs['SVG Render Time']

local t0 = system.getTime()

local width = system.getScreenWidth()
local height = system.getScreenHeight()

local w2, h2 = width*0.5, height*0.5

local X, Y = _model.vertices[1], _model.vertices[2]
local result = {string.format([[<style>
        #render { shape-rendering: optimizeSpeed; background:none }
        #render text { font: bold 14px sans-serif; text-anchor:middle}
        #render path{ stroke:currentColor; fill:currentColor; stroke-width:1; stroke-linecap:butt }
        </style>
        <svg id="render" style="position: absolute; left:0px; top:0px" viewBox="0 0 %.1f %.1f" >]], width, height)}

local index = 2
for i,face in pairs(_model.faces) do
    local vIds = face[1]
    local col = face[4]
    --local cx, cy = 0, 0

    local n = #vIds
    if n == 3 then
        local v1, v2, v3 = vIds[1], vIds[2], vIds[3]
        result[index] = string.format([[<path color=rgb(%.0f,%.0f,%.0f) d="M%.1f %.1fL%.1f %.1fL%.1f %.1fZ"/>]], col[1], col[2], col[3], (1 + X[v1])*w2, (1 + Y[v1])*h2, (1 + X[v2])*w2, (1 + Y[v2])*h2, (1 + X[v3])*w2, (1 + Y[v3])*h2)
    elseif n == 4 then
        local v1, v2, v3, v4 = vIds[1], vIds[2], vIds[3], vIds[4]
        result[index] = string.format([[<path color=rgb(%.0f,%.0f,%.0f) d="M%.1f %.1fL%.1f %.1fL%.1f %.1fL%.1f %.1fZ"/>]], col[1], col[2], col[3], (1 + X[v1])*w2, (1 + Y[v1])*h2, (1 + X[v2])*w2, (1 + Y[v2])*h2, (1 + X[v3])*w2, (1 + Y[v3])*h2, (1 + X[v4])*w2, (1 + Y[v4])*h2)
    else
        result[index] = string.format([[<path color=rgb(%.0f,%.0f,%.0f) d="M]], col[1], col[2], col[3])
        for j, vId in pairs(vIds) do
            local vx, vy = (X[vId] +1.0) * w2, (Y[vId] +1.0) * h2

            result[index+j] = string.format('%.1f %.1f' .. (j < n and 'L' or 'Z'), vx, vy)
        end
        result[index+n] = [["/>]]
        index = index+n
    end
    index = index+1
end




result[index] = '</svg>'

logRenderTime[#logRenderTime +1] = system.getTime() - t0
t0 = system.getTime()

local out = _logRender .. table.concat(result)

logConcatTime[#logConcatTime +1] = system.getTime() - t0
t0 = system.getTime()

system.setScreen(out)

logSVGTime[#logSVGTime +1] = system.getTime() - t0


if #logRenderTime > 200 then table.remove(logRenderTime, 1) end
if #logConcatTime > 200 then table.remove(logConcatTime, 1) end
if #logSVGTime > 200 then table.remove(logSVGTime, 1) end
