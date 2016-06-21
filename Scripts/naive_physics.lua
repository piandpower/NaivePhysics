local uetorch = require 'uetorch'
local image = require 'image'
local config = require 'config'
local block

uetorch.SetTickDeltaBounds(1/16, 1/16)
GetSceneTime = config.GetSceneTime

local currentIteration = 0
local r = math.random(5)
local ground_materials = {"M_Basic_Floor", "M_Ground_Grass", "M_Ground_Moss", "M_Wood_Floor_Walnut_Polished", "M_Wood_Floor_Walnut_Worn"}

local function SetGroundMaterial(id)
	local materialId = "Material'/Game/StarterContent/Materials/" .. ground_materials[id] .. "." .. ground_materials[id] .. "'"
	local material = UE.FindObject(Material.Class(), nil, materialId)
	local floor = uetorch.GetActor('Floor')
	uetorch.SetMaterial(floor, material)
end

local function dict_to_array(a)
	local ret = {}
	local i = 1
	for k, v in pairs(a) do
		ret[i] = v
		i = i + 1
	end
	return ret
end

local actors = {}
local t_last_save = 0
local t3 = 0
local step = 0

local function SaveScreen(dt)
	t3 = t3 + dt

	if t3 - t_last_save >= config.GetScreenCaptureInterval() then
		step = step + 1
		local file = config.GetDataPath() .. currentIteration .. '/' .. step .. '_screen.jpg'
		local i1 = uetorch.Screen()

		if i1 then
			image.save(file, i1)
		end

		file = config.GetDataPath() .. currentIteration .. '/' .. step .. '_objseg.jpg'
		--local i2 = uetorch.ObjectSegmentation(actors, config.GetStride())

		if i2 then
			image.save(file,i2)
		end

		--local i3 = uetorch.ObjectMasks(actors, config.GetStride())

		if i3 then
			actor = 1

			for k, v in pairs(block.actors) do
				file = config.GetDataPath() .. currentIteration .. '/' .. step .. '_' .. k .. '.jpg'
				image.save(file,i3[actor])
				actor = actor + 1
			end
		end

		t_last_save = t3
	end
end

local data = {}
local t_text = 0

local function SaveTextHook(dt)
	local aux = {t = t_text}
	--print(t_text)
	for k,v in pairs(block.actors) do
		--print(k,v)
		aux[k] = {
			location = uetorch.GetActorLocation(v),
			rotation = uetorch.GetActorRotation(v)
		}
	end
	table.insert(data, aux)
	t_text = t_text + dt
end

function SetCurrentIteration(iteration)
	currentIteration = iteration
	print('current iteration =', currentIteration)

	SetGroundMaterial(r)

	block = require(config.GetBlock(currentIteration))
	actors = dict_to_array(block.actors)
	block.set_block()

	if config.GetSave() then
		uetorch.AddTickHook(SaveScreen)
		uetorch.AddTickHook(SaveTextHook)
	end
end

function SaveData()
	local filename = config.GetDataPath() .. currentIteration .. '/data.txt'
	local file = assert(io.open(filename, "w"))
	file:write("block = " .. config.GetBlock(currentIteration) .. "\n")

	for k, v in ipairs(data) do
		file:write("step = " .. k .. "\n")
		file:write("t = " .. v["t"] .. "\n")

		for k2,v2 in pairs(block.actors) do
			file:write("actor = " .. k2 .. "\n")

			for k3,v3 in pairs(v[k2]["location"]) do
				file:write(k3 .. " = " .. v3 .. "\n")
			end

			for k3,v3 in pairs(v[k2]["rotation"]) do
				file:write(k3 .. " = " .. v3 .. "\n")
			end
		end
	end

	file:close()
end