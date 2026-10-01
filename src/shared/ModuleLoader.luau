--!strict
-- [ProductionCore / Shared / ModuleLoader.luau]
-- Core bootstrap lifecycle engine: Handles phased Init/Start, client pacing, and dependency resolution

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModuleLoader = {}
local ModuleCache: { [string]: any } = {}
local ScopeBootStateByName = { Shared = false, Server = false, Client = false }

export type LifecycleUnit = {
	Name: string,
	Loaded: any,
	Priority: number,
}

local function CreateScopeBootProgressState(ScopeName: string)
	return {
		ScopeName = ScopeName,
		CurrentModuleName = "Preparing",
		CurrentPhaseName = "Boot",
		CurrentModulePercent = 0,
		CompletedStepCount = 0,
		TotalStepCount = 0,
		Percent = 0,
		IsComplete = false,
	}
end

local function CalculateScopeBootPercent(CompletedStepCount: number, TotalStepCount: number): number
	if TotalStepCount <= 0 then return 100 end
	local RawPercent = (CompletedStepCount / TotalStepCount) * 100
	return math.clamp(math.floor(RawPercent + 0.5), 0, 100)
end

local function CountLifecyclePhaseSteps(LifecycleUnits: { LifecycleUnit }, PhaseName: string): number
	local Count = 0
	for _, Unit in ipairs(LifecycleUnits) do
		local Loaded = Unit.Loaded
		if type(Loaded) == "table" and type(Loaded[PhaseName]) == "function" then
			Count += 1
		end
	end
	return Count
end

local ScopeBootProgress: { [string]: any } = {}

local function ExecuteLifecyclePhase(ScopeName: string, LifecycleUnits: { LifecycleUnit }, PhaseName: string, Context: any)
	local progress = ScopeBootProgress[ScopeName]
	for _, Unit in ipairs(LifecycleUnits) do
		local Loaded = Unit.Loaded
		if type(Loaded) == "table" and type(Loaded[PhaseName]) == "function" then
			if progress then
				progress.CurrentModuleName = Unit.Name
				progress.CurrentPhaseName = PhaseName
			end

			debug.profilebegin(ScopeName .. ":" .. Unit.Name .. ":" .. PhaseName)
			if PhaseName == "Start" then
				-- Asynchronous Start dispatch ensures services initialize without thread blocking
				task.spawn(function()
					local success, err = pcall(function()
						Loaded[PhaseName](Context)
					end)
					if not success then
						warn(string.format("[ModuleLoader] Error during asynchronous %s on %s: %s", PhaseName, Unit.Name, tostring(err)))
					end
				end)
			else
				local success, err = pcall(function()
					Loaded[PhaseName](Context)
				end)
				if not success then
					error(string.format("[ModuleLoader] Error during %s on %s: %s", PhaseName, Unit.Name, tostring(err)))
				end
			end
			debug.profileend()

			if progress then
				progress.CompletedStepCount += 1
				progress.Percent = CalculateScopeBootPercent(progress.CompletedStepCount, progress.TotalStepCount)
			end
		end
	end
end

-- Resolve module instance from a dot-delimited path
local function ResolveModuleInstance(scope: string, path: string): ModuleScript?
	local current: Instance? = nil

	if scope == "Shared" or path:match("^Packages%.") or path:match("^SharedModules%.") then
		current = ReplicatedStorage
	elseif scope == "Server" or path:match("^ServerModules%.") then
		local sss = game:GetService("ServerScriptService")
		current = sss
	else
		current = ReplicatedStorage
	end

	local parts = string.split(path, ".")
	for _, part in ipairs(parts) do
		if not current then return nil end
		current = current:FindFirstChild(part)
	end

	if current and current:IsA("ModuleScript") then
		return current :: ModuleScript
	end
	return nil
end

function ModuleLoader.Register(name: string, module: any)
	ModuleCache[name] = module
	local simpleName = name:match("([^%.]+)$")
	if simpleName and ModuleCache[simpleName] == nil then
		ModuleCache[simpleName] = module
	end
end

function ModuleLoader.GetBootProgress(scopeName: string): any?
	return ScopeBootProgress[scopeName]
end

function ModuleLoader.Require(scope: string, path: string): any
	local cacheKey = scope .. ":" .. path
	if ModuleCache[cacheKey] ~= nil then
		return ModuleCache[cacheKey]
	end
	if ModuleCache[path] ~= nil then
		return ModuleCache[path]
	end

	local inst = ResolveModuleInstance(scope, path)
	if inst then
		local loaded = require(inst)
		ModuleCache[cacheKey] = loaded
		ModuleCache[path] = loaded
		return loaded
	end

	-- Check fallback in cache under simple name
	local simpleName = path:match("([^%.]+)$") or path
	if ModuleCache[simpleName] ~= nil then
		return ModuleCache[simpleName]
	end

	error(string.format("[ModuleLoader] Could not resolve module '%s' in scope '%s'", path, scope))
end

function ModuleLoader.RequireShared(path: string): any
	return ModuleLoader.Require("Shared", path)
end

function ModuleLoader.RequireScoped(path: string): any
	local isServer = RunService:IsServer()
	local scope = if isServer then "Server" else "Client"
	return ModuleLoader.Require(scope, path)
end

function ModuleLoader.Boot(scopeName: string, container: Instance)
	local units: { LifecycleUnit } = {}

	for _, descendant in ipairs(container:GetDescendants()) do
		if descendant:IsA("ModuleScript") then
			local success, loaded
			if (descendant :: any)._module ~= nil then
				success, loaded = true, (descendant :: any)._module
			else
				success, loaded = pcall(require, descendant)
			end
			if success then
				local priority = 10
				if type(loaded) == "table" and type(loaded.Metadata) == "table" and type(loaded.Metadata.Priority) == "number" then
					priority = loaded.Metadata.Priority
				end
				table.insert(units, {
					Name = descendant.Name,
					Loaded = loaded,
					Priority = priority,
				})
				ModuleCache[descendant.Name] = loaded
			else
				warn(string.format("[ModuleLoader] Failed to require %s: %s", descendant:GetFullName(), tostring(loaded)))
			end
		end
	end

	-- Sort by Priority descending (higher priority inits first)
	table.sort(units, function(a, b)
		return a.Priority > b.Priority
	end)

	local totalSteps = CountLifecyclePhaseSteps(units, "Init") + CountLifecyclePhaseSteps(units, "Start")
	local progress = CreateScopeBootProgressState(scopeName)
	progress.TotalStepCount = totalSteps
	ScopeBootProgress[scopeName] = progress

	local context = {
		ModuleLoader = ModuleLoader,
	}

	-- Phase 1: Synchronous Init
	ExecuteLifecyclePhase(scopeName, units, "Init", context)

	-- Phase 2: Asynchronous Start
	ExecuteLifecyclePhase(scopeName, units, "Start", context)

	progress.IsComplete = true
	progress.Percent = 100
	ScopeBootStateByName[scopeName] = true
	print(string.format("[ModuleLoader] Scope '%s' boot completed (%d modules).", scopeName, #units))
end

return ModuleLoader
