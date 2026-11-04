-- Shared/ReactComponents/BuildPanel.luau
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
local useSpring = ReactFlow.useSpring
local createSelector = Reflex.createSelector
local useEffect = React.useEffect
local useBreakpoint = require(script.Parent.Parent.Hooks.useBreakpoint)
local useInputDevice = require(ReplicatedStorage.Shared.Hooks.useInputDevice)
local CategoryRow = require(script.CategoryRow)
local PaintDock = require(script.PaintDock)
local ItemButton = require(script.ItemButton)

local playerId = Players.LocalPlayer and tostring(Players.LocalPlayer.UserId) or "MockUser"

local function getContrastText(color: Color3): Color3
	local luminance = (color.R * 0.299) + (color.G * 0.587) + (color.B * 0.114)
	return luminance > 0.55 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
end
local function playPaintSound(name: string, speed: number?)
	SoundController.Sound(name, {
		PlaybackSpeed = speed or 1,
	})
end

local function prettySwatchName(name: string?): string
	if not name then
		return "Default"
	end
	return (name:gsub("(%u)", " %1"):gsub("^%s+", ""))
end

local function BuildPanel()
	local visible, setVisible = useState(UIState:getState() and UIState:getState().buildItemId)
	local selectedItem, setSelectedItem = useState(nil)
	local playerInventory, setPlayerInventory = useState(nil)
	local premiumPaintOwned, setPremiumPaintOwned = useState(false)

	-- [[ NEW PAINT STATE ]]
	local primaryColor, setPrimaryColor = useState(nil)
	local secondaryColor, setSecondaryColor = useState(nil)
	local activeChannel, setActiveChannel = useState("Primary")

	local xs, sm, md, lg, xl = useBreakpoint()
	local mobile = xs or sm or md
	local inputDevice = useInputDevice()

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

	-- 2b. Sync Premium Paint ownership
	useEffect(function()
		local function selectPremiumPaint(state)
			local stats = state.Stats and state.Stats[playerId]
			return stats and stats.OwnedGamePasses and stats.OwnedGamePasses.PremiumPaint == true or false
		end

		local unsub = GlobalState:subscribe(selectPremiumPaint, setPremiumPaintOwned)
		setPremiumPaintOwned(selectPremiumPaint(GlobalState:getState()))

		return unsub
	end, {})

	local DELETEMODE = selectedItem == "DELETE_MODE"
	local PAINTMODE = selectedItem == "PAINT_MODE"

	-- 3. Handle Controller Side-Effects
	useEffect(function()
		if not visible then
			return
		end

		PlacementController:setPaintColors(primaryColor, secondaryColor)

		if DELETEMODE then
			PlacementController:setDeleteMode(true)
		elseif PAINTMODE then
			PlacementController:setPaintMode(true)
		else
			PlacementController:setBuildMode(true)
			PlacementController:setDeleteMode(false)
			PlacementController:setPaintMode(false)
			PlacementController:selectItem(selectedItem)
		end
	end, { visible, selectedItem, primaryColor, secondaryColor })

	local show, setShow = useState(true)
	useEffect(function()
		if visible then
			PlacementController:setBuildMode(true)
			setShow(true)
		else
			PlacementController:setBuildMode(false)
			PlacementController:setDeleteMode(false)
			PlacementController:setPaintMode(false)
			PlacementController:selectItem(nil)
			UIState.selectBuildItem(nil)
		end
	end, { visible })

	-- [[ UPDATED: Gamepad Trigger Hooks ]]
	useEffect(function()
		if not visible or not selectedItem then
			return
		end

		local conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then
				return
			end

			-- R2 -> Place / Delete / Paint
			if input.KeyCode == Enum.KeyCode.ButtonR2 then
				if DELETEMODE then
					PlacementController:attemptDestroyAtCursor()
				elseif PAINTMODE then
					PlacementController:attemptPaintAtCursor()
				else
					PlacementController:placeCurrent()
				end
			-- L2 -> Rotate
			elseif input.KeyCode == Enum.KeyCode.ButtonL2 then
				PlacementController:rotateItem()
			end
		end)

		return function()
			conn:Disconnect()
		end
	end, { visible, selectedItem, DELETEMODE, PAINTMODE })

	local function getActionLabel(keyCode: Enum.KeyCode, actionText: string)
		if inputDevice == "Gamepad" then
			local iconSize = mobile and 16 or 24
			return `<font size="{iconSize}">{BuildersIcon.GetPromptText(keyCode, inputDevice)}</font>\n{actionText}`
		end
		return actionText
	end

	-- 4. Generate Inventory Buttons
	local itemButtons = {}

	useEffect(function()
		if playerInventory and selectedItem and not DELETEMODE and not PAINTMODE then
			if (playerInventory[selectedItem] or 0) <= 0 then
				UIState.selectBuildItem(nil)
			end
		end
	end, { playerInventory, selectedItem })

	local pos, setPos = useSpring({ start = 0, target = 0, damper = 1, speed = 10 })
	local itemSelected = selectedItem and true or false
	local category, setCategory = useState(nil)

	useEffect(function()
		if itemSelected then
			GuiService.SelectedObject = nil
			setShow(false)
		else
			setShow(true)
		end
	end, { itemSelected })

	useEffect(function()
		setPos({ target = show and 0 or 1, damper = 1, speed = 10 })
	end, { show })

	if not playerInventory then
		print("no playerinventory")
		return nil
	end

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
					Visible = (category == nil) or category == config.Category,
					OnMount = if itemId == "ice_station"
						then function(rbx)
							UIState.setTutorialTarget("BuildItem_ice_station", rbx)
						end
						else nil,
				})
			end
		end
	end

	return e("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
	}, {
		e(Padding, { All = UDim.new(0, 12) }),

		-- MAIN PANEL (Inventory + Side buttons for Close & Hide)
		MainPanel = e("Frame", {
			Size = pos:map(function(n)
				return UDim2.new(n, (1 - n) * (mobile and 360 or 480), 1, 0)
			end),
			Position = pos:map(function(n)
				return UDim2.new((1 + n), 0, 0, 0)
			end),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
			Active = true,
			Visible = visible,
			ZIndex = 3,
		}, {
			SideButtons = e("Frame", {
				Position = UDim2.new(0, 0, 0.5, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 1,
				Active = true,
				Size = UDim2.new(0, 0, 1, 0),
				ZIndex = 4,
			}, {
				Close = e(SmallButton, {
					Image = "",
					AutomaticSize = Enum.AutomaticSize.None,
					Size = UDim2.new(0, mobile and 40 or 60, 0, mobile and 40 or 60),
					BackgroundColor3 = Color3.new(1, 0.058823, 0.058823),
					[React.Event.Activated] = function()
						UIState.toggle("none")
					end,
					Position = UDim2.new(0.5, 0, 0, 0),
					AnchorPoint = Vector2.new(0.5, 0),
					LayoutOrder = 3,
					Padding = { All = UDim.new() },
				}, {
					e("UIStroke", { Thickness = 2, Transparency = (not DELETEMODE and not PAINTMODE) and 0.4 or nil }),
					e("ImageLabel", {
						ZIndex = 1,
						Image = "rbxassetid://17368208554",
						ScaleType = Enum.ScaleType.Fit,
						Size = UDim2.fromScale(1, 1),
						ImageTransparency = (not DELETEMODE and not PAINTMODE) and 0.4 or nil,
						BackgroundTransparency = 1,
					}),
				}),
				VStackGroup = e(VStack, {
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
							ScaleType = Enum.ScaleType.Fit,
							Size = UDim2.fromScale(1, 1),
							BackgroundTransparency = 1,
						}),
					}),
				}),
			}),
			Background = e("ImageLabel", {
				Image = "rbxassetid://120520009441669",
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(45, 45, 55, 55),
				AnchorPoint = Vector2.new(0, 0),
				Size = UDim2.new(1, 0, 1, 0),
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 1,
				ImageColor3 = Color3.new(0.6, 0.6, 0.6),
				ImageTransparency = 0.1,
				Visible = visible,
				ZIndex = 1,
			}),
			InventoryArea = e(VStack, {
				Size = UDim2.new(0, (mobile and 360 or 480), 1, 0),
				Position = UDim2.new(0.5, 0, 0, 0),
				AnchorPoint = Vector2.new(0.5, 0),
				Active = true,
				Padding = { All = UDim.new(0, 10) },
				Visible = visible,
				ZIndex = 2,
			}, {
				Header = e(SmallText, { Text = "Inventory", Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 1 }),

				Categories = e(CategoryRow, {
					mobile = mobile,
					setCategory = setCategory,
				}),

				ScrollingFrame = e("ScrollingFrame", {
					Selectable = false,
					Size = UDim2.new(1, 0, 1, selectedItem and -130 or -40),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					CanvasSize = UDim2.new(1, 0, 0, 0),
					BackgroundTransparency = 1,
					ScrollBarThickness = 4,
					LayoutOrder = 3,
				}, {
					e(HStack, {
						Size = UDim2.new(1, 0, 0, 0),
						AutomaticSize = Enum.AutomaticSize.XY,
						Wraps = true,
						Spacing = UDim.new(0, 8),
						VerticalAlignment = Enum.VerticalAlignment.Center,
						HorizontalAlignment = Enum.HorizontalAlignment.Left,
					}, {
						Items = e(React.Fragment, nil, itemButtons),
					}),
				}),
			}),
		}),

		-- MIDDLE CONTAINER (Paint dock + Toolbar wrapped vertically)
		MiddleContainer = e(VStack, {
			Position = UDim2.new(0.5, 0, 1, mobile and -24 or -40),
			AnchorPoint = Vector2.new(0.5, 1),
			AutomaticSize = Enum.AutomaticSize.XY,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Spacing = UDim.new(0, 8),
			Visible = visible,
			Size = UDim2.new(0, 0, 0, 0),
			ZIndex = 10,
		}, {
			Paint = (selectedItem and not DELETEMODE) and e(PaintDock, {
				activeChannel = activeChannel,
				primaryColor = primaryColor,
				secondaryColor = secondaryColor,
				premiumPaintOwned = premiumPaintOwned,
				mobile = mobile,
				paintMode = PAINTMODE,
				onSelectChannel = function(channel)
					setActiveChannel(channel)
				end,
				onSelectColor = function(name)
					if activeChannel == "Primary" then
						setPrimaryColor(name)
					else
						setSecondaryColor(name)
					end
				end,
				onClear = function()
					if activeChannel == "Primary" then
						setPrimaryColor(nil)
					else
						setSecondaryColor(nil)
					end
				end,
				onOpenStore = function()
					UIState.toggle("store")
				end,
			}) or nil,

			Toolbar = e(HStack, {
				Size = UDim2.new(0, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,

				Spacing = UDim.new(0, 16),
				LayoutOrder = 2,
			}, {
				Delete = e(SmallButton, {
					Image = "",
					AutomaticSize = Enum.AutomaticSize.None,
					Size = UDim2.new(0, mobile and 40 or 60, 0, mobile and 40 or 60),
					BackgroundTransparency = not DELETEMODE and 0.9 or nil,
					BackgroundColor3 = DELETEMODE and Color3.new(1, 0.058823, 0.058823)
						or Color3.new(1, 0.341176, 0.341176),
					[React.Event.Activated] = function()
						local is = UIState:getState().buildItemId ~= "DELETE_MODE" and "DELETE_MODE" or nil
						playPaintSound(is and "glass_005" or "glass_003", is and 1 or 0.9)
						UIState.selectBuildItem(is)
					end,
					LayoutOrder = 1,
					Padding = { All = UDim.new() },
				}, {
					e("UIStroke", { Thickness = 2, Transparency = not DELETEMODE and 0.4 or nil }),
					e("ImageLabel", {
						ZIndex = 1,
						Image = "rbxassetid://17368204793",
						ScaleType = Enum.ScaleType.Fit,
						Size = UDim2.fromScale(1, 1),
						ImageTransparency = not DELETEMODE and 0.4 or nil,
						BackgroundTransparency = 1,
					}),
					e(SmallText, {
						TextSize = mobile and 12 or 24,
						Text = `delete`,
						Size = UDim2.fromScale(1, 1),
						RichText = true,
						AutomaticSize = Enum.AutomaticSize.XY,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						TextXAlignment = Enum.TextXAlignment.Center,
						TextTransparency = not DELETEMODE and 0.4 or nil,
						TextStrokeTransparency = not DELETEMODE and 0.4 or nil,
					}),
				}),

				PaintTool = e(SmallButton, {
					Image = "",
					AutomaticSize = Enum.AutomaticSize.None,
					Size = UDim2.new(0, mobile and 40 or 60, 0, mobile and 40 or 60),
					BackgroundTransparency = not PAINTMODE and 0.9 or nil,
					BackgroundColor3 = PAINTMODE and Color3.new(0.2, 0.6, 1) or Color3.new(0.4, 0.7, 1),
					[React.Event.Activated] = function()
						local is = UIState:getState().buildItemId ~= "PAINT_MODE" and "PAINT_MODE" or nil
						playPaintSound(is and "glass_003" or "glass_004", is and 1.18 or 0.9)
						UIState.selectBuildItem(is)
					end,
					LayoutOrder = 2,
					Padding = { All = UDim.new() },
				}, {
					e("UIStroke", { Thickness = 2, Transparency = not PAINTMODE and 0.4 or nil }),
					e("ImageLabel", {
						ZIndex = 1,
						Image = "rbxassetid://18609516625",
						ScaleType = Enum.ScaleType.Fit,
						Size = UDim2.fromScale(1, 1),
						ImageTransparency = not PAINTMODE and 0.4 or nil,
						BackgroundTransparency = 1,
					}),
					e(SmallText, {
						TextSize = mobile and 12 or 24,
						Text = `paint`,
						Size = UDim2.fromScale(1, 1),
						RichText = true,
						AutomaticSize = Enum.AutomaticSize.XY,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						TextXAlignment = Enum.TextXAlignment.Center,
						TextTransparency = not PAINTMODE and 0.4 or nil,
						TextStrokeTransparency = not PAINTMODE and 0.4 or nil,
					}),
				}),

				Rotate = e(SmallButton, {
					Image = "",
					OverlayTextSize = 8,
					Size = UDim2.new(0, mobile and 40 or 60, 0, mobile and 40 or 60),
					AutomaticSize = Enum.AutomaticSize.None,
					LayoutOrder = 3,
					[React.Event.Activated] = function()
						playPaintSound("Cranking Sound (Wrench)", 1.15)
						PlacementController:rotateItem()
					end,
					Padding = { All = UDim.new() },
				}, {
					e("ImageLabel", {
						ZIndex = 1,
						Image = "rbxassetid://9559111831",
						ScaleType = Enum.ScaleType.Fit,
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
					}),
					e("UIStroke", { Thickness = 2 }),
					e(SmallText, {
						TextSize = mobile and 12 or 24,
						Text = getActionLabel(Enum.KeyCode.ButtonL2, "rotate"),
						Size = UDim2.fromScale(1, 1),
						RichText = true,
						AutomaticSize = Enum.AutomaticSize.XY,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						TextXAlignment = Enum.TextXAlignment.Center,
					}),
				}),

				Place = (inputDevice == "Touch" or inputDevice == "Gamepad") and selectedItem and e(SmallButton, {
					Image = "",
					AutomaticSize = Enum.AutomaticSize.None,
					Size = UDim2.new(0, mobile and 40 or 60, 0, mobile and 40 or 60),
					LayoutOrder = 4,
					BackgroundColor3 = DELETEMODE and Color3.new(0.8, 0.2, 0.2)
						or (PAINTMODE and Color3.new(0.2, 0.6, 1) or Color3.new(0.2, 0.7, 0.2)),
					OnMount = function(rbx)
						UIState.setTutorialTarget("PlaceButton", rbx)
					end,
					[React.Event.Activated] = function()
						if DELETEMODE then
							PlacementController:attemptDestroyAtCursor()
						elseif PAINTMODE then
							PlacementController:attemptPaintAtCursor()
						else
							PlacementController:placeCurrent()
						end
					end,
					Padding = { All = UDim.new() },
				}, {
					e("UIStroke", { Thickness = 2 }),
					e("ImageLabel", {
						ZIndex = 1,
						Image = DELETEMODE and "rbxassetid://17368204793"
							or (PAINTMODE and "rbxassetid://18609516625" or "rbxassetid://103478691850846"),
						ScaleType = Enum.ScaleType.Fit,
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						ImageTransparency = 0.4,
					}),
					e(SmallText, {
						TextSize = mobile and 12 or 24,
						Text = getActionLabel(
							Enum.KeyCode.ButtonR2,
							DELETEMODE and "destroy" or (PAINTMODE and "paint" or "place")
						),
						Size = UDim2.fromScale(1, 1),
						RichText = true,
						AutomaticSize = Enum.AutomaticSize.XY,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						TextXAlignment = Enum.TextXAlignment.Center,
					}),
				}) or nil,
			}),
		}),
	})
end

return BuildPanel
