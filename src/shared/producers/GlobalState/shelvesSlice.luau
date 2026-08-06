--!strict
-- producers/shelvesSlice.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Types = require(ReplicatedStorage.Shared.Types)

local Dictionary = Sift.Dictionary
local Set = Dictionary.set
local RemoveKey = Dictionary.removeKey

-- /// TYPES ///
type PlayerData = Types.PlayerData
export type ShelvesState = Types.ShelvesState

local log = function(message: string)
    warn(`[shelvesSlice]: {message}`)
end

-- /// INITIALIZATION ///
local initialState: ShelvesState = {}

-- /// REDUCERS ///
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

        -- 1. Check if this specific drink & variation is ALREADY on a shelf
        for shelfUid, shelf in playerShelves do
            for slotName, slotData in shelf.Slots do
                if type(slotData) == "table" and slotData.drinkId == drinkId and slotData.variationId == variationId then
                    -- Already proudly displayed! No state change needed.
                    return state 
                end
            end
        end

        -- 2. It's a new discovery! Let's find the first empty slot across all 6 shelves
        local targetShelfUid = nil
        local targetSlotName = nil

        -- Loop sequentially to ensure they fill up from Shelf1 -> Shelf6
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
            if targetShelfUid then break end -- Found a spot!
        end

        -- If all 120 slots are somehow full, just return the state (or you could expand it dynamically later!)
        if not targetShelfUid or not targetSlotName then
            log(`Player {playerId} has no empty shelf space to display {drinkId}!`)
            return state
        end

        -- 3. Immutably add it to the display shelf!
        local currentShelf = playerShelves[targetShelfUid]
        local newSlots = Set(currentShelf.Slots, targetSlotName, {
            drinkId = drinkId,
            variationId = variationId
        })
        
        local newShelf = Set(currentShelf, "Slots", newSlots)
        local newPlayerShelves = Set(playerShelves, targetShelfUid, newShelf)
        
        return Set(state, playerId, newPlayerShelves)
    end,
}

return Reflex.createProducer(initialState, actions)