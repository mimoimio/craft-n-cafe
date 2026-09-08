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
		local playerPlot = state[playerId]
		if not playerPlot then
			playerPlot = { occupiedCoordinates = {}, placedItems = {}, nextId = 1 }
		end

		-- Grab the current ID from the counter
		local generatedUuid = tostring(playerPlot.nextId)

		local newOccupied = Dictionary.copy(playerPlot.occupiedCoordinates)
		for x = payload.startX, payload.startX + payload.width - 1 do
			for z = payload.startZ, payload.startZ + payload.length - 1 do
				newOccupied[`{x}_{z}`] = generatedUuid
			end
		end

		local newItem: Types.PlacedItem = {
			id = payload.itemId,
			x = payload.startX,
			z = payload.startZ,
			w = payload.width,
			l = payload.length,
			r = payload.rotation,
		}

		-- Merge increments the counter for the next item
		local nextPlayerPlot = Merge(playerPlot, {
			occupiedCoordinates = newOccupied,
			placedItems = Set(playerPlot.placedItems, generatedUuid, newItem),
			nextId = playerPlot.nextId + 1,
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
			-- nextId is explicitly NOT modified here so it never reuses IDs
		})

		return Set(state, playerId, nextPlayerPlot)
	end,
}

return Reflex.createProducer(initialState, actions)
