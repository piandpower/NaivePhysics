local uetorch = require 'uetorch'
local block = {}

local sphere = uetorch.GetActor("Sphere_4")
local wall1 = uetorch.GetActor("Wall_400x200_8")
local wall2 = uetorch.GetActor("Wall_400x201_7")
block.actors = {sphere=sphere, wall1=wall1, wall2=wall2}

local camera = uetorch.GetActor("MainMap_CameraActor_Blueprint_C_1")

local sphere_pos = math.random(2)

local function moveSphere()
	if sphere_pos == 1 then
		uetorch.SetActorLocation(sphere, -50, -550, 70)
	else
		uetorch.SetActorLocation(sphere, 320, -550, 70)
	end
end

local t_rotation = 0
local t_rotation_change = 0
local framesStartDown
local framesRemainUp

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
	framesRemainUp = framesRemainUp - 1
	if framesRemainUp == 0 then
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
		sphere_pos = math.random(2)
		moveSphere()
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

function block.set_block()
	framesStartDown = math.random(5)
	framesRemainUp = math.random(5)
	uetorch.AddTickHook(StartDown)
	uetorch.SetActorScale3D(wall1, 0.5, 1, 1)
	uetorch.SetActorScale3D(wall2, 0.5, 1, 1)
	uetorch.SetActorLocation(camera, 150, 30, 80)
	uetorch.SetActorLocation(wall1, -100, -350, 20)
	uetorch.SetActorLocation(wall2, 200, -350, 20)
	uetorch.SetActorRotation(wall1, 0, 0, 90)
	uetorch.SetActorRotation(wall2, 0, 0, 90)
	moveSphere()
end

return block