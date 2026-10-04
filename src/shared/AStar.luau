-- Shared/AStar.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Grid = require(ReplicatedStorage.Shared.Grid)

local AStar = {}

local function getNodeKey(x, z)
	return x .. "_" .. z
end

local function heuristic(x1, z1, x2, z2)
	return math.abs(x1 - x2) + math.abs(z1 - z2)
end

function AStar.compute(startX, startZ, targetX, targetZ, plotState, plotSize, ignoreCollisions)
	-- Bounds (Add +/- 2 to allow walking to the Entrance, which sits just outside the plot bounds)
	local half = math.floor(plotSize / 2 / Grid.SIZE)
	local minBound = -half - 2
	local maxBound = half + 2

	local openSet = {}
	local openMap = {}
	local closedSet = {}

	local startNode = {
		x = startX,
		z = startZ,
		g = 0,
		h = heuristic(startX, startZ, targetX, targetZ),
		f = 0,
		parent = nil,
	}
	startNode.f = startNode.g + startNode.h

	table.insert(openSet, startNode)
	openMap[getNodeKey(startX, startZ)] = startNode

	-- Up, Down, Left, Right (No diagonals, keeps them walking on the grid cleanly)
	local dirs = {
		{ x = 1, z = 0 },
		{ x = -1, z = 0 },
		{ x = 0, z = 1 },
		{ x = 0, z = -1 },
	}

	while #openSet > 0 do
		local lowestIndex = 1
		for i = 2, #openSet do
			if openSet[i].f < openSet[lowestIndex].f then
				lowestIndex = i
			end
		end

		local current = openSet[lowestIndex]

		-- Did we reach target?
		if current.x == targetX and current.z == targetZ then
			local path = {}
			local temp = current
			while temp do
				table.insert(path, 1, { x = temp.x, z = temp.z })
				temp = temp.parent
			end
			-- Remove the start node so they don't awkwardly walk backwards to the center of their current cell
			if #path > 0 and path[1].x == startX and path[1].z == startZ then
				table.remove(path, 1)
			end
			return path
		end

		table.remove(openSet, lowestIndex)
		openMap[getNodeKey(current.x, current.z)] = nil
		closedSet[getNodeKey(current.x, current.z)] = true

		for _, dir in ipairs(dirs) do
			local nx = current.x + dir.x
			local nz = current.z + dir.z
			local nKey = getNodeKey(nx, nz)

			if nx >= minBound and nx <= maxBound and nz >= minBound and nz <= maxBound then
				if not closedSet[nKey] then
					local isFinalTarget = (nx == targetX and nz == targetZ)

					-- If ignoreCollisions is true, we bypass Grid checks entirely and ghost through!
					local canStep = ignoreCollisions
						or Grid.canMove(current.x, current.z, nx, nz, plotState, isFinalTarget)

					if canStep then
						local tentativeG = current.g + 1
						local neighbor = openMap[nKey]

						if not neighbor then
							neighbor = {
								x = nx,
								z = nz,
								g = tentativeG,
								h = heuristic(nx, nz, targetX, targetZ),
								parent = current,
							}
							neighbor.f = neighbor.g + neighbor.h
							table.insert(openSet, neighbor)
							openMap[nKey] = neighbor
						elseif tentativeG < neighbor.g then
							neighbor.g = tentativeG
							neighbor.f = neighbor.g + neighbor.h
							neighbor.parent = current
						end
					end
				end
			end
		end
	end

	return nil -- Blocked, No path found
end

return AStar
