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

-- 1. THE SLOT COMPONENT
local function ShelfSlotComponent(
	props: {
		PlayerId: string,
		SlotInstance: Part, -- For shelves, the slot itself is a Part
		SlotData: Types.DisplayDrink, -- Can be "none" or { drinkId = string, variationId = string }
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
		props.SlotInstance,
	})

	-- Unlike Tables, Shelf slots are just display! No ProximityPrompt interactions required here.
	return e(React.Fragment)
end

-- 2. THE SHELF COMPONENT
local function ShelfComponent(
	props: {
		PlayerId: string,
		ShelfName: string,
		ShelfData: CafeTypes.ShelfEntity, -- From State
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
					SlotInstance = slotInstance,
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
