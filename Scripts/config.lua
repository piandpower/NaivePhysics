local config = {}

conf = {
	--seed = 0,
	dataPath = '/home/mario/Documents/Unreal Projects/NaivePhysics/data/', -- don't override anything important
	screenCaptureInterval = 0.125,
	sceneTime = 10.0,
	stride = 4,
	iterations = 1
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

local function GetIterations()
	return conf['iterations']
end

return config