local uetorch = require 'uetorch'
local config = require 'config'
local utils = require 'utils'
local material = require 'material'
local block = {}

local camera = uetorch.GetActor("MainMap_CameraActor_Blueprint_C_0")
local floor = uetorch.GetActor('Floor')
local sphere = uetorch.GetActor("Sphere_4")
local sphere2 = uetorch.GetActor("Sphere9_4")
local sphere3 = uetorch.GetActor("Sphere10_7")
local spheres = {sphere, sphere2, sphere3}
local wall = uetorch.GetActor("Wall_400x200_8")
local wall_boxY
block.actors = {wall=wall}

local iterationId, iterationType, iterationBlock, iterationPath
local params = {}
local isHidden

local visible1 = true
local visible2 = true
local possible = true
local trick1 = false
local trick2 = false
local canDoTrick2 = false

local t_rotation = 0
local t_rotation_change = 0
local cont = 1

local RemainDown

local function WallRotationDown(dt)
   local angle = (t_rotation - t_rotation_change) * 20 * 0.125

   uetorch.SetActorRotation(wall, 0, 0, angle)

   uetorch.SetActorLocation(
      wall, 100 - 200 * params.scaleW, -350,
      20 + math.sin(angle * math.pi / 180) * wall_boxY)

   if angle >= 90 then
      utils.RemoveTickHook(WallRotationDown)
      t_rotation_change = t_rotation

      if cont == 1 then
         uetorch.AddTickHook(RemainDown)
         canDoTrick2 = true
         cont = 2
      end
   end
   t_rotation = t_rotation + dt
end

local framesUp = 0

local function RemainUp(dt)
   framesUp = framesUp + 1
   if framesUp == params.framesRemainUp then
      framesUp = 0
      utils.RemoveTickHook(RemainUp)
      utils.AddTickHook(WallRotationDown)
   end
end

local function WallRotationUp(dt)
   local angle = (t_rotation - t_rotation_change) * 20 * 0.125
   uetorch.SetActorRotation(wall, 0, 0, 90 - angle)
   uetorch.SetActorLocation(wall, 100 - 200 * params.scaleW, -350, 20 + math.sin((90 - angle) * math.pi / 180) * wall_boxY)
   if angle >= 90 then
      utils.RemoveTickHook(WallRotationUp)
      utils.AddTickHook(RemainUp)
      t_rotation_change = t_rotation
   end
   t_rotation = t_rotation + dt
end

local framesDown = 0

RemainDown = function(dt)
   framesDown = framesDown + 1
   if framesDown == params.framesStartDown then
      framesDown = 0
      utils.RemoveTickHook(RemainDown)
      utils.AddTickHook(WallRotationUp)
   end
end

local tCheck, tLastCheck = 0, 0
local step = 0

local function Trick(dt)
   if tCheck - tLastCheck >= config.GetBlockCaptureInterval(iterationBlock) then
      step = step + 1

      if not trick1 and isHidden[step] then
         trick1 = true
         uetorch.SetActorVisible(spheres[params.index], visible2)
      end

      if trick1 and canDoTrick2 and not trick2 and isHidden[step] then
         trick2 = true
         uetorch.SetActorVisible(spheres[params.index], visible1)
      end

      tLastCheck = tCheck
   end
   tCheck = tCheck + dt
end


-- Return random parameters for the C1 static block
local function GetRandomParams()
   local params = {
      ground = math.random(#material.ground_materials),
      framesStartDown = math.random(20),
      framesRemainUp = math.random(20),
      scaleW = 1 - 0.4 * math.random(),
      scaleH = 1 - 0.5 * math.random(),
      n = math.random(1,3)
   }
   params.index = math.random(1, params.n)

   return params
end


local mainActor

function block.MainActor()
   return mainActor
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

   visible1 = RandomBool()
   visible2 = visible1
   possible = true

   mainActor = spheres[params.index]
   for i = 1,params.n do
      block.actors['sphere' .. i] = spheres[i]
   end
end


function block.SetBlockTest(currentIteration)
   iterationId, iterationType, iterationBlock, iterationPath =
      config.GetIterationInfo(currentIteration)

   local file = io.open (config.GetDataPath() .. 'output.txt', "a")
   file:write(currentIteration .. ", " ..
                 iterationId .. ", " ..
                 iterationType .. ", " ..
                 iterationBlock .. "\n")
   file:close()

   if iterationType == 5 then
      if config.GetLoadParams() then
         params = ReadJson(iterationPath .. '../params.json')
      else
         params = GetRandomParams()
         WriteJson(params, iterationPath .. '../params.json')
      end

      for i = 1,3 do
         if i ~= params.index then
            uetorch.DestroyActor(spheres[i])
         end
      end
   else
      isHidden = torch.load(iterationPath .. '../hidden_5.t7')
      params = ReadJson(iterationPath .. '../params.json')
      utils.AddTickHook(Trick)

      if iterationType == 1 then
         visible1 = false
         visible2 = false
         possible = true
      elseif iterationType == 2 then
         visible1 = true
         visible2 = true
         possible = true
      elseif iterationType == 3 then
         visible1 = false
         visible2 = true
         possible = false
      elseif iterationType == 4 then
         visible1 = true
         visible2 = false
         possible = false
      end
   end

   mainActor = spheres[params.index]
   for i = 1,params.n do
      block.actors['sphere' .. i] = spheres[i]
   end
end

function block.RunBlock()
   material.SetActorMaterial(floor, material.ground_materials[params.ground])
   utils.AddTickHook(RemainDown)
   uetorch.SetActorLocation(camera, 100, 30, 80)

   uetorch.SetActorScale3D(wall, params.scaleW, 1, params.scaleH)
   wall_boxY = uetorch.GetActorBounds(wall).boxY
   uetorch.SetActorRotation(wall, 0, 0, 90)
   uetorch.SetActorLocation(wall, 100 - 200 * params.scaleW, -350, 20 + wall_boxY)

   uetorch.SetActorLocation(sphere, 150, -550, 70)
   uetorch.SetActorVisible(spheres[params.index], visible1)
   if params.n >= 2 then
      uetorch.SetActorLocation(sphere2, 40,-550, 70)
   end
   if params.n >= 3 then
      uetorch.SetActorLocation(sphere3, 260,-550, 70)
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

local maxDiff = 1e-6

function block.Check()
   local status = true
   torch.save(iterationPath .. '../check_' .. iterationType .. '.t7', checkData)

   if iterationType == 1 then
      local file = io.open(config.GetDataPath() .. 'output.txt', "a")

      local foundHidden = false
      for i = 1,#isHidden do
         if isHidden[i] then
            foundHidden = true
         end
      end

      if not foundHidden then
         file:write("Iteration check failed on condition 1\n")
         status = false
      end

      if status then
         local iteration = utils.GetCurrentIteration()
         local size = config.GetBlockSize(iterationBlock)
         local ticks = config.GetBlockTicks(iterationBlock)
         local allData = {}

         for i = 1,size do
            local aux = torch.load(iterationPath .. '../check_' .. i .. '.t7')
            allData[i] = aux
         end

         for t = 1,ticks do
            for i = 2,size do
               -- check location values
               if(math.abs(allData[i][t].location.x - allData[1][t].location.x) > maxDiff) then
                  status = false
               end
               if(math.abs(allData[i][t].location.y - allData[1][t].location.y) > maxDiff) then
                  status = false
               end
               if(math.abs(allData[i][t].location.z - allData[1][t].location.z) > maxDiff) then
                  status = false
               end
               -- check rotation values
               if(math.abs(allData[i][t].rotation.pitch - allData[1][t].rotation.pitch) > maxDiff) then
                  status = false
               end
               if(math.abs(allData[i][t].rotation.yaw - allData[1][t].rotation.yaw) > maxDiff) then
                  status = false
               end
               if(math.abs(allData[i][t].rotation.roll - allData[1][t].rotation.roll) > maxDiff) then
                  status = false
               end
            end
         end

         if not status then
            file:write("Iteration check failed on condition 2\n")
         end
      end

      if status then
         file:write("Iteration check succeeded\n")
      else
         file:write("Iteration check failed\n")
      end
      file:close()
   end

   utils.UpdateIterationsCounter(status)
end

function block.IsPossible()
   return possible
end

return block
