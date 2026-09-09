-- PlacedItemNode.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local React = require(ReplicatedStorage.Packages.React)
local useEffect = React.useEffect

local Grid = require(ReplicatedStorage.Shared.Grid)
local Types = require(ReplicatedStorage.Shared.Types)
local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local DrinksService = require(ServerScriptService.Server.Services.DrinksService)

local Models = ReplicatedStorage.Shared.Models

local function PlacedItemNode(props: {
	Uuid: string,
	ItemData: Types.PlacedItem,
	BaseModel: CafeTypes.CafeBase,
	GridSize: number,
	PlayerId: string,
})
	useEffect(function()
		local prefab = Models:FindFirstChild(props.ItemData.id)
		if not prefab then
			return
		end

		local clone = prefab:Clone()
		local primary = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart")
		local pp = clone:FindFirstChild("ProximityPrompt")
		if pp then
			pp.Enabled = false
		end

		local _, itemSize = clone:GetBoundingBox()
		local plotCFrame, plotSize = props.BaseModel.Part.CFrame, props.BaseModel.Part.Size

		-- ALWAYS get the unrotated footprint for the base snappedSize Vector3
		-- This prevents double-swapping when passed into gridToWorld
		local rawX, rawZ = Grid.getFootprint(itemSize, 0)
		local snappedSize = Vector3.new(rawX * Grid.SIZE, itemSize.Y, rawZ * Grid.SIZE)

		local targetCFrame = Grid.gridToWorld(
			props.ItemData.itemType,
			props.ItemData.x,
			props.ItemData.z,
			plotCFrame,
			plotSize,
			snappedSize,
			props.ItemData.r
		)

		local conn = nil

		-- [[ FUNCTIONAL ROUTING ]]
		-- Match IDs like "milk_station", "cup_station", "trash_station"
		local stationName = string.match(props.ItemData.id, "^(.+)_station$")

		if stationName then
			local prompt = Instance.new("ProximityPrompt")
			local config = CoffeeModule.IngredientLookup[stationName]
			prompt.RequiresLineOfSight = false

			prompt.ActionText = stationName == "cup" and "Get a cup"
				or stationName == "trash" and "Trash current cup"
				or config and `Add {config.DisplayName}`
				or "???"

			prompt.ObjectText = stationName == "cup" and "Cup"
				or stationName == "trash" and "Trash bin"
				or config and `{config.DisplayName}`
				or "???"

			prompt.Parent = primary

			conn = prompt.Triggered:Connect(function(player: Player)
				local playerId = tostring(player.UserId)
				if playerId ~= props.PlayerId then
					print("not playerId")
					return
				end

				if stationName == "cup" then
					DrinksService.GetCup(player)
				elseif stationName == "trash" then
					DrinksService.TrashCup(player)
				else
					DrinksService.AddIngredient(player, stationName)
				end
			end)
		elseif props.ItemData.id == "EspressoMachine" then
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Brew Espresso"
			prompt.Parent = primary

			conn = prompt.Triggered:Connect(function(player)
				print(player.Name .. " is brewing at " .. props.Uuid)
			end)
		end

		repeat
			local pl = clone:FindFirstChildWhichIsA("PackageLink", true)
			local found = pl and true or false
			if pl then
				pl:Destroy()
			end
		until not found

		-- Setup the new perfectly-snapped PrimaryPart
		local part = Instance.new("Part")
		part.Anchored = true
		part.Color = Color3.new(0, 0, 1)
		part.Size = snappedSize
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Transparency = 1
		part.Parent = clone
		part:PivotTo(_) -- this is important

		clone:SetAttribute("Uuid", props.Uuid)
		clone.PrimaryPart = part
		clone:PivotTo(targetCFrame)
		clone.Parent = props.BaseModel

		return function()
			if conn then
				conn:Disconnect()
			end
			clone:Destroy()
		end
	end, { props.ItemData, props.BaseModel, props.PlayerId })

	return nil
end

return PlacedItemNode
