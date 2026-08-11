-- Server/Services/ShelfCollectorService.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local MAX_ACCUMULATION_SECONDS = 8 * 60 * 60 -- 8 hours

local ShelfCollectorService = {}

function ShelfCollectorService.Claim(player: Player)
    local playerId = tostring(player.UserId)
    local state = GlobalState:getState()
    local shelves = state.Shelves[playerId]
    
    if not shelves then return end

    local currentTime = workspace:GetServerTimeNow()
    local totalAmountToClaim = 0

    for _, shelf in shelves do
        for _, slotData in shelf.Slots do
            if type(slotData) == "table" and slotData.drinkId and slotData.lastClaimTime then
                local config = CoffeeModule.Config[slotData.drinkId]
                local variation = VariationsConfig[slotData.variationId] or VariationsConfig["none"]
                
                if config and config.Rate then
                    local sizeMultiplier = slotData.size or 1
                    local rate = config.Rate * variation.Multiplier * sizeMultiplier
                    
                    local rawTimePassed = currentTime - slotData.lastClaimTime
                    local timePassed = math.min(rawTimePassed, MAX_ACCUMULATION_SECONDS)
                    
                    -- Floor the specific slot's earnings before summing to prevent floating point drift
                    totalAmountToClaim += math.floor(timePassed * rate)
                end
            end
        end
    end
    
    GlobalState.claimShelfCollector(playerId, {
        amount = totalAmountToClaim,
        timestamp = currentTime
    })

    if totalAmountToClaim > 0 then
        print(`{player.Name} claimed {totalAmountToClaim} cash from their shelves!`)
    end
end

function ShelfCollectorService.initialize()
    Remotes.ClaimShelfCollector.OnServerEvent:Connect(function(player: Player)
        ShelfCollectorService.Claim(player)
    end)
end

return ShelfCollectorService