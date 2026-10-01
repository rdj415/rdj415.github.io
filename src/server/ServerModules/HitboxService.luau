--!strict
-- [ProductionCore / ServerModules / HitboxService.luau]
-- Enterprise Shapecasting & Spatial Combat Engine.
-- Complies with ModuleLoader lifecycle (Rule 134), Janitor protocol (Rule 140), and zero-trust server validation.

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

local HitboxService = {}
HitboxService.__index = HitboxService

local _janitor: any = nil
local _moduleLoader: any = nil
local _vfxRemote: UnreliableRemoteEvent? = nil
local _attackerDebounce: { [Player]: number } = {}
local _activeTrackTasks: { [AnimationTrack]: RBXScriptConnection } = {}

-- Constant configuration with numeric separators (Rule 163)
local DEFAULT_FOV_COS: number = 0.25 -- ~75-degree frontal cone
local RATE_LIMIT_WINDOW: number = 0.15 -- Minimum 150ms between casts
local DEFAULT_MAX_TARGETS: number = 8

-- Rule 54: Guard Clauses & Dot Product Angle Pre-filtering
local function _isWithinCombatCone(originCF: CFrame, targetPos: Vector3, minCosAngle: number): boolean
	local direction: Vector3 = targetPos - originCF.Position
	local distance: number = direction.Magnitude
	if distance <= 0.05 then return true end

	local forwardVec: Vector3 = originCF.LookVector
	local dotProduct: number = forwardVec:Dot(direction.Unit)
	return dotProduct >= minCosAngle
end

-- Rule 70 / 142: Load-Guarded Spatial VFX Broadcast
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

-- Rule 134: Synchronous Lifecycle Hook
function HitboxService.Init(Context: any)
	_moduleLoader = Context.ModuleLoader

	-- Lazy-load Janitor through standardized ModuleLoader (Rule 134 / Rule 140)
	local JanitorClass = _moduleLoader.RequireShared("Utility.Janitor")
	_janitor = JanitorClass.new()

	-- Server-side debounce garbage collection on PlayerRemoving (Rule 71 / Rule 140)
	local removeConn = Players.PlayerRemoving:Connect(function(player: Player)
		_attackerDebounce[player] = nil
	end)
	_janitor:GiveTask(removeConn)

	print("[HitboxService] Initialized synchronously via ModuleLoader")
end

-- Rule 134: Asynchronous Start Lifecycle Hook
function HitboxService.Start()
	-- Create / link UnreliableRemoteEvent for high-frequency VFX packets (Rule 74 / 75)
	local remoteFolder = ReplicatedStorage:FindFirstChild("CombatRemotes") :: Folder?
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "CombatRemotes"
		remoteFolder.Parent = ReplicatedStorage
		_janitor:GiveTask(remoteFolder)
	end

	local vfxEvent = remoteFolder:FindFirstChild("CombatVFX") :: UnreliableRemoteEvent?
	if not vfxEvent then
		vfxEvent = Instance.new("UnreliableRemoteEvent")
		vfxEvent.Name = "CombatVFX"
		vfxEvent.Parent = remoteFolder
		_janitor:GiveTask(vfxEvent)
	end
	_vfxRemote = vfxEvent

	print("[HitboxService] Started. Zero-trust spatial validation active.")
end

-- Core Execution: Shapecasting with Whitelist Filtering & Dot Product Checks
function HitboxService:ExecuteCast(request: HitboxRequest): { HitResult }
	local attacker = request.Attacker
	if not attacker then return {} end

	local rootPart = attacker:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return {} end

	-- Rate limiting check for player attackers (Rule 71)
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

	-- Configure Whitelist Overlap / Raycast Params
	local rayParams = RaycastParams.new()
	rayParams.FilterType = RaycastFilterType.Include
	if request.FilterFolder then
		rayParams.FilterDescendantsInstances = { request.FilterFolder }
	else
		rayParams.FilterDescendantsInstances = { Workspace }
	end
	rayParams.IgnoreWater = true

	local hitsRecorded: { HitResult } = {}
	local hitVictims: { [Model]: boolean } = {}
	local maxTargets = request.MaxTargets or DEFAULT_MAX_TARGETS

	-- Execute Shape-Cast (Blockcast or Spherecast)
	local result: RaycastResult? = nil
	if request.Shape == "Block" then
		result = Workspace:Blockcast(originCFrame, request.Size, castDirection, rayParams)
	elseif request.Shape == "Sphere" then
		local radius = math.max(request.Size.X, request.Size.Y, request.Size.Z) // 2 -- Rule 56 integer division
		result = Workspace:Spherecast(originCFrame.Position, radius, castDirection, rayParams)
	end

	if result and result.Instance then
		local hitPart = result.Instance
		local victimModel = hitPart:FindFirstAncestorOfClass("Model")

		if victimModel and victimModel ~= attacker and not hitVictims[victimModel] then
			local victimHRP = victimModel:FindFirstChild("HumanoidRootPart") :: BasePart?
			local victimHum = victimModel:FindFirstChildOfClass("Humanoid")

			if victimHRP and victimHum and victimHum.Health > 0 then
				-- Dot Product Angle Validation
				if _isWithinCombatCone(originCFrame, victimHRP.Position, DEFAULT_FOV_COS) then
					hitVictims[victimModel] = true

					-- Server Authoritative Damage Application
					victimHum:TakeDamage(request.Damage)

					-- Knockback impulse
					if request.Knockback and request.Knockback > 0 then
						local impulseDir = (victimHRP.Position - originCFrame.Position).Unit
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
	end

	return hitsRecorded
end

-- Marker-Driven Animation Trigger (Zero wait() hardcoding)
function HitboxService:BindToAnimationMarker(track: AnimationTrack, markerName: string, request: HitboxRequest)
	if not track or not track.IsPlaying then return end

	-- Clean up previous binding on the same track if re-bound
	if _activeTrackTasks[track] then
		_activeTrackTasks[track]:Disconnect()
		_activeTrackTasks[track] = nil
	end

	local signal = track:GetMarkerReachedSignal(markerName)
	local conn: RBXScriptConnection
	conn = signal:Connect(function()
		self:ExecuteCast(request)
	end)

	_activeTrackTasks[track] = conn
	_janitor:GiveTask(conn)

	-- Auto-cleanup on animation stop
	local stopConn: RBXScriptConnection
	stopConn = track.Stopped:Connect(function()
		if _activeTrackTasks[track] then
			_activeTrackTasks[track]:Disconnect()
			_activeTrackTasks[track] = nil
		end
		stopConn:Disconnect()
	end)
	_janitor:GiveTask(stopConn)
end

-- Rule 134: Destructor Cleanup Hook
function HitboxService.Destroy()
	for track, conn in _activeTrackTasks do
		conn:Disconnect()
	end
	table.clear(_activeTrackTasks)
	table.clear(_attackerDebounce)

	if _janitor then
		_janitor:Destroy()
		_janitor = nil
	end
	print("[HitboxService] Destroyed cleanly.")
end

return HitboxService
