--!strict

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local ScreenGui = script.Parent :: ScreenGui
local Camera = workspace.CurrentCamera

local InteractionSystem = ReplicatedStorage:WaitForChild("InteractionSystem")
local InteractionTypes = require(InteractionSystem:WaitForChild("InteractionTypes"))
local InteractionConfig = require(InteractionSystem:WaitForChild("InteractionConfig"))
local InteractionUtil = require(InteractionSystem:WaitForChild("InteractionUtil"))

local Remotes = InteractionSystem:WaitForChild("Remotes")
local RequestFunction = Remotes:WaitForChild("InteractionRequest") :: RemoteFunction
local HoldEvent = Remotes:WaitForChild("InteractionHold") :: RemoteEvent
local FeedbackEvent = Remotes:WaitForChild("InteractionFeedback") :: RemoteEvent

type InteractableConfig = InteractionTypes.InteractableConfig
type InteractionResponse = InteractionTypes.InteractionResponse

-- UI Elements
local PromptCard = ScreenGui:WaitForChild("PromptCard") :: Frame
local ArrowContainer = PromptCard:WaitForChild("ArrowContainer") :: Frame
local ArrowIcon = ArrowContainer:WaitForChild("ArrowIcon") :: ImageLabel

local MainRow = PromptCard:WaitForChild("MainRow") :: Frame
local KeyWrapper = MainRow:WaitForChild("KeyWrapper") :: Frame
local KeyBadge = KeyWrapper:WaitForChild("KeyBadge") :: Frame
local KeyLabel = KeyBadge:WaitForChild("KeyLabel") :: TextLabel
local ProgressRing = KeyWrapper:WaitForChild("ProgressRing") :: Frame
local RingStroke = ProgressRing:WaitForChild("RingStroke") :: UIStroke

local TextContainer = MainRow:WaitForChild("TextContainer") :: Frame
local ActionLabel = TextContainer:WaitForChild("ActionLabel") :: TextLabel
local ObjectTitleLabel = TextContainer:WaitForChild("ObjectTitleLabel") :: TextLabel
local StatusLabel = TextContainer:WaitForChild("StatusLabel") :: TextLabel
local HoldBarContainer = TextContainer:WaitForChild("HoldBarContainer") :: Frame
local HoldBarFill = HoldBarContainer:WaitForChild("HoldBarFill") :: Frame

-- Facility Objectives Tracker
local FacilityTracker = ScreenGui:WaitForChild("FacilityTracker") :: Frame
local KeycardRow = FacilityTracker:WaitForChild("KeycardRow") :: Frame
local KeycardIcon = KeycardRow:WaitForChild("StatusIcon") :: TextLabel
local KeycardTitle = KeycardRow:WaitForChild("TitleLabel") :: TextLabel

local GeneratorRow = FacilityTracker:WaitForChild("GeneratorRow") :: Frame
local GeneratorIcon = GeneratorRow:WaitForChild("StatusIcon") :: TextLabel
local GeneratorTitle = GeneratorRow:WaitForChild("TitleLabel") :: TextLabel

local BulkheadRow = FacilityTracker:WaitForChild("BulkheadRow") :: Frame
local BulkheadIcon = BulkheadRow:WaitForChild("StatusIcon") :: TextLabel
local BulkheadTitle = BulkheadRow:WaitForChild("TitleLabel") :: TextLabel

-- Alert Toast
local ToastBanner = ScreenGui:WaitForChild("ToastBanner") :: Frame
local ToastText = ToastBanner:WaitForChild("ToastText") :: TextLabel
local ToastStroke = ToastBanner:WaitForChild("ToastStroke") :: UIStroke
local ToastAccent = ToastBanner:WaitForChild("ToastAccent") :: Frame

-- Client State
local LocalInventory: { [string]: boolean } = {}
local FocusedTarget: Instance? = nil
local FocusedConfig: InteractableConfig? = nil

local IsHolding = false
local HoldStartTime = 0
local HoldDuration = 3.0
local HoldTarget: Instance? = nil
local IsRequestInFlight = false

-- Helper: Play UI audio
local function PlayUiSound(soundId: string, volume: number?)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.8
	sound.Parent = SoundService
	sound:Play()
	task.delay(3, function()
		if sound and sound.Parent then
			sound:Destroy()
		end
	end)
end

-- Update Objective Tracker Row with smooth animation
local function SetObjectiveCompleted(iconLabel: TextLabel, titleLabel: TextLabel, newText: string)
	iconLabel.Text = "[✓]"
	iconLabel.TextColor3 = Color3.fromRGB(45, 230, 95)
	titleLabel.Text = newText
	titleLabel.TextColor3 = Color3.fromRGB(160, 235, 185)

	-- Pulse highlight
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local t = TweenService:Create(titleLabel, tweenInfo, { TextColor3 = Color3.fromRGB(240, 255, 240) })
	t:Play()
	task.delay(0.35, function()
		TweenService:Create(titleLabel, tweenInfo, { TextColor3 = Color3.fromRGB(160, 235, 185) }):Play()
	end)
end

-- Display Sleek Slide-In Alert Toast
local ActiveToastThread: thread? = nil
local function ShowToast(message: string, alertType: "Success" | "Danger" | "Warning" | "Info")
	if ActiveToastThread then
		task.cancel(ActiveToastThread)
		ActiveToastThread = nil
	end

	local accentColor = Color3.fromRGB(0, 215, 60)
	local strokeColor = Color3.fromRGB(38, 52, 68)

	if alertType == "Success" then
		accentColor = Color3.fromRGB(45, 230, 95)
		strokeColor = Color3.fromRGB(30, 80, 50)
	elseif alertType == "Danger" then
		accentColor = Color3.fromRGB(255, 65, 75)
		strokeColor = Color3.fromRGB(90, 30, 35)
	elseif alertType == "Warning" then
		accentColor = Color3.fromRGB(245, 170, 45)
		strokeColor = Color3.fromRGB(85, 60, 25)
	elseif alertType == "Info" then
		accentColor = Color3.fromRGB(80, 190, 255)
		strokeColor = Color3.fromRGB(30, 65, 90)
	end

	ToastBanner.Visible = true
	ToastText.Text = message
	ToastAccent.BackgroundColor3 = accentColor
	ToastStroke.Color = strokeColor

	-- Start slightly above screen
	ToastBanner.Position = UDim2.new(0.5, 0, 0, -50)
	ToastBanner.BackgroundTransparency = 1
	ToastStroke.Transparency = 1
	ToastText.TextTransparency = 1

	local slideIn = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	TweenService:Create(ToastBanner, slideIn, {
		Position = UDim2.new(0.5, 0, 0, 24),
		BackgroundTransparency = 0.15
	}):Play()
	TweenService:Create(ToastStroke, slideIn, { Transparency = 0.1 }):Play()
	TweenService:Create(ToastText, slideIn, { TextTransparency = 0 }):Play()

	ActiveToastThread = task.delay(3.5, function()
		local slideOut = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local t1 = TweenService:Create(ToastBanner, slideOut, {
			Position = UDim2.new(0.5, 0, 0, -50),
			BackgroundTransparency = 1
		})
		local t2 = TweenService:Create(ToastStroke, slideOut, { Transparency = 1 })
		local t3 = TweenService:Create(ToastText, slideOut, { TextTransparency = 1 })
		t1:Play()
		t2:Play()
		t3:Play()
		t1.Completed:Wait()
		ToastBanner.Visible = false
		ActiveToastThread = nil
	end)
end

-- Refresh UI prompt content
local function UpdatePromptContent()
	if not FocusedTarget or not FocusedConfig then
		PromptCard.Visible = false
		return
	end

	ActionLabel.Text = FocusedConfig.ActionText
	ObjectTitleLabel.Text = FocusedConfig.ObjectTitle

	if FocusedConfig.InteractionType == "Hold" then
		HoldBarContainer.Visible = true
		ProgressRing.Visible = true
		if not IsHolding then
			HoldBarFill.Size = UDim2.new(0, 0, 1, 0)
			KeyBadge.Size = UDim2.new(0, 36, 0, 36)
		end
	else
		HoldBarContainer.Visible = false
		ProgressRing.Visible = false
		KeyBadge.Size = UDim2.new(0, 36, 0, 36)
	end

	if FocusedConfig.RequiredItem then
		StatusLabel.Visible = true
		local hasRequired = LocalInventory[FocusedConfig.RequiredItem] == true
		if hasRequired then
			StatusLabel.TextColor3 = Color3.fromRGB(45, 240, 140)
			StatusLabel.Text = "Level 1 Keycard Detected"
			ArrowIcon.ImageColor3 = Color3.fromRGB(45, 240, 140)
			RingStroke.Color = Color3.fromRGB(45, 240, 140)
		else
			StatusLabel.TextColor3 = Color3.fromRGB(255, 75, 85)
			StatusLabel.Text = "Requires Level 1 Keycard"
			ArrowIcon.ImageColor3 = Color3.fromRGB(255, 75, 85)
			RingStroke.Color = Color3.fromRGB(255, 75, 85)
		end
	else
		StatusLabel.Visible = false
		ArrowIcon.ImageColor3 = Color3.fromRGB(0, 215, 60)
		RingStroke.Color = Color3.fromRGB(0, 215, 60)
	end
end

-- Scan nearest interactable
local function ScanForInteractables()
	local root = InteractionUtil.getPlayerRoot(LocalPlayer)
	if not root then
		FocusedTarget = nil
		FocusedConfig = nil
		PromptCard.Visible = false
		return
	end

	local bestTarget: Instance? = nil
	local bestDist = math.huge
	local playerPos = root.Position

	local candidates = CollectionService:GetTagged(InteractionConfig.InteractableTag)
	for _, inst in ipairs(candidates) do
		local stateRaw = inst:GetAttribute("CurrentState")
		if stateRaw ~= "Collected" and stateRaw ~= "Open" and stateRaw ~= "Repaired" then
			local pivot = InteractionUtil.getInteractionPivot(inst)
			local dist = (playerPos - pivot).Magnitude
			local maxDist = inst:GetAttribute("MaxDistance") or InteractionConfig.MaxDistanceDefault
			if dist <= (maxDist :: number) and dist < bestDist then
				bestDist = dist
				bestTarget = inst
			end
		end
	end

	if bestTarget ~= FocusedTarget then
		if IsHolding and bestTarget ~= HoldTarget then
			IsHolding = false
			HoldTarget = nil
			HoldEvent:FireServer("Cancel", FocusedTarget)
		end
		FocusedTarget = bestTarget
		if FocusedTarget then
			FocusedConfig = InteractionUtil.getInteractableConfig(FocusedTarget)
		else
			FocusedConfig = nil
		end
		UpdatePromptContent()
	end
end

-- Render loop
RunService.RenderStepped:Connect(function(dt: number)
	ScanForInteractables()

	if FocusedTarget and FocusedConfig then
		local pivot = InteractionUtil.getInteractionPivot(FocusedTarget)
		local screenPos, onScreen = Camera:WorldToViewportPoint(pivot + Vector3.new(0, 1.4, 0))
		if onScreen and screenPos.Z > 0 then
			PromptCard.Visible = true
			local vpSize = Camera.ViewportSize
			local clampedX = math.clamp(screenPos.X, 120, vpSize.X - 120)
			local clampedY = math.clamp(screenPos.Y, 100, vpSize.Y - 100)
			PromptCard.Position = UDim2.fromOffset(clampedX, clampedY)
		else
			PromptCard.Visible = false
		end
	else
		PromptCard.Visible = false
	end

	-- Hold update
	if IsHolding and HoldTarget then
		local now = os.clock()
		local elapsed = now - HoldStartTime
		local progress = math.clamp(elapsed / HoldDuration, 0, 1)

		HoldBarFill.Size = UDim2.new(progress, 0, 1, 0)
		KeyBadge.Size = UDim2.new(0, math.floor(36 - 6 * progress), 0, math.floor(36 - 6 * progress))

		local pulseColor = Color3.fromRGB(0, 215, 60):Lerp(Color3.fromRGB(50, 255, 130), progress)
		HoldBarFill.BackgroundColor3 = pulseColor
		RingStroke.Color = pulseColor

		local withinRange = InteractionUtil.isPlayerWithinRange(LocalPlayer, HoldTarget)
		if not withinRange then
			IsHolding = false
			HoldEvent:FireServer("Cancel", HoldTarget)
			HoldTarget = nil
			ShowToast("REPAIR INTERRUPTED: OUT OF RANGE", "Warning")
			UpdatePromptContent()
			return
		end

		if progress >= 1.0 and not IsRequestInFlight then
			IsHolding = false
			IsRequestInFlight = true
			local targetToComplete = HoldTarget
			HoldTarget = nil

			task.spawn(function()
				local response: InteractionResponse = RequestFunction:InvokeServer("CompleteHold", targetToComplete)
				IsRequestInFlight = false

				if response.Success then
					PlayUiSound(InteractionConfig.SoundAccessGranted, 1.0)
					ShowToast(response.Message, "Success")
					SetObjectiveCompleted(GeneratorIcon, GeneratorTitle, "Auxiliary Generator [Online]")
				else
					PlayUiSound(InteractionConfig.SoundAccessDenied, 0.8)
					ShowToast(response.Message, "Danger")
				end
				UpdatePromptContent()
			end)
		end
	end
end)

-- Input listening for E key
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end
	if input.KeyCode ~= Enum.KeyCode.E then
		return
	end
	if not FocusedTarget or not FocusedConfig or IsRequestInFlight then
		return
	end

	if FocusedConfig.InteractionType == "Tap" then
		IsRequestInFlight = true
		PlayUiSound(InteractionConfig.SoundClick, 0.6)

		local targetToInteract = FocusedTarget
		task.spawn(function()
			local response: InteractionResponse = RequestFunction:InvokeServer("Interact", targetToInteract)
			IsRequestInFlight = false

			if response.Success then
				if response.ItemAcquired then
					LocalInventory[response.ItemAcquired] = true
					SetObjectiveCompleted(KeycardIcon, KeycardTitle, "Security Clearance [Retrieved]")
					PlayUiSound(InteractionConfig.SoundPickupItem, 1.0)
					ShowToast(response.Message, "Success")
				elseif response.State == "Open" then
					SetObjectiveCompleted(BulkheadIcon, BulkheadTitle, "Sector-04 Bulkhead [Breached]")
					ShowToast(response.Message, "Success")
				else
					ShowToast(response.Message, "Success")
				end
			else
				PlayUiSound(InteractionConfig.SoundAccessDenied, 0.9)
				ShowToast(response.Message, "Danger")
			end
			UpdatePromptContent()
		end)

	elseif FocusedConfig.InteractionType == "Hold" then
		if not IsHolding then
			IsHolding = true
			HoldStartTime = os.clock()
			HoldDuration = FocusedConfig.HoldDuration
			HoldTarget = FocusedTarget
			HoldEvent:FireServer("Start", FocusedTarget)
			PlayUiSound(InteractionConfig.SoundClick, 0.6)
		end
	end
end)

UserInputService.InputEnded:Connect(function(input: InputObject)
	if input.KeyCode == Enum.KeyCode.E and IsHolding then
		if HoldTarget then
			HoldEvent:FireServer("Cancel", HoldTarget)
		end
		IsHolding = false
		HoldTarget = nil
		HoldBarFill.Size = UDim2.new(0, 0, 1, 0)
		KeyBadge.Size = UDim2.new(0, 36, 0, 36)
	end
end)

-- Feedback listener from server
FeedbackEvent.OnClientEvent:Connect(function(eventData: any)
	if eventData.Type == "Notification" then
		local alertType: any = "Info"
		if eventData.Payload and eventData.Payload.Status == "Denied" then
			alertType = "Danger"
		elseif eventData.Payload and (eventData.Payload.Status == "Granted" or eventData.Payload.Status == "Repaired") then
			alertType = "Success"
		end
		ShowToast(eventData.Message or "NOTIFICATION", alertType)

		if eventData.Payload and eventData.Payload.Status == "Granted" then
			SetObjectiveCompleted(BulkheadIcon, BulkheadTitle, "Sector-04 Bulkhead [Breached]")
		elseif eventData.Payload and eventData.Payload.Status == "Repaired" then
			SetObjectiveCompleted(GeneratorIcon, GeneratorTitle, "Auxiliary Generator [Online]")
		end
	elseif eventData.Type == "InventoryUpdated" then
		if eventData.Payload and eventData.Payload.Item == "Keycard_Lvl1" then
			LocalInventory["Keycard_Lvl1"] = true
			SetObjectiveCompleted(KeycardIcon, KeycardTitle, "Security Clearance [Retrieved]")
		end
	end
	UpdatePromptContent()
end)

print("InteractionClient updated for sleek AAA HUD and FacilityTracker.")
