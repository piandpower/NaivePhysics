local uetorch = require 'uetorch'
local image = require 'image'
local config = require 'config'

uetorch.SetTickDeltaBounds(1/16,1/16)
GetSceneTime = config.GetSceneTime

local ground_materials = {"M_Basic_Floor", "M_Ground_Grass", "M_Ground_Moss", "M_Wood_Floor_Walnut_Polished", "M_Wood_Floor_Walnut_Worn"}

local function SetGroundMaterial(id)
	local materialId = "Material'/Game/StarterContent/Materials/" .. ground_materials[id] .. "." .. ground_materials[id] .. "'"
	local material = UE.FindObject(Material.Class(), nil, materialId)
	local floor = uetorch.GetActor('Floor')
	uetorch.SetMaterial(floor, material)
end

local r = math.random(5)
SetGroundMaterial(r)

local t = 0
local obj = uetorch.GetActor("Sphere_4")
local firstMover = true
local currentIteration = 0

function SetCurrentIteration(iteration)
	currentIteration = iteration
	print('SetCurrentIteration',iteration,currentIteration)
end

local function MyMover(dt)
	if firstMover then
		local succ = uetorch.SetActorLocation(obj, -400, -500, 70)
		firstMover = false
	end
	local succ = uetorch.SetActorVelocity(obj,100,0,0)
	--print('sphere :',succ,t,GetActorLocation(obj),GetActorVelocity(obj))
	t = t + dt
end

uetorch.AddTickHook(MyMover)

local wall = uetorch.GetActor("Wall_400x200_8")

local t2 = 0

local function WallRotation1(dt)
	local succ = uetorch.SetActorRotation(wall, 0, 0, (t - t2) * 20)
	--print('wallRotation1 succ', succ, t, (t - t2) * 20, GetActorRotation(wall))
	if (t - t2) * 20 > 90 then
		uetorch.RemoveTickHook(WallRotation1)
		uetorch.AddTickHook(WallRotation2)
		t2 = t
	end
	t = t + dt
end

local function WallRotation2(dt)
	local succ = uetorch.SetActorRotation(wall, 0, 0, 90 - (t - t2) * 20)
	if (t - t2) * 20 > 90 then
		uetorch.RemoveTickHook(WallRotation2)
		uetorch.AddTickHook(WallRotation1)
		t2 = t
	end
	t = t + dt
end

uetorch.AddTickHook(WallRotation1)

local last_save_t = 0
local t3 = 0
local step = 0

local function SaveScreen(dt)
	t3 = t3 + dt

	if t3 - last_save_t >= config.GetScreenCaptureInterval() then
		step = step + 1
		local file1 = config.GetDataPath() .. currentIteration .. '/' .. step .. '_screen.jpg'
		--print(file1,t3,dt)
		local i1 = uetorch.Screen()

		if i1 then
			image.save(file1, i1)
		end

		local actors = {obj, wall}
		local file2 = config.GetDataPath() .. currentIteration .. '/' .. step .. '_objseg.jpg'
		local i2 = uetorch.ObjectSegmentation(actors, config.GetStride())

		if i2 then
			image.save(file2,i2)
		end

		local file3 = config.GetDataPath() .. currentIteration .. '/' .. step .. '_mask_ball.jpg'
		local file4 = config.GetDataPath() .. currentIteration .. '/' .. step .. '_mask_wall.jpg'
		local i3 = uetorch.ObjectMasks(actors, config.GetStride())

		if i3 then
			image.save(file3,i3[1])
			image.save(file4,i3[2])
		end

		last_save_t = t3
	end

	if t3 >= config.GetSceneTime() then
		uetorch.RemoveTickHook(SaveScreen)
	end
end

uetorch.AddTickHook(SaveScreen)