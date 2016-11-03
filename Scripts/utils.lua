local uetorch = require 'uetorch'
local config = require 'config'
local utils = {}


function utils.GetCurrentIteration()
   local iteration = torch.load(conf.dataPath .. 'iterations.t7')
   return iteration
end


local function GetFirstIterationInBlock(iteration)
   local iterationId, iterationType, block = config.GetIterationInfo(iteration)
   return iteration - config.GetBlockSize(block) + iterationType
end


function utils.UpdateIterationsCounter(check)
   local iteration = utils.GetCurrentIteration()
   local iterationId, iterationType, iterationBlock, iterationPath
      = config.GetIterationInfo(iteration)

   if check then
      iteration = iteration + 1
   else
      print('check failed, trying new parameters')
      iteration = GetFirstIterationInBlock(iteration)
   end

   -- ensure the iteration exists in iterationsTable
   if not iterationsTable[tonumber(iteration)] then
      print('no more iteration, exiting')
      uetorch.ExecuteConsoleCommand('Exit')
   end

   torch.save(conf.dataPath .. 'iterations.t7', iteration)
end


local TickHooks = {}
local EndTickHooks = {}

-- add a tick 'hook' function f called at each game loop tick
-- tick hooks should take a single argument (dt) and return nothing.
function utils.AddTickHook(f)
   table.insert(TickHooks, f)
end


function utils.AddEndTickHook(f)
   table.insert(EndTickHooks, f)
end


-- remove the function f from the set of tick hooks
function utils.RemoveTickHook(f)
   for i = #TickHooks, 1, -1 do
      if TickHooks[i] == f then
         table.remove(TickHooks, i)
      end
   end
end


local TicksRemaining

function utils.SetTicksRemaining(ticks)
   TicksRemaining = ticks
end


local tickCount = 1
local foundError = false

function utils.Tick(dt)
   tickCount = tickCount + 1
   dt = 1
   if TicksRemaining then
      TicksRemaining = TicksRemaining - dt
      if TicksRemaining < 0 then
         TicksRemaining = nil
         for ii, hook in ipairs(EndTickHooks) do
            hook()
         end
         uetorch.ExecuteConsoleCommand("RestartLevel")
      else
         for ii, hook in ipairs(TickHooks) do
            hook(dt)
         end
      end
   elseif not foundError then
      foundError = true
   end
end

return utils
