-- This module defines the occluders behavior.
-- TODO more variable init location

local uetorch = require 'uetorch'
local material = require 'material'
local occluder = {}


-- the 2 occluders meshes defined in the scene, and their bounding
-- boxes
local occluder1 = uetorch.GetActor('Occluder_1')
local occluder2 = uetorch.GetActor('Occluder_2')

local occluder1_boxY = uetorch.GetActorBounds(occluder1).boxY
local occluder2_boxY = uetorch.GetActorBounds(occluder2).boxY


-- Pick a random wall texture for an occluder
function occluder.randomMaterial()
   return math.random(#material.wall_materials)
end


-- Select a random round trip for the occluder (0 -> no motion, 0.5 ->
-- single one way, 1 -> one round trip, 1.5 -> one round trip and one
-- more single, 2 -> 2 round trips)
function occluder.randomMovement()
   return math.random(0, 4) / 2
end


-- A brief pause (in number of frames) between each motion steps
function occluder.randomPause()
   return math.random(50)
end


-- Random rotation on the Z axis
function occluder.randomRotation()
   return math.random(-60, 60)
end


-- Start position is randomly 'up' or 'down'
function occluder.randomStartPosition()
   if math.random(0, 1) == 1 then
      return 'up'
   else
      return 'down'
   end
end


-- Pick a random scale for wall dimensions
function occluder.randomScale()
   return {
      0.25 * math.random(1, 4),
      1, --math.random(1, 6) / 2,
      1 - 0.6 * math.random()
   }
end


-- Generate a random set of attributes for an occluder
function occluder.random()
   local params = {
      material = occluder.randomMaterial(),
      movement = occluder.randomMovement(),
      scale = occluder.randomScale(),
      rotation = occluder.randomRotation(),
      startPosition = occluder.randomStartPosition()
   }

   params.pause = {}
   for i=1, params.movement*2 do
      table.insert(params.pause, occluder.randomPause())
   end

   return params
end


-- Remove an occluder from the scene, id must be 1 or 2
function occluder.hide(id)
   assert(id == 1 or id == 2)
   if id == 1 then
      uetorch.DestroyActor(occluder1)
   else
      uetorch.DestroyActor(occluder2)
   end
end


local occluder_register = {}

-- Initialize an occluder with its parameters. Id must be 1 or
-- 2. Params must be a table structured as the one returned by
-- occluder.random().
function occluder.setup(id, params)
   assert(id == 1 or id == 2)
   params = params or occluder.random()

   local mesh = occluder1
   local box = occluder1_boxY
   local shift = 0
   if id == 2 then
      mesh = occluder2
      box = occluder2_boxY
      shift = 400
   end

   material.SetActorMaterial(mesh, material.wall_materials[params.material])
   uetorch.SetActorScale3D(mesh, params.scale[1], params.scale[2], params.scale[3])

   if params.startPosition == 'up' then
      uetorch.SetActorRotation(mesh, 0, params.rotation, 0)
      uetorch.SetActorLocation(mesh, shift - 200 * params.scale[1], -350 - shift, 20)
   else -- down
      uetorch.SetActorRotation(mesh, 0, params.rotation, 90)
      uetorch.SetActorLocation(mesh, shift - 200 * params.scale[1], -350, 20 + box)
   end

   -- register the occluder for motion (through the occluder.tick
   -- method)
   if params.movement > 0 then
      table.insert(occluder_register, {
                      id=id,
                      mesh=mesh,
                      box=box,
                      rotation=params.rotation,
                      movement=params.movement,
                      pause=params.pause,
                      status='pause',
                      t_rotation=0,
                      t_rotation_change=0})
   end
end


function _occluder_pause(occ)
   occ.pause[1] = occ.pause[1] - 1
   if occ.pause[1] == 0 then
      -- go to the next movement: if down, go up, if up, go down
      if uetorch.GetActorRotation(occ.mesh).roll >= 89 then
         occ.status = 'go_up'
      else
         occ.status = 'go_down'
      end
   end
end


local function _occluder_move(occ, dir, dt)
   local angle_abs = (occ.t_rotation - occ.t_rotation_change) * 20 * 0.125
   local angle_rel = angle_abs
   if dir == 1 then --go up
      angle_rel = 90 - angle_rel
   end

   local location = uetorch.GetActorLocation(occ.mesh)
   uetorch.SetActorLocation(
      occ.mesh, location.x, location.y,
      20 + math.sin((angle_rel) * math.pi / 180) * occ.box)
   uetorch.SetActorRotation(occ.mesh, 0, occ.rotation, angle_rel)

   if angle_abs >= 90 then
      table.remove(occ.pause, 1)
      occ.movement = occ.movement - 0.5
      occ.status = "pause"
      occ.t_rotation_change = occ.t_rotation
   end

   occ.t_rotation = occ.t_rotation + dt
end


function occluder.tick(dt)
   for n, occ in pairs(occluder_register) do
      if occ.movement > 0 then
         if occ.status == 'pause' then
            _occluder_pause(occ)
         elseif occ.status == 'go_down' then
            _occluder_move(occ, -1, dt)
         else -- 'go_up'
            _occluder_move(occ, 1, dt)
         end
      end
   end
end


return occluder
