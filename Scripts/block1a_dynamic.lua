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
		local forceX = math.random(800000, 1400000)
		local forceY = 0
		local forceZ = math.random(800000, 1000000)
		local signZ = 2 * math.random(2) - 3
		local left = math.random(0,1)

		if left == 1 then
			succ = uetorch.SetActorLocation(sphere, -400, -500, 70 + math.random(200))
		else
			succ = uetorch.SetActorLocation(sphere, 500, -500, 70 + math.random(200))
			forceX = -forceX
		end

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
	local angle = (t_rotation - t_rotation_change) * 20
	local succ = uetorch.SetActorRotation(wall, 0, 0, angle)
	if angle >= 90 then
		uetorch.RemoveTickHook(WallRotation1)
		uetorch.AddTickHook(WallRotation2)
		t_rotation_change = t_rotation
	end
	t_rotation = t_rotation + dt
end

WallRotation2 = function(dt)
	local angle = (t_rotation - t_rotation_change) * 20
	local succ = uetorch.SetActorRotation(wall, 0, 0, 90 - angle)
	if angle >= 90 then
		uetorch.RemoveTickHook(WallRotation2)
		uetorch.AddTickHook(WallRotation1)
		t_rotation_change = t_rotation
		if math.random(2) == 1 then
			sphere_visible = true
		else
			sphere_visible = false
		end
		uetorch.SetActorVisible(sphere, sphere_visible)
	end
	t_rotation = t_rotation + dt
end

function block.set_block()
	uetorch.AddTickHook(MyMover)
	uetorch.AddTickHook(WallRotation2)
end

return block