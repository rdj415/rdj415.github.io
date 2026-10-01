--!strict
-- [ProductionCore / ServerModules / HitboxService.luau]
-- Enterprise Shapecasting & Spatial Combat Engine.
-- Provides server-authoritative hit detection, animation-driven marker triggers, and zero-allocation memory cleanup.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

export type HitboxRequest = {
	Attacker: Model,
	Shape: "Block" | "Sphere",
	Size: Vector3,
	Offset: CFrame?,
	Range: number,
	Damage: number,
	Knockback: number?,
	MaxTargets: number?,
	FilterFolder: Folder?,
}

export type HitResult = {
	Victim: Model,
	HitPoint: Vector3,
	HitNormal: Vector3,
	DamageDealt: number,
}

local HitboxService: any = {}
HitboxService.__index = HitboxService

local _scythe: any = nil
local _serviceScope: number = 0
local _moduleLoader: any = nil
local _vfxRemote: UnreliableRemoteEvent? = nil
local _attackerDebounce: { [Player]: number } = {}
local _activeTrackTasks: { [AnimationTrack]: RBXScriptConnection } = {}

-- Combat configuration
local DEFAULT_FOV_COS: number = 0.25 -- ~75-degree frontal cone
local RATE_LIMIT_WINDOW: number = 0.15 -- Minimum 150ms between casts
local DEFAULT_MAX_TARGETS: number = 8

-- Guard Clauses & Dot Product Angle Pre-filtering
local function _isWithinCombatCone(originCF: CFrame, targetPos: Vector3, minCosAngle: number): boolean
	local direction: Vector3 = targetPos - originCF.Position
	local distance: number = direction.Magnitude
	if distance <= 0.05 then return true end

	local forwardVec: Vector3 = originCF.LookVector
	local dotProduct: number = forwardVec:Dot(direction.Unit)
	return dotProduct >= minCosAngle
end

-- Load-Guarded Spatial VFX Broadcast
local function _broadcastHitVFX(hitPos: Vector3, hitNormal: Vector3, victimModel: Model)
	if not _vfxRemote then return end

	local packet = {
		Position = hitPos,
		Normal = hitNormal,
		Victim = victimModel,
	}

	for _, player in Players:GetPlayers() do
		local isLoaded = player:GetAttribute("__LOADED") == true
		if not isLoaded then continue end

		local char = player.Character
		if not char then continue end

		local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then continue end

		-- Spatial culling: only broadcast if within 128 studs
		local dist = (root.Position - hitPos).Magnitude
		if dist <= 128 then
			_vfxRemote:FireClient(player, packet)
		end
	end
end

-- Synchronous Lifecycle Hook
function HitboxService.Init(Context: any)
	_moduleLoader = Context.ModuleLoader

	-- Import Scythe zero-allocation memory engine
	_scythe = _moduleLoader.RequireShared("Packages.Scythe")
	_serviceScope = _scythe.scope()

	-- Server-side debounce garbage collection on PlayerRemoving
	local removeConn = Players.PlayerRemoving:Connect(function(player: Player)
		_attackerDebounce[player] = nil
	end)
	_scythe.add(_serviceScope, removeConn)

	print("[HitboxService] Initialized synchronously via ModuleLoader with Scythe scope.")
end

-- Asynchronous Start Lifecycle Hook
function HitboxService.Start()
	-- Create / link UnreliableRemoteEvent for high-frequency VFX packets
	local remoteFolder = ReplicatedStorage:FindFirstChild("CombatRemotes") :: Folder?
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "CombatRemotes"
		remoteFolder.Parent = ReplicatedStorage
		_scythe.add(_serviceScope, remoteFolder)
	end

	local vfxEvent = remoteFolder:FindFirstChild("CombatVFX") :: UnreliableRemoteEvent?
	if not vfxEvent then
		vfxEvent = Instance.new("UnreliableRemoteEvent")
		vfxEvent.Name = "CombatVFX"
		vfxEvent.Parent = remoteFolder
		_scythe.add(_serviceScope, vfxEvent)
	end
	_vfxRemote = vfxEvent

	print("[HitboxService] Started. Zero-trust spatial validation active.")
end

-- Core Execution: Shapecasting with Whitelist Filtering & Dot Product Checks
-- Polymorphic signature supporting both HitboxService:ExecuteCast(req) and HitboxService.ExecuteCast(req)
function HitboxService.ExecuteCast(selfOrRequest: any, maybeRequest: HitboxRequest?): { HitResult }
	local request: HitboxRequest = (if maybeRequest ~= nil then maybeRequest else selfOrRequest) :: HitboxRequest
	local attacker = request.Attacker
	if not attacker then return {} end

	local rootPart = attacker:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return {} end

	-- Rate limiting check for player attackers
	local attackerPlayer = Players:GetPlayerFromCharacter(attacker)
	if attackerPlayer then
		local now = os.clock()
		local lastCast = _attackerDebounce[attackerPlayer] or 0
		if now - lastCast < RATE_LIMIT_WINDOW then
			return {}
		end
		_attackerDebounce[attackerPlayer] = now
	end

	local castOffset = request.Offset or CFrame.new()
	local originCFrame = rootPart.CFrame * castOffset
	local castDirection = originCFrame.LookVector * request.Range

	-- Configure Filter: Always exclude attacker to prevent torso self-blocking
	local excludeList: { Instance } = { attacker }
	local includedInstances: { Instance } = {}
	local rayParams = RaycastParams.new()

	if request.FilterFolder then
		rayParams.FilterType = RaycastFilterType.Include
		for _, child in ipairs(request.FilterFolder:GetChildren()) do
			if child ~= attacker then
				table.insert(includedInstances, child)
			end
		end
		rayParams.FilterDescendantsInstances = includedInstances
	else
		rayParams.FilterType = RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = excludeList
	end
	rayParams.IgnoreWater = true

	local hitsRecorded: { HitResult } = {}
	local hitVictims: { [Model]: boolean } = {}
	local maxTargets = request.MaxTargets or DEFAULT_MAX_TARGETS
	local sphereRadius = math.max(request.Size.X, request.Size.Y, request.Size.Z) / 2

	-- Iterative Penetration Shapecasting (supports multi-target cleave)
	for _ = 1, maxTargets do
		if rayParams.FilterType == RaycastFilterType.Include and #includedInstances == 0 then
			break
		end

		local result: RaycastResult? = nil
		if request.Shape == "Block" then
			result = Workspace:Blockcast(originCFrame, request.Size, castDirection, rayParams)
		elseif request.Shape == "Sphere" then
			result = Workspace:Spherecast(originCFrame.Position, sphereRadius, castDirection, rayParams)
		end

		if not result or not result.Instance then
			break
		end

		local hitPart = result.Instance
		local victimModel = hitPart:FindFirstAncestorOfClass("Model")

		if victimModel then
			-- Exclude this model from subsequent penetration steps in this sweep
			if rayParams.FilterType == RaycastFilterType.Exclude then
				table.insert(excludeList, victimModel)
				rayParams.FilterDescendantsInstances = excludeList
			else
				local foundIdx = table.find(includedInstances, victimModel)
				if foundIdx then
					table.remove(includedInstances, foundIdx)
				else
					local partIdx = table.find(includedInstances, hitPart)
					if partIdx then
						table.remove(includedInstances, partIdx)
					end
				end
				rayParams.FilterDescendantsInstances = includedInstances
			end

			if victimModel ~= attacker and not hitVictims[victimModel] then
				local victimHRP = victimModel:FindFirstChild("HumanoidRootPart") :: BasePart?
				local victimHum = victimModel:FindFirstChildOfClass("Humanoid")

				if victimHRP and victimHum and victimHum.Health > 0 then
					-- Dot Product Angle Validation
					if _isWithinCombatCone(originCFrame, victimHRP.Position, DEFAULT_FOV_COS) then
						hitVictims[victimModel] = true

						-- Server Authoritative Damage Application
						victimHum:TakeDamage(request.Damage)

						-- Safe Knockback impulse (prevents NaN vector explosion)
						if request.Knockback and request.Knockback > 0 then
							local diff = victimHRP.Position - originCFrame.Position
							local impulseDir = if diff.Magnitude > 0.001 then diff.Unit else originCFrame.LookVector
							victimHRP:ApplyImpulse(impulseDir * request.Knockback * victimHRP.AssemblyMass)
						end

						local hitData: HitResult = {
							Victim = victimModel,
							HitPoint = result.Position,
							HitNormal = result.Normal,
							DamageDealt = request.Damage,
						}
						table.insert(hitsRecorded, hitData)

						-- Offload VFX to clients
						_broadcastHitVFX(result.Position, result.Normal, victimModel)
					end
				end
			end
		else
			-- Hit environmental geometry; stop penetration if hitting solid anchored structures
			if hitPart.Anchored and hitPart.CanCollide then
				break
			else
				if rayParams.FilterType == RaycastFilterType.Exclude then
					table.insert(excludeList, hitPart)
					rayParams.FilterDescendantsInstances = excludeList
				else
					local partIdx = table.find(includedInstances, hitPart)
					if partIdx then
						table.remove(includedInstances, partIdx)
						rayParams.FilterDescendantsInstances = includedInstances
					else
						break
					end
				end
			end
		end
	end

	return hitsRecorded
end

-- Marker-Driven Animation Trigger supporting both : and . calling conventions
function HitboxService.BindToAnimationMarker(selfOrTrack: any, trackOrMarker: any, markerOrRequest: any, maybeRequest: HitboxRequest?)
	local track: AnimationTrack
	local markerName: string
	local request: HitboxRequest

	if maybeRequest ~= nil then
		track = trackOrMarker :: AnimationTrack
		markerName = markerOrRequest :: string
		request = maybeRequest
	else
		track = selfOrTrack :: AnimationTrack
		markerName = trackOrMarker :: string
		request = markerOrRequest :: HitboxRequest
	end

	if not track or not track.IsPlaying then return end

	-- Clean up previous binding on the same track if re-bound
	if _activeTrackTasks[track] then
		_activeTrackTasks[track]:Disconnect()
		_activeTrackTasks[track] = nil
	end

	local signal = track:GetMarkerReachedSignal(markerName)
	local conn: RBXScriptConnection
	conn = signal:Connect(function()
		HitboxService.ExecuteCast(request)
	end)

	_activeTrackTasks[track] = conn
	_scythe.add(_serviceScope, conn)

	-- Auto-cleanup on animation stop
	local stopConn: RBXScriptConnection? = nil
	stopConn = track.Stopped:Connect(function()
		if _activeTrackTasks[track] then
			_activeTrackTasks[track]:Disconnect()
			_activeTrackTasks[track] = nil
		end
		if stopConn then
			stopConn:Disconnect()
		end
	end)
	if stopConn then
		_scythe.add(_serviceScope, stopConn)
	end
end

-- Destructor Cleanup Hook
function HitboxService.Destroy()
	for track, conn in pairs(_activeTrackTasks) do
		conn:Disconnect()
	end
	table.clear(_activeTrackTasks)
	table.clear(_attackerDebounce)

	if _scythe and _scythe.isAlive(_serviceScope) then
		_scythe.scope(_serviceScope)
	end
	print("[HitboxService] Destroyed cleanly via Scythe.")
end

return HitboxService
