--!strict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local framework = ReplicatedStorage:WaitForChild("CombatFramework")
local combatEvent = framework:WaitForChild("CombatEvent") :: RemoteEvent
local combatVFXEvent = framework:WaitForChild("CombatVFXEvent") :: UnreliableRemoteEvent
local animFolder = framework:FindFirstChild("Animations")

local CombatConfig: any = if (script and script.Parent) then require(script.Parent.Parent.SharedModules:WaitForChild("CombatConfig") :: ModuleScript) else (_G.CombatConfig or require("./src/shared/SharedModules/CombatConfig.luau"))
local CameraShake: any = if (script and script.Parent) then require(script.Parent.Parent.Packages:WaitForChild("CameraShake") :: ModuleScript) else (_G.CameraShake or require("./src/shared/Packages/CameraShake.luau"))
local CombatVFX: any = if (script and script.Parent) then require(script.Parent.Parent.Packages:WaitForChild("CombatVFX") :: ModuleScript) else (_G.CombatVFX or require("./src/shared/Packages/CombatVFX.luau"))
local Scythe: any = if (script and script.Parent) then require(script.Parent.Parent.Packages:WaitForChild("Scythe") :: ModuleScript) else (_G.Scythe or require("./src/shared/Packages/Scythe.luau"))

local CombatController = {}
local _controllerScope: any = nil

local comboIndex = 1
local lastAttackTime = 0
local lastComboTime = 0

local loadedTracks: { [number]: AnimationTrack } = {}

function CombatController.SetupAnimationsForCharacter(char: Model)
    table.clear(loadedTracks)
    if not animFolder then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end
    
    local animMap = {
        [1] = animFolder:FindFirstChild("Swing"),
        [2] = animFolder:FindFirstChild("Swing 2"),
        [3] = animFolder:FindFirstChild("Swing 3"),
        [4] = animFolder:FindFirstChild("Swing 3"),
    }
    
    for idx, kfs in pairs(animMap) do
        if kfs and kfs:IsA("KeyframeSequence") then
            local success, id = pcall(function()
                return KeyframeSequenceProvider:RegisterKeyframeSequence(kfs)
            end)
            if success and id then
                local anim = Instance.new("Animation")
                anim.AnimationId = id
                local track = animator:LoadAnimation(anim)
                track.Priority = Enum.AnimationPriority.Action
                loadedTracks[idx] = track
            end
        end
    end
end

local VALID_ARM_NAMES = {
    ["Left Arm"] = true,
    ["Right Arm"] = true,
    ["LeftUpperArm"] = true,
    ["LeftLowerArm"] = true,
    ["LeftHand"] = true,
    ["RightUpperArm"] = true,
    ["RightLowerArm"] = true,
    ["RightHand"] = true,
}

function CombatController.UpdateFirstPersonArms()
    local player = Players.LocalPlayer
    if not player then return end
    local char = player.Character
    if not char then return end
    local head = char:FindFirstChild("Head") :: BasePart?
    local cam = workspace.CurrentCamera
    if not head or not cam then return end
    
    local distToHead = (cam.CFrame.Position - head.Position).Magnitude
    local distToFocus = (cam.Focus.Position - cam.CFrame.Position).Magnitude
    local isFirstPerson = (distToHead < 2.5) or (distToFocus < 1.5) or (player.CameraMode == Enum.CameraMode.LockFirstPerson)
    
    if isFirstPerson then
        -- HIDE EVERYTHING (Head, Torso, Legs, Hair, Glasses, Hats, Accessories, Pets)
        -- SHOW ONLY THE ARMS
        for _, desc in ipairs(char:GetDescendants()) do
            if desc:IsA("BasePart") then
                if VALID_ARM_NAMES[desc.Name] then
                    desc.LocalTransparencyModifier = 0
                else
                    desc.LocalTransparencyModifier = 1
                end
            end
        end
        
        -- Procedural pitch tracking: arms follow camera pitch (aiming up/down)
        local torso = char:FindFirstChild("Torso") :: BasePart?
        if torso then
            local rightShoulder = torso:FindFirstChild("Right Shoulder") :: Motor6D?
            local leftShoulder = torso:FindFirstChild("Left Shoulder") :: Motor6D?
            local lookPitch = math.clamp(math.asin(cam.CFrame.LookVector.Y), -math.rad(65), math.rad(65))
            
            local idleOffset = CFrame.Angles(math.rad(15), 0, 0)
            
            if rightShoulder then
                rightShoulder.Transform = rightShoulder.Transform * CFrame.Angles(0, 0, lookPitch) * idleOffset
            end
            if leftShoulder then
                leftShoulder.Transform = leftShoulder.Transform * CFrame.Angles(0, 0, -lookPitch) * idleOffset
            end
        end
    else
        -- When in 3rd person, restore normal avatar parts and accessories
        for _, desc in ipairs(char:GetDescendants()) do
            if desc:IsA("BasePart") then
                desc.LocalTransparencyModifier = 0
            end
        end
    end
end

local styleOrder = CombatConfig.StyleOrder or { "Brawler", "MartialArts", "Titan" }
local currentStyleIndex = 1

function CombatController.GetCurrentStyle()
    local key = styleOrder[currentStyleIndex] or "Brawler"
    return (CombatConfig.Styles and CombatConfig.Styles[key]) or CombatConfig.Styles.Brawler
end

function CombatController.CycleStyle(): string
    currentStyleIndex = (currentStyleIndex % #styleOrder) + 1
    comboIndex = 1
    return CombatController.GetCurrentStyle().Id
end

function CombatController.SetStyle(styleId: string)
    for idx, name in ipairs(styleOrder) do
        if name == styleId then
            currentStyleIndex = idx
            comboIndex = 1
            break
        end
    end
end

function CombatController.GetComboIndex(): number
    return comboIndex
end

function CombatController.ResetCombo()
    comboIndex = 1
end

function CombatController.PerformAttack(customPlayer: Player?)
    local player = customPlayer or Players.LocalPlayer
    if not player then return end
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hum or hum.Health <= 0 or not hrp then return end
    
    local style = CombatController.GetCurrentStyle()
    local maxCombo = style and style.MaxCombo or CombatConfig.MaxCombo
    local comboSteps = style and style.ComboData or CombatConfig.ComboData
    
    local now = os.clock()
    local resetDelay = style and style.ComboResetDelay or CombatConfig.ComboResetDelay
    if now - lastComboTime > resetDelay then
        comboIndex = 1
    end
    
    local currentHit = comboIndex
    local comboData = comboSteps[currentHit] or comboSteps[1]
    if now - lastAttackTime < comboData.Cooldown then
        return
    end
    
    lastAttackTime = now
    lastComboTime = now
    
    local isFinisher = (currentHit == maxCombo)
    
    local track = loadedTracks[currentHit]
    if track then
        track:Stop(0.05)
        local speed = isFinisher and 1.35 or 1.15
        track:Play(0.05, 1, speed)
    end
    
    CombatVFX.SpawnSlashArc(hrp.CFrame, comboData.SlashColor, currentHit)
    
    local whooshId = isFinisher and CombatConfig.Sounds.WhooshHeavy or CombatConfig.Sounds.Whoosh1
    CombatVFX.PlaySound(whooshId, hrp, comboData.SoundPitch, 0.9)
    
    local forward = hrp.CFrame.LookVector
    hrp.AssemblyLinearVelocity = Vector3.new(forward.X * comboData.LungeSpeed, hrp.AssemblyLinearVelocity.Y, forward.Z * comboData.LungeSpeed)
    
    CameraShake.AddTrauma(comboData.Trauma * 0.25)
    
    combatEvent:FireServer({
        action = "Attack",
        comboIndex = currentHit,
        moveId = "Punch",
    })
    
    if isFinisher then
        comboIndex = 1
    else
        comboIndex += 1
    end
end

function CombatController.Init()
    _controllerScope = Scythe.scope()
    CameraShake.Init()
    
    local player = Players.LocalPlayer
    if player and player.Character then
        task.spawn(CombatController.SetupAnimationsForCharacter, player.Character)
    end
    if player then
        local charConn = player.CharacterAdded:Connect(CombatController.SetupAnimationsForCharacter)
        Scythe.add(_controllerScope, charConn)
    end
    
    -- Bind first-person arms updater after camera
    RunService:BindToRenderStep("FirstPersonArmsVisibility", Enum.RenderPriority.Camera.Value + 2, CombatController.UpdateFirstPersonArms)
    Scythe.add(_controllerScope, function()
        RunService:UnbindFromRenderStep("FirstPersonArmsVisibility")
    end)
    
    local vfxConn = combatVFXEvent.OnClientEvent:Connect(function(data: any)
        if type(data) ~= "table" then return end
        local hitPos = data.hitPosition or Vector3.zero
        local hitCombo = data.comboIndex or 1
        local isFinisher = data.isFinisher or false
        local comboData = CombatConfig.ComboData[hitCombo] or CombatConfig.ComboData[1]
        local damage = data.damage or comboData.Damage
        
        local slashColor = data.slashColor or comboData.SlashColor
        
        CameraShake.AddTrauma(comboData.Trauma)
        CombatVFX.SpawnHitSparks(hitPos, slashColor, isFinisher)
        CombatVFX.SpawnFlyingComboInfo(hitPos, hitCombo, damage, isFinisher, slashColor)
        
        local impactSound = isFinisher and CombatConfig.Sounds.HitFinisher or (hitCombo >= 3 and CombatConfig.Sounds.HitHeavy or CombatConfig.Sounds.HitMedium)
        CombatVFX.PlaySound(impactSound, nil, comboData.SoundPitch, 1.0)
        
        if isFinisher then
            CombatVFX.SpawnShockwave(hitPos - Vector3.new(0, 1.0, 0), slashColor)
            CombatVFX.PlaySound(CombatConfig.Sounds.CritChime, nil, 1.1, 0.85)
        end
        
        local localPlayer = Players.LocalPlayer
        if localPlayer and data.attacker == localPlayer then
            CombatVFX.Hitstop(comboData.Hitstop, localPlayer.Character, data.target)
        end
    end)
    Scythe.add(_controllerScope, vfxConn)
    
    local inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.ButtonR2 then
            CombatController.PerformAttack()
        elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.V or input.KeyCode == Enum.KeyCode.ButtonY then
            CombatController.CycleStyle()
        end
    end)
    Scythe.add(_controllerScope, inputConn)
    
    print("[CombatController] Initialized: Multi-Styles, Elegant Dot Crosshair, 1st Person Arms.")
end

function CombatController.Start()
    print("[CombatController] Started.")
end

function CombatController.Destroy()
    if Scythe and _controllerScope and Scythe.isAlive(_controllerScope) then
        Scythe.scope(_controllerScope)
    end
    table.clear(loadedTracks)
    print("[CombatController] Destroyed cleanly via Scythe.")
end

return CombatController
