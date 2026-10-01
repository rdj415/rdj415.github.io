--!strict
-- [ProductionCore / Packages / Scythe.luau]
-- Enterprise Zero-Allocation Scope-Based Memory Management Engine.
-- Provides ultra-low-overhead resource lifecycle and cleanup via numeric scope handles.

export type ScopeId = number
export type CleanupTask = Instance | RBXScriptConnection | () -> () | thread | ScopeId | { Destroy: (any) -> () } | { destroy: (any) -> () } | { Disconnect: (any) -> () } | { disconnect: (any) -> () } | any

local _scopes: { [ScopeId]: { CleanupTask } } = {}
local _nextScopeId: ScopeId = 0

local Scythe = {}

local function _cleanupResource(resource: CleanupTask)
	local resType = typeof(resource)

	if resType == "RBXScriptConnection" then
		(resource :: RBXScriptConnection):Disconnect()
	elseif resType == "Instance" then
		(resource :: Instance):Destroy()
	elseif resType == "function" then
		(resource :: () -> ())()
	elseif resType == "thread" then
		local th = resource :: thread
		if coroutine.status(th) ~= "dead" then
			task.cancel(th)
		end
	elseif resType == "number" then
		Scythe.scope(resource :: ScopeId)
	elseif resType == "table" then
		local tbl = resource :: any
		if typeof(tbl.Destroy) == "function" then
			tbl:Destroy()
		elseif typeof(tbl.destroy) == "function" then
			tbl:destroy()
		elseif typeof(tbl.Disconnect) == "function" then
			tbl:Disconnect()
		elseif typeof(tbl.disconnect) == "function" then
			tbl:disconnect()
		end
	end
end

-- Create a new scope handle or destroy an existing scope
function Scythe.scope(scopeId: ScopeId?): ScopeId?
	if scopeId == nil then
		_nextScopeId += 1
		local id = _nextScopeId
		_scopes[id] = {}
		return id
	end

	local bucket = _scopes[scopeId]
	if not bucket then
		return nil
	end

	_scopes[scopeId] = nil

	-- Clean up resources in reverse order (LIFO)
	for i = #bucket, 1, -1 do
		local taskItem = bucket[i]
		local ok, err = pcall(_cleanupResource, taskItem)
		if not ok then
			warn(string.format("[Scythe] Cleanup error in scope %d: %s", scopeId, tostring(err)))
		end
	end

	return nil
end

-- Register a resource inside the specified scope
function Scythe.add(scopeId: ScopeId, resource: CleanupTask): CleanupTask
	local bucket = _scopes[scopeId]
	if not bucket then
		warn(string.format("[Scythe] Attempted to add resource to dead or invalid scope %d. Cleaning immediately.", scopeId))
		pcall(_cleanupResource, resource)
		return resource
	end

	table.insert(bucket, resource)
	return resource
end

-- Batch register an array of resources inside the specified scope
function Scythe.addBulk(scopeId: ScopeId, resources: { CleanupTask })
	local bucket = _scopes[scopeId]
	if not bucket then
		warn(string.format("[Scythe] Attempted to addBulk resources to dead or invalid scope %d. Cleaning immediately.", scopeId))
		for _, res in resources do
			pcall(_cleanupResource, res)
		end
		return
	end

	for _, res in resources do
		table.insert(bucket, res)
	end
end

-- Remove a resource from an active scope without destroying it immediately
function Scythe.remove(scopeId: ScopeId, resource: CleanupTask): boolean
	local bucket = _scopes[scopeId]
	if not bucket then return false end

	local idx = table.find(bucket, resource)
	if idx then
		table.remove(bucket, idx)
		return true
	end
	return false
end

-- Check if the scope is currently active
function Scythe.isAlive(scopeId: ScopeId): boolean
	return _scopes[scopeId] ~= nil
end

return table.freeze(Scythe)
