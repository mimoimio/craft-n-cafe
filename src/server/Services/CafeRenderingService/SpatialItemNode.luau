local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local React = require(ReplicatedStorage.Packages.React)
local useEffect = React.useEffect

local Types = require(ReplicatedStorage.Shared.Types)
local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local Grid = require(ReplicatedStorage.Shared.Grid)
local DrinksService = require(ServerScriptService.Server.Services.DrinksService)

local useState = React.useState
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local Models = ReplicatedStorage.Shared.Models

local function SpatialItemNode(props: {
	Uuid: string,
	ItemData: Types.SpatialItem,
	BaseModel: CafeTypes.CafeBase,
	PlayerId: string,
})
	local plotSizeNum, setPlotSizeNum = useState(32)

	useEffect(function()
		local function selectPlotSize(state)
			local plotState = state.Plot and state.Plot[props.PlayerId]
			return plotState and plotState.plotSize or 32
		end

		local unsub = GlobalState:subscribe(selectPlotSize, setPlotSizeNum)

		-- Initialize state immediately
		setPlotSizeNum(selectPlotSize(GlobalState:getState()))

		return unsub
	end, { props.PlayerId })
	useEffect(function()
		local prefab = Models:FindFirstChild(props.ItemData.id)
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

		-- Disable existing prompts attached to the prefab
		local pp = clone:FindFirstChildWhichIsA("ProximityPrompt", true)
		if pp then
			pp.Enabled = false
		end

		-- FIX: Capture originalCFrame to properly orient the bounding box later
		local originalCFrame, itemSize = clone:GetBoundingBox()

		-- FIX: Use the invisible Anchor for position, and Reflex for the Size
		local anchor = props.BaseModel:FindFirstChild("Anchor")
		local plotCFrame = anchor and anchor.CFrame or props.BaseModel.Part.CFrame
		local plotSize = Vector3.new(plotSizeNum, 1, plotSizeNum)

		local spatialCFrame = if typeof(props.ItemData.cframe) == "table"
			then CFrame.new(table.unpack(props.ItemData.cframe))
			elseif typeof(props.ItemData.cframe) == "CFrame" then props.ItemData.cframe
			else warn("ERROR: SpatialItem NOR CFRAME OR TABLE") or CFrame.new(0, 0, 0)

		local targetCFrame = Grid.spatialToWorld(spatialCFrame, plotCFrame, plotSize)
		local conn, conn2

		-- [[ FUNCTIONAL ROUTING ]]
		-- Enables tabletop ingredients and mini appliances!
		local stationName = string.match(props.ItemData.id, "^(.+)_station$")

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
			-- prompt.HoldDuration = 3

			local starttime = nil
			local isIngredient = stationName ~= "cup" and stationName ~= "trash"
			conn2 = isIngredient
					and prompt.TriggerEnded:Connect(function(player)
						if not starttime then
							warn("Trigger Ended but no starttime")
							return
						end

						local elapsed = workspace:GetServerTimeNow() - starttime
						-- warn("elapsed:", elapsed)
						starttime = nil

						-- DrinksService.AddIngredient(player, stationName, nil)
					end)
				or nil

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

		-- FIX: Use the actual originalCFrame instead of `_`
		part:PivotTo(originalCFrame)

		-- 🎯 CRITICAL: Tag the model so the Delete Raycaster can find its UUID
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
		clone.Parent = props.BaseModel and props.BaseModel.Parent and props.BaseModel.Spatial or nil

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
		end
	end, { props.ItemData, props.BaseModel, props.PlayerId, plotSizeNum }) -- Re-run if plot size expands!

	return nil
end

return SpatialItemNode
