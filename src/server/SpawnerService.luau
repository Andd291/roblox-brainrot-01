-- SpawnerService.luau — the conveyor belt: wild brainrots roll onto it, walk
-- from START to END, and any player with enough money can press E to buy one
-- and send it to their base. What is not bought is washed off at the end.

local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Util = require(Shared.Util)
local BrainrotData = require(Shared.BrainrotData)
local BrainrotFactory = require(Shared.BrainrotFactory)

local SpawnerService = {}

local world = nil
local remotes = nil
local active = {}
local nextId = 0
local MAX_ON_BELT = 12

function SpawnerService.init(worldTable, remoteTable)
	world = worldTable
	remotes = remoteTable
	-- A new wild brainrot rolls onto the belt every few seconds.
	task.spawn(function()
		while true do
			task.wait(Config.CONVEYOR_SPAWN_INTERVAL)
			SpawnerService.spawnBrainrotOnConveyor()
		end
	end)
	-- The belt moves: every frame each brainrot walks a step toward the end.
	RunService.Heartbeat:Connect(function(dt)
		local toDespawn = {}
		for brainrotId, brainrot in pairs(active) do
			brainrot.x = brainrot.x + Config.CONVEYOR_SPEED * dt
			local bob = math.sin(os.clock() * 3 + brainrot.phase) * 0.15
			brainrot.model:PivotTo(CFrame.new(brainrot.x, Config.CONVEYOR_Y + bob, Config.CONVEYOR_Z) * CFrame.Angles(0, math.pi / 2, 0))
			if brainrot.x > Config.CONVEYOR_END_X then
				table.insert(toDespawn, brainrotId)
			end
		end
		for _, brainrotId in ipairs(toDespawn) do
			SpawnerService.despawnBrainrot(brainrotId)
		end
	end)
end

-- Roll a wild brainrot and put it on the belt at the START arch.
function SpawnerService.spawnBrainrotOnConveyor()
	local count = 0
	for _ in pairs(active) do
		count = count + 1
	end
	if count >= MAX_ON_BELT then
		return nil
	end
	nextId = nextId + 1
	local brainrotId = "br" .. tostring(nextId)
	local entry = BrainrotData.rollCatalogEntry()
	local mutation = BrainrotData.rollMutation()
	local rate = BrainrotData.getRate(entry, mutation)
	local cost = BrainrotData.getCost(entry, mutation)
	local model = BrainrotFactory.buildBrainrotModel(entry, mutation, brainrotId)
	model:PivotTo(CFrame.new(Config.CONVEYOR_START_X, Config.CONVEYOR_Y, Config.CONVEYOR_Z) * CFrame.Angles(0, math.pi / 2, 0))
	model.Parent = world.conveyorFolder
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy"
	prompt.ObjectText = entry.name .. " • " .. entry.rarity .. " • " .. Util.formatRate(rate) .. " — " .. Util.formatMoney(cost)
	prompt.HoldDuration = 0
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		SpawnerService.tryBuyBrainrot(player, brainrotId)
	end)
	active[brainrotId] = {
		id = brainrotId,
		model = model,
		entry = entry,
		mutation = mutation,
		rate = rate,
		cost = cost,
		x = Config.CONVEYOR_START_X,
		phase = math.random() * math.pi * 2,
	}
	return brainrotId
end

-- A brainrot that reached the end of the belt leaves without a buyer.
function SpawnerService.despawnBrainrot(brainrotId)
	local brainrot = active[brainrotId]
	if not brainrot then
		return
	end
	active[brainrotId] = nil
	brainrot.model:Destroy()
end

-- Buy the brainrot off the belt: pay, then it moves to a free plot on the
-- buyer's base and starts earning. False buys leave the money alone.
function SpawnerService.tryBuyBrainrot(player, brainrotId)
	local brainrot = active[brainrotId]
	if not brainrot then
		return
	end
	local StateService = require(script.Parent.StateService)
	local BaseService = require(script.Parent.BaseService)
	local data = StateService.getData(player)
	if not data then
		return
	end
	if not data.baseIndex then
		StateService.sendFeedMessage(player, "You need a base first — walk into an empty one!")
		return
	end
	if data.money < brainrot.cost then
		StateService.sendFeedMessage(player, "Not enough money for " .. brainrot.entry.name .. " (" .. Util.formatMoney(brainrot.cost) .. ")!")
		return
	end
	local plotIndex, _ = BaseService.findFreePlot(player)
	if not plotIndex then
		StateService.sendFeedMessage(player, "Your base is full! Buy a Capacity upgrade first.")
		return
	end
	if not StateService.spendMoney(player, brainrot.cost) then
		return
	end
	active[brainrotId] = nil
	local model = brainrot.model
	local prompt = model.PrimaryPart:FindFirstChild("BuyPrompt")
	if prompt then
		prompt:Destroy()
	end
	local displayName = brainrot.entry.name
	if brainrot.mutation.name ~= "None" then
		displayName = brainrot.mutation.name .. " " .. brainrot.entry.name
	end
	local record = {
		id = brainrotId,
		catalogId = brainrot.entry.id,
		name = displayName,
		rarity = brainrot.entry.rarity,
		mutation = brainrot.mutation.name,
		rate = brainrot.rate,
		cost = brainrot.cost,
		plotIndex = nil,
		model = model,
	}
	BaseService.placeBrainrotOnPlot(player, record)
	StateService.pushStateToPlayer(player)
	StateService.sendFeedMessage(player, "You bought " .. displayName .. " (" .. Util.formatRate(brainrot.rate) .. ")!")
	if remotes then
		local plotPosition = BaseService.getBase(player).plots[plotIndex]
		remotes.PlayEffect:FireAllClients("BuySparkle", plotPosition)
	end
end

-- How many wild brainrots are on the belt right now (for the HUD's next tier).
function SpawnerService.countOnBelt()
	local count = 0
	for _ in pairs(active) do
		count = count + 1
	end
	return count
end

-- Put a brainrot that was dropped back onto the belt as a wild one, so it can
-- be bought again instead of vanishing.
function SpawnerService.returnBrainrotToBelt(record)
	local model = record.model
	if not model or not model.Parent then
		return nil
	end
	local prompt = model.PrimaryPart:FindFirstChild("StealPrompt")
	if prompt then
		prompt:Destroy()
	end
	model:PivotTo(CFrame.new(Config.CONVEYOR_START_X, Config.CONVEYOR_Y, Config.CONVEYOR_Z) * CFrame.Angles(0, math.pi / 2, 0))
	model.Parent = world.conveyorFolder
	local buyPrompt = Instance.new("ProximityPrompt")
	buyPrompt.Name = "BuyPrompt"
	buyPrompt.ActionText = "Buy"
	buyPrompt.ObjectText = record.name .. " • " .. record.rarity .. " • " .. Util.formatRate(record.rate) .. " — " .. Util.formatMoney(record.cost)
	buyPrompt.HoldDuration = 0
	buyPrompt.KeyboardKeyCode = Enum.KeyCode.E
	buyPrompt.MaxActivationDistance = 14
	buyPrompt.RequiresLineOfSight = false
	buyPrompt.Parent = model.PrimaryPart
	buyPrompt.Triggered:Connect(function(player)
		SpawnerService.tryBuyBrainrot(player, record.id)
	end)
	active[record.id] = {
		id = record.id,
		model = model,
		entry = BrainrotData.getEntry(record.catalogId),
		mutation = { name = record.mutation, multiplier = 1 },
		rate = record.rate,
		cost = record.cost,
		x = Config.CONVEYOR_START_X,
		phase = math.random() * math.pi * 2,
	}
	return record.id
end

-- The tsunami sweeps the belt clean: every wild brainrot is washed away.
function SpawnerService.washConveyorBrainrots()
	local ids = {}
	for brainrotId in pairs(active) do
		table.insert(ids, brainrotId)
	end
	for _, brainrotId in ipairs(ids) do
		SpawnerService.despawnBrainrot(brainrotId)
	end
end

return SpawnerService
