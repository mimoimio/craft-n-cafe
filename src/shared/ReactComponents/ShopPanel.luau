-- Shared/ReactComponents/ShopPanel.luau
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local Reflex = require(ReplicatedStorage.Packages.Reflex)

local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)
local PlotExpansionsConfig = require(ReplicatedStorage.Shared.Configs.PlotExpansionsConfig)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useSpring = ReactFlow.useSpring
local useBreakpoint = require(script.Parent.Parent.Hooks.useBreakpoint)

local playerId = Players.LocalPlayer and tostring(Players.LocalPlayer.UserId) or "MockUser"

-- Fallback constants to prevent Reflex infinite loops
local DEFAULT_STATS = { Level = 1, Cash = 0 }
local DEFAULT_PLOT = { placedItems = {}, spatialItems = {} }
local DEFAULT_INV = {}
local function ItemButton(
	props: {
		isSelected: boolean,
		isLocked: boolean,
		config: Types.PlaceableConfig,
		mobile: boolean,
		-- [React.Event.Activated]: () -> (),
	}
)
	local itemId = props.config.Id
	local isSelected = props.isSelected
	local isLocked = props.isLocked
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
		[React.Event.Activated] = props[React.Event.Activated],
		BackgroundColor3 = isSelected and Color3.new(0.2, 0.6, 0.2) or nil,
		LayoutOrder = props.config.UnlockLevel,
		Padding = { All = UDim.new() },
	}, {
		-- Locked Overlay Tint
		isLocked and e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.5,
			ZIndex = 4,
		}, {
			e(SmallText, {
				Text = "🔒",
				TextSize = 24,
				Size = UDim2.fromScale(1, 1),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}),
		}) or nil,

		e("ViewportFrame", {
			ZIndex = 1,
			CurrentCamera = currentCamera,
			Size = UDim2.new(1, 0, 1, 0),
			LightDirection = Vector3.new(0, -1, -1),
			BackgroundTransparency = 1,
			Active = false,
			ImageTransparency = isLocked and 0.5 or 0, -- Dim the 3D model if locked
		}, {
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
	})
end

local function ShopPanel()
	local visible, setVisible = useState(false)
	local selectedItem, setSelectedItem = useState(nil) -- Local state for Shop detail view

	local playerStats, setPlayerStats = useState(DEFAULT_STATS)
	local playerInventory, setPlayerInventory = useState(DEFAULT_INV)
	local plotState, setPlotState = useState(DEFAULT_PLOT)

	local xs, sm, md, lg, xl = useBreakpoint()
	local mobile = xs or sm or md

	-- 1. Sync with UIState for panel visibility
	useEffect(function()
		local function selectPanel(state)
			return state.panel
		end
		local unsub = UIState:subscribe(selectPanel, function(panel)
			setVisible(panel == "shop")
			if panel ~= "shop" then
				setSelectedItem(nil)
			end -- Clear selection when closed
		end)
		setVisible(selectPanel(UIState:getState()) == "shop")
		return unsub
	end, {})

	-- 2. Native Sync with GlobalState
	useEffect(function()
		local function selectStats(state)
			return state.Stats and state.Stats[playerId] or DEFAULT_STATS
		end
		local function selectInv(state)
			return state.Inventory and state.Inventory[playerId] or DEFAULT_INV
		end
		local function selectPlot(state)
			return state.Plot and state.Plot[playerId] or DEFAULT_PLOT
		end

		local unsubStats = GlobalState:subscribe(selectStats, setPlayerStats)
		local unsubInv = GlobalState:subscribe(selectInv, setPlayerInventory)
		local unsubPlot = GlobalState:subscribe(selectPlot, setPlotState)

		setPlayerStats(selectStats(GlobalState:getState()))
		setPlayerInventory(selectInv(GlobalState:getState()))
		setPlotState(selectPlot(GlobalState:getState()))

		return function()
			unsubStats()
			unsubInv()
			unsubPlot()
		end
	end, {})

	local function getTotalOwned(itemId)
		local count = playerInventory[itemId] or 0
		for _, item in pairs(plotState.placedItems or {}) do
			if item.id == itemId then
				count += 1
			end
		end
		for _, item in pairs(plotState.spatialItems or {}) do
			if item.id == itemId then
				count += 1
			end
		end
		return count
	end

	-- 3. Pre-calculate details for the selected item overlay
	local selectedConfig = selectedItem and PlaceablesModule.GetConfig(selectedItem)
	local detailsOverlay = nil

	if selectedConfig then
		local totalOwned = getTotalOwned(selectedConfig.Id)
		local isMaxed = selectedConfig.MaxAllowed ~= math.huge and totalOwned >= selectedConfig.MaxAllowed
		local canAfford = playerStats.Cash >= selectedConfig.Price
		local isLocked = playerStats.Level < selectedConfig.UnlockLevel

		local btnText = `Buy (💲{selectedConfig.Price})`
		local btnColor = Color3.new(0.2, 0.7, 0.2)
		local canBuy = true

		if isLocked then
			btnText = `Locked (Requires Lvl {selectedConfig.UnlockLevel})`
			btnColor = Color3.new(0.4, 0.4, 0.4)
			canBuy = false
		elseif isMaxed then
			btnText = "Max Limit Reached"
			btnColor = Color3.new(0.4, 0.4, 0.4)
			canBuy = false
		elseif not canAfford then
			btnText = "Not Enough Cash"
			btnColor = Color3.new(0.8, 0.2, 0.2)
			canBuy = false
		end

		detailsOverlay = e(VStack, {
			Position = UDim2.new(0, -10, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			Size = UDim2.new(0, mobile and 240 or 400, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Color3.new(0.1, 0.1, 0.1),
			BackgroundTransparency = 0.1,
			Padding = {
				All = UDim.new(0, 10),
			},
			Spacing = UDim.new(0, 8),
			ZIndex = 5,
		}, {
			Header = e(SmallText, {
				Text = `<font size="20"><b>{selectedConfig.DisplayName}</b></font>\n<font color="rgb(180,180,180)">{selectedConfig.Category}</font>`,
				RichText = true,
				TextXAlignment = Enum.TextXAlignment.Center,
				Size = UDim2.new(1, 0, 0, 40),
			}),

			ItemImage = selectedConfig.Image and e("ImageLabel", {
				Size = UDim2.new(1, 0, 0, 100),
				BackgroundTransparency = 1,
				Image = selectedConfig.Image,
				ScaleType = Enum.ScaleType.Fit,
				LayoutOrder = 1,
			}) or nil,

			Divider = e("Frame", {
				Size = UDim2.new(1, 0, 0, 2),
				BackgroundColor3 = Color3.new(0.3, 0.3, 0.3),
				BorderSizePixel = 0,
				LayoutOrder = 2,
			}),

			Stats = e(SmallText, {
				Text = `<b>Price:</b> 💲{selectedConfig.Price}\n<b>Unlock Level:</b> {selectedConfig.UnlockLevel}\n<b>Owned:</b> {totalOwned} / {selectedConfig.MaxAllowed == math.huge and "∞" or selectedConfig.MaxAllowed}`,
				RichText = true,
				Size = UDim2.new(1, 0, 0, 60),
				LayoutOrder = 3,
			}),

			BuyButton = e(SmallButton, {
				Size = UDim2.new(1, 0, 0, 45),
				BackgroundColor3 = btnColor,
				LayoutOrder = 4,
				[React.Event.Activated] = function()
					if canBuy then
						Remotes.BuyItem:FireServer({ itemId = selectedConfig.Id, amount = 1 })
					end
				end,
			}, {
				e("UIStroke", { Thickness = 2 }),
				e(SmallText, { Text = btnText, HorizontalAlignment = Enum.HorizontalAlignment.Center }),
			}),

			CloseButton = e(SmallButton, {
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundColor3 = Color3.new(0.8, 0.2, 0.2),
				BackgroundTransparency = 0.5,
				LayoutOrder = 5,
				[React.Event.Activated] = function()
					setSelectedItem(nil)
				end,
			}, { e(SmallText, { Text = "Cancel", HorizontalAlignment = Enum.HorizontalAlignment.Center }) }),
		})
	end

	-- 4. Generate Shop Grid Items
	local itemButtons = {}

	-- Plot Expansion Button (At the top of the grid)
	local currentSize = plotState.plotSize or 32
	local nextTier = nil
	for _, tier in ipairs(PlotExpansionsConfig) do
		if tier.Size > currentSize then
			nextTier = tier
			break
		end
	end

	if nextTier then
		local canAfford = playerStats.Cash >= nextTier.Cost
		local levelMet = playerStats.Level >= nextTier.UnlockLevel
		local statusText = `(💲{nextTier.Cost})`
		local bgColor = Color3.new(0.8, 0.6, 0.1)

		if not levelMet then
			statusText = `(Unlocks Lvl {nextTier.UnlockLevel})`
			bgColor = Color3.new(0.4, 0.4, 0.4)
		elseif not canAfford then
			statusText = `(TOO EXPENSIVE)`
			bgColor = Color3.new(0.6, 0.2, 0.2)
		end

		itemButtons["PLOT_EXPANSION"] = e(SmallButton, {
			Size = UDim2.new(1, -8, 0, 60),
			BackgroundColor3 = bgColor,
			LayoutOrder = -1,
			[React.Event.Activated] = function()
				if canAfford and levelMet then
					Remotes.ExpandPlot:FireServer()
				end
			end,
		}, {
			e("UIStroke", { Thickness = 2, Color = Color3.new(1, 0.8, 0) }),
			e(SmallText, {
				Text = `⭐️ Expand Cafe to {nextTier.Size}x{nextTier.Size} ⭐️\n{statusText}`,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),
		})
	end

	-- Regular Catalog Items
	for _, config in ipairs(PlaceablesModule.Array) do
		local isLocked = playerStats.Level < config.UnlockLevel

		itemButtons[config.Id] = e(ItemButton, {
			config = config,
			isSelected = selectedItem == config.Id,
			isLocked = isLocked,
			mobile = mobile,
			[React.Event.Activated] = function()
				setSelectedItem(config.Id)
			end,
		})
	end

	-- Animation & Layout
	local show, setShow = useState(true)
	local pos, setPos = useSpring({ start = 0, target = 0, damper = 1, speed = 10 })

	useEffect(function()
		setPos({ target = show and 0 or 1, damper = 1, speed = 10 })
	end, { show })

	return e("Frame", {
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
	}, {
		-- The Left-Side Action Area (Close Button + Details Overlay)
		SidePanelContainer = e("Frame", {
			Position = UDim2.new(0, 0, 0.5, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			Active = true,
			Size = UDim2.new(0, 0, 1, 0),
			ZIndex = 4,
		}, {
			-- Main Close Button
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
				Padding = { All = UDim.new() },
			}, {
				e("UIStroke", { Thickness = 2 }),
				e("ImageLabel", {
					ZIndex = 1,
					Image = "rbxassetid://17368208554",
					ScaleType = Enum.ScaleType.Fit,
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
				}),
			}),

			-- The Master-Detail Overlay
			DetailsOverlay = detailsOverlay,
		}),

		-- Translucent Background
		Background = e("ImageLabel", {
			Image = "rbxassetid://103478691850846",
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(8, 8, 92, 92),
			AnchorPoint = Vector2.new(0, 0),
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
			ImageColor3 = Color3.new(0.6, 0.6, 0.6),
			ImageTransparency = 0.2,
			Visible = visible,
			ZIndex = 1,
		}),

		-- Main Shop Grid
		ShopContainer = e(VStack, {
			Size = UDim2.new(0, (mobile and 360 or 480), 1, 0),
			Position = UDim2.new(0.5, 0, 0, 0),
			AnchorPoint = Vector2.new(0.5, 0),
			Active = true,
			Padding = { All = UDim.new(0, 10) },
			Visible = visible,
			ZIndex = 2,
		}, {
			Header = e(SmallText, {
				Text = `Shop <font size="14" color="rgb(100,255,100)">[Cash: 💲{playerStats.Cash}]</font>`,
				RichText = true,
				Size = UDim2.new(1, 0, 0, 30),
				LayoutOrder = 1,
			}),
			ScrollingFrame = e("ScrollingFrame", {
				Size = UDim2.new(1, 0, 1, -40),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 1,
				ScrollBarThickness = 4,
				LayoutOrder = 2,
			}, {
				e(HStack, {
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.XY,
					Wraps = true,
					Spacing = UDim.new(0, 8),
					VerticalAlignment = Enum.VerticalAlignment.Top,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
				}, {
					Items = e(React.Fragment, nil, itemButtons),
				}),
			}),
		}),
	})
end

return ShopPanel
