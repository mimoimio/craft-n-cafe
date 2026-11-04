-- Shared/ReactComponents/ShopPanel/ShopTabs.luau
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Mionum = require(ReplicatedStorage.Packages.Mionum)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local Reflex = require(ReplicatedStorage.Packages.Reflex)

local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)
local PlotExpansionsConfig = require(ReplicatedStorage.Shared.Configs.PlotExpansionsConfig)
local WorkersConfig = require(ReplicatedStorage.Shared.Configs.WorkersConfig)
local UpgradesConfig = require(ReplicatedStorage.Shared.Configs.UpgradesConfig)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local Toasts = require(script.Parent.Parent.Parent.ReactComponents.Toasts)

local e = React.createElement
local useState = React.useState
local useRef = React.useRef
local useBinding = React.useBinding
local useEffect = React.useEffect
local useSpring = ReactFlow.useSpring
local BuildersIcon = require(script.Parent.Parent.Parent.Utils.BuildersIcon)

local DOWN_ICON = BuildersIcon["chevron-large-down"]
local function Padding(props: { All: UDim })
	local All = props.All or UDim.new(0, 4)
	return e("UIPadding", { PaddingTop = All, PaddingBottom = All, PaddingLeft = All, PaddingRight = All })
end

local playerId = Players.LocalPlayer and tostring(Players.LocalPlayer.UserId) or "MockUser"

local function ShopTabs(props: {
	mobile: boolean,
	setTab: (string) -> ()?,
	tab: string,
	LayoutOrder: number?,
	level: number,
})
	local toast = Toasts.useToast()

	local function handleTab(tabName: string, reqLevel: number)
		if props.level >= reqLevel then
			if props.setTab then
				props.setTab(tabName)
			end
		else
			if toast then
				toast.open(`Unlocks at Level {reqLevel} 🔒`, 3, Color3.new(1, 0.3, 0.3))
			end
		end
	end

	return e(HStack, {
		Size = UDim2.new(0, 0, 0, 0),
		LayoutOrder = props.LayoutOrder,
		AutomaticSize = Enum.AutomaticSize.XY,
		VerticalFlex = "Fill",
		HorizontalFlex = "Fill",
		Spacing = UDim.new(0, props.mobile and 4 or 8),
	}, {
		e(SmallButton, {
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 0),
			[React.Event.Activated] = function()
				handleTab("item", 1)
			end,
			BackgroundTransparency = props.tab == "item" and 0 or 0.6,
		}, {
			e(SmallText, {
				Text = "Item",
				TextTransparency = props.tab == "item" and 0 or 0.6,
				TextStrokeTransparency = props.tab == "item" and 0 or 0.6,
			}),
		}),
		e(SmallButton, {
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundColor3 = props.level < 4 and Color3.new(0.4, 0.4, 0.4) or nil,
			[React.Event.Activated] = function()
				handleTab("upgrade", 4)
			end,
			BackgroundTransparency = props.tab == "upgrade" and 0 or 0.6,
		}, {
			e(SmallText, {
				Text = "Upgrade",
				TextTransparency = props.tab == "upgrade" and 0 or 0.6,
				TextStrokeTransparency = props.tab == "upgrade" and 0 or 0.6,
			}),
		}),
		e(SmallButton, {
			LayoutOrder = 3,
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundColor3 = props.level < 4 and Color3.new(0.4, 0.4, 0.4) or nil,
			[React.Event.Activated] = function()
				handleTab("staff", 4)
			end,
			BackgroundTransparency = props.tab == "staff" and 0 or 0.6,
		}, {
			e(SmallText, {
				Text = "Staff",
				TextTransparency = props.tab == "staff" and 0 or 0.6,
				TextStrokeTransparency = props.tab == "staff" and 0 or 0.6,
			}),
		}),
	})
end
return ShopTabs
