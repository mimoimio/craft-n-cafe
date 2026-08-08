-- Shared/ReactComponents/ShelfManager.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Promise = require(ReplicatedStorage.Packages.Promise)

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)
local Types = require(ReplicatedStorage.Shared.Types)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)

local SmallText = require(script.Parent.ui.SmallText)
local HStack = require(script.Parent.ui.HStack)
local VStack = require(script.Parent.ui.VStack)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""

-- ==========================================
-- 1. THE SLOT COMPONENT
-- ==========================================
local function ShelfSlotNode(
	props: {
		SlotName: string,
		SlotData: any, -- { drinkId, variationId } or "none"
		ShelfSlot: CafeTypes.ShelfSlot,
	}
)
	local adornee, setAdornee = useState(nil)
	local shelfSlot = props.ShelfSlot
	useEffect(function()
		if not (shelfSlot and shelfSlot.Parent) then
			return
		end
		local promise = Promise.defer(function(resolve, reject, onCancel)
			setAdornee(shelfSlot:WaitForChild("DisplayPart"))
			return resolve()
		end):catch(function(err)
			warn(`Waiting ShelfSlot Display Error: {err}`)
		end)
		return function()
			promise:cancel()
		end
	end, { shelfSlot })
	-- warn(shelfSlot)

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
		-- titleText = `<font color="#{hex}">{variationName}</font> {displayname}`
		titleText = `<font color="#{hex}">{displayname}</font>`
	end

	return e(React.Fragment, nil, {
		RateGui = e("SurfaceGui", {
			Active = false,
			Adornee = adornee,
			MaxDistance = 60,
			-- ref = warn,
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
-- ==========================================
-- 2. THE SHELF COMPONENT
-- ==========================================
local function ShelfNode(props: {
	ShelfId: string,
	ShelfData: Types.ShelfEntity,
	Shelf: CafeTypes.Shelf?,
})
	if not props.Shelf or not props.ShelfData or not props.ShelfData.Slots then
		return nil
	end

	local children = {}
	local slotsFolder = props.Shelf:FindFirstChild("ShelfSlots")

	if slotsFolder then
		for slotName, slotData in pairs(props.ShelfData.Slots) do
			local slotInstance: CafeTypes.ShelfSlot = slotsFolder:FindFirstChild(slotName)
			-- warn(slotName, slotInstance)
			if slotInstance and slotInstance:IsA("BasePart") then
				children[slotName] = e(ShelfSlotNode, {
					SlotName = slotName,
					SlotData = slotData,
					ShelfSlot = slotInstance,
				})
			end
		end
	end

	return e(React.Fragment, nil, children)
end

-- ==========================================
-- 3. THE SHELVES MANAGER
-- ==========================================
local function ShelfManager(props: { CafeModel: Model })
	local shelvesState, setShelvesState = useState({})
	local shelvesFolder = props.CafeModel and props.CafeModel:FindFirstChild("Shelves")

	-- Subscribe to the Shelves state slice
	useEffect(function()
		local unsub = GlobalState:subscribe(function(state)
			return state.Shelves[playerId]
		end, function(newShelves)
			if not newShelves then
				return
			end
			setShelvesState(newShelves)
		end)

		local state = GlobalState:getState()
		if state.Shelves and state.Shelves[playerId] then
			setShelvesState(state.Shelves[playerId])
		end

		if not player then
			setShelvesState({
				Shelf1 = {
					ShelfId = "Shelf1",
					Slots = {
						Slot1 = {
							drinkId = "espresso",
							variationId = "starlit",
						},
						Slot2 = {
							drinkId = "shavedice",
							variationId = "hexed",
						},
					},
				},
			})
		end

		return function()
			unsub()
		end
	end, {})

	local children = {}

	-- Only render if the physical Shelves folder exists in the Cafe model
	if shelvesFolder then
		for shelfId, shelfData in pairs(shelvesState) do
			local shelfInstance = shelvesFolder:FindFirstChild(shelfId)
			if shelfInstance then
				children[shelfId] = e(ShelfNode, {
					ShelfId = shelfId,
					ShelfData = shelfData,
					Shelf = shelfInstance,
				})
			end
		end
	end

	return e(React.Fragment, nil, children)
end

return ShelfManager
