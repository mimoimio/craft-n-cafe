-- Shared/Grid.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)

local Grid = {}
Grid.SIZE = 4
Grid.WALL_HEIGHT = 14 -- NEW: Adjust this to match the height of your physical Wall models!

export type GridStud = Types.GridStud
export type HalfGridStud = Types.HalfGridStud

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

function Grid.getFootprint(itemSize: Vector3, rotation: number): (GridStud, GridStud)
	local isRotated = math.abs(rotation % 180) == 90
	local x = isRotated and itemSize.Z or itemSize.X
	local z = isRotated and itemSize.X or itemSize.Z
	return math.max(1, math.round(x / Grid.SIZE)), math.max(1, math.round(z / Grid.SIZE))
end

function Grid.worldToSolid(
	worldPos: Vector3,
	plotCFrame: CFrame,
	itemSize: Vector3,
	rotation: number
): (GridStud, GridStud)
	local localPos = plotCFrame:PointToObjectSpace(worldPos)

	local isRotated = math.abs(rotation % 180) == 90
	local itemX = isRotated and itemSize.Z or itemSize.X
	local itemZ = isRotated and itemSize.X or itemSize.Z

	local cornerLocalX = localPos.X - (itemX / 2)
	local cornerLocalZ = localPos.Z - (itemZ / 2)

	return math.round(cornerLocalX / Grid.SIZE), math.round(cornerLocalZ / Grid.SIZE)
end

function Grid.worldToEdge(worldPos: Vector3, plotCFrame: CFrame, rotation: number): (string, GridStud, GridStud)
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
	gridX: GridStud,
	gridZ: GridStud,
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
		localY = (plotSize.Y / 2)
	end

	return plotCFrame * CFrame.new(localX, localY, localZ) * CFrame.Angles(0, rad, 0)
end

function Grid.clampToGrid(
	itemType: string,
	gridX: GridStud,
	gridZ: GridStud,
	itemWidth: GridStud,
	itemLength: GridStud,
	plotSize: Vector3
): (GridStud, GridStud)
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
function Grid.getHalfGridBounds(
	itemType: string,
	stdX: number,
	stdZ: number,
	stdW: number,
	stdL: number
): (HalfGridStud, HalfGridStud, HalfGridStud)
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
	stdX: GridStud,
	stdZ: GridStud,
	width: GridStud,
	length: GridStud
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
-- [[ SPATIAL/FREE PLACEMENT OPERATIONS ]]

-- Converts a real-world CFrame into a saved coordinate relative to the plot's TOP surface
function Grid.worldToSpatial(worldCFrame: CFrame, plotCFrame: CFrame, plotSize: Vector3): CFrame
	local plotTopCFrame = plotCFrame * CFrame.new(0, plotSize.Y / 2, 0)
	return plotTopCFrame:ToObjectSpace(worldCFrame)
end

-- Converts a saved spatial coordinate back into a real-world CFrame for rendering
function Grid.spatialToWorld(relativeCFrame: CFrame, plotCFrame: CFrame, plotSize: Vector3): CFrame
	local plotTopCFrame = plotCFrame * CFrame.new(0, plotSize.Y / 2, 0)
	return plotTopCFrame:ToWorldSpace(relativeCFrame)
end

-- Validates that a free-placed item does not hang off the edge of the plot
function Grid.isSpatialInBounds(relativeCFrame: CFrame, itemSize: Vector3, plotSize: Vector3): boolean
	-- 1. Grab the rotational vectors of the item
	local right = relativeCFrame.RightVector
	local up = relativeCFrame.UpVector
	local look = relativeCFrame.LookVector

	local halfX = itemSize.X / 2
	local halfY = itemSize.Y / 2
	local halfZ = itemSize.Z / 2

	-- 2. Calculate the exact projected size on the Plot's X and Z axes based on its current rotation
	local extentX = math.abs(right.X) * halfX + math.abs(up.X) * halfY + math.abs(look.X) * halfZ
	local extentZ = math.abs(right.Z) * halfX + math.abs(up.Z) * halfY + math.abs(look.Z) * halfZ

	local posAbsX = math.abs(relativeCFrame.Position.X)
	local posAbsZ = math.abs(relativeCFrame.Position.Z)

	local plotHalfX = plotSize.X / 2
	local plotHalfZ = plotSize.Z / 2

	local xValid = (posAbsX + extentX) <= plotHalfX
	local zValid = (posAbsZ + extentZ) <= plotHalfZ

	-- 3. Log accurate failures
	-- local r = math.random() < 0.08
	if not (xValid and zValid) then
		-- if not xValid and r then
		-- 	warn(
		-- 		`[Grid.isSpatialInBounds] Placement Rejected: -> X-Axis Failed: (Position: {xAbs} + Radius: {maxRadius}) > Limit: {plotHalfX}`
		-- 	)
		-- end
		-- if not zValid and r then
		-- 	warn(
		-- 		`[Grid.isSpatialInBounds] Placement Rejected: -> Z-Axis Failed: (Position: {zAbs} + Radius: {maxRadius}) > Limit: {plotHalfZ}`
		-- 	)
		-- end
		return false
	end

	return true
end
return Grid
