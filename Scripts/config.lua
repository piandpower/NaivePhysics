config = {
	--seed = 0,
	dataPath = '/home/mario/Documents/Unreal Projects/NaivePhysics/data/', -- don't override anything important
	screenCaptureInterval = 0.125,
	sceneTime = 15.0,
	stride = 5,
	iterations = 10
	--loadTime = 2.0, -- 1s
	--resolution = 'nil', -- this gets interpreted by the blueprints as NULL, but you can still override
}

function getDataPath()
	return config['dataPath']
end

function getScreenCaptureInterval()
	return config['screenCaptureInterval']
end

function getSceneTime()
	return config['sceneTime']
end

function getStride()
	return config['stride']
end

function getIterations()
	return config['iterations']
end