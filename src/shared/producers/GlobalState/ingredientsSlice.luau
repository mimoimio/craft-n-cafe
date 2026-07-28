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
	claimDailyReward = function(state: IngredientsState, playerId: string, payload: Types.DailyClaimPayload)
		local playerIngredients = state[playerId]

		if not playerIngredients then
			warn(`ingredientsSlice player({playerId}) not found`)
			return state
		end

		local newIngredients = {}
		for ingId, amount in payload.ingredients do
			newIngredients[ingId] = playerIngredients[ingId] or 0 + amount
		end

		return Set(state, playerId, Merge(playerIngredients, newIngredients))
	end,

	buyIngredient = function(
		state: IngredientsState,
		playerId: string,
		payload: {
			ingredientId: string,
			amount: number,
			cost: number,
		}
	)
		local playersIngredients = state[playerId]
		if not playersIngredients then
			warn(`ingredientsSlice player({playerId}) not found`)
			return state
		end

		return Set(
			state,
			playerId,
			Set(
				playersIngredients,
				payload.ingredientId,
				(playersIngredients[payload.ingredientId] or 0) + payload.amount
			)
		)
	end,
	buyIngredientFromSpawner = function(
		state: IngredientsState,
		playerId: string,
		payload: Types.BuyIngredientFromSpawnerPayload
	)
		local playersIngredients = state[playerId]
		if not playersIngredients then
			warn(`ingredientsSlice player({playerId}) not found`)
			return state
		end

		return Set(
			state,
			playerId,
			Set(playersIngredients, payload.ingredientId, (playersIngredients[payload.ingredientId] or 0) + 1)
		)
	end,
}

return Reflex.createProducer(initialState, actions)
