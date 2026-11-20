-- StealService.luau — the steal: walk up to another player's base, press E on
-- their brainrot, carry it home over your head and set it down on your own
-- base. A locked base cannot be stolen from, and a thief the tsunami washes
-- drops everything they carried.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)

local StealService = {}

local world = nil
local remotes = nil
-- player -> { record, originalOwner } for every brainrot being carried.
local carried = {}

function StealService.init(worldTable, remoteTable)
	world = worldTable
	remotes = remoteTable
	-- Carried brainrots ride above their thief's head, and are set down the
	-- moment the thief steps inside their own base.
	RunService.Heartbeat:Connect(function()
		for player, info in pairs(carried) do
			local character = player.Character
			if not character then
				continue
			end
			local root = character:FindFirstChild("HumanoidRootPart")
			if not root then
				continue
			end
			local bob = math.sin(os.clock() * 4) * 0.3
			info.record.model:PivotTo(CFrame.new(root.Position + Vector3.new(0, 5 + bob, 0)) * CFrame.Angles(0, math.rad(os.clock() * 90 % 360), 0))
			local BaseService = require(script.Parent.BaseService)
			if BaseService.isPlayerInsideOwnBase(player) then
				StealService.placeCarriedBrainrot(player)
			end
		end
	end)
	-- A thief who dies drops what they carried.
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild("Humanoid")
			humanoid.Died:Connect(function()
				StealService.dropCarriedBrainrot(player, "died")
			end)
		end)
	end)
end

-- Is this player's base locked against stealing right now?
function StealService.isBaseLocked(player)
	local StateService = require(script.Parent.StateService)
	local data = StateService.getData(player)
	return data and os.clock() < data.lockUntil
end

-- Lock your base for a minute so nobody can steal from it, then it recharges.
function StealService.toggleBaseLock(player)
	local StateService = require(script.Parent.StateService)
	local BaseService = require(script.Parent.BaseService)
	local data = StateService.getData(player)
	if not data or not data.baseIndex then
		return
	end
	local now = os.clock()
	if now < data.lockCooldownUntil then
		local left = math.floor(data.lockCooldownUntil - now + 0.5)
		StateService.sendFeedMessage(player, "Lock is recharging — " .. left .. "s left.")
		return
	end
	data.lockUntil = now + Config.LOCK_DURATION
	data.lockCooldownUntil = now + Config.LOCK_DURATION + Config.LOCK_COOLDOWN
	BaseService.setBaseLockVisual(data.baseIndex, true)
	task.delay(Config.LOCK_DURATION, function()
		local fresh = StateService.getData(player)
		if fresh and fresh.baseIndex and os.clock() >= fresh.lockUntil then
			BaseService.setBaseLockVisual(fresh.baseIndex, false)
		end
	end)
	StateService.pushStateToPlayer(player)
	StateService.sendFeedMessage(player, "Base locked for " .. Config.LOCK_DURATION .. "s — nobody can steal from you!")
end

-- Find which player owns a brainrot by its id, searching every base.
local function findBrainrotOwner(brainrotId)
	local StateService = require(script.Parent.StateService)
	for _, player in ipairs(Players:GetPlayers()) do
		local data = StateService.getData(player)
		if data and data.owned[brainrotId] then
			return player, data.owned[brainrotId]
		end
	end
	return nil, nil
end

-- Steal a brainrot off someone else's base and carry it home.
function StealService.tryStealBrainrot(thief, brainrotId)
	local StateService = require(script.Parent.StateService)
	local BaseService = require(script.Parent.BaseService)
	local thiefData = StateService.getData(thief)
	if not thiefData or not thiefData.baseIndex then
		return
	end
	if thiefData.carried then
		StateService.sendFeedMessage(thief, "You are already carrying a brainrot — take it home first!")
		return
	end
	local owner, record = findBrainrotOwner(brainrotId)
	if not owner or not record then
		return
	end
	if owner == thief then
		return
	end
	if StealService.isBaseLocked(owner) then
		StateService.sendFeedMessage(thief, "That base is locked — come back later!")
		return
	end
	local plotIndex, _ = BaseService.findFreePlot(thief)
	if not plotIndex then
		StateService.sendFeedMessage(thief, "Your base is full! Buy a Capacity upgrade first.")
		return
	end
	BaseService.removeBrainrotFromPlot(owner, brainrotId)
	local prompt = record.model.PrimaryPart:FindFirstChild("StealPrompt")
	if prompt then
		prompt:Destroy()
	end
	thiefData.carried = brainrotId
	carried[thief] = { record = record, originalOwner = owner }
	StateService.pushStateToPlayer(thief)
	StateService.pushStateToPlayer(owner)
	StateService.sendFeedMessage(thief, "You stole " .. record.name .. " — run it home!")
	StateService.sendFeedMessage(owner, thief.DisplayName .. " stole your " .. record.name .. "!")
	if remotes then
		remotes.PlayEffect:FireAllClients("StealAlarm", record.model:GetPivot().Position)
	end
end

-- Set a carried brainrot down on a free plot of the thief's own base.
function StealService.placeCarriedBrainrot(player)
	local info = carried[player]
	if not info then
		return
	end
	local StateService = require(script.Parent.StateService)
	local BaseService = require(script.Parent.BaseService)
	local data = StateService.getData(player)
	if not data then
		return
	end
	local plotIndex = BaseService.placeBrainrotOnPlot(player, info.record)
	if not plotIndex then
		StateService.sendFeedMessage(player, "Your base is full! Buy a Capacity upgrade first.")
		return
	end
	carried[player] = nil
	data.carried = nil
	StateService.pushStateToPlayer(player)
	StateService.sendFeedMessage(player, "You placed " .. info.record.name .. " on your base — it earns for you now!")
end

-- Drop what a player is carrying (died, left, or washed by the wave): it goes
-- back to its original owner's base, or onto the belt if that base is full.
function StealService.dropCarriedBrainrot(player, reason)
	local info = carried[player]
	if not info then
		return
	end
	carried[player] = nil
	local StateService = require(script.Parent.StateService)
	local BaseService = require(script.Parent.BaseService)
	local data = StateService.getData(player)
	if data then
		data.carried = nil
	end
	local owner = info.originalOwner
	local ownerData = StateService.getData(owner)
	if ownerData and ownerData.baseIndex then
		local plotIndex = BaseService.placeBrainrotOnPlot(owner, info.record)
		if plotIndex then
			StateService.sendFeedMessage(owner, "Your " .. info.record.name .. " came home (" .. reason .. ")!")
			StateService.pushStateToPlayer(owner)
			return
		end
	end
	local SpawnerService = require(script.Parent.SpawnerService)
	SpawnerService.returnBrainrotToBelt(info.record)
	if ownerData then
		StateService.sendFeedMessage(owner, "Your " .. info.record.name .. " escaped back onto the belt!")
	end
end

return StealService
