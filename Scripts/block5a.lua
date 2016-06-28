local uetorch = require 'uetorch'
local block = {}

local sphere = uetorch.GetActor("Sphere_4")
local wall = uetorch.GetActor("Wall_400x200_8")
local wall2 = uetorch.GetActor("Wall_400x201_7")
block.actors = {sphere=sphere, wall=wall}
local possible

if math.random(2) == 1 then
	possible = true
else
	possible = false
end

local camera = uetorch.GetActor("MainMap_CameraActor_Blueprint_C_1")

local function InitSphere()
	local forceX = math.random(1800000, 2200000)
	local forceY = 0
	local forceZ = 0
	local signZ = 2 * math.random(2) - 3
	local left = math.random(0,1)

	if left == 1 then
		uetorch.SetActorLocation(sphere, -400, -550, 200 + math.random(150))
		if not possible then
			uetorch.SetActorLocation(wall2, 0, -750, 20)
		end
	else
		uetorch.SetActorLocation(sphere, 500, -550, 200 + math.random(150))
		if not possible then
			uetorch.SetActorLocation(wall2, 150, -750, 20)
		end
		forceX = -forceX
	end

	uetorch.AddForce(sphere, forceX, forceY, signZ * forceZ)
end

local t_rotation = 0
local t_rotation_change = 0
local framesStartDown
local framesRemainUp

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
	framesRemainUp = framesRemainUp - 1
	if framesRemainUp == 0 then
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
	framesStartDown = framesStartDown - 1
	if framesStartDown == 0 then
		uetorch.RemoveTickHook(StartDown)
		uetorch.AddTickHook(WallRotationUp)
	end
end

function block.SetBlock()
	framesStartDown = math.random(5)
	framesRemainUp = math.random(5)
	uetorch.AddTickHook(StartDown)
	uetorch.SetActorLocation(camera, 100, 30, 80)
	uetorch.SetActorLocation(wall, -100, -350, 20)
	uetorch.SetActorLocation(sphere, 150, -550, 70)
	uetorch.SetActorRotation(wall, 0, 0, 90)
	InitSphere()

	if not possible then
		uetorch.SetActorRotation(wall2, 0, 90, 0)
		uetorch.SetActorVisible(wall2, false)
	end
end

function block.IsPossible()
	return possible
end

return block