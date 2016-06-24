local uetorch = require 'uetorch'
local image = require 'image'
local config = require 'config'
local block

uetorch.SetTickDeltaBounds(1/16, 1/16)
GetSceneTime = config.GetSceneTime

local currentIteration = 0
local r = math.random(5)
local ground_materials = {"M_Basic_Floor", "M_Ground_Grass", "M_Ground_Moss", "M_Wood_Floor_Walnut_Polished", "M_Wood_Floor_Walnut_Worn"}
local floor = uetorch.GetActor('Floor')

local function SetGroundMaterial(id)
	local materialId = "Material'/Game/StarterContent/Materials/" .. ground_materials[id] .. "." .. ground_materials[id] .. "'"
	local material = UE.FindObject(Material.Class(), nil, materialId)
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
local tLastSaveScreen = 0
local tSaveScreen = 0
local step = 0

local function SaveScreen(dt)
	if tSaveScreen - tLastSaveScreen >= config.GetScreenCaptureInterval() then
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

		tLastSaveScreen = tSaveScreen
	end
	tSaveScreen = tSaveScreen + dt
end

local data = {}
local tSaveText = 0
local tLastSaveText = 0

local function SaveTextHook(dt)
	local aux = {t = tSaveText}
	if tSaveText - tLastSaveText >= config.GetScreenCaptureInterval() then
		for k,v in pairs(block.actors) do
			aux[k] = {
				location = uetorch.GetActorLocation(v),
				rotation = uetorch.GetActorRotation(v)
			}
		end
		table.insert(data, aux)

		tLastSaveText = tSaveText
	end
	tSaveText = tSaveText + dt
end

function SetCurrentIteration(iteration)
	currentIteration = iteration
	print('current iteration =', currentIteration)

	SetGroundMaterial(r)

	block = require(config.GetBlock(currentIteration))
	actors = dict_to_array(block.actors)
	block.SetBlock()

	if config.GetSave() then
		uetorch.AddTickHook(SaveScreen)
		uetorch.AddTickHook(SaveTextHook)
	end
end

function SaveData()
	local filename = config.GetDataPath() .. currentIteration .. '/data.txt'
	local file = assert(io.open(filename, "w"))
	file:write("block = " .. config.GetBlock(currentIteration) .. "\n")

	local possible = block.IsPossible()
	if possible then
		file:write("possible = true\n")
	else
		file:write("possible = false\n")
	end
	
	local bounds = uetorch.GetActorBounds(floor)
	local minx = bounds["x"] - bounds["boxX"]
	local maxx = bounds["x"] + bounds["boxX"]
	local miny = bounds["y"] - bounds["boxY"]
	local maxy = bounds["y"] + bounds["boxY"]
	file:write("minX = " .. minx .. " maxX = " .. maxx .. " minY = " .. miny .. " maxY = " .. maxy .. "\n")

	for k, v in ipairs(data) do
		file:write("step = " .. k .. "\n")
		file:write("t = " .. v["t"] .. "\n")

		for k2,v2 in pairs(block.actors) do
			file:write("actor = " .. k2 .. "\n")

			for k3,v3 in pairs(v[k2]["location"]) do
				file:write(k3 .. " = " .. v3 .. " ")
			end
			file:write("\n")
			for k3,v3 in pairs(v[k2]["rotation"]) do
				file:write(k3 .. " = " .. v3 .. " ")
			end
			file:write("\n")
		end
	end

	file:close()
end