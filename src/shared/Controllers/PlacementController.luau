-- Shared/Controllers/PlacementController.luau
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Remotes = require(script.Parent.Parent.Remotes)
local GlobalState = require(script.Parent.Parent.producers.GlobalState)
local Grid = require(script.Parent.Parent.Grid)
local PlacementVisualizer = require(script.Parent.Parent.PlacementVisualizer)

local self = {}

function self.new(plotPart: Part, gridSize: number, itemPrefabsFolder: Folder)
	self.plot = plotPart
	self.gridSize = gridSize
	self.itemPrefabs = itemPrefabsFolder

	self.visualizer = nil
	self.buildModeActive = false
	self.currentItemId = nil
	self.rotation = 0

	return self
end

function self:setBuildMode(isActive: boolean)
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

function self:selectItem(itemId: string)
	if not self.buildModeActive then
		return
	end
	self.currentItemId = itemId

	local prefab = self.itemPrefabs:FindFirstChild(itemId)
	if self.visualizer then
		self.visualizer:setGhostItem(prefab)
	end
end

function self:rotateItem()
	self.rotation = (self.rotation + 90) % 360
end

function self:update(cursorWorldPos: Vector3)
	if not self.buildModeActive or not self.currentItemId or not self.visualizer then
		return
	end

	local prefab = self.itemPrefabs:FindFirstChild(self.currentItemId)
	if not prefab then
		return
	end
	local primary = prefab.PrimaryPart or prefab:FindFirstChildWhichIsA("BasePart")

	local plotCFrame, plotSize
	if typeof(self.plot) == "Instance" and self.plot:IsA("Model") then
		plotCFrame, plotSize = self.plot:GetBoundingBox()
	else
		plotCFrame, plotSize = self.plot.CFrame, self.plot.Size
	end

	local width, length = Grid.getFootprint(primary.Size, self.gridSize, self.rotation)
	local rawGridX, rawGridZ = Grid.worldToGrid(cursorWorldPos, plotCFrame, self.gridSize, primary.Size, self.rotation)
	local gridX, gridZ = Grid.clampToGrid(rawGridX, rawGridZ, width, length, plotSize, self.gridSize)

	-- Fetch state from Reflex instead of local OOP
	local playerId = Players.LocalPlayer and tostring(Players.LocalPlayer.UserId) or "MockUser"
	local state = GlobalState:getState()
	local plotState = state.Plot and state.Plot[playerId]

	local isFree = Grid.isAreaFree(plotState, gridX, gridZ, width, length)
	local targetCFrame =
		Grid.gridToWorld(gridX, gridZ, plotCFrame, plotSize, self.gridSize, primary.Size, self.rotation)

	self.visualizer:updateGhost(targetCFrame, isFree)
end

function self:placeItem(cursorWorldPos: Vector3)
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

	local width, length = Grid.getFootprint(primary.Size, self.gridSize, self.rotation)
	local rawGridX, rawGridZ = Grid.worldToGrid(cursorWorldPos, plotCFrame, self.gridSize, primary.Size, self.rotation)
	local gridX, gridZ = Grid.clampToGrid(rawGridX, rawGridZ, width, length, plotSize, self.gridSize)

	local playerId = Players.LocalPlayer and tostring(Players.LocalPlayer.UserId) or "MockUser"
	local state = GlobalState:getState()
	local plotState = state.Plot and state.Plot[playerId]

	if Grid.isAreaFree(plotState, gridX, gridZ, width, length) then
		local uuid = HttpService:GenerateGUID(false)

		Remotes.PlaceItem:FireServer(uuid, self.currentItemId, gridX, gridZ, width, length, self.rotation)

		return true, uuid
	end
	return false, nil
end

function self:destroyItem(uuid: string)
	Remotes.DestroyItem:FireServer(uuid)
	return true
end

return self
