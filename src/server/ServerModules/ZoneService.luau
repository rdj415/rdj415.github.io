--!strict
-- [ProductionCore / ServerModules / ZoneService.luau]
-- Enterprise Dynamic Battle Royale Safe Zone & Hermite Interpolation Controller.
-- Provides Cubic Hermite smoothstep storm shrinking, 2D radial damage, and Scythe scope lifecycles.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ZoneService: any = {}
ZoneService.Metadata = {
	Priority = 22,
}

local _scythe: any = nil
local _serviceScope: number = 0
local _networkRegistry: any = nil
local _stormStateEvent: any = nil
local _testConfig: any = nil
local _initialDiameter: number = 1000
local _currentDiameter: number = 1000
local _activeDelayThread: thread? = nil
local _activePhaseScope: number? = nil

local function _updateStormVisuals(diameter: number)
	_currentDiameter = diameter
	local stormZone = workspace:FindFirstChild("StormZone")
	if not stormZone then return end
	stormZone:SetAttribute("Diameter", diameter)
end

local function _checkAndDamagePlayers()
	local radius = _currentDiameter / 2
	local stormZone = workspace:FindFirstChild("StormZone")
	local outer = stormZone and stormZone:FindFirstChild("StormWall") :: BasePart?
	local stormCenter = outer and outer.Position or Vector3.zero

	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and humanoid and humanoid.Health > 0 then
			local dist2D = Vector2.new(hrp.Position.X - stormCenter.X, hrp.Position.Z - stormCenter.Z).Magnitude
			if dist2D > radius then
				humanoid:TakeDamage(5)
			end
		end
	end
end

function ZoneService.Init(context: any)
	_scythe = context.ModuleLoader.RequireShared("Packages.Scythe")
	_serviceScope = _scythe.scope()

	pcall(function()
		_networkRegistry = context.ModuleLoader.RequireShared("SharedModules.NetworkRegistry")
		if _networkRegistry and _networkRegistry.Resolve then
			_stormStateEvent = _networkRegistry.Resolve("StormStateEvent")
		end
	end)

	pcall(function()
		_testConfig = context.ModuleLoader.RequireScoped("ServerModules.TestConfig")
	end)

	if not _stormStateEvent then
		local remotes = ReplicatedStorage:FindFirstChild("Remotes") :: Folder?
		if not remotes then
			remotes = Instance.new("Folder")
			remotes.Name = "Remotes"
			remotes.Parent = ReplicatedStorage
			_scythe.add(_serviceScope, remotes)
		end
		local evt = remotes:FindFirstChild("StormStateEvent") :: RemoteEvent?
		if not evt then
			evt = Instance.new("RemoteEvent")
			evt.Name = "StormStateEvent"
			evt.Parent = remotes
			_scythe.add(_serviceScope, evt)
		end
		_stormStateEvent = evt
	end
end

function ZoneService.Start(context: any)
	if _testConfig and _testConfig.EnableStorm == false then return end
	if _testConfig then
		_initialDiameter = _testConfig.StormInitialDiameter or 1000
	end
	_currentDiameter = _initialDiameter
	_updateStormVisuals(_initialDiameter)

	local currentPhaseIndex = 1
	local phases = (_testConfig and _testConfig.StormPhases) or {
		{ WaitDuration = 15, ShrinkDuration = 25, TargetDiameter = 300 }
	}

	local function runNextPhase()
		if currentPhaseIndex > #phases then return end
		if not _scythe or not _scythe.isAlive(_serviceScope) then return end

		local phase = phases[currentPhaseIndex]
		local phaseScope: number = _scythe.scope() :: number
		_activePhaseScope = phaseScope
		_scythe.add(_serviceScope, phaseScope)

		_activeDelayThread = task.delay(phase.WaitDuration, function()
			_activeDelayThread = nil
			if not _scythe or not _scythe.isAlive(_serviceScope) or not _scythe.isAlive(phaseScope) then return end
			if _stormStateEvent then
				_stormStateEvent:FireAllClients("Shrinking", phase.ShrinkDuration)
			end

			local startDiameter = _currentDiameter
			local targetDiameter = phase.TargetDiameter
			local startTime = os.clock()
			local duration = phase.ShrinkDuration

			local conn: RBXScriptConnection
			conn = RunService.Heartbeat:Connect(function()
				if not _scythe or not _scythe.isAlive(_serviceScope) or not _scythe.isAlive(phaseScope) then
					if conn then conn:Disconnect() end
					return
				end

				local elapsed = os.clock() - startTime
				local alpha = math.clamp(elapsed / duration, 0, 1)
				-- Cubic Hermite smoothstep for natural boundary shrinking
				local t = alpha * alpha * (3 - 2 * alpha)
				local currentDiameter = startDiameter + (targetDiameter - startDiameter) * t
				_updateStormVisuals(currentDiameter)

				if alpha >= 1 then
					conn:Disconnect()
					if _stormStateEvent then
						_stormStateEvent:FireAllClients("Finished")
					end
					_scythe.scope(phaseScope)
					_activePhaseScope = nil
					currentPhaseIndex += 1
					runNextPhase()
				end
			end)

			if _scythe.isAlive(phaseScope) then
				_scythe.add(phaseScope, conn)
			else
				conn:Disconnect()
			end
		end)

		if _activeDelayThread then
			_scythe.add(phaseScope, _activeDelayThread)
		end
	end

	runNextPhase()

	-- Periodic damage tick (1.0s accumulator) avoids per-frame CPU overhead
	local damageTimer = 0
	local damageConn = RunService.Heartbeat:Connect(function(dt: number)
		damageTimer += dt
		if damageTimer >= 1.0 then
			damageTimer = 0
			_checkAndDamagePlayers()
		end
	end)
	_scythe.add(_serviceScope, damageConn)
	print("[ZoneService] Started. Authoritative storm boundary active.")
end

function ZoneService.GetStormCenter(): Vector3
	local stormZone = workspace:FindFirstChild("StormZone")
	local outer = stormZone and stormZone:FindFirstChild("StormWall") :: BasePart?
	return outer and outer.Position or Vector3.zero
end

function ZoneService.GetStormRadius(): number
	return _currentDiameter / 2
end

function ZoneService.Destroy()
	if _activeDelayThread then
		task.cancel(_activeDelayThread)
		_activeDelayThread = nil
	end
	if _activePhaseScope and _scythe and _scythe.isAlive(_activePhaseScope) then
		_scythe.scope(_activePhaseScope)
		_activePhaseScope = nil
	end
	if _scythe and _scythe.isAlive(_serviceScope) then
		_scythe.scope(_serviceScope)
	end
	print("[ZoneService] Destroyed cleanly via Scythe.")
end

return ZoneService
