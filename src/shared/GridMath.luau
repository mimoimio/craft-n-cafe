-- GridMath.luau
local GridMath = {}

-- Converts a world position into discrete 2D grid coordinates centered at 0,0
function GridMath.worldToGrid(
	worldPos: Vector3,
	plotCFrame: CFrame,
	gridSize: number,
	itemSize: Vector3,
	rotation: number
): (number, number)
	local localPos = plotCFrame:PointToObjectSpace(worldPos)

	local isRotated = math.abs(rotation % 180) == 90
	local itemX = isRotated and itemSize.Z or itemSize.X
	local itemZ = isRotated and itemSize.X or itemSize.Z

	-- Shift by half the item size to get the corner coordinate relative to the center
	local cornerLocalX = localPos.X - (itemX / 2)
	local cornerLocalZ = localPos.Z - (itemZ / 2)

	-- Snap directly to grid size without adding plot boundaries
	local gridX = math.round(cornerLocalX / gridSize)
	local gridZ = math.round(cornerLocalZ / gridSize)

	return gridX, gridZ
end

-- Converts grid coordinates back to a world CFrame relative to 0,0
function GridMath.gridToWorld(
	gridX: number,
	gridZ: number,
	plotCFrame: CFrame,
	plotSize: Vector3,
	gridSize: number,
	itemSize: Vector3,
	rotation: number
): CFrame
	local rad = math.rad(rotation)

	local isRotated = math.abs(rotation % 180) == 90
	local itemX = isRotated and itemSize.Z or itemSize.X
	local itemZ = isRotated and itemSize.X or itemSize.Z

	-- gridX * gridSize gives the exact local offset of the bottom-left corner from 0,0
	local localX = (gridX * gridSize) + (itemX / 2)
	local localZ = (gridZ * gridSize) + (itemZ / 2)

	-- Y is relative to the top of the plot bounding box
	local localY = (plotSize.Y / 2) + (itemSize.Y / 2)

	return plotCFrame * CFrame.new(localX, localY, localZ) * CFrame.Angles(0, rad, 0)
end
-- Forces grid coordinates to stay within the physical bounds of the plot
function GridMath.clampToGrid(
	gridX: number,
	gridZ: number,
	itemWidth: number,
	itemLength: number,
	plotSize: Vector3,
	gridSize: number
): (number, number)
	local minX = math.ceil((-plotSize.X / 2) / gridSize)
	local maxX = math.floor((plotSize.X / 2) / gridSize) - itemWidth
	local minZ = math.ceil((-plotSize.Z / 2) / gridSize)
	local maxZ = math.floor((plotSize.Z / 2) / gridSize) - itemLength

	return math.clamp(gridX, minX, maxX), math.clamp(gridZ, minZ, maxZ)
end

-- Validates if the coordinates stay within the physical bounds of the plot
function GridMath.isWithinBounds(
	gridX: number,
	gridZ: number,
	itemWidth: number,
	itemLength: number,
	plotSize: Vector3,
	gridSize: number
): boolean
	local minX = math.ceil((-plotSize.X / 2) / gridSize)
	local maxX = math.floor((plotSize.X / 2) / gridSize) - itemWidth
	local minZ = math.ceil((-plotSize.Z / 2) / gridSize)
	local maxZ = math.floor((plotSize.Z / 2) / gridSize) - itemLength

	return gridX >= minX and gridX <= maxX and gridZ >= minZ and gridZ <= maxZ
end

-- Returns the dimensions of the item in grid units
function GridMath.getFootprint(itemSize: Vector3, gridSize: number, rotation: number): (number, number)
	local isRotated = math.abs(rotation % 180) == 90
	local x = isRotated and itemSize.Z or itemSize.X
	local z = isRotated and itemSize.X or itemSize.Z

	return math.max(1, math.round(x / gridSize)), math.max(1, math.round(z / gridSize))
end

return GridMath
