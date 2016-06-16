local uetorch = require 'uetorch'
local image = require 'image'
local config = require 'config'
local block = require(config.GetBlock())

uetorch.SetTickDeltaBounds(1/16, 1/16)
GetSceneTime = config.GetSceneTime

local currentIteration = 0

function SetCurrentIteration(iteration)
	currentIteration = iteration
	print('current iteration =', currentIteration)
end

local ground_materials = {"M_Basic_Floor", "M_Ground_Grass", "M_Ground_Moss", "M_Wood_Floor_Walnut_Polished", "M_Wood_Floor_Walnut_Worn"}

local function SetGroundMaterial(id)
	local materialId = "Material'/Game/StarterContent/Materials/" .. ground_materials[id] .. "." .. ground_materials[id] .. "'"
	local material = UE.FindObject(Material.Class(), nil, materialId)
	local floor = uetorch.GetActor('Floor')
	uetorch.SetMaterial(floor, material)
end

local r = math.random(5)
SetGroundMaterial(r)

local t_last_save = 0
local t3 = 0
local step = 0
local actors = {}

local function dict_to_array(a)
	local ret = {}
	local i = 1
	for k, v in pairs(a) do
		ret[i] = v
		i = i + 1
	end
	return ret
end

actors = dict_to_array(block.actors)

local function SaveScreen(dt)
	t3 = t3 + dt

	if t3 - t_last_save >= config.GetScreenCaptureInterval() then
		step = step + 1
		local file1 = config.GetDataPath() .. currentIteration .. '/' .. step .. '_screen.jpg'
		local i1 = uetorch.Screen()

		if i1 then
			image.save(file1, i1)
		end

		local file2 = config.GetDataPath() .. currentIteration .. '/' .. step .. '_objseg.jpg'
		local i2 = uetorch.ObjectSegmentation(actors, config.GetStride())

		if i2 then
			image.save(file2,i2)
		end

		local i3 = uetorch.ObjectMasks(actors, config.GetStride())

		if i3 then
			actor = 1

			for k, v in pairs(block.actors) do
				local file = config.GetDataPath() .. currentIteration .. '/' .. step .. '_' .. k .. '.jpg'
				image.save(file,i3[actor])
				actor = actor + 1
			end
		end

		t_last_save = t3
	end
end

block.set_block()

if config.GetSave() then
	uetorch.AddTickHook(SaveScreen)
end