require 'uetorch'

local ground_materials = {"M_Basic_Floor", "M_Ground_Grass", "M_Ground_Moss", "M_Wood_Floor_Walnut_Polished", "M_Wood_Floor_Walnut_Worn"}

local r = math.random(5)
local material = UE.FindObject(Material.Class(), nil, "Material'/Game/StarterContent/Materials/" .. ground_materials[r] .. "." .. ground_materials[r] .. "'")
-- print('material', ground_materials[r], material)
local floor = GetActor('Floor')
-- print('floor', floor)
SetMaterial(floor, material)