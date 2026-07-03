--!strict
-- ingredientsSlice.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Types = require(ReplicatedStorage.Shared.Types)

local Dictionary = Sift.Dictionary
local Merge = Dictionary.merge
local Set = Dictionary.set
local RemoveKey = Dictionary.removeKey

-- /// TYPES ///
type PlayerData = Types.PlayerData

export type IngredientsState = Types.IngredientsState

-- /// INITIALIZATION ///
local initialState: IngredientsState = {}

-- /// REDUCERS ///
local actions = {
	startPlayerSession = function(state: IngredientsState, playerId: string, data: PlayerData)
		return Set(state, playerId, data.Ingredients)
	end,
	endPlayerSession = function(state: IngredientsState, playerId: string, data: PlayerData)
		return RemoveKey(state, playerId)
	end,
	mixDrink = function(state: IngredientsState, playerId: string, payload: Types.MixDrinkPayload)
		local playersIngredients = state[playerId]
		if not playersIngredients then
			warn(`ingredientsSlice player({playerId}) not found`)
			return state
		end
		for i, ingredientId: string in payload.ingredients do
			playersIngredients[ingredientId] = (playersIngredients[ingredientId] or 0) - 1
		end

		return Set(state, playerId, playersIngredients)
	end,
	buyIngredient = function(
		state: IngredientsState,
		playerId: string,
		ingredientId: string,
		amount: number,
		cost: number
	)
		local playersIngredients = state[playerId]
		if not playersIngredients then
			warn(`ingredientsSlice player({playerId}) not found`)
			return state
		end

		return Set(
			state,
			playerId,
			Set(playersIngredients, ingredientId, (playersIngredients[ingredientId] or 0) + amount)
		)
	end,
}

return Reflex.createProducer(initialState, actions)
