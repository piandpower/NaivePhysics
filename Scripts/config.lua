local config = {}

conf = {
	--seed = 0,
	dataPath = '/home/mario/Documents/Unreal Projects/NaivePhysics/data/', -- don't override anything important
	screenCaptureInterval = 0.125,
	sceneTime = 15.0,
	stride = 4,
	iterations = 2,
	save = true
	--loadTime = 2.0, -- 1s
	--resolution = 'nil', -- this gets interpreted by the blueprints as NULL, but you can still override
}

function config.GetDataPath()
	return conf['dataPath']
end

function config.GetScreenCaptureInterval()
	return conf['screenCaptureInterval']
end

function config.GetSceneTime()
	return conf['sceneTime']
end

function config.GetStride()
	return conf['stride']
end

function GetIterations()
	return conf['iterations']
end

function config.Save()
	return conf['save']
end

return config