local uetorch = require 'uetorch'
local config = require 'config'
local utils = require 'utils'
local material = require 'material'
local backwall = require 'backwall'
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
local isHidden1,isHidden2


local t_rotation = 0
local t_rotation_change = 0

local function WallRotationDown(dt)
   local angle = (t_rotation - t_rotation_change) * 20 * 0.125
   local succ = uetorch.SetActorRotation(occluder1, 0, 0, angle)
   local succ2 = uetorch.SetActorRotation(occluder2, 0, 0, angle)

   uetorch.SetActorLocation(
      occluder1, -200 * params.scaleW, -350,
      20 + math.sin(angle * math.pi / 180) * occluder1_boxY)

   uetorch.SetActorLocation(
      occluder2, 300 - 200 * params.scaleW, -350,
      20 + math.sin(angle * math.pi / 180) * occluder2_boxY)

   if angle >= 90 then
      utils.RemoveTickHook(WallRotationDown)
      t_rotation_change = t_rotation
   end
   t_rotation = t_rotation + dt
end

local function RemainUp(dt)
   params.framesRemainUp = params.framesRemainUp - 1
   if params.framesRemainUp == 0 then
      utils.RemoveTickHook(RemainUp)
      utils.AddTickHook(WallRotationDown)
   end
end

local function WallRotationUp(dt)
   local angle = (t_rotation - t_rotation_change) * 20 * 0.125
   local succ = uetorch.SetActorRotation(occluder1, 0, 0, 90 - angle)
   local succ2 = uetorch.SetActorRotation(occluder2, 0, 0, 90 - angle)

   uetorch.SetActorLocation(
      occluder1, -200 * params.scaleW, -350,
      20 + math.sin((90 - angle) * math.pi / 180) * occluder1_boxY)

   uetorch.SetActorLocation(
      occluder2, 300 - 200 * params.scaleW, -350,
      20 + math.sin((90 - angle) * math.pi / 180) * occluder2_boxY)

   if angle >= 90 then
      utils.RemoveTickHook(WallRotationUp)
      utils.AddTickHook(RemainUp)
      t_rotation_change = t_rotation
   end
   t_rotation = t_rotation + dt
end

local function StartDown(dt)
   params.framesStartDown = params.framesStartDown - 1
   if params.framesStartDown == 0 then
      utils.RemoveTickHook(StartDown)
      utils.AddTickHook(WallRotationUp)
   end
end


local mainActor
function block.MainActor()
   return mainActor
end


function block.MaskingActors()
   local active, inactive = {}, {}
   local a = {table.unpack(spheres)}
   table.insert(active, occluder1)
   table.insert(active, occluder2)
   table.insert(active, floor)

   -- on train, we don't have any inactive actor
   for _, s in pairs(spheres) do
      table.insert(active, s)
   end

   if params.isBackwall then
      backwall.tableInsert(active)
   end

   return active, inactive
end


function block.MaxActors()
   return params.n + 6 -- spheres + 2 walls + floor + backwall*3
end


-- Return random parameters for the C1 block, training configuration
local function GetRandomParams()
   local params = {
      -- floor
      ground = math.random(#material.ground_materials),

      -- occluders
      nOccluders = math.random(0, 2),
      occluder1 = math.random(#material.wall_materials),
      occluder2 = math.random(#material.wall_materials),
      framesStartDown = math.random(5),
      framesRemainUp = math.random(5),
      scaleW = 1 - 0.5 * math.random(),
      scaleH = 1 - 0.4 * math.random(),

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

      sphereScale = {
         math.random() + 0.5,
         math.random() + 0.5,
         math.random() + 0.5
      },

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

   -- Pick random coordinates for the camera only for train
   params.cameraLocation = camera.randomLocation()
   params.cameraRotation = camera.randomRotation()

   return params
end


function block.SetBlockTrain(currentIteration)
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

   mainActor = spheres[params.index]
   for i = 1, params.n do
      block.actors['sphere' .. i] = spheres[i]
   end
end


function block.RunBlock()
   -- camera
   camera.setup(iterationType, 150, params.cameraLocation, params.cameraRotation)

   -- floor
   material.SetActorMaterial(floor, material.ground_materials[params.ground])

   -- background wall
   if params.isBackwall then
      backwall.setup(params.backwall)
   else
      backwall.hide()
   end

   -- occluders
   occluder1_boxY = uetorch.GetActorBounds(occluder1).boxY
   occluder2_boxY = uetorch.GetActorBounds(occluder2).boxY

   if params.nOccluders >= 1 then
      material.SetActorMaterial(occluder1, material.wall_materials[params.occluder1])
      uetorch.SetActorScale3D(occluder1, params.scaleW, 1, params.scaleH)
      uetorch.SetActorLocation(occluder1, -200 * params.scaleW, -350, 20 + occluder1_boxY)
      uetorch.SetActorRotation(occluder1, 0, 0, 90)
   else
      uetorch.DestroyActor(occluder1)
   end

   if params.nOccluders >= 2 then
      material.SetActorMaterial(occluder2, material.wall_materials[params.occluder2])
      uetorch.SetActorScale3D(occluder2, params.scaleW, 1, params.scaleH)
      uetorch.SetActorLocation(occluder2, 300 - 200 * params.scaleW, -350, 20 + occluder2_boxY)
      uetorch.SetActorRotation(occluder2, 0, 0, 90)
   else
      uetorch.DestroyActor(occluder2)
   end

   utils.AddTickHook(StartDown)

   -- spheres
   uetorch.SetActorVisible(sphere, true)

   material.SetActorMaterial(spheres[1], material.sphere_materials[params.sphere1])
   material.SetActorMaterial(spheres[2], material.sphere_materials[params.sphere2])
   material.SetActorMaterial(spheres[3], material.sphere_materials[params.sphere3])

   for i = 1,params.n do
      uetorch.SetActorScale3D(spheres[i], 0.9, 0.9, 0.9)
      if params.left[i] == 1 then
         uetorch.SetActorLocation(spheres[i], -400, -550 - 150 * (i - 1), params.sphereZ[i])
      else
         uetorch.SetActorLocation(spheres[i], 700, -550 - 150 * (i - 1), params.sphereZ[i])
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

local checkData = {}
local saveTick = 1

function block.SaveCheckInfo(dt)
   local aux = {}
   aux.location = uetorch.GetActorLocation(mainActor)
   aux.rotation = uetorch.GetActorRotation(mainActor)
   table.insert(checkData, aux)
   saveTick = saveTick + 1
end


function block.IsPossible()
   return true  -- train always physically possible
end

return block
