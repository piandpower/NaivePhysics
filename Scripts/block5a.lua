local uetorch = require 'uetorch'
local config = require 'config'
local block = {}

local sphere = uetorch.GetActor("Sphere_4")
local wall = uetorch.GetActor("Wall_400x200_8")
local wall2 = uetorch.GetActor("Wall_400x201_7")
block.actors = {sphere=sphere, wall=wall}
local possible
local isHidden
local params = {}
local iterationType

local camera = uetorch.GetActor("MainMap_CameraActor_Blueprint_C_1")

local function InitSphere()
	if params.left == 1 then
		uetorch.SetActorLocation(sphere, -400, -550, params.sphereZ)
		if params.possible ~= 1 then
			uetorch.SetActorLocation(wall2, 0, -750, 20)
		end
	else
		uetorch.SetActorLocation(sphere, 500, -550, params.sphereZ)
		if params.possible ~= 1 then
			uetorch.SetActorLocation(wall2, 150, -750, 20)
		end
		params.forceX = -params.forceX
	end

	uetorch.AddForce(sphere, params.forceX, params.forceY, params.signZ * params.forceZ)
end

local t_rotation = 0
local t_rotation_change = 0

local function WallRotationDown(dt)
	local angle = (t_rotation - t_rotation_change) * 60
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
	local angle = (t_rotation - t_rotation_change) * 60
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
			sphereZ = 200 + math.random(150),
			forceX = math.random(1800000, 2200000),
			forceY = 0,
			forceZ = 0,
			signZ = 2 * math.random(2) - 3,
			left = math.random(0,1),
			framesStartDown = math.random(5),
			framesRemainUp = math.random(5),
			possible = math.random(2)
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

	if params.possible ~= 1 then
		uetorch.SetActorRotation(wall2, 0, 90, 0)
		uetorch.SetActorVisible(wall2, false)
	end
end

function block.IsPossible()
	return params.possible == 1
end

return block