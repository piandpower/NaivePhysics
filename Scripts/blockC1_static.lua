local uetorch = require 'uetorch'
local config = require 'config'
local utils = require 'utils'
local block = {}

local sphere = uetorch.GetActor("Sphere_4")
local sphere2 = uetorch.GetActor("Sphere9_4")
local sphere3 = uetorch.GetActor("Sphere10_7")
local spheres = {sphere, sphere2, sphere3}

local wall = uetorch.GetActor("Wall_400x200_8")
local wall_boxY
block.actors = {sphere=sphere, wall=wall}

local visible1 = true
local visible2 = true
local possible = true

local isHidden
local params = {}

local iterationId
local iterationType
local iterationBlock

local camera = uetorch.GetActor("MainMap_CameraActor_Blueprint_C_1")
local floor = uetorch.GetActor('Floor')

local t_rotation = 0
local t_rotation_change = 0

local function WallRotationDown(dt)
	local angle = (t_rotation - t_rotation_change) * 20
	uetorch.SetActorRotation(wall, 0, 0, angle)
	uetorch.SetActorLocation(wall, 100 - 200 * params.scaleW, -350, 20 + math.sin(angle * math.pi / 180) * wall_boxY)
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
	uetorch.SetActorLocation(wall, 100 - 200 * params.scaleW, -350, 20 + math.sin((90 - angle) * math.pi / 180) * wall_boxY)
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
			uetorch.SetActorVisible(spheres[params.index], visible2)
		end

		tLastCheck = tCheck
	end
	tCheck = tCheck + dt
end

function block.SetBlock(currentIteration)
	iterationId, iterationType, iterationBlock = config.GetIterationInfo(currentIteration)

	if iterationType == 0 then
		utils.SetActorMaterial(wall, "BlackMaterial")

		params = {
			ground = math.random(#utils.ground_materials),
			framesStartDown = math.random(20),
			framesRemainUp = math.random(20),
			scaleW = 1 - 0.5 * math.random(),
			scaleH = 1 - 0.5 * math.random(),
			n = math.random(1,3)
		}

		params.index = math.random(1, params.n)
		utils.SetActorMaterial(spheres[params.index], "GreenMaterial")

		for i = 1,3 do
			if i ~= params.index then
				uetorch.DestroyActor(spheres[i])
			end
		end

		torch.save(config.GetDataPath() .. iterationId .. '/params.t7', params)
	else
		isHidden = torch.load(config.GetDataPath() .. iterationId .. '/hidden.t7')
		params = torch.load(config.GetDataPath() .. iterationId .. '/params.t7')
		uetorch.AddTickHook(MagicTrick)

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

function block.RunBlock()
	utils.SetActorMaterial(floor, utils.ground_materials[params.ground])
	uetorch.AddTickHook(StartDown)
	uetorch.SetActorLocation(camera, 100, 30, 80)

	uetorch.SetActorScale3D(wall, params.scaleW, 1, params.scaleH)
	wall_boxY = uetorch.GetActorBounds(wall)['boxY']
	uetorch.SetActorRotation(wall, 0, 0, 90)
	uetorch.SetActorLocation(wall, 100 - 200 * params.scaleW, -350, 20 + wall_boxY)

	uetorch.SetActorLocation(sphere, 150, -550, 70)
	uetorch.SetActorVisible(spheres[params.index], visible1)
	if params.n >= 2 then
		uetorch.SetActorLocation(sphere2, 40,-550, 70)
	end
	if params.n >= 3 then
		uetorch.SetActorLocation(sphere3, 260,-550, 70)
	end
end

function block.IsPossible()
	return possible
end

return block