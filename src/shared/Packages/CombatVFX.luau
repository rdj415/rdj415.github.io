--!strict
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local CombatVFX = {}
local rng = Random.new()

function CombatVFX.PlaySound(soundId: string, parent: Instance?, pitch: number?, volume: number?)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 0.85
    sound.PlaybackSpeed = pitch or 1.0
    sound.RollOffMaxDistance = 100
    sound.RollOffMinDistance = 10
    sound.Parent = parent or SoundService
    sound:Play()
    Debris:AddItem(sound, 3)
end

function CombatVFX.SpawnSlashArc(cframe: CFrame, color: Color3, comboIndex: number)
    local isFinisher = (comboIndex == 4)
    local slash = Instance.new("Part")
    slash.Name = "SlashArc"
    slash.Shape = Enum.PartType.Cylinder
    slash.Size = isFinisher and Vector3.new(0.3, 10, 10) or Vector3.new(0.2, 6.5, 6.5)
    
    local slantAngle = (comboIndex % 2 == 1) and math.rad(25) or math.rad(-25)
    slash.CFrame = cframe * CFrame.new(0, 0, -3.2) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(slantAngle, 0, 0)
    slash.Anchored = true
    slash.CanCollide = false
    slash.Material = Enum.Material.Neon
    slash.Color = color
    slash.Transparency = 0.15
    slash.Parent = workspace
    
    local targetSize = isFinisher and Vector3.new(0.1, 18, 18) or Vector3.new(0.1, 11, 11)
    
    local tween = TweenService:Create(slash, TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = targetSize,
        Transparency = 1,
        CFrame = slash.CFrame * CFrame.new(0, 0, -1.8)
    })
    tween:Play()
    tween.Completed:Connect(function()
        slash:Destroy()
    end)
    Debris:AddItem(slash, 0.5)
end

function CombatVFX.SpawnHitSparks(position: Vector3, color: Color3, isFinisher: boolean)
    local terrain = workspace:FindFirstChildOfClass("Terrain") or workspace
    local attach = Instance.new("Attachment")
    attach.WorldPosition = position
    attach.Parent = terrain
    
    local emitter = Instance.new("ParticleEmitter")
    emitter.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.3, color),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 30))
    })
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.45),
        NumberSequenceKeypoint.new(1, 0)
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    emitter.Speed = NumberRange.new(isFinisher and 28 or 14, isFinisher and 45 or 24)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Lifetime = NumberRange.new(0.25, 0.45)
    emitter.LightEmission = 1
    emitter.Rate = 0
    emitter.Parent = attach
    
    emitter:Emit(isFinisher and 40 or 18)
    
    local flash = Instance.new("Part")
    flash.Shape = Enum.PartType.Ball
    flash.Size = isFinisher and Vector3.new(5, 5, 5) or Vector3.new(2.5, 2.5, 2.5)
    flash.Position = position
    flash.Anchored = true
    flash.CanCollide = false
    flash.Material = Enum.Material.Neon
    flash.Color = isFinisher and Color3.fromRGB(255, 255, 255) or color
    flash.Transparency = 0.2
    flash.Parent = workspace
    
    TweenService:Create(flash, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = flash.Size * 1.8,
        Transparency = 1
    }):Play()
    Debris:AddItem(flash, 0.2)
    Debris:AddItem(attach, 0.8)
end

function CombatVFX.SpawnShockwave(position: Vector3, color: Color3)
    local ring = Instance.new("Part")
    ring.Name = "ShockwaveRing"
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.3, 2, 2)
    ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
    ring.Anchored = true
    ring.CanCollide = false
    ring.Material = Enum.Material.Neon
    ring.Color = color
    ring.Transparency = 0.1
    ring.Parent = workspace
    
    local tween = TweenService:Create(ring, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = Vector3.new(0.1, 26, 26),
        Transparency = 1
    })
    tween:Play()
    tween.Completed:Connect(function()
        ring:Destroy()
    end)
    Debris:AddItem(ring, 0.6)
end

function CombatVFX.SpawnDamageNumber(position: Vector3, damage: number, isFinisher: boolean)
    local part = Instance.new("Part")
    part.Size = Vector3.new(0.1, 0.1, 0.1)
    part.Position = position + Vector3.new(rng:NextNumber(-0.8, 0.8), rng:NextNumber(0.2, 0.8), rng:NextNumber(-0.8, 0.8))
    part.Transparency = 1
    part.Anchored = true
    part.CanCollide = false
    part.Parent = workspace
    
    local bbg = Instance.new("BillboardGui")
    bbg.Size = UDim2.new(4, 0, 1.5, 0)
    bbg.AlwaysOnTop = true
    bbg.Parent = part
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.GothamBlack
    text.Text = isFinisher and ("CRIT " .. tostring(math.floor(damage)) .. "!") or tostring(math.floor(damage))
    text.TextColor3 = isFinisher and Color3.fromRGB(244, 63, 94) or Color3.fromRGB(255, 255, 255)
    text.TextSize = isFinisher and 32 or 22
    text.Parent = bbg
    
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2.5
    stroke.Color = Color3.fromRGB(15, 23, 42)
    stroke.Parent = text
    
    local endPos = part.Position + Vector3.new(rng:NextNumber(-1, 1), 3.2, rng:NextNumber(-1, 1))
    TweenService:Create(part, TweenInfo.new(0.65, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
        Position = endPos
    }):Play()
    
    task.delay(0.35, function()
        TweenService:Create(text, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            TextTransparency = 1,
            TextSize = text.TextSize * 0.7
        }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Transparency = 1
        }):Play()
    end)
    
    Debris:AddItem(part, 0.75)
end

function CombatVFX.Hitstop(duration: number, attackerChar: Model?, targetChar: Model?)
    local attackerTracks = {}
    if attackerChar then
        local hum = attackerChar:FindFirstChildOfClass("Humanoid")
        if hum then
            local animator = hum:FindFirstChildOfClass("Animator")
            if animator then
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    track:AdjustSpeed(0)
                    table.insert(attackerTracks, track)
                end
            end
        end
    end
    
    local cam = workspace.CurrentCamera
    local originalFov = 70
    if cam then
        originalFov = cam.FieldOfView
        cam.FieldOfView = math.max(55, originalFov - 3.5)
    end
    
    task.delay(duration, function()
        for _, track in ipairs(attackerTracks) do
            track:AdjustSpeed(1)
        end
        if cam then
            TweenService:Create(cam, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                FieldOfView = originalFov
            }):Play()
        end
    end)
end

return CombatVFX
