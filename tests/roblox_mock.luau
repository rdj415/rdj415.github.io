--!strict
-- Minimal, robust Roblox environment mock for Lune test harness

local mock = {}

-- Signals
local Signal = {}
Signal.__index = Signal
function Signal.new()
	return setmetatable({ _listeners = {} }, Signal)
end
function Signal:Connect(fn: (...any) -> ())
	local conn = {
		Connected = true,
		Disconnect = function(self) end,
	}
	table.insert(self._listeners, fn)
	conn.Disconnect = function(c)
		c.Connected = false
		for i, listener in ipairs(self._listeners) do
			if listener == fn then
				table.remove(self._listeners, i)
				break
			end
		end
	end
	return conn
end
function Signal:Fire(...: any)
	for _, fn in ipairs(table.clone(self._listeners)) do
		fn(...)
	end
end

-- Mathematics declarations
local Vector3 = {}
local Vector3_meta = {
	__add = function(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end,
	__sub = function(a, b) return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end,
	__mul = function(a, b)
		if type(a) == "number" then return Vector3.new(a * b.X, a * b.Y, a * b.Z) end
		if type(b) == "number" then return Vector3.new(a.X * b, a.Y * b, a.Z * b) end
		return Vector3.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
	end,
	__div = function(a, b)
		if type(b) == "number" then return Vector3.new(a.X / b, a.Y / b, a.Z / b) end
		return Vector3.new(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
	end,
	__unm = function(a) return Vector3.new(-a.X, -a.Y, -a.Z) end,
	__tostring = function(a) return string.format("Vector3(%f, %f, %f)", a.X, a.Y, a.Z) end,
}
function Vector3.new(x: number?, y: number?, z: number?)
	local vx = x or 0
	local vy = y or 0
	local vz = z or 0
	local mag = math.sqrt(vx*vx + vy*vy + vz*vz)
	local v = {
		X = vx,
		Y = vy,
		Z = vz,
		Magnitude = mag,
		Unit = if mag > 0 then setmetatable({ X = vx/mag, Y = vy/mag, Z = vz/mag, Magnitude = 1, Unit = nil }, Vector3_meta) else nil,
		Dot = function(self, other) return self.X * other.X + self.Y * other.Y + self.Z * other.Z end,
		Lerp = function(self, target, alpha) return self + (target - self) * alpha end,
	}
	if v.Unit then v.Unit.Unit = v.Unit end
	return setmetatable(v, Vector3_meta)
end
Vector3.zero = Vector3.new(0, 0, 0)
_G.Vector3 = Vector3

local Vector2 = {}
local Vector2_meta = {
	__add = function(a, b) return Vector2.new(a.X + b.X, a.Y + b.Y) end,
	__sub = function(a, b) return Vector2.new(a.X - b.X, a.Y - b.Y) end,
	__mul = function(a, b)
		if type(a) == "number" then return Vector2.new(a * b.X, a * b.Y) end
		return Vector2.new(a.X * b, a.Y * b)
	end,
	__tostring = function(a) return string.format("Vector2(%f, %f)", a.X, a.Y) end,
}
function Vector2.new(x: number?, y: number?)
	local vx = x or 0
	local vy = y or 0
	local mag = math.sqrt(vx*vx + vy*vy)
	local v = {
		X = vx,
		Y = vy,
		Magnitude = mag,
		Unit = if mag > 0 then setmetatable({ X = vx/mag, Y = vy/mag, Magnitude = 1, Unit = nil }, Vector2_meta) else nil,
	}
	if v.Unit then v.Unit.Unit = v.Unit end
	return setmetatable(v, Vector2_meta)
end
Vector2.zero = Vector2.new(0, 0)
_G.Vector2 = Vector2

local CFrame = {}
local CFrame_meta = {
	__mul = function(a, b)
		if type(b) == "table" and b.Position then
			return CFrame.new(a.Position + b.Position)
		end
		return a
	end,
	__tostring = function(a) return string.format("CFrame(Position=%s)", tostring(a.Position)) end,
}
function CFrame.new(x: any?, y: number?, z: number?)
	local pos: any
	if typeof(x) == "table" and x.X then
		pos = x
	else
		pos = Vector3.new(x or 0, y or 0, z or 0)
	end
	return setmetatable({
		Position = pos,
		LookVector = Vector3.new(0, 0, -1),
		VectorToObjectSpace = function(self, v) return v end,
	}, CFrame_meta)
end
function CFrame.Angles(x: number, y: number, z: number)
	return CFrame.new(0, 0, 0)
end
_G.CFrame = CFrame

-- Raycasting types
_G.RaycastFilterType = {
	Include = "Include",
	Exclude = "Exclude",
}
_G.Enum = {
	RaycastFilterType = _G.RaycastFilterType
}
_G.RaycastParams = {
	new = function()
		return {
			FilterType = _G.RaycastFilterType.Exclude,
			FilterDescendantsInstances = {},
			IgnoreWater = true,
		}
	end,
}

-- Instance Class Mock
local InstanceMethods = {}
local InstanceMeta = {
	__index = function(self, key)
		if key == "Parent" then
			return rawget(self, "_parent")
		end
		return InstanceMethods[key] or rawget(self, key)
	end,
	__newindex = function(self, key, value)
		if key == "Parent" then
			local oldParent = rawget(self, "_parent")
			if oldParent == value then return end

			if oldParent and oldParent._children then
				for i, c in ipairs(oldParent._children) do
					if c == self then
						table.remove(oldParent._children, i)
						break
					end
				end
				if oldParent.ChildRemoved then
					oldParent.ChildRemoved:Fire(self)
				end
			end

			rawset(self, "_parent", value)

			if value and value._children then
				table.insert(value._children, self)
				if value.ChildAdded then
					value.ChildAdded:Fire(self)
				end
			end

			if self.AncestryChanged then
				self.AncestryChanged:Fire(self, value)
			end
			return
		end
		rawset(self, key, value)
	end,
}

function InstanceMethods:FindFirstChild(name: string, recursive: boolean?)
	for _, child in ipairs(rawget(self, "_children") or {}) do
		if child.Name == name then return child end
		if recursive then
			local found = child:FindFirstChild(name, true)
			if found then return found end
		end
	end
	return nil
end

function InstanceMethods:FindFirstChildOfClass(className: string)
	for _, child in ipairs(rawget(self, "_children") or {}) do
		if child.ClassName == className then return child end
	end
	return nil
end

function InstanceMethods:FindFirstChildWhichIsA(className: string, recursive: boolean?)
	for _, child in ipairs(rawget(self, "_children") or {}) do
		if child.ClassName == className or child:IsA(className) then return child end
		if recursive then
			local found = child:FindFirstChildWhichIsA(className, true)
			if found then return found end
		end
	end
	return nil
end

function InstanceMethods:FindFirstAncestorOfClass(className: string)
	local curr = self.Parent
	while curr do
		if curr.ClassName == className then return curr end
		curr = curr.Parent
	end
	return nil
end

function InstanceMethods:GetChildren()
	return table.clone(rawget(self, "_children") or {})
end

function InstanceMethods:GetPivot()
	return self.CFrame or CFrame.new(self.Position or Vector3.new(0,0,0))
end

function InstanceMethods:SetAttribute(k: string, v: any)
	rawget(self, "_attributes")[k] = v
end

function InstanceMethods:GetAttribute(k: string)
	return rawget(self, "_attributes")[k]
end

function InstanceMethods:IsA(className: string)
	return self.ClassName == className
end

function InstanceMethods:IsDescendantOf(ancestor: any)
	local curr = self.Parent
	while curr do
		if curr == ancestor then return true end
		curr = curr.Parent
	end
	return false
end

function InstanceMethods:Destroy()
	self.Parent = nil
	for _, child in ipairs(self:GetChildren()) do
		child:Destroy()
	end
end

function InstanceMethods:TakeDamage(amount: number)
	self.Health = math.max(0, self.Health - amount)
end

function InstanceMethods:ApplyImpulse(impulse: Vector3)
	self.AssemblyLinearVelocity = self.AssemblyLinearVelocity + (impulse / (self.AssemblyMass or 1))
end

function InstanceMethods:Move(dir: Vector3, relative: boolean?) end
function InstanceMethods:Kick(reason: string)
	self._kicked = true
	self._kickReason = reason
end

function InstanceMethods:GetMarkerReachedSignal(marker: string)
	local signals = rawget(self, "_markerSignals")
	if not signals[marker] then
		signals[marker] = Signal.new()
	end
	return signals[marker]
end

function InstanceMethods:FireClient(player: any, data: any) end
function InstanceMethods:FireAllClients(...: any) end

local Instance = {}
function Instance.new(className: string, parent: any?)
	local inst = setmetatable({
		ClassName = className,
		Name = className,
		_parent = nil,
		_children = {},
		_attributes = {},
		AncestryChanged = Signal.new(),
		ChildAdded = Signal.new(),
		ChildRemoved = Signal.new(),
		DescendantAdded = Signal.new(),
		Position = Vector3.new(0, 0, 0),
		CFrame = CFrame.new(0, 0, 0),
		AssemblyLinearVelocity = Vector3.new(0, 0, 0),
		AssemblyMass = 10,
		Health = 100,
		MaxHealth = 100,
		WalkSpeed = 16,
		AutoRotate = true,
		Jump = false,
		Enabled = true,
		Anchored = false,
		CanCollide = true,
		Size = Vector3.new(4, 4, 4),
		UserId = 123456,
		Character = nil,
		PrimaryPart = nil,
		IsPlaying = true,
		_markerSignals = {},
		OnServerEvent = Signal.new(),
	}, InstanceMeta)

	if parent then
		inst.Parent = parent
	end

	return inst
end

_G.Instance = Instance

-- Services
local playersList = {}
local PlayersService = Instance.new("Players")
PlayersService.PlayerAdded = Signal.new()
PlayersService.PlayerRemoving = Signal.new()
function PlayersService:GetPlayers() return table.clone(playersList) end
function PlayersService:GetPlayerFromCharacter(char)
	for _, p in ipairs(playersList) do
		if p.Character == char then return p end
	end
	return nil
end
function PlayersService:BanAsync(params)
	return true
end

local WorkspaceService = Instance.new("Workspace")
WorkspaceService.Blockcast = function(self, cf, sz, dir, params) return nil end
WorkspaceService.Spherecast = function(self, pos, rad, dir, params) return nil end
WorkspaceService.Raycast = function(self, orig, dir, params) return nil end

local ReplicatedStorageService = Instance.new("ReplicatedStorage")
local RunServiceService = Instance.new("RunService")
RunServiceService.Heartbeat = Signal.new()
RunServiceService.IsServer = function(self) return true end

local HttpServiceService = Instance.new("HttpService")
local guidCounter = 0
function HttpServiceService:GenerateGUID(wrap)
	guidCounter += 1
	local g = string.format("guid-%06d", guidCounter)
	return if wrap then "{" .. g .. "}" else g
end

local taggedRegistry: { [string]: { Instance } } = {}
local tagAddedSignals: { [string]: any } = {}
local tagRemovedSignals: { [string]: any } = {}

local CollectionService = Instance.new("CollectionService")
function CollectionService:GetTagged(tag: string): { Instance }
	return table.clone(taggedRegistry[tag] or {})
end
function CollectionService:GetInstanceAddedSignal(tag: string)
	if not tagAddedSignals[tag] then
		tagAddedSignals[tag] = Signal.new()
	end
	return tagAddedSignals[tag]
end
function CollectionService:GetInstanceRemovedSignal(tag: string)
	if not tagRemovedSignals[tag] then
		tagRemovedSignals[tag] = Signal.new()
	end
	return tagRemovedSignals[tag]
end
function CollectionService:AddTag(inst: Instance, tag: string)
	taggedRegistry[tag] = taggedRegistry[tag] or {}
	if not table.find(taggedRegistry[tag], inst) then
		table.insert(taggedRegistry[tag], inst)
		if tagAddedSignals[tag] then
			tagAddedSignals[tag]:Fire(inst)
		end
	end
end
function CollectionService:RemoveTag(inst: Instance, tag: string)
	if taggedRegistry[tag] then
		local idx = table.find(taggedRegistry[tag], inst)
		if idx then
			table.remove(taggedRegistry[tag], idx)
			if tagRemovedSignals[tag] then
				tagRemovedSignals[tag]:Fire(inst)
			end
		end
	end
end

local services = {
	Workspace = WorkspaceService,
	workspace = WorkspaceService,
	Players = PlayersService,
	ReplicatedStorage = ReplicatedStorageService,
	RunService = RunServiceService,
	HttpService = HttpServiceService,
	CollectionService = CollectionService,
	ServerScriptService = Instance.new("ServerScriptService"),
}

local game = {
	GetService = function(self, name)
		if not services[name] then
			services[name] = Instance.new(name)
		end
		return services[name]
	end,
}
_G.game = game
_G.workspace = WorkspaceService
_G.Workspace = WorkspaceService

_G.Random = {
	new = function(seed)
		return {
			NextNumber = function(self, min, max)
				min = min or 0
				max = max or 1
				return min + math.random() * (max - min)
			end,
			NextInteger = function(self, min, max)
				return math.random(min, max)
			end,
		}
	end,
}

_G.debug = _G.debug or {}
_G.debug.profilebegin = function() end
_G.debug.profileend = function() end

_G.task = {
	wait = function(t) end,
	spawn = function(f, ...) return coroutine.create(f), f(...) end,
	delay = function(t, f, ...)
		local thread = coroutine.create(function(...)
			f(...)
		end)
		return thread
	end,
	cancel = function(thread) end,
}

function mock.addPlayer(name: string, userId: number?)
	local p = Instance.new("Player", PlayersService)
	p.Name = name
	p.UserId = userId or (#playersList + 1000)
	local char = Instance.new("Model", WorkspaceService)
	char.Name = name .. "_Char"
	local hrp = Instance.new("Part", char)
	hrp.Name = "HumanoidRootPart"
	local hum = Instance.new("Humanoid", char)
	char.PrimaryPart = hrp
	p.Character = char
	table.insert(playersList, p)
	PlayersService.PlayerAdded:Fire(p)
	return p, char, hum, hrp
end

function mock.removePlayer(p: any)
	for i, pl in ipairs(playersList) do
		if pl == p then
			table.remove(playersList, i)
			break
		end
	end
	if p.Character then
		p.Character:Destroy()
	end
	p:Destroy()
	PlayersService.PlayerRemoving:Fire(p)
end

function mock.reset()
	table.clear(playersList)
	for _, s in pairs(services) do
		s._children = {}
	end
	table.clear(taggedRegistry)
end

local fs = require("@lune/fs")

function mock.requireModule(path: string)
	local content = fs.readFile(path)
	local baseEnv = getfenv()
	local env = setmetatable({}, {
		__index = function(self, key)
			if _G[key] ~= nil then
				return _G[key]
			end
			return baseEnv[key]
		end,
	})
	local fn, err = loadstring(content, path)
	if not fn then
		error("Failed to load " .. path .. ": " .. tostring(err))
	end
	setfenv(fn, env)
	return fn()
end

return mock
