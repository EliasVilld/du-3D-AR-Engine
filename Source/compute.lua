-- To place in a tick event with a timerId "compute"
--==================================================
local logCompTime = _logs['Computation Time']
local logCompMem = _logs['Computation Memory Use']

-- Localisation
local cos, sin, tan = math.cos, math.sin, math.tan
local deg, rad = math.deg, math.rad
local sort, remove, garbageCount = table.sort, table.remove, collectgarbage

local getCamPos, getTime = system.getCameraPos, system.getTime
local getCamFwd, getCamRgt, getCamUp = system.getCameraForward, system.getCameraRight, system.getCameraUp

-- Get screen data
local t0 = getTime()

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

-- Set model
local nMX, nMY, nMZ = mesh.normals[1], mesh.normals[2], mesh.normals[3]
local vMX, vMY, vMZ = mesh.vertices[1], mesh.vertices[2], mesh.vertices[3]
local sMV, sMN = mesh.shapes[1], mesh.shapes[2]

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
        {},
        {}
    },
    shapes = {
        {},
        {},
        {}
    },
    buffer = {},
    depth = {}
}
local vX, vY, vZ = _model.vertices[1], _model.vertices[2], _model.vertices[3]
local nX, nY, nZ, nDot = _model.normals[1], _model.normals[2], _model.normals[3], _model.normals[4]
local sV, sN, sC = _model.shapes[1], _model.shapes[2], _model.shapes[3]
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


-- Compute normals
for i=1,nN do
    local nx, ny, nz = nMX[i], nMY[i], nMZ[i]

    --Rotation
    nX[i] = nx*cycp + ny*sycp + nz*(-sp)
    nY[i] = nx*cyspsr_sycr + ny*syspsr_cycr + nz*cpsr
    nZ[i] = nx*cyspcr_sysr + ny*syspcr_cysr + nz*cpcr
    nDot[i] = nil
end


-- Compute vertices
local shapeId = 1

for i = 1,nS do
    local depth, dot = 0, 0
    local vIds, nId, vId = sMV[i], sMN[i], -1
    local index, maxIndex = 1, #vIds
    local iMaxIndex = 1/maxIndex

    --# Compute the first vertice position for back-face culling
    if nId then
        id = vIds[index]

        --Local rotations YAW, PITCH, ROLL & positionning
        local vxT, vyT, vzT = vMX[id], vMY[id], vMZ[id]
        vx = vxT*cycp + vyT*sycp + vzT*(-sp) + dX
        vy = vxT*cyspsr_sycr + vyT*syspsr_cycr + vzT*cpsr + dY
        vz = vxT*cyspcr_sysr + vyT*syspcr_cysr + vzT*cpcr + dZ

        -- Compute dot product with normal
        dot = nDot[nId]
        if not dot then
            local len = (vx*vx+vy*vy+vz*vz)^(-0.5)
            dot = vx*len*nMX[nId] + vy*len*nMY[nId] + vz*len*nMZ[nId]
            nDot[nId] = dot
        end

        if dot >= 0 then goto skipShape end

        --Project camera referential
        vxT, vyT, vzT = vx, vy, vz
        
        vx = vxT * camRgtX + vyT * camRgtY + vzT * camRgtZ
        vy = vxT * camFwdX + vyT * camFwdY + vzT * camFwdZ
        vz = vxT *  camUpX + vyT *  camUpY + vzT *  camUpZ

        if vy < 0.01 then goto skipShape end

        --Project vertice from 3D -> 2D
        local ivy = 1/vy

        vX[id] = (af * vx)*ivy
        vY[id] = ( -tanFov * vz)*ivy            
        vz = ( -field * vy + nq)*ivy
        vZ[id] = vz

        depth = depth + vz

        index = 2
    end

    for j=index,maxIndex do
        id = vIds[j]

        if vX[id] then
            vz = vZ[id]
        else
            --Compute this vertice
            vx, vy, vz = vMX[id], vMY[id], vMZ[id]

            --Local rotations YAW, PITCH, ROLL & Positionning & Projection to camera            
            local vxT, vyT, vzT = vx, vy, vz
            vx = vxT * Mxx + vyT * Myx + vzT * Mzx + Mwx 
            vy = vxT * Mxy + vyT * Myy + vzT * Mzy + Mwy 
            vz = vxT * Mxz + vyT * Myz + vzT * Mzz + Mwz 

            if vy < 0.01 then goto skipShape end

            --Project vertice from 3D -> 2D
            local ivy = 1/vy

            vX[id] = (af * vx)*ivy
            vY[id] = ( -tanFov * vz)*ivy            
            vz = ( -field * vy + nq)*ivy
            vZ[id] = vz
        end

        depth = depth + vz
    end

    if depth >= 0 then
        depth = depth*iMaxIndex

        sV[shapeId] = vIds
        sN[shapeId] = nId
        sC[shapeId] = mesh.colors[nId] or {180, 180, 180}

        D[shapeId] = depth
        B[depth] = shapeId
        shapeId = shapeId+1
    end

    ::skipShape::
end

sort(D)

system.print(#_model.vertices[1])

logCompTime[#logCompTime+1] = getTime() - t0
logCompMem[#logCompMem+1] = garbageCount("count")

if #logCompTime > 200 then remove(logCompTime, 1) end
if #logCompMem > 200 then remove(logCompMem, 1) end
