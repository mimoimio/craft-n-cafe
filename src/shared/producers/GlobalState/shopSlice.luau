-- shopSlice.luau
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Types = require(ReplicatedStorage.Shared.Types)

local Dictionary = Sift.Dictionary
local Set = Dictionary.set
local Merge = Dictionary.merge
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
		local newestSeed = tonumber(payload.newestSeed)
		local seedString = tostring(newestSeed)

		local savedShops = data.Shop or {}
		local currentShop = savedShops[newestSeed]

		-- If the player hasn't seen this cycle yet, assign the deterministic shop
		if not currentShop then
			savedShops = {
				[seedString] = payload.newestShop,
			}
		else
			-- Clean up old memory; we only care about their progress in the current active seed
			savedShops = {
				[seedString] = currentShop,
			}
		end

		return Set(state, playerId, {
			variationEvent = payload.variationEvent,
			currentSeed = newestSeed,
			shops = savedShops,
		})
	end,

	endPlayerSession = function(state: ShopState, playerId: string)
		return RemoveKey(state, playerId)
	end,

	refreshShop = function(state: ShopState, playerId: string, payload: Types.RefreshShopPayload)
		local playersShopState = state[playerId]
		if not playersShopState then
			return state
		end

		local newestSeed = tonumber(payload.newestSeed)
		local seedString = tostring(newestSeed)

		if newestSeed == playersShopState.currentSeed then
			print(`is the same seed`)
			return state
		end

		local newShops = {}
		newShops[seedString] = payload.newestShop

		return Set(state, playerId, {
			variationEvent = payload.variationEvent,
			currentSeed = newestSeed,
			shops = newShops,
		})
	end,

	buyIngredient = function(state: ShopState, playerId: string, payload: Types.BuyIngredientPayload)
		local playerState = state[playerId]
		if not playerState then
			warn(`shopSlice: buyIngredient: not playerState`)
			return state
		end
		-- retrieving seed from player's shops dictionary. Since it's a key, use string
		local seed = tonumber(payload.seed)
		local seedString = tostring(seed)
		local shop = playerState.shops[seedString]
		if not shop or not shop[payload.ingredientId] then
			warn(`shopSlice: buyIngredient: not shop`)
			return state
		end

		local currentStock = shop[payload.ingredientId]
		local newStock = math.max(0, currentStock - payload.amount)

		-- Deep update the specific ingredient's stock
		return Set(
			state,
			playerId,
			Merge(playerState, {
				currentSeed = playerState.currentSeed,
				shops = Set(
					playerState.shops,
					seedString, -- string, cuz key
					Dictionary.set(shop, payload.ingredientId, newStock)
				),
			})
		)
	end,
}

return Reflex.createProducer(initialState, actions)
