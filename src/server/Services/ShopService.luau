local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)

local ShopService = {}

function ShopService.initialize()
	Remotes.BuyDragon.OnServerEvent:Connect(function(player, dragonId)
		local playerId = tostring(player.UserId)
		GlobalState.playerBuyDragon(playerId, {
			dragon = {},
			price = 50,
		})
	end)
end
return ShopService
