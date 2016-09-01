local config = {}

conf = {
	dataPath = '/home/mario/Documents/Unreal Projects/NaivePhysics/data/', -- don't override anything important
	loadParams = false,
	screenCaptureInterval = 0.125,
	sceneTime = {
		blockC1_static = 25.0,
		blockC1_dynamic_1 = 15.0,
		blockC1_dynamic_2 = 15.0,
		block1c = 10.0,
		block5a = 7.0
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
	stride = 1,
	save = true,
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

function config.GetDataPath()
	return conf['dataPath']
end

function config.GetScreenCaptureInterval()
	return conf['screenCaptureInterval']
end

function config.GetSceneTime(iteration)
	iteration = tonumber(iteration)
	for k, v in ipairs(conf['blocks']) do
		local block = v['block']
		local cur = v['iterations'] * (conf['tupleSize'][block] + conf['visibilityCheckSize'][block])

		if iteration <= cur then
			return conf['sceneTime'][block]
		end

		iteration = iteration - cur
	end
	print("ERROR: Invalid Iteration")
	return nil
end

function config.GetStride()
	return conf['stride']
end

function GetIterations()
	local iterations = 0
	for k, v in ipairs(conf['blocks']) do
		local block = v['block']
		iterations = iterations + v['iterations'] * (conf['tupleSize'][block] + conf['visibilityCheckSize'][block])
	end
	print("iterations =", iterations)
	return iterations
end

function config.GetSave()
	return conf['save']
end

function config.GetLoadParams()
	return conf['loadParams']
end

function config.GetIterationInfo(iteration)
	iteration = tonumber(iteration)
	local iterationId = 0
	for k, v in ipairs(conf['blocks']) do
		local block = v['block']
		local block_len = conf['tupleSize'][block] + conf['visibilityCheckSize'][block]
		local cur = v['iterations'] * block_len

		if iteration <= cur then
			iterationId = iterationId + math.ceil(iteration / block_len)
			local iterationType = iteration % block_len
			return iterationId, iterationType, block
		end

		iteration = iteration - cur
		iterationId = iterationId + v['iterations']
	end
	print("ERROR: Invalid Iteration")
	return nil
end

function config.IsVisibilityCheck(block, iterationType)
	if iterationType == 0 or iterationType > conf['tupleSize'][block] then
		return true
	else
		return false
	end
end

return config