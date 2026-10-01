--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local framework = ReplicatedStorage:WaitForChild("CombatFramework")
local combatEvent = framework:WaitForChild("CombatEvent") :: RemoteEvent
local combatVFXEvent = framework:WaitForChild("CombatVFXEvent") :: UnreliableRemoteEvent

local CombatConfig: any = if (script and script.Parent) then require(script.Parent.Parent.SharedModules:WaitForChild("CombatConfig") :: ModuleScript) else (_G.CombatConfig or require("./src/shared/SharedModules/CombatConfig.luau"))
local Scythe: any = if (script and script.Parent) then require(script.Parent.Parent.Packages:WaitForChild("Scythe") :: ModuleScript) else (_G.Scythe or require("./src/shared/Packages/Scythe.luau"))

local CombatService = {}
local _serviceScope: any = nil

type PlayerState = {
    LastAttackTime: number,
    CurrentCombo: number,
}
local playerStates: { [Player]: PlayerState } = {}

function CombatService.GetPlayerState(player: Player): PlayerState
    local state = playerStates[player]
    if not state then
        state = {
            LastAttackTime = 0,
            CurrentCombo = 1,
        }
        playerStates[player] = state
    end
    return state
end

function CombatService.FindTargetsInFront(attackerChar: Model, maxRange: number, maxAngleRad: number): { { Model: Model, HitPoint: Vector3 } }
    local attackerHrp = attackerChar:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not attackerHrp then return {} end
    
    local results = {}
    local attackerPos = attackerHrp.Position
    local lookVector = attackerHrp.CFrame.LookVector
    local halfAngleCos = math.cos(maxAngleRad / 2)
    
    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc:IsA("Humanoid") and desc.Health > 0 then
            local targetModel = desc.Parent :: Model?
            if targetModel and targetModel ~= attackerChar and targetModel:IsA("Model") then
                local targetHrp = targetModel:FindFirstChild("HumanoidRootPart") :: BasePart?
                if targetHrp then
                    local toTarget = targetHrp.Position - attackerPos
                    local dist = toTarget.Magnitude
                    
                    if dist <= maxRange then
                        local dir = toTarget.Unit
                        local dot = lookVector:Dot(dir)
                        if dot >= halfAngleCos or dist <= 3.2 then
                            local hitPoint = attackerPos + (toTarget * 0.7) + Vector3.new(0, 1.2, 0)
                            table.insert(results, { Model = targetModel, HitPoint = hitPoint })
                        end
                    end
                end
            end
        end
    end
    
    return results
end

function CombatService.ProcessAttack(player: Player, comboIndex: number): { TargetsHit: number, IsFinisher: boolean }
    local char = player.Character
    if not char then return { TargetsHit = 0, IsFinisher = false } end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hum or hum.Health <= 0 or not hrp then return { TargetsHit = 0, IsFinisher = false } end
    
    local state = CombatService.GetPlayerState(player)
    local now = os.clock()
    
    local clampedIndex = math.clamp(comboIndex, 1, CombatConfig.MaxCombo)
    local comboData = CombatConfig.ComboData[clampedIndex]
    
    if now - state.LastAttackTime < (comboData.Cooldown * 0.85) then
        return { TargetsHit = 0, IsFinisher = (clampedIndex == CombatConfig.MaxCombo) }
    end
    state.LastAttackTime = now
    state.CurrentCombo = (clampedIndex % CombatConfig.MaxCombo) + 1
    
    local lookVec = hrp.CFrame.LookVector
    if comboData.LungeSpeed and comboData.LungeSpeed > 0 then
        hrp.AssemblyLinearVelocity = Vector3.new(lookVec.X * comboData.LungeSpeed, hrp.AssemblyLinearVelocity.Y, lookVec.Z * comboData.LungeSpeed)
    end
    
    local targets = CombatService.FindTargetsInFront(char, CombatConfig.AttackRange, CombatConfig.AttackAngle)
    local isFinisher = (clampedIndex == CombatConfig.MaxCombo)
    local hitCount = 0
    
    for _, hit in ipairs(targets) do
        local targetModel = hit.Model
        local targetHum = targetModel:FindFirstChildOfClass("Humanoid")
        local targetHrp = targetModel:FindFirstChild("HumanoidRootPart") :: BasePart?
        
        if targetHum and targetHum.Health > 0 and targetHrp then
            hitCount += 1
            targetHum:TakeDamage(comboData.Damage)
            
            local knockVec: Vector3
            if isFinisher then
                knockVec = (lookVec * comboData.Knockback) + Vector3.new(0, comboData.KnockbackUp or 35, 0)
            else
                knockVec = (lookVec * comboData.Knockback) + Vector3.new(0, 12, 0)
            end
            targetHrp.AssemblyLinearVelocity = knockVec
            
            combatVFXEvent:FireAllClients({
                attacker = player,
                target = targetModel,
                hitPosition = hit.HitPoint,
                comboIndex = clampedIndex,
                damage = comboData.Damage,
                isFinisher = isFinisher,
                lookVector = lookVec,
            })
        end
    end
    
    return { TargetsHit = hitCount, IsFinisher = isFinisher }
end

function CombatService.Init()
    _serviceScope = Scythe.scope()
    local conn = combatEvent.OnServerEvent:Connect(function(player: Player, data: any)
        if type(data) ~= "table" then return end
        if data.action ~= "Attack" then return end
        local idx = tonumber(data.comboIndex) or 1
        CombatService.ProcessAttack(player, idx)
    end)
    Scythe.add(_serviceScope, conn)
    
    local pLeave = Players.PlayerRemoving:Connect(function(p)
        playerStates[p] = nil
    end)
    Scythe.add(_serviceScope, pLeave)
    
    print("[CombatService] Initialized with Scythe memory management.")
end

function CombatService.Start()
    print("[CombatService] Started. Authoritative combo pipeline ready.")
end

function CombatService.Destroy()
    if Scythe and _serviceScope and Scythe.isAlive(_serviceScope) then
        Scythe.scope(_serviceScope)
    end
    table.clear(playerStates)
    print("[CombatService] Destroyed cleanly via Scythe.")
end

return CombatService
