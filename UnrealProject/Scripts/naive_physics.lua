local uetorch = require 'uetorch'
local paths = require 'paths'
local image = require 'image'
local posix = require 'posix'
local config = require 'config'
local utils = require 'utils'
local block

-- Return unique elements of `t` (equivalent to set(t) in
-- Python). From https://stackoverflow.com/questions/20066835
function Unique(t)
   local hash, res = {}, {}
   t:apply(
      function(x) if not hash[x] then res[#res+1] = x; hash[x] = true end end)
   return res
end


-- Force the rendered image to be 288x288
function SetResolution(dt)
   uetorch.SetResolution(288, 288)
end


-- setup the random seed
local seed = os.getenv('NAIVEPHYSICS_SEED') or os.time()
math.randomseed(seed)
posix.setenv('NAIVEPHYSICS_SEED', seed + 1)

-- Setup the dry mode: if active, do not capture any screenshot
local dry_run = os.getenv('NAIVEPHYSICS_DRY') or false

-- functions called from MainMap_CameraActor_Blueprint
GetCurrentIteration = utils.GetCurrentIteration
RunBlock = nil

-- replace uetorch's Tick function
Tick = utils.Tick
uetorch.SetTickDeltaBounds(1/8, 1/8)


local camera = assert(uetorch.GetActor("Camera"))
local iterationId, iterationType, iterationBlock, iterationPath
local screenTable, depthTable = {}, {}
local tLastSaveScreen = 0
local tSaveScreen = 0
local step = 0
local max_depth = 0


-- Save screenshot, object masks and depth field into png images
local function SaveScreen(dt)
   if tSaveScreen - tLastSaveScreen >= config.GetBlockCaptureInterval(iterationBlock) then
      step = step + 1
      local stepStr = PadZeros(step, 3)

      -- save the screen
      local file = iterationPath .. 'scene/scene_' .. stepStr .. '.png'
      local i1 = uetorch.Screen()
      if i1 then
         image.save(file, i1)
      end

      -- active and inactive actors in the scene are required for
      -- depth and mask
      local active_actors, inactive_actors, _ = block.MaskingActors()

      -- compute the depth field and objects segmentation masks
      local depth_file = iterationPath .. 'depth/depth_' .. stepStr .. '.png'
      local mask_file = iterationPath .. 'mask/mask_' .. stepStr .. '.png'
      local i2, i3 = uetorch.CaptureDepthAndMasks(
         camera, active_actors, inactive_actors)

      -- save the depth field
      if i2 then
         -- normalize the depth field in [0, 1]. TODO max depth is the
         -- horizon line, which is assumed to be visible at the first
         -- tick. If this is not the case, the following normalization
         -- isn't correct as the max_depth varies accross ticks.
         max_depth = math.max(i2:max(), max_depth)
         i2:apply(function(x) return x / max_depth end)
         image.save(depth_file, i2)
      end

      -- save the objects segmentation masks
      if i3 then
         local max1 = i3:max()
         local max2 = block.MaxActors()

         i3 = i3:float()  -- cast from int to float for normalization
         i3:apply(function(x) return x / block.MaxActors() end)
         local max3 = i3:max()

         for k, u in pairs(Unique(i3)) do
            print(u .. '\t' .. math.floor(u*255))
         end
         print('in mask: ' .. max1 .. ' ' .. max2 .. ' ' .. max3)

         image.save(mask_file, i3)
      end

      tLastSaveScreen = tSaveScreen
   end
   tSaveScreen = tSaveScreen + dt
end


local data = {}
local tSaveText = 0
local tLastSaveText = 0

local function SaveStatusToTable(dt)
   local aux = {t = tSaveText}
   if tSaveText - tLastSaveText >= config.GetBlockCaptureInterval(iterationBlock) then
      for k, v in pairs(block.actors) do
         aux[k] = {
            location = uetorch.GetActorLocation(v),
            rotation = uetorch.GetActorRotation(v)
         }
      end
      table.insert(data, aux)

      tLastSaveText = tSaveText
   end
   tSaveText = tSaveText + dt
end


local visibilityTable = {}
local tCheck, tLastCheck = 0, 0
local step = 0
local hidden = false
local isHidden = {}

local function CheckVisibility(dt)
   if tCheck - tLastCheck >= config.GetBlockCaptureInterval(iterationBlock) then
      step = step + 1
      local stepStr = PadZeros(step, 3)

      local actors = {block.MainActor()}
      local i2 = uetorch.ObjectSegmentation(actors)

      if i2 then
         if torch.max(i2) == 0 then
            hidden = true
         else
            hidden = false
         end
      end

      table.insert(isHidden, hidden)
      tLastCheck = tCheck
   end
   tCheck = tCheck + dt
end

local function SaveData()
   if config.IsVisibilityCheck(iterationBlock, iterationType) then
      local nHidden = #isHidden

      for k = 1,nHidden do
         if not isHidden[k] then
            break
         else
            isHidden[k] = false
         end
      end

      for k = nHidden,1,-1 do
         if not isHidden[k] then
            break
         else
            isHidden[k] = false
         end
      end

      torch.save(iterationPath .. '../hidden_' .. iterationType .. '.t7', isHidden)
   else
      -- TODO need to be refactored, better if we have a json
      -- structure as well
      local filename = iterationPath .. 'status.txt'
      local file = assert(io.open(filename, "w"))
      file:write("block = " .. iterationBlock .. "\n")

      if block.IsPossible() then
         file:write("possible = true\n")
      else
         file:write("possible = false\n")
      end

      local floor = uetorch.GetActor('Floor')
      local bounds = uetorch.GetActorBounds(floor)
      local minx = bounds["x"] - bounds["boxX"]
      local maxx = bounds["x"] + bounds["boxX"]
      local miny = bounds["y"] - bounds["boxY"]
      local maxy = bounds["y"] + bounds["boxY"]
      file:write("minX = " .. minx .. " maxX = " .. maxx ..
                    " minY = " .. miny .. " maxY = " .. maxy .. "\n")

      file:write("camera:\n")
      local cam_loc = uetorch.GetActorLocation(camera)
      local cam_rot = uetorch.GetActorRotation(camera)
      file:write("x = " .. cam_loc.x .. " y = " .. cam_loc.y .. " z = " .. cam_loc.z .. "\n")
      file:write("pitch = " .. cam_rot.pitch .. " roll = " .. cam_rot.roll ..
                    " yaw = " .. cam_rot.yaw .. "\n")

      file:write("masks:\n")
      local _, _, masks = block.MaskingActors()
      for n, m in pairs(masks) do
         file:write(n .. ' = ' .. m .. ' ')
      end
      file:write('\n')

      local nactors = 0
      for k,v in pairs(block.actors) do
         nactors = nactors + 1
      end
      file:write("number of actors = " .. nactors .. "\n")

      for k, v in ipairs(data) do
         file:write("step = " .. k .. "\n")
         file:write("t = " .. v["t"] .. "\n")

         for k2,v2 in pairs(block.actors) do
            file:write("actor = " .. k2 .. "\n")
            local loc = v[k2]["location"]
            file:write("x = " .. loc["x"] .. " y = " .. loc["y"] .. " z = " .. loc["z"] .. "\n")
            local rot = v[k2]["rotation"]
            file:write("pitch = " .. rot["pitch"] ..
                          " roll = " .. rot["roll"] ..
                          " yaw = " .. rot["yaw"] .. "\n")
         end
      end
      file:close()
   end
end


function SetCurrentIteration()
   local currentIteration = utils.GetCurrentIteration()
   iterationId, iterationType, iterationBlock, iterationPath =
      config.GetIterationInfo(currentIteration)

   local descr = 'running ' .. config.IterationDescription(iterationBlock, iterationId, iterationType)
   print(descr)

   -- create subdirectories for this iteration
   paths.mkdir(iterationPath)
   paths.mkdir(iterationPath .. 'mask')
   if not config.IsVisibilityCheck(iterationBlock, iterationType) then
      paths.mkdir(iterationPath .. 'scene')
      paths.mkdir(iterationPath .. 'depth')
   end

   -- prepare the block for either train or test
   -- if iterationType == -1 then -- train
   --    block = require('blockC1_train')
   -- else
   block = require(iterationBlock)
   -- end
   block.SetBlock(currentIteration)

   -- RunBlock will be called from blueprint
   RunBlock = function() return block.RunBlock() end

   utils.SetTicksRemaining(config.GetBlockTicks(iterationBlock))

   -- BUGFIX tweak to force the first iteration to be at the required
   -- resolution
   utils.AddTickHook(SetResolution)


   if config.IsVisibilityCheck(iterationBlock, iterationType) then
      utils.AddTickHook(CheckVisibility)
   else
      -- save screen, depth and mask
      if not dry_run then
         utils.AddTickHook(SaveScreen)
      end
   end
   utils.AddTickHook(SaveStatusToTable)
   utils.AddEndTickHook(SaveData)

   if iterationType == -1 then  -- train
      utils.AddEndTickHook(
         function(dt) return utils.UpdateIterationsCounter(true) end)
   else  -- test
      utils.AddTickHook(block.SaveCheckInfo)
      utils.AddEndTickHook(block.Check)
   end
end
