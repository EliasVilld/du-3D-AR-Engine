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

local tanFov, field = _tanFov, _field
local af = _aspectRatio*tanFov
local nq = _near*field


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
local yaw, pitch, roll = 0, 0, 0
local oX, oY, oZ = -0.125, 11.875, -0.125
local scale = 10

-- Set model
local nMX, nMY, nMZ = _mesh.normals[1], _mesh.normals[2], _mesh.normals[3]
local vMX, vMY, vMZ = _mesh.vertices[1], _mesh.vertices[2], _mesh.vertices[3]
local sMV, sMN = _mesh.shapes[1], _mesh.shapes[2]

local nN, nS = #nMX,#sMV
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
local nX, nY, nZ = _model.normals[1], _model.normals[2], _model.normals[3]
local sV, sN, sC, sDot = _model.shapes[1], _model.shapes[2], _model.shapes[3], _model.shapes[4]
local B, D = _model.buffer, _model.depth

-- Precompute cos and sin
local cy, sy = cos(yaw), sin(yaw)
local cp, sp = cos(pitch), sin(pitch)
local cr, sr = cos(roll), sin(roll)

local cycp, sycp = cy*cp, sy*cp
local cyspsr_sycr, syspsr_cycr, cpsr = cy*sp*sr - sy*cr, sy*sp*sr + cy*cr, cp*sr
local cyspcr_sysr, syspcr_cysr, cpcr = cy*sp*cr + sy*sr, sy*sp*cr - cy*sr, cp*cr

local dX, dY, dZ = oX - camX, oY - camY, oZ - camZ

-- Precompute 2

local Mxx, Myx, Mzx, Mwx =              cycp*camRgtX + sycp*camFwdX + (-sp)*camUpX,              cycp*camRgtY + sycp*camFwdY + (-sp)*camUpY,              cycp*camRgtZ + sycp*camFwdZ + (-sp)*camUpZ, dX*camRgtX + dY*camRgtY + dZ*camRgtZ
local Mxy, Myy, Mzy, Mwy = cyspsr_sycr*camRgtX + syspsr_cycr*camFwdX + cpsr*camUpX, cyspsr_sycr*camRgtY + syspsr_cycr*camFwdY + cpsr*camUpY, cyspsr_sycr*camRgtZ + syspsr_cycr*camFwdZ + cpsr*camUpZ, dX*camFwdX + dY*camFwdY + dZ*camFwdZ
local Mxz, Myz, Mzz, Mwz = cyspcr_sysr*camRgtX + syspcr_cysr*camFwdX + cpcr*camUpX, cyspcr_sysr*camRgtY + syspcr_cysr*camFwdY + cpcr*camUpY, cyspcr_sysr*camRgtZ + syspcr_cysr*camFwdZ + cpcr*camUpZ,    dX*camUpX + dY*camUpY + dZ*camUpZ
local Mxw, Myw, Mzw, Mww = 0, 0, 0, 1

local MVxx, MVyx, MVzx, MVwx =      af*Mxx,      af*Myx,      af*Mzx,          af*Mwx
local MVxy, MVyy, MVzy, MVwy = -tanFov*Mxz, -tanFov*Myz, -tanFov*Mzz,     -tanFov*Mwz
local MVxz, MVyz, MVzz, MVwz =  -field*Mxy,  -field*Mxy,  -field*Mxy, -field*Mxy + nq
local MVxw, MVyw, MVzw, MVww =         Mxz,         Myz,         Mzz,             Mwz

local MCVxx, MCVyx, MCVzx, MCVwx =     af*camRgtX,     af*camRgtY,     af*camRgtZ,   0
local MCVxy, MCVyy, MCVzy, MCVwy = -tanFov*camUpX, -tanFov*camUpY, -tanFov*camUpZ,   0
local MCVxz, MCVyz, MCVzz, MCVwz = -field*camFwdX, -field*camFwdY, -field*camFwdZ,  nq
local MCVxw, MCVyw, MCVzw, MCVww =         camUpX,         camUpY,         camUpZ,   0

-- Compute normals
for i=1,nN do
    local nx, ny, nz = nMX[i], nMY[i], nMZ[i]

    --Rotation
    nX[i] = nx*cycp + ny*sycp + nz*(-sp)
    nY[i] = nx*cyspsr_sycr + ny*syspsr_cycr + nz*cpsr
    nZ[i] = nx*cyspcr_sysr + ny*syspcr_cysr + nz*cpcr
end


-- Compute vertices
local shapeId = 1
_vertexId = 0


local vx, vy, vz = 0, 0, 0 
for i = 1,nS do
    local depth, dot = 0, 0
    local vIds, nId = sMV[i], sMN[i]
    local index, maxIndex = 1, #vIds

    --# Compute the first vertice position for back-face culling
    if nId then        
        local id = vIds[index]

        --Local rotations YAW, PITCH, ROLL & positionning
        local vxT, vyT, vzT = vMX[id]*scale, vMY[id]*scale, vMZ[id]*scale
        
        local vx = vxT*cycp + vyT*sycp + vzT*(-sp) + dX
        local vy = vxT*cyspsr_sycr + vyT*syspsr_cycr + vzT*cpsr + dY
        local vz = vxT*cyspcr_sysr + vyT*syspcr_cysr + vzT*cpcr + dZ

        -- Compute dot product with normal
        local len = (vx*vx+vy*vy+vz*vz)^(-0.5)
        dot = vx*len*nMX[nId] + vy*len*nMY[nId] + vz*len*nMZ[nId]
        sDot[nId] = dot

        if dot >= 0 then goto skipShape end

        if vX[id] then
            vz = vZ[id]
        else
            --Project camera referential
            vxT, vyT, vzT = vx, vy, vz

            vy = vxT * camFwdX + vyT * camFwdY + vzT * camFwdZ
            if vy < 0.01 then goto skipShape end
            local ivy = 1/vy
            
            --Project vertice from 3D -> 2D
            --Matrix Proj.View
            vX[id] = (vxT * MCVxx + vyT * MCVyx + vzT * MCVzx + MCVwx)*ivy 
            vY[id] = (vxT * MCVxy + vyT * MCVyy + vzT * MCVzy + MCVwy)*ivy 
            vz = (vxT * MCVxz + vyT * MCVyz + vzT * MCVzz + MCVwz)*ivy 
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
            vx, vy, vz = vMX[id]*scale, vMY[id]*scale, vMZ[id]*scale
            local vxT, vyT, vzT = vx, vy, vz
            
            --Local rotations YAW, PITCH, ROLL & Positionning & Projection to camera 
            --Matrix View.Trans
            vy = vxT * Mxy + vyT * Myy + vzT * Mzy + Mwy
            if vy < 0.01 then goto skipShape end

            --Project vertice from 3D -> 2D
            --Matrix Proj.View  
            local ivy = 1/vy
            
            vX[id] = (vxT * MVxx + vyT * MVyx + vzT * MVzx + MVwx)*ivy 
            vY[id] = (vxT * MVxy + vyT * MVyy + vzT * MVzy + MVwy)*ivy 
            vz = (vxT * MVxz + vyT * MVyz + vzT * MVzz + MVwz)*ivy 
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
