--!strict
export type Spring = {
    Mass: number,
    Force: number,
    Damping: number,
    Speed: number,
    Position: number,
    Velocity: number,
    Target: number,
    Update: (self: Spring, dt: number) -> number,
    Impulse: (self: Spring, velocity: number) -> (),
    Reset: (self: Spring) -> (),
}

local Spring = {}
Spring.__index = Spring

function Spring.new(initial: number?, mass: number?, force: number?, damping: number?, speed: number?): Spring
    local self = setmetatable({
        Mass = mass or 1,
        Force = force or 50,
        Damping = damping or 4,
        Speed = speed or 1,
        Position = initial or 0,
        Velocity = 0,
        Target = initial or 0,
    }, Spring)
    return (self :: any) :: Spring
end

function Spring:Update(dt: number): number
    local d = self.Damping
    local m = self.Mass
    local k = self.Force
    local s = self.Speed
    
    local scaledDt = dt * s
    local force = -k * (self.Position - self.Target) - d * self.Velocity
    local accel = force / m
    
    self.Velocity += accel * scaledDt
    self.Position += self.Velocity * scaledDt
    
    return self.Position
end

function Spring:Impulse(velocity: number)
    self.Velocity += velocity
end

function Spring:Reset()
    self.Position = self.Target
    self.Velocity = 0
end

return Spring
