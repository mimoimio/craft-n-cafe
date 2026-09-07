-- PlacementController.luau
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")

local GridMath = require(script.Parent.Parent.GridMath)
local GridState = require(script.Parent.Parent.GridState)
local PlacementVisualizer = require(script.Parent.Parent.PlacementVisualizer)

local PlacementController = {}
PlacementController.__index = PlacementController

function PlacementController.new(plotPart: Part, gridSize: number, itemPrefabsFolder: Folder)
	local self = setmetatable({}, PlacementController)

	self.plot = plotPart
	self.gridSize = gridSize
	self.itemPrefabs = itemPrefabsFolder

	self.state = GridState.new()
	self.visualizer = nil

	self.buildModeActive = false
	self.currentItemId = nil
	self.rotation = 0

	-- Cached plot grid dimensions
	self.plotGridWidth = math.floor(plotPart.Size.X / gridSize)
	self.plotGridLength = math.floor(plotPart.Size.Z / gridSize)

	return self
end

-- Use Case 1: Toggle Build Mode
function PlacementController:setBuildMode(isActive: boolean)
	self.buildModeActive = isActive

	if isActive then
		if not self.visualizer then
			self.visualizer = PlacementVisualizer.new(self.plot, self.gridSize)
		end
	else
		if self.visualizer then
			self.visualizer:destroy()
			self.visualizer = nil
		end
		self.currentItemId = nil
	end
end
function PlacementController:selectItem(itemId: string)
	if not self.buildModeActive then
		return
	end
	self.currentItemId = itemId

	local prefab = self.itemPrefabs:FindFirstChild(itemId)
	if self.visualizer then
		self.visualizer:setGhostItem(prefab)
	end
end

function PlacementController:rotateItem()
	self.rotation = (self.rotation + 90) % 360
end

-- Render loop
function PlacementController:update(cursorWorldPos: Vector3)
	if not self.buildModeActive or not self.currentItemId or not self.visualizer then
		return
	end

	local prefab = self.itemPrefabs:FindFirstChild(self.currentItemId)
	if not prefab then
		return
	end
	local primary = prefab.PrimaryPart or prefab:FindFirstChildWhichIsA("BasePart")

	-- Dynamically fetch CFrame and Size to support Models (CafeBase) and Parts (Baseplate)
	local plotCFrame, plotSize
	if typeof(self.plot) == "Instance" and self.plot:IsA("Model") then
		plotCFrame, plotSize = self.plot:GetBoundingBox()
	else
		plotCFrame, plotSize = self.plot.CFrame, self.plot.Size
	end

	local width, length = GridMath.getFootprint(primary.Size, self.gridSize, self.rotation)
	local rawGridX, rawGridZ =
		GridMath.worldToGrid(cursorWorldPos, plotCFrame, self.gridSize, primary.Size, self.rotation)
	local gridX, gridZ = GridMath.clampToGrid(rawGridX, rawGridZ, width, length, plotSize, self.gridSize)

	local isFree = self.state:isAreaFree(gridX, gridZ, width, length)
	local targetCFrame =
		GridMath.gridToWorld(gridX, gridZ, plotCFrame, plotSize, self.gridSize, primary.Size, self.rotation)

	self.visualizer:updateGhost(targetCFrame, isFree)
end
-- Use Case 2: Place Item
function PlacementController:placeItem(cursorWorldPos: Vector3)
	if not self.buildModeActive or not self.currentItemId then
		return false, nil
	end

	local prefab = self.itemPrefabs:FindFirstChild(self.currentItemId)
	local primary = prefab.PrimaryPart or prefab:FindFirstChildWhichIsA("BasePart")

	local plotCFrame, plotSize
	if typeof(self.plot) == "Instance" and self.plot:IsA("Model") then
		plotCFrame, plotSize = self.plot:GetBoundingBox()
	else
		plotCFrame, plotSize = self.plot.CFrame, self.plot.Size
	end

	local width, length = GridMath.getFootprint(primary.Size, self.gridSize, self.rotation)
	local rawGridX, rawGridZ =
		GridMath.worldToGrid(cursorWorldPos, plotCFrame, self.gridSize, primary.Size, self.rotation)
	local gridX, gridZ = GridMath.clampToGrid(rawGridX, rawGridZ, width, length, plotSize, self.gridSize)

	if self.state:isAreaFree(gridX, gridZ, width, length) then
		local uuid = HttpService:GenerateGUID(false)
		local success = self.state:occupy(uuid, self.currentItemId, gridX, gridZ, width, length)

		if success then
			local placedModel = prefab:Clone()
			placedModel:PivotTo(
				GridMath.gridToWorld(gridX, gridZ, plotCFrame, plotSize, self.gridSize, primary.Size, self.rotation)
			)
			placedModel.Parent = workspace

			return true, uuid
		end
	end
	return false, nil
end

-- Use Case 3: Destroy Item
function PlacementController:destroyItem(uuid: string)
	local success = self.state:free(uuid)
	if success then
		-- Later: Find the physical model associated with UUID and destroy it
		return true
	end
	return false
end

return PlacementController
