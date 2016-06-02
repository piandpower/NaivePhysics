require 'uetorch'

SetTickDeltaBounds(1/16,1/16)

local ground_materials = {"M_Basic_Floor", "M_Ground_Grass", "M_Ground_Moss", "M_Wood_Floor_Walnut_Polished", "M_Wood_Floor_Walnut_Worn"}

function setGroundMaterial(id)
	local materialId = "Material'/Game/StarterContent/Materials/" .. ground_materials[id] .. "." .. ground_materials[id] .. "'"
	local material = UE.FindObject(Material.Class(), nil, materialId)
	print('material', ground_materials[id], materialId, material)
	local floor = GetActor('Floor')
	print('floor', floor)
	SetMaterial(floor, material)
end

--for i = 1,5 do
--	setGroundMaterial(i)
--end

math.randomseed(os.time())
local r = math.random(5)
print('r', r)
setGroundMaterial(r)

local t = 0
local obj = GetActor("Sphere_4")
print('obj', obj)

function myMover(dt)
	local succ = SetActorLocation(obj, -400 + t*100, -500, 70)
	--print('succ', succ, t)
	local succ2 = SetActorRotation(obj, 0, t * 100, 0)
	t = t + dt
end

AddHook(myMover)
--start_repl()