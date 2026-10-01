--!strict
-- [ProductionCore / Shared / Packages / BufferUtil.luau]
-- Enterprise High-Performance Binary Serialization Engine.
-- Provides dynamically resizing buffer writer, cursor-based streaming reader, and native Vector3 packing.

local BufferUtil = {}

function BufferUtil.WriteVector3(b: buffer, offset: number, v: Vector3): number
	buffer.writef32(b, offset, v.X)
	buffer.writef32(b, offset + 4, v.Y)
	buffer.writef32(b, offset + 8, v.Z)
	return offset + 12
end

function BufferUtil.ReadVector3(b: buffer, offset: number): (Vector3, number)
	return Vector3.new(
		buffer.readf32(b, offset),
		buffer.readf32(b, offset + 4),
		buffer.readf32(b, offset + 8)
	), offset + 12
end

function BufferUtil.CreateWriter(initialSize: number?)
	local b = buffer.create(math.max(16, initialSize or 64))
	local cursor = 0
	local writer = {}

	local function ensureCapacity(neededBytes: number)
		local currentLen = buffer.len(b)
		if cursor + neededBytes > currentLen then
			local newCapacity = math.max(currentLen * 2, cursor + neededBytes)
			local newB = buffer.create(newCapacity)
			buffer.copy(newB, 0, b, 0, cursor)
			b = newB
		end
	end

	function writer:WriteU8(v: number)
		ensureCapacity(1)
		buffer.writeu8(b, cursor, v)
		cursor += 1
	end

	function writer:WriteI8(v: number)
		ensureCapacity(1)
		buffer.writei8(b, cursor, v)
		cursor += 1
	end

	function writer:WriteU16(v: number)
		ensureCapacity(2)
		buffer.writeu16(b, cursor, v)
		cursor += 2
	end

	function writer:WriteI16(v: number)
		ensureCapacity(2)
		buffer.writei16(b, cursor, v)
		cursor += 2
	end

	function writer:WriteU32(v: number)
		ensureCapacity(4)
		buffer.writeu32(b, cursor, v)
		cursor += 4
	end

	function writer:WriteI32(v: number)
		ensureCapacity(4)
		buffer.writei32(b, cursor, v)
		cursor += 4
	end

	function writer:WriteF32(v: number)
		ensureCapacity(4)
		buffer.writef32(b, cursor, v)
		cursor += 4
	end

	function writer:WriteF64(v: number)
		ensureCapacity(8)
		buffer.writef64(b, cursor, v)
		cursor += 8
	end

	function writer:WriteVector3(v: Vector3)
		ensureCapacity(12)
		cursor = BufferUtil.WriteVector3(b, cursor, v)
	end

	function writer:WriteBoolean(v: boolean)
		self:WriteU8(if v then 1 else 0)
	end

	function writer:WriteString(str: string)
		local strLen = #str
		self:WriteU16(strLen)
		ensureCapacity(strLen)
		buffer.writestring(b, cursor, str, strLen)
		cursor += strLen
	end

	function writer:GetBuffer(): (buffer, number)
		return b, cursor
	end

	function writer:ToBuffer(): buffer
		local trimmed = buffer.create(cursor)
		buffer.copy(trimmed, 0, b, 0, cursor)
		return trimmed
	end

	function writer:GetCursor(): number
		return cursor
	end

	function writer:SetCursor(pos: number)
		cursor = math.clamp(pos, 0, buffer.len(b))
	end

	return writer
end

function BufferUtil.CreateReader(b: buffer)
	local cursor = 0
	local totalLen = buffer.len(b)
	local reader = {}

	function reader:ReadU8(): number
		local v = buffer.readu8(b, cursor)
		cursor += 1
		return v
	end

	function reader:ReadI8(): number
		local v = buffer.readi8(b, cursor)
		cursor += 1
		return v
	end

	function reader:ReadU16(): number
		local v = buffer.readu16(b, cursor)
		cursor += 2
		return v
	end

	function reader:ReadI16(): number
		local v = buffer.readi16(b, cursor)
		cursor += 2
		return v
	end

	function reader:ReadU32(): number
		local v = buffer.readu32(b, cursor)
		cursor += 4
		return v
	end

	function reader:ReadI32(): number
		local v = buffer.readi32(b, cursor)
		cursor += 4
		return v
	end

	function reader:ReadF32(): number
		local v = buffer.readf32(b, cursor)
		cursor += 4
		return v
	end

	function reader:ReadF64(): number
		local v = buffer.readf64(b, cursor)
		cursor += 8
		return v
	end

	function reader:ReadVector3(): Vector3
		local v, nextCursor = BufferUtil.ReadVector3(b, cursor)
		cursor = nextCursor
		return v
	end

	function reader:ReadBoolean(): boolean
		return self:ReadU8() ~= 0
	end

	function reader:ReadString(): string
		local strLen = self:ReadU16()
		local str = buffer.readstring(b, cursor, strLen)
		cursor += strLen
		return str
	end

	function reader:GetCursor(): number
		return cursor
	end

	function reader:SetCursor(pos: number)
		cursor = math.clamp(pos, 0, totalLen)
	end

	function reader:GetRemaining(): number
		return math.max(0, totalLen - cursor)
	end

	function reader:CanRead(bytes: number): boolean
		return cursor + bytes <= totalLen
	end

	return reader
end

return table.freeze(BufferUtil)
