-- shopSlice.luau
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Types = require(ReplicatedStorage.Shared.Types)

local Dictionary = Sift.Dictionary
local Set = Dictionary.set
local RemoveKey = Dictionary.removeKey

-- /// TYPES ///
type PlayerData = Types.PlayerData
export type ShopState = Types.ShopState

-- /// INITIALIZATION ///
local initialState: ShopState = {}

-- /// REDUCERS ///
local actions = {
	startPlayerSession = function(
		state: ShopState,
		playerId: string,
		data: PlayerData,
		payload: Types.StartPlayerSessionPayload
	)
		local newestSeed = payload.newestSeed
		local savedShops = data.Shop or {}
		local currentShop = savedShops[newestSeed]

		-- If the player hasn't seen this cycle yet, assign the deterministic shop
		if not currentShop then
			savedShops = {
				[newestSeed] = payload.newestShop,
			}
		else
			-- Clean up old memory; we only care about their progress in the current active seed
			savedShops = {
				[newestSeed] = currentShop,
			}
		end

		return Set(state, playerId, {
			currentSeed = newestSeed,
			shops = savedShops,
		})
	end,

	endPlayerSession = function(state: ShopState, playerId: string)
		return RemoveKey(state, playerId)
	end,

	refreshShop = function(state: ShopState, playerId: string, payload: Types.RefreshShopPayload)
		local playerState = state[playerId]
		if not playerState then
			return state
		end

		local newShops = Dictionary.copy(playerState.shops)
		newShops[payload.newestSeed] = payload.newestShop

		return Set(state, playerId, {
			currentSeed = payload.newestSeed,
			shops = newShops,
		})
	end,

	buyIngredient = function(state: ShopState, playerId: string, payload: Types.BuyIngredientPayload)
		local playerState = state[playerId]
		if not playerState then
			warn(`shopSlice: buyIngredient: not playerState`)
			return state
		end

		local shop = playerState.shops[payload.seed]
		if not shop or not shop[payload.ingredientId] then
			warn(`shopSlice: buyIngredient: not shop`)
			return state
		end

		local currentStock = shop[payload.ingredientId]
		local newStock = math.max(0, currentStock - payload.amount)

		-- Deep update the specific ingredient's stock
		return Set(state, playerId, {
			currentSeed = playerState.currentSeed,
			shops = Dictionary.set(
				playerState.shops,
				payload.seed,
				Dictionary.set(shop, payload.ingredientId, newStock)
			),
		})
	end,
}

return Reflex.createProducer(initialState, actions)
