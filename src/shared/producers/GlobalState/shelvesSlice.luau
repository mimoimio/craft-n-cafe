-- producers/shelvesSlice.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Types = require(ReplicatedStorage.Shared.Types)

local Dictionary = Sift.Dictionary
local Set = Dictionary.set
local RemoveKey = Dictionary.removeKey

type PlayerData = Types.PlayerData
type ShelvesState = Types.ShelvesState

local initialState: ShelvesState = {}

local actions = {
	startPlayerSession = function(state: ShelvesState, playerId: string, data: PlayerData)
		return Set(state, playerId, data.Shelves)
	end,

	endPlayerSession = function(state: ShelvesState, playerId: string, data: PlayerData)
		return RemoveKey(state, playerId)
	end,

	pickUpDrinkFromMixer = function(state: ShelvesState, playerId: string, payload: Types.PickUpPayload)
		local playerShelves = state[playerId]
		if not playerShelves then
			return state
		end

		local drinkId = payload.drinkId
		local variationId = payload.variationId or "none"
		local newSize = payload.size or 1

		-- 1. Check if already on shelf & handle Size upgrades
		for shelfUid, shelf in playerShelves do
			for slotName, slotData in shelf.Slots do
				if
					type(slotData) == "table"
					and slotData.drinkId == drinkId
					and slotData.variationId == variationId
				then
					local currentSize = slotData.size or 1

					if newSize > currentSize then
						-- Upgrade the existing trophy to the larger size!
						local newSlotData = Dictionary.merge(slotData, { size = newSize })
						local newSlots = Set(shelf.Slots, slotName, newSlotData)
						local newShelf = Set(shelf, "Slots", newSlots)
						local newPlayerShelves = Set(playerShelves, shelfUid, newShelf)

						return Set(state, playerId, newPlayerShelves)
					else
						-- They already have this size or better on display.
						return state
					end
				end
			end
		end

		-- 2. It's a new discovery! Let's find the first empty slot across all 6 shelves
		local targetShelfUid = nil
		local targetSlotName = nil

		for shelfIndex = 1, 6 do
			local shelfUid = "Shelf" .. tostring(shelfIndex)
			local shelf = playerShelves[shelfUid]

			if shelf then
				for slotIndex = 1, 20 do
					local slotName = "Slot" .. tostring(slotIndex)
					if shelf.Slots[slotName] == "none" then
						targetShelfUid = shelfUid
						targetSlotName = slotName
						break
					end
				end
			end
			if targetShelfUid then
				break
			end
		end

		if not targetShelfUid or not targetSlotName then
			warn(`[shelvesSlice]: Player {playerId} has no empty shelf space to display {drinkId}!`)
			return state
		end

		-- 3. Immutably add it to the display shelf!
		local currentShelf = playerShelves[targetShelfUid]
		local newSlots = Set(currentShelf.Slots, targetSlotName, {
			drinkId = drinkId,
			variationId = variationId,
			size = newSize,
		})

		local newShelf = Set(currentShelf, "Slots", newSlots)
		local newPlayerShelves = Set(playerShelves, targetShelfUid, newShelf)

		return Set(state, playerId, newPlayerShelves)
	end,
}

return Reflex.createProducer(initialState, actions)
