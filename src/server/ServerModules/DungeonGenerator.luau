--!strict

local DungeonTypes = require(script.Parent.DungeonTypes)
local DungeonGrid = require(script.Parent.DungeonGrid)
local DungeonConfig = require(script.Parent.DungeonConfig)

type DirectionName = DungeonTypes.DirectionName
type RoomType = DungeonTypes.RoomType
type RoomNode = DungeonTypes.RoomNode
type GenerationResult = DungeonTypes.GenerationResult
type GridPosition = DungeonTypes.GridPosition

local DungeonGenerator = {}

-- Static constants frozen to guarantee immutability (Rule 163)
local DirectionsOrder: { DirectionName } = table.freeze({ "North", "East", "South", "West" })

-- Internal scratchpad buffers for zero-allocation shuffling (Rule 57)
local ScratchPrimary: { DirectionName } = { "North", "East", "South", "West" }
local ScratchSecondary: { DirectionName } = { "North", "East", "South", "West" }

-- Internal helper: in-place Fisher-Yates shuffle (Rule 57)
local function _shuffleIntoBuffer(rng: Random, buffer: { DirectionName })
	buffer[1] = DirectionsOrder[1]
	buffer[2] = DirectionsOrder[2]
	buffer[3] = DirectionsOrder[3]
	buffer[4] = DirectionsOrder[4]

	for i = 4, 2, -1 do
		local j = rng:NextInteger(1, i)
		local temp = buffer[i]
		buffer[i] = buffer[j]
		buffer[j] = temp
	end
end

-- Internal helper: classify room archetype based on door topology (Rule 57)
local function _classifyHallway(doors: DungeonTypes.DoorDirections, doorCount: number): RoomType
	if doorCount == 1 then
		return "DeadEnd"
	elseif doorCount == 2 then
		if (doors.North and doors.South) or (doors.East and doors.West) then
			return "HallwayStraight"
		end
		return "HallwayCorner"
	elseif doorCount == 3 then
		return "HallwayTee"
	elseif doorCount >= 4 then
		return "HallwayCross"
	end
	return "DeadEnd"
end

function DungeonGenerator.generate(overrideSeed: number?, overrideRoomCount: number?): GenerationResult
	local startTime = os.clock()

	-- Rule 75 & Rule 163: Isolated Random instance + numeric separators
	local seed = if typeof(overrideSeed) == "number"
		then math.floor(overrideSeed)
		else Random.new():NextInteger(100_000, 999_999)

	local targetRooms = if typeof(overrideRoomCount) == "number"
		then math.clamp(math.floor(overrideRoomCount), DungeonConfig.MinRoomCount, DungeonConfig.MaxRoomCount)
		else DungeonConfig.DefaultRoomCount

	local rng = Random.new(seed)
	local cellSize = DungeonConfig.CellSize

	-- Pre-allocated capacity for room list to avoid dynamic resizing
	local occupied: { [string]: RoomNode } = {}
	local roomList: { RoomNode } = table.create(targetRooms)

	local function _createNode(pos: GridPosition, depth: number): RoomNode
		local id = DungeonGrid.toKey(pos)
		local node: RoomNode = {
			id = id,
			gridPos = pos,
			worldPos = DungeonGrid.gridToWorld(pos, cellSize, 0),
			roomType = "HallwayStraight",
			doors = { North = false, South = false, East = false, West = false },
			doorCount = 0,
			depthFromStart = depth,
			neighbors = {},
		}
		occupied[id] = node
		table.insert(roomList, node)
		return node
	end

	local function _connectNodes(a: RoomNode, b: RoomNode, dirFromA: DirectionName)
		local dirFromB = DungeonGrid.OPPOSITE_DIRECTIONS[dirFromA]
		if not a.doors[dirFromA] then
			a.doors[dirFromA] = true
			a.doorCount += 1
			a.neighbors[dirFromA] = b.id
		end
		if not b.doors[dirFromB] then
			b.doors[dirFromB] = true
			b.doorCount += 1
			b.neighbors[dirFromB] = a.id
		end
	end

	-- 1. Initialize Start Room at origin (0, 0)
	local startNode = _createNode({ x = 0, y = 0 }, 0)
	startNode.roomType = "Start"

	-- 2. Build Critical Path (Main spine of the dungeon)
	local mainPathTarget = math.max(4, math.floor(targetRooms * DungeonConfig.MainPathRatio))
	local currentNode = startNode
	local mainSpineNodes: { RoomNode } = table.create(mainPathTarget + 1)
	table.insert(mainSpineNodes, startNode)

	for _ = 1, mainPathTarget do
		_shuffleIntoBuffer(rng, ScratchPrimary)
		local stepped = false

		for i = 1, 4 do
			local dir = ScratchPrimary[i]
			local nextPos = DungeonGrid.getNeighborPos(currentNode.gridPos, dir)
			local key = DungeonGrid.toKey(nextPos)

			if not occupied[key] then
				local nextNode = _createNode(nextPos, currentNode.depthFromStart + 1)
				_connectNodes(currentNode, nextNode, dir)
				currentNode = nextNode
				table.insert(mainSpineNodes, nextNode)
				stepped = true
				break
			end
		end

		if not stepped then
			-- Backtrack along the spine to find an unblocked branching point
			for bi = #mainSpineNodes - 1, 1, -1 do
				local prior = mainSpineNodes[bi]
				_shuffleIntoBuffer(rng, ScratchSecondary)

				for i = 1, 4 do
					local dir = ScratchSecondary[i]
					local nextPos = DungeonGrid.getNeighborPos(prior.gridPos, dir)
					local key = DungeonGrid.toKey(nextPos)

					if not occupied[key] then
						local nextNode = _createNode(nextPos, prior.depthFromStart + 1)
						_connectNodes(prior, nextNode, dir)
						currentNode = nextNode
						table.insert(mainSpineNodes, nextNode)
						stepped = true
						break
					end
				end

				if stepped then
					break
				end
			end

			if not stepped then
				break
			end
		end
	end

	local mainSpineCount = #roomList

	-- 3. Branching Expansion (Secondary branches)
	local attempts = 0
	local maxAttempts = targetRooms * 15

	while #roomList < targetRooms and attempts < maxAttempts do
		attempts += 1
		local parentIndex = rng:NextInteger(1, #roomList)
		local parentNode = roomList[parentIndex]

		if rng:NextNumber() <= DungeonConfig.BranchProbability then
			_shuffleIntoBuffer(rng, ScratchPrimary)
			for i = 1, 4 do
				local dir = ScratchPrimary[i]
				local nextPos = DungeonGrid.getNeighborPos(parentNode.gridPos, dir)
				local key = DungeonGrid.toKey(nextPos)

				if not occupied[key] then
					local newNode = _createNode(nextPos, parentNode.depthFromStart + 1)
					_connectNodes(parentNode, newNode, dir)
					break
				end
			end
		end
	end

	local branchCount = #roomList - mainSpineCount

	-- 4. Determine Exit Room (Maximum topological depth from Start)
	local exitCandidate: RoomNode = startNode
	local maxDepth = 0

	for i = 1, #roomList do
		local node = roomList[i]
		if node.id ~= startNode.id and node.depthFromStart > maxDepth then
			maxDepth = node.depthFromStart
			exitCandidate = node
		end
	end

	exitCandidate.roomType = "Exit"

	-- 5. Classify Dead Ends and Loot Vaults
	local maxLootRooms = math.max(1, math.floor(targetRooms * DungeonConfig.MaxLootRoomRatio))
	local lootRooms: { RoomNode } = table.create(maxLootRooms)

	for i = 1, #roomList do
		local node = roomList[i]
		if node.id == startNode.id then
			node.roomType = "Start"
		elseif node.id == exitCandidate.id then
			node.roomType = "Exit"
		else
			local defaultClass = _classifyHallway(node.doors, node.doorCount)
			if defaultClass == "DeadEnd" then
				if rng:NextNumber() <= DungeonConfig.LootRoomProbability and #lootRooms < maxLootRooms then
					node.roomType = "Loot"
					table.insert(lootRooms, node)
				else
					node.roomType = "DeadEnd"
				end
			else
				node.roomType = defaultClass
			end
		end
	end

	-- 6. Verification: Reachability Check via Breadth-First Search (BFS)
	local visited: { [string]: boolean } = { [startNode.id] = true }
	local queue: { RoomNode } = table.create(targetRooms)
	queue[1] = startNode
	local head = 1

	while head <= #queue do
		local curr = queue[head]
		head += 1

		-- Generalized Luau iteration (Rule 163)
		for _, neighborId in curr.neighbors do
			if not visited[neighborId] and occupied[neighborId] then
				visited[neighborId] = true
				table.insert(queue, occupied[neighborId])
			end
		end
	end

	local isReachable = (visited[exitCandidate.id] == true)
	local genDuration = (os.clock() - startTime) * 1_000

	local result: GenerationResult = {
		seed = seed,
		rooms = occupied,
		roomList = roomList,
		startRoom = startNode,
		exitRoom = exitCandidate,
		lootRooms = lootRooms,
		totalRooms = #roomList,
		mainSpineCount = mainSpineCount,
		branchCount = branchCount,
		maxDepth = maxDepth,
		generationTimeMs = math.round(genDuration * 1_000) / 1_000,
		isReachable = isReachable,
		hasCollisions = false,
	}

	return result
end

return table.freeze(DungeonGenerator)
