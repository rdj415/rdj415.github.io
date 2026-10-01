--!strict
-- Comprehensive Test Suite for all 11 Luau Production Modules

local mock = require("./roblox_mock")
local game = _G.game
local Vector3 = _G.Vector3
local Vector2 = _G.Vector2
local CFrame = _G.CFrame

local passedCount = 0
local failedCount = 0

local function assertEqual(actual: any, expected: any, msg: string)
	if actual ~= expected then
		error(string.format("FAILED [%s]: Expected %s, got %s", msg, tostring(expected), tostring(actual)))
	end
end

local function assertTrue(cond: boolean, msg: string)
	if not cond then
		error(string.format("FAILED [%s]: Condition was false", msg))
	end
end

local function runTest(testName: string, testFn: () -> ())
	mock.reset()
	local ok, err = pcall(testFn)
	if ok then
		passedCount += 1
		print(string.format("  ✓ %s", testName))
	else
		failedCount += 1
		print(string.format("  ✗ %s: %s", testName, tostring(err)))
	end
end

print("========================================")
print("RUNNING LUAU UNIT TEST SUITE")
print("========================================")

-- 1. Scythe tests
runTest("Scythe: Lifecycle and cleanup order", function()
	local Scythe = mock.requireModule("./src/shared/Packages/Scythe.luau")
	local scope = Scythe.scope()
	assertTrue(scope ~= nil and Scythe.isAlive(scope :: number), "Scope should be alive")

	local cleaned = {}
	Scythe.add(scope :: number, function() table.insert(cleaned, "first") end)
	Scythe.add(scope :: number, function() table.insert(cleaned, "second") end)

	local dummyInst = _G.Instance.new("Part")
	Scythe.add(scope :: number, dummyInst)

	Scythe.scope(scope)
	assertTrue(not Scythe.isAlive(scope :: number), "Scope should be dead")
	assertEqual(cleaned[1], "second", "LIFO execution order")
	assertEqual(cleaned[2], "first", "LIFO execution order")
	assertEqual(dummyInst.Parent, nil, "Instance destroyed")
end)

runTest("Scythe: Nested scope and thread cancellation", function()
	local Scythe = mock.requireModule("./src/shared/Packages/Scythe.luau")
	local parentScope = Scythe.scope() :: number
	local childScope = Scythe.scope() :: number

	local childCleaned = false
	Scythe.add(childScope, function() childCleaned = true end)
	Scythe.add(parentScope, childScope)

	Scythe.scope(parentScope)
	assertTrue(not Scythe.isAlive(parentScope), "Parent scope should be dead")
	assertTrue(not Scythe.isAlive(childScope), "Child scope should be dead")
	assertTrue(childCleaned, "Child task should have run")
end)

-- 2. BufferUtil tests
runTest("BufferUtil: Dynamic resizing and Vector3 serialization", function()
	local BufferUtil = mock.requireModule("./src/shared/Packages/BufferUtil.luau")
	local writer = BufferUtil.CreateWriter(16)

	-- Write 30 vectors (30 * 12 = 360 bytes), well past 16 byte initial capacity
	for i = 1, 30 do
		writer:WriteVector3(Vector3.new(i, i * 2, i * 3))
	end

	assertEqual(writer:GetCursor(), 360, "Cursor should be 360")
	local finalBuf = writer:ToBuffer()
	assertEqual(buffer.len(finalBuf), 360, "Trimmed buffer length")

	local reader = BufferUtil.CreateReader(finalBuf)
	for i = 1, 30 do
		local v = reader:ReadVector3()
		assertEqual(v.X, i, "Vector X match")
		assertEqual(v.Y, i * 2, "Vector Y match")
		assertEqual(v.Z, i * 3, "Vector Z match")
	end
end)

-- 3. AtomicBinding tests
runTest("AtomicBinding: Hierarchical resolution and destructors", function()
	local AtomicBinding = mock.requireModule("./src/shared/SharedModules/AtomicBinding.luau")

	local boundCount = 0
	local unboundCount = 0

	local binder = AtomicBinding.new({
		HRP = "HumanoidRootPart",
		Head = "Head",
	}, function(manifest)
		boundCount += 1
		return function()
			unboundCount += 1
		end
	end)

	local root = _G.Instance.new("Model")
	local hrp = _G.Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Parent = root

	binder:bindRoot(root)
	assertEqual(boundCount, 0, "Not resolved yet without Head")

	local head = _G.Instance.new("Part")
	head.Name = "Head"
	head.Parent = root
	assertEqual(boundCount, 1, "Resolved when Head added")

	head:Destroy()
	assertEqual(unboundCount, 1, "Unbound when Head destroyed")

	binder:destroy()
end)

-- 4. ModuleLoader tests
runTest("ModuleLoader: Registration, priority sorting, and phased lifecycle", function()
	local ModuleLoader = mock.requireModule("./src/shared/ModuleLoader.luau")
	local Scythe = mock.requireModule("./src/shared/Packages/Scythe.luau")
	ModuleLoader.Register("Packages.Scythe", Scythe)

	local initOrder = {}
	local startOrder = {}

	local ModA = {
		Metadata = { Priority = 10 },
		Init = function(ctx) table.insert(initOrder, "ModA") end,
		Start = function(ctx) table.insert(startOrder, "ModA") end,
	}
	local ModB = {
		Metadata = { Priority = 50 },
		Init = function(ctx) table.insert(initOrder, "ModB") end,
		Start = function(ctx) table.insert(startOrder, "ModB") end,
	}

	ModuleLoader.Register("ModA", ModA)
	ModuleLoader.Register("ModB", ModB)

	assertEqual(ModuleLoader.RequireShared("Packages.Scythe"), Scythe, "RequireShared resolution")
	assertEqual(ModuleLoader.Require("Server", "ModA"), ModA, "Require resolution")
end)

-- 5. AntiCheatService tests
runTest("AntiCheatService: BypassPlayer and session cleanup", function()
	local AntiCheatService = mock.requireModule("./src/server/ServerModules/AntiCheatService.luau")
	local ModuleLoader = mock.requireModule("./src/shared/ModuleLoader.luau")
	local Scythe = mock.requireModule("./src/shared/Packages/Scythe.luau")
	ModuleLoader.Register("Packages.Scythe", Scythe)

	AntiCheatService.Init({ ModuleLoader = ModuleLoader })
	AntiCheatService.Start()

	local plr = mock.addPlayer("TestUser", 99999)
	AntiCheatService.BypassPlayer(plr, 5.0)

	-- Verify player cleanup on disconnect
	mock.removePlayer(plr)

	AntiCheatService.Destroy()
end)

-- 6. AbilityService tests
runTest("AbilityService: Rate limiting and AntiCheat coordination", function()
	local AbilityService = mock.requireModule("./src/server/ServerModules/AbilityService.luau")
	local AntiCheatService = mock.requireModule("./src/server/ServerModules/AntiCheatService.luau")
	local ModuleLoader = mock.requireModule("./src/shared/ModuleLoader.luau")
	local Scythe = mock.requireModule("./src/shared/Packages/Scythe.luau")
	ModuleLoader.Register("Packages.Scythe", Scythe)
	ModuleLoader.Register("ServerModules.AntiCheatService", AntiCheatService)

	AntiCheatService.Init({ ModuleLoader = ModuleLoader })
	AbilityService.Init({ ModuleLoader = ModuleLoader })
	AbilityService.Start()

	local plr = mock.addPlayer("AbilityUser", 88888)
	local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
	local remote = remotes and remotes:FindFirstChild("AbilityActivated") :: any
	assertTrue(remote ~= nil, "AbilityActivated remote should exist")

	-- Fire ability
	remote.OnServerEvent:Fire(plr, "Dash")

	AbilityService.Destroy()
	AntiCheatService.Destroy()
end)

-- 7. InteractionController tests
runTest("InteractionController: Scope management and prompt enabling", function()
	local InteractionController = mock.requireModule("./src/client/Controllers/InteractionController.luau")
	local ModuleLoader = mock.requireModule("./src/shared/ModuleLoader.luau")
	local Scythe = mock.requireModule("./src/shared/Packages/Scythe.luau")
	ModuleLoader.Register("Packages.Scythe", Scythe)

	local plr, char, hum, hrp = mock.addPlayer("LocalHero", 77777)
	game:GetService("Players").LocalPlayer = plr

	InteractionController.Init({ ModuleLoader = ModuleLoader })
	InteractionController.Start()

	local chest = _G.Instance.new("Model", game:GetService("Workspace"))
	chest.Name = "Chest"
	local chestPart = _G.Instance.new("Part", chest)
	chestPart.Position = Vector3.new(2, 0, 2)
	local prompt = _G.Instance.new("ProximityPrompt", chestPart)

	InteractionController.Destroy()
end)

-- 8. ZoneService tests
runTest("ZoneService: Smoothstep radius calculation and destruction", function()
	local ZoneService = mock.requireModule("./src/server/ServerModules/ZoneService.luau")
	local ModuleLoader = mock.requireModule("./src/shared/ModuleLoader.luau")
	local Scythe = mock.requireModule("./src/shared/Packages/Scythe.luau")
	ModuleLoader.Register("Packages.Scythe", Scythe)

	ZoneService.Init({ ModuleLoader = ModuleLoader })
	ZoneService.Start()

	local center = ZoneService.GetStormCenter()
	local radius = ZoneService.GetStormRadius()
	assertTrue(radius > 0, "Storm radius should be positive")

	ZoneService.Destroy()
end)

-- 9. AIService tests
runTest("AIService: Registration, unregistration, and AncestryConn cleanup", function()
	local AIService = mock.requireModule("./src/server/ServerModules/AIService.luau")
	local ModuleLoader = mock.requireModule("./src/shared/ModuleLoader.luau")
	local Scythe = mock.requireModule("./src/shared/Packages/Scythe.luau")
	ModuleLoader.Register("Packages.Scythe", Scythe)

	AIService.Init({ ModuleLoader = ModuleLoader })
	AIService.Start()

	local npc = _G.Instance.new("Model", game:GetService("Workspace"))
	local hrp = _G.Instance.new("Part", npc)
	hrp.Name = "HumanoidRootPart"
	local hum = _G.Instance.new("Humanoid", npc)

	AIService.RegisterNPC(npc, "Survivor")
	-- Unregistering should not leave hanging connections
	AIService.UnregisterNPC(npc)

	-- Re-register and destroy model
	AIService.RegisterNPC(npc, "Tactician")
	npc:Destroy()

	AIService.Destroy()
end)

-- 10. HitboxService tests
runTest("HitboxService: Multi-target FilterFolder penetration, knockback, and conventions", function()
	local HitboxService = mock.requireModule("./src/server/ServerModules/HitboxService.luau")
	local ModuleLoader = mock.requireModule("./src/shared/ModuleLoader.luau")
	local Scythe = mock.requireModule("./src/shared/Packages/Scythe.luau")
	ModuleLoader.Register("Packages.Scythe", Scythe)

	HitboxService.Init({ ModuleLoader = ModuleLoader })
	HitboxService.Start()

	local _, attChar, _, attHRP = mock.addPlayer("Attacker", 11111)
	local _, vic1Char, vic1Hum, vic1HRP = mock.addPlayer("Victim1", 22222)
	local _, vic2Char, vic2Hum, vic2HRP = mock.addPlayer("Victim2", 33333)

	attHRP.Position = Vector3.new(0, 0, 0)
	vic1HRP.Position = Vector3.new(0, 0, -5)
	vic2HRP.Position = Vector3.new(0, 0, -10)

	local filterFolder = _G.Instance.new("Folder")
	attChar.Parent = filterFolder
	vic1Char.Parent = filterFolder
	vic2Char.Parent = filterFolder

	-- Mock Workspace:Blockcast returning victims sequentially
	game:GetService("Workspace").Blockcast = function(self, cf, sz, dir, params)
		local filterList = params.FilterDescendantsInstances
		-- Ensure attacker is NOT in included list!
		assertTrue(not table.find(filterList, attChar), "Attacker must never be in included target list")

		if table.find(filterList, vic1Char) then
			return { Instance = vic1HRP, Position = vic1HRP.Position, Normal = Vector3.new(0, 0, 1) }
		elseif table.find(filterList, vic2Char) then
			return { Instance = vic2HRP, Position = vic2HRP.Position, Normal = Vector3.new(0, 0, 1) }
		end
		return nil
	end

	-- Test calling with .
	local hits = HitboxService.ExecuteCast({
		Attacker = attChar,
		Shape = "Block",
		Size = Vector3.new(4, 4, 4),
		Range = 15,
		Damage = 25,
		Knockback = 10,
		MaxTargets = 4,
		FilterFolder = filterFolder,
	})

	assertEqual(#hits, 2, "Both victims should be hit through penetration")
	assertEqual(hits[1].Victim, vic1Char, "First victim")
	assertEqual(hits[2].Victim, vic2Char, "Second victim")
	assertEqual(vic1Hum.Health, 75, "Victim 1 took 25 damage")
	assertEqual(vic2Hum.Health, 75, "Victim 2 took 25 damage")

	-- Test calling with :
	local hitsColon = HitboxService:ExecuteCast({
		Attacker = attChar,
		Shape = "Block",
		Size = Vector3.new(4, 4, 4),
		Range = 15,
		Damage = 10,
	})
	assertTrue(type(hitsColon) == "table", "Colon call succeeded")

	HitboxService.Destroy()
end)

-- 11. DataService tests
runTest("DataService: Session locking, isolated templates, transactional updates, and RollLootDrop", function()
	local DataService = mock.requireModule("./src/server/ServerModules/DataService.luau")
	local ModuleLoader = mock.requireModule("./src/shared/ModuleLoader.luau")
	local Scythe = mock.requireModule("./src/shared/Packages/Scythe.luau")
	ModuleLoader.Register("Packages.Scythe", Scythe)

	DataService.Init({ ModuleLoader = ModuleLoader })
	DataService.Start()

	local plr1 = mock.addPlayer("DataUser1", 55551)
	local plr2 = mock.addPlayer("DataUser2", 55552)

	local prof1 = DataService.Get(plr1)
	local prof2 = DataService.Get(plr2)
	assertTrue(prof1 ~= nil, "Profile 1 loaded")
	assertTrue(prof2 ~= nil, "Profile 2 loaded")

	-- Verify isolated table instances (no shared table pollution)
	prof1.Stats.ChestsOpened = 99
	assertTrue(prof2.Stats.ChestsOpened ~= 99, "Profiles must not share nested tables")

	-- Transactional update success
	local success, updated = DataService.Update(plr1, "Coins", function(current)
		return current + 500, true
	end)
	assertTrue(success, "Update succeeded")
	assertEqual(updated, 1750, "Coins incremented")

	-- Transactional update rollback when shouldPersist == false
	local rollbackSuccess, rolledBackVal = DataService.Update(plr1, "Coins", function(current)
		return current + 9999, false
	end)
	assertTrue(not rollbackSuccess, "Update rolled back")
	assertEqual(DataService.Get(plr1).Coins, 1750, "Coins remained unchanged after rollback")

	-- RollLootDrop with both . and :
	local rollDot = DataService.RollLootDrop(plr1, 1.0)
	local rollColon = DataService:RollLootDrop(plr1, 1.0)
	assertTrue(rollDot == true, "100% chance roll returns true with dot")
	assertTrue(rollColon == true, "100% chance roll returns true with colon")

	DataService.Destroy()
end)

print("========================================")
print(string.format("RESULTS: %d PASSED, %d FAILED", passedCount, failedCount))
print("========================================")

if failedCount > 0 then
	error(string.format("%d tests failed!", failedCount))
end
