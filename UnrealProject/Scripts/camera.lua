-- This module defines random camera position, and a function to setup
-- the camera in a given position and orientation.
--
-- TODO for now we only pick random camera coordinates for the train
-- pathway, test pathway has constant camera point of view.
local uetorch = require 'uetorch'
local camera = {}


function camera.randomLocation()
   local cameraLocation = {
      math.random(-50, 50), -- x axis is left/right
      math.random(-50, 150), -- y axis is front/back
      math.random(-10, 50)  -- z axis is up/down
   }
   -- print('camera y location is ' .. cameraLocation[2])
   return cameraLocation
end


function camera.randomRotation()
   return {
      math.random(-15, 10),
      math.random(-30, 30),
      0
   }
end


-- Setup the camera location and rotation
--
-- locationShift and rotationShift are considered only for train (when
-- iterationType is -1), the camera location on the x axis varies
-- across blocks and is therefore given as a parameter.
function camera.setup(iterationType, xLocation, locationShift, rotationShift)
   local cameraActor = uetorch.GetActor("MainMap_CameraActor_Blueprint_C_0")

   if iterationType == -1 then  -- train
      uetorch.SetActorLocation(
         cameraActor,
         xLocation + locationShift[1],
         30 + locationShift[2],
         80 + locationShift[3])

      uetorch.SetActorRotation(
         cameraActor,
         0 + rotationShift[1],
         -90 + rotationShift[2],
         0 + rotationShift[3])
   else
      uetorch.SetActorLocation(cameraActor, xLocation, 30, 80)
      uetorch.SetActorRotation(cameraActor, 0, -90, 0)
   end
end


return camera
