--!strict

local InteractionTypes = require(script.Parent.InteractionTypes)
local InteractionConfig = require(script.Parent.InteractionConfig)

type InteractableConfig = InteractionTypes.InteractableConfig
type InteractionType = InteractionTypes.InteractionType
type InteractionState = InteractionTypes.InteractionState

local InteractionUtil = {}

function InteractionUtil.getInteractionPivot(instance: Instance): Vector3
	if instance:IsA("BasePart") then
		return instance.Position
	elseif instance:IsA("Model") then
		local primaryPart = instance.PrimaryPart
		if primaryPart then
			return primaryPart.Position
		end
		return instance:GetPivot().Position
	elseif instance:IsA("Attachment") then
		return instance.WorldPosition
	end
	return Vector3.zero
end

function InteractionUtil.getInteractableConfig(instance: Instance): InteractableConfig
	local interactionTypeRaw = instance:GetAttribute("InteractionType")
	local interactionType: InteractionType = if interactionTypeRaw == "Hold" then "Hold" else "Tap"

	local stateRaw = instance:GetAttribute("CurrentState")
	local currentState: InteractionState = if typeof(stateRaw) == "string" then stateRaw :: any else "Available"

	local holdDuration = instance:GetAttribute("HoldDuration")
	if typeof(holdDuration) ~= "number" then
		holdDuration = if interactionType == "Hold" then InteractionConfig.DefaultHoldDuration else 0
	end

	local maxDistance = instance:GetAttribute("MaxDistance")
	if typeof(maxDistance) ~= "number" then
		maxDistance = InteractionConfig.MaxDistanceDefault
	end

	local cooldown = instance:GetAttribute("Cooldown")
	if typeof(cooldown) ~= "number" then
		cooldown = InteractionConfig.DefaultCooldown
	end

	local actionText = instance:GetAttribute("ActionText")
	if typeof(actionText) ~= "string" or actionText == "" then
		actionText = if interactionType == "Hold" then "Hold to Interact" else "Interact"
	end

	local objectTitle = instance:GetAttribute("ObjectTitle")
	if typeof(objectTitle) ~= "string" or objectTitle == "" then
		objectTitle = instance.Name
	end

	local requiredItem = instance:GetAttribute("RequiredItem")
	if typeof(requiredItem) ~= "string" or requiredItem == "" then
		requiredItem = nil
	end

	local interactionId = instance:GetAttribute("InteractionId")
	if typeof(interactionId) ~= "string" or interactionId == "" then
		interactionId = instance.Name
	end

	return {
		InteractionId = interactionId,
		InteractionType = interactionType,
		HoldDuration = holdDuration,
		MaxDistance = maxDistance,
		Cooldown = cooldown,
		ActionText = actionText,
		ObjectTitle = objectTitle,
		RequiredItem = requiredItem,
		CurrentState = currentState,
	}
end

function InteractionUtil.getPlayerRoot(player: Player): BasePart?
	local char = player.Character
	if not char then
		return nil
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

function InteractionUtil.isPlayerAlive(player: Player): boolean
	local char = player.Character
	if not char then
		return false
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return false
	end
	return true
end

function InteractionUtil.getDistanceToTarget(player: Player, target: Instance): number
	local root = InteractionUtil.getPlayerRoot(player)
	if not root then
		return math.huge
	end
	local targetPos = InteractionUtil.getInteractionPivot(target)
	return (root.Position - targetPos).Magnitude
end

function InteractionUtil.isPlayerWithinRange(player: Player, target: Instance, customTolerance: number?): (boolean, number)
	local config = InteractionUtil.getInteractableConfig(target)
	local distance = InteractionUtil.getDistanceToTarget(player, target)
	local tolerance = customTolerance or InteractionConfig.DistanceTolerance
	local allowedMax = config.MaxDistance + tolerance
	return distance <= allowedMax, distance
end

function InteractionUtil.hasLineOfSight(player: Player, target: Instance, ignoreList: { Instance }?): boolean
	if not InteractionConfig.RaycastValidationEnabled then
		return true
	end
	local char = player.Character
	if not char then
		return false
	end
	local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
	if not head or not head:IsA("BasePart") then
		return false
	end

	local startPos = head.Position
	local targetPos = InteractionUtil.getInteractionPivot(target)
	local direction = targetPos - startPos
	local distance = direction.Magnitude

	if distance <= 0.5 then
		return true
	end

	local params = RaycastParams.new()
	params.FilterType = RaycastParamsFilterType.Exclude
	local excludes = { char, target }
	if ignoreList then
		for _, item in ipairs(ignoreList) do
			table.insert(excludes, item)
		end
	end
	params.FilterDescendantsInstances = excludes
	params.IgnoreWater = true

	local result = workspace:Raycast(startPos, direction.Unit * (distance - 0.2), params)
	if result and result.Instance and result.Instance.CanCollide and result.Instance.Transparency < 0.95 then
		return false
	end

	return true
end

return table.freeze(InteractionUtil)
