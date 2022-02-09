-- To place in a tick event with a timerId "compute"
--==================================================
local logCompTime = _logs['Computation Time']
local logCompMem = _logs['Computation Memory Use']
local logCompNormals = _logs['Computed Normals']
local logCompFaces = _logs['Computed Faces']
local logCompVertices = _logs['Computed Vertices']

local t0 = system.getTime()

-- Localisation
local cos, sin, tan = math.cos, math.sin, math.tan
local deg, rad = math.deg, math.rad

-- Get screen data
local width = system.getScreenWidth()
local height = system.getScreenHeight()
local vFov = system.getCameraVerticalFov()

if width ~= _width or height~= _height or vFov~= _vFov then
    _width, _height, _vFov = width, height, vFov
    
    _aspectRatio = height/width
    _tanFov = 1.0/math.tan(math.rad(vFov)*0.5)
    _field = -_far/(_far-_near)
end

local tanFov, field = _tanFov, _field
local af = _aspectRatio*tanFov
local nq = _near*field


-- Get camera data
local pos = system.getCameraPos()
local camX, camY, camZ = pos[1], pos[2], pos[3]
local fwd = system.getCameraForward()
local camFwdX, camFwdY, camFwdZ = fwd[1], fwd[2], fwd[3]
local rgt = system.getCameraRight()
local camRgtX, camRgtY, camRgtZ = rgt[1], rgt[2], rgt[3]
local up = system.getCameraUp()
local camUpX, camUpY, camUpZ = up[1], up[2], up[3]

-- Set mesh properties
local yaw, pitch, roll = 0, 0, 0
local oX, oY, oZ = -0.125, 11.875, -0.125
local scaleX, scaleY, scaleZ = 1, 1, 1

-- Set model
local nMX, nMY, nMZ = mesh.normals[1], mesh.normals[2], mesh.normals[3]
local vMX, vMY, vMZ = mesh.vertices[1], mesh.vertices[2], mesh.vertices[3]
local MF, ML = mesh.faces, mesh.lines

local sV, sN, sF, sL = #vMX,#nMX,#MF,#ML
_model = {
    size = {sV, sN, sF, sL},
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
local vX, vY, vZ = _model.vertices[1], _model.vertices[2], _model.vertices[3]
local nX, nY, nZ, nDot = _model.normals[1], _model.normals[2], _model.normals[3], _model.normals[4]
local F, L = _model.faces, _model.lines

-- Precompute cos and sin
local cy, sy = cos(yaw), sin(yaw)
local cp, sp = cos(pitch), sin(pitch)
local cr, sr = cos(roll), sin(roll)

local cycp, sycp = cy*cp, sy*cp
local cyspsr_sycr, syspsr_cycr, cpsr = cy*sp*sr - sy*cr, sy*sp*sr + cy*cr, cp*sr
local cyspcr_sysr, syspcr_cysr, cpcr = cy*sp*cr + sy*sr, sy*sp*cr - cy*sr, cp*cr

local dX, dY, dZ = oX - camX, oY - camY, oZ - camZ

-- Compute normals
for i=1,sN do
    local nx, ny, nz = nMX[i], nMY[i], nMZ[i]

    --Rotation
    local nxT, nyT, nzT = nx, ny, nz
    nx = nxT*cycp + nyT*sycp + nzT*(-sp)
    ny = nxT*cyspsr_sycr + nyT*syspsr_cycr + nzT*cpsr
    nz = nxT*cyspcr_sysr + nyT*syspcr_cysr + nzT*cpcr

    --Add the normal update the normal vector
    nX[i] = nx
    nY[i] = ny
    nZ[i] = nz
    nDot[i] = nil
end
logCompNormals[#logCompNormals+1] = sN

-- Compute vertices
local faceId = 1
local vertexIndex = 0
for i = 1,sF do
    local face, depth, dot = MF[i], 0, 0
    local nId = face[2]

    for j=1,#face[1] do
        local id = face[1][j]

        if j>1 and vX[id] then
            vz = vZ[id]
        else
            --Compute this vertice
            vx, vy, vz = vMX[id], vMY[id], vMZ[id]

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
            vx = vx + dX
            vy = vy + dY
            vz = vz + dZ

            -- Compute dot product with normal
            dot = nDot[nId]
            if not dot then
                local len = (vx*vx+vy*vy+vz*vz)^(-0.5)
                dot = vx*len*nMX[nId] + vy*len*nMY[nId] + vz*len*nMZ[nId]
                nDot[nId] = dot
            end

            if dot >= 0 then goto skipFace end

            --Project camera referential
            vxT, vyT, vzT = vx, vy, vz
            vx = vxT * camRgtX + vyT * camRgtY + vzT * camRgtZ
            vy = vxT * camFwdX + vyT * camFwdY + vzT * camFwdZ
            vz = vxT *  camUpX + vyT *  camUpY + vzT *  camUpZ

            if vy < 0.01 then goto skipFace end
            
            --Project vertice from 3D -> 2D
            vxT, vyT, vzT = vx, vy, vz
            local ivyT = 1/vyT
            vx = (af * vxT)*ivyT
            vy = ( -tanFov * vzT)*ivyT
            vz = ( -field * vyT + nq)*ivyT

            --Add this vertice to the mesh
            vX[id], vY[id], vZ[id] = vx, vy, vz
            
            vertexIndex = vertexIndex +1
        end

        depth = depth + vz
    end
    
    depth = depth/#face[1]
    if depth >= 0 then
        F[faceId] = {
            face[1],
            nId,
            depth,
            mesh.colors[nId] or {180, 180, 180}
        }
        faceId = faceId+1
    end
    
    ::skipFace::
end

logCompFaces[#logCompFaces+1] = faceId-1
logCompVertices[#logCompVertices+1] = vertexIndex

table.sort(F, function(a,b) return a[3] > b[3] end)


logCompTime[#logCompTime+1] = system.getTime() - t0
logCompMem[#logCompMem+1] = collectgarbage("count")

if #logCompTime > 200 then table.remove(logCompTime, 1) end
if #logCompMem > 200 then table.remove(logCompMem, 1) end
if #logCompNormals > 200 then table.remove(logCompNormals, 1) end
if #logCompFaces > 200 then table.remove(logCompFaces, 1) end
if #logCompVertices > 200 then table.remove(logCompVertices, 1) end

--collectgarbage("collect")
