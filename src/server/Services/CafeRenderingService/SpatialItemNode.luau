-- ServerScriptService/Server/Services/CafeRenderingService/SpatialItemNode.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local React = require(ReplicatedStorage.Packages.React)
local useEffect = React.useEffect

local Types = require(ReplicatedStorage.Shared.Types)
local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local DrinksService = require(ServerScriptService.Server.Services.DrinksService)

local Models = ReplicatedStorage.Shared.Models

local function SpatialItemNode(props: {
	Uuid: string,
	ItemData: Types.SpatialItem,
	BaseModel: CafeTypes.CafeBase,
	PlayerId: string,
})
	useEffect(function()
		local prefab = Models:FindFirstChild(props.ItemData.id)
		if not prefab then
			return
		end

		local clone = prefab:Clone()
		local primary = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart")

		-- Disable existing prompts attached to the prefab
		local pp = clone:FindFirstChildWhichIsA("ProximityPrompt", true)
		if pp then
			pp.Enabled = false
		end

		local _, itemSize = clone:GetBoundingBox()
		local plotCFrame = props.BaseModel.Part.CFrame
		local targetCFrame = plotCFrame:ToWorldSpace(props.ItemData.cframe)
		local conn = nil

		-- [[ FUNCTIONAL ROUTING ]]
		-- Enables tabletop ingredients and mini appliances!
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
		-- Setup the new perfectly-snapped PrimaryPart bounding box
		local part = Instance.new("Part")
		part.Anchored = true
		part.Color = Color3.new(1, 0, 0) -- Red outline in debug mode to distinguish from Grid items
		part.Size = itemSize
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Transparency = 1
		part.Parent = clone
		part:PivotTo(_) -- Resets orientation internally

		-- 🎯 CRITICAL: Tag the model so the Delete Raycaster can find its UUID
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

return SpatialItemNode
