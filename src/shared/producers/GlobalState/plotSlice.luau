-- Shared/producers/GlobalState/plotSlice.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Types = require(ReplicatedStorage.Shared.Types)
local Grid = require(ReplicatedStorage.Shared.Grid)

local Dictionary = Sift.Dictionary
local Merge = Dictionary.merge
local Set = Dictionary.set
local RemoveKey = Dictionary.removeKey

export type PlotState = Types.PlotState

local initialState: { [string]: PlotState } = {}

local actions = {
	startPlayerSession = function(state: { [string]: PlotState }, playerId: string, data: Types.PlayerData)
		-- Initialize with the new unified architecture including spatialItems
		local defaultPlot = { grid = {}, placedItems = {}, spatialItems = {}, nextId = 1 }
		return Set(state, playerId, data.Plot or defaultPlot)
	end,

	endPlayerSession = function(state: { [string]: PlotState }, playerId: string)
		return RemoveKey(state, playerId)
	end,

	placeItem = function(state: { [string]: PlotState }, playerId: string, payload: Types.PlaceItemPayload)
		local playerPlot = state[playerId] or { grid = {}, placedItems = {}, spatialItems = {}, nextId = 1 }
		local generatedUuid = tostring(playerPlot.nextId)

		local nextPlayerPlot = Dictionary.copy(playerPlot)
		nextPlayerPlot.nextId = playerPlot.nextId + 1

		if payload.placementType == "Free" then
			-- [[ SPATIAL PLACEMENT LOGIC ]]
			local newItem: Types.SpatialItem = {
				id = payload.itemId,
				parentUuid = payload.parentUuid or "Plot",
				cframe = payload.cframe,
			}

			nextPlayerPlot.spatialItems = Set(playerPlot.spatialItems or {}, generatedUuid, newItem)
		else
			-- [[ HALF-GRID PLACEMENT LOGIC ]]
			local newGrid = Dictionary.copy(playerPlot.grid)

			-- UPDATED: Treat Floor/Roof as Solid for footprint calculation
			local mappedType = (payload.itemType == "Floor" or payload.itemType == "Roof") and "Solid"
				or payload.itemType
			local startX, endX, startZ, endZ =
				Grid.getHalfGridBounds(mappedType, payload.startX, payload.startZ, payload.width, payload.length)

			-- NEW: Fetch the specific collision layer
			local layer = Grid.getLayer(payload.itemType)

			for hx = startX, endX do
				for hz = startZ, endZ do
					-- WRITE WITH LAYER PREFIX
					newGrid[`{layer}_{hx}_{hz}`] = generatedUuid
				end
			end

			local newItem: Types.PlacedItem = {
				id = payload.itemId,
				itemType = payload.itemType,
				x = payload.startX,
				z = payload.startZ,
				w = payload.width,
				l = payload.length,
				r = payload.rotation,
			}

			nextPlayerPlot.grid = newGrid
			nextPlayerPlot.placedItems = Set(playerPlot.placedItems, generatedUuid, newItem)
		end

		return Set(state, playerId, nextPlayerPlot)
	end,

	destroyItem = function(state: { [string]: PlotState }, playerId: string, payload: Types.DestroyItemPayload)
		local playerPlot = state[playerId]
		if not playerPlot then
			return state
		end

		local uuid = payload.uuid
		local isGridItem = playerPlot.placedItems[uuid] ~= nil
		local isSpatialItem = playerPlot.spatialItems and playerPlot.spatialItems[uuid] ~= nil

		if not isGridItem and not isSpatialItem then
			return state
		end

		local nextPlayerPlot = Dictionary.copy(playerPlot)

		if isGridItem then
			local itemData = playerPlot.placedItems[uuid]

			-- 1. Free up the Half-Grid memory
			local newGrid = Dictionary.copy(playerPlot.grid)

			-- UPDATED: Treat Floor/Roof as Solid for footprint calculation
			local mappedType = (itemData.itemType == "Floor" or itemData.itemType == "Roof") and "Solid"
				or itemData.itemType
			local startX, endX, startZ, endZ =
				Grid.getHalfGridBounds(mappedType, itemData.x, itemData.z, itemData.w, itemData.l)

			-- NEW: Fetch the specific collision layer
			local layer = Grid.getLayer(itemData.itemType)

			for hx = startX, endX do
				for hz = startZ, endZ do
					-- DELETE WITH LAYER PREFIX
					newGrid[`{layer}_{hx}_{hz}`] = nil
				end
			end

			nextPlayerPlot.grid = newGrid
			nextPlayerPlot.placedItems = RemoveKey(playerPlot.placedItems, uuid)

			-- 2. CASCADE DELETE: Remove all Spatial Items sitting on this Grid item
			if nextPlayerPlot.spatialItems then
				nextPlayerPlot.spatialItems = Dictionary.filter(nextPlayerPlot.spatialItems, function(sItem)
					return sItem.parentUuid ~= uuid
				end)
			end
		elseif isSpatialItem then
			-- Free items have no grid footprint to clean up, just remove them
			nextPlayerPlot.spatialItems = RemoveKey(playerPlot.spatialItems, uuid)
		end

		return Set(state, playerId, nextPlayerPlot)
	end,
}

return Reflex.createProducer(initialState, actions)
