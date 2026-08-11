-- Server/Services/CafeRenderingService/Shelves.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)

local CafeTypes = require(game.ReplicatedStorage.Shared.CafeTypes)
local Types = require(game.ReplicatedStorage.Shared.Types)
local DrinkModelUtil = require(ReplicatedStorage.Shared.Utils.DrinkModelUtil)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)

local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local VStack = require(ReplicatedStorage.Shared.ReactComponents.ui.VStack)

-- 1. THE SLOT COMPONENT
local function ShelfSlotComponent(
	props: {
		PlayerId: string,
		SlotInstance: CafeTypes.ShelfSlot, -- For shelves, the slot itself is a Part containing a DisplayPart
		SlotData: any, -- Can be "none" or Types.DisplayDrink
	}
)
	-- Render physical trophy drink
	useEffect(function()
		if not props.SlotData or props.SlotData == "none" then
			return
		end

		local clone, modelBasePart =
			DrinkModelUtil.BuildDrinkModel(props.SlotData.drinkId, props.SlotData.variationId, {
				Anchored = true,
				CanCollide = false,
				Size = props.SlotData.size,
			})

		if clone then
			-- Pivot to the static slot part
			clone:PivotTo(props.SlotInstance.CFrame)

			local tag = props.PlayerId and props.PlayerId .. "ShelfDrink" or ""

			local basePartDescendants = 0
			for _, desc in clone:GetDescendants() do
				if desc:IsA("BasePart") then
					basePartDescendants += 1
				end
			end

			clone:SetAttribute("BasePartDescendants", basePartDescendants)
			clone:AddTag(tag)

			clone.Parent = workspace

			return function()
				clone:Destroy()
			end
		end
	end, {
		props.SlotData and props.SlotData.drinkId,
		props.SlotData and props.SlotData.variationId,
		props.SlotData and props.SlotData.size,
		props.SlotInstance,
	})

	-- Bail out of rendering UI if slot is empty
	if not props.SlotData or props.SlotData == "none" then
		return nil
	end

	local config = CoffeeModule.Config[props.SlotData.drinkId]
	local variation = VariationsConfig[props.SlotData.variationId] or VariationsConfig["none"]

	local rate = 0
	if config and config.Rate then
		local sizeMultiplier = props.SlotData.size or 1
		rate = config.Rate * variation.Multiplier * sizeMultiplier
	end

	if rate <= 0 then
		return nil
	end

	local displayname = config.DisplayName or "Unknown"
	local variationName = variation.DisplayName or ""

	-- Format the title with RichText to color the variation name
	local titleText = displayname
	if variation.VariationId ~= "none" and variationName ~= "" then
		local color = variation.ColorPrimary or Color3.new(1, 1, 1)
		local hex = color:ToHex()
		titleText = `<font color="#{hex}">{displayname}</font>`
	end

	-- Attempt to find the specific display part (Fallback to SlotInstance if missing)
	local adornee = props.SlotInstance:FindFirstChild("DisplayPart") or props.SlotInstance

	return e(React.Fragment, nil, {
		RateGui = e("SurfaceGui", {
			ResetOnSpawn = false,
			Active = false,
			Adornee = adornee,
			MaxDistance = 60,
			CanvasSize = Vector2.new(200, 100),
		}, {
			Container = e(VStack, {
				Size = UDim2.fromScale(1, 1),
			}, {
				NameLabel = e(SmallText, {
					LayoutOrder = 1,
					Text = titleText,
					TextSize = 32,
					TextWrapped = false,
					TextColor3 = Color3.new(1, 1, 1),
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center,
					RichText = true, -- Enables the Hex coloring
					TextStrokeTransparency = 0,
					TextStrokeColor3 = Color3.new(0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.XY,
				}),
				RateLabel = e(SmallText, {
					LayoutOrder = 2,
					Text = `+${rate}/s`,
					TextColor3 = Color3.fromRGB(115, 255, 135), -- Money green
					TextSize = 32,
					TextWrapped = false,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center,
					RichText = true,
					TextStrokeTransparency = 0,
					TextStrokeColor3 = Color3.new(0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.XY,
				}),
			}),
		}),
	})
end

-- 2. THE SHELF COMPONENT
local function ShelfComponent(
	props: {
		PlayerId: string,
		ShelfName: string,
		ShelfData: Types.ShelfEntity, -- From State
		ShelfAnchor: CafeTypes.Shelf, -- From Cafe Model
	}
)
	local children = {}

	-- Since shelves are static, we don't clone anything! We just grab the existing slots.
	local shelfSlotsFolder = props.ShelfAnchor:FindFirstChild("ShelfSlots")

	if shelfSlotsFolder and props.ShelfData.Slots then
		for slotName, slotData in props.ShelfData.Slots do
			local slotInstance = shelfSlotsFolder:FindFirstChild(slotName)

			if slotInstance and slotInstance:IsA("BasePart") then
				-- Make the physical marker invisible
				slotInstance.Transparency = 1

				children[slotName] = e(ShelfSlotComponent, {
					key = slotName,
					PlayerId = props.PlayerId,
					SlotInstance = slotInstance :: any, -- Coerced as it adheres to ShelfSlot in runtime
					SlotData = slotData,
				})
			end
		end
	end

	return e(React.Fragment, nil, children)
end

-- 3. THE SHELVES MANAGER
local function Shelves(props: {
	CafeModel: CafeTypes.Cafe,
	PlayerId: string,
})
	local shelvesState, setShelvesState = useState({})

	-- Subscribe strictly to this player's Shelves slice
	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.Shelves[props.PlayerId]
		end, function(newShelvesState)
			setShelvesState(newShelvesState or {})
		end)

		-- Initial fetch
		local state = GlobalState:getState()
		if state.Shelves[props.PlayerId] then
			setShelvesState(state.Shelves[props.PlayerId])
		end

		return unsub
	end, { props.PlayerId })

	local children = {}
	local shelvesFolder = props.CafeModel:FindFirstChild("Shelves")

	if shelvesFolder then
		-- Loop through the state dictionary (Shelf1, Shelf2, etc.)
		for shelfName, shelfData in shelvesState do
			-- Find the corresponding static anchor in the 3D space
			local shelfAnchor = shelvesFolder:FindFirstChild(shelfName)

			if shelfAnchor then
				children[shelfName] = e(ShelfComponent, {
					PlayerId = props.PlayerId,
					ShelfName = shelfName,
					ShelfData = shelfData,
					ShelfAnchor = shelfAnchor,
				})
			end
		end
	end

	return e(React.Fragment, nil, children)
end

return Shelves
