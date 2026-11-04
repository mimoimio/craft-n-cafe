-- Shared/ReactComponents/BuildPanel/CategoryRow.luau
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage.Packages.React)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local Reflex = require(ReplicatedStorage.Packages.Reflex)

local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local PlacementController = require(ReplicatedStorage.Shared.Controllers.PlacementController)
local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)
local PaintConfig = require(ReplicatedStorage.Shared.Configs.PaintConfig)
local Types = require(ReplicatedStorage.Shared.Types)
local BuildersIcon = require(ReplicatedStorage.Shared.Utils.BuildersIcon)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local Grid = require(Primitives.Grid)
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local Padding = require(Primitives.Padding)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local DOWN_ICON = BuildersIcon["chevron-large-down"]

local function CategoryRow(props: {
	mobile: boolean,
	setCategory: (category: string) -> (),
})
	local selectedCategory, setSelectedCategory = useState(nil)
	local categories = PlaceablesModule.Categories
	local selecting, setSelecting = useState(false)
	useEffect(function()
		if props.setCategory then
			props.setCategory(selectedCategory)
		end
	end, { selectedCategory })

	local children = {}
	for i, category in categories do
		children[category] = e(SmallButton, {
			Size = UDim2.new(1, 0, 0, props.mobile and 20 or 40),
			AutomaticSize = Enum.AutomaticSize.None,
			Text = category,
			RichText = true,
			TextXAlignment = "Left",
			BackgroundTransparency = 0.2,
			Rounded = false,
			[React.Event.Activated] = function()
				setSelecting(false)
				setSelectedCategory(category)
			end,
		}, {})
	end
	children["All"] = e(SmallButton, {
		Size = UDim2.new(1, 0, 0, props.mobile and 20 or 40),
		AutomaticSize = Enum.AutomaticSize.None,
		Text = "All",
		RichText = true,
		TextXAlignment = "Left",
		BackgroundTransparency = 0.2,
		Rounded = false,
		[React.Event.Activated] = function()
			setSelecting(false)
			setSelectedCategory(nil)
		end,
	}, {})
	return e("Frame", {
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, props.mobile and 40 or 60),
		AutomaticSize = Enum.AutomaticSize.None,
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		ZIndex = 20,
	}, {
		e(Padding),
		DropdownButton = e(SmallButton, {
			Size = UDim2.new(1, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.None,
			RichText = true,
			[React.Event.Activated] = function()
				setSelecting(function(prev)
					return not prev
				end)
			end,
			BackgroundTransparency = 1,
			Padding = { All = UDim.new(0, 0) },
		}, {
			e("ImageLabel", {
				ZIndex = 1,
				ScaleType = Enum.ScaleType.Stretch,
				Image = "rbxassetid://124700292719297",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
			}, {
				e(Padding),
				e(SmallText, {
					Size = UDim2.fromScale(1, 1),
					Text = `Category: {selectedCategory == nil and "All" or selectedCategory} {DOWN_ICON}`,
					RichText = true,
					AutomaticSize = Enum.AutomaticSize.XY,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
			}),
		}),
		Dropdown = e(VStack, {
			Visible = selecting,
			AutomaticSize = Enum.AutomaticSize.XY,
			VerticalFlex = Enum.UIFlexAlignment.None,
			ClipsDescendants = false,
			Size = UDim2.new(1, 0, 0, 0),
			Position = UDim2.new(0, 0, 1, 0),
		}, children),
	})
end

return CategoryRow
