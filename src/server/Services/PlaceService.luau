-- ShopService.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local MixerConfig = require(ReplicatedStorage.Shared.Configs.MixerConfig)
local Types = require(ReplicatedStorage.Shared.Types)
local UpgradesModule = require(ReplicatedStorage.Shared.UpgradesModule)
local ShopCycle = require(ReplicatedStorage.Shared.ShopCycle)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local ShopService = {}

local function handleCollisions(object, char: Model?)
	if object then
		local collided = false
		local collisionPoints = workspace:GetPartsInPart(object.PrimaryPart)

		for i, cp in collisionPoints do
			local isCharacter = char and cp:IsDescendantOf(char) or false
			local isObject = cp:IsDescendantOf(object)

			if not (isObject or isCharacter) then
				collided = true
				break
			end
		end
		return collided
	end
end

function ShopService.initialize()
	Remotes.Place.OnServerEvent:Connect(function(player, id, loc, cf, plot)
		local item = ReplicatedStorage.Shared.Models:FindFirstChild(id):Clone()
		-- item.PrimaryPart.CanCollide = false
		item:PivotTo(cf)
		local char = player.Character
		if handleCollisions(item, char) then
			item:Destroy()
			return
		end

		if plot then
			item.Parent = loc
		end
	end)
end
return ShopService
