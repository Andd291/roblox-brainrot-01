-- BrainrotFactory.luau — turns a catalog entry into a visible 3D brainrot: a
-- body, a face, one signature accessory, and a floating label with its name,
-- rarity and money per second, so every character reads at a glance.

local BrainrotData = require(script.Parent.BrainrotData)
local Util = require(script.Parent.Util)

local BrainrotFactory = {}

-- One small part, anchored, with the given shape and material.
local function makePart(name, size, position, color, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Shape = shape or Enum.PartType.Block
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	return part
end

-- The signature accessory for one character, built on top of its body.
local function addAccessory(model, accessory, bodyColor, size)
	local top = Vector3.new(0, size * 0.5, 0)
	if accessory == "noodles" then
		for i = 1, 3 do
			local strand = makePart("Noodle", Vector3.new(0.3, 1.2, 0.3), top + Vector3.new((i - 2) * 0.6, 0.4, 0), Color3.fromRGB(255, 220, 100), Enum.PartType.Cylinder)
			strand.CFrame = CFrame.new(top + Vector3.new((i - 2) * 0.6, 0.4, 0)) * CFrame.Angles(0, 0, math.rad((i - 2) * 18))
			strand.Parent = model
		end
	elseif accessory == "cup" then
		local cup = makePart("Cup", Vector3.new(1.2, 1.4, 1.2), top + Vector3.new(0, 0.5, 0), Color3.fromRGB(240, 240, 240), Enum.PartType.Cylinder)
		cup.Parent = model
		local tea = makePart("Tea", Vector3.new(1.0, 0.3, 1.0), top + Vector3.new(0, 1.1, 0), Color3.fromRGB(160, 90, 40), Enum.PartType.Cylinder)
		tea.Parent = model
	elseif accessory == "hat" then
		local brim = makePart("HatBrim", Vector3.new(2.6, 0.25, 2.6), top + Vector3.new(0, 0.2, 0), Color3.fromRGB(120, 80, 40), Enum.PartType.Cylinder)
		brim.Parent = model
		local crown = makePart("HatTop", Vector3.new(1.4, 0.9, 1.4), top + Vector3.new(0, 0.7, 0), Color3.fromRGB(120, 80, 40), Enum.PartType.Cylinder)
		crown.Parent = model
	elseif accessory == "spikes" then
		for i = 1, 5 do
			local angle = (i - 1) * (math.pi * 2 / 5)
			local spike = makePart("Spike", Vector3.new(0.4, 1.0, 0.4), top + Vector3.new(math.cos(angle) * 0.9, 0.2, math.sin(angle) * 0.9), Color3.fromRGB(90, 160, 50))
			spike.CFrame = CFrame.new(top + Vector3.new(math.cos(angle) * 0.9, 0.2, math.sin(angle) * 0.9)) * CFrame.Angles(math.rad(35), 0, 0)
			spike.Parent = model
		end
	elseif accessory == "straw" then
		local straw = makePart("Straw", Vector3.new(0.3, 1.8, 0.3), top + Vector3.new(0.5, 0.6, 0), Color3.fromRGB(255, 80, 120), Enum.PartType.Cylinder)
		straw.CFrame = CFrame.new(top + Vector3.new(0.5, 0.6, 0)) * CFrame.Angles(0, 0, math.rad(-20))
		straw.Parent = model
		local pearl = makePart("Pearl", Vector3.new(0.7, 0.7, 0.7), Vector3.new(0.8, -size * 0.3, 1.2), Color3.fromRGB(60, 40, 50), Enum.PartType.Ball)
		pearl.Parent = model
	elseif accessory == "cone" then
		local cone = makePart("Cone", Vector3.new(1.8, 2.2, 1.8), top + Vector3.new(0, 0.9, 0), Color3.fromRGB(255, 120, 30))
		cone.Parent = model
		local stripe = makePart("Stripe", Vector3.new(1.9, 0.4, 1.9), top + Vector3.new(0, 0.6, 0), Color3.fromRGB(255, 255, 255))
		stripe.Parent = model
	elseif accessory == "wings" then
		for _, side in ipairs({ -1, 1 }) do
			local wing = makePart("Wing", Vector3.new(0.2, 1.6, 2.2), Vector3.new(side * (size * 0.55), 0.3, -0.4), bodyColor)
			wing.CFrame = CFrame.new(Vector3.new(side * (size * 0.55), 0.3, -0.4)) * CFrame.Angles(0, 0, math.rad(side * -25))
			wing.Parent = model
		end
	elseif accessory == "skewer" then
		local stick = makePart("Skewer", Vector3.new(0.25, 2.4, 0.25), top + Vector3.new(0, 0.8, 0), Color3.fromRGB(180, 140, 90), Enum.PartType.Cylinder)
		stick.CFrame = CFrame.new(top + Vector3.new(0, 0.8, 0)) * CFrame.Angles(0, 0, math.rad(35))
		stick.Parent = model
		for i = 1, 3 do
			local chunk = makePart("Satay", Vector3.new(0.8, 0.8, 0.8), top + Vector3.new(-0.5 + (i - 1) * 0.5, 0.4 + (i - 1) * 0.5, 0), Color3.fromRGB(200, 130, 50), Enum.PartType.Ball)
			chunk.Parent = model
		end
	elseif accessory == "crown" then
		local band = makePart("CrownBand", Vector3.new(2.0, 0.5, 2.0), top + Vector3.new(0, 0.3, 0), Color3.fromRGB(255, 215, 0), Enum.PartType.Cylinder)
		band.Parent = model
		for i = 1, 3 do
			local point = makePart("CrownPoint", Vector3.new(0.5, 0.8, 0.5), top + Vector3.new((i - 2) * 0.7, 0.9, 0), Color3.fromRGB(255, 215, 0))
			point.Parent = model
		end
	elseif accessory == "tentacles" then
		for i = 1, 4 do
			local angle = (i - 1) * (math.pi / 2)
			local arm = makePart("Tentacle", Vector3.new(0.5, 0.5, 2.0), Vector3.new(math.cos(angle) * 1.6, -size * 0.3, math.sin(angle) * 1.6), Color3.fromRGB(50, 30, 80))
			arm.CFrame = CFrame.new(Vector3.new(math.cos(angle) * 1.6, -size * 0.3, math.sin(angle) * 1.6)) * CFrame.Angles(0, -angle, 0)
			arm.Parent = model
		end
	end
end

-- The floating label: name, rarity and money per second, always readable.
local function addNameLabel(model, entry, mutation, rate)
	local rarity = BrainrotData.RARITIES[entry.rarity]
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Size = UDim2.fromOffset(140, 64)
	gui.StudsOffset = Vector3.new(0, 3.4, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	local displayName = entry.name
	if mutation.name ~= "None" then
		displayName = mutation.name .. " " .. entry.name
	end
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = displayName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.TextSize = 15
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = gui
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "Rarity"
	rarityLabel.Position = UDim2.new(0, 0, 0.4, 0)
	rarityLabel.Size = UDim2.new(1, 0, 0.3, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = entry.rarity .. (mutation.name ~= "None" and (" • " .. mutation.name) or "")
	rarityLabel.TextColor3 = rarity and rarity.color or Color3.fromRGB(255, 255, 255)
	rarityLabel.TextStrokeTransparency = 0
	rarityLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	rarityLabel.TextSize = 13
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.Parent = gui
	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "Rate"
	rateLabel.Position = UDim2.new(0, 0, 0.7, 0)
	rateLabel.Size = UDim2.new(1, 0, 0.3, 0)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = Util.formatRate(rate)
	rateLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
	rateLabel.TextStrokeTransparency = 0
	rateLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	rateLabel.TextSize = 13
	rateLabel.Font = Enum.Font.GothamBold
	rateLabel.Parent = gui
	gui.Parent = model.PrimaryPart
end

-- Build one brainrot model from a catalog entry and a mutation. The model is
-- anchored and sits at the origin; the caller moves it with PivotTo.
function BrainrotFactory.buildBrainrotModel(entry, mutation, brainrotId)
	local rate = BrainrotData.getRate(entry, mutation)
	local cost = BrainrotData.getCost(entry, mutation)
	local size = entry.size
	local bodyColor = entry.color
	if mutation.color then
		bodyColor = mutation.color
	end
	local model = Instance.new("Model")
	model.Name = entry.name
	local body = makePart("Body", Vector3.new(size, size, size), Vector3.new(0, size * 0.5, 0), bodyColor, Enum.PartType.Ball)
	body.Parent = model
	model.PrimaryPart = body
	-- Eyes on the front face.
	for _, side in ipairs({ -1, 1 }) do
		local eyeWhite = makePart("Eye", Vector3.new(0.7, 0.9, 0.3), Vector3.new(side * size * 0.22, size * 0.62, size * 0.48), Color3.fromRGB(255, 255, 255), Enum.PartType.Ball)
		eyeWhite.Parent = model
		local pupil = makePart("Pupil", Vector3.new(0.3, 0.4, 0.15), Vector3.new(side * size * 0.22, size * 0.62, size * 0.62), Color3.fromRGB(20, 20, 20), Enum.PartType.Ball)
		pupil.Parent = model
	end
	-- A little mouth.
	local mouth = makePart("Mouth", Vector3.new(size * 0.4, 0.25, 0.2), Vector3.new(0, size * 0.32, size * 0.48), Color3.fromRGB(60, 20, 20))
	mouth.Parent = model
	addAccessory(model, entry.accessory, bodyColor, size)
	addNameLabel(model, entry, mutation, rate)
	model:SetAttribute("BrainrotId", brainrotId)
	model:SetAttribute("CatalogId", entry.id)
	model:SetAttribute("Rate", rate)
	model:SetAttribute("Cost", cost)
	model:SetAttribute("Rarity", entry.rarity)
	model:SetAttribute("Mutation", mutation.name)
	return model
end

return BrainrotFactory
