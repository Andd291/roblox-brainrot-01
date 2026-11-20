-- BaseService.luau — the eight player bases: who owns which, which plot a
-- brainrot sits on, the money tick that pays every brainrot every second, and
-- the test for whether a player is standing safe inside their own base.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)

local BaseService = {}

local world = nil
local remotes = nil
local baseOwners = {}

function BaseService.init(worldTable, remoteTable)
	world = worldTable
	remotes = remoteTable
	-- The money tick: every second each brainrot pays its owner.
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local income = BaseService.getIncomePerSecond(player)
				if income > 0 then
					local StateService = require(script.Parent.StateService)
					StateService.addMoney(player, income)
					StateService.pushStateToPlayer(player)
				end
			end
		end
	end)
end

-- The base table for one player, or nil before they claimed one.
function BaseService.getBase(player)
	local StateService = require(script.Parent.StateService)
	local data = StateService.getData(player)
	if not data or not data.baseIndex then
		return nil
	end
	return world.bases[data.baseIndex]
end

-- Where a player's character spawns: their base, or the plaza if unclaimed.
function BaseService.getSpawnPositionForPlayer(player)
	local base = BaseService.getBase(player)
	if base then
		return base.spawnPosition
	end
	return Vector3.new(0, 3, 30)
end

-- How many plots this player's base holds with their capacity upgrades.
function BaseService.getPlotCapacity(player)
	local StateService = require(script.Parent.StateService)
	local data = StateService.getData(player)
	if not data then
		return Config.PLOTS_PER_BASE
	end
	return Config.getPlotCapacity(data.upgrades.capacity)
end

-- Hand the first free base to a player and name it after them.
function BaseService.assignBaseToPlayer(player)
	local StateService = require(script.Parent.StateService)
	local data = StateService.getData(player)
	if not data then
		return nil
	end
	for i, base in ipairs(world.bases) do
		if not baseOwners[i] then
			baseOwners[i] = player
			data.baseIndex = i
			base.bannerOwnerLabel.Text = player.DisplayName .. " (@" .. player.Name .. ")"
			local character = player.Character
			if character then
				local root = character:FindFirstChild("HumanoidRootPart")
				if root then
					root.CFrame = CFrame.new(base.spawnPosition)
				end
			end
			return i
		end
	end
	return nil
end

-- Free a player's base when they leave, and clear their brainrots from it.
function BaseService.releaseBaseOfPlayer(player)
	local StateService = require(script.Parent.StateService)
	local data = StateService.getData(player)
	if not data or not data.baseIndex then
		return
	end
	local base = world.bases[data.baseIndex]
	for _, record in pairs(data.owned) do
		if record.model then
			record.model:Destroy()
		end
	end
	data.owned = {}
	base.bannerOwnerLabel.Text = "empty — walk in to claim it"
	baseOwners[data.baseIndex] = nil
	data.baseIndex = nil
end

-- The first free plot on a player's base: its index and world position.
function BaseService.findFreePlot(player)
	local StateService = require(script.Parent.StateService)
	local data = StateService.getData(player)
	local base = BaseService.getBase(player)
	if not data or not base then
		return nil, nil
	end
	local capacity = BaseService.getPlotCapacity(player)
	local maxPlots = math.min(capacity, #base.plots)
	local taken = {}
	for _, record in pairs(data.owned) do
		taken[record.plotIndex] = true
	end
	for i = 1, maxPlots do
		if not taken[i] then
			return i, base.plots[i]
		end
	end
	return nil, nil
end

-- Set a brainrot down on a free plot of the player's base, facing the plaza,
-- with a Steal prompt for everyone else. Returns the plot index or nil.
function BaseService.placeBrainrotOnPlot(player, record)
	local plotIndex, plotPosition = BaseService.findFreePlot(player)
	if not plotIndex then
		return nil
	end
	local base = BaseService.getBase(player)
	local StateService = require(script.Parent.StateService)
	local data = StateService.getData(player)
	if not data or not base then
		return nil
	end
	record.plotIndex = plotIndex
	data.owned[record.id] = record
	local model = record.model
	model:PivotTo(CFrame.new(plotPosition) * CFrame.Angles(0, base.angle + math.pi, 0))
	model.Parent = world.placedFolder
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "Steal"
	prompt.ObjectText = record.name .. " — " .. record.rate .. "/s"
	prompt.HoldDuration = 0
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(thief)
		require(script.Parent.StealService).tryStealBrainrot(thief, record.id)
	end)
	return plotIndex
end

-- Lift a brainrot off a player's base (stolen, rebirthed or returned).
function BaseService.removeBrainrotFromPlot(player, brainrotId)
	local StateService = require(script.Parent.StateService)
	local data = StateService.getData(player)
	if not data then
		return nil
	end
	local record = data.owned[brainrotId]
	if record then
		data.owned[brainrotId] = nil
	end
	return record
end

-- The money per second a player's brainrots earn, after their multiplier.
function BaseService.getIncomePerSecond(player)
	local StateService = require(script.Parent.StateService)
	local data = StateService.getData(player)
	if not data then
		return 0
	end
	local total = 0
	for _, record in pairs(data.owned) do
		total = total + record.rate
	end
	return total * StateService.getIncomeMultiplier(player)
end

-- Is this player standing inside their own base's pad? The wave cannot wash
-- them there, and a carried brainrot is placed down there.
function BaseService.isPlayerInsideOwnBase(player)
	local base = BaseService.getBase(player)
	if not base then
		return false
	end
	local character = player.Character
	if not character then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local frame = CFrame.new(base.center) * CFrame.Angles(0, base.angle, 0)
	local localPoint = frame:PointToObjectSpace(root.Position)
	return math.abs(localPoint.X) <= 9 and math.abs(localPoint.Z) <= 9
end

-- Show or hide the lock shield over a base.
function BaseService.setBaseLockVisual(baseIndex, locked)
	local base = world.bases[baseIndex]
	if base then
		base.shield.Visible = locked
	end
end

return BaseService
