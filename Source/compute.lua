-- To place in a tick event with a timerId "compute"
--==================================================
-- Localisation
local cos, sin, tan = math.cos, math.sin, math.tan
local deg, rad = math.deg, math.rad

-- Get screen data
local width = system.getScreenWidth()
local height = system.getScreenHeight()
local vFov = system.getCameraVerticalFov()

local near = 0.1
local far = 1000.0

local aspectRatio = height/width
local tanFov = 1.0/math.tan(math.rad(vFov)*0.5)
local field = -far/(far-near)

local af = aspectRatio*tanFov
local nq = near*field


-- Get camera data
local pos = system.getCameraPos()
local camX, camY, camZ = pos[1], pos[2], pos[3]
local fwd = system.getCameraForward()
local camFwdX, camFwdY, camFwdZ = fwd[1], fwd[2], fwd[3]
local rgt = system.getCameraRight()
local camRgtX, camRgtY, camRgtZ = rgt[1], rgt[2], rgt[3]
local up = system.getCameraUp()
local camUpX, camUpY, camUpZ = up[1], up[2], up[3]

-- Set model properties
local yaw, pitch, roll = 0, 0, 0
local oX, oY, oZ = 0-0.125, 12-0.125, -0.125
local scaleX, scaleY, scaleZ = 1, 1, 1

_model = {
    size = {sV, sN, sV},
    vert = {
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
    faces = {}
}

-- Precompute cos and sin
local cy, sy = math.cos(yaw), math.sin(yaw)
local cp, sp = math.cos(pitch), math.sin(pitch)
local cr, sr = math.cos(roll), math.sin(roll)

local cycp, sycp = cy*cp, sy*cp
local cyspsr_sycr, syspsr_cycr, cpsr = cy*sp*sr - sy*cr, sy*sp*sr + cy*cr, cp*sr
local cyspcr_sysr, syspcr_cysr, cpcr = cy*sp*cr + sy*sr, sy*sp*cr - cy*sr, cp*cr


-- Compute normals
local nX, nY, nZ = mesh.normals[1], mesh.normals[2], mesh.normals[3]
for i=1,#nX do
    local nx, ny, nz = nX[i], nY[i], nZ[i]
    
    --Rotation
    local nxT, nyT, nzT = nx, ny, nz
    nx = nxT*cycp + nyT*sycp + nzT*(-sp)
    ny = nxT*cyspsr_sycr + nyT*syspsr_cycr + nzT*cpsr
    nz = nxT*cyspcr_sysr + nyT*syspcr_cysr + nzT*cpcr

    --Add the normal update the normal vector
    _model.normals[1][i] = nx
    _model.normals[2][i] = ny
    _model.normals[3][i] = nz
    _model.normals[4][i] = nil
end

-- Compute vertices
local faceId = 1
local F = mesh.faces
local vX, vY, vZ = mesh.vert[1], mesh.vert[2], mesh.vert[3]

for i = 1,#F do
    local face, depth, dot = F[i], 0, 0
    local nId = face[2]
    
    for j=1,#face[1] do
        local id = face[1][j]

        --Compute this vertice
        vx, vy, vz = vX[id], vY[id], vZ[id]

        --Local scaling
        vx = vx*scaleX
        vy = vy*scaleY
        vz = vz*scaleZ

        --Local rotations YAW, PITCH, ROLL
        local vxT, vyT, vzT = vx, vy, vz
        vx = vxT*cycp + vyT*sycp + vzT*(-sp)
        vy = vxT*cyspsr_sycr + vyT*syspsr_cycr + vzT*cpsr
        vz = vxT*cyspcr_sysr + vyT*syspcr_cysr + vzT*cpcr

        --Positionning
        vx = vx + oX - camX
        vy = vy + oY - camY
        vz = vz + oZ - camZ

        -- Compute dot product with normal
        dot = _model.normals[4][nId]
        if not dot then
            local len = (vx*vx+vy*vy+vz*vz)^(-0.5)
            dot = vx*len*nX[nId] + vy*len*nY[nId] + vz*len*nZ[nId]
        end
        _model.normals[4][nId] = dot
        
        if dot >= 0 then break end

        --Project camera referential
        vxT, vyT, vzT = vx, vy, vz
        vx = vxT * camRgtX + vyT * camRgtY + vzT * camRgtZ
        vy = vxT * camFwdX + vyT * camFwdY + vzT * camFwdZ
        vz = vxT *  camUpX + vyT *  camUpY + vzT *  camUpZ

        --Project vertice from 3D -> 2D
        vxT, vyT, vzT = vx, vy, vz
        vx = (af * vxT)/vyT
        vy = ( -tanFov * vzT)/vyT
        vz = ( -field * vyT + nq)/vyT

        --Add this vertice to the mesh
        _model.vert[1][id], _model.vert[2][id], _model.vert[3][id] = vx, vy, vz

        depth = depth + vz
    end


    face[3] = depth/#face[1]
    if face[3] >= 0 and dot < 0 then
        face[4] = mesh.colors[nId] or {180, 180, 180}
        _model.faces[faceId] = face
        faceId = faceId +1
    end
end

table.sort(_model.faces, function(a,b) return a[3] > b[3] end)