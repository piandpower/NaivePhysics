local uetorch = require 'uetorch'
local image = require 'image'
local config = require 'config'
local utils = require 'utils'
local block

uetorch.SetTickDeltaBounds(1/8, 1/8)
--uetorch.SetResolution(480, 480)

-- functions called from MainMap_CameraActor_Blueprint
GetSceneTime = config.GetSceneTime
GetCurrentIteration = utils.GetCurrentIteration
RunBlock = nil

-- replace uetorch's Tick function
Tick = utils.Tick

local iterationId
local iterationType
local iterationBlock

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

local tCheck, tLastCheck = 0, 0
local step = 0
local hidden = false
local isHidden = {}

local function CheckVisibility(dt)
	if tCheck - tLastCheck >= config.GetScreenCaptureInterval() then
		step = step + 1
		local file = config.GetDataPath() .. iterationId .. '/screenv_' .. step .. '_' .. iterationType .. '.jpg'
		local i2 = uetorch.ObjectSegmentation({block.MainActor()}, config.GetStride())

		if i2 then
			image.save(file,i2)

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
end

function SaveData()
	if config.IsVisibilityCheck(iterationBlock, iterationType) then
		local nHidden = #isHidden
		local deleted_front = 0
		local deleted_back = 0

		for k = 1,nHidden do
			if not isHidden[k] then
				break
			else
				isHidden[k] = false
				deleted_front = deleted_front + 1
			end
		end

		for k = nHidden,1,-1 do
			if not isHidden[k] then
				break
			else
				isHidden[k] = false
				deleted_back = deleted_back + 1
			end
		end

		local fileHidden = assert(io.open(config.GetDataPath() .. iterationId .. '/check_hidden_' .. iterationType .. '.txt', "w"))
		local found = false
		for k = 1,nHidden do
			if isHidden[k] then
				found = true
				break
			end
		end

		if found then
			fileHidden:write("found hidden\n")
		else
			fileHidden:write("didn't find hidden\n")
		end
		fileHidden:write("deleted front = " .. deleted_front .. "\n")
		fileHidden:write("deleted back = " .. deleted_back .. "\n")

		fileHidden:close()
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