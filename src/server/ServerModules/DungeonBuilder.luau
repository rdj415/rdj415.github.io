--!strict
--[[
    DungeonBuilder.luau
    Advanced 3D world assembler for procedural dungeons with Toolbox Prefab integration.
    
    Features:
      - Hybrid Prefab / Procedural Architecture:
        Clones high-detail models from ReplicatedStorage.DungeonPrefabs (Pillars, Torches, Chests, Portals, Barrels)
        with automatic fallback to clean procedural geometry.
      - Isolated Off-Workspace Assembly (zero render/replication thrashing).
      - Physics & Query Optimization (CanTouch=false, CanQuery=false on all decor).
      - Atmospheric lighting, corner props, and door archways.
      - Full memory lifecycle cleanup via Cleaner (Janitor pattern).
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DungeonTypes = require(script.Parent.DungeonTypes)
local DungeonGrid = require(script.Parent.DungeonGrid)
local DungeonConfig = require(script.Parent.DungeonConfig)
local Cleaner = require(script.Parent.Cleaner)

type GenerationResult = DungeonTypes.GenerationResult
type RoomNode = DungeonTypes.RoomNode
type DirectionName = DungeonTypes.DirectionName
type Cleaner = Cleaner.Cleaner

local DungeonBuilder = {}
local CONTAINER_NAME = "GeneratedDungeon"
local activeDungeonCleaner: Cleaner? = nil

local function getPrefab(name: string): Model?
	local prefabsFolder = ReplicatedStorage:FindFirstChild("DungeonPrefabs")
	if prefabsFolder then
		local found = prefabsFolder:FindFirstChild(name)
		if found and found:IsA("Model") then
			return found
		end
	end
	return nil
end

local function createPart(
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	isStructural: boolean,
	parent: Instance?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = true

	if isStructural then
		part.CanCollide = true
		part.CanTouch = false
		part.CanQuery = true
		part.CastShadow = true
	else
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = DungeonConfig.EnableShadowsOnDecor
	end

	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth

	if parent then
		part.Parent = parent
	end
	return part
end

local function buildFloor(roomCenter: Vector3, cellSize: number, parent: Instance)
	local floorThickness = DungeonConfig.FloorThickness
	local floorPos = roomCenter + Vector3.new(0, -floorThickness / 2, 0)
	-- Main tiled slate floor
	createPart("Floor", Vector3.new(cellSize, floorThickness, cellSize), CFrame.new(floorPos), DungeonConfig.Colors.Floor, Enum.Material.Slate, true, parent)

	-- Dark stone perimeter rim for high architectural fidelity
	local rimThickness = 1.5
	local half = cellSize / 2
	local rimY = 0.2
	createPart("FloorRim_N", Vector3.new(cellSize, rimY, rimThickness), CFrame.new(roomCenter + Vector3.new(0, rimY / 2, half - rimThickness / 2)), DungeonConfig.Colors.Trim, Enum.Material.Concrete, false, parent)
	createPart("FloorRim_S", Vector3.new(cellSize, rimY, rimThickness), CFrame.new(roomCenter + Vector3.new(0, rimY / 2, -half + rimThickness / 2)), DungeonConfig.Colors.Trim, Enum.Material.Concrete, false, parent)
	createPart("FloorRim_E", Vector3.new(rimThickness, rimY, cellSize), CFrame.new(roomCenter + Vector3.new(half - rimThickness / 2, rimY / 2, 0)), DungeonConfig.Colors.Trim, Enum.Material.Concrete, false, parent)
	createPart("FloorRim_W", Vector3.new(rimThickness, rimY, cellSize), CFrame.new(roomCenter + Vector3.new(-half + rimThickness / 2, rimY / 2, 0)), DungeonConfig.Colors.Trim, Enum.Material.Concrete, false, parent)
end

local function buildCornerPillars(roomCenter: Vector3, cellSize: number, wallHeight: number, parent: Instance)
	local half = cellSize / 2
	local pt = DungeonConfig.PillarThickness
	local pillarOffsets = {
		Vector3.new(half - (pt / 2), wallHeight / 2, half - (pt / 2)),
		Vector3.new(-half + (pt / 2), wallHeight / 2, half - (pt / 2)),
		Vector3.new(half - (pt / 2), wallHeight / 2, -half + (pt / 2)),
		Vector3.new(-half + (pt / 2), wallHeight / 2, -half + (pt / 2)),
	}

	local pillarPrefab = getPrefab("PillarPrefab")

	for i, offset in ipairs(pillarOffsets) do
		if pillarPrefab then
			local clonedPillar = pillarPrefab:Clone()
			clonedPillar.Name = "CornerPillar_" .. i
			local targetPos = roomCenter + Vector3.new(offset.X, 0, offset.Z)
			clonedPillar:PivotTo(CFrame.new(targetPos) * CFrame.Angles(0, math.rad((i - 1) * 90), 0))
			for _, part in ipairs(clonedPillar:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = true
					part.CanCollide = true
					part.CanTouch = false
					part.CanQuery = false
				end
			end
			clonedPillar.Parent = parent
		else
			createPart("Pillar_" .. i, Vector3.new(pt, wallHeight, pt), CFrame.new(roomCenter + offset), DungeonConfig.Colors.Pillar, DungeonConfig.Materials.Pillar, true, parent)
		end
	end
end

local function buildWallSegment(
	roomCenter: Vector3,
	dir: DirectionName,
	hasDoor: boolean,
	cellSize: number,
	wallHeight: number,
	doorWidth: number,
	doorHeight: number,
	parent: Instance
)
	local halfCell = cellSize / 2
	local wallThickness = DungeonConfig.WallThickness
	local offset: Vector3
	local rotation: CFrame

	if dir == "North" then
		offset = Vector3.new(0, 0, halfCell - (wallThickness / 2))
		rotation = CFrame.Angles(0, 0, 0)
	elseif dir == "South" then
		offset = Vector3.new(0, 0, -halfCell + (wallThickness / 2))
		rotation = CFrame.Angles(0, 0, 0)
	elseif dir == "East" then
		offset = Vector3.new(halfCell - (wallThickness / 2), 0, 0)
		rotation = CFrame.Angles(0, math.rad(90), 0)
	elseif dir == "West" then
		offset = Vector3.new(-halfCell + (wallThickness / 2), 0, 0)
		rotation = CFrame.Angles(0, math.rad(90), 0)
	end

	local wallCenter = roomCenter + offset

	if not hasDoor then
		-- Solid wall with stone baseboard trim
		local solidCF = CFrame.new(wallCenter + Vector3.new(0, wallHeight / 2, 0)) * rotation
		createPart("SolidWall_" .. dir, Vector3.new(cellSize, wallHeight, wallThickness), solidCF, DungeonConfig.Colors.Wall, Enum.Material.Concrete, true, parent)

		-- Decorative Wall Torch from toolbox
		local torchPrefab = getPrefab("TorchPrefab")
		if torchPrefab then
			local torch = torchPrefab:Clone()
			torch.Name = "WallTorch_" .. dir
			local torchOffset = Vector3.new(0, wallHeight * 0.55, -wallThickness / 2 - 0.4)
			local torchCF = CFrame.new(wallCenter) * rotation * CFrame.new(torchOffset) * CFrame.Angles(0, math.rad(180), 0)
			torch:PivotTo(torchCF)

			for _, p in ipairs(torch:GetDescendants()) do
				if p:IsA("BasePart") then
					p.Anchored = true
					p.CanCollide = false
					p.CanTouch = false
					p.CanQuery = false
				elseif p:IsA("PointLight") then
					p.Range = 24
					p.Brightness = 1.8
					p.Shadows = true
				end
			end
			torch.Parent = parent
		end
	else
		-- Doorway with side posts and arched header
		local sideWidth = (cellSize - doorWidth) / 2
		local headerHeight = wallHeight - doorHeight

		local leftLocalPos = Vector3.new(-doorWidth / 2 - sideWidth / 2, wallHeight / 2, 0)
		local leftWorldCF = CFrame.new(wallCenter) * rotation * CFrame.new(leftLocalPos)
		createPart("DoorPostLeft_" .. dir, Vector3.new(sideWidth, wallHeight, wallThickness), leftWorldCF, DungeonConfig.Colors.Wall, Enum.Material.Concrete, true, parent)

		local rightLocalPos = Vector3.new(doorWidth / 2 + sideWidth / 2, wallHeight / 2, 0)
		local rightWorldCF = CFrame.new(wallCenter) * rotation * CFrame.new(rightLocalPos)
		createPart("DoorPostRight_" .. dir, Vector3.new(sideWidth, wallHeight, wallThickness), rightWorldCF, DungeonConfig.Colors.Wall, Enum.Material.Concrete, true, parent)

		if headerHeight > 0 then
			local headerLocalPos = Vector3.new(0, doorHeight + headerHeight / 2, 0)
			local headerWorldCF = CFrame.new(wallCenter) * rotation * CFrame.new(headerLocalPos)
			createPart("DoorHeader_" .. dir, Vector3.new(doorWidth, headerHeight, wallThickness), headerWorldCF, DungeonConfig.Colors.Wall, Enum.Material.Concrete, true, parent)

			-- Arch keystone decorative block
			local keystonePos = Vector3.new(0, doorHeight + 0.5, -0.4)
			local keystoneCF = CFrame.new(wallCenter) * rotation * CFrame.new(keystonePos)
			createPart("Keystone_" .. dir, Vector3.new(3, 2, wallThickness + 0.8), keystoneCF, DungeonConfig.Colors.Trim, Enum.Material.Slate, false, parent)
		end
	end
end

local function decorateRoom(node: RoomNode, roomModel: Model)
	local center = node.worldPos
	local wallHeight = DungeonConfig.WallHeight

	-- Soft ceiling ambiance
	local lampFixture = createPart("CeilingFixture", Vector3.new(2, 0.6, 2), CFrame.new(center + Vector3.new(0, wallHeight - 0.3, 0)), DungeonConfig.Colors.Trim, Enum.Material.Metal, false, roomModel)
	local light = Instance.new("PointLight")
	light.Range = DungeonConfig.LightRange.Hallway
	light.Brightness = DungeonConfig.LightBrightness.Hallway
	light.Shadows = true
	light.Color = DungeonConfig.Colors.HallwayLight
	light.Parent = lampFixture

	local barrelPrefab = getPrefab("BarrelPrefab")

	-- Room Type Specific Props & Visuals
	if node.roomType == "Start" then
		light.Color = DungeonConfig.Colors.StartLight
		light.Range = DungeonConfig.LightRange.Start
		light.Brightness = DungeonConfig.LightBrightness.Start

		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "DungeonSpawn"
		spawn.Size = Vector3.new(12, 0.6, 12)
		spawn.CFrame = CFrame.new(center + Vector3.new(0, 0.3, 0))
		spawn.Material = Enum.Material.Neon
		spawn.Color = Color3.fromRGB(60, 200, 100)
		spawn.Anchored = true
		spawn.CanCollide = true
		spawn.CanTouch = true
		spawn.Duration = 0

		-- Decorative runic border around spawn
		local border = createPart("SpawnBorder", Vector3.new(14, 0.4, 14), CFrame.new(center + Vector3.new(0, 0.2, 0)), Color3.fromRGB(30, 40, 35), Enum.Material.Slate, false, roomModel)

		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 160, 0, 40)
		billboard.StudsOffset = Vector3.new(0, 6, 0)
		billboard.AlwaysOnTop = true
		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, 0, 1, 0)
		text.BackgroundTransparency = 1
		text.Text = "[ START ROOM ]"
		text.TextColor3 = Color3.fromRGB(120, 255, 160)
		text.Font = Enum.Font.GothamBold
		text.TextSize = 18
		text.Parent = billboard
		billboard.Parent = spawn
		spawn.Parent = roomModel

	elseif node.roomType == "Exit" then
		light.Color = DungeonConfig.Colors.ExitLight
		light.Range = DungeonConfig.LightRange.Exit
		light.Brightness = DungeonConfig.LightBrightness.Exit

		local portalPrefab = getPrefab("PortalPrefab")
		if portalPrefab then
			local portal = portalPrefab:Clone()
			portal.Name = "ExitPortalModel"
			portal:PivotTo(CFrame.new(center + Vector3.new(0, 0.5, 0)))
			for _, p in ipairs(portal:GetDescendants()) do
				if p:IsA("BasePart") then
					p.Anchored = true
					p.CanCollide = false
				elseif p:IsA("PointLight") then
					p.Color = Color3.fromRGB(160, 110, 255)
					p.Brightness = 3.5
				end
			end
			local billboard = Instance.new("BillboardGui")
			billboard.Size = UDim2.new(0, 180, 0, 40)
			billboard.StudsOffset = Vector3.new(0, 15, 0)
			billboard.AlwaysOnTop = true
			local text = Instance.new("TextLabel")
			text.Size = UDim2.new(1, 0, 1, 0)
			text.BackgroundTransparency = 1
			text.Text = "[ EXIT PORTAL ]"
			text.TextColor3 = Color3.fromRGB(200, 160, 255)
			text.Font = Enum.Font.GothamBold
			text.TextSize = 18
			text.Parent = billboard
			billboard.Parent = portal
			portal.Parent = roomModel
		else
			local frame = createPart("ExitPortalFrame", Vector3.new(14, 12, 2), CFrame.new(center + Vector3.new(0, 6, 0)), Color3.fromRGB(40, 30, 60), Enum.Material.Slate, true, roomModel)
			createPart("ExitPortalCore", Vector3.new(10, 10, 0.6), CFrame.new(center + Vector3.new(0, 6, 0)), Color3.fromRGB(160, 110, 255), Enum.Material.Neon, false, roomModel)
		end

	elseif node.roomType == "Loot" then
		light.Color = DungeonConfig.Colors.LootLight
		light.Range = DungeonConfig.LightRange.Loot
		light.Brightness = DungeonConfig.LightBrightness.Loot

		-- Stepped stone altar
		createPart("AltarBase", Vector3.new(10, 0.8, 10), CFrame.new(center + Vector3.new(0, 0.4, 0)), Color3.fromRGB(50, 52, 58), Enum.Material.Slate, true, roomModel)
		createPart("AltarTop", Vector3.new(7, 1.4, 7), CFrame.new(center + Vector3.new(0, 1.5, 0)), Color3.fromRGB(70, 72, 80), Enum.Material.Granite, true, roomModel)

		local chestPrefab = getPrefab("ChestPrefab")
		if chestPrefab then
			local chest = chestPrefab:Clone()
			chest.Name = "TreasureChestModel"
			chest:PivotTo(CFrame.new(center + Vector3.new(0, 2.2, 0)))
			for _, p in ipairs(chest:GetDescendants()) do
				if p:IsA("BasePart") then
					p.Anchored = true
					p.CanCollide = true
				end
			end
			local billboard = Instance.new("BillboardGui")
			billboard.Size = UDim2.new(0, 160, 0, 40)
			billboard.StudsOffset = Vector3.new(0, 5, 0)
			billboard.AlwaysOnTop = true
			local text = Instance.new("TextLabel")
			text.Size = UDim2.new(1, 0, 1, 0)
			text.BackgroundTransparency = 1
			text.Text = "[ LOOT VAULT ]"
			text.TextColor3 = Color3.fromRGB(255, 230, 100)
			text.Font = Enum.Font.GothamBold
			text.TextSize = 16
			text.Parent = billboard
			billboard.Parent = chest
			chest.Parent = roomModel
		else
			createPart("TreasureChest", Vector3.new(4, 3, 3), CFrame.new(center + Vector3.new(0, 3.5, 0)), Color3.fromRGB(210, 160, 30), Enum.Material.WoodPlanks, true, roomModel)
		end

		-- Scatter barrels in the corners of Loot vault
		if barrelPrefab then
			local b1 = barrelPrefab:Clone()
			b1:PivotTo(CFrame.new(center + Vector3.new(12, 0, 12)) * CFrame.Angles(0, math.rad(25), 0))
			b1.Parent = roomModel
			local b2 = barrelPrefab:Clone()
			b2:PivotTo(CFrame.new(center + Vector3.new(-12, 0, 11)) * CFrame.Angles(0, math.rad(-40), 0))
			b2.Parent = roomModel
		end

	elseif node.roomType == "DeadEnd" then
		-- In dead ends, place a decorative barrel cluster
		if barrelPrefab then
			local b = barrelPrefab:Clone()
			b:PivotTo(CFrame.new(center + Vector3.new(8, 0, -8)) * CFrame.Angles(0, math.rad(50), 0))
			b.Parent = roomModel
		end
	end
end

function DungeonBuilder.clearDungeon(): ()
	if activeDungeonCleaner then
		activeDungeonCleaner:Clean()
		activeDungeonCleaner = nil
	end
	local existing = Workspace:FindFirstChild(CONTAINER_NAME)
	if existing then
		existing:Destroy()
	end

	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Transparency = 1
		baseplate.CanCollide = false
	end
	local spawn = Workspace:FindFirstChild("SpawnLocation")
	if spawn and spawn:IsA("SpawnLocation") then
		spawn.Enabled = false
		spawn.Transparency = 1
		spawn.CanCollide = false
	end

	local safeSpawn = Workspace:FindFirstChild("DungeonSafeSpawn")
	if not safeSpawn then
		local s = Instance.new("SpawnLocation")
		s.Name = "DungeonSafeSpawn"
		s.Size = Vector3.new(12, 1, 12)
		s.Position = Vector3.new(0, 2, 0)
		s.Anchored = true
		s.CanCollide = false
		s.Transparency = 1
		s.Enabled = true
		s.Duration = 0
		s.Parent = Workspace
	end
end

function DungeonBuilder.build(result: GenerationResult): (Model, number, number)
	local startBuildTime = os.clock()
	DungeonBuilder.clearDungeon()

	local newCleaner = Cleaner.new()
	activeDungeonCleaner = newCleaner

	local container = Instance.new("Model")
	container.Name = CONTAINER_NAME
	newCleaner:Add(container)

	local cellSize = DungeonConfig.CellSize
	local wallHeight = DungeonConfig.WallHeight
	local doorWidth = DungeonConfig.DoorWidth
	local doorHeight = DungeonConfig.DoorHeight
	local totalInstanceCount = 0

	for _, node in ipairs(result.roomList) do
		local roomModel = Instance.new("Model")
		roomModel.Name = string.format("Room_%s_%s", node.roomType, node.id)

		buildFloor(node.worldPos, cellSize, roomModel)
		buildCornerPillars(node.worldPos, cellSize, wallHeight, roomModel)

		for _, dir in ipairs(DungeonGrid.DIRECTION_ORDER) do
			local hasDoor = (node.doors[dir] == true)
			buildWallSegment(node.worldPos, dir, hasDoor, cellSize, wallHeight, doorWidth, doorHeight, roomModel)
		end

		decorateRoom(node, roomModel)
		roomModel:SetAttribute("Depth", node.depthFromStart)
		roomModel:SetAttribute("RoomType", node.roomType)
		roomModel:SetAttribute("GridX", node.gridPos.x)
		roomModel:SetAttribute("GridY", node.gridPos.y)
		totalInstanceCount += #roomModel:GetDescendants()
		roomModel.Parent = container
	end

	-- Invisible safety barrier under dungeon preventing falling into the void
	local safetyNet = Instance.new("Part")
	safetyNet.Name = "SafetyFloorNet"
	safetyNet.Size = Vector3.new(4096, 2, 4096)
	safetyNet.CFrame = CFrame.new(0, -3, 0)
	safetyNet.Anchored = true
	safetyNet.CanCollide = true
	safetyNet.CanTouch = false
	safetyNet.CanQuery = false
	safetyNet.Transparency = 1
	safetyNet.CastShadow = false
	safetyNet.Parent = container
	totalInstanceCount += 1

	totalInstanceCount += #container:GetDescendants()
	container.Parent = Workspace

	local buildDuration = (os.clock() - startBuildTime) * 1000
	local roundedBuildMs = math.round(buildDuration * 100) / 100

	container:SetAttribute("Seed", result.seed)
	container:SetAttribute("TotalRooms", result.totalRooms)
	container:SetAttribute("BuildTimeMs", roundedBuildMs)
	container:SetAttribute("TotalInstances", totalInstanceCount)

	return container, roundedBuildMs, totalInstanceCount
end

return DungeonBuilder
