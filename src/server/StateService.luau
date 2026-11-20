-- StateService.luau — the single source of truth for player data. Every other
-- service reads and changes money, brainrots, locks and upgrades through this
-- one table, and every change is pushed to the client as one state update.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Util = require(Shared.Util)

local StateService = {}

local remotes = nil
local playerData = {}

-- A fresh player: starting money, no brainrots, no rebirths, no upgrades.
local function newPlayerData()
	return {
		money = Config.START_MONEY,
		rebirths = 0,
		upgrades = { capacity = 0, income = 0, speed = 0 },
		owned = {},
		carried = nil,
		baseIndex = nil,
		lockUntil = 0,
		lockCooldownUntil = 0,
	}
end

function StateService.init(remoteTable)
	remotes = remoteTable
end

-- Give a new player their data row and a leaderstats row for the player list.
function StateService.registerPlayer(player)
	playerData[player] = newPlayerData()
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local moneyValue = Instance.new("IntValue")
	moneyValue.Name = "Money"
	moneyValue.Value = Config.START_MONEY
	moneyValue.Parent = leaderstats
	local rebirthValue = Instance.new("IntValue")
	rebirthValue.Name = "Rebirths"
	rebirthValue.Value = 0
	rebirthValue.Parent = leaderstats
	leaderstats.Parent = player
	-- Spawn at their base once their character loads, at upgrade speed.
	player.CharacterAdded:Connect(function(character)
		local data = playerData[player]
		if not data then
			return
		end
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.WalkSpeed = Config.getWalkSpeed(data.upgrades.speed)
		local root = character:WaitForChild("HumanoidRootPart")
		local BaseService = require(script.Parent.BaseService)
		local spawnAt = BaseService.getSpawnPositionForPlayer(player)
		if spawnAt then
			root.CFrame = CFrame.new(spawnAt)
		end
	end)
end

function StateService.unregisterPlayer(player)
	playerData[player] = nil
end

-- The mutable data row for one player (nil once they left).
function StateService.getData(player)
	return playerData[player]
end

-- The income multiplier from rebirths and the income upgrade.
function StateService.getIncomeMultiplier(player)
	local data = playerData[player]
	if not data then
		return 1
	end
	return Config.getIncomeMultiplier(data.rebirths, data.upgrades.income)
end

-- How many brainrots a player owns right now.
function StateService.countOwnedBrainrots(player)
	local data = playerData[player]
	if not data then
		return 0
	end
	local count = 0
	for _ in pairs(data.owned) do
		count = count + 1
	end
	return count
end

-- The best (highest-order) rarity a player owns, for the next-tier progress.
function StateService.getBestRarityOrder(player)
	local data = playerData[player]
	if not data then
		return 0
	end
	local BrainrotData = require(Shared.BrainrotData)
	local best = 0
	for _, record in pairs(data.owned) do
		local order = BrainrotData.getRarityOrder(record.rarity)
		if order > best then
			best = order
		end
	end
	return best
end

-- Add money and keep the leaderstats row in step.
function StateService.addMoney(player, amount)
	local data = playerData[player]
	if not data then
		return
	end
	data.money = math.max(0, data.money + amount)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local moneyValue = leaderstats:FindFirstChild("Money")
		if moneyValue then
			moneyValue.Value = math.floor(data.money + 0.5)
		end
	end
end

-- Spend money when the player can afford it; false leaves the balance alone.
function StateService.spendMoney(player, amount)
	local data = playerData[player]
	if not data or data.money < amount then
		return false
	end
	StateService.addMoney(player, -amount)
	return true
end

-- One compact state update for the HUD: money, income, counts, lock, wave.
function StateService.buildStateForPlayer(player)
	local data = playerData[player]
	if not data then
		return nil
	end
	local BaseService = require(script.Parent.BaseService)
	local income = BaseService.getIncomePerSecond(player)
	local bestOrder = StateService.getBestRarityOrder(player)
	local BrainrotData = require(Shared.BrainrotData)
	local nextRarity = BrainrotData.getNextRarity(bestOrder)
	local now = os.clock()
	return {
		money = math.floor(data.money + 0.5),
		moneyText = Util.formatMoney(data.money),
		incomePerSecond = math.floor(income + 0.5),
		incomeText = Util.formatRate(income),
		brainrotCount = StateService.countOwnedBrainrots(player),
		rebirths = data.rebirths,
		upgrades = {
			capacity = data.upgrades.capacity,
			income = data.upgrades.income,
			speed = data.upgrades.speed,
		},
		plotCapacity = Config.getPlotCapacity(data.upgrades.capacity),
		lockActive = now < data.lockUntil,
		lockSecondsLeft = math.max(0, math.floor(data.lockUntil - now + 0.5)),
		lockCooldownLeft = math.max(0, math.floor(data.lockCooldownUntil - now + 0.5)),
		rebirthCost = Config.getRebirthCost(data.rebirths),
		carried = data.carried ~= nil,
		nextRarity = nextRarity,
		bestRarityOrder = bestOrder,
	}
end

-- Push the state to one player.
function StateService.pushStateToPlayer(player)
	if not remotes then
		return
	end
	local state = StateService.buildStateForPlayer(player)
	if state then
		remotes.StateChanged:FireClient(player, state)
	end
end

-- Push the state to every player still in the game.
function StateService.pushStateToAll()
	for _, player in ipairs(Players:GetPlayers()) do
		StateService.pushStateToPlayer(player)
	end
end

-- A short feed line for one player ("You bought Mie Goreng Golem!").
function StateService.sendFeedMessage(player, text)
	if not remotes then
		return
	end
	remotes.PlayEffect:FireClient(player, "Feed", text)
end

-- A feed line for everyone ("Tsunami incoming!").
function StateService.broadcastFeedMessage(text)
	if not remotes then
		return
	end
	remotes.PlayEffect:FireAllClients("Feed", text)
end

return StateService
