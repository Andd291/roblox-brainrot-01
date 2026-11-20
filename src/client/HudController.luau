-- HudController.luau — the HUD: money and income, the lock / rebirth /
-- upgrades buttons, the upgrades panel, the wave banner, the event feed and
-- the next-tier progress. Big text, high contrast, readable at a glance.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Util = require(Shared.Util)

local HudController = {}

local player = Players.LocalPlayer
local remotes = nil
local gui = nil
local moneyLabel = nil
local incomeLabel = nil
local statsLabel = nil
local waveBanner = nil
local waveLabel = nil
local lockButton = nil
local rebirthButton = nil
local upgradesButton = nil
local upgradesPanel = nil
local upgradeRows = {}
local hintLabel = nil
local carryingLabel = nil
local nextTierLabel = nil
local feedLabels = {}
local feedMessages = {}
local currentState = nil

local PANEL_COLOR = Color3.fromRGB(20, 20, 30)
local PANEL_TRANSPARENCY = 0.35
local ACCENT = Color3.fromRGB(255, 220, 100)
local GREEN = Color3.fromRGB(120, 255, 140)
local WHITE = Color3.fromRGB(255, 255, 255)

local function makePanel(parent, name, position, size)
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.Position = position
	panel.Size = size
	panel.BackgroundColor3 = PANEL_COLOR
	panel.BackgroundTransparency = PANEL_TRANSPARENCY
	panel.BorderSizePixel = 0
	panel.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel
	return panel
end

local function makeLabel(parent, name, position, size, text, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or WHITE
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextSize = textSize
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function makeButton(parent, name, position, size, text)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = position
	button.Size = size
	button.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
	button.BackgroundTransparency = 0.2
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = WHITE
	button.TextStrokeTransparency = 0
	button.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	button.TextSize = 17
	button.Font = Enum.Font.GothamBold
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	return button
end

-- Keep the last three feed lines on screen, newest on top.
local function addFeedMessage(text)
	table.insert(feedMessages, 1, text)
	while #feedMessages > 3 do
		table.remove(feedMessages)
	end
	for i, label in ipairs(feedLabels) do
		label.Text = feedMessages[i] or ""
		label.TextTransparency = 0.25 * (i - 1)
	end
end

-- The wave banner: warn with a countdown, flash while the wall sweeps.
local function setWaveStatus(data)
	if data.status == "warning" then
		waveBanner.Visible = true
		waveLabel.Text = "TSUNAMI INCOMING — RUN TO YOUR BASE! " .. Util.formatTime(data.secondsLeft or 0)
		waveBanner.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
	elseif data.status == "sweeping" then
		waveBanner.Visible = true
		waveLabel.Text = "TSUNAMI! STAY ON YOUR BASE!"
		waveBanner.BackgroundColor3 = Color3.fromRGB(30, 90, 180)
	else
		waveBanner.Visible = false
	end
end

-- Refresh every label from the latest state the server sent.
local function refreshFromState(state)
	currentState = state
	moneyLabel.Text = state.moneyText
	incomeLabel.Text = "+" .. state.incomeText
	statsLabel.Text = "Brainrots: " .. state.brainrotCount .. " / " .. state.plotCapacity .. "  •  Rebirths: " .. state.rebirths
	if state.lockActive then
		lockButton.Text = "Locked (" .. state.lockSecondsLeft .. "s)"
		lockButton.BackgroundColor3 = Color3.fromRGB(30, 90, 180)
	elseif state.lockCooldownLeft > 0 then
		lockButton.Text = "Lock (" .. state.lockCooldownLeft .. "s)"
		lockButton.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
	else
		lockButton.Text = "Lock Base (60s)"
		lockButton.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
	end
	rebirthButton.Text = "Rebirth — " .. Util.formatMoney(state.rebirthCost)
	carryingLabel.Visible = state.carried
	if state.nextRarity then
		nextTierLabel.Text = "Next tier: " .. state.nextRarity .. " — find one on the belt!"
	else
		nextTierLabel.Text = "Top tier reached — you own a Mythic!"
	end
	for upgradeId, row in pairs(upgradeRows) do
		local level = state.upgrades[upgradeId] or 0
		local upgrade = Config.UPGRADES[upgradeId]
		if level >= upgrade.maxLevel then
			row.costLabel.Text = "MAX"
			row.buyButton.Text = "Maxed"
		else
			local cost = Config.getUpgradeCost(upgradeId, level)
			row.costLabel.Text = "Lv " .. level .. " → " .. Util.formatMoney(cost)
			row.buyButton.Text = "Buy"
		end
	end
end

-- The contextual hint at the bottom (set by the interaction controller).
function HudController.setHint(text)
	hintLabel.Text = text
end

function HudController.init(remoteTable)
	remotes = remoteTable
	gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotHud"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	-- Money panel, top left, clear of the Roblox menu buttons.
	local moneyPanel = makePanel(gui, "MoneyPanel", UDim2.new(0, 12, 0, 56), UDim2.fromOffset(270, 108))
	moneyLabel = makeLabel(moneyPanel, "Money", UDim2.new(0, 12, 0, 6), UDim2.new(1, -24, 0, 40), "$150", 32, ACCENT)
	incomeLabel = makeLabel(moneyPanel, "Income", UDim2.new(0, 12, 0, 46), UDim2.new(1, -24, 0, 26), "+$0/s", 20, GREEN)
	statsLabel = makeLabel(moneyPanel, "Stats", UDim2.new(0, 12, 0, 74), UDim2.new(1, -24, 0, 24), "Brainrots: 0 / 6  •  Rebirths: 0", 16, WHITE)
	-- Wave banner, top centre, hidden until a wave comes.
	waveBanner = makePanel(gui, "WaveBanner", UDim2.new(0.5, -230, 0, 12), UDim2.fromOffset(460, 48))
	waveBanner.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
	waveBanner.Visible = false
	waveLabel = makeLabel(waveBanner, "WaveText", UDim2.new(0, 10, 0, 0), UDim2.new(1, -20, 1, 0), "", 20, WHITE)
	waveLabel.TextXAlignment = Enum.TextXAlignment.Center
	-- Buttons, top right.
	lockButton = makeButton(gui, "LockButton", UDim2.new(1, -196, 0, 12), UDim2.fromOffset(184, 44), "Lock Base (60s)")
	lockButton.MouseButton1Click:Connect(function()
		remotes.ToggleLock:FireServer()
	end)
	rebirthButton = makeButton(gui, "RebirthButton", UDim2.new(1, -196, 0, 64), UDim2.fromOffset(184, 44), "Rebirth")
	rebirthButton.MouseButton1Click:Connect(function()
		remotes.RequestRebirth:FireServer()
	end)
	upgradesButton = makeButton(gui, "UpgradesButton", UDim2.new(1, -196, 0, 116), UDim2.fromOffset(184, 44), "Upgrades")
	upgradesButton.MouseButton1Click:Connect(function()
		upgradesPanel.Visible = not upgradesPanel.Visible
	end)
	-- Upgrades panel, right side, hidden until opened.
	upgradesPanel = makePanel(gui, "UpgradesPanel", UDim2.new(1, -336, 0, 172), UDim2.fromOffset(324, 210))
	upgradesPanel.Visible = false
	makeLabel(upgradesPanel, "UpgradesTitle", UDim2.new(0, 12, 0, 8), UDim2.new(1, -24, 0, 26), "UPGRADES", 20, ACCENT)
	local rowY = 42
	for _, upgradeId in ipairs({ "capacity", "income", "speed" }) do
		local upgrade = Config.UPGRADES[upgradeId]
		makeLabel(upgradesPanel, upgradeId .. "Name", UDim2.new(0, 12, 0, rowY), UDim2.new(1, -24, 0, 22), upgrade.name, 17, WHITE)
		makeLabel(upgradesPanel, upgradeId .. "Desc", UDim2.new(0, 12, 0, rowY + 22), UDim2.new(1, -24, 0, 18), upgrade.description, 13, Color3.fromRGB(200, 200, 200))
		local costLabel = makeLabel(upgradesPanel, upgradeId .. "Cost", UDim2.new(0, 12, 0, rowY + 40), UDim2.new(0, 150, 0, 20), "", 15, GREEN)
		local buyButton = makeButton(upgradesPanel, upgradeId .. "Buy", UDim2.new(1, -84, 0, rowY + 34), UDim2.fromOffset(72, 32), "Buy")
		buyButton.TextSize = 15
		buyButton.MouseButton1Click:Connect(function()
			remotes.BuyUpgrade:FireServer(upgradeId)
		end)
		upgradeRows[upgradeId] = { costLabel = costLabel, buyButton = buyButton }
		rowY = rowY + 56
	end
	-- Event feed, left side under the money panel.
	for i = 1, 3 do
		local label = makeLabel(gui, "Feed" .. i, UDim2.new(0, 12, 0, 172 + (i - 1) * 24), UDim2.fromOffset(420, 22), "", 15, WHITE)
		table.insert(feedLabels, label)
	end
	-- Carrying notice and hint, bottom centre.
	carryingLabel = makeLabel(gui, "Carrying", UDim2.new(0.5, -250, 1, -92), UDim2.fromOffset(500, 30), "You are carrying a brainrot — run it to your base!", 18, ACCENT)
	carryingLabel.TextXAlignment = Enum.TextXAlignment.Center
	carryingLabel.Visible = false
	hintLabel = makeLabel(gui, "Hint", UDim2.new(0.5, -250, 1, -56), UDim2.fromOffset(500, 30), "Walk to the belt and press E to buy a brainrot!", 17, WHITE)
	hintLabel.TextXAlignment = Enum.TextXAlignment.Center
	-- Next tier, bottom right.
	nextTierLabel = makeLabel(gui, "NextTier", UDim2.new(1, -332, 1, -48), UDim2.fromOffset(320, 30), "Next tier: Rare", 16, ACCENT)
	nextTierLabel.TextXAlignment = Enum.TextXAlignment.Right
	-- State and effect updates from the server.
	remotes.StateChanged.OnClientEvent:Connect(refreshFromState)
	remotes.PlayEffect.OnClientEvent:Connect(function(effectName, data)
		if effectName == "Feed" then
			addFeedMessage(data)
		elseif effectName == "WaveStatus" then
			setWaveStatus(data)
		end
	end)
	addFeedMessage("Welcome to Brainrot Bazaar! Buy brainrots on the belt.")
end

return HudController
