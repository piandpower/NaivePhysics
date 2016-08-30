local uetorch = require 'uetorch'
local config = require 'config'
local utils = require 'utils'
local block = {}

local camera = uetorch.GetActor("MainMap_CameraActor_Blueprint_C_1")
local floor = uetorch.GetActor('Floor')
local sphere = uetorch.GetActor("Sphere_4")
local sphere2 = uetorch.GetActor("Sphere9_4")
local sphere3 = uetorch.GetActor("Sphere10_7")
local spheres = {sphere, sphere2, sphere3}
local wall = uetorch.GetActor("Wall_400x200_8")
local wall_boxY
block.actors = {sphere=sphere, wall=wall}

local iterationId
local iterationType
local iterationBlock
local params = {}
local isHidden

local visible1 = true
local visible2 = true
local possible = true
local trick = false

local function InitSphere()
	if iterationType ~= 0 then
		uetorch.SetActorVisible(spheres[params.index], visible1)
	end

	for i = 1,3 do
		uetorch.SetActorScale3D(spheres[i], 0.9, 0.9, 0.9)
		if params.left[i] == 1 then
			uetorch.SetActorLocation(spheres[i], -400, -350 - 120 * (i - 1), params.sphereZ[i])
		else
			uetorch.SetActorLocation(spheres[i], 500, -350 - 120 * (i - 1), params.sphereZ[i])
			params.forceX[i] = -params.forceX[i]
		end

		uetorch.AddForce(spheres[i], params.forceX[i], params.forceY[i], params.signZ[i] * params.forceZ[i])
	end
end

local t_rotation = 0
local t_rotation_change = 0

local function WallRotationDown(dt)
	local angle = (t_rotation - t_rotation_change) * 20
	uetorch.SetActorRotation(wall, 0, 0, angle)
	uetorch.SetActorLocation(wall, 100 - 200 * params.scaleW, -250, 20 + math.sin(angle * math.pi / 180) * wall_boxY)
	if angle >= 90 then
		uetorch.RemoveTickHook(WallRotationDown)
		t_rotation_change = t_rotation
	end
	t_rotation = t_rotation + dt
end

local function RemainUp(dt)
	params.framesRemainUp = params.framesRemainUp - 1
	if params.framesRemainUp == 0 then
		uetorch.RemoveTickHook(RemainUp)
		uetorch.AddTickHook(WallRotationDown)
	end
end

local function WallRotationUp(dt)
	local angle = (t_rotation - t_rotation_change) * 20
	uetorch.SetActorRotation(wall, 0, 0, 90 - angle)
	uetorch.SetActorLocation(wall, 100 - 200 * params.scaleW, -250, 20 + math.sin((90 - angle) * math.pi / 180) * wall_boxY)
	if angle >= 90 then
		uetorch.RemoveTickHook(WallRotationUp)
		uetorch.AddTickHook(RemainUp)
		t_rotation_change = t_rotation
	end
	t_rotation = t_rotation + dt
end

local function StartDown(dt)
	params.framesStartDown = params.framesStartDown - 1
	if params.framesStartDown == 0 then
		uetorch.RemoveTickHook(StartDown)
		uetorch.AddTickHook(WallRotationUp)
	end
end

local tCheck, tLastCheck = 0, 0
local step = 0

local function Trick(dt)
	if tCheck - tLastCheck >= config.GetScreenCaptureInterval() then
		step = step + 1

		if not trick and isHidden[step] then
			trick = true
			uetorch.SetActorVisible(spheres[params.index], visible2)
		end

		tLastCheck = tCheck
	end
	tCheck = tCheck + dt
end

local mainActor

function block.MainActor()
	return mainActor
end

function block.SetBlock(currentIteration)
	iterationId, iterationType, iterationBlock = config.GetIterationInfo(currentIteration)

	if iterationType == 0 then
		if config.GetLoadParams() then
			params = torch.load(config.GetDataPath() .. iterationId .. '/params.t7')
		else
			params = {
				ground = math.random(#utils.ground_materials),
				sphereZ = {
					70 + math.random(200),
					70 + math.random(200),
					70 + math.random(200)
				},
				forceX = {
					math.random(800000, 1100000),
					math.random(800000, 1100000),
					math.random(800000, 1100000)
				},
				forceY = {0, 0, 0},
				forceZ = {
					math.random(800000, 1000000),
					math.random(800000, 1000000),
					math.random(800000, 1000000)
				},
				signZ = {
					2 * math.random(2) - 3,
					2 * math.random(2) - 3,
					2 * math.random(2) - 3
				},
				left = {
					math.random(0,1),
					math.random(0,1),
					math.random(0,1)
				},
				framesStartDown = math.random(5),
				framesRemainUp = math.random(5),
				scaleW = 0.5,--0 - 0.5 * math.random(),
				scaleH = 1 - 0.5 * math.random(),
				n = math.random(1,3),
			}

			params.index = math.random(1, params.n)
			torch.save(config.GetDataPath() .. iterationId .. '/params.t7', params)
		end

		for i = 1,3 do
			if i ~= params.index then
				uetorch.DestroyActor(spheres[i])
			end
		end
	else
		isHidden = torch.load(config.GetDataPath() .. iterationId .. '/hidden.t7')
		params = torch.load(config.GetDataPath() .. iterationId .. '/params.t7')
		uetorch.AddTickHook(Trick)

		if iterationType == 1 then
			visible1 = false
			visible2 = false
			possible = true
		elseif iterationType == 2 then
			visible1 = true
			visible2 = true
			possible = true
		elseif iterationType == 3 then
			visible1 = false
			visible2 = true
			possible = false
		elseif iterationType == 4 then
			visible1 = true
			visible2 = false
			possible = false
		end
	end

	mainActor = spheres[params.index]
end

function block.RunBlock()
	utils.SetActorMaterial(floor, utils.ground_materials[params.ground])
	uetorch.AddTickHook(StartDown)
	uetorch.SetActorLocation(camera, 100, 30, 80)

	uetorch.SetActorScale3D(wall, params.scaleW, 1, params.scaleH)
	wall_boxY = uetorch.GetActorBounds(wall)['boxY']
	uetorch.SetActorLocation(wall, 100 - 200 * params.scaleW, -250, 20 + wall_boxY)
	uetorch.SetActorRotation(wall, 0, 0, 90)

	InitSphere()
end

function block.IsPossible()
	return possible
end

return block