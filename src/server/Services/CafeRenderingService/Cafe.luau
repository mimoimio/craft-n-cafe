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
local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)

local PlacedItemsManager = require(script.Parent.PlacedItemsManager)
local Customers = require(script.Parent.Customers)
local Workers = require(script.Parent.Workers)

local function Cafe(props: { BaseModel: CafeTypes.CafeBase, PlayerId: string })
	local plotSizeNum, setPlotSizeNum = useState(32)
	local plotPart, setPlotPart = useState(nil)
	local cashiers: CashierItems, setCashiers: (CashierItem | (prev: CashierItems) -> CashierItems) -> () = useState({})
	local stations, setStations = useState({}) -- NEW: Store extracted stations

	useEffect(function()
		local function selectPlotState(state)
			return state.Plot and state.Plot[props.PlayerId] or nil
		end

		local selectPlotSize = createSelector({ selectPlotState }, function(plotState)
			return plotState and plotState.plotSize or 32
		end)

		-- OBSERVE CASHIERS
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

		local unsubCashiers = GlobalState:observe(selectCashiers, function(cashierItem: CashierItem, itemId)
			return itemId
		end, function(cashierItem: CashierItem, cashierUuid)
			setCashiers(function(prev: CashierItem)
				local newCashiers = table.clone(prev)
				newCashiers[cashierUuid] = cashierItem
				return newCashiers
			end)
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
		end)

		-- OBSERVE STATIONS
		local selectStations = function(state: GlobalState.GlobalState)
			local plotState = state.Plot[props.PlayerId]
			local newStations = {}
			if not plotState then
				return newStations
			end

			-- Map string names (e.g. "espresso_station") to their physical UUID
			for uuid, item in pairs(plotState.placedItems or {}) do
				newStations[item.id] = uuid
			end
			for uuid, item in pairs(plotState.spatialItems or {}) do
				newStations[item.id] = uuid
			end
			return newStations
		end

		local unsubStations = GlobalState:observe(selectStations, function(uuid: string, stationId: string)
			-- Discriminator: Observe changes based on the station's name (e.g. "espresso_station")
			return stationId
		end, function(uuid: string, stationId: string)
			-- On Add / On Change
			setStations(function(prev)
				local nextStations = table.clone(prev)
				nextStations[stationId] = uuid
				return nextStations
			end)
			-- On Remove
			return function()
				setStations(function(prev)
					local nextStations = table.clone(prev)
					nextStations[stationId] = nil
					return nextStations
				end)
			end
		end)

		local unsubSize = GlobalState:subscribe(selectPlotSize, setPlotSizeNum)

		-- Initialize state immediately
		setPlotSizeNum(selectPlotSize(GlobalState:getState()))

		return function()
			unsubSize()
			unsubCashiers()
			unsubStations()
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
		Cashiers = cashiers,
	})

	children.Workers = e(Workers, {
		PlayerId = props.PlayerId,
		BaseModel = props.BaseModel,
		Stations = stations, -- Pass the strictly observed stations
	})

	return e(React.Fragment, nil, children)
end

return Cafe
