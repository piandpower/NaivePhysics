local uetorch = require 'uetorch'
local config = require 'config'
local utils = {}

utils.ground_materials = {"M_Basic_Floor", "M_Ground_Grass", "M_Ground_Moss", "M_Wood_Floor_Walnut_Polished", "M_Wood_Floor_Walnut_Worn"}

function utils.SetActorMaterial(actor, id)
	local materialId = "Material'/Game/StarterContent/Materials/" .. id .. "." .. id .. "'"
	local material = UE.FindObject(Material.Class(), nil, materialId)
	uetorch.SetMaterial(actor, material)
end

function utils.GetCurrentIteration()
	local iteration = torch.load(conf.dataPath .. 'iterations.t7')
	return iteration
end

function utils.UpdateIterationsCounter(check)
	local iteration = utils.GetCurrentIteration()
	local iterationId, iterationType, iterationBlock = config.GetIterationInfo(iteration)

	if check then
		iteration = iteration - 1
	else
		iteration = iteration + config.GetBlockSize(iterationBlock) - 1
	end

	torch.save(conf.dataPath .. 'iterations.t7', iteration)
end

local TickHooks = {}
local EndTickHooks = {}

-- add a tick 'hook' function f called at each game loop tick
-- tick hooks should take a single argument (dt) and return nothing.
function utils.AddTickHook(f)
	table.insert(TickHooks, f)
end

function utils.AddEndTickHook(f)
	table.insert(EndTickHooks, f)
end

-- remove the function f from the set of tick hooks
function utils.RemoveTickHook(f)
	for i = #TickHooks, 1, -1 do
		if TickHooks[i] == f then
			table.remove(TickHooks, i)
		end
	end
end

local TicksRemaining

function utils.SetTicksRemaining(ticks)
	print("TicksRemaining : " .. ticks)
	TicksRemaining = ticks
end

local tickCount = 1
local foundError = false

function utils.Tick(dt)
	tickCount = tickCount + 1
	dt = 1
	if TicksRemaining then
		TicksRemaining = TicksRemaining - dt
		if TicksRemaining < 0 then
			TicksRemaining = nil
			for ii, hook in ipairs(EndTickHooks) do
				hook()
			end
			uetorch.ExecuteConsoleCommand("RestartLevel")
		else
			for ii, hook in ipairs(TickHooks) do
				hook(dt)
			end
		end
	elseif not foundError then
		foundError = true
		print("no TicksRemaining")
	end
end

return utils