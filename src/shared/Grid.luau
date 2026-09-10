-- Shared/Grid.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)

local Grid = {}
Grid.SIZE = 4
Grid.WALL_HEIGHT = 14 -- NEW: Adjust this to match the height of your physical Wall models!

--- Checks for a designated logical Hitbox part, otherwise falls back to mesh bounds
function Grid.getModelBounds(model: Model): (CFrame, Vector3)
	local hitbox = model:FindFirstChild("Hitbox")
	if hitbox and hitbox:IsA("BasePart") then
		return hitbox.CFrame, hitbox.Size
	end
	return model:GetBoundingBox()
end
-- NEW: Helper to separate physical layers so a Floor doesn't block a Table
function Grid.getLayer(itemType: string): string
	if itemType == "Floor" then
		return "Floor"
	end
	if itemType == "Roof" then
		return "Roof"
	end
	return "Main" -- Solid, Wall_V, and Wall_H share the Main collision layer
end

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

	-- UPDATED: Floor and Roof share the "Solid" footprint logic (centered in cells)
	if itemType == "Solid" or itemType == "Floor" or itemType == "Roof" then
		localX = (gridX * Grid.SIZE) + (itemX / 2)
		localZ = (gridZ * Grid.SIZE) + (itemZ / 2)
	elseif itemType == "Wall_V" then
		localX = (gridX * Grid.SIZE) -- Snaps directly onto the X line
		localZ = (gridZ * Grid.SIZE) + (itemZ / 2)
	elseif itemType == "Wall_H" then
		localX = (gridX * Grid.SIZE) + (itemX / 2)
		localZ = (gridZ * Grid.SIZE) -- Snaps directly onto the Z line
	end

	-- [[ Z-AXIS ELEVATION LOGIC ]]
	local localY = (plotSize.Y / 2) + (itemSize.Y / 2)

	if itemType == "Roof" then
		localY += Grid.WALL_HEIGHT
	elseif itemType == "Floor" then
		localY += 0.05 -- Tiny offset so floor textures don't Z-fight with the plot part
	end

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
		-- UPDATED: Solids, Floors, and Roofs consume space on both axes
		maxX = baseMaxX - itemWidth
		maxZ = baseMaxZ - itemLength
	end

	return math.clamp(gridX, minX, maxX), math.clamp(gridZ, minZ, maxZ)
end

-- [[ STATE VALIDATION ]]
function Grid.getHalfGridBounds(itemType: string, stdX: number, stdZ: number, stdW: number, stdL: number)
	local startX, endX, startZ, endZ

	-- UPDATED: Treat Floors and Roofs mathematically like Solids
	if itemType == "Solid" or itemType == "Floor" or itemType == "Roof" then
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

	-- NEW: Get the target layer string
	local layer = Grid.getLayer(itemType)

	for hx = startX, endX do
		for hz = startZ, endZ do
			-- UPDATED: Prefix the grid key with the layer so they don't intersect
			if plotState.grid[`{layer}_{hx}_{hz}`] ~= nil then
				return false
			end
		end
	end
	return true
end

return Grid
