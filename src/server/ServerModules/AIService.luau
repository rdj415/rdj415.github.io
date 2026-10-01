--!strict
-- [ProductionCore / ServerModules / AIService.luau]
-- Enterprise Autonomous Agent & Combat AI Controller.
-- Provides behavior tree/strategy dispatching, 2D distance projection, anti-stuck physics detection, and Scythe lifecycle cleanup.

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

export type NPCStrategy = "Tactician" | "Survivor" | string

export type NPCState = {
	Strategy: NPCStrategy,
	WalkStuckTime: number?,
	Target: Model?,
	LastPathCalculation: number?,
	AncestryConn: RBXScriptConnection?,
}

local AIService = {}
AIService.__index = AIService
AIService.Metadata = {
	Priority = 25,
}

local _scythe: any = nil
local _serviceScope: number = 0
local _moduleLoader: any = nil
local _zoneService: any = nil

local _npcs: { [Model]: NPCState } = {}
local _heartbeatConn: RBXScriptConnection? = nil

-- Keep NPC position clamped inside battle royale storm zone
local function _keepInZone(npc: Model, targetPos: Vector3): Vector3
	if not _zoneService then
		return targetPos
	end

	local stormCenter = _zoneService.GetStormCenter and _zoneService.GetStormCenter()
	local stormRadius = _zoneService.GetStormRadius and _zoneService.GetStormRadius()
	if not stormCenter or not stormRadius then
		return targetPos
	end

	local offsetFromCenter = Vector2.new(targetPos.X - stormCenter.X, targetPos.Z - stormCenter.Z)
	local distFromCenter = offsetFromCenter.Magnitude

	-- Clamp target inside 90% of storm radius to prevent NPCs from running into storm damage
	local maxSafeRadius = stormRadius * 0.9
	if distFromCenter > maxSafeRadius and distFromCenter > 0 then
		local clampedOffset = offsetFromCenter.Unit * maxSafeRadius
		return Vector3.new(stormCenter.X + clampedOffset.X, targetPos.Y, stormCenter.Z + clampedOffset.Y)
	end

	return targetPos
end

-- Strategy-based target validation
local function _isValidTargetForStrategy(npc: Model, targetChar: Model): boolean
	local data = _npcs[npc]
	if not data then return true end

	if data.Strategy == "Tactician" then
		if _zoneService then
			local stormCenter = _zoneService.GetStormCenter and _zoneService.GetStormCenter()
			local stormRadius = _zoneService.GetStormRadius and _zoneService.GetStormRadius()
			local targetHRP = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
			if stormCenter and stormRadius and targetHRP then
				local targetDistToCenter = Vector2.new(targetHRP.Position.X - stormCenter.X, targetHRP.Position.Z - stormCenter.Z).Magnitude
				return targetDistToCenter > stormRadius * 0.6
			end
		end
	elseif data.Strategy == "Survivor" then
		local hrp = npc:FindFirstChild("HumanoidRootPart") :: BasePart?
		local targetHRP = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp and targetHRP then
			local dist = (targetHRP.Position - hrp.Position).Magnitude
			return dist < 25
		end
	end

	return true
end

-- Server-authoritative NPC movement with anti-stuck detection and replication throttling
local function _moveNPCTo(npc: Model, targetPos: Vector3, speed: number): boolean
	targetPos = _keepInZone(npc, targetPos)
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	local hrp = npc:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not hrp then return false end

	local currentPos = hrp.Position
	local direction = (targetPos - currentPos)
	local directionXZ = Vector3.new(direction.X, 0, direction.Z)
	local distance = directionXZ.Magnitude

	if distance < 1.5 then
		humanoid:Move(Vector3.zero, false)
		return true
	end

	-- Guard against redundant network property replication
	if humanoid.WalkSpeed ~= speed then
		humanoid.WalkSpeed = speed
	end
	if not humanoid.AutoRotate then
		humanoid.AutoRotate = true
	end

	humanoid:Move(directionXZ.Unit, false)

	-- Anti-stuck jump detection using physics linear velocity
	local data = _npcs[npc]
	if data then
		local now = os.clock()
		local currentSpeed = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z).Magnitude
		if speed > 0 and currentSpeed < 1.5 then
			if not data.WalkStuckTime then
				data.WalkStuckTime = now
			elseif now - data.WalkStuckTime > 0.5 then
				humanoid.Jump = true
				data.WalkStuckTime = nil
			end
		else
			data.WalkStuckTime = nil
		end
	end

	return false
end

-- Synchronous Lifecycle Hook
function AIService.Init(Context: any)
	_moduleLoader = Context.ModuleLoader
	_scythe = _moduleLoader.RequireShared("Packages.Scythe")
	_serviceScope = _scythe.scope()

	print("[AIService] Initialized with Scythe memory management.")
end

-- Asynchronous Start Lifecycle Hook
function AIService.Start()
	if _moduleLoader then
		pcall(function()
			_zoneService = _moduleLoader.RequireScoped("ServerModules.ZoneService")
		end)
	end

	-- High-performance throttled AI simulation loop
	local lastTick = os.clock()
	_heartbeatConn = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - lastTick < 0.1 then return end -- 10Hz AI decision tick
		lastTick = now

		for npc, state in pairs(_npcs) do
			if not npc.Parent then
				AIService.UnregisterNPC(npc)
				continue
			end

			local hum = npc:FindFirstChildOfClass("Humanoid")
			if not hum or hum.Health <= 0 then
				AIService.UnregisterNPC(npc)
				continue
			end

			-- Evaluate target and move
			if state.Target and state.Target.Parent then
				local targetHRP = state.Target:FindFirstChild("HumanoidRootPart") :: BasePart?
				if targetHRP and _isValidTargetForStrategy(npc, state.Target) then
					_moveNPCTo(npc, targetHRP.Position, 16)
				end
			end
		end
	end)

	if _heartbeatConn then
		_scythe.add(_serviceScope, _heartbeatConn)
	end

	print("[AIService] Started. AI combat loop running.")
end

-- Register an active NPC
function AIService.RegisterNPC(npc: Model, strategy: NPCStrategy?)
	if _npcs[npc] then
		AIService.UnregisterNPC(npc)
	end

	local state: NPCState = {
		Strategy = strategy or "Tactician",
		WalkStuckTime = nil,
		Target = nil,
		LastPathCalculation = nil,
		AncestryConn = nil,
	}
	_npcs[npc] = state

	-- Bind ancestry destroyed cleanup with self-disconnecting listener
	local conn: RBXScriptConnection? = nil
	conn = npc.AncestryChanged:Connect(function(_, parent)
		if not parent then
			AIService.UnregisterNPC(npc)
		end
	end)
	state.AncestryConn = conn
end

-- Unregister an NPC and clean up connections immediately
function AIService.UnregisterNPC(npc: Model)
	local state = _npcs[npc]
	if state and state.AncestryConn then
		state.AncestryConn:Disconnect()
		state.AncestryConn = nil
	end
	_npcs[npc] = nil
end

-- Destructor Cleanup Hook
function AIService.Destroy()
	for npc in pairs(_npcs) do
		AIService.UnregisterNPC(npc)
	end
	table.clear(_npcs)
	if _scythe and _scythe.isAlive(_serviceScope) then
		_scythe.scope(_serviceScope)
	end
	print("[AIService] Destroyed cleanly via Scythe.")
end

return AIService
