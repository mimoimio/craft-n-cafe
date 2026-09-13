-- ServerScriptService/Server/Services/CafeRenderingService/Cafe.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)

local PlacedItemsManager = require(script.Parent.PlacedItemsManager)
local Customers = require(script.Parent.Customers)

local function Cafe(props: { BaseModel: CafeTypes.CafeBase, PlayerId: string })
	-- 1. Native Reflex Subscription Pattern
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

	local children = {}

	-- 2. Render the physical dynamic plot on the server
	local anchor = props.BaseModel:FindFirstChild("Anchor")
	local plotCFrame = anchor and anchor.CFrame or CFrame.new(0, 0, 0)

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
				}),
			}, props.BaseModel)
		or nil

	-- The PlacedItemsManager now builds the entire physical cafe
	children.PlacedItems = e(PlacedItemsManager, {
		PlayerId = props.PlayerId,
		BaseModel = props.BaseModel,
		GridSize = 4,
	})

	-- Customers will eventually need to read the PlotState to know where tables/queues are
	children.Customers = e(Customers, {
		PlayerId = props.PlayerId,
		BaseModel = props.BaseModel,
	})

	return e(React.Fragment, nil, children)
end

return Cafe
