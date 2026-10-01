--!strict
-- [ProductionCore / Client / Controllers / InteractionController.luau]
-- Enterprise Dynamic Interaction & Proximity Prompt Optimization Controller.
-- Manages zero-allocation tag scopes, throttled proximity calculations, and automated teardown lifecycles.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local InteractionController: any = {}
InteractionController.Metadata = {
	Priority = 15,
}

local _spatialService: any = nil
local _tagService: any = nil
local _scythe: any = nil
local _controllerScope: number = 0
local _tagScopes: { [Instance]: number } = {}

local CheckInterval: number = 0.2
local InteractionRadius: number = 15
local _localPlayer = Players.LocalPlayer
local _activePrompts: { [Instance]: ProximityPrompt } = {}

function InteractionController.Init(context: any)
	local ml = context.ModuleLoader
	_scythe = ml.RequireShared("Packages.Scythe")
	_controllerScope = _scythe.scope()

	pcall(function()
		_spatialService = ml.RequireShared("SharedModules.SpatialService")
	end)
	pcall(function()
		_tagService = ml.RequireShared("SharedModules.TagService")
	end)
end

local function getInstancePosition(inst: Instance): Vector3?
	if inst:IsA("BasePart") then
		return (inst :: BasePart).Position
	elseif inst:IsA("Model") then
		local prim = (inst :: Model).PrimaryPart
		if prim then return prim.Position end
		return (inst :: Model):GetPivot().Position
	elseif inst:IsA("Attachment") then
		return (inst :: Attachment).WorldPosition
	end
	local part = inst:FindFirstChildWhichIsA("BasePart", true)
	if part then return part.Position end
	return nil
end

local function cleanupTagScope(instance: Instance)
	local scope = _tagScopes[instance]
	if scope then
		_tagScopes[instance] = nil
		_activePrompts[instance] = nil
		if _scythe and _scythe.isAlive(scope) then
			_scythe.remove(_controllerScope, scope)
			_scythe.scope(scope)
		end
	end
end

function InteractionController.Start()
	print("[InteractionController] Started")

	local function onInteractableAdded(instance: Instance)
		-- Clean up previous scope if re-tagged
		cleanupTagScope(instance)

		local tagScope: number = _scythe.scope() :: number
		_tagScopes[instance] = tagScope
		_scythe.add(_controllerScope, tagScope)

		local function setupPrompt(prompt: ProximityPrompt)
			prompt.Enabled = false
			_activePrompts[instance] = prompt
		end

		local prompt = instance:FindFirstChildWhichIsA("ProximityPrompt", true) :: ProximityPrompt?
		if prompt then
			setupPrompt(prompt)
		else
			local conn: RBXScriptConnection? = nil
			conn = instance.DescendantAdded:Connect(function(descendant: Instance)
				if descendant:IsA("ProximityPrompt") then
					setupPrompt(descendant :: ProximityPrompt)
					if conn then
						conn:Disconnect()
						conn = nil
					end
				end
			end)
			_scythe.add(tagScope, function()
				if conn then
					conn:Disconnect()
					conn = nil
				end
			end)
		end

		-- Clean up on ancestry removal to prevent memory leaks
		local ancestryConn = instance.AncestryChanged:Connect(function(_, parent)
			if not parent then
				cleanupTagScope(instance)
			end
		end)
		_scythe.add(tagScope, ancestryConn)

		_scythe.add(tagScope, function()
			_activePrompts[instance] = nil
		end)
	end

	-- Hook TagService watcher if available, or fall back to CollectionService
	if _tagService and _tagService.Watch then
		_tagService.Watch("Interactable", onInteractableAdded)
	else
		local CollectionService = game:GetService("CollectionService")
		for _, inst in ipairs(CollectionService:GetTagged("Interactable")) do
			task.spawn(onInteractableAdded, inst)
		end
		local tagAddedConn = CollectionService:GetInstanceAddedSignal("Interactable"):Connect(onInteractableAdded)
		local tagRemovedConn = CollectionService:GetInstanceRemovedSignal("Interactable"):Connect(cleanupTagScope)
		_scythe.add(_controllerScope, tagAddedConn)
		_scythe.add(_controllerScope, tagRemovedConn)
	end

	-- Throttled proximity loop (5 Hz) prevents per-frame CPU degradation
	local timeAccumulator = 0
	local heartbeatConn = RunService.Heartbeat:Connect(function(dt: number)
		timeAccumulator += dt
		if timeAccumulator < CheckInterval then return end
		timeAccumulator = 0

		local player = _localPlayer or Players.LocalPlayer
		if not player then return end
		local character = player.Character
		if not character then return end
		local root = (character.PrimaryPart or character:FindFirstChild("HumanoidRootPart")) :: BasePart?
		if not root then return end

		local myPos = root.Position
		for instance, prompt in pairs(_activePrompts) do
			if not instance.Parent or not prompt.Parent then
				cleanupTagScope(instance)
				continue
			end

			local targetPos = getInstancePosition(instance)
			if targetPos then
				local dist = (targetPos - myPos).Magnitude
				prompt.Enabled = (dist <= InteractionRadius)
			else
				prompt.Enabled = false
			end
		end
	end)
	_scythe.add(_controllerScope, heartbeatConn)
end

function InteractionController.Destroy()
	for instance in pairs(_tagScopes) do
		cleanupTagScope(instance)
	end
	table.clear(_activePrompts)
	table.clear(_tagScopes)
	if _scythe and _scythe.isAlive(_controllerScope) then
		_scythe.scope(_controllerScope)
	end
	print("[InteractionController] Destroyed cleanly via Scythe.")
end

return InteractionController
