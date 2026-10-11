-- PlacedItemNode.luau
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local React = require(ReplicatedStorage.Packages.React)
local useState = React.useState
local useEffect = React.useEffect

local Grid = require(ReplicatedStorage.Shared.Grid)
local Types = require(ReplicatedStorage.Shared.Types)
local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local DrinksService = require(ServerScriptService.Server.Services.DrinksService)

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local Models = ReplicatedStorage.Shared.Models
local PaintUtil = require(ReplicatedStorage.Shared.Utils.PaintUtil)

local function PlacedItemNode(props: {
	Uuid: string,
	ItemData: Types.PlacedItem,
	BaseModel: CafeTypes.CafeBase,
	GridSize: number,
	PlayerId: string,
})
	local plotSizeNum, setPlotSizeNum = useState(32)
	local modelClone, setModelClone = useState(nil) -- Track the clone for dynamic repainting

	-- 1. Native Reflex Subscription Pattern
	useEffect(function()
		local function selectPlotSize(state)
			local plotState = state.Plot and state.Plot[props.PlayerId]
			return plotState and plotState.plotSize or 32
		end

		local unsub = GlobalState:subscribe(selectPlotSize, setPlotSizeNum)
		setPlotSizeNum(selectPlotSize(GlobalState:getState()))

		return unsub
	end, { props.PlayerId })

	-- 2. Physical Rendering (Mount/Positioning)
	-- NOTICE: Dependencies are decoupled from the full ItemData so color changes don't re-clone!
	local x, z, r, w, l = props.ItemData.x, props.ItemData.z, props.ItemData.r, props.ItemData.w, props.ItemData.l
	local itemType, id = props.ItemData.itemType, props.ItemData.id

	useEffect(function()
		local prefab = Models:FindFirstChild(id)
		if not prefab then
			warn("prefab not found", id)
			return
		end

		local clone = prefab:Clone()
		local primary = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart")
		local pp = clone:FindFirstChild("ProximityPrompt")
		if pp then
			pp.Enabled = false
		end

		local originalCFrame, itemSize = Grid.getModelBounds(clone)
		local anchor = props.BaseModel:FindFirstChild("Anchor")
		local plotCFrame = anchor and anchor.CFrame or props.BaseModel.Part.CFrame
		local plotSize = Vector3.new(plotSizeNum, 1, plotSizeNum)

		local rawX, rawZ = Grid.getFootprint(itemSize, 0)
		local snappedSize = Vector3.new(rawX * Grid.SIZE, itemSize.Y, rawZ * Grid.SIZE)

		local targetCFrame = Grid.gridToWorld(itemType, x, z, plotCFrame, plotSize, snappedSize, r)

		local conn = nil
		local stationName = string.match(id, "^(.+)_station$")

		if stationName then
			repeat
				local found = clone:FindFirstChildWhichIsA("ProximityPrompt")
				if found then
					found:Destroy()
				end
			until not found
			local prompt = Instance.new("ProximityPrompt")
			local config = CoffeeModule.IngredientLookup[stationName]
			prompt.RequiresLineOfSight = false
			prompt.Name = "TriggerPrompt"

			prompt.ActionText = stationName == "cup" and "Get a cup"
				or stationName == "trash" and "Trash current cup"
				or config and `Add {config.DisplayName}`
				or "???"

			prompt.ObjectText = stationName == "cup" and "Cup"
				or stationName == "trash" and "Trash bin"
				or config and `{config.DisplayName}`
				or "???"

			local newCenterPart = Instance.new("Part")
			newCenterPart.Size = Vector3.one
			newCenterPart.Transparency = 1
			newCenterPart.Anchored = true
			newCenterPart.CanCollide = false
			newCenterPart.CanQuery = false
			newCenterPart.CanTouch = false
			newCenterPart:PivotTo(CFrame.new(originalCFrame.Position))
			newCenterPart.Parent = clone
			prompt.Parent = newCenterPart

			local starttime = nil
			local isIngredient = stationName ~= "cup" and stationName ~= "trash"

			conn = prompt.Triggered:Connect(function(player: Player)
				local playerId = tostring(player.UserId)
				if playerId ~= props.PlayerId then
					return
				end
				starttime = workspace:GetServerTimeNow()

				if stationName == "cup" then
					DrinksService.GetCup(player)
				elseif stationName == "trash" then
					DrinksService.TrashCup(player)
				end
			end)
			CollectionService:AddTag(clone, "Station" .. props.PlayerId)
		end

		repeat
			local pl = clone:FindFirstChildWhichIsA("PackageLink", true)
			local found = pl and true or false
			if pl then
				pl:Destroy()
			end
		until not found

		local part = Instance.new("Part")
		part.Anchored = true
		part.Color = Color3.new(0, 0, 1)
		part.Size = snappedSize
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Transparency = 1
		part:PivotTo(originalCFrame)
		part.Parent = clone

		for i, desc: BasePart in clone:GetDescendants() do
			if desc:IsA("BasePart") then
				desc.CollisionGroup = "Walls"
				desc.Anchored = true
			end
		end

		clone:SetAttribute("Uuid", props.Uuid)
		clone.PrimaryPart = part
		clone:PivotTo(targetCFrame)
		clone.Name = props.Uuid
		part:Destroy()

		-- Apply initial colors immediately to prevent a 1-frame flash
		PaintUtil.ApplyColors(clone, props.ItemData.primaryColor, props.ItemData.secondaryColor)

		clone.Parent = props.BaseModel.Grid
		setModelClone(clone)

		return function()
			if conn then
				conn:Disconnect()
			end
			clone:Destroy()
			setModelClone(nil)
		end
	end, { id, x, z, r, w, l, itemType, props.BaseModel, props.PlayerId, plotSizeNum })

	-- 3. Dynamic Repainting (Zero Interruption!)
	useEffect(function()
		if modelClone then
			PaintUtil.ApplyColors(modelClone, props.ItemData.primaryColor, props.ItemData.secondaryColor)
		end
	end, { modelClone, props.ItemData.primaryColor, props.ItemData.secondaryColor })

	return nil
end

return PlacedItemNode
