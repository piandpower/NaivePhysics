-- This module defines the background wall behavior. Random texture,
-- height, width and distance from the camera. The background wall is
-- a U-shaped wall surrounding the scene. It has physics enabled so
-- the spheres can collide to it.

local uetorch = require 'uetorch'
local material = require 'material'
local backwall = {}


-- those are the componants of the background wall in the Unreal scene
local wallBack = uetorch.GetActor("WallBack")
local wallRight = uetorch.GetActor("WallRight")
local wallLeft = uetorch.GetActor("WallLeft")


-- Pick a random wall texture for the background wall
function backwall.randomMaterial()
   return math.random(#material.wall_materials)
end

-- Pick a random height for the background wall
function backwall.randomHeight()
   return math.random(1, 10) * 0.5
end

-- Pick a random distance from the camera for the background wall
function backwall.randomDepth()
   return math.random(-1500, -900)
end

-- Pick a random width of the U-shaped wall (i.e. lenght of the U bottom)
function backwall.randomWidth()
   return math.random(1500, 4000)
end

-- Generate a random set of attributes for the background wall
function backwall.random()
   return {
      material = backwall.randomMaterial(),
      height = backwall.randomHeight(),
      depth = backwall.randomDepth(),
      width = backwall.randomWidth()
   }
end

-- Setup a background wall configuration from precomputed attributes
--
-- The params must be table structured as the one returned by
-- backwall.random()
function backwall.setup(params)
   params = params or backwall.random()

   for _, w in ipairs({wallBack, wallLeft, wallRight}) do
      -- material
      material.SetActorMaterial(w, material.wall_materials[params.material])

      -- height
      local scale = uetorch.GetActorScale3D(w)
      uetorch.SetActorScale3D(w, scale.x, scale.y, scale.z * params.height)

      -- depth
      local location = uetorch.GetActorLocation(w)
      uetorch.SetActorLocation(w, location.x, params.depth, location.z)
   end

   -- width
   local location = uetorch.GetActorLocation(wallLeft)
   uetorch.SetActorLocation(wallLeft, -params.width / 2, location.y, location.z)

   local location = uetorch.GetActorLocation(wallRight)
   uetorch.SetActorLocation(wallRight, params.width / 2, location.y, location.z)
end


-- Make the background wall invisible
function backwall.hide()
   uetorch.DestroyActor(wallBack)
   uetorch.DestroyActor(wallRight)
   uetorch.DestroyActor(wallLeft)
end

-- Insert the background wall componants in a table (this is usefull
-- for masks computation). TODO here each subwall will have a distinct
-- mask ID, wheras a single id would be better.
function backwall.tableInsert(tActor, tText)
   table.insert(tActor, wallBack)
   table.insert(tActor, wallLeft)
   table.insert(tActor, wallRight)

   table.insert(tText, "wallBack")
   table.insert(tText, "wallLeft")
   table.insert(tText, "wallRight")
end

return backwall
