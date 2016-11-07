local uetorch = require 'uetorch'
local material = {}


material.ground_materials = {
   "M_Basic_Floor",
   "M_Brick_Clay_Beveled",
   "M_Brick_Clay_New",
   "M_Brick_Clay_Old",
   "M_Brick_Cut_Stone",
   "M_Ground_Grass",
   "M_Ground_Gravel",
   "M_Ground_Moss",
   "M_Tech_Panel",
   "M_Wood_Wallnut",
   "M_Wood_Oak",
   "M_Wood_Pine",
   "M_Wood_Floor_Walnut_Polished",
   "M_Wood_Floor_Walnut_Worn"
}


function material.SetActorMaterial(actor, id)
   local materialId = "Material'/Game/StarterContent/Materials/" .. id .. "." .. id .. "'"
   local material = UE.LoadObject(Material.Class(), nil, materialId)
   uetorch.SetMaterial(actor, material)
end


return material
