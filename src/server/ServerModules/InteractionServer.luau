--!strict

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local InteractionSystem = ReplicatedStorage:WaitForChild("InteractionSystem")
local InteractionTypes = require(InteractionSystem:WaitForChild("InteractionTypes"))
local InteractionConfig = require(InteractionSystem:WaitForChild("InteractionConfig"))
local InteractionUtil = require(InteractionSystem:WaitForChild("InteractionUtil"))

local Remotes = InteractionSystem:WaitForChild("Remotes")
local RequestFunction = Remotes:WaitForChild("InteractionRequest") :: RemoteFunction
local HoldEvent = Remotes:WaitForChild("InteractionHold") :: RemoteEvent
local FeedbackEvent = Remotes:WaitForChild("InteractionFeedback") :: RemoteEvent

type ActiveHoldSession = InteractionTypes.ActiveHoldSession
type InteractionResponse = InteractionTypes.InteractionResponse

-- State storage
local PlayerInventories: { [Player]: { [string]: boolean } } = {}
local ActiveHolds: { [Player]: ActiveHoldSession } = {}
local PlayerCooldowns: { [Player]: number } = {}

-- Utility: play 3D positional sound
local function PlayPositionalSound(soundId: string, parentPart: BasePart, volume: number?)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 1.0
	sound.RollOffMaxDistance = 50
	sound.RollOffMinDistance = 5
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.Parent = parentPart
	sound:Play()
	task.delay(4, function()
		if sound and sound.Parent then
			sound:Destroy()
		end
	end)
end

-- Server Door Animation Handler
local function HandleDoorOpen(doorModel: Model)
	local soundRoot = doorModel.PrimaryPart or doorModel:FindFirstChildOfClass("BasePart")

	local statusScreen = doorModel:FindFirstChild("StatusScreen") :: BasePart?
	if statusScreen then
		statusScreen.Color = InteractionConfig.ColorSuccess
		local light = statusScreen:FindFirstChildOfClass("PointLight")
		if light then light.Color = InteractionConfig.ColorSuccess end
	end

	if soundRoot then
		PlayPositionalSound(InteractionConfig.SoundAccessGranted, soundRoot, 0.9)
	end

	-- Animate sliding leaves Door0 and Door1
	local ag = doorModel:FindFirstChild("Action Group", true)
	if ag then
		local d0 = ag:FindFirstChild("Door0") :: Model?
		local d1 = ag:FindFirstChild("Door1") :: Model?
		local tweenInfo = TweenInfo.new(1.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

		if d0 and d0.PrimaryPart then
			local startCF = d0.PrimaryPart:GetAttribute("ClosedCFrame") :: CFrame? or d0.PrimaryPart.CFrame
			local targetCF = startCF * CFrame.new(-3.8, 0, 0)
			TweenService:Create(d0.PrimaryPart, tweenInfo, { CFrame = targetCF }):Play()
		end

		if d1 and d1.PrimaryPart then
			local startCF = d1.PrimaryPart:GetAttribute("ClosedCFrame") :: CFrame? or d1.PrimaryPart.CFrame
			local targetCF = startCF * CFrame.new(3.8, 0, 0)
			TweenService:Create(d1.PrimaryPart, tweenInfo, { CFrame = targetCF }):Play()
		end
	end
end

-- Server Generator Repair Handler
local function HandleGeneratorRepaired(generatorModel: Model)
	generatorModel:SetAttribute("CurrentState", "Repaired")

	-- 1. Extinguish electrical sparks and stop arc flicker
	local faultPart = generatorModel:FindFirstChild("FaultVFX") :: BasePart?
	if faultPart then
		for _, desc in ipairs(faultPart:GetDescendants()) do
			if desc:IsA("ParticleEmitter") then
				desc.Enabled = false
			elseif desc:IsA("PointLight") then
				desc.Brightness = 0
			end
		end
	end

	-- 2. Emit one-shot pressure valve steam puff
	local steamPart = generatorModel:FindFirstChild("SteamVentVFX") :: BasePart?
	if steamPart then
		local steamEmitter = steamPart:FindFirstChild("SteamPuff", true) :: ParticleEmitter?
		if steamEmitter then
			steamEmitter:Emit(25)
		end
	end

	-- 3. Transition exhaust smoke to soft clean operational heat vapor
	local exhaustSmoke = generatorModel:FindFirstChild("ExhaustSmoke", true) :: ParticleEmitter?
	if exhaustSmoke then
		exhaustSmoke.Rate = 6
		exhaustSmoke.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 185, 190)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 225, 230))
		})
		exhaustSmoke.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.8),
			NumberSequenceKeypoint.new(0.3, 0.45),
			NumberSequenceKeypoint.new(1, 1.0)
		})
		exhaustSmoke.Speed = NumberRange.new(2.5, 4.0)
	end

	-- 4. Update physical control panel status diode
	local panelIndicator = generatorModel:FindFirstChild("PanelIndicator")
	local statusDiode = panelIndicator and panelIndicator:FindFirstChild("StatusDiode") :: BasePart?
	if statusDiode then
		statusDiode.Color = Color3.fromRGB(45, 230, 95)
		local diodeLight = statusDiode:FindFirstChildOfClass("PointLight")
		if diodeLight then
			diodeLight.Color = Color3.fromRGB(45, 230, 95)
			diodeLight.Brightness = 1.6
			diodeLight.Range = 8
		end
		PlayPositionalSound(InteractionConfig.SoundAccessGranted, statusDiode, 1.0)
	end

	-- 5. Start engine motor drone sound
	local corePart = generatorModel:FindFirstChild("GeneratorCore") :: BasePart?
	if corePart then
		corePart.Color = Color3.fromRGB(40, 180, 220)
		local humSound = corePart:FindFirstChild("HumSound") :: Sound?
		if humSound then
			humSound.Playing = true
		end
	end
end

-- Server Keycard Pickup Handler
local function HandleKeycardPickup(keycardModel: Model, player: Player)
	local cardPart = keycardModel:FindFirstChild("CardBody") :: BasePart? or keycardModel.PrimaryPart
	if cardPart then
		PlayPositionalSound(InteractionConfig.SoundPickupItem, cardPart, 0.9)
	end

	-- Hide visuals
	for _, desc in ipairs(keycardModel:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.Transparency = 1
			desc.CanCollide = false
		elseif desc:IsA("BillboardGui") or desc:IsA("PointLight") or desc:IsA("ParticleEmitter") then
			desc.Enabled = false
		end
	end
end

-- Reset Arena to initial state
local function ResetArena()
	local arena = workspace:FindFirstChild("InteractionArena")
	if not arena then return end

	-- Reset Keycard
	local keycard = arena:FindFirstChild("Keycard_Lvl1")
	if keycard then
		keycard:SetAttribute("CurrentState", "Available")
		for _, desc in ipairs(keycard:GetDescendants()) do
			if desc.Name == "CardBody" and desc:IsA("BasePart") then
				desc.Transparency = 0
			elseif desc.Name == "CardStripe" and desc:IsA("BasePart") then
				desc.Transparency = 0
			elseif desc.Name == "CardChip" and desc:IsA("BasePart") then
				desc.Transparency = 0
			elseif desc:IsA("PointLight") or desc:IsA("ParticleEmitter") then
				desc.Enabled = true
			end
		end
	end

	-- Reset Generator
	local gen = arena:FindFirstChild("Generator_01")
	if gen then
		gen:SetAttribute("CurrentState", "Available")
		local core = gen:FindFirstChild("GeneratorCore") :: BasePart?
		if core then
			core.Color = Color3.fromRGB(255, 100, 30)
		end

		local faultPart = gen:FindFirstChild("FaultVFX")
		if faultPart then
			for _, desc in ipairs(faultPart:GetDescendants()) do
				if desc:IsA("ParticleEmitter") then
					desc.Enabled = true
				end
			end
		end

		local exhaustSmoke = gen:FindFirstChild("ExhaustSmoke", true) :: ParticleEmitter?
		if exhaustSmoke then
			exhaustSmoke.Rate = 18
			exhaustSmoke.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 44)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 60, 65)),
				ColorSequenceKeypoint.new(1.0, Color3.fromRGB(90, 92, 95))
			})
			exhaustSmoke.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.8),
				NumberSequenceKeypoint.new(0.15, 0.3),
				NumberSequenceKeypoint.new(0.7, 0.6),
				NumberSequenceKeypoint.new(1.0, 1.0)
			})
		end

		local panelIndicator = gen:FindFirstChild("PanelIndicator")
		local statusDiode = panelIndicator and panelIndicator:FindFirstChild("StatusDiode") :: BasePart?
		if statusDiode then
			statusDiode.Color = Color3.fromRGB(240, 45, 45)
			local diodeLight = statusDiode:FindFirstChildOfClass("PointLight")
			if diodeLight then
				diodeLight.Color = Color3.fromRGB(240, 45, 45)
				diodeLight.Brightness = 1.2
				diodeLight.Range = 6
			end
		end
	end

	-- Reset Blast Door
	local door = arena:FindFirstChild("BlastDoor_A1")
	if door then
		door:SetAttribute("CurrentState", "Available")
		local ag = door:FindFirstChild("Action Group", true)
		if ag then
			local d0 = ag:FindFirstChild("Door0") :: Model?
			local d1 = ag:FindFirstChild("Door1") :: Model?
			if d0 and d0.PrimaryPart then
				local closed = d0.PrimaryPart:GetAttribute("ClosedCFrame") :: CFrame?
				if closed then d0.PrimaryPart.CFrame = closed end
			end
			if d1 and d1.PrimaryPart then
				local closed = d1.PrimaryPart:GetAttribute("ClosedCFrame") :: CFrame?
				if closed then d1.PrimaryPart.CFrame = closed end
			end
		end
		local statusScreen = door:FindFirstChild("StatusScreen") :: BasePart?
		if statusScreen then
			statusScreen.Color = Color3.fromRGB(255, 60, 60)
			local light = statusScreen:FindFirstChildOfClass("PointLight")
			if light then light.Color = Color3.fromRGB(255, 60, 60) end
		end
	end
end

ResetArena()

-- Player lifecycle
Players.PlayerAdded:Connect(function(player)
	PlayerInventories[player] = {}
	PlayerCooldowns[player] = 0
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerInventories[player] = nil
	ActiveHolds[player] = nil
	PlayerCooldowns[player] = nil
end)

-- Hold event listener
HoldEvent.OnServerEvent:Connect(function(player: Player, action: string, target: Instance)
	if action == "Start" then
		if not target or not target:IsDescendantOf(workspace) then
			return
		end
		if not CollectionService:HasTag(target, InteractionConfig.InteractableTag) then
			return
		end
		if not InteractionUtil.isPlayerAlive(player) then
			return
		end
		local withinRange = InteractionUtil.isPlayerWithinRange(player, target)
		if not withinRange then
			return
		end

		local config = InteractionUtil.getInteractableConfig(target)
		if config.InteractionType ~= "Hold" or config.CurrentState ~= "Available" then
			return
		end

		ActiveHolds[player] = {
			Player = player,
			Target = target,
			StartTime = os.clock(),
			HoldDuration = config.HoldDuration,
		}
	elseif action == "Cancel" then
		ActiveHolds[player] = nil
	end
end)

-- Main server authoritative request dispatcher
RequestFunction.OnServerInvoke = function(player: Player, action: string, target: Instance): InteractionResponse
	local now = os.clock()

	-- 1. Anti-spam / Cooldown validation
	local lastCall = PlayerCooldowns[player] or 0
	if (now - lastCall) < 0.25 and action ~= "CompleteHold" then
		return {
			Success = false,
			Reason = "RateLimit",
			Message = "ACTION RATE LIMITED",
		}
	end
	PlayerCooldowns[player] = now

	-- 2. Target validation
	if not target or not target:IsDescendantOf(workspace) then
		return {
			Success = false,
			Reason = "InvalidTarget",
			Message = "TARGET NOT FOUND",
		}
	end

	if not CollectionService:HasTag(target, InteractionConfig.InteractableTag) then
		return {
			Success = false,
			Reason = "NotInteractable",
			Message = "OBJECT IS NOT INTERACTABLE",
		}
	end

	-- 3. Player state validation
	if not InteractionUtil.isPlayerAlive(player) then
		return {
			Success = false,
			Reason = "PlayerDead",
			Message = "PLAYER INCAPACITATED",
		}
	end

	-- 4. Distance and line-of-sight validation
	local withinRange, dist = InteractionUtil.isPlayerWithinRange(player, target)
	if not withinRange then
		return {
			Success = false,
			Reason = "OutOfRange",
			Message = string.format("OUT OF RANGE (%.1f STUDS)", dist),
		}
	end

	local config = InteractionUtil.getInteractableConfig(target)

	-- 5. Execution based on action type
	if action == "Interact" then
		if config.InteractionType ~= "Tap" then
			return {
				Success = false,
				Reason = "TypeMismatch",
				Message = "REQUIRES HOLD INTERACTION",
			}
		end

		if config.CurrentState ~= "Available" then
			return {
				Success = false,
				Reason = "Unavailable",
				Message = "OBJECT IS ALREADY IN USE",
			}
		end

		-- Conditional dependency verification
		if config.RequiredItem then
			local inv = PlayerInventories[player] or {}
			if not inv[config.RequiredItem] then
				local soundPart = if target:IsA("BasePart") then target else (target:FindFirstChildOfClass("BasePart") or InteractionUtil.getPlayerRoot(player))
				if soundPart then
					PlayPositionalSound(InteractionConfig.SoundAccessDenied, soundPart, 0.9)
				end

				FeedbackEvent:FireClient(player, {
					Type = "Notification",
					Target = target,
					Message = "LOCKED: REQUIRES LEVEL 1 KEYCARD",
					Payload = { Status = "Denied", Color = "Danger" }
				})

				return {
					Success = false,
					Reason = "RequirementMissing",
					Message = "LOCKED: REQUIRES LEVEL 1 KEYCARD",
				}
			end
		end

		local targetName = target.Name
		if targetName == "Keycard_Lvl1" or target:GetAttribute("ItemReward") == "Keycard_Lvl1" then
			PlayerInventories[player]["Keycard_Lvl1"] = true
			target:SetAttribute("CurrentState", "Collected")
			if target:IsA("Model") then
				HandleKeycardPickup(target, player)
			end

			FeedbackEvent:FireClient(player, {
				Type = "InventoryUpdated",
				Target = target,
				Message = "SECURITY KEYCARD [LVL 1] ACQUIRED",
				Payload = { Item = "Keycard_Lvl1", Status = true }
			})

			return {
				Success = true,
				Message = "KEYCARD ACQUIRED [LEVEL 1]",
				State = "Collected",
				ItemAcquired = "Keycard_Lvl1",
			}

		elseif targetName == "BlastDoor_A1" or target:GetAttribute("InteractionId") == "BlastDoor_A1" then
			target:SetAttribute("CurrentState", "Open")
			if target:IsA("Model") then
				HandleDoorOpen(target)
			end

			FeedbackEvent:FireAllClients({
				Type = "Notification",
				Target = target,
				Message = "ACCESS GRANTED: BULKHEAD OPENING",
				Payload = { Status = "Granted", Color = "Success" }
			})

			return {
				Success = true,
				Message = "ACCESS GRANTED: BULKHEAD OPENING",
				State = "Open",
			}
		else
			target:SetAttribute("CurrentState", "Completed")
			return {
				Success = true,
				Message = "INTERACTION COMPLETED",
				State = "Completed",
			}
		end

	elseif action == "CompleteHold" then
		local session = ActiveHolds[player]
		if not session then
			return {
				Success = false,
				Reason = "NoSession",
				Message = "NO ACTIVE HOLD DETECTED",
			}
		end

		if session.Target ~= target then
			ActiveHolds[player] = nil
			return {
				Success = false,
				Reason = "TargetMismatch",
				Message = "ACTIVE HOLD TARGET MISMATCH",
			}
		end

		local elapsed = now - session.StartTime
		local requiredTime = session.HoldDuration - InteractionConfig.HoldLatencyTolerance
		if elapsed < requiredTime then
			ActiveHolds[player] = nil
			return {
				Success = false,
				Reason = "PrematureCompletion",
				Message = "HOLD INTERRUPTED OR TOO FAST",
			}
		end

		ActiveHolds[player] = nil

		if target.Name == "Generator_01" or target:GetAttribute("InteractionId") == "Generator_01" then
			target:SetAttribute("CurrentState", "Repaired")
			if target:IsA("Model") then
				HandleGeneratorRepaired(target)
			end

			FeedbackEvent:FireAllClients({
				Type = "Notification",
				Target = target,
				Message = "AUXILIARY GENERATOR RESTORED",
				Payload = { Status = "Repaired", Color = "Success" }
			})

			return {
				Success = true,
				Message = "AUXILIARY GENERATOR RESTORED",
				State = "Repaired",
			}
		else
			target:SetAttribute("CurrentState", "Repaired")
			return {
				Success = true,
				Message = "REPAIR COMPLETED",
				State = "Repaired",
			}
		end

	else
		return {
			Success = false,
			Reason = "UnknownAction",
			Message = "UNKNOWN INTERACTION ACTION",
		}
	end
end

print("ServerScriptService.InteractionServer updated with realistic generator VFX and door pipeline.")
