--!strict

local InteractionConfig = {}

-- General Network & Validation Thresholds
InteractionConfig.InteractableTag = "Interactable"
InteractionConfig.MaxDistanceDefault = 13.0
InteractionConfig.DistanceTolerance = 3.5
InteractionConfig.HoldLatencyTolerance = 0.35
InteractionConfig.DefaultHoldDuration = 3.0
InteractionConfig.DefaultCooldown = 0.4
InteractionConfig.RaycastValidationEnabled = true

-- Visual Theme Palettes (Cyberpunk / Clean Sci-Fi Lab)
InteractionConfig.ColorPrimary = Color3.fromRGB(0, 210, 255)
InteractionConfig.ColorSecondary = Color3.fromRGB(15, 25, 40)
InteractionConfig.ColorSuccess = Color3.fromRGB(45, 240, 140)
InteractionConfig.ColorWarning = Color3.fromRGB(255, 175, 40)
InteractionConfig.ColorDanger = Color3.fromRGB(255, 65, 75)
InteractionConfig.ColorTextLight = Color3.fromRGB(240, 245, 255)
InteractionConfig.ColorTextMuted = Color3.fromRGB(140, 160, 190)

-- Core Sound Asset IDs
InteractionConfig.SoundClick = "rbxassetid://6895079853"
InteractionConfig.SoundAccessDenied = "rbxassetid://9069609200"
InteractionConfig.SoundAccessGranted = "rbxassetid://9069609128"
InteractionConfig.SoundRepairProgress = "rbxassetid://9114223171"
InteractionConfig.SoundHydraulicOpen = "rbxassetid://9114223171"
InteractionConfig.SoundPickupItem = "rbxassetid://9069609128"

return table.freeze(InteractionConfig)
