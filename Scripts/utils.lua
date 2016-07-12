local uetorch = require 'uetorch'
local utils = {}

utils.ground_materials = {"M_Basic_Floor", "M_Ground_Grass", "M_Ground_Moss", "M_Wood_Floor_Walnut_Polished", "M_Wood_Floor_Walnut_Worn"}

function utils.SetActorMaterial(actor, id)
	local materialId = "Material'/Game/StarterContent/Materials/" .. id .. "." .. id .. "'"
	local material = UE.FindObject(Material.Class(), nil, materialId)
	uetorch.SetMaterial(actor, material)
end

return utils