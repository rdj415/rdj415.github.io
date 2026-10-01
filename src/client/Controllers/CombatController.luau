--!strict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local framework = ReplicatedStorage:WaitForChild("CombatFramework")
local combatEvent = framework:WaitForChild("CombatEvent") :: RemoteEvent
local combatVFXEvent = framework:WaitForChild("CombatVFXEvent") :: UnreliableRemoteEvent

local CombatConfig: any = if (script and script.Parent) then require(script.Parent.Parent.SharedModules:WaitForChild("CombatConfig") :: ModuleScript) else (_G.CombatConfig or require("./src/shared/SharedModules/CombatConfig.luau"))
local CameraShake: any = if (script and script.Parent) then require(script.Parent.Parent.Packages:WaitForChild("CameraShake") :: ModuleScript) else (_G.CameraShake or require("./src/shared/Packages/CameraShake.luau"))
local CombatVFX: any = if (script and script.Parent) then require(script.Parent.Parent.Packages:WaitForChild("CombatVFX") :: ModuleScript) else (_G.CombatVFX or require("./src/shared/Packages/CombatVFX.luau"))
local Scythe: any = if (script and script.Parent) then require(script.Parent.Parent.Packages:WaitForChild("Scythe") :: ModuleScript) else (_G.Scythe or require("./src/shared/Packages/Scythe.luau"))

local CombatController = {}
local _controllerScope: any = nil

local comboIndex = 1
local lastAttackTime = 0
local lastComboTime = 0

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
    
    local now = os.clock()
    if now - lastComboTime > CombatConfig.ComboResetDelay then
        comboIndex = 1
    end
    
    local comboData = CombatConfig.ComboData[comboIndex]
    if now - lastAttackTime < comboData.Cooldown then
        return
    end
    
    lastAttackTime = now
    lastComboTime = now
    
    local currentHit = comboIndex
    local isFinisher = (currentHit == CombatConfig.MaxCombo)
    
    CombatVFX.SpawnSlashArc(hrp.CFrame, comboData.SlashColor, currentHit)
    
    local whooshId = isFinisher and CombatConfig.Sounds.WhooshHeavy or CombatConfig.Sounds.Whoosh1
    CombatVFX.PlaySound(whooshId, hrp, comboData.SoundPitch, 0.9)
    
    local forward = hrp.CFrame.LookVector
    hrp.AssemblyLinearVelocity = Vector3.new(forward.X * comboData.LungeSpeed, hrp.AssemblyLinearVelocity.Y, forward.Z * comboData.LungeSpeed)
    
    CameraShake.AddTrauma(comboData.Trauma * 0.3)
    
    combatEvent:FireServer({
        action = "Attack",
        comboIndex = currentHit,
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
    
    local vfxConn = combatVFXEvent.OnClientEvent:Connect(function(data: any)
        if type(data) ~= "table" then return end
        local hitPos = data.hitPosition or Vector3.zero
        local hitCombo = data.comboIndex or 1
        local isFinisher = data.isFinisher or false
        local comboData = CombatConfig.ComboData[hitCombo] or CombatConfig.ComboData[1]
        local damage = data.damage or comboData.Damage
        
        CameraShake.AddTrauma(comboData.Trauma)
        CombatVFX.SpawnHitSparks(hitPos, comboData.SlashColor, isFinisher)
        CombatVFX.SpawnDamageNumber(hitPos, damage, isFinisher)
        
        local impactSound = isFinisher and CombatConfig.Sounds.HitFinisher or (hitCombo >= 3 and CombatConfig.Sounds.HitHeavy or CombatConfig.Sounds.HitMedium)
        CombatVFX.PlaySound(impactSound, nil, comboData.SoundPitch, 1.0)
        
        if isFinisher then
            CombatVFX.SpawnShockwave(hitPos - Vector3.new(0, 1.5, 0), comboData.SlashColor)
            CombatVFX.PlaySound(CombatConfig.Sounds.CritChime, nil, 1.1, 0.8)
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
        end
    end)
    Scythe.add(_controllerScope, inputConn)
    
    print("[CombatController] Initialized successfully with 4-Hit combo and Hitstop.")
end

function CombatController.Start()
    print("[CombatController] Started.")
end

function CombatController.Destroy()
    if Scythe and _controllerScope and Scythe.isAlive(_controllerScope) then
        Scythe.scope(_controllerScope)
    end
    print("[CombatController] Destroyed cleanly via Scythe.")
end

return CombatController
