--!strict
-- [ProductionCore / ServerModules / AntiCheatService.luau]
-- Enterprise Authoritative Server Anti-Cheat & Exploit Mitigation Controller.
-- Provides displacement validation, speed-hack suppression, ability bypass coordination, and leak-free memory management.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

export type ViolationData = {
	Type: string,
	Details: { [string]: any }?,
	Timestamp: number,
}

export type PlayerState = {
	Player: Player,
	Violations: number,
	SuspicionScore: number,
	JoinTime: number,
	LastCheckTime: number,
	LastPosition: Vector3?,
	LastVerifiedPosition: Vector3?,
	LastVelocity: Vector3,
	AirTime: number,
	BypassUntil: number,
	IsWhitelisted: boolean,
}

local AntiCheatService: any = {}
local AntiCheatConfig = {
	PositionCheckInterval = 0.1,
	MaxInstantDisplacement = 45,
	MaxSuspicionScore = 30,
	RubberbandThreshold = 8,
	DecayRate = 2.0,
	NoclipCheck = true,
	AutoKickThreshold = 12,
	AutoBanThreshold = 20,
	StrictPunishment = true,
	LogViolations = true,
	Whitelist = {} :: { number },
}

local PlayerStates: { [number]: PlayerState } = {}
local ViolationHistory: { [number]: { ViolationData } } = {}

AntiCheatService.Metadata = {
	Priority = 30,
}

local _scythe: any = nil
local _serviceScope: number = 0
local _moduleLoader: any = nil

local function EnforcePunishment(player: Player, action: string, reason: string)
	if not AntiCheatConfig.StrictPunishment then
		warn(string.format("[AntiCheatService] [DRY RUN] %s on %s. Reason: %s", action, player.Name, reason))
		return
	end

	if action == "Kick" then
		player:Kick("\n[Security Enforcement]\n" .. reason)
	elseif action == "Ban" then
		pcall(function()
			Players:BanAsync({
				UserIds = { player.UserId },
				ApplyToUniverse = true,
				Duration = 604800,
				DisplayReason = "Security Violation: Exploiting Detected",
				PrivateReason = reason,
			})
		end)
		player:Kick("\n[Security System]\nAccount suspended for exploiting.")
	end
end

local function RecordViolation(player: Player, violation: ViolationData)
	local userId = player.UserId
	ViolationHistory[userId] = ViolationHistory[userId] or {}
	table.insert(ViolationHistory[userId], violation)

	local state = PlayerStates[userId]
	if state then
		state.Violations += 1
		if violation.Type == "HoneypotTriggered" or violation.Type == "ExecutorDetected" then
			EnforcePunishment(player, "Ban", "Unauthorized Honeypot / Exploit Execution")
		elseif state.Violations >= AntiCheatConfig.AutoBanThreshold then
			EnforcePunishment(player, "Ban", "Multiple Anti-Cheat Violations")
		elseif state.Violations >= AntiCheatConfig.AutoKickThreshold then
			EnforcePunishment(player, "Kick", "Displacement verification threshold exceeded")
		end
	end
end

-- Whitelist player for burst physics during authorized combat abilities
function AntiCheatService.BypassPlayer(player: Player, duration: number)
	local state = PlayerStates[player.UserId]
	if state then
		local targetBypass = os.clock() + duration
		if targetBypass > state.BypassUntil then
			state.BypassUntil = targetBypass
		end
	end
end

-- Initialize tracking state for a connected player
local function _trackPlayer(player: Player)
	local now = os.clock()
	PlayerStates[player.UserId] = {
		Player = player,
		Violations = 0,
		SuspicionScore = 0,
		JoinTime = now,
		LastCheckTime = now,
		LastPosition = nil,
		LastVerifiedPosition = nil,
		LastVelocity = Vector3.zero,
		AirTime = 0,
		BypassUntil = 0,
		IsWhitelisted = table.find(AntiCheatConfig.Whitelist, player.UserId) ~= nil,
	}
end

-- Purge tracking state on disconnect to eliminate memory leaks
local function _untrackPlayer(player: Player)
	PlayerStates[player.UserId] = nil
	ViolationHistory[player.UserId] = nil
end

function AntiCheatService.Init(context: any)
	_moduleLoader = context.ModuleLoader
	_scythe = _moduleLoader.RequireShared("Packages.Scythe")
	_serviceScope = _scythe.scope()

	local addConn = Players.PlayerAdded:Connect(_trackPlayer)
	local remConn = Players.PlayerRemoving:Connect(_untrackPlayer)

	_scythe.add(_serviceScope, addConn)
	_scythe.add(_serviceScope, remConn)

	for _, player in ipairs(Players:GetPlayers()) do
		_trackPlayer(player)
	end

	print("[AntiCheatService] Initialized with Scythe scope and leak-free session tracking.")
end

function AntiCheatService.Start()
	local lastCheck = os.clock()

	local heartbeatConn = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		local dt = now - lastCheck
		if dt < AntiCheatConfig.PositionCheckInterval then return end
		lastCheck = now

		for userId, state in pairs(PlayerStates) do
			local player = state.Player
			if not player or not player:IsDescendantOf(Players) then
				PlayerStates[userId] = nil
				ViolationHistory[userId] = nil
				continue
			end

			if state.IsWhitelisted or now < state.BypassUntil then
				state.LastPosition = nil
				continue
			end

			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then
				state.LastPosition = nil
				continue
			end

			local currentPos = hrp.Position
			if state.LastPosition then
				local displacement = (currentPos - state.LastPosition).Magnitude
				if displacement > AntiCheatConfig.MaxInstantDisplacement then
					state.SuspicionScore += 5
					RecordViolation(player, {
						Type = "DisplacementExceeded",
						Details = { Displacement = displacement, Allowed = AntiCheatConfig.MaxInstantDisplacement },
						Timestamp = now,
					})
					if state.LastVerifiedPosition then
						hrp.CFrame = CFrame.new(state.LastVerifiedPosition)
						hrp.Position = state.LastVerifiedPosition
						hrp.AssemblyLinearVelocity = Vector3.zero
						hrp.AssemblyAngularVelocity = Vector3.zero
						state.LastPosition = state.LastVerifiedPosition
					else
						state.LastPosition = currentPos
					end
				else
					state.LastVerifiedPosition = currentPos
					state.LastPosition = currentPos
				end
			else
				state.LastVerifiedPosition = currentPos
				state.LastPosition = currentPos
			end

			-- Suspicion Score Decay over time
			state.SuspicionScore = math.max(0, state.SuspicionScore - AntiCheatConfig.DecayRate * dt)
			if state.SuspicionScore >= AntiCheatConfig.MaxSuspicionScore then
				EnforcePunishment(player, "Kick", "Suspicion score threshold exceeded")
			end

			state.LastCheckTime = now
		end
	end)

	_scythe.add(_serviceScope, heartbeatConn)
	print("[AntiCheatService] Started. Authoritative spatial validation active.")
end

-- Report a violation from honeypots or server scripts
function AntiCheatService.ReportViolation(player: Player, violationType: string, details: { [string]: any }?)
	RecordViolation(player, {
		Type = violationType,
		Details = details,
		Timestamp = os.clock(),
	})
end

-- Get tracking state for a player
function AntiCheatService.GetPlayerState(player: Player): PlayerState?
	return PlayerStates[player.UserId]
end

-- Get recorded violation history for a player
function AntiCheatService.GetViolationHistory(player: Player): { ViolationData }?
	return ViolationHistory[player.UserId]
end

function AntiCheatService.Destroy()
	table.clear(PlayerStates)
	table.clear(ViolationHistory)
	if _scythe and _scythe.isAlive(_serviceScope) then
		_scythe.scope(_serviceScope)
	end
	print("[AntiCheatService] Destroyed cleanly via Scythe.")
end

return AntiCheatService
