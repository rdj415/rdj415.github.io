--!strict
-- [ProductionCore / Shared / SharedModules / AtomicBinding.luau]
-- Custom pattern-matching library: Resolves hierarchical instance trees with automated destructors

local RootAlias = "root"

local function parsePath(pathStr: string): { string }
	local pathArray = string.split(pathStr, "/")
	for idx = #pathArray, 1, -1 do
		if pathArray[idx] == "" then
			table.remove(pathArray, idx)
		end
	end
	return pathArray
end

local function isManifestResolved(resolvedManifest: { [string]: Instance }, manifestSizeTarget: number): boolean
	local manifestSize = 0
	for _ in pairs(resolvedManifest) do
		manifestSize += 1
	end
	assert(manifestSize <= manifestSizeTarget, tostring(manifestSize))
	return manifestSize == manifestSizeTarget
end

local function unbindNodeDescend(node: any, resolvedManifest: { [string]: Instance })
	if node.instance == nil then return end
	node.instance = nil
	local connections = node.connections
	if connections then
		for _, conn in ipairs(connections) do
			conn:Disconnect()
		end
		table.clear(connections)
	end
	if resolvedManifest and node.alias then
		resolvedManifest[node.alias] = nil
	end
	local children = node.children
	if children then
		for _, childNode in pairs(children) do
			unbindNodeDescend(childNode, resolvedManifest)
		end
	end
end

local AtomicBinding = {}
AtomicBinding.__index = AtomicBinding

export type Destructor = () -> () | RBXScriptConnection | Instance | { Destroy: (any) -> () } | { destroy: (any) -> () } | any
export type BoundCallback = (manifest: { [string]: Instance }) -> Destructor?

function AtomicBinding.new(manifest: { [string]: string }, boundFn: BoundCallback)
	local parsedManifest = {}
	local manifestSizeTarget = 1
	for alias, rawPath in pairs(manifest) do
		parsedManifest[alias] = parsePath(rawPath)
		manifestSizeTarget += 1
	end
	return setmetatable({
		_boundFn = boundFn,
		_parsedManifest = parsedManifest,
		_manifestSizeTarget = manifestSizeTarget,
		_dtorMap = {} :: { [Instance]: Destructor? },
		_connections = {},
		_rootInstToRootNode = {},
		_rootInstToManifest = {} :: { [Instance]: { [string]: Instance } },
	}, AtomicBinding)
end

function AtomicBinding:_startBoundFn(root: Instance, resolvedManifest: { [string]: Instance })
	if self._dtorMap[root] ~= nil then
		return
	end
	local success, dtor = pcall(self._boundFn, resolvedManifest)
	if success then
		self._dtorMap[root] = dtor
	else
		warn(string.format("[AtomicBinding] Error executing bound callback on %s: %s", root:GetFullName(), tostring(dtor)))
	end
end

function AtomicBinding:_stopBoundFn(root: Instance)
	local dtor = self._dtorMap[root]
	if dtor == nil then return end
	self._dtorMap[root] = nil

	pcall(function()
		local dtorType = typeof(dtor)
		if dtorType == "function" then
			(dtor :: () -> ())()
		elseif dtorType == "RBXScriptConnection" then
			(dtor :: RBXScriptConnection):Disconnect()
		elseif dtorType == "Instance" then
			(dtor :: Instance):Destroy()
		elseif dtorType == "table" then
			local tbl = dtor :: any
			if typeof(tbl.Destroy) == "function" then
				tbl:Destroy()
			elseif typeof(tbl.destroy) == "function" then
				tbl:destroy()
			elseif typeof(tbl.Disconnect) == "function" then
				tbl:Disconnect()
			end
		end
	end)
end

function AtomicBinding:bindRoot(root: Instance)
	debug.profilebegin("AtomicBinding:BindRoot")
	local parsedManifest = self._parsedManifest
	local rootInstToRootNode = self._rootInstToRootNode
	local rootInstToManifest = self._rootInstToManifest
	local manifestSizeTarget = self._manifestSizeTarget
	assert(rootInstToManifest[root] == nil, "Root instance is already bound")

	local resolvedManifest: { [string]: Instance } = {}
	rootInstToManifest[root] = resolvedManifest

	local rootNode = {
		alias = RootAlias,
		instance = root,
		children = {},
		connections = {},
	}
	rootInstToRootNode[root] = rootNode

	-- Build hierarchical search tree from path segments
	for alias, parsedPath in pairs(parsedManifest) do
		local parentNode = rootNode
		for idx, childName in ipairs(parsedPath) do
			local leaf = idx == #parsedPath
			local childNode = parentNode.children[childName] or {}
			if leaf then
				childNode.alias = alias
			else
				childNode.children = childNode.children or {}
				childNode.connections = childNode.connections or {}
			end
			parentNode.children[childName] = childNode
			parentNode = childNode
		end
	end

	local function processNode(node: any)
		local instance = assert(node.instance)
		local children = node.children
		if node.alias then resolvedManifest[node.alias] = instance end

		if children then
			local function processAddChild(childInstance: Instance)
				local childNode = children[childInstance.Name]
				if not childNode or childNode.instance ~= nil then return end
				childNode.instance = childInstance
				processNode(childNode)
			end

			local function processDeleteChild(childInstance: Instance)
				local childNode = children[childInstance.Name]
				if not childNode or childNode.instance ~= childInstance then return end
				self:_stopBoundFn(root)
				unbindNodeDescend(childNode, resolvedManifest)
			end

			for _, child in ipairs(instance:GetChildren()) do processAddChild(child) end
			table.insert(node.connections, instance.ChildAdded:Connect(processAddChild))
			table.insert(node.connections, instance.ChildRemoved:Connect(processDeleteChild))
		end

		if not children and isManifestResolved(resolvedManifest, manifestSizeTarget) then
			self:_startBoundFn(root, resolvedManifest)
		end
	end

	processNode(rootNode)
	debug.profileend()
end

function AtomicBinding:unbindRoot(root: Instance)
	self:_stopBoundFn(root)
	local rootNode = self._rootInstToRootNode[root]
	if rootNode then
		unbindNodeDescend(rootNode, self._rootInstToManifest[root])
		self._rootInstToRootNode[root] = nil
	end
	self._rootInstToManifest[root] = nil
end

function AtomicBinding:destroy()
	for root in pairs(self._rootInstToManifest) do
		self:unbindRoot(root)
	end
	table.clear(self._rootInstToRootNode)
	table.clear(self._rootInstToManifest)
	table.clear(self._dtorMap)
end

return AtomicBinding
