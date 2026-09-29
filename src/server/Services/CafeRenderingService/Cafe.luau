-- ServerScriptService/Server/Services/CafeRenderingService/Cafe.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local createSelector = Reflex.createSelector
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)
local Types = require(ReplicatedStorage.Shared.Types)
type CashierItem = Types.PlacedItem | Types.SpatialItem
type CashierItems = { [string]: CashierItem }
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule) -- NEW: Required to identify Cashiers

local PlacedItemsManager = require(script.Parent.PlacedItemsManager)
local Customers = require(script.Parent.Customers)

local function Cafe(props: { BaseModel: CafeTypes.CafeBase, PlayerId: string })
	-- 1. Native Reflex Subscription Pattern
	local plotSizeNum, setPlotSizeNum = useState(32)
	local plotPart, setPlotPart = useState(nil)
	local cashiers: CashierItems, setCashiers: (CashierItem | (prev: CashierItems) -> CashierItems) -> () = useState({}) -- NEW: Store extracted cashiers

	useEffect(function()
		local function selectPlotState(state)
			return state.Plot and state.Plot[props.PlayerId] or nil
		end

		local selectPlotSize = createSelector({ selectPlotState }, function(plotState)
			return plotState and plotState.plotSize or 32
		end)

		local selectCashiers = function(state: GlobalState.GlobalState)
			local plotState = state.Plot[props.PlayerId]
			local newCashiers = {}
			if not plotState then
				return newCashiers
			end

			for uuid, item in pairs(plotState.placedItems or {}) do
				local config = PlaceablesModule.GetConfig(item.id)
				if config and config.Category == "Cashier" then
					newCashiers[uuid] = { itemData = item, type = "Grid" }
				end
			end

			for uuid, item in pairs(plotState.spatialItems or {}) do
				local config = PlaceablesModule.GetConfig(item.id)
				if config and config.Category == "Cashier" then
					newCashiers[uuid] = { itemData = item, type = "Spatial" }
				end
			end

			return newCashiers
		end

		local discriminator = function(cashierItem: CashierItem, itemId)
			return itemId
		end

		local unsubCashiers = GlobalState:observe(
			selectCashiers,
			discriminator,
			function(cashierItem: CashierItem, cashierUuid)
				setCashiers(function(prev: CashierItem)
					local newCashiers = table.clone(prev)
					newCashiers[cashierUuid] = cashierItem
					return newCashiers
				end)
				-- cleanup
				return function()
					setCashiers(function(prev: CashierItem)
						local cashier = prev[cashierUuid]
						if not cashier then
							return prev
						end
						local newCashiers = table.clone(prev)
						newCashiers[cashierUuid] = nil
						return newCashiers
					end)
				end
			end
		)

		local unsubSize = GlobalState:subscribe(selectPlotSize, setPlotSizeNum)

		-- Initialize state immediately
		setPlotSizeNum(selectPlotSize(GlobalState:getState()))
		-- setCashiers(selectCashiers(GlobalState:getState())) -- no need to initialize when already observing

		return function()
			unsubSize()
			unsubCashiers()
		end
	end, { props.PlayerId })

	local anchor = props.BaseModel:FindFirstChild("Anchor")
	local plotCFrame = anchor and anchor.CFrame or CFrame.new(0, 0, 0)
	useEffect(function()
		if not plotPart then
			return
		end
		local entrance = props.BaseModel.Entrance
		local mailbox = props.BaseModel.Mailbox

		local entranceSize = entrance.Size
		local plotSize = plotPart.Size

		local originalEntranceCFrame = entrance.CFrame
		local newEntranceCFrame = plotCFrame
			* CFrame.new(Vector3.new(0, plotSize.Y / 2 - entranceSize.Y / 2, -(plotSize.Z / 2 + entranceSize.Z / 2)))

		local _, mailboxSize = mailbox:GetBoundingBox()
		local originalMailboxCFrame = mailbox:GetPivot()
		local newMailboxCFrame = plotCFrame
			* CFrame.new(Vector3.new(-6, -plotSize.Y / 2, -(plotSize.Z / 2 + mailboxSize.Z / 2 + 2)))

		entrance:PivotTo(newEntranceCFrame)
		mailbox:PivotTo(newMailboxCFrame)

		return function()
			entrance:PivotTo(originalEntranceCFrame)
			mailbox:PivotTo(originalMailboxCFrame)
		end
	end, { plotPart, anchor, plotCFrame, plotSizeNum })

	local children = {}

	children.DynamicPlot = props.BaseModel
			and props.BaseModel.Parent
			and ReactRoblox.createPortal({
				Part = e("Part", {
					Anchored = true,
					Size = Vector3.new(plotSizeNum, 1, plotSizeNum),
					CFrame = plotCFrame,
					Color = Color3.fromRGB(120, 180, 100),
					Material = Enum.Material.Grass,
					Parent = props.BaseModel,
					ref = setPlotPart,
				}),
			}, props.BaseModel)
		or nil

	children.PlacedItems = e(PlacedItemsManager, {
		PlayerId = props.PlayerId,
		BaseModel = props.BaseModel,
		GridSize = 4,
	})

	children.Customers = e(Customers, {
		PlayerId = props.PlayerId,
		BaseModel = props.BaseModel,
		Cashiers = cashiers, -- NEW: Pass the extracted cashiers safely down!
	})

	return e(React.Fragment, nil, children)
end

return Cafe
