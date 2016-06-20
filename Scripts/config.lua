local config = {}

conf = {
	--seed = 0,
	dataPath = '/home/mario/Documents/Unreal Projects/NaivePhysics/data/', -- don't override anything important
	screenCaptureInterval = 0.125,
	sceneTime = {
		block1a_static = 10.0,
		block1a_dynamic = 12.0,
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
		if iteration <= v['iterations'] then
			return conf['sceneTime'][ v['block'] ]
		end
		iteration = iteration -  v['iterations']
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
		iterations = iterations + v['iterations']
	end
	print("iterations =", iterations)
	return iterations
end

function config.GetSave()
	return conf['save']
end

function config.GetBlock(iteration)
	iteration = tonumber(iteration)
	for k, v in ipairs(conf['blocks']) do
		if iteration <= v['iterations'] then
			return v['block']
		end
		iteration = iteration -  v['iterations']
	end
	print("ERROR: Invalid Iteration")
	return nil
end

return config