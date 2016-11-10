local uetorch = require 'uetorch'

local agent = uetorch.GetActor("ThirdPersonCharacter_C_1")
local handleComponent

local object = uetorch.GetActor("TargetPoint_1")
local object2 = uetorch.GetActor("Cube_4")
local wall = uetorch.GetActor("Wall_400x200_4")
local wall_boxY
local hit

uetorch.SetTickDeltaBounds(1/128, 1/128)

local t_rotation = 0

local function WallRotationDown(dt)
   local angle = t_rotation * 50
   uetorch.SetActorRotation(wall, 0, 0, angle)
   uetorch.SetActorLocation(wall, -220, -140, 20 + math.sin(angle * math.pi / 180) * wall_boxY)
   if angle >= 90 then
      uetorch.RemoveTickHook(WallRotationDown)
   end
   t_rotation = t_rotation + dt
end

local waitTime = 4
local waited

local function WaitMoveToLocation(dt)
   if waited < waitTime then
      waited = waited + dt
      local location = uetorch.GetActorLocation(agent)
      local forward = uetorch.GetActorForwardVector(agent)
      local handleDistance = 100
      local handleX = location.x + handleDistance * forward.x
      local handleY = location.y + handleDistance * forward.y
      local handleZ = location.z + handleDistance * forward.z + 40
      uetorch.SetTargetLocation(handleComponent, handleX, handleY, handleZ)

      if waited >= waitTime then
         print("ReleaseComponent", uetorch.ReleaseComponent(agent))
         local meshComponent = UETorch.GetActorMeshComponentAsPrimitive(object2)
         print("GetActorMeshComponentAsPrimitive 2", meshComponent)
         print("WakeRigidBody", uetorch.WakeRigidBody(meshComponent))
         uetorch.RemoveTickHook(WaitMoveToLocation)

         uetorch.SimpleMoveToActor(agent, wall)
      end
   end
end

local function MoveObject(dt)
   local locationStart = uetorch.GetActorLocation(agent)
   local locationEnd = uetorch.GetActorLocation(object2)
   hit = UETorch.LineTraceMeshComponent(object2, locationStart.x, locationStart.y, locationStart.z, locationEnd.x, locationEnd.y, locationEnd.z)
   local meshComponent = UETorch.GetActorMeshComponentAsPrimitive(object2)
   print("GetActorMeshComponentAsPrimitive 1", meshComponent)
   print('GrabComponent', uetorch.GrabComponent(handleComponent, meshComponent, hit.BoneName, hit.x, hit.y, hit.z))
   uetorch.IgnoreCollisionWithPawn(meshComponent)
   print("move to location", uetorch.SimpleMoveToLocation(agent, 100, 200, 0))
   waited = 0
   uetorch.AddTickHook(WaitMoveToLocation)
   uetorch.RemoveTickHook(MoveObject)
end

local function WaitMoveToActor(dt)
   if waited < waitTime then
      waited = waited + dt

      if waited >= waitTime then
         uetorch.AddTickHook(MoveObject)
         uetorch.RemoveTickHook(WaitMoveToActor)
      end
   end
end

local function CallMove(dt)
   print("CallMove", dt)
   handleComponent = UETorch.GetActorPhysicsHandleComponent(agent)
   print("move to actor", uetorch.SimpleMoveToActor(agent, object2))
   waited = 0
   uetorch.AddTickHook(WaitMoveToActor)
   uetorch.RemoveTickHook(CallMove)
end

function BeginPlay()
   print("call BeginPlay")
   wall_boxY = uetorch.GetActorBounds(wall)['boxY']
   uetorch.AddTickHook(WallRotationDown)
   uetorch.AddTickHook(CallMove)
end
