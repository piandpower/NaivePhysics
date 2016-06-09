require 'uetorch'
image = require 'image'

SetTickDeltaBounds(1/16,1/16)

config = {
	--seed = 0,
	dataRoot = '/home/mario/Documents/Unreal Projects/NaivePhysics/data', -- don't override anything important
	screenCaptureTime = 0.125,
	sceneTime = 15.0,
	stride = 5
	--loadTime = 2.0, -- 1s
	--resolution = 'nil', -- this gets interpreted by the blueprints as NULL, but you can still override
}

for k,v in pairs(config) do
	if os.getenv(k) then
		local v = os.getenv(k)
		config[k] = tonumber(v) or v
	end
end

print(config)

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

	if t3 - last_save_t >= config['screenCaptureTime'] then
		local file1 = config['dataRoot'] .. '/' .. it .. '_screen.jpg'
		print(file1,t3,dt)
	    local i1 = Screen()

	    if i1 then
	      image.save(file1, i1)
	    end

		local actors = {obj, wall}
	    local file2 = config['dataRoot'] .. '/' .. it .. '_objseg.jpg'
	    local i2 = ObjectSegmentation(actors, config['stride'])

	    if i2 then
			image.save(file2,i2)
	    end

	    local file3 = config['dataRoot'] .. '/' .. it .. '_mask.jpg'
	    local i3 = ObjectMasks(actors, config['stride'])

	    if i3 then
			image.save(file3,i3[1])
	    end

	    it = it + 1
		last_save_t = t3
	end

	if t3 >= config['sceneTime'] then
		RemoveHook(saveScreen)
	end
end

AddHook(saveScreen)