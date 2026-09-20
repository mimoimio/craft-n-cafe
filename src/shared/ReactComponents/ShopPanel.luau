-- Shared/ReactComponents/ShopPanel.luau
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

-- FIX: Define fallback tables as constants so Reflex doesn't see new memory addresses on every check!
local DEFAULT_STATS = { Level = 1, Cash = 0 }
local DEFAULT_PLOT = { placedItems = {}, spatialItems = {} }
local function ItemButton(props: {
	isSelected: boolean,
	config: Types.PlaceableConfig,
	count: number,
	mobile: boolean,
	BackgroundColor3: Color3,
})
	local itemId = props.config.Id
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
		[React.Event.Activated] = props[React.Event.Activated],
		BackgroundColor3 = props.BackgroundColor3,
		Padding = { All = UDim.new() },
	}, {
		e(SmallText, {
			TextSize = 10,
			Text = `{props.config.DisplayName} (x{count})`,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			TextWrapped = true,
			ZIndex = 2,
			Size = UDim2.new(1, 0, 1, 0),
		}),
		e("ViewportFrame", {
			ZIndex = 1,
			CurrentCamera = currentCamera,
			Size = UDim2.new(1, 0, 1, 0),
			LightDirection = Vector3.new(0, -1, -1),
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
	})
end

local function ShopPanel()
	local visible, setVisible = useState(false)
	local playerStats, setPlayerStats = useState(DEFAULT_STATS)
	local playerInventory, setPlayerInventory = useState(nil)
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
		end)
		setVisible(selectPanel(UIState:getState()) == "shop")
		return unsub
	end, {})

	-- 2. Sync with GlobalState (Stats, Inventory, Plot) natively
	useEffect(function()
		local function selectStats(state)
			return state.Stats and state.Stats[playerId] or DEFAULT_STATS
		end
		local function selectInv(state)
			return state.Inventory and state.Inventory[playerId] or nil
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

	-- Helper to count how many the player owns (Inventory + Placed)
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

	-- 3. Generate Shop Buttons
	local itemButtons = {}
	local unlockedItems = PlaceablesModule.GetUnlockedItems(playerStats.Level)
	local PlotExpansionsConfig = require(ReplicatedStorage.Shared.Configs.PlotExpansionsConfig)

	-- 1. Plot Expansion Button
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

		local statusText = `(Cash: {nextTier.Cost})`
		local bgColor = Color3.new(0.8, 0.6, 0.1) -- Gold for upgrades!

		if not levelMet then
			statusText = `(Unlocks at Lvl {nextTier.UnlockLevel})`
			bgColor = Color3.new(0.4, 0.4, 0.4)
		elseif not canAfford then
			statusText = `(TOO EXPENSIVE)`
			bgColor = Color3.new(0.6, 0.2, 0.2)
		end

		itemButtons["PLOT_EXPANSION"] = e(SmallButton, {
			Size = UDim2.new(0, 60, 0, 60),
			BackgroundColor3 = bgColor,
			LayoutOrder = -1, -- Force it to the top of the shop
			[React.Event.Activated] = function()
				if canAfford and levelMet then
					Remotes.ExpandPlot:FireServer()
				end
			end,
		}, {
			e("UIStroke", { Thickness = 2, Color = Color3.new(1, 0.8, 0) }), -- Fancy gold outline
			e(SmallText, {
				Text = `⭐️ Expand Cafe to {nextTier.Size}x{nextTier.Size} ⭐️\n{statusText}`,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),
		})
	end
	local show, setShow = useState(true)
	local pos, setPos = useSpring({ start = 0, target = 0, damper = 1, speed = 10 })

	useEffect(function()
		setPos({ target = show and 0 or 1, damper = 1, speed = 10 })
	end, { show })

	if not playerInventory then
		return
	end

	for _, config in ipairs(unlockedItems) do
		local totalOwned = getTotalOwned(config.Id)
		local isMaxed = config.MaxAllowed ~= math.huge and totalOwned >= config.MaxAllowed
		local canAfford = playerStats.Cash >= config.Price

		local statusText = `(${config.Price} Cash)`
		local bgColor = Color3.new(0.2, 0.6, 0.2) -- Green (Buyable)

		if isMaxed then
			statusText = "(MAX REACHED)"
			bgColor = Color3.new(0.4, 0.4, 0.4) -- Gray (Disabled)
		elseif not canAfford then
			statusText = "(TOO EXPENSIVE)"
			bgColor = Color3.new(0.6, 0.2, 0.2) -- Red (Disabled)
		end

		local count = playerInventory[config.Id] or 0

		itemButtons[config.Id] = e(ItemButton, {
			config = config,
			count = count,
			mobile = mobile,
			BackgroundColor3 = bgColor,
			[React.Event.Activated] = function()
				if isMaxed or not canAfford then
					return
				end

				Remotes.BuyItem:FireServer({ itemId = config.Id, amount = 1 })
			end,
			Text = `{config.DisplayName}\n{statusText}`,
		})
	end

	return e("Frame", {
		Size = UDim2.new(0, mobile and 260 or 600, 1, 0),
		Position = pos:map(function(n)
			return UDim2.new(1, n * (mobile and 260 or 600), 0, 0)
		end),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Active = true,
		Visible = visible,
	}, {
		-- e(VStack, {
		-- 	Position = UDim2.new(0, 0, 0.5, 0),
		-- 	AutomaticSize = Enum.AutomaticSize.XY,
		-- 	AnchorPoint = Vector2.new(1, 0.5),
		-- 	BackgroundTransparency = 1,
		-- 	BackgroundColor3 = Color3.new(0.1, 0.1, 0.1),
		-- 	Active = true,
		-- 	Visible = visible,
		-- 	Spacing = UDim.new(0, 8),
		-- }, {
		-- 	HideButton = e(SmallButton, {
		-- 		Image = "",
		-- 		[React.Event.Activated] = function()
		-- 			setShow(function(prev)
		-- 				return not prev
		-- 			end)
		-- 		end,
		-- 		Position = UDim2.new(0, 0, 0.5, 0),
		-- 		AnchorPoint = Vector2.new(1, 0.5),
		-- 		AutomaticSize = Enum.AutomaticSize.XY,
		-- 	}, {
		-- 		e("UIStroke", { Thickness = 2 }),
		-- 		e(SmallText, {
		-- 			TextSize = 48,
		-- 			Text = show and ">>" or "<<",
		-- 			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		-- 		}),
		-- 	}),
		-- }),
		e(VStack, {
			Size = UDim2.new(0, mobile and 260 or 600, 1, 0),
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
				Text = `Shop (Cash: ${playerStats.Cash})`,
				Size = UDim2.new(1, 0, 0, 30),
				LayoutOrder = 1,
			}),
			ScrollingFrame = e("ScrollingFrame", {
				Size = UDim2.new(1, 0, 1, -40),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 1,
				ScrollBarThickness = 4,
				ScrollingDirection = Enum.ScrollingDirection.Y,
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

return ShopPanel
