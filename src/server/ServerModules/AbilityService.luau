--!strict
-- [ProductionCore / ServerModules / AbilityService.luau]
-- Enterprise Ability Execution & Cooldown Rate-Limiting Controller.
-- Coordinates with AntiCheatService for physics whitelisting, manages atomic cooldowns, and binds Scythe lifecycles.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

export type AbilityDefinition = {
	Cooldown: number,
	ServiceName: string?,
	WhitelistPhysicsDuration: number?,
}

export type AbilityConfigType = {
	Abilities: { [string]: AbilityDefinition },
}

local AbilityService: any = {}
AbilityService.Metadata = {
	Priority = 20,
}

local _scythe: any = nil
local _serviceScope: number = 0
local _moduleLoader: any = nil
local _abilityConfig: AbilityConfigType? = nil
local _abilityActivated: RemoteEvent? = nil
local _lastUse: { [Player]: { [string]: number } } = {}

local function _onAbilityActivated(player: Player, abilityName: string, arg1: any, arg2: any)
	if typeof(abilityName) ~= "string" then return end
	if not _abilityConfig or not _abilityConfig.Abilities then return end

	local abilityData = _abilityConfig.Abilities[abilityName]
	if not abilityData then return end

	local now = os.clock()
	local playerCooldowns = _lastUse[player]
	if not playerCooldowns then
		playerCooldowns = {}
		_lastUse[player] = playerCooldowns
	end

	local lastTime = playerCooldowns[abilityName] or 0
	local minCooldown = math.max(0, (abilityData.Cooldown or 1.0) - 0.2)
	if now - lastTime < minCooldown then
		warn(string.format("[AbilityService] Rate limit exceeded for %s on %s", player.Name, abilityName))
		return
	end
	playerCooldowns[abilityName] = now

	-- Coordinate with server anti-cheat to whitelist physics burst during ability
	local antiCheat = _moduleLoader and _moduleLoader.RequireScoped("ServerModules.AntiCheatService")
	if antiCheat and antiCheat.BypassPlayer then
		local duration = abilityData.WhitelistPhysicsDuration or 4
		antiCheat.BypassPlayer(player, duration)
	end

	if abilityData.ServiceName and _moduleLoader then
		local service = _moduleLoader.Require("Server", "ServerModules." .. abilityData.ServiceName)
		if service and service.OnAbilityActivated then
			service.OnAbilityActivated(player, abilityName, arg1, arg2)
		end
	end
end

local function _setupRemotes()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes") :: Folder?
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
		_scythe.add(_serviceScope, remotes)
	end

	local remote = remotes:FindFirstChild("AbilityActivated") :: RemoteEvent?
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = "AbilityActivated"
		remote.Parent = remotes
		_scythe.add(_serviceScope, remote)
	end
	_abilityActivated = remote

	local conn = remote.OnServerEvent:Connect(_onAbilityActivated)
	_scythe.add(_serviceScope, conn)
end

function AbilityService.Init(context: any)
	_moduleLoader = context.ModuleLoader
	_scythe = _moduleLoader.RequireShared("Packages.Scythe")
	_serviceScope = _scythe.scope()

	local ok, cfg = pcall(function()
		return _moduleLoader.RequireShared("SharedModules.AbilityConfig")
	end)
	if ok and cfg then
		_abilityConfig = cfg
	else
		-- Fallback default config
		_abilityConfig = {
			Abilities = {
				Dash = { Cooldown = 3.0, ServiceName = nil, WhitelistPhysicsDuration = 1.5 },
				Slash = { Cooldown = 1.0, ServiceName = nil, WhitelistPhysicsDuration = 0.5 },
			},
		}
	end
end

function AbilityService.Start()
	_setupRemotes()

	local removeConn = Players.PlayerRemoving:Connect(function(plr: Player)
		_lastUse[plr] = nil
	end)
	_scythe.add(_serviceScope, removeConn)

	print("[AbilityService] Started. Authoritative cooldown pipeline ready.")
end

-- Query remaining cooldown time in seconds for a player's ability
function AbilityService.GetRemainingCooldown(player: Player, abilityName: string): number
	local playerCooldowns = _lastUse[player]
	if not playerCooldowns then return 0 end
	local lastTime = playerCooldowns[abilityName] or 0
	local cfg = _abilityConfig and _abilityConfig.Abilities and _abilityConfig.Abilities[abilityName]
	local totalCd = cfg and cfg.Cooldown or 1.0
	local elapsed = os.clock() - lastTime
	return math.max(0, totalCd - elapsed)
end

-- Programmatically trigger an ability with full authoritative validation
function AbilityService.TriggerAbility(player: Player, abilityName: string, arg1: any, arg2: any): boolean
	if not player or not player:IsDescendantOf(Players) then return false end
	local remaining = AbilityService.GetRemainingCooldown(player, abilityName)
	if remaining > 0.2 then return false end
	_onAbilityActivated(player, abilityName, arg1, arg2)
	return true
end

function AbilityService.Destroy()
	table.clear(_lastUse)
	if _scythe and _scythe.isAlive(_serviceScope) then
		_scythe.scope(_serviceScope)
	end
	print("[AbilityService] Destroyed cleanly via Scythe.")
end

return AbilityService
