-- EffectsController.luau — the juice: a sparkle burst when a brainrot is
-- bought, a red flash when a steal happens, confetti on a rebirth, floating
-- text, and short sounds (best-effort classic ids; silence is fine if one
-- does not load). The server asks for these through the PlayEffect remote.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local EffectsController = {}

local player = Players.LocalPlayer

-- A short sound, played once, failing silently when the id does not load.
local function playSoundOnce(soundId, volume)
	local ok = pcall(function()
		local sound = Instance.new("Sound")
		sound.SoundId = soundId
		sound.Volume = volume or 0.5
		sound.Parent = player:WaitForChild("PlayerGui")
		sound:Play()
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
		task.delay(5, function()
			if sound.Parent then
				sound:Destroy()
			end
		end)
	end)
	return ok
end

-- A burst of coloured particles at a position, gone in two seconds.
local function burstParticles(position, color, count)
	local anchor = Instance.new("Part")
	anchor.Name = "EffectAnchor"
	anchor.Size = Vector3.new(0.5, 0.5, 0.5)
	anchor.Position = position
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Parent = Workspace
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color)
	emitter.Size = NumberSequence.new(0.8)
	emitter.Lifetime = NumberRange.new(0.6, 1.2)
	emitter.Rate = 0
	emitter.Speed = NumberRange.new(8, 16)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = anchor
	emitter:Emit(count or 24)
	task.delay(2, function()
		anchor:Destroy()
	end)
end

-- Floating text that rises and fades ("+$45/s!", "STOLEN!").
local function showFloatingText(position, text, color)
	local gui = Instance.new("BillboardGui")
	gui.Name = "FloatingText"
	gui.Size = UDim2.fromOffset(200, 40)
	gui.StudsOffset = Vector3.new(0, 2, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextSize = 22
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	local anchor = Instance.new("Part")
	anchor.Name = "TextAnchor"
	anchor.Size = Vector3.new(0.5, 0.5, 0.5)
	anchor.Position = position
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Parent = Workspace
	gui.Parent = anchor
	local tween = TweenService:Create(gui, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffset = Vector3.new(0, 6, 0) })
	tween:Play()
	local fade = TweenService:Create(label, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 1, TextStrokeTransparency = 1 })
	fade:Play()
	task.delay(1.6, function()
		anchor:Destroy()
	end)
end

-- The gold sparkle when a brainrot is bought onto a base.
local function playBuySparkle(position)
	burstParticles(position, Color3.fromRGB(255, 220, 100), 30)
	showFloatingText(position, "BOUGHT!", Color3.fromRGB(255, 220, 100))
	playSoundOnce("rbxassetid://13107261", 0.5)
end

-- The red alarm when a brainrot is stolen from any base.
local function playStealAlarm(position)
	burstParticles(position, Color3.fromRGB(255, 60, 60), 20)
	showFloatingText(position, "STOLEN!", Color3.fromRGB(255, 60, 60))
	playSoundOnce("rbxassetid://13107261", 0.4)
end

-- Confetti over the player on a rebirth.
local function playRebirthConfetti(position)
	for _, color in ipairs({ Color3.fromRGB(255, 220, 100), Color3.fromRGB(120, 255, 140), Color3.fromRGB(80, 160, 255), Color3.fromRGB(255, 100, 180) }) do
		burstParticles(position + Vector3.new(math.random(-3, 3), math.random(0, 3), math.random(-3, 3)), color, 12)
	end
	showFloatingText(position, "REBIRTH!", Color3.fromRGB(255, 220, 100))
	playSoundOnce("rbxassetid://13107261", 0.6)
end

function EffectsController.init(remoteTable)
	remoteTable.PlayEffect.OnClientEvent:Connect(function(effectName, data)
		if effectName == "BuySparkle" and typeof(data) == "Vector3" then
			playBuySparkle(data)
		elseif effectName == "StealAlarm" and typeof(data) == "Vector3" then
			playStealAlarm(data)
		elseif effectName == "RebirthConfetti" and typeof(data) == "Vector3" then
			playRebirthConfetti(data)
		end
	end)
end

return EffectsController
