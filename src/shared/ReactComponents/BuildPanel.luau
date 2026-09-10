-- Shared/ReactComponents/BuildPanel.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage.Packages.React)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local Reflex = require(ReplicatedStorage.Packages.Reflex)

local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local PlacementController = require(ReplicatedStorage.Shared.Controllers.PlacementController)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local VStack = require(Primitives.VStack)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)

local e = React.createElement
local useState = React.useState
local useSpring = ReactFlow.useSpring
local createSelector = Reflex.createSelector
local useEffect = React.useEffect
local useBreakpoint = require(script.Parent.Parent.Hooks.useBreakpoint)

local Models = ReplicatedStorage.Shared.Models

local function BuildPanel()
	local visible, setVisible = useState(false)
	local selectedItem, setSelectedItem = useState(nil)
	local xs, sm, md, lg, xl = useBreakpoint()
	local mobile = xs or sm or md

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

			if selectedItem == "DELETE_MODE" then
				PlacementController:setDeleteMode(true)
			elseif selectedItem then
				PlacementController:setDeleteMode(false)
				PlacementController:selectItem(selectedItem)
			else
				PlacementController:setDeleteMode(false)
				PlacementController:selectItem(nil)
			end
		else
			PlacementController:setBuildMode(false)
			PlacementController:setDeleteMode(false)
		end

		return function()
			if not visible then
				PlacementController:setBuildMode(false)
				PlacementController:setDeleteMode(false)
			end
		end
	end, { visible, selectedItem })
	-- Generate buttons for every model in ReplicatedStorage.Shared.Models
	local itemButtons = {}

	-- -- 1. Insert the special Delete Tool Button first
	-- itemButtons["DELETE_MODE"] = e(SmallButton, {
	-- 	Size = UDim2.new(1, 0, 0, 50),
	-- 	BackgroundColor3 = selectedItem == "DELETE_MODE" and Color3.new(0.8, 0.2, 0.2) or Color3.new(0.3, 0.1, 0.1),
	-- 	LayoutOrder = -1, -- Force it to the top of the list
	-- 	[React.Event.Activated] = function()
	-- 		UIState.selectBuildItem("DELETE_MODE")
	-- 	end,
	-- }, {
	-- 	e(SmallText, {
	-- 		Text = "🗑️",
	-- 		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	-- 	}),
	-- })

	-- 2. Generate standard item buttons
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

	local show, setShow = useState(true)
	local pos, setPos = useSpring({ start = 0, target = 0, damper = 1, speed = 10 })
	useEffect(function()
		if show then
			setPos({
				target = 0,
				damper = 1,
				speed = 10,
			})
		else
			setPos({
				target = 1,
				damper = 1,
				speed = 10,
			})
		end
	end, { show })

	return e("Frame", {
		Size = UDim2.new(0, mobile and 260 or 300, 1, 0),
		Position = pos:map(function(n)
			return UDim2.new(1, n * (mobile and 260 or 300), 0, 0)
		end),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Active = true,
		Visible = visible,
	}, {
		e(VStack, {
			-- Size = UDim2.new(0, mobile and 260 or 300, 1, 0),
			Position = UDim2.new(0, 0, 0.5, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			AnchorPoint = Vector2.new(1, 0.5),
			-- OnMount = warn,
			BackgroundTransparency = 1,
			BackgroundColor3 = Color3.new(0.1, 0.1, 0.1),
			Active = true,
			VerticalFlex = Enum.UIFlexAlignment.None,
			HorizontalFlex = Enum.UIFlexAlignment.None,
			Visible = visible,
			Size = UDim2.new(0, 0, 0, 0),
		}, {
			HideButton = e(SmallButton, {
				Image = "",
				[React.Event.Activated] = function()
					setShow(function(prev)
						return not prev
					end)
				end,
				Position = UDim2.new(0, 0, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				Size = UDim2.new(0, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
			}, {
				e("UIStroke", { Thickness = 2 }),
				e(SmallText, {
					TextSize = 48,
					Text = "👀",
					AutomaticSize = Enum.AutomaticSize.XY,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
				}),
			}),
			Delete = e(SmallButton, {
				Image = "",
				AutomaticSize = Enum.AutomaticSize.XY,
				Size = UDim2.new(0, 0, 0, 0),
				BackgroundColor3 = selectedItem == "DELETE_MODE" and Color3.new(1, 0.058823, 0.058823)
					or Color3.new(1, 0.341176, 0.341176),
				LayoutOrder = -1, -- Force it to the top of the list
				[React.Event.Activated] = function()
					local is = UIState:getState().buildItemId ~= "DELETE_MODE" and "DELETE_MODE" or "crate"
					UIState.selectBuildItem(is)
				end,
			}, {
				e("UIStroke", { Thickness = 2 }),
				e(SmallText, {
					TextSize = 48,
					Text = "🗑️",
					AutomaticSize = Enum.AutomaticSize.XY,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
				}),
			}),
		}),
		e(VStack, {
			Size = UDim2.new(0, mobile and 260 or 300, 1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 0.2,
			BackgroundColor3 = Color3.new(0.1, 0.1, 0.1),
			Active = true,
			Visible = visible,
		}, {
			Padding = e("UIPadding", {
				PaddingTop = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
			}),
			Header = e(SmallText, {
				Text = "Build Mode",
				Size = UDim2.new(1, 0, 0, 30),
				LayoutOrder = 1,
			}),
			ScrollingFrame = e("ScrollingFrame", {
				Size = UDim2.new(1, 0, 1, selectedItem and -90 or -40),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				ScrollBarThickness = 4,
				LayoutOrder = 2,
			}, {
				List = e("UIListLayout", { Padding = UDim.new(0, 5) }),
				Items = e(React.Fragment, nil, itemButtons),
			}),

			-- NEW: Dynamic Place Button, appears only when an item is selected
			PlaceActionContainer = (
				UserInputService.PreferredInput == Enum.PreferredInput.Touch
				or UserInputService.PreferredInput == Enum.PreferredInput.Gamepad
			)
					and selectedItem
					and e("Frame", {
						Size = UDim2.new(1, 0, 0, 50),
						BackgroundTransparency = 1,
						LayoutOrder = 3,
					}, {
						ActionButton = e(SmallButton, {
							Size = UDim2.new(1, 0, 1, 0),
							BackgroundColor3 = selectedItem == "DELETE_MODE" and Color3.new(0.8, 0.2, 0.2)
								or Color3.new(0.2, 0.7, 0.2),
							[React.Event.Activated] = function()
								if selectedItem == "DELETE_MODE" then
									PlacementController:attemptDestroyAtCursor()
								else
									PlacementController:placeCurrent()
								end
							end,
						}, {
							e(SmallText, {
								Text = selectedItem == "DELETE_MODE" and "DELETE ITEM" or "PLACE ITEM",
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
							}),
						}),
					})
				or nil,
		}),
	})
end

return BuildPanel
