-- This module defines possible materials for the ground, the walls
-- and the spheres. It also defines a function setup a given actor
-- with a given material.
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
   "M_Wood_Floor_Walnut_Polished",
   "M_Wood_Floor_Walnut_Worn",
   "M_Wood_Oak",
   "M_Wood_Pine",
   "M_Wood_Walnut",
}


material.sphere_materials = {
   "BlackMaterial",
   "GreenMaterial",
   "M_ColorGrid_LowSpec",
   "M_Metal_Brushed_Nickel",
   "M_Metal_Burnished_Steel",
   "M_Metal_Chrome",
   "M_Metal_Copper",
   "M_Metal_Gold",
   "M_Metal_Rust",
   "M_Metal_Steel",
   "M_Tech_Hex_Tile_Pulse",
   "M_Tech_Hex_Tile",
   "M_Tech_Panel",
}


material.wall_materials = {
   "M_Basic_Wall",
   "M_Brick_Clay_Beveled",
   "M_Brick_Clay_New",
   "M_Brick_Clay_Old",
   "M_Brick_Cut_Stone",
   "M_Brick_Hewn_Stone",
   "M_Ceramic_Tile_Checker",
   "M_CobbleStone_Pebble",
   "M_CobbleStone_Rough",
   "M_CobbleStone_Smooth",
}


function material.SetActorMaterial(actor, id)
   local materialId = "Material'/Game/StarterContent/Materials/" .. id .. "." .. id .. "'"
   local material = UE.LoadObject(Material.Class(), nil, materialId)
   uetorch.SetMaterial(actor, material)
end


return material
