-- Shared/producers/GlobalState/plotSlice.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Types = require(ReplicatedStorage.Shared.Types)

local Dictionary = Sift.Dictionary
local Merge = Dictionary.merge
local Set = Dictionary.set
local RemoveKey = Dictionary.removeKey

export type PlotState = Types.PlotState

-- Map of plots by PlayerId
local initialState: { [string]: PlotState } = {}

local actions = {
	startPlayerSession = function(state: { [string]: PlotState }, playerId: string, data: Types.PlayerData)
		return Set(state, playerId, data.Plot or { occupiedCoordinates = {}, placedItems = {} })
	end,

	endPlayerSession = function(state: { [string]: PlotState }, playerId: string)
		return RemoveKey(state, playerId)
	end,

	placeItem = function(state: { [string]: PlotState }, playerId: string, payload: Types.PlaceItemPayload)
		local playerPlot = state[playerId]
		-- If plot state doesn't exist for player, initialize it on the fly
		if not playerPlot then
			playerPlot = { occupiedCoordinates = {}, placedItems = {} }
		end

		-- 1. Create a new occupied dictionary immutably
		local newOccupied = Dictionary.copy(playerPlot.occupiedCoordinates)
		for x = payload.startX, payload.startX + payload.width - 1 do
			for z = payload.startZ, payload.startZ + payload.length - 1 do
				newOccupied[`{x}_{z}`] = payload.uuid
			end
		end

		-- 2. Create the new item data
		local newItem: Types.PlacedItem = {
			id = payload.itemId,
			x = payload.startX,
			z = payload.startZ,
			w = payload.width,
			l = payload.length,
			r = payload.rotation,
		}

		-- 3. Merge into the next state
		local nextPlayerPlot = Merge(playerPlot, {
			occupiedCoordinates = newOccupied,
			placedItems = Set(playerPlot.placedItems, payload.uuid, newItem),
		})
		local newstate = Set(state, playerId, nextPlayerPlot)
		warn("success", newstate)
		return newstate
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

		local newOccupied = Dictionary.copy(playerPlot.occupiedCoordinates)
		for x = itemData.x, itemData.x + itemData.w - 1 do
			for z = itemData.z, itemData.z + itemData.l - 1 do
				newOccupied[`{x}_{z}`] = nil
			end
		end

		local nextPlayerPlot = Merge(playerPlot, {
			occupiedCoordinates = newOccupied,
			placedItems = RemoveKey(playerPlot.placedItems, payload.uuid),
		})

		return Set(state, playerId, nextPlayerPlot)
	end,
}

return Reflex.createProducer(initialState, actions)
