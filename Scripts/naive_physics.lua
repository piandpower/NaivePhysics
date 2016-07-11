local uetorch = require 'uetorch'
local image = require 'image'
local config = require 'config'
local block

uetorch.SetTickDeltaBounds(1/16, 1/16)
-- functions called from MainMap_CameraActor_Blueprint
GetSceneTime = nil
RunBlock = nil

local currentIteration = 0
local folderid = 0
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

		local file = config.GetDataPath() .. folderid .. '/' .. step .. '_screen.jpg'
		local i1 = uetorch.Screen()
		if i1 then
			image.save(file, i1)
		end

		file = config.GetDataPath() .. folderid .. '/' .. step .. '_objseg.jpg'
		--local i2 = uetorch.ObjectSegmentation(actors, config.GetStride())
		if i2 then
			image.save(file,i2)
		end

		--local i3 = uetorch.ObjectMasks(actors, config.GetStride())
		if i3 then
			actor = 1

			for k, v in pairs(block.actors) do
				file = config.GetDataPath() .. folderid .. '/' .. step .. '_' .. k .. '.jpg'
				image.save(file,i3[actor])
				actor = actor + 1
			end
		end

		tLastSaveScreen = tSaveScreen
	end
	tSaveScreen = tSaveScreen + dt
end

local function SaveBlackScreen(dt)
	if tSaveScreen - tLastSaveScreen >= config.GetScreenCaptureInterval() then
		step = step + 1

		local file = config.GetDataPath() .. folderid .. '/' .. step .. '_blackscreen.jpg'
		local i1 = uetorch.Screen()
		if i1 then
			image.save(file, i1)
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

local fog = uetorch.GetActor('AtmosphericFog_1')
local lightsource = uetorch.GetActor('LightSource')
local skylight = uetorch.GetActor('SkyLight_1')

local tCheck, tLastCheck = 0, 0
local step = 0
local hidden = false
local isHidden = {}

local function CheckVisibility(dt)
	if tCheck - tLastCheck >= config.GetScreenCaptureInterval() then
		step = step + 1
		local img = uetorch.Screen()

		if torch.max(img) <= 0.0236 then
			hidden = true
		else
			hidden = false
		end

		table.insert(isHidden, hidden)
		tLastCheck = tCheck
	end
	tCheck = tCheck + dt
end

function SetCurrentIteration(iteration)
	currentIteration = tonumber(iteration)
	folderid = math.ceil(currentIteration / 2)
	print('current iteration =', folderid)

	GetSceneTime = function(iteration)
		return config.GetSceneTime(folderid)
	end

	SetGroundMaterial(r)

	block = require(config.GetBlock(folderid))
	actors = dict_to_array(block.actors)
	block.SetBlock(currentIteration)
	RunBlock = function()
		return block.RunBlock()
	end

	if currentIteration % 2 == 0 then
		uetorch.SetActorVisible(floor, false)
		uetorch.SetActorVisible(fog, false)
		uetorch.DestroyActor(lightsource)
		uetorch.DestroyActor(skylight)
		uetorch.AddTickHook(CheckVisibility)
		uetorch.AddTickHook(SaveBlackScreen)
	end

	if config.GetSave() and currentIteration % 2 ~= 0 then
		uetorch.AddTickHook(SaveScreen)
		uetorch.AddTickHook(SaveTextHook)
	end
end

function SaveData()
	if currentIteration % 2 == 0 then
		torch.save(config.GetDataPath() .. folderid .. '/hidden.t7', isHidden)
	else
		local filename = config.GetDataPath() .. folderid .. '/data.txt'
		local file = assert(io.open(filename, "w"))
		file:write("block = " .. config.GetBlock(folderid) .. "\n")

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
end