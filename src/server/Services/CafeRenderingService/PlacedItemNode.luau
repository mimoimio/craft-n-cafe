-- ServerScriptService/Server/Services/CafeRenderingService/PlacedItemNode.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local useEffect = React.useEffect

local Grid = require(ReplicatedStorage.Shared.Grid)
local Types = require(ReplicatedStorage.Shared.Types)
local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)

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

		local _, itemSize = clone:GetBoundingBox()
		local plotCFrame, plotSize = props.BaseModel.Part.CFrame, props.BaseModel.Part.Size

		-- ALWAYS get the unrotated footprint for the base snappedSize Vector3
		-- This prevents double-swapping when passed into gridToWorld
		local rawX, rawZ = Grid.getFootprint(itemSize, 0)
		local snappedSize = Vector3.new(rawX * Grid.SIZE, itemSize.Y, rawZ * Grid.SIZE)

		local targetCFrame = Grid.gridToWorld(
			props.ItemData.x,
			props.ItemData.z,
			plotCFrame,
			plotSize,
			snappedSize, -- Pass snappedSize instead of itemSize
			props.ItemData.r
		)

		-- [[ FUNCTIONAL ROUTING ]]
		if props.ItemData.id == "EspressoMachine" then
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Brew Espresso"
			prompt.Parent = primary
			prompt.Triggered:Connect(function(player)
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

		clone.PrimaryPart = part
		clone:PivotTo(targetCFrame)
		clone.Parent = props.BaseModel

		return function()
			clone:Destroy()
		end
	end, { props.ItemData, props.BaseModel })

	return nil
end

return PlacedItemNode
