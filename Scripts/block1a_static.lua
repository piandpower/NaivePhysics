local uetorch = require 'uetorch'
local config = require 'config'
local block = {}

local sphere = uetorch.GetActor("Sphere_4")
local wall = uetorch.GetActor("Wall_400x200_8")
block.actors = {sphere=sphere, wall=wall}
local possible = true
local isVisible
local isHidden
local decided = false
local params = {}
local iterationType

local camera = uetorch.GetActor("MainMap_CameraActor_Blueprint_C_1")

local function InitSphere()
	uetorch.SetActorLocation(sphere, 150, -550, 70)
	if iterationType ~= 0 then
		isVisible = math.random(2)
		if isVisible == 1 then
			uetorch.SetActorVisible(sphere, true)
		else
			uetorch.SetActorVisible(sphere, false)
		end
	end
end

local t_rotation = 0
local t_rotation_change = 0

local function WallRotationDown(dt)
	local angle = (t_rotation - t_rotation_change) * 20
	uetorch.SetActorRotation(wall, 0, 0, angle)
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

local function Dissapear(dt)
	if tCheck - tLastCheck >= config.GetScreenCaptureInterval() then
		step = step + 1

		if not decided and isHidden[step] then
			decided = true
			local isVisible2 = math.random(2)
			if isVisible2 ~= isVisible then
				possible = false
			end
			isVisible = isVisible2
			if isVisible == 1 then
				uetorch.SetActorVisible(sphere, true)
			else
				uetorch.SetActorVisible(sphere, false)
			end
		end

		tLastCheck = tCheck
	end
	tCheck = tCheck + dt
end

function block.SetBlock(currentIteration)
	iterationType = currentIteration % 2
	local folderid = math.ceil(currentIteration / 2)

	if iterationType == 0 then
		local id = "GreenMaterial"
		local greenMaterialId = "Material'/Game/StarterContent/Materials/" .. id .. "." .. id .. "'"
		local greenMaterial = UE.FindObject(Material.Class(), nil, greenMaterialId)
		uetorch.SetMaterial(sphere, greenMaterial)

		id = "BlackMaterial"
		local blackMaterialId = "Material'/Game/StarterContent/Materials/" .. id .. "." .. id .. "'"
		local blackMaterial = UE.FindObject(Material.Class(), nil, blackMaterialId)
		uetorch.SetMaterial(wall, blackMaterial)

		params = {
			framesStartDown = math.random(5),
			framesRemainUp = math.random(5)
		}

		torch.save(config.GetDataPath() .. folderid .. '/params.t7', params)
	else
		isHidden = torch.load(config.GetDataPath() .. folderid .. '/hidden.t7')
		params = torch.load(config.GetDataPath() .. folderid .. '/params.t7')
		uetorch.AddTickHook(Dissapear)
	end
end

function block.RunBlock()
	uetorch.AddTickHook(StartDown)
	uetorch.SetActorLocation(camera, 100, 30, 80)
	uetorch.SetActorLocation(wall, -100, -350, 20)
	uetorch.SetActorRotation(wall, 0, 0, 90)
	InitSphere()
end

function block.IsPossible()
	return possible
end

return block