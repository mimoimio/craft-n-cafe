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
local PaintUtil = require(ReplicatedStorage.Shared.Utils.PaintUtil)

local self = {}

function self.new(plotPart: Part, itemPrefabsFolder: Folder)
	self.plot = plotPart
	self.itemPrefabs = itemPrefabsFolder

	self.visualizer = nil
	self.buildModeActive = false
	self.deleteModeActive = false
	self.paintModeActive = false
	self.currentItemId = nil
	self.rotation = 0

	self.primaryColor = nil
	self.secondaryColor = nil

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
	self.paintModeActive = false

	if isActive then
		self.deleteHighlight.FillColor = Color3.new(1, 0, 0)
		self.deleteHighlight.OutlineColor = Color3.new(1, 0, 0)
		self.currentItemId = nil
		if self.visualizer then
			self.visualizer:setGhostItem(nil)
		end
	else
		self.hoveredUuid = nil
		self.deleteHighlight.Parent = nil
	end
end

function self:setPaintMode(isActive: boolean)
	if not self.initialized then
		return
	end
	self.paintModeActive = isActive
	self.deleteModeActive = false

	if isActive then
		self.deleteHighlight.FillColor = Color3.new(0, 0.5, 1) -- Blue highlight for painting
		self.deleteHighlight.OutlineColor = Color3.new(0, 0.5, 1)
		self.currentItemId = nil
		if self.visualizer then
			self.visualizer:setGhostItem(nil)
		end
	else
		self.hoveredUuid = nil
		self.deleteHighlight.Parent = nil
	end
end

function self:setPaintColors(primary: string?, secondary: string?)
	self.primaryColor = primary
	self.secondaryColor = secondary

	-- Apply colors to the ghost item in real time if placing
	if self.visualizer and self.visualizer.ghostModel then
		PaintUtil.ApplyColors(self.visualizer.ghostModel, self.primaryColor, self.secondaryColor)
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

function self:selectItem(itemId: string?)
	if not self.initialized or not self.buildModeActive then
		return
	end
	self.currentItemId = itemId

	local prefab = nil
	if itemId then
		prefab = self.itemPrefabs:FindFirstChild(itemId)
	end

	if self.visualizer then
		self.visualizer:setGhostItem(prefab)

		-- Make sure the newly swapped ghost item receives our current colors
		if self.visualizer.ghostModel then
			PaintUtil.ApplyColors(self.visualizer.ghostModel, self.primaryColor, self.secondaryColor)
		end
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

	-- [[ DELETE & PAINT MODE HOVER LOGIC ]]
	if self.deleteModeActive or self.paintModeActive then
		local baseModel = self.plot.Parent
		local hoveredUuid = InputAdapter.getHoveredItemUuid(baseModel)

		if hoveredUuid and self.hoveredUuid ~= hoveredUuid then
			self.hoveredUuid = hoveredUuid
			for _, child in baseModel.Grid:GetChildren() do
				if child:GetAttribute("Uuid") == hoveredUuid then
					self.deleteHighlight.Parent = child
					return
				end
			end
			for _, child in baseModel.Spatial:GetChildren() do
				if child:GetAttribute("Uuid") == hoveredUuid then
					self.deleteHighlight.Parent = child
					return
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
		local ignoreList = self.visualizer.ghostModel and { self.visualizer.ghostModel } or {}
		local rayResult = InputAdapter.getSpatialRaycast(self.plot.Parent, ignoreList)

		if rayResult then
			local hitPos = rayResult.Position
			local normal = rayResult.Normal

			if math.abs(normal.Y) > 0.99 then
				targetCFrame = CFrame.new(hitPos + normal * (itemSize.Y / 2))
					* CFrame.Angles(0, math.rad(self.rotation), 0)
			else
				targetCFrame = CFrame.lookAt(hitPos + normal * (itemSize.Z / 2), hitPos + normal * 2)
			end

			local relativeCFrame = Grid.worldToSpatial(targetCFrame, plotCFrame, plotSize)
			isFree = Grid.isSpatialInBounds(relativeCFrame, itemSize, plotSize)

			if isFree then
				local _, s = prefab:GetBoundingBox()
				s = Vector3.new(math.max(0, s.X - 0.2), math.max(0, s.Y - 0.2), math.max(0, s.Z - 0.2))
				local overlapparams = OverlapParams.new()
				overlapparams.FilterType = Enum.RaycastFilterType.Include
				overlapparams.FilterDescendantsInstances = { self.plot.Parent.Spatial }
				local parts = workspace:GetPartBoundsInBox(targetCFrame, s, overlapparams)
				if parts and #parts > 0 then
					isFree = false
				end
			end
		else
			targetCFrame = self.plot.CFrame * CFrame.new(0, -100, 0)
			isFree = false
		end
	else
		if itemTypeAttr == "Wall" then
			resolvedItemType, rawGridX, rawGridZ = Grid.worldToEdge(cursorWorldPos, plotCFrame, finalRotation)
		else
			resolvedItemType = itemTypeAttr
			rawGridX, rawGridZ = Grid.worldToSolid(cursorWorldPos, plotCFrame, itemSize, finalRotation)
		end

		local width, length = Grid.getFootprint(itemSize, finalRotation)
		local rawX, rawZ = Grid.getFootprint(itemSize, 0)

		local dummyY = itemSize.Y
		local mathItemType = resolvedItemType

		if itemTypeAttr == "Roof" then
			dummyY = itemSize.Y + Grid.WALL_HEIGHT
			mathItemType = "Solid"
		end

		local snappedSize = Vector3.new(rawX * Grid.SIZE, dummyY, rawZ * Grid.SIZE)

		local gridX, gridZ = Grid.clampToGrid(resolvedItemType, rawGridX, rawGridZ, width, length, plotSize)

		local playerId = Players.LocalPlayer and tostring(Players.LocalPlayer.UserId) or "MockUser"
		local state = GlobalState:getState()
		local plotState = state.Plot and state.Plot[playerId]

		isFree = Grid.isAreaFree(plotState, resolvedItemType, gridX, gridZ, width, length)

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

		local relativeCFrame = Grid.worldToSpatial(targetCFrame, plotCFrame, plotSize)
		local isWithinBounds = Grid.isSpatialInBounds(relativeCFrame, itemSize, plotSize)

		if not isWithinBounds then
			return false
		end

		Remotes.PlaceItem:FireServer({
			itemId = self.currentItemId,
			placementType = "Free",
			cframe = relativeCFrame,
			parentUuid = hitUuid,
			primaryColor = self.primaryColor,
			secondaryColor = self.secondaryColor,
		})
		return true
	else
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
				primaryColor = self.primaryColor,
				secondaryColor = self.secondaryColor,
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

	local targetElevation = nil
	if self.currentItemId then
		local prefab = self.itemPrefabs:FindFirstChild(self.currentItemId)
		if prefab and prefab:GetAttribute("ItemType") == "Roof" then
			targetElevation = Grid.WALL_HEIGHT
		end
	end

	local hitPos = InputAdapter.getCursorWorldPosition(self.plot, targetElevation)
	local success, uuid = self:placeItem(hitPos)
	return success
end

function self:attemptPaintAtCursor()
	if not self.initialized or not self.plot then
		return false
	end

	local baseModel = self.plot.Parent
	local hoveredUuid = InputAdapter.getHoveredItemUuid(baseModel)

	if hoveredUuid then
		Remotes.PaintItem:FireServer({
			uuid = hoveredUuid,
			primaryColor = self.primaryColor,
			secondaryColor = self.secondaryColor,
		})
		return true
	end
	return false
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
	self.initializePromise = Promise.new(function(resolve, reject, onCancel)
		local currentState = UIState:getState()
		if currentState.cafeBase then
			resolve(currentState.cafeBase)
			return
		end

		local waitPromise = UIState:wait(function(state: UIState.UIState)
			return state.cafeBase
		end, function(cafeBase)
			if cafeBase then
				resolve(cafeBase)
				return true
			end
			return false
		end)

		onCancel(function()
			if waitPromise.cancel then
				waitPromise:cancel()
			end
		end)
	end)
		:andThen(function(cafeBase)
			local initialPart = cafeBase:FindFirstChild("Part")

			if not initialPart then
				initialPart = cafeBase:WaitForChild("Part", 10)
			end

			if not initialPart then
				warn("[PlacementController] FATAL: 'Part' never loaded.")
				return
			end

			self.new(initialPart, ReplicatedStorage.Shared.Models)

			self.partAddedConn = cafeBase.ChildAdded:Connect(function(child)
				if child.Name == "Part" and child:IsA("BasePart") then
					self.plot = child
					if self.visualizer then
						self.visualizer.plot = child
					end
				end
			end)

			self.connection = RunService.RenderStepped:Connect(function()
				if not self.plot then
					return
				end

				local targetElevation = nil
				if self.currentItemId then
					local prefab = self.itemPrefabs:FindFirstChild(self.currentItemId)
					if prefab and prefab:GetAttribute("ItemType") == "Roof" then
						targetElevation = Grid.WALL_HEIGHT
					end
				end

				local hitPos = InputAdapter.getCursorWorldPosition(self.plot, targetElevation)
				self:update(hitPos)
			end)

			self.inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if gameProcessed or not self.plot then
					return
				end

				if input.KeyCode == Enum.KeyCode.R then
					self:rotateItem()
				elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
					if self.deleteModeActive then
						self:attemptDestroyAtCursor()
					elseif self.paintModeActive then
						self:attemptPaintAtCursor()
					else
						local targetElevation = nil
						if self.currentItemId then
							local prefab = self.itemPrefabs:FindFirstChild(self.currentItemId)
							if prefab and prefab:GetAttribute("ItemType") == "Roof" then
								targetElevation = Grid.WALL_HEIGHT
							end
						end

						local hitPos = InputAdapter.getCursorWorldPosition(self.plot, targetElevation)
						self:placeItem(hitPos)
					end
				end
			end)
		end)
		:catch(function(err)
			warn("[PlacementController] Initialization failed:", err)
		end)
end

function self.cleanup()
	if self.initializePromise then
		self.initializePromise:cancel()
	end
	if self.connection then
		self.connection:Disconnect()
	end
	if self.inputConnection then
		self.inputConnection:Disconnect()
	end
	if self.highlightConn then
		self.highlightConn:Disconnect()
	end
	if self.partAddedConn then
		self.partAddedConn:Disconnect()
	end
end

return self
