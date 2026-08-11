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
		local playersIngredients = state[playerId]

		if not playersIngredients then
			warn(`ingredientsSlice player({playerId}) not found`)
			return state
		end

		local newIngredients = table.clone(playersIngredients)
		for ingId, amount in payload.ingredients do
			local currentAmount = newIngredients[ingId] or 0
			newIngredients[ingId] = currentAmount + amount
		end

		return Set(state, playerId, Merge(playersIngredients, newIngredients))
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

		local newIngredients = table.clone(playersIngredients)
		warn(`payload.ingredientIds`, payload.ingredientIds)
		for i, ingredient in payload.ingredientIds do
			-- newIngredients[ingredient] = (playersIngredients[ingredient] or 0) + 1
			-- payload.ingredientIds :: {string}, therefore, keys can repeat.
			-- keep using playersIngredients will only update the new ingredients
			-- even if there's 100 of them (100 string of the same id in the array),
			-- it will only update once. Therefore clone it first and update the new ingredients.
			newIngredients[ingredient] = (newIngredients[ingredient] or 0) + 1
		end

		return Set(state, playerId, Merge(playersIngredients, newIngredients))
	end,
}

return Reflex.createProducer(initialState, actions)
