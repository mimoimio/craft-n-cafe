-- ServerScriptService/Server/Services/PlacementService.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local Grid = require(ReplicatedStorage.Shared.Grid)
local Types = require(ReplicatedStorage.Shared.Types)
local Models = ReplicatedStorage.Shared.Models
local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)

local PlacementService = {}

function PlacementService.PlaceItem(player: Player, payload: Types.PlaceItemRemotePayload)
	local playerId = tostring(player.UserId)

	local prefab = Models:FindFirstChild(payload.itemId)
	if not prefab then
		warn(`Placement failed: Prefab '{payload.itemId}' does not exist.`)
		return
	end

	local config = PlaceablesModule.GetConfig(payload.itemId)
	if not config then
		warn(`Exploit prevented: Player {playerId} attempted to place an unconfigured item ({payload.itemId}).`)
		return
	end

	local state = GlobalState:getState()
	local playerInventory = state.Inventory and state.Inventory[playerId] or {}
	local plotState = state.Plot and state.Plot[playerId]

	if not plotState then
		return
	end

	local stock = playerInventory[payload.itemId] or 0
	if stock <= 0 then
		warn(`Placement failed: Player {playerId} has 0 {payload.itemId} in inventory.`)
		return
	end

	local placementType = prefab:GetAttribute("PlacementType") or "Grid"
	local plotSizeNum = plotState.plotSize
	local plotSize = Vector3.new(plotSizeNum, 1, plotSizeNum)

	if placementType == "Free" then
		if typeof(payload.cframe) ~= "CFrame" then
			return warn("Spatial Placement has no cframe")
		end

		local _, itemSize = Grid.getModelBounds(prefab)

		if not Grid.isSpatialInBounds(payload.cframe, itemSize, plotSize) then
			warn(`PlaceItem failed: Player {playerId} attempted to place {payload.itemId} outside plot bounds.`)
			return
		end

		local CafeRenderingService = require(script.Parent.CafeRenderingService)
		local playerbase = CafeRenderingService.getCafeBaseFromPlayerId(playerId)
		if not (playerbase and playerbase.Spatial) then
			return
		end
		local anchor = playerbase:FindFirstChild("Anchor")
		local plotCFrame = anchor and anchor.CFrame or CFrame.new(0, 0, 0)
		local worldCFrame = Grid.spatialToWorld(payload.cframe, plotCFrame, plotSize)

		local _, s = prefab:GetBoundingBox()
		s = Vector3.new(math.max(0, s.X - 0.2), math.max(0, s.Y - 0.2), math.max(0, s.Z - 0.2))

		local overlapparams = OverlapParams.new()
		overlapparams.FilterType = Enum.RaycastFilterType.Include
		overlapparams.FilterDescendantsInstances = { playerbase.Spatial }
		local parts = workspace:GetPartBoundsInBox(worldCFrame, s, overlapparams)
		if parts and #parts > 0 then
			return
		end

		local statePayload: Types.PlaceItemPayload = {
			itemId = payload.itemId,
			placementType = "Free",
			cframe = { payload.cframe:GetComponents() },
			parentUuid = payload.parentUuid or "Plot",
			primaryColor = payload.primaryColor,
			secondaryColor = payload.secondaryColor,
		}

		GlobalState.placeItem(playerId, statePayload)
	else
		local itemTypeAttr = prefab:GetAttribute("ItemType") or "Solid"
		local resolvedItemType = itemTypeAttr

		if itemTypeAttr == "Wall" then
			local isRotated = math.abs(payload.rotation % 180) == 90
			resolvedItemType = isRotated and "Wall_V" or "Wall_H"
		end

		local _, itemSize = Grid.getModelBounds(prefab)
		local width, length = Grid.getFootprint(itemSize, payload.rotation)

		if typeof(payload.startX) ~= "number" or typeof(payload.startZ) ~= "number" then
			return warn(`PlaceItem failed: not a number`)
		end

		local clampedX, clampedZ =
			Grid.clampToGrid(resolvedItemType, payload.startX, payload.startZ, width, length, plotSize)

		if payload.startX ~= clampedX or payload.startZ ~= clampedZ then
			warn(`Exploit prevented: Player {playerId} attempted to place {payload.itemId} outside grid bounds.`)
			return
		end

		if not Grid.isAreaFree(plotState, resolvedItemType, payload.startX, payload.startZ, width, length) then
			warn(`Exploit prevented: Player {playerId} attempted to place {payload.itemId} in an occupied space.`)
			return
		end

		local statePayload: Types.PlaceItemPayload = {
			itemId = payload.itemId,
			placementType = "Grid",
			itemType = resolvedItemType,
			startX = payload.startX,
			startZ = payload.startZ,
			width = width,
			length = length,
			rotation = payload.rotation,
			primaryColor = payload.primaryColor,
			secondaryColor = payload.secondaryColor,
		}

		GlobalState.placeItem(playerId, statePayload)
	end
end

function PlacementService.PaintItem(player: Player, payload: Types.PaintItemRemotePayload)
	local playerId = tostring(player.UserId)
	local state = GlobalState:getState()
	local plotState = state.Plot and state.Plot[playerId]
	if not plotState then
		return
	end

	-- Make sure they actually own this uuid before they can paint it!
	local isGridItem = plotState.placedItems[payload.uuid] ~= nil
	local isSpatialItem = plotState.spatialItems and plotState.spatialItems[payload.uuid] ~= nil

	if not isGridItem and not isSpatialItem then
		return
	end

	GlobalState.paintItem(playerId, payload)
end

function PlacementService.DestroyItem(player: Player, uuid: string)
	local playerId = tostring(player.UserId)

	local state = GlobalState:getState()
	local plotState = state.Plot and state.Plot[playerId]
	if not plotState then
		return
	end

	local item = plotState.placedItems[uuid] or plotState.spatialItems[uuid]
	if not item then
		return
	end

	if plotState.placedItems[uuid] and plotState.spatialItems then
		for childUuid, childItem in pairs(plotState.spatialItems) do
			if childItem.parentUuid == uuid then
				GlobalState.destroyItem(playerId, {
					uuid = childUuid,
					itemId = childItem.id,
				})
			end
		end
	end

	GlobalState.destroyItem(playerId, {
		uuid = uuid,
		itemId = item.id,
	})
end

PlacementService._connections = {}

function PlacementService.initialize()
	table.insert(PlacementService._connections, Remotes.PlaceItem.OnServerEvent:Connect(PlacementService.PlaceItem))
	table.insert(PlacementService._connections, Remotes.DestroyItem.OnServerEvent:Connect(PlacementService.DestroyItem))
	table.insert(PlacementService._connections, Remotes.PaintItem.OnServerEvent:Connect(PlacementService.PaintItem))
end

function PlacementService.cleanup()
	for _, conn in ipairs(PlacementService._connections) do
		conn:Disconnect()
	end
	table.clear(PlacementService._connections)
end

return PlacementService
