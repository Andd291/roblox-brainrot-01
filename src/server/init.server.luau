-- init.server.luau — Brainrot Bazaar server bootstrap: build the 3D world, create
-- the remotes, then start every service in dependency order. StateService holds
-- all player data; the other services read and change it through that one place.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

-- Remotes first, so no service fires before the client can hear it.
local remotes = Remotes.createRemotes()

local WorldBuilder = require(script.Parent.WorldBuilder)
local StateService = require(script.Parent.StateService)
local BaseService = require(script.Parent.BaseService)
local SpawnerService = require(script.Parent.SpawnerService)
local StealService = require(script.Parent.StealService)
local WaveService = require(script.Parent.WaveService)
local RebirthService = require(script.Parent.RebirthService)

-- The world (bases, conveyor, decorations, tsunami wall) exists before any
-- player is handed a base or a brainrot is spawned onto the belt.
local world = WorldBuilder.buildWorld()

StateService.init(remotes)
BaseService.init(world, remotes)
SpawnerService.init(world, remotes)
StealService.init(world, remotes)
WaveService.init(world, remotes)
RebirthService.init(world, remotes)

-- Wire the remote requests to the services that answer them.
remotes.BuyBrainrot.OnServerEvent:Connect(function(player, brainrotId)
	SpawnerService.tryBuyBrainrot(player, brainrotId)
end)

remotes.StealBrainrot.OnServerEvent:Connect(function(player, brainrotId)
	StealService.tryStealBrainrot(player, brainrotId)
end)

remotes.ToggleLock.OnServerEvent:Connect(function(player)
	StealService.toggleBaseLock(player)
end)

remotes.RequestRebirth.OnServerEvent:Connect(function(player)
	RebirthService.tryRebirth(player)
end)

remotes.BuyUpgrade.OnServerEvent:Connect(function(player, upgradeId)
	RebirthService.tryBuyUpgrade(player, upgradeId)
end)

-- A player who joins gets a base, starting money and a leaderstats row.
Players.PlayerAdded:Connect(function(player)
	StateService.registerPlayer(player)
	BaseService.assignBaseToPlayer(player)
	StateService.pushStateToPlayer(player)
end)

-- A player who leaves gives their base back and drops anything they carried.
Players.PlayerRemoving:Connect(function(player)
	StealService.dropCarriedBrainrot(player, "left")
	BaseService.releaseBaseOfPlayer(player)
	StateService.unregisterPlayer(player)
end)

print("[Brainrot Bazaar] server started: world built, services running.")
