local config = {}

conf = {
	dataPath = '/home/mario/Documents/Unreal Projects/NaivePhysics/data/', -- don't override anything important
	loadParams = false,
	stitch = false,
	stride = 1,
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
	blocks = {
		{
			iterations = 1,
			block = 'blockC1_static'
		},
		{
			iterations = 1,
			block = 'blockC1_dynamic_1'
		},
		{
			iterations = 1,
			block = 'blockC1_dynamic_2'
		},
		{
			iterations = 0,
			block = 'block1c'
		},
		{
			iterations = 0,
			block = 'block5a'
		}
	}
}

function SetIterationsCounter()
	local iterations = 0
	for k, v in ipairs(conf.blocks) do
		local block = v.block
		iterations = iterations + v.iterations * (conf.tupleSize[block] + conf.visibilityCheckSize[block])
	end
	print("iterations = " .. iterations)
	local file = conf.dataPath .. 'iterations.t7'
	torch.save(file, iterations)
	return iterations
end

function config.GetDataPath()
	return conf.dataPath
end

function config.GetLoadParams()
	return conf.loadParams
end

function config.GetStitch()
	return conf.stitch
end

function config.GetStride()
	return conf.stride
end

function config.GetBlockCaptureInterval(block)
	return conf.captureInterval[block]
end

function config.GetBlockTicks(block)
	return conf.sceneTicks[block]
end

function config.GetIterationInfo(iteration)
	iteration = tonumber(iteration)
	local iterationId = 0
	for k, v in ipairs(conf.blocks) do
		local block = v.block
		local block_len = conf.tupleSize[block] + conf.visibilityCheckSize[block]
		local cur = v.iterations * block_len

		if iteration <= cur then
			iterationId = iterationId + math.ceil(iteration / block_len)
			local iterationType = iteration % block_len
			if iterationType == 0 then
				iterationType = block_len
			end
			return iterationId, iterationType, block
		end

		iteration = iteration - cur
		iterationId = iterationId + v.iterations
	end
	print("ERROR: Invalid Iteration")
	return nil
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

return config