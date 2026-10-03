--!strict
--[[
    DungeonConfig.luau
    Data-Driven configuration file isolating gameplay balance, spatial dimensions,
    and procedural probabilities from execution logic.
]]

export type DungeonConfigData = {
	-- Spatial Grid Dimensions (in studs)
	CellSize: number,
	WallHeight: number,
	WallThickness: number,
	DoorWidth: number,
	DoorHeight: number,
	FloorThickness: number,
	PillarThickness: number,

	-- Algorithmic Parameters
	DefaultRoomCount: number,
	MinRoomCount: number,
	MaxRoomCount: number,
	MainPathRatio: number, -- Fraction of targetRooms allocated to critical spine (0.4 - 0.7)
	BranchProbability: number, -- Chance to sprout a secondary branch from an existing room
	MaxBranchLength: number, -- Max step depth for secondary branches
	LootRoomProbability: number, -- Chance for a dead-end to become a treasure vault
	MaxLootRoomRatio: number, -- Maximum fraction of total rooms that can be loot vaults

	-- Visual Theme & Performance Tuning
	EnableShadowsOnDecor: boolean,
	LightBrightness: {
		Hallway: number,
		Start: number,
		Loot: number,
		Exit: number,
	},
	LightRange: {
		Hallway: number,
		Start: number,
		Loot: number,
		Exit: number,
	},
	Colors: {
		Floor: Color3,
		Wall: Color3,
		Trim: Color3,
		Pillar: Color3,
		StartLight: Color3,
		ExitLight: Color3,
		LootLight: Color3,
		HallwayLight: Color3,
	},
	Materials: {
		Floor: Enum.Material,
		Wall: Enum.Material,
		Trim: Enum.Material,
		Pillar: Enum.Material,
	},
}

local DungeonConfig: DungeonConfigData = {
	-- Spatial Grid Dimensions
	CellSize = 48,
	WallHeight = 14,
	WallThickness = 2,
	DoorWidth = 12,
	DoorHeight = 12,
	FloorThickness = 2,
	PillarThickness = 3,

	-- Algorithmic Parameters
	DefaultRoomCount = 20,
	MinRoomCount = 8,
	MaxRoomCount = 45,
	MainPathRatio = 0.55,
	BranchProbability = 0.45,
	MaxBranchLength = 4,
	LootRoomProbability = 0.65,
	MaxLootRoomRatio = 0.20,

	-- Visual Theme & Performance Tuning
	EnableShadowsOnDecor = false, -- Optimization: decor doesn't cast shadow maps
	LightBrightness = {
		Hallway = 1.2,
		Start = 2.0,
		Loot = 2.5,
		Exit = 3.5,
	},
	LightRange = {
		Hallway = 26,
		Start = 28,
		Loot = 28,
		Exit = 36,
	},
	Colors = {
		Floor = Color3.fromRGB(48, 50, 56),
		Wall = Color3.fromRGB(75, 78, 86),
		Trim = Color3.fromRGB(30, 31, 35),
		Pillar = Color3.fromRGB(55, 58, 65),
		StartLight = Color3.fromRGB(100, 255, 140),
		ExitLight = Color3.fromRGB(160, 110, 255),
		LootLight = Color3.fromRGB(255, 215, 60),
		HallwayLight = Color3.fromRGB(255, 200, 140),
	},
	Materials = {
		Floor = Enum.Material.Slate,
		Wall = Enum.Material.Concrete,
		Trim = Enum.Material.SmoothPlastic,
		Pillar = Enum.Material.Concrete,
	},
}

return table.freeze(DungeonConfig)
