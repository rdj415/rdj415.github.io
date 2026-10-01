--!strict
export type ComboStep = {
    Damage: number,
    Cooldown: number,
    Trauma: number,
    Hitstop: number,
    LungeSpeed: number,
    LungeDuration: number,
    Knockback: number,
    KnockbackUp: number?,
    SlashColor: Color3,
    Name: string,
    SoundPitch: number,
}

export type CombatConfigType = {
    MaxCombo: number,
    ComboResetDelay: number,
    AttackRange: number,
    AttackAngle: number,
    ComboData: { [number]: ComboStep },
    Sounds: { [string]: string },
}

local CombatConfig: CombatConfigType = {
    MaxCombo = 4,
    ComboResetDelay = 1.2,
    AttackRange = 8.5,
    AttackAngle = math.rad(115), -- 115-degree frontal arc
    
    ComboData = {
        [1] = {
            Damage = 15,
            Cooldown = 0.28,
            Trauma = 0.12,
            Hitstop = 0.05,
            LungeSpeed = 16,
            LungeDuration = 0.12,
            Knockback = 12,
            KnockbackUp = 8,
            SlashColor = Color3.fromRGB(0, 242, 254),
            Name = "Light Slash",
            SoundPitch = 1.0,
        },
        [2] = {
            Damage = 20,
            Cooldown = 0.32,
            Trauma = 0.18,
            Hitstop = 0.06,
            LungeSpeed = 20,
            LungeDuration = 0.12,
            Knockback = 18,
            KnockbackUp = 10,
            SlashColor = Color3.fromRGB(79, 172, 254),
            Name = "Cross Strike",
            SoundPitch = 1.1,
        },
        [3] = {
            Damage = 25,
            Cooldown = 0.38,
            Trauma = 0.26,
            Hitstop = 0.08,
            LungeSpeed = 24,
            LungeDuration = 0.15,
            Knockback = 28,
            KnockbackUp = 14,
            SlashColor = Color3.fromRGB(168, 85, 247),
            Name = "Spinning Uppercut",
            SoundPitch = 1.2,
        },
        [4] = {
            Damage = 55,
            Cooldown = 0.85,
            Trauma = 0.55,
            Hitstop = 0.14,
            LungeSpeed = 38,
            LungeDuration = 0.22,
            Knockback = 80,
            KnockbackUp = 35,
            SlashColor = Color3.fromRGB(244, 63, 94),
            Name = "HEAVY METEOR FINISHER",
            SoundPitch = 0.85,
        },
    },
    
    Sounds = {
        Whoosh1 = "rbxassetid://9114223170",
        Whoosh2 = "rbxassetid://9114223407",
        Whoosh3 = "rbxassetid://9114223630",
        WhooshHeavy = "rbxassetid://9114223845",
        HitLight = "rbxassetid://9114221580",
        HitMedium = "rbxassetid://9114221764",
        HitHeavy = "rbxassetid://9114222045",
        HitFinisher = "rbxassetid://9114222370",
        CritChime = "rbxassetid://9114220473",
    }
}

return CombatConfig
