-- Shared/Grid.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)

local Grid = {}
Grid.SIZE = 4

-- [[ MATH OPERATIONS ]]

function Grid.getFootprint(itemSize: Vector3, rotation: number): (number, number)
	local isRotated = math.abs(rotation % 180) == 90
	local x = isRotated and itemSize.Z or itemSize.X
	local z = isRotated and itemSize.X or itemSize.Z
	return math.max(1, math.round(x / Grid.SIZE)), math.max(1, math.round(z / Grid.SIZE))
end

function Grid.worldToSolid(worldPos: Vector3, plotCFrame: CFrame, itemSize: Vector3, rotation: number): (number, number)
	local localPos = plotCFrame:PointToObjectSpace(worldPos)

	local isRotated = math.abs(rotation % 180) == 90
	local itemX = isRotated and itemSize.Z or itemSize.X
	local itemZ = isRotated and itemSize.X or itemSize.Z

	local cornerLocalX = localPos.X - (itemX / 2)
	local cornerLocalZ = localPos.Z - (itemZ / 2)

	return math.round(cornerLocalX / Grid.SIZE), math.round(cornerLocalZ / Grid.SIZE)
end

function Grid.worldToEdge(worldPos: Vector3, plotCFrame: CFrame, rotation: number): (string, number, number)
	local localPos = plotCFrame:PointToObjectSpace(worldPos)

	local rawX = localPos.X / Grid.SIZE
	local rawZ = localPos.Z / Grid.SIZE

	local isRotated = math.abs(rotation % 180) == 90

	if isRotated then
		-- Rotated 90 or 270: It's a Vertical Wall.
		-- Snap rigidly to X-lines (round), slide smoothly along Z-cells (floor).
		return "Wall_V", math.round(rawX), math.floor(rawZ)
	else
		-- Rotated 0 or 180: It's a Horizontal Wall.
		-- Snap rigidly to Z-lines (round), slide smoothly along X-cells (floor).
		return "Wall_H", math.floor(rawX), math.round(rawZ)
	end
end

function Grid.gridToWorld(
	itemType: string,
	gridX: number,
	gridZ: number,
	plotCFrame: CFrame,
	plotSize: Vector3,
	itemSize: Vector3,
	rotation: number
): CFrame
	local rad = math.rad(rotation)
	local isRotated = math.abs(rotation % 180) == 90
	local itemX = isRotated and itemSize.Z or itemSize.X
	local itemZ = isRotated and itemSize.X or itemSize.Z

	local localX, localZ

	if itemType == "Solid" then
		localX = (gridX * Grid.SIZE) + (itemX / 2)
		localZ = (gridZ * Grid.SIZE) + (itemZ / 2)
	elseif itemType == "Wall_V" then
		localX = (gridX * Grid.SIZE) -- Snaps directly onto the X line
		localZ = (gridZ * Grid.SIZE) + (itemZ / 2)
	elseif itemType == "Wall_H" then
		localX = (gridX * Grid.SIZE) + (itemX / 2)
		localZ = (gridZ * Grid.SIZE) -- Snaps directly onto the Z line
	end

	local localY = (plotSize.Y / 2) + (itemSize.Y / 2)
	return plotCFrame * CFrame.new(localX, localY, localZ) * CFrame.Angles(0, rad, 0)
end

function Grid.clampToGrid(
	itemType: string,
	gridX: number,
	gridZ: number,
	itemWidth: number,
	itemLength: number,
	plotSize: Vector3
): (number, number)
	local minX = math.ceil((-plotSize.X / 2) / Grid.SIZE)
	local baseMaxX = math.floor((plotSize.X / 2) / Grid.SIZE)

	local minZ = math.ceil((-plotSize.Z / 2) / Grid.SIZE)
	local baseMaxZ = math.floor((plotSize.Z / 2) / Grid.SIZE)

	local maxX, maxZ

	if itemType == "Wall_V" then
		-- Vertical walls consume Z-length, but take up 0 space on the X-axis (they sit on the line)
		maxX = baseMaxX
		maxZ = baseMaxZ - itemLength
	elseif itemType == "Wall_H" then
		-- Horizontal walls consume X-width, but take up 0 space on the Z-axis
		maxX = baseMaxX - itemWidth
		maxZ = baseMaxZ
	else
		-- Solids consume space on both axes
		maxX = baseMaxX - itemWidth
		maxZ = baseMaxZ - itemLength
	end

	return math.clamp(gridX, minX, maxX), math.clamp(gridZ, minZ, maxZ)
end

-- [[ STATE VALIDATION ]]
function Grid.getHalfGridBounds(itemType: string, stdX: number, stdZ: number, stdW: number, stdL: number)
	local startX, endX, startZ, endZ
	if itemType == "Solid" then
		startX = stdX * 2
		endX = 2 * (stdX + stdW - 1)
		startZ = stdZ * 2
		endZ = 2 * (stdZ + stdL - 1)
	elseif itemType == "Wall_V" then
		startX = (stdX * 2) - 1
		endX = startX
		startZ = stdZ * 2
		endZ = 2 * (stdZ + stdL - 1)
	elseif itemType == "Wall_H" then
		startX = stdX * 2
		endX = 2 * (stdX + stdW - 1)
		startZ = (stdZ * 2) - 1
		endZ = startZ
	end
	return startX, endX, startZ, endZ
end

function Grid.isAreaFree(
	plotState: Types.PlotState?,
	itemType: string,
	stdX: number,
	stdZ: number,
	width: number,
	length: number
): boolean
	if not plotState then
		return true
	end
	local startX, endX, startZ, endZ = Grid.getHalfGridBounds(itemType, stdX, stdZ, width, length)

	for hx = startX, endX do
		for hz = startZ, endZ do
			if plotState.grid[`{hx}_{hz}`] ~= nil then
				return false
			end
		end
	end
	return true
end

return Grid
