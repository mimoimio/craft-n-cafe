-- Shared/Grid.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)

local Grid = {}

Grid.SIZE = 4 -- Centralized Constant

-- [[ MATH OPERATIONS ]]

function Grid.getFootprint(itemSize: Vector3, rotation: number): (number, number)
	local isRotated = math.abs(rotation % 180) == 90
	local x = isRotated and itemSize.Z or itemSize.X
	local z = isRotated and itemSize.X or itemSize.Z
	return math.max(1, math.round(x / Grid.SIZE)), math.max(1, math.round(z / Grid.SIZE))
end

function Grid.worldToGrid(worldPos: Vector3, plotCFrame: CFrame, itemSize: Vector3, rotation: number): (number, number)
	local localPos = plotCFrame:PointToObjectSpace(worldPos)

	local isRotated = math.abs(rotation % 180) == 90
	local itemX = isRotated and itemSize.Z or itemSize.X
	local itemZ = isRotated and itemSize.X or itemSize.Z

	local cornerLocalX = localPos.X - (itemX / 2)
	local cornerLocalZ = localPos.Z - (itemZ / 2)

	local gridX = math.round(cornerLocalX / Grid.SIZE)
	local gridZ = math.round(cornerLocalZ / Grid.SIZE)

	return gridX, gridZ
end

function Grid.gridToWorld(
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

	local localX = (gridX * Grid.SIZE) + (itemX / 2)
	local localZ = (gridZ * Grid.SIZE) + (itemZ / 2)
	local localY = (plotSize.Y / 2) + (itemSize.Y / 2)

	return plotCFrame * CFrame.new(localX, localY, localZ) * CFrame.Angles(0, rad, 0)
end

function Grid.clampToGrid(
	gridX: number,
	gridZ: number,
	itemWidth: number,
	itemLength: number,
	plotSize: Vector3
): (number, number)
	local minX = math.ceil((-plotSize.X / 2) / Grid.SIZE)
	local maxX = math.floor((plotSize.X / 2) / Grid.SIZE) - itemWidth
	local minZ = math.ceil((-plotSize.Z / 2) / Grid.SIZE)
	local maxZ = math.floor((plotSize.Z / 2) / Grid.SIZE) - itemLength

	return math.clamp(gridX, minX, maxX), math.clamp(gridZ, minZ, maxZ)
end

-- [[ STATE VALIDATION ]]

function Grid.isAreaFree(
	plotState: Types.PlotState?,
	startX: number,
	startZ: number,
	width: number,
	length: number
): boolean
	if not plotState then
		return true
	end -- If no state exists yet, it's free

	for x = startX, startX + width - 1 do
		for z = startZ, startZ + length - 1 do
			local key = `{x}_{z}`
			if plotState.occupiedCoordinates[key] ~= nil then
				return false
			end
		end
	end

	return true
end

return Grid
