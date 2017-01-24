local uetorch = require 'uetorch'
local config = require 'config'
local utils = require 'utils'
local material = require 'material'
local backwall = require 'backwall'
local occluder = require 'occluder'
local camera = require 'camera'
local block = {}

local floor = uetorch.GetActor('Floor')
local sphere = uetorch.GetActor("Sphere_1")
local sphere2 = uetorch.GetActor("Sphere_2")
local sphere3 = uetorch.GetActor("Sphere_3")
local spheres = {sphere, sphere2, sphere3}
local occluder1 = uetorch.GetActor("Occluder_1")
local occluder2 = uetorch.GetActor("Occluder_2")
local occluder1_boxY, occluder2_boxY
block.actors = {occluder1=occluder1, occluder2=occluder2}

local iterationId, iterationType, iterationBlock, iterationPath
local params = {}


function block.IsPossible()
   -- train blocks are always physically possible
   return true
end


function block.MaskingActors()
   -- on train, we don't have any inactive actor
   local active, inactive, text = {}, {}, {}

   table.insert(active, floor)
   table.insert(text, "floor")

   if params.isBackwall then
      backwall.tableInsert(active, text)
   end

   if params.nOccluders >=1 then
      table.insert(active, occluder1)
      table.insert(text, "occluder1")
   end

   if params.nOccluders >= 2 then
      table.insert(active, occluder2)
      table.insert(text, "occluder2")
   end

   for i = 1, params.n do
      table.insert(active, spheres[i])
      table.insert(text, 'sphere' .. i)
   end

   return active, inactive, text
end


function block.MaxActors()
   -- spheres + occluders + floor + backwall*3
   local max = 1 -- floor
   if params.isBackwall then
      max = max + 3
   end
   return max + params.n + params.nOccluders
end


-- Return random parameters for the C1 block, training configuration
local function GetRandomParams()
   local params = {
      -- floor
      ground = math.random(#material.ground_materials),

      -- occluders
      nOccluders = math.random(0, 2),

      -- spheres
      n = math.random(1,3),
      sphere1 = math.random(#material.sphere_materials),
      sphere2 = math.random(#material.sphere_materials),
      sphere3 = math.random(#material.sphere_materials),
      sphereZ = {
         70 + math.random(200),
         70 + math.random(200),
         70 + math.random(200)
      },

      -- scale in [1/2, 3/2], keep it a sphere -> scaling in all axes
      sphereScale = {
         math.random() + 1,
         math.random() + 1,
         math.random() + 1
      },

      -- 25% chance the sphere don't move (no force applied)
      sphereIsStatic = {
         math.random(1, 100) <= 25,
         math.random(1, 100) <= 25,
         math.random(1, 100) <= 25
      },

      forceX = {
         math.random(500000, 2000000),
         math.random(500000, 2000000),
         math.random(500000, 2000000)
      },
      forceY = {
         math.random(-1000000, 500000),
         math.random(-1000000, 500000),
         math.random(-1000000, 500000)
      },
      forceZ = {
         math.random(800000, 1000000),
         math.random(800000, 1000000),
         math.random(800000, 1000000)
      },
      signZ = {
         2 * math.random(2) - 3,
         2 * math.random(2) - 3,
         2 * math.random(2) - 3,
      },
      left = {
         math.random(0,1),
         math.random(0,1),
         math.random(0,1),
      }
   }
   params.index = math.random(1, params.n)

   -- Background wall with 50% chance
   params.isBackwall = (1 == math.random(0, 1))
   if params.isBackwall then
      params.backwall = backwall.random()
   end

   -- Pick random coordinates for the camera
   params.camera = camera.random()

   -- Pick random attributes for each occluder
   params.occluder = {}
   for i=1, params.nOccluders do
      table.insert(params.occluder, occluder.random())
   end

   return params
end


function block.SetBlock(currentIteration)
   iterationId, iterationType, iterationBlock, iterationPath =
      config.GetIterationInfo(currentIteration)

   local file = io.open (config.GetDataPath() .. 'output.txt', "a")
   file:write(currentIteration .. ", " ..
                 iterationId .. ", " ..
                 iterationType .. ", " ..
                 iterationBlock .. "\n")
   file:close()

   params = GetRandomParams()
   WriteJson(params, iterationPath .. 'params.json')

   for i = 1, params.n do
      block.actors['sphere' .. i] = spheres[i]
   end
end


function block.RunBlock()
   -- camera
   camera.setup(iterationType, 150, params.camera)

   -- floor
   material.SetActorMaterial(floor, material.ground_materials[params.ground])

   -- background wall
   if params.isBackwall then
      backwall.setup(params.backwall)
   else
      backwall.hide()
   end

   -- occluders
   for i = 1,2 do
      if params.occluder[i] == nil then
         occluder.hide(i)
      else
         occluder.setup(i, params.occluder[i])
      end
   end
   utils.AddTickHook(occluder.tick)

   -- spheres
   uetorch.SetActorVisible(sphere, true)

   material.SetActorMaterial(spheres[1], material.sphere_materials[params.sphere1])
   material.SetActorMaterial(spheres[2], material.sphere_materials[params.sphere2])
   material.SetActorMaterial(spheres[3], material.sphere_materials[params.sphere3])

   for i = 1,params.n do
      if params.left[i] == 1 then
         uetorch.SetActorLocation(spheres[i], -400, -550 - 150 * (i - 1), params.sphereZ[i])
      else
         uetorch.SetActorLocation(spheres[i], 500, -550 - 150 * (i - 1), params.sphereZ[i])
         params.forceX[i] = -params.forceX[i]
      end

      uetorch.SetActorScale3D(
         spheres[i], params.sphereScale[i], params.sphereScale[i], params.sphereScale[i])

      if not params.sphereIsStatic[i] then
         uetorch.AddForce(
            spheres[i], params.forceX[i], params.forceY[i], params.signZ[i] * params.forceZ[i])
      end
   end
end


return block
