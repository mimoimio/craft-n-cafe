-- Shared/Controllers/PlacementController.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local Remotes = require(script.Parent.Parent.Remotes)
local Promise = require(script.Parent.Parent.Parent.Packages.Promise)
local UIState = require(script.Parent.Parent.producers.UIState)
local GlobalState = require(script.Parent.Parent.producers.GlobalState)
local Grid = require(script.Parent.Parent.Grid)
local InputAdapter = require(ReplicatedStorage.Shared.Controllers.InputAdapter)
local PlacementVisualizer = require(script.Parent.Parent.PlacementVisualizer)

local self = {}

function self.new(plotPart: Part, itemPrefabsFolder: Folder)
	self.plot = plotPart
	self.itemPrefabs = itemPrefabsFolder

	self.visualizer = nil
	self.buildModeActive = false
	self.deleteModeActive = false
	self.currentItemId = nil
	self.rotation = 0

	self.hoveredUuid = nil
	local newHighlight
	newHighlight = function()
		if self.highlightConn then
			self.highlightConn:Disconnect()
		end
		self.deleteHighlight = Instance.new("Highlight")
		self.deleteHighlight.FillColor = Color3.new(1, 0, 0)
		self.deleteHighlight.FillTransparency = 0.5
		self.deleteHighlight.OutlineColor = Color3.new(1, 0, 0)
		self.highlightConn = self.deleteHighlight.Destroying:Connect(newHighlight)
	end
	newHighlight()

	self.initialized = true
	return self
end

function self:setDeleteMode(isActive: boolean)
	if not self.initialized then
		return
	end

	self.deleteModeActive = isActive
	if isActive then
		self.currentItemId = nil
		if self.visualizer then
			self.visualizer:setGhostItem(nil)
		end
	else
		self.hoveredUuid = nil
		self.deleteHighlight.Parent = nil
	end
end

function self:setBuildMode(isActive: boolean)
	if not self.initialized then
		return
	end
	self.buildModeActive = isActive

	if isActive then
		if not self.visualizer then
			self.visualizer = PlacementVisualizer.new(self.plot, Grid.SIZE)
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
	if not self.initialized or not self.buildModeActive then
		return
	end
	self.currentItemId = itemId

	local prefab = self.itemPrefabs:FindFirstChild(itemId)
	if self.visualizer then
		self.visualizer:setGhostItem(prefab)
	end
end

function self:rotateItem()
	if not self.initialized then
		return
	end
	self.rotation = (self.rotation + 90) % 360
end

function self:update(cursorWorldPos: Vector3)
	if not self.initialized or not self.buildModeActive then
		return
	end

	-- [[ DELETE MODE HOVER LOGIC ]]
	if self.deleteModeActive then
		local baseModel = self.plot.Parent
		local hoveredUuid = InputAdapter.getHoveredItemUuid(baseModel)

		if hoveredUuid and self.hoveredUuid ~= hoveredUuid then
			self.hoveredUuid = hoveredUuid
			for _, child in baseModel:GetChildren() do
				if child:GetAttribute("Uuid") == hoveredUuid then
					self.deleteHighlight.Parent = child
					break
				end
			end
		elseif not hoveredUuid then
			self.hoveredUuid = nil
			self.deleteHighlight.Parent = nil
		end
		return
	end

	-- [[ NORMAL PLACEMENT LOGIC ]]
	if not self.buildModeActive or not self.currentItemId or not self.visualizer then
		return
	end

	local prefab = self.itemPrefabs:FindFirstChild(self.currentItemId)
	if not prefab then
		return
	end

	local placementType = prefab:GetAttribute("PlacementType") or "Grid"
	local itemTypeAttr = prefab:GetAttribute("ItemType") or "Solid"

	local _, itemSize = Grid.getModelBounds(prefab)
	local plotCFrame, plotSize = self.plot.CFrame, self.plot.Size

	local resolvedItemType = "Solid"
	local finalRotation = self.rotation
	local rawGridX, rawGridZ

	local targetCFrame
	local isFree = false
	local hitUuid = nil

	if placementType == "Free" then
		-- [[ SPATIAL PLACEMENT LOGIC ]]
		local ignoreList = self.visualizer.ghostModel and { self.visualizer.ghostModel } or {}
		local rayResult = InputAdapter.getSpatialRaycast(self.plot.Parent, ignoreList)

		if rayResult then
			local hitPos = rayResult.Position
			local normal = rayResult.Normal

			local hitModel = rayResult.Instance:FindFirstAncestorWhichIsA("Model")
			hitUuid = hitModel and hitModel:GetAttribute("Uuid") or "Plot"

			if math.abs(normal.Y) > 0.99 then
				targetCFrame = CFrame.new(hitPos + normal * (itemSize.Y / 2))
					* CFrame.Angles(0, math.rad(self.rotation), 0)
			else
				targetCFrame = CFrame.lookAt(hitPos + normal * (itemSize.Z / 2), hitPos + normal * 2)
			end

			local relativeCFrame = plotCFrame:ToObjectSpace(targetCFrame)
			local maxRadius = math.max(itemSize.X, itemSize.Z) / 2

			local isWithinBounds = math.abs(relativeCFrame.X) + maxRadius <= (plotSize.X / 2)
				and math.abs(relativeCFrame.Z) + maxRadius <= (plotSize.Z / 2)

			isFree = isWithinBounds
		else
			targetCFrame = self.plot.CFrame * CFrame.new(0, -100, 0)
			isFree = false
		end
	else
		-- [[ EXISTING GRID LOGIC ]]
		if itemTypeAttr == "Wall" then
			resolvedItemType, rawGridX, rawGridZ = Grid.worldToEdge(cursorWorldPos, plotCFrame, finalRotation)
		else
			resolvedItemType = itemTypeAttr
			rawGridX, rawGridZ = Grid.worldToSolid(cursorWorldPos, plotCFrame, itemSize, finalRotation)
		end

		local width, length = Grid.getFootprint(itemSize, finalRotation)
		local rawX, rawZ = Grid.getFootprint(itemSize, 0)

		-- FIX: Use the SNAPPED footprint for X and Z, just like PlacedItemNode!
		local dummyY = itemSize.Y
		local mathItemType = resolvedItemType

		if itemTypeAttr == "Roof" then
			dummyY = itemSize.Y + Grid.WALL_HEIGHT
			mathItemType = "Solid" -- Prevent gridToWorld from double-elevating the ghost
		end

		local snappedSize = Vector3.new(rawX * Grid.SIZE, dummyY, rawZ * Grid.SIZE)

		local gridX, gridZ = Grid.clampToGrid(resolvedItemType, rawGridX, rawGridZ, width, length, plotSize)

		local playerId = Players.LocalPlayer and tostring(Players.LocalPlayer.UserId) or "MockUser"
		local state = GlobalState:getState()
		local plotState = state.Plot and state.Plot[playerId]

		isFree = Grid.isAreaFree(plotState, resolvedItemType, gridX, gridZ, width, length)

		-- Pass snappedSize instead of visualItemSize
		targetCFrame = Grid.gridToWorld(mathItemType, gridX, gridZ, plotCFrame, plotSize, snappedSize, finalRotation)
	end
	self.visualizer:updateGhost(targetCFrame, isFree)
end

function self:placeItem(cursorWorldPos: Vector3)
	if not self.initialized or not self.buildModeActive or not self.currentItemId then
		return false
	end

	local prefab = self.itemPrefabs:FindFirstChild(self.currentItemId)
	local placementType = prefab:GetAttribute("PlacementType") or "Grid"
	local itemTypeAttr = prefab:GetAttribute("ItemType") or "Solid"

	local _, itemSize = Grid.getModelBounds(prefab)
	local plotCFrame, plotSize = self.plot.CFrame, self.plot.Size

	local playerId = Players.LocalPlayer and tostring(Players.LocalPlayer.UserId) or "MockUser"
	local state = GlobalState:getState()
	local plotState = state.Plot and state.Plot[playerId]

	if placementType == "Free" then
		-- [[ SPATIAL PLACEMENT LOGIC ]]
		local ignoreList = self.visualizer and self.visualizer.ghostModel and { self.visualizer.ghostModel } or {}
		if Players.LocalPlayer and Players.LocalPlayer.Character then
			table.insert(ignoreList, Players.LocalPlayer.Character)
		end

		local rayResult = InputAdapter.getSpatialRaycast(self.plot.Parent, ignoreList)
		if not rayResult then
			return false
		end

		local hitPos = rayResult.Position
		local normal = rayResult.Normal
		local targetCFrame

		if math.abs(normal.Y) > 0.99 then
			targetCFrame = CFrame.new(hitPos + normal * (itemSize.Y / 2)) * CFrame.Angles(0, math.rad(self.rotation), 0)
		else
			targetCFrame = CFrame.lookAt(hitPos + normal * (itemSize.Z / 2), hitPos + normal * 2)
		end

		local hitModel = rayResult.Instance:FindFirstAncestorWhichIsA("Model")
		local hitUuid = hitModel and hitModel:GetAttribute("Uuid") or "Plot"

		local relativeCFrame = plotCFrame:ToObjectSpace(targetCFrame)
		local maxRadius = math.max(itemSize.X, itemSize.Z) / 2
		local isWithinBounds = math.abs(relativeCFrame.X) + maxRadius <= (plotSize.X / 2)
			and math.abs(relativeCFrame.Z) + maxRadius <= (plotSize.Z / 2)

		if not isWithinBounds then
			return false
		end

		Remotes.PlaceItem:FireServer({
			itemId = self.currentItemId,
			placementType = "Free",
			cframe = relativeCFrame,
			parentUuid = hitUuid,
		})
		return true
	else
		-- [[ EXISTING GRID LOGIC ]]
		local resolvedItemType = "Solid"
		local finalRotation = self.rotation
		local rawGridX, rawGridZ

		if itemTypeAttr == "Wall" then
			resolvedItemType, rawGridX, rawGridZ = Grid.worldToEdge(cursorWorldPos, plotCFrame, finalRotation)
		else
			resolvedItemType = itemTypeAttr
			rawGridX, rawGridZ = Grid.worldToSolid(cursorWorldPos, plotCFrame, itemSize, finalRotation)
		end

		local width, length = Grid.getFootprint(itemSize, finalRotation)
		local gridX, gridZ = Grid.clampToGrid(resolvedItemType, rawGridX, rawGridZ, width, length, plotSize)

		if Grid.isAreaFree(plotState, resolvedItemType, gridX, gridZ, width, length) then
			Remotes.PlaceItem:FireServer({
				itemId = self.currentItemId,
				placementType = "Grid",
				itemType = resolvedItemType,
				startX = gridX,
				startZ = gridZ,
				width = width,
				length = length,
				rotation = finalRotation,
			})
			return true
		end
	end

	return false
end

function self:placeCurrent()
	if not self.initialized or not self.plot or not self.buildModeActive then
		return false
	end
	local hitPos = InputAdapter.getCursorWorldPosition(self.plot)
	local success, uuid = self:placeItem(hitPos)
	if success then
		print("Successfully placed item with UUID:", uuid)
	end
	return success
end

function self:destroyItem(uuid: string)
	if not self.initialized then
		return
	end
	Remotes.DestroyItem:FireServer(uuid)
	return true
end

function self:attemptDestroyAtCursor()
	if not self.initialized or not self.plot then
		return false
	end
	local baseModel = self.plot.Parent
	local hoveredUuid = InputAdapter.getHoveredItemUuid(baseModel)

	if hoveredUuid then
		self:destroyItem(hoveredUuid)
		self.hoveredUuid = nil
		self.deleteHighlight.Parent = nil
		return true
	end
	return false
end

function self.initialize()
	self.initializePromise = Promise.defer(function(resolve, reject, onCancel)
		local playersPlot = UIState:getState().cafeBase or nil
		if playersPlot then
			resolve(playersPlot)
		end
		local waitPromise = UIState:wait(function(state: UIState.UIState)
			return state.cafeBase
		end, function(cafeBase)
			local found = cafeBase and true or false
			if found then
				resolve(cafeBase)
			end
			return found
		end)
			:timeout(10)
			:catch(function(err)
				warn("Error waiting cafeBase.Part:", err)
			end)
			:await()
	end)
		:andThen(function(cafeBase)
			warn("initialized controller")
			self.new(cafeBase.Part, ReplicatedStorage.Shared.Models)

			self.connection = RunService.RenderStepped:Connect(function()
				local hitPos = InputAdapter.getCursorWorldPosition(cafeBase.Part)
				self:update(hitPos)
			end)

			self.inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if gameProcessed then
					return
				end

				if input.KeyCode == Enum.KeyCode.R then
					self:rotateItem()
				elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
					if self.deleteModeActive then
						self:attemptDestroyAtCursor()
					else
						local hitPos = InputAdapter.getCursorWorldPosition(cafeBase.Part)
						self:placeItem(hitPos)
					end
				end
			end)
		end)
		:catch(function(err)
			warn("PlacementController error:", err)
		end)
end

function self.cleanup()
	self.initializePromise:cancel()
	if self.connection then
		self.connection:Disconnect()
	end
	if self.inputConnection then
		self.inputConnection:Disconnect()
	end
	if self.highlightConn then
		self.highlightConn:Disconnect()
	end
end

return self
