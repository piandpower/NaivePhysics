local config = {}

conf = {
	--seed = 0,
	dataPath = '/home/mario/Documents/Unreal Projects/NaivePhysics/data/', -- don't override anything important
	screenCaptureInterval = 0.125,
	sceneTime = {
		block1a_static = 10.0,
		block1a_dynamic = 11.0,
		block1c = 10.0,
		block5a = 7.0
	},
	tupleSize = {
		block1a_static = 4,
		block1a_dynamic = 4,
		block1c = 4,
		block5a = 2
	},
	stride = 4,
	save = true,
	blocks = {
		{
			iterations = 1,
			block = 'block1a_static'
		},
		{
			iterations = 1,
			block = 'block1a_dynamic'
		},
		{
			iterations = 1,
			block = 'block1c'
		},
		{
			iterations = 3,
			block = 'block5a'
		}
	}
	--loadTime = 2.0, -- 1s
	--resolution = 'nil', -- this gets interpreted by the blueprints as NULL, but you can still override
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
		local cur = v['iterations'] * (1 + conf['tupleSize'][ v['block'] ])
		if iteration <= cur then
			return conf['sceneTime'][ v['block'] ]
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
		iterations = iterations + v['iterations'] * (1 + conf['tupleSize'][ v['block'] ])
	end
	print("iterations =", iterations)
	return iterations
end

function config.GetSave()
	return conf['save']
end

function config.GetIterationInfo(iteration)
	iteration = tonumber(iteration)
	local iterationId = 0
	for k, v in ipairs(conf['blocks']) do
		local cur = v['iterations'] * (1 + conf['tupleSize'][ v['block'] ])
		if iteration <= cur then
			iterationId = iterationId + math.ceil(iteration / (1 + conf['tupleSize'][ v['block'] ]))
			local iterationType = iteration % (1 + conf['tupleSize'][ v['block'] ])
			return iterationId, iterationType, v['block']
		end
		iteration = iteration - cur
		iterationId = iterationId + v['iterations']
	end
	print("ERROR: Invalid Iteration")
	return nil
end

return config