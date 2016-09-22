local uetorch = require 'uetorch'
local image = require 'image'
local config = require 'config'
local utils = require 'utils'
local block

uetorch.SetTickDeltaBounds(1/8, 1/8)
uetorch.SetResolution(512, 288) -- keep the 16:9 proportion

-- functions called from MainMap_CameraActor_Blueprint
GetCurrentIteration = utils.GetCurrentIteration
RunBlock = nil

-- replace uetorch's Tick function
Tick = utils.Tick

local iterationId
local iterationType
local iterationBlock

local screenTable = {}
local tLastSaveScreen = 0
local tSaveScreen = 0
local step = 0

local function SaveScreen(dt)
	if tSaveScreen - tLastSaveScreen >= config.GetBlockCaptureInterval(iterationBlock) then
		step = step + 1

		local file = config.GetDataPath() .. iterationId .. '/screen_' .. step .. '_' .. iterationType .. '.jpg'
		local i1 = uetorch.Screen()

		if config.GetStitch() then
			table.insert(screenTable, i1)
		else
			if i1 then
				image.save(file, i1)
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
	if tSaveText - tLastSaveText >= config.GetBlockCaptureInterval(iterationBlock) then
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

local visibilityTable = {}
local tCheck, tLastCheck = 0, 0
local step = 0
local hidden = false
local isHidden = {}

local function CheckVisibility(dt)
	if tCheck - tLastCheck >= config.GetBlockCaptureInterval(iterationBlock) then
		step = step + 1
		local file = config.GetDataPath() .. iterationId .. '/screenv_' .. step .. '_' .. iterationType .. '.jpg'
		local actors = {block.MainActor()}
		local i2 = uetorch.ObjectSegmentation(actors, config.GetStride())

		if i2 then
			if config.GetStitch() then
				table.insert(visibilityTable, i2)
			else
				image.save(file, i2)
			end

			if torch.max(i2) == 0 then
				hidden = true
			else
				hidden = false
			end
		end

		table.insert(isHidden, hidden)
		tLastCheck = tCheck
	end
	tCheck = tCheck + dt
end

local function SaveData()
	if config.IsVisibilityCheck(iterationBlock, iterationType) then
		local nHidden = #isHidden

		for k = 1,nHidden do
			if not isHidden[k] then
				break
			else
				isHidden[k] = false
			end
		end

		for k = nHidden,1,-1 do
			if not isHidden[k] then
				break
			else
				isHidden[k] = false
			end
		end

		torch.save(config.GetDataPath() .. iterationId .. '/hidden_' .. iterationType .. '.t7', isHidden)
	else
		local filename = config.GetDataPath() .. iterationId .. '/data_' .. iterationType .. '.txt'
		local file = assert(io.open(filename, "w"))
		file:write("block = " .. iterationBlock .. "\n")

		local possible = block.IsPossible()
		if possible then
			file:write("possible = true\n")
		else
			file:write("possible = false\n")
		end

		local floor = uetorch.GetActor('Floor')
		local bounds = uetorch.GetActorBounds(floor)
		local minx = bounds["x"] - bounds["boxX"]
		local maxx = bounds["x"] + bounds["boxX"]
		local miny = bounds["y"] - bounds["boxY"]
		local maxy = bounds["y"] + bounds["boxY"]
		file:write("minX = " .. minx .. " maxX = " .. maxx .. " minY = " .. miny .. " maxY = " .. maxy .. "\n")

		local nactors = 0
		for k,v in pairs(block.actors) do
			nactors = nactors + 1
		end
		file:write("number of actors = " .. nactors .. "\n")

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
end

local function SaveStitchedImages()
	if config.IsVisibilityCheck(iterationBlock, iterationType) then
		local filename = config.GetDataPath() .. iterationId .. '/screenv_' .. iterationType .. '.jpg'
		local height = visibilityTable[1]:size(1)
		local width = visibilityTable[1]:size(2)
		local result = torch.IntTensor(height * #visibilityTable, width)

		for k,v in ipairs(visibilityTable) do
			local aux = result:narrow(1, 1 + (k - 1) * height, height)
			aux:copy(v)
		end
		image.save(filename, result)
	else
		local filename = config.GetDataPath() .. iterationId .. '/screen_' .. iterationType .. '.jpg'
		local height = screenTable[1]:size(2)
		local width = screenTable[1]:size(3)
		local result = torch.Tensor(3, height * #screenTable, width)

		for k,v in ipairs(screenTable) do
			local aux = result:narrow(2, 1 + (k - 1) * height, height)
			aux:copy(v)
		end
		image.save(filename, result)
	end
end

function SetCurrentIteration()
	local currentIteration = utils.GetCurrentIteration()
	iterationId, iterationType, iterationBlock = config.GetIterationInfo(currentIteration)
	print('current iteration :', currentIteration, iterationId, iterationType, iterationBlock)

	block = require(iterationBlock)
	block.SetBlock(currentIteration)
	RunBlock = function()
		return block.RunBlock()
	end

	utils.SetTicksRemaining(config.GetBlockTicks(iterationBlock))
	if config.IsVisibilityCheck(iterationBlock, iterationType) then
		utils.AddTickHook(CheckVisibility)
	else
		utils.AddTickHook(SaveScreen)
	end
	utils.AddTickHook(SaveStatusToTable)
	utils.AddTickHook(block.SaveCheckInfo)
	utils.AddEndTickHook(block.Check)
	utils.AddEndTickHook(SaveData)
	if config.GetStitch() then
		utils.AddEndTickHook(SaveStitchedImages)
	end
end