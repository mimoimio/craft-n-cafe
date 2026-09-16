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
	local plotPart, setPlotPart = useState(nil)

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

	local anchor = props.BaseModel:FindFirstChild("Anchor")
	local plotCFrame = anchor and anchor.CFrame or CFrame.new(0, 0, 0)
	useEffect(function()
		-- pivot Entrance and mailbox in front

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

	-- Render the physical dynamic plot on the server

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
