-- InteractionController.luau — the contextual hint at the bottom of the
-- screen: it finds the nearest brainrot with a Buy or Steal prompt and tells
-- the player what pressing E there would do. The prompts themselves are
-- handled by the server; this side only reads them.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local InteractionController = {}

local player = Players.LocalPlayer
local hud = nil

-- The nearest brainrot model with a prompt, and the prompt's own text.
local function findNearestPromptedBrainrot()
	local character = player.Character
	if not character then
		return nil, nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil, nil
	end
	local nearest = nil
	local nearestPrompt = nil
	local nearestDistance = 18
	local function scanFolder(folder)
		if not folder then
			return
		end
		for _, model in ipairs(folder:GetChildren()) do
			if not model:IsA("Model") or not model.PrimaryPart then
				continue
			end
			local prompt = model.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
			if not prompt or not prompt.Enabled then
				continue
			end
			local distance = (model.PrimaryPart.Position - root.Position).Magnitude
			if distance < nearestDistance then
				nearestDistance = distance
				nearest = model
				nearestPrompt = prompt
			end
		end
	end
	scanFolder(Workspace:FindFirstChild("Conveyor"))
	scanFolder(Workspace:FindFirstChild("PlacedBrainrots"))
	return nearest, nearestPrompt
end

function InteractionController.init(remoteTable, hudController)
	hud = hudController
	-- Four times a second, refresh the hint from the nearest prompt.
	task.spawn(function()
		while true do
			task.wait(0.25)
			local model, prompt = findNearestPromptedBrainrot()
			if model and prompt then
				hud.setHint("Press E: " .. prompt.ActionText .. " — " .. prompt.ObjectText)
			else
				local character = player.Character
				if character and character:FindFirstChild("HumanoidRootPart") then
					hud.setHint("Walk to the belt and press E to buy a brainrot!")
				end
			end
		end
	end)
end

return InteractionController
