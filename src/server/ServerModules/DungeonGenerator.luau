--!strict
--[[
    DungeonGenerator.luau
    Pure algorithmic, deterministic procedural room graph generator.
    Strictly follows Branching Grid Walker algorithm.
    Features:
      - Deterministic PRNG seeded by integer (Random.new)
      - Guaranteed connectivity (Start to Exit is always reachable)
      - Zero overlap by construction using spatial grid occupancy
      - Branching generation with room categorization (Start, Exit, Loot, Hallways, DeadEnds)
      - Microsecond performance benchmark (< 2ms for 30+ rooms)
]]

local DungeonTypes = require(script.Parent.DungeonTypes)
local DungeonGrid = require(script.Parent.DungeonGrid)
local DungeonConfig = require(script.Parent.DungeonConfig)

type DirectionName = DungeonTypes.DirectionName
type RoomType = DungeonTypes.RoomType
type RoomNode = DungeonTypes.RoomNode
type GenerationResult = DungeonTypes.GenerationResult
type GridPosition = DungeonTypes.GridPosition
type DungeonConfigData = typeof(DungeonConfig)

local DungeonGenerator = {}

local function shuffleDirections(rng: Random): { DirectionName }
	local dirs: { DirectionName } = { "North", "East", "South", "West" }
	for i = #dirs, 2, -1 do
		local j = rng:NextInteger(1, i)
		dirs[i], dirs[j] = dirs[j], dirs[i]
	end
	return dirs
end

local function classifyHallway(doors: DungeonTypes.DoorDirections, doorCount: number): RoomType
	if doorCount == 1 then
		return "DeadEnd"
	elseif doorCount == 2 then
		if (doors.North and doors.South) or (doors.East and doors.West) then
			return "HallwayStraight"
		else
			return "HallwayCorner"
		end
	elseif doorCount == 3 then
		return "HallwayTee"
	elseif doorCount >= 4 then
		return "HallwayCross"
	end
	return "DeadEnd"
end

function DungeonGenerator.generate(overrideSeed: number?, overrideRoomCount: number?): GenerationResult
	local startTime = os.clock()

	local seed = if typeof(overrideSeed) == "number" then math.floor(overrideSeed) else math.random(100000, 999999)
	local targetRooms = if typeof(overrideRoomCount) == "number"
		then math.clamp(math.floor(overrideRoomCount), DungeonConfig.MinRoomCount, DungeonConfig.MaxRoomCount)
		else DungeonConfig.DefaultRoomCount

	local rng = Random.new(seed)
	local cellSize = DungeonConfig.CellSize

	-- Spatial occupancy map: "x:y" -> RoomNode
	local occupied: { [string]: RoomNode } = {}
	local roomList: { RoomNode } = {}

	local function createNode(pos: GridPosition, depth: number): RoomNode
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

	local function connectNodes(a: RoomNode, b: RoomNode, dirFromA: DirectionName)
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
	local startNode = createNode({ x = 0, y = 0 }, 0)
	startNode.roomType = "Start"

	-- 2. Build Critical Path (Main spine of the dungeon)
	local mainPathTarget = math.max(4, math.floor(targetRooms * DungeonConfig.MainPathRatio))
	local currentNode = startNode
	local mainSpineNodes: { RoomNode } = { startNode }

	for _ = 1, mainPathTarget do
		local candidateDirs = shuffleDirections(rng)
		local stepped = false

		for _, dir in ipairs(candidateDirs) do
			local nextPos = DungeonGrid.getNeighborPos(currentNode.gridPos, dir)
			local key = DungeonGrid.toKey(nextPos)

			if not occupied[key] then
				local nextNode = createNode(nextPos, currentNode.depthFromStart + 1)
				connectNodes(currentNode, nextNode, dir)
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
				for _, dir in ipairs(shuffleDirections(rng)) do
					local nextPos = DungeonGrid.getNeighborPos(prior.gridPos, dir)
					local key = DungeonGrid.toKey(nextPos)
					if not occupied[key] then
						local nextNode = createNode(nextPos, prior.depthFromStart + 1)
						connectNodes(prior, nextNode, dir)
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

	-- 3. Branching Expansion (Fill up to targetRooms with secondary branches)
	local attempts = 0
	local maxAttempts = targetRooms * 15

	while #roomList < targetRooms and attempts < maxAttempts do
		attempts += 1
		local parentIndex = rng:NextInteger(1, #roomList)
		local parentNode = roomList[parentIndex]

		if rng:NextNumber() <= DungeonConfig.BranchProbability then
			local dirs = shuffleDirections(rng)
			for _, dir in ipairs(dirs) do
				local nextPos = DungeonGrid.getNeighborPos(parentNode.gridPos, dir)
				local key = DungeonGrid.toKey(nextPos)

				if not occupied[key] then
					local newNode = createNode(nextPos, parentNode.depthFromStart + 1)
					connectNodes(parentNode, newNode, dir)
					break
				end
			end
		end
	end

	local branchCount = #roomList - mainSpineCount

	-- 4. Determine Exit Room (Maximum topological depth from Start)
	local exitCandidate: RoomNode = startNode
	local maxDepth = 0

	for _, node in ipairs(roomList) do
		if node.id ~= startNode.id and node.depthFromStart > maxDepth then
			maxDepth = node.depthFromStart
			exitCandidate = node
		end
	end

	exitCandidate.roomType = "Exit"

	-- 5. Classify Dead Ends and Loot Vaults
	local lootRooms: { RoomNode } = {}
	local maxLootRooms = math.max(1, math.floor(targetRooms * DungeonConfig.MaxLootRoomRatio))

	for _, node in ipairs(roomList) do
		if node.id == startNode.id then
			node.roomType = "Start"
		elseif node.id == exitCandidate.id then
			node.roomType = "Exit"
		else
			local defaultClass = classifyHallway(node.doors, node.doorCount)
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
	local queue: { RoomNode } = { startNode }
	local head = 1

	while head <= #queue do
		local curr = queue[head]
		head += 1

		for _, neighborId in pairs(curr.neighbors) do
			if not visited[neighborId] and occupied[neighborId] then
				visited[neighborId] = true
				table.insert(queue, occupied[neighborId])
			end
		end
	end

	local isReachable = (visited[exitCandidate.id] == true)
	local genDuration = (os.clock() - startTime) * 1000

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
		generationTimeMs = math.round(genDuration * 100) / 100,
		isReachable = isReachable,
		hasCollisions = false, -- Guaranteed by grid key space
	}

	return result
end

return DungeonGenerator
