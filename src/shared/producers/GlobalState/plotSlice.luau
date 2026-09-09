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
		-- Ensure nextId initializes to 1 if loading a new plot
		return Set(state, playerId, data.Plot or { occupiedCoordinates = {}, placedItems = {}, nextId = 1 })
	end,

	endPlayerSession = function(state: { [string]: PlotState }, playerId: string)
		return RemoveKey(state, playerId)
	end,

	placeItem = function(state: { [string]: PlotState }, playerId: string, payload: Types.PlaceItemPayload)
		local playerPlot = state[playerId] or { grid = {}, placedItems = {}, nextId = 1 }
		local generatedUuid = tostring(playerPlot.nextId)

		-- Grab Half-Grid bounds and write to the unified grid
		local newGrid = Dictionary.copy(playerPlot.grid)
		local startX, endX, startZ, endZ =
			Grid.getHalfGridBounds(payload.itemType, payload.startX, payload.startZ, payload.width, payload.length)

		for hx = startX, endX do
			for hz = startZ, endZ do
				newGrid[`{hx}_{hz}`] = generatedUuid
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

		local nextPlayerPlot = Merge(playerPlot, {
			grid = newGrid,
			placedItems = Set(playerPlot.placedItems, generatedUuid, newItem),
			nextId = playerPlot.nextId + 1,
		})

		return Set(state, playerId, nextPlayerPlot)
	end,

	destroyItem = function(state: { [string]: PlotState }, playerId: string, payload: Types.DestroyItemPayload)
		local playerPlot = state[playerId]
		if not playerPlot then
			return state
		end

		local itemData = playerPlot.placedItems[payload.uuid]
		if not itemData then
			return state
		end

		-- Grab bounds from saved itemData and clear those exact Half-Grid keys
		local newGrid = Dictionary.copy(playerPlot.grid)
		local startX, endX, startZ, endZ =
			Grid.getHalfGridBounds(itemData.itemType, itemData.x, itemData.z, itemData.w, itemData.l)

		for hx = startX, endX do
			for hz = startZ, endZ do
				newGrid[`{hx}_{hz}`] = nil
			end
		end

		local nextPlayerPlot = Merge(playerPlot, {
			grid = newGrid,
			placedItems = RemoveKey(playerPlot.placedItems, payload.uuid),
		})

		return Set(state, playerId, nextPlayerPlot)
	end,
}

return Reflex.createProducer(initialState, actions)
