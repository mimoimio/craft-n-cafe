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
local Types = require(ReplicatedStorage.Shared.Types)
local BuildersIcon = require(ReplicatedStorage.Shared.Utils.BuildersIcon)
local TOUCHICON = BuildersIcon["hand-half-ellipse"]

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)

local e = React.createElement
local useState = React.useState
local useBinding = React.useBinding
local useSpring = ReactFlow.useSpring
local createSelector = Reflex.createSelector
local useEffect = React.useEffect
local useBreakpoint = require(script.Parent.Parent.Hooks.useBreakpoint)

local playerId = Players.LocalPlayer and tostring(Players.LocalPlayer.UserId) or "MockUser"
local function ItemButton(props: {
	isSelected: boolean,
	config: Types.PlaceableConfig,
	count: number,
	mobile: boolean,
})
	local itemId = props.config.Id
	local isSelected = props.isSelected
	local count = props.count
	local currentCamera: Camera, setCurrentCamera = useState(nil)
	local worldModel, setWorldModel = useState(nil)
	local modelClone, setModelClone = useState(nil)
	local mobile = props.mobile
	useEffect(function()
		if not worldModel then
			return
		end
		local prefab = ReplicatedStorage.Shared.Models:FindFirstChild(itemId)
		if not prefab then
			return
		end
		local clone = prefab:Clone()
		clone:PivotTo(CFrame.new(Vector3.zero))
		clone.Parent = worldModel
		setModelClone(clone)

		return function()
			clone:Destroy()
			setModelClone(nil)
		end
	end, { worldModel })

	useEffect(function()
		if not (worldModel and currentCamera and modelClone) then
			return
		end
		currentCamera:ZoomToExtents(modelClone:GetBoundingBox())
	end, { worldModel, currentCamera, modelClone })

	return e(SmallButton, {
		Size = UDim2.new(0, mobile and 60 or 80, 0, mobile and 60 or 80),
		AutomaticSize = Enum.AutomaticSize.None,
		[React.Event.Activated] = function()
			UIState.selectBuildItem(itemId)
		end,
		BackgroundColor3 = isSelected and Color3.new(0, 1, 0) or nil,
		Padding = { All = UDim.new() },
	}, {
		e("ImageLabel", {
			ZIndex = 1,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			AnchorPoint = Vector2.one * 0.5,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			ImageColor3 = isSelected and Color3.new(0, 1, 0) or nil,
			Image = "rbxassetid://103478691850846",
		}, { e("UIScale", { Scale = isSelected and 1.1 or 1 }) }),
		e("ViewportFrame", {
			ZIndex = 2,
			CurrentCamera = currentCamera,
			Size = UDim2.new(1, 0, 1, mobile and -6 or -12),
			LightDirection = Vector3.new(0, -1, -1),
			-- BackgroundTransparency = 0,
			-- BackgroundColor3 = Color3.new(1, 0, 0),
			BackgroundTransparency = 1,
			Active = false,
			ImageTransparency = 0,
		}, {
			-- Add the WorldModel here to enable animation and physics processing
			World = e("WorldModel", {
				ref = setWorldModel,
			}, {

				Camera = e("Camera", {
					ref = setCurrentCamera,
					CFrame = CFrame.new(Vector3.new(20, 20, -20), Vector3.zero),
					FieldOfView = 45,
				}),
			}),
		}),
		e(SmallText, {
			TextSize = 10,
			Text = `{props.config.DisplayName}`,
			-- Text = `{props.config.DisplayName} {isSelected and "\n[Selected]" or ""}`,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			TextWrapped = true,
			ZIndex = 3,
			AutomaticSize = Enum.AutomaticSize.None,
			Size = UDim2.new(1, 0, 1, mobile and -6 or -12),
		}),
		e(SmallText, {
			TextSize = 20,
			Text = `x{count}`,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			TextWrapped = true,
			ZIndex = 3,
			AutomaticSize = Enum.AutomaticSize.XY,
			Position = UDim2.new(0, 8, 0, 0),
		}),
	})
end
local function BuildPanel()
	local visible, setVisible = useState(false)
	local selectedItem, setSelectedItem = useState(nil)
	local playerInventory, setPlayerInventory = useState(nil)

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
			return state.Inventory and state.Inventory[playerId] or nil
		end

		local unsub = GlobalState:subscribe(selectInventory, setPlayerInventory)
		setPlayerInventory(selectInventory(GlobalState:getState()))

		return unsub
	end, {})

	local DELETEMODE = selectedItem == "DELETE_MODE"

	-- 3. Handle Controller Side-Effects
	useEffect(function()
		if not visible then
			return
		end
		if DELETEMODE then
			PlacementController:setDeleteMode(true)
		else
			PlacementController:setBuildMode(true)
			PlacementController:setDeleteMode(false)
			PlacementController:selectItem(selectedItem)
		end
	end, { visible, selectedItem })
	local show, setShow = useState(true)
	useEffect(function()
		if visible then
			PlacementController:setBuildMode(true)
			setShow(true)
		else
			PlacementController:setBuildMode(false)
			PlacementController:setDeleteMode(false)
			PlacementController:selectItem(nil)
			UIState.selectBuildItem(nil)
		end
	end, { visible })

	-- 4. Generate Inventory Buttons
	local itemButtons = {}

	-- Automatically deselect if the player places their very last item of that type
	useEffect(function()
		if playerInventory and selectedItem and selectedItem ~= "DELETE_MODE" then
			if (playerInventory[selectedItem] or 0) <= 0 then
				UIState.selectBuildItem(nil)
			end
		end
	end, { playerInventory, selectedItem })

	local pos, setPos = useSpring({ start = 0, target = 0, damper = 1, speed = 10 })
	local itemSelected = selectedItem and true or false
	useEffect(function()
		if itemSelected then
			setShow(false)
		else
			setShow(true)
		end
	end, { itemSelected })
	useEffect(function()
		setPos({ target = show and 0 or 1, damper = 1, speed = 10 })
	end, { show })

	if not playerInventory then
		return
	end
	-- Loop through their exact inventory
	for itemId, count in pairs(playerInventory) do
		if count > 0 then
			local config = PlaceablesModule.GetConfig(itemId)
			if config then
				local isSelected = selectedItem == itemId
				itemButtons[itemId] = e(ItemButton, {
					isSelected = isSelected,
					config = config,
					count = count,
					mobile = mobile,
				})
			end
		end
	end

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
		e("Frame", {
			Position = UDim2.new(0, 0, 0.5, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			Active = true,
			Size = UDim2.new(0, 0, 1, 0),
			ZIndex = 4,
		}, {
			Delete = e(SmallButton, {
				Image = "",
				AutomaticSize = Enum.AutomaticSize.None,
				Size = UDim2.new(0, mobile and 40 or 60, 0, mobile and 40 or 60),
				BackgroundTransparency = not DELETEMODE and 0.9 or nil,
				BackgroundColor3 = DELETEMODE and Color3.new(1, 0.058823, 0.058823)
					or Color3.new(1, 0.341176, 0.341176),
				[React.Event.Activated] = function()
					UIState.toggle("none")
				end,
				Position = UDim2.new(0.5, 0, 0, 0),
				AnchorPoint = Vector2.new(0.5, 0),
				LayoutOrder = 2,
				Padding = { All = UDim.new() },
			}, {
				e("UIStroke", { Thickness = 2, Transparency = not DELETEMODE and 0.4 or nil }),

				e("ImageLabel", {
					ZIndex = 1,
					Image = "rbxassetid://17368208554",
					-- Size = UDim2.new(0, BUTTONHEIGHT, 0, BUTTONHEIGHT),
					ScaleType = Enum.ScaleType.Fit,
					Size = UDim2.fromScale(1, 1),
					ImageTransparency = not DELETEMODE and 0.4 or nil,
					BackgroundTransparency = 1,
				}),
			}),
			e(VStack, {
				Position = UDim2.new(0, 0, 0.5, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				BackgroundColor3 = Color3.new(0.1, 0.1, 0.1),
				Active = true,
				VerticalFlex = Enum.UIFlexAlignment.None,
				HorizontalFlex = Enum.UIFlexAlignment.None,
				Visible = visible,
				Spacing = UDim.new(0, 8),
				Size = UDim2.new(0, 0, 0, 0),
				ZIndex = 4,
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
		}),
		e("ImageLabel", {
			Image = "rbxassetid://103478691850846",
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(8, 8, 92, 92),
			AnchorPoint = Vector2.new(1, 0),
			Size = UDim2.new(0, mobile and 260 or 300, 1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			ImageColor3 = Color3.new(0.6, 0.6, 0.6),
			ImageTransparency = 0.2,
			Visible = visible,
			ZIndex = 1,
		}),
		e(VStack, {
			Size = UDim2.new(0, mobile and 260 or 300, 1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			AnchorPoint = Vector2.new(1, 0),
			-- BackgroundTransparency = 0.2,
			Active = true,
			Padding = { All = UDim.new(0, 10) },
			Visible = visible,
			ZIndex = 2,
		}, {
			Header = e(SmallText, { Text = "Inventory", Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 1 }),
			ScrollingFrame = e("ScrollingFrame", {
				Size = UDim2.new(1, 0, 1, selectedItem and -90 or -40),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 1,
				ScrollBarThickness = 4,
				LayoutOrder = 2,
			}, {
				-- List = e("UIListLayout", { Padding = UDim.new(0, 5) }),
				e(HStack, {
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.XY,
					-- BackgroundTransparency = 0,
					Wraps = true,
					Spacing = UDim.new(0, 8),
					VerticalAlignment = Enum.VerticalAlignment.Center,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
				}, {

					Items = e(React.Fragment, nil, itemButtons),
				}),
			}),
		}),
	})
end

return BuildPanel
