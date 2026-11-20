-- RebirthService.luau — progression beyond the belt: rebirth (give up your
-- money and brainrots for a permanent income boost) and upgrades (more plots,
-- more income, more speed), all bought with the money your brainrots earned.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Util = require(Shared.Util)

local RebirthService = {}

local world = nil
local remotes = nil

function RebirthService.init(worldTable, remoteTable)
	world = worldTable
	remotes = remoteTable
end

-- Rebirth: pay the cost and own enough brainrots, then start over richer.
function RebirthService.tryRebirth(player)
	local StateService = require(script.Parent.StateService)
	local data = StateService.getData(player)
	if not data then
		return
	end
	local cost = Config.getRebirthCost(data.rebirths)
	if data.money < cost then
		StateService.sendFeedMessage(player, "Rebirth costs " .. Util.formatMoney(cost) .. " — keep earning!")
		return
	end
	if StateService.countOwnedBrainrots(player) < Config.REBIRTH_MIN_BRAINROTS then
		StateService.sendFeedMessage(player, "Rebirth needs at least " .. Config.REBIRTH_MIN_BRAINROTS .. " brainrots on your base!")
		return
	end
	if not StateService.spendMoney(player, cost) then
		return
	end
	-- The old brainrots go; the boost stays.
	for _, record in pairs(data.owned) do
		if record.model then
			record.model:Destroy()
		end
	end
	data.owned = {}
	data.money = Config.REBIRTH_START_MONEY
	data.rebirths = data.rebirths + 1
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local rebirthValue = leaderstats:FindFirstChild("Rebirths")
		if rebirthValue then
			rebirthValue.Value = data.rebirths
		end
		local moneyValue = leaderstats:FindFirstChild("Money")
		if moneyValue then
			moneyValue.Value = data.money
		end
	end
	StateService.pushStateToPlayer(player)
	StateService.sendFeedMessage(player, "REBIRTH " .. data.rebirths .. "! Your income is now x" .. string.format("%.1f", Config.getIncomeMultiplier(data.rebirths, data.upgrades.income)) .. "!")
	if remotes then
		local character = player.Character
		if character then
			local root = character:FindFirstChild("HumanoidRootPart")
			if root then
				remotes.PlayEffect:FireAllClients("RebirthConfetti", root.Position)
			end
		end
	end
end

-- Buy one level of an upgrade: capacity, income or speed.
function RebirthService.tryBuyUpgrade(player, upgradeId)
	local StateService = require(script.Parent.StateService)
	local data = StateService.getData(player)
	if not data then
		return
	end
	local upgrade = Config.UPGRADES[upgradeId]
	if not upgrade then
		return
	end
	local level = data.upgrades[upgradeId] or 0
	if level >= upgrade.maxLevel then
		StateService.sendFeedMessage(player, upgrade.name .. " is already maxed out!")
		return
	end
	local cost = Config.getUpgradeCost(upgradeId, level)
	if data.money < cost then
		StateService.sendFeedMessage(player, upgrade.name .. " costs " .. Util.formatMoney(cost) .. " — keep earning!")
		return
	end
	if not StateService.spendMoney(player, cost) then
		return
	end
	data.upgrades[upgradeId] = level + 1
	-- Speed applies at once; capacity and income apply on the next tick.
	if upgradeId == "speed" then
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = Config.getWalkSpeed(data.upgrades.speed)
			end
		end
	end
	StateService.pushStateToPlayer(player)
	StateService.sendFeedMessage(player, upgrade.name .. " upgraded to level " .. (level + 1) .. "!")
end

return RebirthService
