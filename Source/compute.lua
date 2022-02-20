-- To place in a tick event with a timerId "compute"
--==================================================

-- Localisation
local cos, sin, tan = math.cos, math.sin, math.tan
local deg, rad = math.deg, math.rad
local getCamPos, getTime = system.getCameraPos, system.getTime
local getCamFwd, getCamRgt, getCamUp = system.getCameraForward, system.getCameraRight, system.getCameraUp

local t0 = getTime()

-- Get screen data
local width = _width
local height = _height
local vFov = _vFov
local near, far = _near, _far

local tF, f = _tanFov, _field
local af = _aspectRatio*tF
local nq = near*f


-- Get camera data
local pos = getCamPos()
local camX, camY, camZ = pos[1], pos[2], pos[3]
local fwd = getCamFwd()
local camFwdX, camFwdY, camFwdZ = fwd[1], fwd[2], fwd[3]
local rgt = getCamRgt()
local camRgtX, camRgtY, camRgtZ = rgt[1], rgt[2], rgt[3]
local up = getCamUp()
local camUpX, camUpY, camUpZ = up[1], up[2], up[3]

-- Set mesh properties
local yaw, pitch, roll = 0.25*t0, 0.25*t0, 0.25*t0
local oX, oY, oZ = -0.125, 11.875, -0.125
local s = 10

-- Set model
local nMX, nMY, nMZ, nN = {},{},{},0
local nX, nY, nZ = {},{},{}
if _mesh.normals then
    nMX, nMY, nMZ = _mesh.normals[1], _mesh.normals[2], _mesh.normals[3]
    nX, nY, nZ = _model.normals[1], _model.normals[2], _model.normals[3]
    nN = #nMX
end
local vMX, vMY, vMZ = _mesh.vertices[1], _mesh.vertices[2], _mesh.vertices[3]
local sMV, sMN = _mesh.shapes[1], _mesh.shapes[2]

local nS = #sMV
_model = {
    vertices = {
        {},
        {},
        {}
    },
    normals = {
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
local vX, vY, vZ = _model.vertices[1], _model.vertices[2], _model.vertices[3]
local sV, sN, sC, sDot = _model.shapes[1], _model.shapes[2], _model.shapes[3], _model.shapes[4]
local B, D = _model.buffer, _model.depth

-- Precompute cos and sin
local cy, sy = cos(yaw), sin(yaw)
local cp, sp = cos(pitch), sin(pitch)
local cr, sr = cos(roll), sin(roll)

local crcy, crsy, cpcr, crsp = cr*cy, cr*sy, cp*cr, cr*sp
local cpsy_cyspsr, cpcy_spsrsy = cp*sy + cy*sp*sr, cp*cy - sp*sr*sy
local cysp_cpsrsy, spsy_cpcysr = cy*sp + cp*sr*sy, sp*sy - cp*cy*sr

local dX, dY, dZ = oX - camX, oY - camY, oZ - camZ

-- Precompute matrix
--Mview*R (for normals)
local MNxx,MNxy,MNxz, MNyx,MNyy,MNyz, MNzx,MNzy,MNzz
if _mesh.normals then
    MNxx, MNxy, MNxz = camRgtX*crcy - camRgtZ*sr - camRgtY*crsy, camRgtX*(cpsy_cyspsr) + camRgtY*(cpcy_spsrsy) + camRgtZ*crsp, camRgtZ*cpcr - camRgtY*(cysp_cpsrsy) - camRgtX*(spsy_cpcysr)
    MNyx, MNyy, MNyz = camFwdX*crcy - camFwdZ*sr - camFwdY*crsy, camFwdX*(cpsy_cyspsr) + camFwdY*(cpcy_spsrsy) + camFwdZ*crsp, camFwdZ*cpcr - camFwdY*(cysp_cpsrsy) - camFwdX*(spsy_cpcysr)
    MNzx, MNzy, MNzz =    camUpX*crcy - camUpZ*sr - camUpY*crsy,    camUpX*(cpsy_cyspsr) + camUpY*(cpcy_spsrsy) + camUpZ*crsp,    camUpZ*cpcr - camUpY*(cysp_cpsrsy) - camUpX*(spsy_cpcysr)
end
--Mview*T*R*S (for first vertice)
local Mxx, Mxy, Mxz, Mxw = -s*(camRgtZ*sr - camRgtX*crcy + camRgtY*crsy), s*(camRgtX*(cpsy_cyspsr) + camRgtY*(cpcy_spsrsy) + camRgtZ*crsp), -s*(camRgtX*(spsy_cpcysr) + camRgtY*(cysp_cpsrsy) - camRgtZ*cpcr), camRgtX*dX + camRgtY*dY + camRgtZ*dZ
local Myx, Myy, Myz, Myw = -s*(camFwdZ*sr - camFwdX*crcy + camFwdY*crsy), s*(camFwdX*(cpsy_cyspsr) + camFwdY*(cpcy_spsrsy) + camFwdZ*crsp), -s*(camFwdX*(spsy_cpcysr) + camFwdY*(cysp_cpsrsy) - camFwdZ*cpcr), camFwdX*dX + camFwdY*dY + camFwdZ*dZ
local Mzx, Mzy, Mzz, Mzw =    -s*(camUpZ*sr - camUpX*crcy + camUpY*crsy),    s*(camUpX*(cpsy_cyspsr) + camUpY*(cpcy_spsrsy) + camUpZ*crsp),    -s*(camUpX*(spsy_cpcysr) + camUpY*(cysp_cpsrsy) - camUpZ*cpcr),    camUpX*dX + camUpY*dY + camUpZ*dZ
--Mproj*Mview*Tx*R*S
local MPxx, MPxy, MPxz, MPxw =         Mxx*af,        Mxy*af,        Mxz*af,          Mxw*af
local MPyx, MPyy, MPyz, MPyw =        -Mzx*tF,       -Mzy*tF,       -Mzz*tF,         -Mzw*tF
local MPzx, MPzy, MPzz, MPzw =         -Myx*f,        -Myy*f,        -Myz*f,      nq - Myw*f

-- Compute normals
for i=1,nN do
    local nx, ny, nz = nMX[i], nMY[i], nMZ[i]    

    --Mview*R
    nX[i] = MNxx*nx + MNxy*ny + MNxz*nz
    nY[i] = MNyx*nx + MNyy*ny + MNyz*nz
    nZ[i] = MNzx*nx + MNzy*ny + MNzz*nz
end

-- Compute vertices
local shapeId = 1
_vertexId = 0

for i = 1,nS do
    local depth, dot = 0, 0
    local vIds, nId = sMV[i], sMN[i]
    local index, maxIndex = 1, #vIds

    --# Compute the first vertice position for back-face culling
    if nId then        
        local id = vIds[index]
        --Local rotations YAW, PITCH, ROLL & positionning
        local vxT, vyT, vzT = vMX[id], vMY[id], vMZ[id]
        
        --Mview*T*R*S
        local vx = Mxx*vxT + Mxy*vyT + Mxz*vzT + Mxw
        local vy = Myx*vxT + Myy*vyT + Myz*vzT + Myw
        local vz = Mzx*vxT + Mzy*vyT + Mzz*vzT + Mzw
        
        -- Compute dot product with normal
        local len = (vx*vx+vy*vy+vz*vz)^(-0.5)
        dot = vx*len*nX[nId] + vy*len*nY[nId] + vz*len*nZ[nId]
        sDot[nId] = dot

        if dot >= 0 then goto skipShape end
        if vy < near or vy > far then goto skipShape end

        if vX[id] then
            vz = vZ[id]
        else
            local ivy = 1/vy
            --Project vertice from 3D -> 2D            
            --Mproj
            vX[id] = (af*vx)*ivy
            vY[id] = (-tF*vz)*ivy
            vz =     (-f*vy + nq)*ivy
            vZ[id] = vz
            
            _vertexId = _vertexId +1
        end

        depth = depth + vz
        index = 2
    end

    for j=index,maxIndex do
        local id = vIds[j]

        if vX[id] then
            vz = vZ[id]
        else
            --Compute this vertice
            local vxT, vyT, vzT = vMX[id], vMY[id], vMZ[id]
            
            --Local rotations YAW, PITCH, ROLL & Positionning & Projection to camera 
            --Mview*Tx*R*S
            local vy = Myx*vxT + Myy*vyT + Myz*vzT + Myw
            if vy < near or vy > far then goto skipShape end

            --Project vertice from 3D -> 2D
            local ivy = 1/vy
            
            --Mproj*Mview*Tx*R*S.*V
            vX[id] = (MPxx*vxT + MPxy*vyT + MPxz*vzT + MPxw)*ivy
            vY[id] = (MPyx*vxT + MPyy*vyT + MPyz*vzT + MPyw)*ivy
            vz = (MPzx*vxT + MPzy*vyT + MPzz*vzT + MPzw)*ivy
            vZ[id] = vz
            
            _vertexId = _vertexId +1            
        end

        depth = depth + vz
    end
    
    local col = _mesh.colors[nId]
    if not col then col = {180,40,40} end

    sV[shapeId] = vIds
    sN[shapeId] = nId
    sC[shapeId] = {
            col[1] + 40*(0.5-dot),
            col[2] + 40*(0.5-dot),
            col[3] + 40*(0.5-dot)
        }

    local iMaxIndex = 1/maxIndex
    depth = depth*iMaxIndex
    D[shapeId] = depth
    B[depth] = shapeId
    shapeId = shapeId+1

    ::skipShape::
end

local sort = table.sort
sort(D)
_compTime = getTime() - t0