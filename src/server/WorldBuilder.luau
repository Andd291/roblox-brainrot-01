-- WorldBuilder.luau — builds the whole 3D world at runtime: the plaza and
-- fountain, eight player bases in a ring, the conveyor belt where wild
-- brainrots walk past, decorations, and the tsunami wall that sweeps the map.
-- The world is code, so the place file stays small and the build is readable.

local WorldBuilder = {}

local BASE_COLORS = {
	Color3.fromRGB(230, 70, 70),
	Color3.fromRGB(70, 130, 255),
	Color3.fromRGB(80, 200, 90),
	Color3.fromRGB(255, 200, 50),
	Color3.fromRGB(170, 90, 230),
	Color3.fromRGB(255, 130, 40),
	Color3.fromRGB(255, 100, 180),
	Color3.fromRGB(60, 210, 220),
}

local TREE_SPOTS = {
	Vector3.new(30, 0, -70), Vector3.new(-30, 0, -70),
	Vector3.new(70, 0, -70), Vector3.new(-70, 0, -70),
	Vector3.new(90, 0, 0), Vector3.new(-90, 0, 0),
	Vector3.new(90, 0, 40), Vector3.new(-90, 0, 40),
	Vector3.new(40, 0, 85), Vector3.new(-40, 0, 85),
	Vector3.new(0, 0, 95), Vector3.new(75, 0, 75),
	Vector3.new(-75, 0, 75), Vector3.new(20, 0, -95),
	Vector3.new(-20, 0, -95),
}

local function makePart(parent, name, size, position, color, shape, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Shape = shape or Enum.PartType.Block
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.Parent = parent
	return part
end

local function makeTree(parent, position)
	local trunk = makePart(parent, "Trunk", Vector3.new(1.4, 6, 1.4), position + Vector3.new(0, 3, 0), Color3.fromRGB(120, 80, 40), Enum.PartType.Cylinder)
	trunk.CanCollide = false
	local leaves = makePart(parent, "Leaves", Vector3.new(6, 6, 6), position + Vector3.new(0, 8, 0), Color3.fromRGB(60, 160, 70), Enum.PartType.Ball)
	leaves.CanCollide = false
	local top = makePart(parent, "Top", Vector3.new(4, 4, 4), position + Vector3.new(0, 11, 0), Color3.fromRGB(80, 190, 90), Enum.PartType.Ball)
	top.CanCollide = false
end

local function makeLamp(parent, position)
	local pole = makePart(parent, "Pole", Vector3.new(0.5, 6, 0.5), position + Vector3.new(0, 3, 0), Color3.fromRGB(60, 60, 60), Enum.PartType.Cylinder)
	pole.CanCollide = false
	local bulb = makePart(parent, "Bulb", Vector3.new(1.6, 1.6, 1.6), position + Vector3.new(0, 6.5, 0), Color3.fromRGB(255, 240, 170), Enum.PartType.Ball)
	bulb.Material = Enum.Material.Neon
	bulb.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 240, 170)
	light.Range = 16
	light.Brightness = 1
	light.Parent = bulb
end

local function makeCloud(parent, position)
	local cloud = Instance.new("Model")
	cloud.Name = "Cloud"
	for i, offset in ipairs({ Vector3.new(0, 0, 0), Vector3.new(3, 0.5, 0), Vector3.new(-3, 0.5, 0) }) do
		local puff = makePart(cloud, "Puff" .. i, Vector3.new(7, 4, 5), position + offset, Color3.fromRGB(255, 255, 255), Enum.PartType.Ball)
		puff.CanCollide = false
		puff.CanQuery = false
	end
	cloud.Parent = parent
	return cloud
end

-- One player base: pad, back wall, six plot pads, a banner naming its owner,
-- a lock shield (hidden until the owner locks it), and a spawn pad.
local function makeBase(parent, index, angle)
	local radius = 62
	local center = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
	local color = BASE_COLORS[((index - 1) % #BASE_COLORS) + 1]
	-- Local +Z points away from the plaza, local -Z toward it.
	local yaw = math.atan2(center.X, center.Z)
	local frame = CFrame.new(center) * CFrame.Angles(0, yaw, 0)
	local function toWorld(localOffset)
		return (frame * CFrame.new(localOffset)).Position
	end
	local baseFolder = Instance.new("Folder")
	baseFolder.Name = "Base" .. index
	baseFolder.Parent = parent
	local pad = makePart(baseFolder, "Pad", Vector3.new(18, 1, 18), center + Vector3.new(0, 0.5, 0), color)
	pad.Material = Enum.Material.SmoothPlastic
	local wall = makePart(baseFolder, "BackWall", Vector3.new(18, 6, 1), toWorld(Vector3.new(0, 3, 8.5)), color)
	wall.Material = Enum.Material.SmoothPlastic
	-- Twelve plot pads in a 4 by 3 grid; capacity upgrades unlock the later ones.
	local plots = {}
	for _, lx in ipairs({ -6, -2, 2, 6 }) do
		for _, lz in ipairs({ -3, 3 }) do
			local plotPos = toWorld(Vector3.new(lx, 0, lz))
			local plot = makePart(baseFolder, "Plot", Vector3.new(4, 0.5, 4), plotPos + Vector3.new(0, 1.2, 0), Color3.fromRGB(255, 255, 255), Enum.PartType.Cylinder)
			plot.Material = Enum.Material.SmoothPlastic
			table.insert(plots, plotPos + Vector3.new(0, 1.5, 0))
		end
	end
	-- A banner at the front naming the base and its owner.
	local bannerPart = makePart(baseFolder, "Banner", Vector3.new(10, 4, 0.5), toWorld(Vector3.new(0, 5, -8.5)), Color3.fromRGB(40, 40, 40))
	local bannerGui = Instance.new("BillboardGui")
	bannerGui.Name = "BaseBanner"
	bannerGui.Size = UDim2.fromOffset(220, 70)
	bannerGui.StudsOffset = Vector3.new(0, 0, 0)
	bannerGui.AlwaysOnTop = true
	bannerGui.LightInfluence = 0
	bannerGui.Parent = bannerPart
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0.5, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "BASE " .. index
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextStrokeTransparency = 0
	titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	titleLabel.TextSize = 22
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = bannerGui
	local ownerLabel = Instance.new("TextLabel")
	ownerLabel.Name = "Owner"
	ownerLabel.Position = UDim2.new(0, 0, 0.5, 0)
	ownerLabel.Size = UDim2.new(1, 0, 0.5, 0)
	ownerLabel.BackgroundTransparency = 1
	ownerLabel.Text = "empty — walk in to claim it"
	ownerLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	ownerLabel.TextStrokeTransparency = 0
	ownerLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	ownerLabel.TextSize = 15
	ownerLabel.Font = Enum.Font.GothamBold
	ownerLabel.Parent = bannerGui
	-- The lock shield: a translucent dome shown while the base is locked.
	local shield = makePart(baseFolder, "LockShield", Vector3.new(24, 14, 24), center + Vector3.new(0, 7, 0), Color3.fromRGB(120, 200, 255), Enum.PartType.Cylinder)
	shield.Transparency = 0.75
	shield.CanCollide = false
	shield.CanQuery = false
	shield.Visible = false
	return {
		index = index,
		center = center,
		angle = yaw,
		color = color,
		plots = plots,
		bannerOwnerLabel = ownerLabel,
		shield = shield,
		spawnPosition = center + Vector3.new(0, 3, 0),
	}
end

local function makeConveyor(parent)
	local belt = makePart(parent, "Belt", Vector3.new(180, 1, 8), Vector3.new(0, 2.5, -40), Color3.fromRGB(50, 50, 55))
	belt.Material = Enum.Material.SmoothPlastic
	for _, z in ipairs({ -44, -36 }) do
		local rail = makePart(parent, "Rail", Vector3.new(180, 0.6, 0.6), Vector3.new(0, 3.4, z), Color3.fromRGB(255, 200, 50))
		rail.Material = Enum.Material.Neon
	end
	for x = -80, 80, 20 do
		makePart(parent, "Leg", Vector3.new(1, 2.5, 1), Vector3.new(x, 1.2, -40), Color3.fromRGB(80, 80, 85))
	end
	-- Start and end arches.
	for _, x in ipairs({ -92, 92 }) do
		for _, z in ipairs({ -44, -36 }) do
			makePart(parent, "ArchPost", Vector3.new(1, 8, 1), Vector3.new(x, 4, z), Color3.fromRGB(255, 120, 40))
		end
		makePart(parent, "ArchBeam", Vector3.new(1, 1, 9), Vector3.new(x, 8.5, -40), Color3.fromRGB(255, 120, 40))
	end
	local signPart = makePart(parent, "BeltSign", Vector3.new(30, 6, 1), Vector3.new(0, 12, -40), Color3.fromRGB(40, 40, 40))
	local signGui = Instance.new("BillboardGui")
	signGui.Name = "BeltSign"
	signGui.Size = UDim2.fromOffset(420, 90)
	signGui.AlwaysOnTop = true
	signGui.LightInfluence = 0
	signGui.Parent = signPart
	local signLabel = Instance.new("TextLabel")
	signLabel.Size = UDim2.new(1, 0, 0.6, 0)
	signLabel.BackgroundTransparency = 1
	signLabel.Text = "BRAINROT BELT"
	signLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	signLabel.TextStrokeTransparency = 0
	signLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	signLabel.TextSize = 30
	signLabel.Font = Enum.Font.GothamBold
	signLabel.Parent = signGui
	local signSub = Instance.new("TextLabel")
	signSub.Position = UDim2.new(0, 0, 0.6, 0)
	signSub.Size = UDim2.new(1, 0, 0.4, 0)
	signSub.BackgroundTransparency = 1
	signSub.Text = "walk up and press E to buy one"
	signSub.TextColor3 = Color3.fromRGB(255, 255, 255)
	signSub.TextStrokeTransparency = 0
	signSub.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	signSub.TextSize = 18
	signSub.Font = Enum.Font.GothamBold
	signSub.Parent = signGui
end

local function makeFountain(parent)
	local basin = makePart(parent, "Basin", Vector3.new(16, 1.5, 16), Vector3.new(0, 0.75, 0), Color3.fromRGB(200, 200, 210), Enum.PartType.Cylinder)
	basin.Material = Enum.Material.SmoothPlastic
	local water = makePart(parent, "Water", Vector3.new(14, 0.4, 14), Vector3.new(0, 1.4, 0), Color3.fromRGB(80, 160, 255), Enum.PartType.Cylinder)
	water.Material = Enum.Material.SmoothPlastic
	water.Transparency = 0.3
	local column = makePart(parent, "Column", Vector3.new(1.5, 5, 1.5), Vector3.new(0, 3.5, 0), Color3.fromRGB(220, 220, 230), Enum.PartType.Cylinder)
	column.Material = Enum.Material.SmoothPlastic
	local orb = makePart(parent, "Orb", Vector3.new(3, 3, 3), Vector3.new(0, 7, 0), Color3.fromRGB(255, 220, 100), Enum.PartType.Ball)
	orb.Material = Enum.Material.Neon
end

-- Build the world and return its handles for the services.
function WorldBuilder.buildWorld()
	local workspace = game:GetService("Workspace")
	local worldFolder = Instance.new("Folder")
	worldFolder.Name = "World"
	worldFolder.Parent = workspace
	local conveyorFolder = Instance.new("Folder")
	conveyorFolder.Name = "Conveyor"
	conveyorFolder.Parent = workspace
	local placedFolder = Instance.new("Folder")
	placedFolder.Name = "PlacedBrainrots"
	placedFolder.Parent = workspace
	-- Plaza disc and fountain at the middle.
	local plaza = makePart(worldFolder, "Plaza", Vector3.new(40, 1, 40), Vector3.new(0, 0.5, 0), Color3.fromRGB(210, 205, 190), Enum.PartType.Cylinder)
	plaza.Material = Enum.Material.SmoothPlastic
	makeFountain(worldFolder)
	-- Eight bases in a ring, offset so none sits on the belt.
	local bases = {}
	for i = 1, 8 do
		local angle = math.rad(22.5 + (i - 1) * 45)
		bases[i] = makeBase(worldFolder, i, angle)
	end
	makeConveyor(worldFolder)
	-- Trees, lamps and clouds for the skyline.
	for _, spot in ipairs(TREE_SPOTS) do
		makeTree(worldFolder, spot)
	end
	for i = 1, 8 do
		local angle = math.rad((i - 1) * 45)
		makeLamp(worldFolder, Vector3.new(math.cos(angle) * 28, 0, math.sin(angle) * 28))
	end
	local clouds = {}
	for i = 1, 6 do
		local cloud = makeCloud(worldFolder, Vector3.new(-100 + i * 35, 42 + (i % 3) * 5, -60 + (i % 2) * 90))
		table.insert(clouds, cloud)
	end
	-- The big title board behind the belt, facing the spawn.
	local titlePart = makePart(worldFolder, "TitleBoard", Vector3.new(34, 7, 1), Vector3.new(0, 9, -62), Color3.fromRGB(40, 40, 40))
	local titleGui = Instance.new("BillboardGui")
	titleGui.Name = "TitleBoard"
	titleGui.Size = UDim2.fromOffset(520, 110)
	titleGui.AlwaysOnTop = true
	titleGui.LightInfluence = 0
	titleGui.Parent = titlePart
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0.55, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "BRAINROT BAZAAR"
	titleLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	titleLabel.TextStrokeTransparency = 0
	titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	titleLabel.TextSize = 38
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = titleGui
	local titleSub = Instance.new("TextLabel")
	titleSub.Position = UDim2.new(0, 0, 0.55, 0)
	titleSub.Size = UDim2.new(1, 0, 0.45, 0)
	titleSub.BackgroundTransparency = 1
	titleSub.Text = "Buy them. Base them. Steal them back."
	titleSub.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleSub.TextStrokeTransparency = 0
	titleSub.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	titleSub.TextSize = 20
	titleSub.Font = Enum.Font.GothamBold
	titleSub.Parent = titleGui
	-- The tsunami wall, parked off the map until a wave sweeps it through.
	local waveWall = makePart(worldFolder, "WaveWall", Vector3.new(220, 40, 4), Vector3.new(0, 12, -150), Color3.fromRGB(80, 160, 255))
	waveWall.Material = Enum.Material.SmoothPlastic
	waveWall.Transparency = 0.4
	waveWall.CanCollide = false
	waveWall.CanQuery = false
	-- Clouds drift slowly across the sky.
	task.spawn(function()
		while true do
			task.wait(1)
			for _, cloud in ipairs(clouds) do
				local pivot = cloud:GetPivot()
				local x = pivot.Position.X + 0.6
				if x > 130 then
					x = -130
				end
				cloud:PivotTo(CFrame.new(x, pivot.Position.Y, pivot.Position.Z))
			end
		end
	end)
	return {
		bases = bases,
		conveyor = { startX = -90, endX = 90, z = -40, y = 3 },
		waveWall = waveWall,
		conveyorFolder = conveyorFolder,
		placedFolder = placedFolder,
	}
end

return WorldBuilder
