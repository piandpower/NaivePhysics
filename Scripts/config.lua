local lfs = require 'lfs'
local json = require 'cjson'
local uetorch = require 'uetorch'

local config = {}


-- Exit the program
local function Exit()
   uetorch.ExecuteConsoleCommand('Exit')
end


-- Pad a number with beginning zeros, return it as a string
function PadZeros(int, n)
   s = tostring(int)
   for _ = 1, n-#s do
      s = '0' .. s
   end
   return s
end


-- Load a JSon file as a table
local function ReadJson(file)
   local f = assert(io.open(file, "rb"))
   local content = f:read("*all")
   f:close()
   return json.decode(content)
end


-- Write a table as a JSon file
local function WriteJson(t, file)
   local f = assert(io.open(file, "wb"))
   f:write(json.encode(t))
   f:close()
end


conf = {
   dataPath = assert(os.getenv('NAIVEPHYSICS_DATA')),
   loadParams = false,
   captureInterval = {
      blockC1_static = 3,
      blockC1_dynamic_1 = 2,
      blockC1_dynamic_2 = 2
   },
   sceneTicks = {
      blockC1_static = 200,
      blockC1_dynamic_1 = 120,
      blockC1_dynamic_2 = 120
   },
   visibilityCheckSize = {
      blockC1_static = 1,
      blockC1_dynamic_1 = 1,
      blockC1_dynamic_2 = 2,
      block1c = 1,
      block5a = 1
   },
   tupleSize = {
      blockC1_static = 4,
      blockC1_dynamic_1 = 4,
      blockC1_dynamic_2 = 4,
      block1c = 4,
      block5a = 2
   },
   blocks = ReadJson(assert(os.getenv('NAIVEPHYSICS_JSON')))
}



function SetIterationsCounter()
   -- count the number of iterations both for train and test. Each
   -- train is always a single iteration, the number of test
   -- iterations depends on the block type
   local train_runs, test_runs, test_iterations = 0, 0, 0
   for block, iters in pairs(config.GetBlocks()) do
      train_runs = train_runs + assert(iters.train)
      test_runs = test_runs + assert(iters.test)
   end

   if test_runs + train_runs == 0 then
      print('no iterations specified, exiting')
      Exit()
   end
   print("generation of " .. test_runs .. " test and " .. train_runs .. " train samples")

   -- put the detail of each iteration into a table
   local n, id_train, id_test, iterationsTable = 1, 1, 1, {}
   for block, iters in pairs(config.GetBlocks()) do
      -- setup train iterations for the current block
      for id = 1, iters.train do
         iterationsTable[n] = {iterationBlock=block, iterationType=-1, iterationId=id_train}
         n = n + 1
         id_train = id_train + 1
      end

      -- setup test iterations for the current block
      local ntypes = config.GetTupleSize(block) + config.GetVisibilityCheckSize(block)
      for id = 1, iters.test do
         for t = ntypes, 1, -1 do
            iterationsTable[n] = {iterationBlock=block, iterationType=t, iterationId=id_test}
            n = n + 1
         end
         id_test = id_test + 1
      end
   end

   WriteJson(iterationsTable, conf.dataPath .. 'iterations_table.json')
   torch.save(conf.dataPath .. 'iterations.t7', "1")
end


function config.GetDataPath()
   return conf.dataPath
end


function config.GetLoadParams()
   return conf.loadParams
end


function config.GetBlockCaptureInterval(block)
   return conf.captureInterval[block]
end


function config.GetBlockTicks(block)
   return conf.sceneTicks[block]
end


function config.GetBlocks()
   return conf.blocks
end


function config.GetTupleSize(block)
   return conf.tupleSize[block]
end


function config.GetVisibilityCheckSize(block)
   return conf.visibilityCheckSize[block]
end


function config.GetBlockSize(block)
   return conf.visibilityCheckSize[block] + conf.tupleSize[block]
end


function config.IsVisibilityCheck(block, iterationType)
   if conf.visibilityCheckSize[block] == 0 then
      return false
   end
   if iterationType > conf.tupleSize[block] then
      return true
   else
      return false
   end
end


local iterationsTable, maxId = nil, nil

function config.GetIterationInfo(iteration)
   if not iterationsTable then
      iterationsTable = ReadJson(conf.dataPath .. 'iterations_table.json')
      maxId = 0
      for k, v in pairs(conf.blocks) do
         maxId = math.max(maxId, v.test, v.train)
      end
   end

   local i = iterationsTable[tonumber(iteration)]
   if not i then
      -- TODO do not exit here but in SetCurrentIteration
      print('no more iterations, exiting')
      Exit()
   else
      subpath = 'train/'
      if i.iterationType ~= -1 then
         subpath = 'test/'
      end

      -- TODO do not create directories here but in SetCurrentIteration
      path = conf.dataPath .. subpath
      lfs.mkdir(path)

      path = path .. PadZeros(i.iterationId, #tostring(maxId)) .. '/'
      lfs.mkdir(path)

      if i.iterationType ~= -1 then
         path = path .. i.iterationType .. '/'
         lfs.mkdir(path)
      end

      return i.iterationId, i.iterationType, i.iterationBlock, path
   end
end


function config.IterationDescription(iterationBlock, iterationId, iterationType)
   local _type = 'train ' .. iterationId
   if iterationType ~= -1 then
      local _n = 1 + config.GetBlockSize(iterationBlock) - iterationType
      _type = 'test ' .. iterationId ..
         ' (' .. _n .. '/' .. config.GetBlockSize(iterationBlock) .. ')'
   end
   return _type .. ' (' .. iterationBlock .. ', ' .. config.GetBlockTicks(iterationBlock) .. ' ticks) '
end


return config
