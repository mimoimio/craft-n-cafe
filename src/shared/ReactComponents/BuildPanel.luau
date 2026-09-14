-- Shared/ReactComponents/BuildPanel.luau
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
local BuildersIcon = require(ReplicatedStorage.Shared.Utils.BuildersIcon)
local TOUCHICON = BuildersIcon["hand-half-ellipse"]

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

local playerId = Players.LocalPlayer and tostring(Players.LocalPlayer.UserId) or "MockUser"

-- FIX: Define a single memory address for the fallback inventory so Reflex doesn't infinite loop.
local DEFAULT_INV = {}

local function BuildPanel()
	local visible, setVisible = useState(false)
	local selectedItem, setSelectedItem = useState(nil)
	local playerInventory, setPlayerInventory = useState(DEFAULT_INV)

	local xs, sm, md, lg, xl = useBreakpoint()
	local mobile = xs or sm or md

	-- 1. Sync with UIState
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

	-- 2. NATIVE Sync with Inventory State
	useEffect(function()
		local function selectInventory(state)
			return state.Inventory and state.Inventory[playerId] or DEFAULT_INV
		end

		local unsub = GlobalState:subscribe(selectInventory, setPlayerInventory)
		setPlayerInventory(selectInventory(GlobalState:getState()))

		return unsub
	end, {})

	local DELETEMODE = selectedItem == "DELETE_MODE"

	-- 3. Handle Controller Side-Effects
	useEffect(function()
		if visible then
			PlacementController:setBuildMode(true)
			if DELETEMODE then
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

	-- 4. Generate Inventory Buttons
	local itemButtons = {}

	-- Loop through their exact inventory
	for itemId, count in pairs(playerInventory) do
		if count > 0 then
			local config = PlaceablesModule.GetConfig(itemId)
			if config then
				local isSelected = selectedItem == itemId

				itemButtons[itemId] = e(SmallButton, {
					Size = UDim2.new(1, 0, 0, 50),
					[React.Event.Activated] = function()
						UIState.selectBuildItem(itemId)
					end,
				}, {
					e(SmallText, {
						Text = `{config.DisplayName} (x{count}){isSelected and "\n[Selected]" or ""}`,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
					}),
				})
			end
		end
	end

	-- Automatically deselect if the player places their very last item of that type
	useEffect(function()
		if selectedItem and selectedItem ~= "DELETE_MODE" then
			if (playerInventory[selectedItem] or 0) <= 0 then
				UIState.selectBuildItem(nil)
			end
		end
	end, { playerInventory, selectedItem })

	local show, setShow = useState(true)
	local pos, setPos = useSpring({ start = 0, target = 0, damper = 1, speed = 10 })

	useEffect(function()
		setPos({ target = show and 0 or 1, damper = 1, speed = 10 })
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
			Position = UDim2.new(0, 0, 0.5, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			BackgroundColor3 = Color3.new(0.1, 0.1, 0.1),
			Active = true,
			VerticalFlex = Enum.UIFlexAlignment.None,
			HorizontalFlex = Enum.UIFlexAlignment.None,
			Visible = visible,
			Spacing = UDim.new(0, 8),
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
				Size = UDim2.new(0, mobile and 40 or 60, 0, mobile and 40 or 60),
				AutomaticSize = Enum.AutomaticSize.None,
				AnchorPoint = Vector2.new(1, 0.5),
				LayoutOrder = 1,
				Padding = { All = UDim.new() },
			}, {
				e("UIStroke", { Thickness = 2 }),
				e("ImageLabel", {
					ZIndex = 1,
					Image = show and "rbxassetid://15403015683" or "rbxassetid://15403018096",
					-- Size = UDim2.new(0, BUTTONHEIGHT, 0, BUTTONHEIGHT),
					ScaleType = Enum.ScaleType.Fit,
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
				}),
			}),
			Delete = e(SmallButton, {
				Image = "",
				AutomaticSize = Enum.AutomaticSize.None,
				Size = UDim2.new(0, mobile and 40 or 60, 0, mobile and 40 or 60),
				BackgroundTransparency = not DELETEMODE and 0.9 or nil,
				BackgroundColor3 = DELETEMODE and Color3.new(1, 0.058823, 0.058823)
					or Color3.new(1, 0.341176, 0.341176),
				[React.Event.Activated] = function()
					local is = UIState:getState().buildItemId ~= "DELETE_MODE" and "DELETE_MODE" or nil
					UIState.selectBuildItem(is)
				end,
				LayoutOrder = 2,
				Padding = { All = UDim.new() },
			}, {
				e("UIStroke", { Thickness = 2, Transparency = not DELETEMODE and 0.4 or nil }),

				e("ImageLabel", {
					ZIndex = 1,
					Image = "rbxassetid://17368204793",
					-- Size = UDim2.new(0, BUTTONHEIGHT, 0, BUTTONHEIGHT),
					ScaleType = Enum.ScaleType.Fit,
					Size = UDim2.fromScale(1, 1),
					ImageTransparency = not DELETEMODE and 0.4 or nil,
					BackgroundTransparency = 1,
				}),
				e(SmallText, {
					TextSize = mobile and 10 or 12,
					Text = `delete mode`,
					Size = UDim2.fromScale(1, 1),
					RichText = true,
					AutomaticSize = Enum.AutomaticSize.XY,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextTransparency = not DELETEMODE and 0.4 or nil,
					TextStrokeTransparency = not DELETEMODE and 0.4 or nil,
				}),
			}),
			Rotate = e(SmallButton, {
				Image = "",
				OverlayTextSize = 8,
				Size = UDim2.new(0, mobile and 40 or 60, 0, mobile and 40 or 60),
				AutomaticSize = Enum.AutomaticSize.None,
				LayoutOrder = 3,
				[React.Event.Activated] = function()
					PlacementController:rotateItem()
				end,
				Padding = { All = UDim.new() },
			}, {
				e("ImageLabel", {
					ZIndex = 1,
					Image = "rbxassetid://9559111831",
					-- Size = UDim2.new(0, BUTTONHEIGHT, 0, BUTTONHEIGHT),
					ScaleType = Enum.ScaleType.Fit,
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
				}),
				e("UIStroke", { Thickness = 2 }),
				e(SmallText, {
					TextSize = mobile and 10 or 12,
					Text = `rotate`,
					Size = UDim2.fromScale(1, 1),
					RichText = true,
					AutomaticSize = Enum.AutomaticSize.XY,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					TextXAlignment = Enum.TextXAlignment.Center,
				}),
			}),
			Place = (
				UserInputService.PreferredInput == Enum.PreferredInput.Touch
				or UserInputService.PreferredInput == Enum.PreferredInput.Gamepad
			)
					and selectedItem
					and e(SmallButton, {
						Image = "",
						OverlayTextSize = 8,
						AutomaticSize = Enum.AutomaticSize.XY,
						Size = UDim2.new(0, 0, 0, 0),
						LayoutOrder = 4,
						BackgroundColor3 = DELETEMODE and Color3.new(0.8, 0.2, 0.2) or Color3.new(0.2, 0.7, 0.2),
						[React.Event.Activated] = function()
							if DELETEMODE then
								PlacementController:attemptDestroyAtCursor()
							else
								PlacementController:placeCurrent()
							end
						end,
					}, {
						e("UIStroke", { Thickness = 2 }),
						e(SmallText, {
							MinTextSize = 12,
							MaxTextSize = 48,
							Text = `<font size="48">{TOUCHICON}</font>\n<font size="12">{DELETEMODE and "delete\nitem" or "place\nitem"}</font>`,
							RichText = true,
							TextXAlignment = Enum.TextXAlignment.Center,
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
						}),
					})
				or nil,
		}),
		e(VStack, {
			Size = UDim2.new(0, mobile and 260 or 300, 1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 0.2,
			BackgroundColor3 = Color3.new(0.1, 0.1, 0.1),
			Active = true,
			Padding = { All = UDim.new(0, 10) },
			Visible = visible,
		}, {
			Header = e(SmallText, { Text = "Inventory", Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 1 }),
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
		}),
	})
end

return BuildPanel
