-- SpatialItemNode.luau
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local React = require(ReplicatedStorage.Packages.React)
local useEffect = React.useEffect
local useState = React.useState

local Types = require(ReplicatedStorage.Shared.Types)
local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local Grid = require(ReplicatedStorage.Shared.Grid)
local DrinksService = require(ServerScriptService.Server.Services.DrinksService)

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local Models = ReplicatedStorage.Shared.Models
local PaintUtil = require(ReplicatedStorage.Shared.Utils.PaintUtil)

local function SpatialItemNode(props: {
	Uuid: string,
	ItemData: Types.SpatialItem,
	BaseModel: CafeTypes.CafeBase,
	PlayerId: string,
})
	local plotSizeNum, setPlotSizeNum = useState(32)
	local modelClone, setModelClone = useState(nil)

	useEffect(function()
		local function selectPlotSize(state)
			local plotState = state.Plot and state.Plot[props.PlayerId]
			return plotState and plotState.plotSize or 32
		end

		local unsub = GlobalState:subscribe(selectPlotSize, setPlotSizeNum)
		setPlotSizeNum(selectPlotSize(GlobalState:getState()))

		return unsub
	end, { props.PlayerId })

	local id = props.ItemData.id
	local parentUuid = props.ItemData.parentUuid
	local cframeDep = typeof(props.ItemData.cframe) == "table" and table.concat(props.ItemData.cframe, ",") or ""

	useEffect(function()
		local prefab = Models:FindFirstChild(id)
		if not prefab then
			return
		end

		local clone = prefab:Clone()
		local primary = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart")
		local hitbox = clone:FindFirstChild("Hitbox")
		if hitbox then
			if hitbox.Transparency == 1 then
				hitbox:Destroy()
			end
		end

		local pp = clone:FindFirstChildWhichIsA("ProximityPrompt", true)
		if pp then
			pp.Enabled = false
		end

		local originalCFrame, itemSize = clone:GetBoundingBox()

		local anchor = props.BaseModel:FindFirstChild("Anchor")
		local plotCFrame = anchor and anchor.CFrame or props.BaseModel.Part.CFrame
		local plotSize = Vector3.new(plotSizeNum, 1, plotSizeNum)

		local spatialCFrame = if typeof(props.ItemData.cframe) == "table"
			then CFrame.new(table.unpack(props.ItemData.cframe))
			elseif typeof(props.ItemData.cframe) == "CFrame" then props.ItemData.cframe
			else warn("ERROR: SpatialItem NOR CFRAME OR TABLE") or CFrame.new(0, 0, 0)

		local targetCFrame = Grid.spatialToWorld(spatialCFrame, plotCFrame, plotSize)
		local conn, conn2

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
		part.Color = Color3.new(1, 0, 0)
		part.Size = itemSize
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Transparency = 1
		part.Parent = clone

		part:PivotTo(originalCFrame)
		clone:SetAttribute("Uuid", props.Uuid)

		clone.PrimaryPart = part
		clone.Name = props.Uuid
		clone:PivotTo(targetCFrame)

		part:Destroy()
		for i, desc: BasePart in clone:GetDescendants() do
			if desc:IsA("BasePart") then
				desc.CollisionGroup = "Walls"
				desc.Anchored = true
			end
		end

		PaintUtil.ApplyColors(clone, props.ItemData.primaryColor, props.ItemData.secondaryColor)
		clone.Parent = props.BaseModel and props.BaseModel.Parent and props.BaseModel.Spatial or nil
		setModelClone(clone)

		return function()
			if conn then
				conn:Disconnect()
			end
			if conn2 then
				conn2:Disconnect()
			end
			if clone and clone.Parent then
				clone:Destroy()
			end
			setModelClone(nil)
		end
	end, { id, parentUuid, cframeDep, props.BaseModel, props.PlayerId, plotSizeNum })

	useEffect(function()
		if modelClone then
			PaintUtil.ApplyColors(modelClone, props.ItemData.primaryColor, props.ItemData.secondaryColor)
		end
	end, { modelClone, props.ItemData.primaryColor, props.ItemData.secondaryColor })

	return nil
end

return SpatialItemNode
