local uetorch = require 'uetorch'
local block = {}

local sphere = uetorch.GetActor("Sphere_4")
local wall = uetorch.GetActor("Wall_400x200_8")
block.actors = {sphere=sphere, wall=wall}

local t_mover = 0
local firstMover = true
local succ

local function MyMover(dt)
	if firstMover then
		succ = uetorch.SetActorLocation(sphere, -400, -500, 70 + math.random(200))
		forceX = math.random(800000, 1500000)
		forceY = 0
		forceZ = math.random(800000, 1000000)
		signZ = 2 * math.random(2) - 3
		succ = uetorch.AddForce(sphere, forceX, forceY, signZ * forceZ)
		firstMover = false
	end
	--local succ = uetorch.SetActorVelocity(sphere,100,0,0)
	--print('sphere :',succ,t,uetorch.GetActorLocation(sphere),uetorch.GetActorVelocity(sphere))
	t_mover = t_mover + dt
end

local t_rotation = 0
local t_rotation_change = 0
local WallRotation2

local function WallRotation1(dt)
	local succ = uetorch.SetActorRotation(wall, 0, 0, (t_rotation - t_rotation_change) * 20)
	--print('wallRotation1 succ', succ, t, (t - t_rotation_change) * 20, uetorch.GetActorRotation(wall))
	if (t_rotation - t_rotation_change) * 20 > 90 then
		uetorch.RemoveTickHook(WallRotation1)
		uetorch.AddTickHook(WallRotation2)
		t_rotation_change = t_rotation
	end
	t_rotation = t_rotation + dt
end

WallRotation2 = function(dt)
	local succ = uetorch.SetActorRotation(wall, 0, 0, 90 - (t_rotation - t_rotation_change) * 20)
	if (t_rotation - t_rotation_change) * 20 > 90 then
		uetorch.RemoveTickHook(WallRotation2)
		uetorch.AddTickHook(WallRotation1)
		t_rotation_change = t_rotation
	end
	t_rotation = t_rotation + dt
end

function block.set_block()
	uetorch.AddTickHook(MyMover)
	uetorch.AddTickHook(WallRotation1)
end

return block