local uetorch = require 'uetorch'
local config = require 'config'
local utils = require 'utils'
local block = {}

local sphere = uetorch.GetActor("Sphere_4")
local wall1 = uetorch.GetActor("Wall_400x200_8")
local wall2 = uetorch.GetActor("Wall_400x201_7")
block.actors = {sphere=sphere, wall1=wall1, wall2=wall2}

local pos1 = 1
local pos2 = 1
local possible = true

local isHidden
local params = {}

local iterationId
local iterationType
local iterationBlock

local camera = uetorch.GetActor("MainMap_CameraActor_Blueprint_C_1")
local floor = uetorch.GetActor('Floor')

local function MoveSphere(pos)
	if pos == 1 then
		uetorch.SetActorLocation(sphere, -50, -550, 70)
	else
		uetorch.SetActorLocation(sphere, 320, -550, 70)
	end
end

local t_rotation = 0
local t_rotation_change = 0

local function WallRotationDown(dt)
	local angle = (t_rotation - t_rotation_change) * 20
	local succ = uetorch.SetActorRotation(wall1, 0, 0, angle)
	local succ2 = uetorch.SetActorRotation(wall2, 0, 0, angle)
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

local function MagicTrick(dt)
	if tCheck - tLastCheck >= config.GetScreenCaptureInterval() then
		step = step + 1

		if not decided and isHidden[step] then
			decided = true
			MoveSphere(pos2)
		end

		tLastCheck = tCheck
	end
	tCheck = tCheck + dt
end

function block.SetBlock(currentIteration)
	iterationId, iterationType, iterationBlock = config.GetIterationInfo(currentIteration)

	if iterationType == 0 then
		utils.SetActorMaterial(sphere, "GreenMaterial")
		utils.SetActorMaterial(wall1, "BlackMaterial")
		utils.SetActorMaterial(wall2, "BlackMaterial")

		params = {
			ground = math.random(#utils.ground_materials),
			framesStartDown = math.random(5),
			framesRemainUp = math.random(5),
			sphere_pos = math.random(2)
		}

		torch.save(config.GetDataPath() .. iterationId .. '/params.t7', params)
	else
		isHidden = torch.load(config.GetDataPath() .. iterationId .. '/hidden.t7')
		params = torch.load(config.GetDataPath() .. iterationId .. '/params.t7')
		uetorch.AddTickHook(MagicTrick)

		if iterationType == 1 then
			pos1 = 1
			pos2 = 1
			possible = true
		elseif iterationType == 2 then
			pos1 = 2
			pos2 = 2
			possible = true
		elseif iterationType == 3 then
			pos1 = 1
			pos2 = 2
			possible = false
		elseif iterationType == 4 then
			pos1 = 2
			pos2 = 1
			possible = false
		end
	end
end

function block.RunBlock()
	utils.SetActorMaterial(floor, utils.ground_materials[params.ground])
	uetorch.AddTickHook(StartDown)
	uetorch.SetActorScale3D(wall1, 0.5, 1, 1)
	uetorch.SetActorScale3D(wall2, 0.5, 1, 1)
	uetorch.SetActorLocation(camera, 150, 30, 80)
	uetorch.SetActorLocation(wall1, -100, -350, 20)
	uetorch.SetActorLocation(wall2, 200, -350, 20)
	uetorch.SetActorRotation(wall1, 0, 0, 90)
	uetorch.SetActorRotation(wall2, 0, 0, 90)
	MoveSphere(pos1)
end

function block.IsPossible()
	return possible
end

return block