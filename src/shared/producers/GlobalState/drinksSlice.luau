--!strict
-- drinksSlice.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Types = require(ReplicatedStorage.Shared.Types)

local Array = Sift.Array
local Update = Array.update
local Insert = Array.insert
local Dictionary = Sift.Dictionary
local Merge = Dictionary.merge
local Set = Dictionary.set
local RemoveKey = Dictionary.removeKey

-- /// TYPES ///
type PlayerData = Types.PlayerData
export type DrinkEntity = Types.DrinkEntity
export type DrinksState = Types.DrinksState

export type StatsActions = {}

-- /// INITIALIZATION ///
local initialState: DrinksState = {}

-- /// REDUCERS ///
local actions = {
	startPlayerSession = function(state: DrinksState, playerId: string, data: PlayerData)
		return Set(state, playerId, data.Drinks)
	end,
	endPlayerSession = function(state: DrinksState, playerId: string, data: PlayerData)
		return RemoveKey(state, playerId)
	end,

	pickUpDrinkFromMixer = function(state: DrinksState, playerId: string, payload: Types.PickUpPayload)
		local playersDrinks = state[playerId]
		if not playersDrinks then
			return state
		end
		local newDrinks = table.clone(playersDrinks)
		table.insert(newDrinks, {
			id = payload.id,
			drinkId = payload.drinkId,
			stock = payload.stock,
			variationId = payload.variationId,
		})
		return Set(state, playerId, newDrinks)
	end,
	customerTakeItems = function(state: DrinksState, playerId: string, payload: Types.CustomerItemPayload)
		local playersDrinks = state[playerId]
		if not playersDrinks then
			return state
		end

		local newDrinks = table.clone(playersDrinks)

		local indexesToRemove = {}
		for i, drink in newDrinks do
			local deduct = payload.drinksDeducted[drink.id]
			if deduct then
				-- deduct({deduct},{type(deduct)})
				local total = drink.stock - deduct
				if total > 0 then
					newDrinks[i] = Set(drink, "stock", total) -- earlier an error where this was typed as {total}, an array. need to watchout
				else
					table.insert(indexesToRemove, i)
				end
			end
		end

		return Set(state, playerId, Array.removeIndices(newDrinks, table.unpack(indexesToRemove)))
	end,
}

return Reflex.createProducer(initialState, actions)
