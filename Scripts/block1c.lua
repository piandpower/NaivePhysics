local uetorch = require 'uetorch'
local block = {}

local sphere = uetorch.GetActor("Sphere_4")
local wall1 = uetorch.GetActor("Wall_400x200_8")
local wall2 = uetorch.GetActor("Wall_400x201_7")
block.actors = {sphere=sphere, wall1=wall1, wall2=wall2}

local camera = uetorch.GetActor("MainMap_CameraActor_Blueprint_C_0")

local t_rotation = 0
local t_rotation_change = 0
local WallRotation2
local sphere_pos = math.random(2)

local function move_sphere()
	if sphere_pos == 1 then
		uetorch.SetActorLocation(sphere, -50, -500, 70)
	else
		uetorch.SetActorLocation(sphere, 270, -500, 70)
	end
end

local function WallRotation1(dt)
	local angle = (t_rotation - t_rotation_change) * 20
	local succ = uetorch.SetActorRotation(wall1, 0, 0, angle)
	local succ2 = uetorch.SetActorRotation(wall2, 0, 0, angle)
	if angle >= 90 then
		uetorch.RemoveTickHook(WallRotation1)
		uetorch.AddTickHook(WallRotation2)
		t_rotation_change = t_rotation
	end
	t_rotation = t_rotation + dt
end

WallRotation2 = function(dt)
	local angle = (t_rotation - t_rotation_change) * 20
	local succ = uetorch.SetActorRotation(wall1, 0, 0, 90 - angle)
	local succ2 = uetorch.SetActorRotation(wall2, 0, 0, 90 - angle)
	if angle >= 90 then
		uetorch.RemoveTickHook(WallRotation2)
		uetorch.AddTickHook(WallRotation1)
		t_rotation_change = t_rotation
		sphere_pos = math.random(2)
		move_sphere()
	end
	t_rotation = t_rotation + dt
end

function block.set_block()
	uetorch.AddTickHook(MyMover)
	uetorch.AddTickHook(WallRotation2)
	uetorch.SetActorScale3D(wall1, 0.5, 1, 1)
	uetorch.SetActorScale3D(wall2, 0.5, 1, 1)
	uetorch.SetActorLocation(wall2, 200, -400, 20)
	uetorch.SetActorLocation(camera, 150, 30, 80)
	move_sphere()
end

return block