-- ServerScriptService/Server/Services/PlacementService.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local Grid = require(ReplicatedStorage.Shared.Grid)
local Types = require(ReplicatedStorage.Shared.Types)
local Models = ReplicatedStorage.Shared.Models
local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule) -- NEW REQUIRE

local PlacementService = {}

function PlacementService.PlaceItem(player: Player, payload: Types.PlaceItemRemotePayload)
	local playerId = tostring(player.UserId)

	local prefab = Models:FindFirstChild(payload.itemId)
	if not prefab then
		warn(`Placement failed: Prefab '{payload.itemId}' does not exist.`)
		return
	end

	-- [[ 1. INVENTORY GUARD ]]
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

	-- Check if they actually have this item in their inventory!
	local stock = playerInventory[payload.itemId] or 0
	if stock <= 0 then
		warn(`Placement failed: Player {playerId} has 0 {payload.itemId} in inventory.`)
		return
	end

	-- [[ 2. SPATIAL & GRID GUARDS ]]
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
		-- 1. Get the Anchor's World CFrame
		local anchor = playerbase:FindFirstChild("Anchor")
		local plotCFrame = anchor and anchor.CFrame or CFrame.new(0, 0, 0)
		-- 2. Convert the relative payload CFrame back to World Space
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

		-- Serialize to the State Payload
		local statePayload: Types.PlaceItemPayload = {
			itemId = payload.itemId,
			placementType = "Free",
			cframe = { payload.cframe:GetComponents() },
			parentUuid = payload.parentUuid or "Plot",
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

		-- Bounds Check
		local clampedX, clampedZ =
			Grid.clampToGrid(resolvedItemType, payload.startX, payload.startZ, width, length, plotSize)

		if payload.startX ~= clampedX or payload.startZ ~= clampedZ then
			warn(`Exploit prevented: Player {playerId} attempted to place {payload.itemId} outside grid bounds.`)
			return
		end

		-- Collision Check
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
		}

		GlobalState.placeItem(playerId, statePayload)
	end
end

function PlacementService.DestroyItem(player: Player, uuid: string)
	local playerId = tostring(player.UserId)

	local state = GlobalState:getState()
	local plotState = state.Plot and state.Plot[playerId]
	if not plotState then
		return
	end

	-- 1. Find the target item
	local item = plotState.placedItems[uuid] or plotState.spatialItems[uuid]
	if not item then
		return
	end

	-- 2. CASCADE REFUND: Find any child items sitting on this parent and refund them FIRST
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

	-- 3. Finally, destroy and refund the parent item itself
	GlobalState.destroyItem(playerId, {
		uuid = uuid,
		itemId = item.id,
	})
end
function PlacementService.initialize()
	Remotes.PlaceItem.OnServerEvent:Connect(PlacementService.PlaceItem)
	Remotes.DestroyItem.OnServerEvent:Connect(PlacementService.DestroyItem)
end

return PlacementService
