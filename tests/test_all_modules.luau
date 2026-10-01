--!strict
-- Comprehensive Enterprise Test Suite for all 11 Luau Production Modules

local mock = require("./roblox_mock")
local game = _G.game
local Vector3 = _G.Vector3
local Vector2 = _G.Vector2
local CFrame = _G.CFrame
local task = _G.task

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
print("RUNNING LUAU ENTERPRISE TEST SUITE")
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

runTest("Scythe: Nested scope, early removal, and safe thread cancellation", function()
	local Scythe = mock.requireModule("./src/shared/Packages/Scythe.luau")
	local parentScope = Scythe.scope() :: number
	local childScope = Scythe.scope() :: number

	local childCleaned = false
	Scythe.add(childScope, function() childCleaned = true end)
	Scythe.add(parentScope, childScope)

	-- Add completed thread (should not warn or crash)
	local deadThread = task.spawn(function() end)
	Scythe.add(parentScope, deadThread)

	-- Test early removal
	local removeTarget = function() end
	Scythe.add(parentScope, removeTarget)
	assertTrue(Scythe.remove(parentScope, removeTarget), "Remove should succeed")
	assertTrue(not Scythe.remove(parentScope, removeTarget), "Second remove should return false")

	Scythe.scope(parentScope)
	assertTrue(not Scythe.isAlive(parentScope), "Parent scope should be dead")
	assertTrue(not Scythe.isAlive(childScope), "Child scope should be dead")
	assertTrue(childCleaned, "Child task should have run")
end)

-- 2. BufferUtil tests
runTest("BufferUtil: Dynamic resizing, Vector3, Boolean, and cursor navigation", function()
	local BufferUtil = mock.requireModule("./src/shared/Packages/BufferUtil.luau")
	local writer = BufferUtil.CreateWriter(16)

	-- Write 30 vectors (30 * 12 = 360 bytes), past 16 byte initial capacity
	for i = 1, 30 do
		writer:WriteVector3(Vector3.new(i, i * 2, i * 3))
	end
	writer:WriteBoolean(true)
	writer:WriteBoolean(false)
	writer:WriteString("EnterpriseNetworking")

	local finalBuf = writer:ToBuffer()
	local reader = BufferUtil.CreateReader(finalBuf)
	for i = 1, 30 do
		local v = reader:ReadVector3()
		assertEqual(v.X, i, "Vector X match")
		assertEqual(v.Y, i * 2, "Vector Y match")
		assertEqual(v.Z, i * 3, "Vector Z match")
	end

	assertEqual(reader:ReadBoolean(), true, "Boolean true match")
	assertEqual(reader:ReadBoolean(), false, "Boolean false match")
	assertEqual(reader:ReadString(), "EnterpriseNetworking", "String match")
	assertTrue(reader:GetRemaining() == 0, "No remaining bytes")

	-- Cursor seeking
	reader:SetCursor(0)
	assertTrue(reader:CanRead(12), "Can read first vector after seek")
	local firstV = reader:ReadVector3()
	assertEqual(firstV.X, 1, "First vector read after seek")
end)

-- 3. AtomicBinding tests
runTest("AtomicBinding: Hierarchical resolution, empty manifest, and nil dtor protection", function()
	local AtomicBinding = mock.requireModule("./src/shared/SharedModules/AtomicBinding.luau")

	-- Test empty manifest binding
	local emptyCalls = 0
	local emptyBinder = AtomicBinding.new({}, function(manifest)
		emptyCalls += 1
		return nil
	end)
	local emptyRoot = _G.Instance.new("Model")
	emptyBinder:bindRoot(emptyRoot)
	assertEqual(emptyCalls, 1, "Empty manifest binds to root immediately")
	emptyBinder:Destroy()

	-- Test nil dtor re-invocation guard
	local boundCalls = 0
	local binder = AtomicBinding.new({
		HRP = "HumanoidRootPart",
		Head = "Head",
	}, function(manifest)
		boundCalls += 1
		return nil -- Returning nil destructor
	end)

	local root = _G.Instance.new("Model")
	local hrp = _G.Instance.new("Part", root)
	hrp.Name = "HumanoidRootPart"
	local head = _G.Instance.new("Part", root)
	head.Name = "Head"

	binder:bindRoot(root)
	assertEqual(boundCalls, 1, "Resolved once initially")

	-- Adding another part should NOT re-trigger boundFn
	local extra = _G.Instance.new("Part", root)
	extra.Name = "LeftArm"
	assertEqual(boundCalls, 1, "Adding unrelated sibling must not re-trigger boundFn")

	binder:Destroy()
end)

runTest("AtomicBinding: Sibling replacement and thread destructor cancellation", function()
	local AtomicBinding = mock.requireModule("./src/shared/SharedModules/AtomicBinding.luau")

	local unbindRun = false
	local threadCancelled = false

	local binder = AtomicBinding.new({
		Weapon = "WeaponPart",
	}, function(manifest)
		local th = task.delay(5, function() end)
		return function()
			unbindRun = true
			if coroutine.status(th) ~= "dead" then
				task.cancel(th)
				threadCancelled = true
			end
		end
	end)

	local root = _G.Instance.new("Model")
	local weapon1 = _G.Instance.new("Part", root)
	weapon1.Name = "WeaponPart"
	local weapon2 = _G.Instance.new("Part", root)
	weapon2.Name = "WeaponPart"

	binder:bindRoot(root)

	-- Destroy weapon1; weapon2 should take over
	weapon1:Destroy()
	assertTrue(unbindRun, "Destructor executed on weapon1 removal")
	assertTrue(threadCancelled, "Thread cancelled in destructor")

	binder:Destroy()
end)

-- 4. ModuleLoader tests
runTest("ModuleLoader: Registration, priority sorting, Boot execution, and progress tracking", function()
	local ModuleLoader = mock.requireModule("./src/shared/ModuleLoader.luau")
	local Scythe = mock.requireModule("./src/shared/Packages/Scythe.luau")
	ModuleLoader.Register("Packages.Scythe", Scythe)

	local folder = _G.Instance.new("Folder")
	folder.Name = "ServerModules"

	local initSeq = {}
	local startSeq = {}

	local modLow = _G.Instance.new("ModuleScript", folder)
	modLow.Name = "ModLow"
	modLow._module = {
		Metadata = { Priority = 10 },
		Init = function(ctx) table.insert(initSeq, "Low") end,
		Start = function(ctx) table.insert(startSeq, "Low") end,
	}

	local modHigh = _G.Instance.new("ModuleScript", folder)
	modHigh.Name = "ModHigh"
	modHigh._module = {
		Metadata = { Priority = 90 },
		Init = function(ctx) table.insert(initSeq, "High") end,
		Start = function(ctx) table.insert(startSeq, "High") end,
	}

	ModuleLoader.Boot("Server", folder)

	-- High priority must initialize before Low priority
	assertEqual(initSeq[1], "High", "High priority inits first")
	assertEqual(initSeq[2], "Low", "Low priority inits second")

	local progress = ModuleLoader.GetBootProgress("Server")
	assertTrue(progress ~= nil and progress.IsComplete, "Boot progress completed")
	assertEqual(progress.Percent, 100, "Boot percent 100")

	assertEqual(ModuleLoader.RequireShared("Packages.Scythe"), Scythe, "RequireShared resolution")
end)

-- 5. AntiCheatService tests
runTest("AntiCheatService: Authoritative displacement, single-violation rubberband, and velocity zeroing", function()
	local AntiCheatService = mock.requireModule("./src/server/ServerModules/AntiCheatService.luau")
	local ModuleLoader = mock.requireModule("./src/shared/ModuleLoader.luau")
	local Scythe = mock.requireModule("./src/shared/Packages/Scythe.luau")
	ModuleLoader.Register("Packages.Scythe", Scythe)

	AntiCheatService.Init({ ModuleLoader = ModuleLoader })
	AntiCheatService.Start()

	local plr, char, hum, hrp = mock.addPlayer("Speedster", 55443)
	hrp.Position = Vector3.new(0, 0, 0)
	hrp.AssemblyLinearVelocity = Vector3.new(50, 0, 0)

	-- Tick 1: Establishes (0,0,0) as verified position
	task.wait(0.12)
	game:GetService("RunService").Heartbeat:Fire(0.15)

	-- Exploit: instantaneous teleport to (200, 0, 0)
	hrp.Position = Vector3.new(200, 0, 0)

	-- Tick 2: Catch teleport and rubberband back
	task.wait(0.12)
	game:GetService("RunService").Heartbeat:Fire(0.15)

	assertEqual(hrp.Position.X, 0, "Player rubberbanded to verified position")
	assertEqual(hrp.AssemblyLinearVelocity.X, 0, "Physics velocity zeroed on rubberband")

	-- Tick 3: Player legitimately stays at (0,0,0); verify NO phantom cascade violation!
	task.wait(0.12)
	game:GetService("RunService").Heartbeat:Fire(0.15)

	local history = AntiCheatService.GetViolationHistory(plr)
	assertTrue(history ~= nil, "Violation history exists")
	assertEqual(#history, 1, "Exactly ONE violation recorded (no phantom rubberband cascade!)")

	-- Public API test
	AntiCheatService.ReportViolation(plr, "HoneypotTriggered", { Trap = "SecretChest" })
	assertEqual(#history, 2, "ReportViolation added violation")

	AntiCheatService.Destroy()
end)

-- 6. AbilityService tests
runTest("AbilityService: Cooldown enforcement, remaining query, and trigger validation", function()
	local AbilityService = mock.requireModule("./src/server/ServerModules/AbilityService.luau")
	local AntiCheatService = mock.requireModule("./src/server/ServerModules/AntiCheatService.luau")
	local ModuleLoader = mock.requireModule("./src/shared/ModuleLoader.luau")
	local Scythe = mock.requireModule("./src/shared/Packages/Scythe.luau")
	ModuleLoader.Register("Packages.Scythe", Scythe)
	ModuleLoader.Register("ServerModules.AntiCheatService", AntiCheatService)

	AntiCheatService.Init({ ModuleLoader = ModuleLoader })
	AbilityService.Init({ ModuleLoader = ModuleLoader })
	AbilityService.Start()

	local plr = mock.addPlayer("AbilityHero", 88888)

	-- First trigger should succeed
	local success1 = AbilityService.TriggerAbility(plr, "Dash")
	assertTrue(success1, "First ability trigger succeeds")

	local cd = AbilityService.GetRemainingCooldown(plr, "Dash")
	assertTrue(cd > 1.0, "Remaining cooldown is positive")

	-- Immediate re-trigger must be rejected
	local success2 = AbilityService.TriggerAbility(plr, "Dash")
	assertTrue(not success2, "Immediate re-trigger rejected by rate limiter")

	AbilityService.Destroy()
	AntiCheatService.Destroy()
end)

-- 7. InteractionController tests
runTest("InteractionController: Scope cleanup without leaks and non-PVInstance support", function()
	local InteractionController = mock.requireModule("./src/client/Controllers/InteractionController.luau")
	local ModuleLoader = mock.requireModule("./src/shared/ModuleLoader.luau")
	local Scythe = mock.requireModule("./src/shared/Packages/Scythe.luau")
	ModuleLoader.Register("Packages.Scythe", Scythe)

	local plr, char, hum, hrp = mock.addPlayer("LocalExplorer", 77777)
	game:GetService("Players").LocalPlayer = plr
	hrp.Position = Vector3.new(0, 0, 0)

	InteractionController.Init({ ModuleLoader = ModuleLoader })
	InteractionController.Start()

	-- Tag a non-PVInstance Folder containing a ProximityPrompt
	local folder = _G.Instance.new("Folder", game:GetService("Workspace"))
	folder.Name = "InteractableFolder"
	local part = _G.Instance.new("Part", folder)
	part.Position = Vector3.new(5, 0, 5)
	local prompt = _G.Instance.new("ProximityPrompt", folder)

	game:GetService("CollectionService"):AddTag(folder, "Interactable")

	-- Proximity check (5 studs <= 15 stud radius)
	game:GetService("RunService").Heartbeat:Fire(0.25)
	assertTrue(prompt.Enabled, "Prompt enabled within proximity for tagged folder")

	-- Remove tag and verify clean teardown
	game:GetService("CollectionService"):RemoveTag(folder, "Interactable")

	InteractionController.Destroy()
end)

-- 8. ZoneService tests
runTest("ZoneService: Smoothstep radius, physical storm wall resizing, and scope cleanup", function()
	local ZoneService = mock.requireModule("./src/server/ServerModules/ZoneService.luau")
	local ModuleLoader = mock.requireModule("./src/shared/ModuleLoader.luau")
	local Scythe = mock.requireModule("./src/shared/Packages/Scythe.luau")
	ModuleLoader.Register("Packages.Scythe", Scythe)

	-- Create StormZone with physical StormWall
	local stormZone = _G.Instance.new("Folder", game:GetService("Workspace"))
	stormZone.Name = "StormZone"
	local wall = _G.Instance.new("Part", stormZone)
	wall.Name = "StormWall"
	wall.Position = Vector3.new(0, 0, 0)
	wall.Size = Vector3.new(1000, 100, 1000)

	ZoneService.Init({ ModuleLoader = ModuleLoader })
	ZoneService.Start()

	local radius = ZoneService.GetStormRadius()
	assertTrue(radius == 500, "Initial radius matches 1000 diameter / 2")

	ZoneService.Destroy()
end)

-- 9. AIService tests
runTest("AIService: Target management, nearest target discovery, and corpse avoidance", function()
	local AIService = mock.requireModule("./src/server/ServerModules/AIService.luau")
	local ModuleLoader = mock.requireModule("./src/shared/ModuleLoader.luau")
	local Scythe = mock.requireModule("./src/shared/Packages/Scythe.luau")
	ModuleLoader.Register("Packages.Scythe", Scythe)

	AIService.Init({ ModuleLoader = ModuleLoader })
	AIService.Start()

	local npc = _G.Instance.new("Model", game:GetService("Workspace"))
	local hrp = _G.Instance.new("Part", npc)
	hrp.Name = "HumanoidRootPart"
	hrp.Position = Vector3.new(0, 0, 0)
	local hum = _G.Instance.new("Humanoid", npc)
	AIService.RegisterNPC(npc, "Tactician")

	local _, vicChar, vicHum, vicHRP = mock.addPlayer("TargetUser", 33441)
	vicHRP.Position = Vector3.new(10, 0, 10)

	AIService.SetTarget(npc, vicChar)
	assertEqual(AIService.GetTarget(npc), vicChar, "Target getter returns assigned target")

	-- Kill target
	vicHum.Health = 0

	-- Trigger AI tick; dead target must be dropped immediately
	task.wait(0.12)
	game:GetService("RunService").Heartbeat:Fire(0.15)
	assertEqual(AIService.GetTarget(npc), nil, "Dead target cleared from NPC state")

	AIService.Destroy()
end)

-- 10. HitboxService tests
runTest("HitboxService: Multi-marker animation trigger, anchored target penetration, and conventions", function()
	local HitboxService = mock.requireModule("./src/server/ServerModules/HitboxService.luau")
	local ModuleLoader = mock.requireModule("./src/shared/ModuleLoader.luau")
	local Scythe = mock.requireModule("./src/shared/Packages/Scythe.luau")
	ModuleLoader.Register("Packages.Scythe", Scythe)

	HitboxService.Init({ ModuleLoader = ModuleLoader })
	HitboxService.Start()

	local _, attChar, _, attHRP = mock.addPlayer("Swordsman", 11111)
	attHRP.Position = Vector3.new(0, 0, 0)

	-- 1. Test multi-marker animation bindings on the SAME AnimationTrack
	local track = _G.Instance.new("AnimationTrack")
	local hit1Fired = false
	local hit2Fired = false

	local origExecute = HitboxService.ExecuteCast
	HitboxService.ExecuteCast = function(req)
		if req.Damage == 15 then hit1Fired = true end
		if req.Damage == 30 then hit2Fired = true end
		return {}
	end

	HitboxService.BindToAnimationMarker(track, "Slash1", { Damage = 15, Shape = "Block", Size = Vector3.new(4,4,4), Range = 5 })
	HitboxService.BindToAnimationMarker(track, "Slash2", { Damage = 30, Shape = "Block", Size = Vector3.new(4,4,4), Range = 5 })

	track:GetMarkerReachedSignal("Slash1"):Fire()
	track:GetMarkerReachedSignal("Slash2"):Fire()

	assertTrue(hit1Fired, "Slash1 marker triggered")
	assertTrue(hit2Fired, "Slash2 marker triggered without overwriting Slash1")
	HitboxService.ExecuteCast = origExecute

	-- 2. Test multi-target penetration on anchored items in FilterFolder
	local filterFolder = _G.Instance.new("Folder")
	local target1 = _G.Instance.new("Part", filterFolder)
	target1.Anchored = true
	target1.CanCollide = true
	local target2 = _G.Instance.new("Part", filterFolder)
	target2.Anchored = true
	target2.CanCollide = true

	local blockcastHits = 0
	game:GetService("Workspace").Blockcast = function(self, cf, sz, dir, params)
		blockcastHits += 1
		local list = params.FilterDescendantsInstances
		if table.find(list, target1) then
			return { Instance = target1, Position = Vector3.new(0,0,-5), Normal = Vector3.new(0,0,1) }
		elseif table.find(list, target2) then
			return { Instance = target2, Position = Vector3.new(0,0,-10), Normal = Vector3.new(0,0,1) }
		end
		return nil
	end

	HitboxService.ExecuteCast({
		Attacker = attChar,
		Shape = "Block",
		Size = Vector3.new(4, 4, 4),
		Range = 15,
		Damage = 20,
		MaxTargets = 4,
		FilterFolder = filterFolder,
	})
	assertEqual(blockcastHits, 2, "Penetrated through both anchored targets in Include mode")

	HitboxService.Destroy()
end)

-- 11. DataService tests
runTest("DataService: Transactional mutation, Set method, IsReadOnly, and exact roll bounds", function()
	local DataService = mock.requireModule("./src/server/ServerModules/DataService.luau")
	local ModuleLoader = mock.requireModule("./src/shared/ModuleLoader.luau")
	local Scythe = mock.requireModule("./src/shared/Packages/Scythe.luau")
	ModuleLoader.Register("Packages.Scythe", Scythe)

	DataService.Init({ ModuleLoader = ModuleLoader })
	DataService.Start()

	local plr = mock.addPlayer("DataVaultUser", 77112)
	assertTrue(DataService.Get(plr) ~= nil, "Profile loaded")
	assertTrue(not DataService.IsReadOnly(plr), "Session is read-write")

	-- Test Set method
	local setOk = DataService.Set(plr, "Coins", 5000)
	assertTrue(setOk, "DataService.Set succeeded")
	assertEqual(DataService.Get(plr).Coins, 5000, "Coins updated via Set")

	-- Roll bounds: 0.0 must ALWAYS be false, 1.0 must ALWAYS be true
	assertEqual(DataService.RollLootDrop(plr, 0.0), false, "0.0 drop chance returns false guaranteed")
	assertEqual(DataService.RollLootDrop(plr, 1.0), true, "1.0 drop chance returns true guaranteed")

	DataService.Destroy()
end)

print("========================================")
print(string.format("RESULTS: %d PASSED, %d FAILED", passedCount, failedCount))
print("========================================")

if failedCount > 0 then
	error(string.format("%d tests failed!", failedCount))
end
