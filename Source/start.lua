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
    colors = {
        {  0,  0,250},
        {  0,125,125},
        {  0,250,  0},
        {125,125,  0},
        {250,  0,  0},
        {125,  0,125}
    },
    -- VERTICES IDS | NORMAL ID
    shapes = {
        {
            { 2, 3, 1},
            { 4, 7, 3},
            { 8, 5, 7},
            { 6, 1, 5},
            { 7, 1, 3},
            { 4, 6, 8},
            { 2, 4, 3},
            { 4, 8, 7},
            { 8, 6, 5},
            { 6, 2, 1},
            { 7, 5, 1},
            { 4, 2, 6}
        },
        {1,2,3,4,5,6,1,2,3,4,5,6}
    }
}

--Generate a wavy circle line
_steps = 32
local vX, vY, vZ = mesh.vertices[1], mesh.vertices[2], mesh.vertices[3]
local sV, sN = mesh.shapes[1], mesh.shapes[2]
for i = 1, _steps do
    local d = i*(2*math.pi)/_steps
    local id = #vX+1
    
    vX[id] = math.cos(d)
    vY[id] = math.sin(d)
    vZ[id] = 0.25*math.sin(2*d)
    
    sV[#sV+1] = {id, i == _steps and id-(_steps-1) or id+1}
    sN[#sN+1] = nil
end

--Set model global
local sV, sN, sS = #mesh.vertices[1],#mesh.normals[1],#mesh.shapes
_model = {
    size = {sV, sN, sS},
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
    shapes = {
        {},
        {},
        {},
        {}
    },
    buffer = {},
    depth = {}
}

-- Define global parameters
_width = system.getScreenWidth()
_height = system.getScreenHeight()
_vFov = system.getCameraVerticalFov()

_near = 0.01
_far = 1000.0
-- To recompute on regular time
_aspectRatio = _height/_width
_tanFov = 1.0/math.tan(math.rad(_vFov)*0.5)
_field = -_far/(_far-_near)

--Set the computation tick
unit.setTimer('compute', 0.001)
system.showHelper(0)
system.showScreen(1)

_logs = {
    ['Computed Normals'] = {},
    ['Computed Faces'] = {},
    ['Computation Time'] = {},
    ['Computation Memory Use'] = {},
    ['Rendering Compose Time'] = {},
    ['Concat Time'] = {},
    ['SVG Render Time'] = {},
    ['Computed Lines'] = {}
}
_logCompVertices = 0
