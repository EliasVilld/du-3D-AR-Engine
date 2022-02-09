-- To place in a unit start filter
--==================================================
--Set globals fields
mesh = {
    size = {8,6,12},
    -- X | Y | Z
    vertices = {
        {-0.5,-0.5,-0.5,-0.5,0.5,0.5,0.5,0.5},
        {-0.5,-0.5,0.5,0.5,-0.5,-0.5,0.5,0.5},
        {-0.5,0.5,-0.5,0.5,-0.5,0.5,-0.5,0.5}
    },
    -- X | Y | Z | DOT
    normals = {
        {-1.0, 0.0, 1.0, 0.0, 0.0, 0.0},
        { 0.0, 1.0, 0.0,-1.0, 0.0, 0.0},
        { 0.0, 0.0, 0.0, 0.0,-1.0, 1.0},
        {   0,   0,   0,   0,   0,   0,}
    },
    lines = {},
    colors = {
        {  0,  0,250},
        {  0,125,125},
        {  0,250,  0},
        {125,125,  0},
        {250,  0,  0},
        {125,  0,125}
    },
    -- VERTICES IDS | NORMAL ID
    faces = {
        {{ 2, 3, 1}, 1},
        {{ 4, 7, 3}, 2},
        {{ 8, 5, 7}, 3},
        {{ 6, 1, 5}, 4},
        {{ 7, 1, 3}, 5},
        {{ 4, 6, 8}, 6},
        {{ 2, 4, 3}, 1},
        {{ 4, 8, 7}, 2},
        {{ 8, 6, 5}, 3},
        {{ 6, 2, 1}, 4},
        {{ 7, 5, 1}, 5},
        {{ 4, 2, 6}, 6}
    }
}

--[[local vX, vY, vZ = mesh.vertices[1], mesh.vertices[2], mesh.vertices[3]
for i = 1, 32 do
    local d = math.pi/64
    local id = #vX+1
    
    vX[id] = math.cos(d)
    vY[id] = math.sin(d)
    vZ[id] = 0
    
    mesh.lines[#mesh.lines+1] = {id, i == 32 and id-31 or id+1}
end]]

--Set model global
local sV, sN, sV = #mesh.vertices[1],#mesh.normals[1],#mesh.faces
_model = {
    size = {sV, sN, sV},
    vertices = {
        {},
        {},
        {}
    },
    normals = {
        {},
        {},
        {},
        {}
    },
    lines = {},
    faces = {}
}

-- Define global parameters
_width = system.getScreenWidth()
_height = system.getScreenHeight()
_vFov = system.getCameraVerticalFov()

system.print(string.format('Horizontal fov : %.16f',system.getCameraHorizontalFov()))
system.print(string.format('Vertical fov : %.16f',_vFov))
system.print(string.format('Width: %.2f',_width))
system.print(string.format('Height: %.2f',_height))

_near = 0.01
_far = 1000.0

_aspectRatio = _height/_width
_tanFov = 1.0/math.tan(math.rad(_vFov)*0.5)
_field = -_far/(_far-_near)

--Set the computation tick
unit.setTimer('compute', 0.001)
system.showScreen(1)

_logs = {
    ['Computed Normals'] = {},
    ['Computed Faces'] = {},
    ['Computed Vertices'] = {},
    ['Computation Time'] = {},
    ['Computation Memory Use'] = {},
    ['Rendering Compose Time'] = {},
    ['Concat Time'] = {},
    ['SVG Render Time'] = {}
}
