--!strict
local RunService = game:GetService("RunService")
local Spring: any = if (script and script.Parent) then require(script.Parent:WaitForChild("Spring") :: ModuleScript) else (_G.Spring or require("./src/shared/Packages/Spring.luau"))

local CameraShake = {}
CameraShake.__index = CameraShake

local trauma = 0
local decay = 1.35
local isBound = false
local rng = Random.new()

local pitchSpring = Spring.new(0, 1, 65, 5, 1)
local yawSpring = Spring.new(0, 1, 65, 5, 1)
local rollSpring = Spring.new(0, 1, 75, 6, 1)
local xSpring = Spring.new(0, 1, 60, 5, 1)
local ySpring = Spring.new(0, 1, 60, 5, 1)

function CameraShake.AddTrauma(amount: number)
    trauma = math.clamp(trauma + amount, 0, 1)
    local mult = math.max(0.2, trauma)
    pitchSpring:Impulse((rng:NextNumber(-1, 1) * 35) * mult)
    yawSpring:Impulse((rng:NextNumber(-1, 1) * 35) * mult)
    rollSpring:Impulse((rng:NextNumber(-1, 1) * 45) * mult)
    xSpring:Impulse((rng:NextNumber(-1, 1) * 8) * mult)
    ySpring:Impulse((rng:NextNumber(-1, 1) * 8) * mult)
end

function CameraShake.GetTrauma(): number
    return trauma
end

function CameraShake.SetTrauma(val: number)
    trauma = math.clamp(val, 0, 1)
end

function CameraShake.CalculateOffset(dt: number): (Vector3, Vector3)
    if trauma <= 0.001 then
        trauma = 0
        return Vector3.zero, Vector3.zero
    end
    
    trauma = math.max(0, trauma - decay * dt)
    local shakeAmount = trauma * trauma
    
    local p = pitchSpring:Update(dt) * 0.001 * shakeAmount
    local y = yawSpring:Update(dt) * 0.001 * shakeAmount
    local r = rollSpring:Update(dt) * 0.001 * shakeAmount
    
    local ox = xSpring:Update(dt) * 0.01 * shakeAmount
    local oy = ySpring:Update(dt) * 0.01 * shakeAmount
    
    return Vector3.new(ox, oy, 0), Vector3.new(p, y, r)
end

function CameraShake.Init()
    if isBound then return end
    isBound = true
    
    RunService:BindToRenderStep("CombatCameraShake", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
        local offsetPos, offsetAngles = CameraShake.CalculateOffset(dt)
        local cam = workspace.CurrentCamera
        if cam and (offsetPos ~= Vector3.zero or offsetAngles ~= Vector3.zero) then
            local offsetCFrame = CFrame.new(offsetPos.X, offsetPos.Y, 0) * CFrame.Angles(offsetAngles.X, offsetAngles.Y, offsetAngles.Z)
            cam.CFrame = cam.CFrame * offsetCFrame
        end
    end)
end

return CameraShake
