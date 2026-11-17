-- Shared/ReactComponents/ShopPanel.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Reflex = require(ReplicatedStorage.Packages.Reflex)

local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local Panel = require(Primitives.Panel)
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local Padding = require(Primitives.Padding)

local ShopTabs = require(script.ShopTabs)
local ShopTabConfig = require(script.ShopTabConfig)
local ItemTab = require(script.ItemTab)
local UpgradeTab = require(script.UpgradeTab)
local StaffTab = require(script.StaffTab)
local PremiumTab = require(script.PremiumTab)
local DetailsOverlay = require(script.DetailsOverlay)

local e = React.createElement
local useState = React.useState
local useRef = React.useRef
local useBinding = React.useBinding
local useEffect = React.useEffect
local useBreakpoint = require(script.Parent.Parent.Hooks.useBreakpoint)
local BuildersIcon = require(script.Parent.Parent.Utils.BuildersIcon)
local useInputDevice = require(ReplicatedStorage.Shared.Hooks.useInputDevice)

local DOWN_ICON = BuildersIcon["chevron-large-down"]

local playerId = Players.LocalPlayer and tostring(Players.LocalPlayer.UserId) or "MockUser"

local function CategoryRow(props: {
	mobile: boolean,
	tab: string,
	categories: { string },
	setCategory: (string?) -> (),
	onSelecting: ((boolean) -> ())?,
	Visible: boolean?,
	LayoutOrder: number?,
})
	local selectedCategory, setSelectedCategory = useState(nil)
	local selecting, setSelecting = useState(false)

	useEffect(function()
		setSelectedCategory(nil)
		setSelecting(false)
		if props.setCategory then
			props.setCategory(nil)
		end
	end, { props.tab })

	useEffect(function()
		if props.setCategory then
			props.setCategory(selectedCategory)
		end
	end, { selectedCategory })

	useEffect(function()
		if props.onSelecting then
			props.onSelecting(selecting)
		end
	end, { selecting })

	local children = {}
	for _, category in ipairs(props.categories or {}) do
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
	children.All = e(SmallButton, {
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
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.new(1, 0, 0, props.mobile and 40 or 60),
		AutomaticSize = Enum.AutomaticSize.None,
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		Visible = props.Visible,
		ZIndex = 20,
	}, {

		DropdownButton = e(SmallButton, {
			Size = UDim2.new(1, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.None,
			RichText = true,
			[React.Event.Activated] = function()
				setSelecting(function(prev)
					return not prev
				end)
			end,
			Image = "rbxassetid://76169596898587",
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(8, 8, 92, 92),
			TextXAlignment = "Left",
			Padding = { All = UDim.new(0, 0) },
			Rounded = false,
		}, {
			e("ImageLabel", {
				ZIndex = 1,
				ScaleType = Enum.ScaleType.Stretch,
				-- Image = "rbxassetid://124700292719297",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
			}, {

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

local function ShopPanel()
	local visible, setVisible = useState(false)
	local selectedItem, setSelectedItem = useState(nil)
	local currentInput = useInputDevice()

	local playerStats, setPlayerStats = useState(nil)
	local playerInventory, setPlayerInventory = useState(nil)
	local plotState, setPlotState = useState(nil)
	local playerWorkers, setPlayerWorkers = useState(nil)
	local amount, setAmount = useState(nil)

	local xs, sm, md = useBreakpoint()
	local mobile = xs or sm or md
	local category, setCategory = useState(nil)
	local tab, setTab = useState("item")
	local itemSubTab, setItemSubTab = useState(ShopTabConfig.getDefaultItemSubTab())
	local selectingCategory, setSelectingCategory = useBinding(nil)

	useEffect(function()
		local unsub = UIState:subscribe(function(state)
			return state.panel
		end, function(panel)
			setVisible(panel == "shop")
			if panel ~= "shop" then
				setSelectedItem(nil)
			end
		end)
		setVisible(UIState:getState().panel == "shop")
		return unsub
	end, {})

	useEffect(function()
		local unsubStats = GlobalState:subscribe(function(s)
			return s.Stats and s.Stats[playerId] or nil
		end, setPlayerStats)
		local unsubInv = GlobalState:subscribe(function(s)
			return s.Inventory and s.Inventory[playerId] or nil
		end, setPlayerInventory)
		local unsubPlot = GlobalState:subscribe(function(s)
			return s.Plot and s.Plot[playerId] or nil
		end, setPlotState)
		local unsubWorkers = GlobalState:subscribe(function(s)
			return s.Workers and s.Workers[playerId] or {}
		end, setPlayerWorkers)

		setPlayerStats(GlobalState:getState().Stats and GlobalState:getState().Stats[playerId] or nil)
		setPlayerInventory(GlobalState:getState().Inventory and GlobalState:getState().Inventory[playerId] or nil)
		setPlotState(GlobalState:getState().Plot and GlobalState:getState().Plot[playerId] or nil)
		setPlayerWorkers(GlobalState:getState().Workers and GlobalState:getState().Workers[playerId] or {})

		return function()
			unsubStats()
			unsubInv()
			unsubPlot()
			unsubWorkers()
		end
	end, {})

	local unackedUnlocks, setUnackedUnlocks = useState({})
	local prevLevelRef = useRef(nil)

	useEffect(function()
		if not playerStats or not playerStats.Level then
			return
		end
		local currentLevel = playerStats.Level
		local prevLevel = prevLevelRef.current

		if prevLevel ~= nil and currentLevel > prevLevel then
			local newUnlocks = table.clone(unackedUnlocks)
			local hasChanges = false
			for _, config in ipairs(PlaceablesModule.Array) do
				if prevLevel < config.UnlockLevel and currentLevel >= config.UnlockLevel then
					newUnlocks[config.Id] = true
					hasChanges = true
				end
			end
			if hasChanges then
				setUnackedUnlocks(newUnlocks)
			end
		end
		prevLevelRef.current = currentLevel
	end, { playerStats and playerStats.Level })

	useEffect(function()
		local unsub = GlobalState:subscribe(
			Reflex.createSelector({
				function(state: GlobalState.GlobalState)
					return state.Plot[playerId] and state.Plot[playerId].placedItems or nil
				end,
				function(state: GlobalState.GlobalState)
					return state.Plot[playerId] and state.Plot[playerId].spatialItems or nil
				end,
				function(state: GlobalState.GlobalState)
					return state.Inventory[playerId] and state.Inventory[playerId] or nil
				end,
			}, function(placedItems, spatialItems, inventory)
				local totalOwned = {}
				for _, item in placedItems or {} do
					totalOwned[item.id] = (totalOwned[item.id] or 0) + 1
				end
				for _, item in spatialItems or {} do
					totalOwned[item.id] = (totalOwned[item.id] or 0) + 1
				end
				for id, itemAmount in inventory or {} do
					totalOwned[id] = (totalOwned[id] or 0) + itemAmount
				end
				return totalOwned
			end),
			setAmount
		)

		local totalOwned = {}
		local state = GlobalState:getState()
		local placedItems = state.Plot[playerId] and state.Plot[playerId].placedItems or nil
		local spatialItems = state.Plot[playerId] and state.Plot[playerId].spatialItems or nil
		local inventory = state.Inventory[playerId] and state.Inventory[playerId] or nil

		for _, item in placedItems or {} do
			totalOwned[item.id] = (totalOwned[item.id] or 0) + 1
		end
		for _, item in spatialItems or {} do
			totalOwned[item.id] = (totalOwned[item.id] or 0) + 1
		end
		for id, itemAmount in inventory or {} do
			totalOwned[id] = (totalOwned[id] or 0) + itemAmount
		end
		setAmount(totalOwned)
		return unsub
	end, {})

	useEffect(function()
		setCategory(nil)
		setSelectedItem(nil)
		setItemSubTab(ShopTabConfig.getDefaultItemSubTab())
	end, { tab })

	useEffect(function()
		UIState.selectShopItem(selectedItem)
	end, { selectedItem })

	local allCleared = true
	for _, config in ipairs(PlaceablesModule.Array) do
		allCleared = allCleared and not unackedUnlocks[config.Id]
	end

	useEffect(function()
		UIState.setPanelCleared("shop", allCleared)
	end, { allCleared })

	if not (playerStats and playerInventory and plotState) then
		return nil
	end

	local isItemTab = ShopTabConfig.isItemTab(tab)
	local selectedConfig = selectedItem and PlaceablesModule.GetConfig(selectedItem)
	local isLocked = selectedConfig and playerStats.Level < selectedConfig.UnlockLevel

	local detailsOverlay = (selectedConfig and isItemTab)
			and e(DetailsOverlay, {
				config = selectedConfig,
				amount = amount,
				playerCash = playerStats.Cash,
				locked = isLocked,
				currentInput = currentInput,
				mobile = mobile,
				onClose = function()
					setSelectedItem(nil)
				end,
			})
		or nil

	local content
	if tab == "premium" then
		content = e(VStack, {
			Size = UDim2.new(1, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.None,
			LayoutOrder = 4,
			HorizontalFlex = Enum.UIFlexAlignment.Fill,
			VerticalFlex = Enum.UIFlexAlignment.Fill,
			BackgroundImage = "rbxassetid://99700456312840",
			SliceCenter = Rect.new(8, 8, 92, 92),
			ScaleType = Enum.ScaleType.Slice,
			Padding = { All = UDim.new(0, 12) },
		}, {
			Premium = e(PremiumTab),
		})
	elseif tab == "upgrade" then
		content = e(VStack, {
			Size = UDim2.new(1, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.None,
			LayoutOrder = 4,
			HorizontalFlex = Enum.UIFlexAlignment.Fill,
			VerticalFlex = Enum.UIFlexAlignment.Fill,
			BackgroundImage = "rbxassetid://99700456312840",
			SliceCenter = Rect.new(8, 8, 92, 92),
			ScaleType = Enum.ScaleType.Slice,
		}, {
			e("ScrollingFrame", {
				Size = UDim2.fromScale(1, 1),
				Selectable = false,
				AutomaticCanvasSize = Enum.AutomaticSize.XY,
				CanvasSize = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 1,
				-- BackgroundColor3 = Color3.new(1, 0, 1),
				ScrollBarThickness = 4,
				ScrollingDirection = Enum.ScrollingDirection.Y,
			}, {

				e(UpgradeTab, { plotState = plotState, playerStats = playerStats }),
			}),
		})
	elseif tab == "staff" then
		content = e(VStack, {
			Size = UDim2.new(1, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.None,
			LayoutOrder = 4,
			HorizontalFlex = Enum.UIFlexAlignment.Fill,
			VerticalFlex = Enum.UIFlexAlignment.Fill,
			BackgroundImage = "rbxassetid://99700456312840",
			SliceCenter = Rect.new(8, 8, 92, 92),
			ScaleType = Enum.ScaleType.Slice,
			Padding = { All = UDim.new(0, 8) },
		}, {
			Scroll = e("ScrollingFrame", {
				Size = UDim2.fromScale(1, 1),
				Selectable = false,
				AutomaticCanvasSize = Enum.AutomaticSize.XY,
				CanvasSize = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 1,
				ScrollBarThickness = 4,
				ScrollingDirection = Enum.ScrollingDirection.Y,
			}, {
				e(StaffTab, { playerWorkers = playerWorkers, playerStats = playerStats }),
			}),
		})
	else
		content = e(VStack, {
			Size = UDim2.new(1, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.None,
			LayoutOrder = 4,
			HorizontalFlex = Enum.UIFlexAlignment.Fill,
			VerticalFlex = Enum.UIFlexAlignment.Fill,
		}, {
			e("ScrollingFrame", {
				Size = UDim2.fromScale(1, 1),
				Selectable = false,
				AutomaticCanvasSize = Enum.AutomaticSize.XY,
				CanvasSize = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 1,
				-- BackgroundColor3 = Color3.new(1, 0, 1),
				ScrollBarThickness = 4,
				ScrollingDirection = Enum.ScrollingDirection.Y,
			}, {
				e(ItemTab, {
					tab = tab,
					mobile = mobile,
					playerStats = playerStats,
					amount = amount,
					selectedItem = selectedItem,
					subTab = itemSubTab,
					unackedUnlocks = unackedUnlocks,
					selectingCategory = selectingCategory,
					onSelectSubTab = setItemSubTab,
					onSelectItem = setSelectedItem,
					onClearUnlock = function(itemId)
						if unackedUnlocks[itemId] then
							setUnackedUnlocks(function(prevMap)
								local nextMap = table.clone(prevMap)
								nextMap[itemId] = nil
								return nextMap
							end)
						end
					end,
				}),
			}),
		})
	end

	return e(React.Fragment, {}, {
		Shop = e(Panel, {
			Title = "Shop",
			Open = visible,
			Size = mobile and UDim2.fromScale(0.96, 0.92) or UDim2.fromScale(0.9, 0.88),
			Spacing = UDim.new(0, 8),
			Padding = { All = UDim.new(0, 12) },
			BackgroundImage = "rbxassetid://120520009441669",
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(8, 8, 92, 92),
			BackgroundImageColor3 = Color3.fromRGB(180, 170, 160),
			OpenPosition = UDim2.fromScale(0.5, 0.5),
			HiddenPosition = UDim2.fromScale(0.5, 1.5),
			BackgroundImageTransparency = 0.15,
			OnClose = function()
				UIState.toggle("none")
			end,
			MaxSize = Vector2.new(mobile and 720 or 920, 2000),
		}, {
			ContentRoot = e(VStack, {
				Size = UDim2.fromScale(1, 1),
				AutomaticSize = Enum.AutomaticSize.None,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				HorizontalFlex = "Fill",
				VerticalFlex = "Fill",

				Spacing = UDim.new(0, 8),
				LayoutOrder = 1,
			}, {
				Tabs = e(ShopTabs, {
					mobile = mobile,
					LayoutOrder = 2,
					setTab = setTab,
					tab = tab,
					level = playerStats.Level,
				}),
				Content = content,
			}),
		}),
		Details = detailsOverlay,
	})
end

return ShopPanel
