local uetorch = require 'uetorch'
local block = {}

local sphere = uetorch.GetActor("Sphere_4")
local wall = uetorch.GetActor("Wall_400x200_8")
block.actors = {sphere=sphere, wall=wall}

local t = 0
local firstMover = true

local function MyMover(dt)
	if firstMover then
		local succ = uetorch.SetActorLocation(sphere, -400, -500, 70)
		firstMover = false
	end
	local succ = uetorch.SetActorVelocity(sphere,100,0,0)
	--print('sphere :',succ,t,uetorch.GetActorLocation(sphere),uetorch.GetActorVelocity(sphere))
	t = t + dt
end

local t_rotation_change = 0
local WallRotation2

local function WallRotation1(dt)
	local succ = uetorch.SetActorRotation(wall, 0, 0, (t - t_rotation_change) * 20)
	--print('wallRotation1 succ', succ, t, (t - t_rotation_change) * 20, uetorch.GetActorRotation(wall))
	if (t - t_rotation_change) * 20 > 90 then
		uetorch.RemoveTickHook(WallRotation1)
		uetorch.AddTickHook(WallRotation2)
		t_rotation_change = t
	end
	t = t + dt
end

WallRotation2 = function(dt)
	local succ = uetorch.SetActorRotation(wall, 0, 0, 90 - (t - t_rotation_change) * 20)
	if (t - t_rotation_change) * 20 > 90 then
		uetorch.RemoveTickHook(WallRotation2)
		uetorch.AddTickHook(WallRotation1)
		t_rotation_change = t
	end
	t = t + dt
end


function block.set_block()
	uetorch.AddTickHook(MyMover)
	uetorch.AddTickHook(WallRotation1)
end

return block