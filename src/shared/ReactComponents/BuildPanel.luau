-- Shared/ReactComponents/BuildPanel.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Reflex = require(ReplicatedStorage.Packages.Reflex)

local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local PlacementController = require(ReplicatedStorage.Shared.Controllers.PlacementController)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local VStack = require(Primitives.VStack)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)

local e = React.createElement
local useState = React.useState
local createSelector = Reflex.createSelector
local useEffect = React.useEffect

local Models = ReplicatedStorage.Shared.Models

local function BuildPanel()
	local visible, setVisible = useState(false)
	local selectedItem, setSelectedItem = useState(nil)

	-- Sync with Reflex
	useEffect(function()
		local unsub = UIState:subscribe(
			createSelector({
				function(state)
					return state.panel == "build"
				end,
				function(state)
					return state.buildItemId
				end,
			}, function(isOpen, itemId)
				return { isOpen = isOpen, itemId = itemId }
			end),
			function(mapped)
				setVisible(mapped.isOpen)
				setSelectedItem(mapped.itemId)
			end
		)

		local state = UIState:getState()
		setVisible(state.panel == "build")
		setSelectedItem(state.buildItemId)

		return unsub
	end, {})

	-- Handle Controller Side-Effects natively inside the panel
	useEffect(function()
		if visible then
			PlacementController:setBuildMode(true)
			if selectedItem then
				PlacementController:selectItem(selectedItem)
			end
		else
			PlacementController:setBuildMode(false)
		end

		-- Cleanup when the panel unmounts or state changes
		return function()
			if not visible then
				PlacementController:setBuildMode(false)
			end
		end
	end, { visible, selectedItem })

	-- Generate buttons for every model in ReplicatedStorage.Shared.Models
	local itemButtons = {}
	for _, model in Models:GetChildren() do
		local isSelected = selectedItem == model.Name

		itemButtons[model.Name] = e(SmallButton, {
			Size = UDim2.new(1, 0, 0, 50),
			[React.Event.Activated] = function()
				UIState.selectBuildItem(model.Name)
			end,
		}, {
			e(SmallText, {
				Text = model.Name .. (isSelected and " (Selected)" or ""),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),
		})
	end

	return e(VStack, {
		Size = UDim2.new(0, 300, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		AnchorPoint = Vector2.new(0, 0),
		BackgroundTransparency = 0.2,
		BackgroundColor3 = Color3.new(0.1, 0.1, 0.1),
		Active = true,
		Visible = visible,
	}, {
		Padding = e(
			"UIPadding",
			{ PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }
		),
		Header = e(SmallText, {
			Text = "Build Mode",
			Size = UDim2.new(1, 0, 0, 30),
		}),
		ScrollingFrame = e("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, -40),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			ScrollBarThickness = 4,
		}, {
			List = e("UIListLayout", { Padding = UDim.new(0, 5) }),
			Items = e(React.Fragment, nil, itemButtons),
		}),
	})
end

return BuildPanel
