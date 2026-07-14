-- TestingService.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local LevelConfig = require(ReplicatedStorage.Shared.Configs.LevelConfig)
local Types = require(ReplicatedStorage.Shared.Types)
local ShopCycle = require(ReplicatedStorage.Shared.ShopCycle)

local TestingService = {}

-- Generates a shop predeterministically based on the cycle seed
function TestingService.initialize()
	Remotes.Add500.OnServerEvent:Connect(function(player)
		GlobalState.Add500(tostring(player.UserId))
	end)
end
return TestingService
