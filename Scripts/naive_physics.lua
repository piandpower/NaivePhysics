require 'uetorch'
image = require 'image'
require 'config'

SetTickDeltaBounds(1/16,1/16)

local ground_materials = {"M_Basic_Floor", "M_Ground_Grass", "M_Ground_Moss", "M_Wood_Floor_Walnut_Polished", "M_Wood_Floor_Walnut_Worn"}

function setGroundMaterial(id)
	local materialId = "Material'/Game/StarterContent/Materials/" .. ground_materials[id] .. "." .. ground_materials[id] .. "'"
	local material = UE.FindObject(Material.Class(), nil, materialId)
	local floor = GetActor('Floor')
	SetMaterial(floor, material)
end

local r = math.random(5)
setGroundMaterial(r)

local t = 0
local obj = GetActor("Sphere_4")
local firstMover = true
local cont = 0

function myMover(dt)
	if firstMover then
		local succ = SetActorLocation(obj, -400, -500, 70)
		firstMover = false
	end
	local succ = SetActorVelocity(obj,100,0,0)
	--print('sphere :',succ,t,GetActorLocation(obj),GetActorVelocity(obj))
	t = t + dt
end

AddHook(myMover)

local wall = GetActor("Wall_400x200_8")

local t2 = 0

function wallRotation1(dt)
	local succ = SetActorRotation(wall, 0, 0, (t - t2) * 20)
	--print('wallRotation1 succ', succ, t, (t - t2) * 20, GetActorRotation(wall))
	if (t - t2) * 20 > 90 then
		RemoveHook(wallRotation1)
		AddHook(wallRotation2)
		t2 = t
	end
	t = t + dt
end

function wallRotation2(dt)
	local succ = SetActorRotation(wall, 0, 0, 90 - (t - t2) * 20)
	if (t - t2) * 20 > 90 then
		RemoveHook(wallRotation2)
		AddHook(wallRotation1)
		t2 = t
	end
	t = t + dt
end

AddHook(wallRotation1)

local last_save_t = 0
local t3 = 0
local it = 0

function saveScreen(dt)
	t3 = t3 + dt

	if t3 - last_save_t >= getScreenCaptureInterval() then
		local file1 = getDataPath() .. it .. '_screen.jpg'
		print(file1,t3,dt)
	    local i1 = Screen()

	    if i1 then
	      image.save(file1, i1)
	    end

		local actors = {obj, wall}
	    local file2 = getDataPath() .. it .. '_objseg.jpg'
	    local i2 = ObjectSegmentation(actors, getStride())

	    if i2 then
			image.save(file2,i2)
	    end

	    local file3 = getDataPath() .. it .. '_mask.jpg'
	    local i3 = ObjectMasks(actors, getStride())

	    if i3 then
			image.save(file3,i3[1])
	    end

	    it = it + 1
		last_save_t = t3
	end

	if t3 >= getSceneTime() then
		RemoveHook(saveScreen)
	end
end

AddHook(saveScreen)