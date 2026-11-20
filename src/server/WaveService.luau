-- WaveService.luau — the tsunami: every couple of minutes a warning sounds,
-- then a wall of water sweeps the whole map. Anyone caught outside their own
-- base is washed home and drops what they carried; the belt is swept clean.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)

local WaveService = {}

local world = nil
local remotes = nil

function WaveService.init(worldTable, remoteTable)
	world = worldTable
	remotes = remoteTable
	task.spawn(function()
		task.wait(Config.FIRST_WAVE_DELAY)
		while true do
			WaveService.runOneWave()
			task.wait(Config.WAVE_INTERVAL)
		end
	end)
end

-- Tell every client the wave status, so the HUD banner can warn them.
local function broadcastWaveStatus(status, secondsLeft)
	if not remotes then
		return
	end
	remotes.PlayEffect:FireAllClients("WaveStatus", { status = status, secondsLeft = secondsLeft })
end

-- Wash one player home: back to their base, carrying nothing.
local function washPlayerHome(player)
	local StateService = require(script.Parent.StateService)
	local BaseService = require(script.Parent.BaseService)
	local StealService = require(script.Parent.StealService)
	StealService.dropCarriedBrainrot(player, "washed away")
	local character = player.Character
	if character then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame = CFrame.new(BaseService.getSpawnPositionForPlayer(player))
		end
	end
	StateService.sendFeedMessage(player, "The tsunami washed you home!")
end

-- One full wave: warn, sweep the wall across the map, then reset it.
function WaveService.runOneWave()
	local StateService = require(script.Parent.StateService)
	local BaseService = require(script.Parent.BaseService)
	local SpawnerService = require(script.Parent.SpawnerService)
	-- Warning: ten seconds to run for your base.
	StateService.broadcastFeedMessage("TSUNAMI INCOMING — run to your base!")
	broadcastWaveStatus("warning", Config.WAVE_WARNING)
	for left = Config.WAVE_WARNING, 1, -1 do
		broadcastWaveStatus("warning", left)
		task.wait(1)
	end
	-- The sweep: the wall crosses the map in ten seconds.
	broadcastWaveStatus("sweeping", 0)
	local wall = world.waveWall
	local steps = 100
	local beltWashed = false
	for step = 1, steps do
		local t = step / steps
		local wallZ = Config.WAVE_START_Z + (Config.WAVE_END_Z - Config.WAVE_START_Z) * t
		wall.CFrame = CFrame.new(0, 12, wallZ)
		-- The belt is swept clean when the wall crosses it.
		if not beltWashed and math.abs(wallZ - Config.CONVEYOR_Z) < 8 then
			beltWashed = true
			SpawnerService.washConveyorBrainrots()
			StateService.broadcastFeedMessage("The tsunami swept the belt clean!")
		end
		-- Anyone the wall touches outside their base is washed home.
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			if not character then
				continue
			end
			local root = character:FindFirstChild("HumanoidRootPart")
			if not root then
				continue
			end
			if math.abs(root.Position.Z - wallZ) < 8 and not BaseService.isPlayerInsideOwnBase(player) then
				washPlayerHome(player)
			end
		end
		task.wait(Config.WAVE_SWEEP_TIME / steps)
	end
	-- Park the wall off the map until the next wave.
	wall.CFrame = CFrame.new(0, 12, Config.WAVE_START_Z)
	broadcastWaveStatus("calm", 0)
	StateService.broadcastFeedMessage("The tsunami passed. The belt is open again!")
end

return WaveService
