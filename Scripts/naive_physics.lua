local uetorch = require 'uetorch'
local image = require 'image'
local config = require 'config'
local block

uetorch.SetTickDeltaBounds(1/16, 1/16)
-- functions called from MainMap_CameraActor_Blueprint
GetSceneTime = config.GetSceneTime
RunBlock = nil

local iterationId
local iterationType
local iterationBlock

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

		local file = config.GetDataPath() .. iterationId .. '/screen_' .. step .. '_' .. iterationType .. '.jpg'
		local i1 = uetorch.Screen()
		if i1 then
			image.save(file, i1)
		end

		file = config.GetDataPath() .. iterationId .. '/objseg_' .. step .. '_' .. iterationType .. '.jpg'
		--local i2 = uetorch.ObjectSegmentation(actors, config.GetStride())
		if i2 then
			image.save(file,i2)
		end

		--local i3 = uetorch.ObjectMasks(actors, config.GetStride())
		if i3 then
			actor = 1

			for k, v in pairs(block.actors) do
				file = config.GetDataPath() .. iterationId .. '/' .. k .. '_' .. step .. '_' .. iterationType .. '.jpg'
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

local function SaveStatusToTable(dt)
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
	iterationId, iterationType, iterationBlock = config.GetIterationInfo(iteration)
	print('current iteration :', iteration, iterationId, iterationType, iterationBlock)

	block = require(iterationBlock)
	actors = dict_to_array(block.actors)
	block.SetBlock(currentIteration)
	RunBlock = function()
		return block.RunBlock()
	end

	if iterationType == 0 then
		uetorch.SetActorVisible(floor, false)
		uetorch.SetActorVisible(fog, false)
		uetorch.DestroyActor(lightsource)
		uetorch.DestroyActor(skylight)
		uetorch.AddTickHook(CheckVisibility)
	end

	if config.GetSave() then
		uetorch.AddTickHook(SaveScreen)
		uetorch.AddTickHook(SaveStatusToTable)
	end
end

function SaveData()
	if iterationType == 0 then
		torch.save(config.GetDataPath() .. iterationId .. '/hidden.t7', isHidden)
	end

	local filename = config.GetDataPath() .. iterationId .. '/data_' .. iterationType .. '.txt'
	local file = assert(io.open(filename, "w"))
	file:write("block = " .. iterationBlock .. "\n")

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
			local loc = v[k2]["location"]
			file:write("x = " .. loc["x"] .. " y = " .. loc["y"] .. " z = " .. loc["z"] .. "\n")
			local rot = v[k2]["rotation"]
			file:write("pitch = " .. rot["pitch"] .. " roll = " .. rot["roll"] .. " yaw = " .. rot["yaw"] .. "\n")
		end
	end

	file:close()
end