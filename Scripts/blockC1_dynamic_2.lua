local uetorch = require 'uetorch'
local config = require 'config'
local utils = require 'utils'
local block = {}

local sphere = uetorch.GetActor("Sphere_4")
local wall1 = uetorch.GetActor("Wall_400x200_8")
local wall_boxY
local wall2 = uetorch.GetActor("Wall_400x201_7")
block.actors = {sphere=sphere, wall1=wall1, wall2=wall2}

local iterationId
local iterationType
local iterationBlock
local params = {}
local isHidden1
local isHidden2

local visible1 = true
local visible2 = true
local possible = true
local trick1 = false
local trick2 = false
local canDoTrick2 = false

local camera = uetorch.GetActor("MainMap_CameraActor_Blueprint_C_1")
local floor = uetorch.GetActor('Floor')

local function InitSphere()
	--if iterationType ~= 0 then
	--	uetorch.SetActorVisible(sphere, visible1)
	--end

	if params.left == 1 then
		uetorch.SetActorLocation(sphere, -400, -550, params.sphereZ)
	else
		uetorch.SetActorLocation(sphere, 500, -550, params.sphereZ)
		params.forceX = -params.forceX
	end

	uetorch.AddForce(sphere, params.forceX, params.forceY, params.signZ * params.forceZ)
end

local t_rotation = 0
local t_rotation_change = 0

local function WallRotationDown(dt)
	local angle = (t_rotation - t_rotation_change) * 20
	local succ = uetorch.SetActorRotation(wall1, 0, 0, angle)
	local succ2 = uetorch.SetActorRotation(wall2, 0, 0, angle)
	--uetorch.SetActorLocation(wall1, 50 - 200 * params.scaleW, -350, 20 + math.sin(angle * math.pi / 180) * wall_boxY)
	uetorch.SetActorLocation(wall1, 50 - 200 * params.scaleW, -350, 20 + math.sin((90 - angle) * math.pi / 180) * wall_boxY)
	uetorch.SetActorLocation(wall2, 300 - 200 * params.scaleW, -350, 20 + math.sin(angle * math.pi / 180) * wall_boxY)
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
	local succ = uetorch.SetActorRotation(wall1, 0, 0, 90 - angle)
	local succ2 = uetorch.SetActorRotation(wall2, 0, 0, 90 - angle)
	--uetorch.SetActorLocation(wall1, 50 - 200 * params.scaleW, -350, 20 + math.sin((90 - angle) * math.pi / 180) * wall_boxY)
	uetorch.SetActorLocation(wall1, 50 - 200 * params.scaleW, -350, 20 + math.sin(angle * math.pi / 180) * wall_boxY)
	uetorch.SetActorLocation(wall2, 300 - 200 * params.scaleW, -350, 20 + math.sin((90 - angle) * math.pi / 180) * wall_boxY)
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

		if not decided and isHidden[step] then
			decided = true
			--MoveSphere(pos2)
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
				ground = 1,--math.random(#utils.ground_materials),
				sphereZ = 200,--70 + math.random(200),
				forceX = 2500000,--math.random(800000, 1100000),
				forceY = 0,
				forceZ = math.random(800000, 1000000),
				signZ = 1,--2 * math.random(2) - 3,
				left = 1,--math.random(0,1),
				framesStartDown = math.random(5),
				framesRemainUp = math.random(5),
				scaleW = 0.5,--1 - 0.5 * math.random(),
				scaleH = 1 - 0.4 * math.random()
			}

			torch.save(config.GetDataPath() .. iterationId .. '/params.t7', params)
		end

		uetorch.DestroyActor(wall2)
	else
		params = torch.load(config.GetDataPath() .. iterationId .. '/params.t7')

		if iterationType == 5 then
			uetorch.DestroyActor(wall1)
		else
			isHidden = torch.load(config.GetDataPath() .. iterationId .. '/hidden_0.t7')
			isHidden2 = torch.load(config.GetDataPath() .. iterationId .. '/hidden_5.t7')
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
	end

	mainActor = sphere
end

function block.RunBlock()
	utils.SetActorMaterial(floor, utils.ground_materials[params.ground])
	uetorch.AddTickHook(StartDown)
	uetorch.SetActorLocation(camera, 150, 30, 80)

	uetorch.SetActorScale3D(wall1, params.scaleW, 1, params.scaleH)
	uetorch.SetActorScale3D(wall2, params.scaleW, 1, params.scaleH)
	wall_boxY = uetorch.GetActorBounds(wall1)['boxY']
	uetorch.SetActorLocation(wall1, 50 - 200 * params.scaleW, -350, 20 + wall_boxY)
	uetorch.SetActorLocation(wall2, 300 - 200 * params.scaleW, -350, 20 + wall_boxY)
	uetorch.SetActorRotation(wall1, 0, 0, 90)
	uetorch.SetActorRotation(wall2, 0, 0, 90)

	InitSphere()
end

function block.IsPossible()
	return possible
end

return block