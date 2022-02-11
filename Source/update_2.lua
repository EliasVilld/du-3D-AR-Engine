-- To place in a second update filter
--==================================================

local logCompTime = _logs['Computation Time']
local logCompMem = _logs['Computation Memory Use']
local logRenderTime = _logs['Rendering Compose Time']

local width = system.getScreenWidth()
local height = system.getScreenHeight()

local result, index = {
    string.format([[<style>#debug { shape-rendering: optimizeSpeed; background:none } #debug text { fill:#fff; stroke:#000; font: 12px sans-serif} #debug text.m{text-anchor:middle} #debug text.r{text-anchor:end} #debug text.big{ font: 18px sans-serif} #debug path{ stroke:currentColor; fill:none; stroke-width:1; stroke-linecap:butt }</style><svg id="debug" style="position: absolute; left:0px; top:0px" viewBox="0 0 %.1f %.1f" >]], width, height),
    [[<text x=10 y=14 >v0.16</text>]]
}, 2

--Computation time
local min, max, avg = 999999, -999999, 0
for i=1, #logCompTime do
    local v = logCompTime[i]
    if v < min then min = v end
    if v > max then max = v end
    
    avg = avg + v
end
avg = avg/#logCompTime
local delta = max-min

result[index+1] = [[<g transform="translate(10,20)"><rect x=0 y=0 width=220 height=94 fill=rgba(0,0,0,0.2) />]]
result[index+2] = [[<text x=10 y=16 >Computation Time</text>]]
result[index+3] = [[<text x=20 y=32 >min</text>]]
result[index+4] = [[<text x=70 y=32 >max</text>]]
result[index+5] = string.format([[<text x=20 y=48 >%.3f</text>]], min*1000)
result[index+6] = string.format([[<text x=70 y=48 >%.3f</text>]], max*1000)
result[index+7] = string.format([[<text class='r big' x=210 y=48 >%.3fms</text>]], avg*1000)

result[index+8] = string.format([[<path color=#f00 d="M10 54M]])

index = index +8
for i=1, #logCompTime do
    local v = logCompTime[i]

    result[index+i] = string.format('%.1f %.1f' .. (i < #logCompTime and 'L' or ''), 10+i, 94 - (v/0.0005)*40)
end
result[#result+1] = [["/></g>]]
index = index +#logCompTime +1


--Memory Use
local min, max, avg = 999999, -999999, 0
for i=1, #logCompMem do
    local v = logCompMem[i]
    if v < min then min = v end
    if v > max then max = v end
    
    avg = avg + v
end
avg = avg/#logCompMem
local delta = max-min

result[index+1] = [[<g transform="translate(10,120)"><rect x=0 y=0 width=220 height=94 fill=rgba(0,0,0,0.2) />]]
result[index+2] = [[<text x=10 y=16 >Memory Use</text>]]
result[index+3] = [[<text x=20 y=32 >min</text>]]
result[index+4] = [[<text x=70 y=32 >max</text>]]
result[index+5] = string.format([[<text x=20 y=48 >%.1f</text>]], min)
result[index+6] = string.format([[<text x=70 y=48 >%.1f</text>]], max)
result[index+7] = string.format([[<text class='r big' x=210 y=48 >%.2fKB</text>]], avg)

result[index+8] = string.format([[<path color=#0f0 d="M10 54M]])

index = index +8
for i=1, #logCompMem do
    local v = logCompMem[i]

    result[index+i] = string.format('%.1f %.1f' .. (i < #logCompMem and 'L' or ''), 10+i, 94 - (v/4000)*40)
end
result[#result+1] = [["/></g>]]
index = index +#logCompMem +1


--Memory Use
local min, max, avg = 999999, -999999, 0
for i=1, #logRenderTime do
    local v = logRenderTime[i]
    if v < min then min = v end
    if v > max then max = v end
    
    avg = avg + v
end
avg = avg/#logRenderTime
local delta = max-min

result[index+1] = [[<g transform="translate(10,220)"><rect x=0 y=0 width=220 height=94 fill=rgba(0,0,0,0.2) />]]
result[index+2] = [[<text x=10 y=16 >SVG black magic</text>]]
result[index+3] = [[<text x=20 y=32 >min</text>]]
result[index+4] = [[<text x=70 y=32 >max</text>]]
result[index+5] = string.format([[<text x=20 y=48 >%.3f</text>]], min*1000)
result[index+6] = string.format([[<text x=70 y=48 >%.3f</text>]], max*1000)
result[index+7] = string.format([[<text class='r big' x=210 y=48 >%.3fms</text>]], avg*1000)

result[index+8] = string.format([[<path color=#0f0 d="M10 54M]])

index = index +8
for i=1, #logRenderTime do
    local v = logRenderTime[i]

    result[index+i] = string.format('%.1f %.1f' .. (i < #logRenderTime and 'L' or ''), 10+i, 94 - (v/0.0004)*40)
end
result[#result+1] = [["/></g>]]
index = index +#logRenderTime +1


-- Statistics
result[index+1] = [[<g transform="translate(10,320)"><rect x=0 y=0 width=220 height=94 fill=rgba(0,0,0,0.2) />]]
result[index+2] = [[<text x=10 y=16 >Statistics</text>]]
result[index+3] = [[<text x=20 y=32 >Vertices</text>]]
result[index+4] = string.format([[<text class="r" x=200 y=32 >%d/%d</text>]], #_model.vertices[1], #mesh.vertices[1])


result[#result+1] = '</svg>'
_logRender = table.concat(result)
