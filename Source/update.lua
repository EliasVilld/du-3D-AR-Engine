-- To place in an update filter
--==================================================
if not _model then return end

local t0 = system.getTime()
local memory = collectgarbage("count")
local fps = 1/(t0-_fpsTime)
_fpsTime = t0

--=============================
local format, concat, remove = string.format, table.concat, table.remove

local width, height = _width, _height
local w2, h2 = width*0.5, height*0.5

local index = 2
local X, Y = _model.vertices[1], _model.vertices[2]
local sV, sN, sC, sDOT = _model.shapes[1], _model.shapes[2], _model.shapes[3], _model.shapes[4]
local buffer, depth = _model.buffer, _model.depth
local nd = #depth


local result = {format([[<style>
        #render path{ stroke:#eee; fill:none}
        #render line{ stroke:#eee}
        #render text { font: 12px sans-serif; fill:#fff}
        #render text.c { text-anchor:middle}
        #render polygon{ stroke:currentColor; fill:currentColor; stroke-width:1; stroke-linecap:butt }
        </style>
        <svg id="render" style="position: absolute; left:0px; top:0px" viewBox="0 0 %.1f %.1f" >
        <text x=6 y=12 >FPS : %.1f</text>
        <text x=6 y=30 >Mem. : %.1fKB</text>
        <text x=6 y=48 >Comp. : %.4fms</text>
        <text x=6 y=66 >Rend. : %.4fms</text>
        <text x=6 y=84 >Vert. : %d/%d</text>
        <text x=6 y=102 >Shap. : %d/%d</text>]], width, height, fps, memory, _compTime*1000, _rendTime*1000, _vertexId or 0, #_mesh.vertices[1], #sV, #_mesh.shapes[1])}


for i = nd,1,-1 do
    local shapeId = buffer[depth[i]]
    local vIds, isLine, col = sV[shapeId], sN[shapeId] == nil, sC[shapeId]
    --local dot, cx, cy, cw = sDOT[shapeId], 0, 0, 0
    local n = #vIds

    if n == 2 then
        local v1, v2 = vIds[1], vIds[2]
        cx, cy = (X[v1]+X[v2] +2.0) * w2/2, (Y[v1]+Y[v2] +2.0) * h2/2
        result[index] = format([[<line x1=%.1f y1=%.1f x2=%.1f y2=%.1f />]], (1 + X[v1])*w2, (1 + Y[v1])*h2, (1 + X[v2])*w2, (1 + Y[v2])*h2)

    elseif n == 3 and not isLine then
        local v1, v2, v3 = vIds[1], vIds[2], vIds[3]
        --cx, cy = (X[v1]+X[v2]+X[v3] +3.0) * w2/3, (Y[v1]+Y[v2]+Y[v3] +3.0) * h2/3
        
        result[index] = format([[<polygon color=rgb(%.0f,%.0f,%.0f) points="%.1f %.1f,%.1f %.1f,%.1f %.1f"/>]], col[1], col[2], col[3], (1 + X[v1])*w2, (1 + Y[v1])*h2, (1 + X[v2])*w2, (1 + Y[v2])*h2, (1 + X[v3])*w2, (1 + Y[v3])*h2)

    else
        if isLine then
            result[index] = format([[<path d="M]], col[1], col[2], col[3])
            for j = 1,n do
                local id = vIds[j]
                
                --cx, cy = cx + (X[id] +1.0) * w2, cy + (Y[id] +1.0) * h2

                local pattern = '%.1f %.1fL'
                if j == n then pattern = '%.1f %.1fZ' end
                
                result[index+j] = format(pattern, (X[id] +1.0) * w2, (Y[id] +1.0) * h2)
            end
            result[index+n+1] = [["/>]]
        else
            result[index] = format([[<polygon color=rgb(%.0f,%.0f,%.0f) points="]], col[1], col[2], col[3])
            for j = 1,n do
                local id = vId[j]

                --cx, cy = cx + (X[id] +1.0) * w2, cy + (Y[id] +1.0) * h2
                
                local pattern = '%.1f %.1f,'
                if j==n then pattern = '%.1f %.1f' end
                result[index+j] = format(pattern, (X[id] +1.0) * w2, (Y[id] +1.0) * h2)
            end
            result[index+n+1] = [["/>]]
        end
        
        --cx, cy = cx/n, cy/n
    end
    
    --result[#result+1] = string.format([[<text class="c" x=%.1f y=%.1f >%d</text>]], cx, cy, shapeId)
    index = #result+1
end
result[index] = '</svg>'

system.setScreen(concat(result))

_rendTime = system.getTime() - t0

