-- Shared/ReactComponents/ShopPanel.luau
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
local WorkersConfig = require(ReplicatedStorage.Shared.Configs.WorkersConfig) -- NEW: Import Workers config

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local RedDot = require(script.Parent.RedDot).RedDot

local e = React.createElement
local useState = React.useState
local useRef = React.useRef
local useBinding = React.useBinding
local useEffect = React.useEffect
local useSpring = ReactFlow.useSpring
local useBreakpoint = require(script.Parent.Parent.Hooks.useBreakpoint)
local BuildersIcon = require(script.Parent.Parent.Utils.BuildersIcon)

local DOWN_ICON = BuildersIcon["chevron-large-down"]
local function Padding(props: {
	All: UDim,
})
	local All = props.All or UDim.new(0, 4)
	return e("UIPadding", {
		PaddingTop = All,
		PaddingBottom = All,
		PaddingLeft = All,
		PaddingRight = All,
	})
end

local playerId = Players.LocalPlayer and tostring(Players.LocalPlayer.UserId) or "MockUser"

local function ShopTabs(props: {
	mobile: boolean,
	setTab: (string) -> ()?,
	LayoutOrder: number?,
})
	return e(HStack, {
		Size = UDim2.new(0, 0, 0, 0),
		LayoutOrder = props.LayoutOrder,
		AutomaticSize = Enum.AutomaticSize.XY,
		VerticalFlex = "Fill",
		HorizontalFlex = "Fill",
		Spacing = UDim.new(0, props.mobile and 4 or 8),
	}, {
		e(SmallButton, {
			Text = "Item",
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = 1,
			[React.Event.Activated] = function()
				if props.setTab then
					props.setTab("item")
				end
			end,
		}),
		e(SmallButton, {
			Text = "Upgrade",
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = 2,
			[React.Event.Activated] = function()
				if props.setTab then
					props.setTab("upgrade")
				end
			end,
		}),
		e(SmallButton, {
			Text = "Expansion",
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = 3,
			[React.Event.Activated] = function()
				if props.setTab then
					props.setTab("expansion")
				end
			end,
		}),
		-- NEW: Staff Tab
		e(SmallButton, {
			Text = "Staff",
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = 4,
			[React.Event.Activated] = function()
				if props.setTab then
					props.setTab("staff")
				end
			end,
		}),
	})
end
local function ItemModelViewport(props: {
	config: Types.PlaceableConfig,
	mobile: boolean?,
	ImageTransparency: number?,
})
	local itemId = props.config.Id
	local currentCamera: Camera, setCurrentCamera = useState(nil)
	local modelClone, setModelClone = useState(nil)
	local viewportFrame: ViewportFrame, setViewportFrame = useState(nil)

	useEffect(function()
		if not (viewportFrame and props.config) then
			return
		end
		local prefab = ReplicatedStorage.Shared.Models:FindFirstChild(itemId)
		if not prefab then
			return
		end

		local clone = prefab:Clone()
		clone:PivotTo(CFrame.new(Vector3.zero))
		clone.Parent = viewportFrame
		setModelClone(clone)

		return function()
			clone:Destroy()
			setModelClone(nil)
		end
	end, { viewportFrame, props.config })

	useEffect(function()
		if not (viewportFrame and currentCamera and modelClone) then
			return
		end

		currentCamera:ZoomToExtents(modelClone:GetBoundingBox())
		viewportFrame.CurrentCamera = currentCamera
	end, { viewportFrame, currentCamera, modelClone })

	local onMount = React.useCallback(function(rbx)
		setViewportFrame(rbx)
	end, {})
	
	return e("ViewportFrame", {
		ZIndex = 1,
		CurrentCamera = currentCamera,
		Size = UDim2.new(1, 0, 1, 0),
		LightDirection = Vector3.new(0, -1, -1),
		BackgroundTransparency = 1,
		Active = false,
		ImageTransparency = props.ImageTransparency,
		ref = onMount,
	}, {
		Camera = e("Camera", {
			ref = setCurrentCamera,
			CFrame = CFrame.new(Vector3.new(20, 20, -20), Vector3.zero),
			FieldOfView = 45,
		}),
	})
end

local function ItemButton(
	props: {
		isSelected: boolean,
		isLocked: boolean,
		config: Types.PlaceableConfig,
		mobile: boolean,
		cleared: boolean,
		selectingCategory: React.ReactBinding<boolean>?,
		Visible: boolean?,
		-- [React.Event.Activated]: () -> (), -- cant type like this
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
		Image = "",
		Visible = props.Visible,
		Selectable = props.selectingCategory and props.selectingCategory:map(function(is)
			return not is
		end) or nil,
	}, {
		-- Locked Overlay Tint
		stroke = e("UIStroke", { Thickness = isSelected and 2 or 0 }),
		reddot = not props.cleared and e(RedDot, {
			Position = UDim2.new(1, -8, 0, 8),
			SizeNum = 48,
		}),
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
			ImageTransparency = isLocked and 0.5 or 0,
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

local function CategoryRow(props: {
	mobile: boolean,
	setCategory: (category: string?) -> (),
	onSelecting: (selecting: boolean) -> (),
	Visible: boolean?,
	LayoutOrder: number?,
})
	local selectedCategory, setSelectedCategory = useState(nil)
	local categories = PlaceablesModule.Categories
	local selecting, setSelecting = useState(false)

	useEffect(function()
		if props.setCategory then
			props.setCategory(selectedCategory)
		end
	end, { selectedCategory })
	
	useEffect(function()
		if props.onSelecting then
			props.onSelecting(selecting)
		end
	end, { selecting, props.onSelecting })

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
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.new(1, 0, 0, props.mobile and 40 or 60),
		AutomaticSize = Enum.AutomaticSize.None,
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		Visible = props.Visible,
		ZIndex = 20,
	}, {
		e(Padding),
		DropdownButton = e(SmallButton, {
			Size = UDim2.new(1, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.None,
			Text = `Category: {selectedCategory == nil and "All" or selectedCategory} {DOWN_ICON}`,
			RichText = true,
			[React.Event.Activated] = function()
				setSelecting(function(prev)
					return not prev
				end)
			end,
			TextXAlignment = "Left",
		}, {}),
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

	local playerStats, setPlayerStats = useState(nil)
	local playerInventory, setPlayerInventory = useState(nil)
	local plotState, setPlotState = useState(nil)
	local playerWorkers, setPlayerWorkers = useState(nil) -- NEW

	local xs, sm, md, lg, xl = useBreakpoint()
	local mobile = xs or sm or md
	local category, setCategory = useState(nil)

	-- 1. Sync with UIState for panel visibility
	useEffect(function()
		local function selectPanel(state)
			return state.panel
		end
		local unsub = UIState:subscribe(selectPanel, function(panel)
			setVisible(panel == "shop")
			if panel ~= "shop" then
				setSelectedItem(nil)
			end
		end)
		setVisible(selectPanel(UIState:getState()) == "shop")
		return unsub
	end, {})

	-- 2. Native Sync with GlobalState
	useEffect(function()
		local function selectStats(state)
			return state.Stats and state.Stats[playerId] or nil
		end
		local function selectInv(state)
			return state.Inventory and state.Inventory[playerId] or nil
		end
		local function selectPlot(state)
			return state.Plot and state.Plot[playerId] or nil
		end
		local function selectWorkers(state)
			return state.Workers and state.Workers[playerId] or {}
		end

		local unsubStats = GlobalState:subscribe(selectStats, setPlayerStats)
		local unsubInv = GlobalState:subscribe(selectInv, setPlayerInventory)
		local unsubPlot = GlobalState:subscribe(selectPlot, setPlotState)
		local unsubWorkers = GlobalState:subscribe(selectWorkers, setPlayerWorkers)

		setPlayerStats(selectStats(GlobalState:getState()))
		setPlayerInventory(selectInv(GlobalState:getState()))
		setPlotState(selectPlot(GlobalState:getState()))
		setPlayerWorkers(selectWorkers(GlobalState:getState()))

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

	local tab, setTab = useState("item")
	local selectingCategory, setSelectingCategory = useBinding(nil)
	local show, setShow = useState(true)
	local pos, setPos = useSpring({ start = 0, target = 0, damper = 1, speed = 10 })

	local selectedConfig = selectedItem and PlaceablesModule.GetConfig(selectedItem)
	local detailsOverlay = nil
	
	useEffect(function()
		setPos({ target = show and 0 or 1, damper = 1, speed = 10 })
	end, { show })
	
	local allCleared = true
	local itemButtons = {}

	for _, config in ipairs(PlaceablesModule.Array) do
		allCleared = allCleared and not unackedUnlocks[config.Id]
	end
	
	useEffect(function()
		UIState.setPanelCleared("shop", allCleared)
	end, { allCleared })
	
	if not (playerStats and playerInventory and plotState) then
		return nil
	end

	-- Master-Detail Overlay for Standard Items
	if selectedConfig then
		local totalOwned = getTotalOwned(selectedConfig.Id)
		local isMaxed = selectedConfig.MaxAllowed ~= math.huge and totalOwned >= selectedConfig.MaxAllowed
		local canAfford = playerStats.Cash >= selectedConfig.Price
		local isLocked = playerStats.Level < selectedConfig.UnlockLevel

		local btnText = `Buy ( ${selectedConfig.Price})`
		local btnColor = Color3.new(0.2, 0.7, 0.2)
		local canBuy = true
		local btnTextSize = mobile and 14 or 20
		
		if isLocked then
			btnText = `Unlock at Lvl {selectedConfig.UnlockLevel}`
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
			Position = UDim2.new(0, 0, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			Size = UDim2.new(0, mobile and 240 or 400, 0, 0),
			BackgroundColor3 = Color3.new(0.1, 0.1, 0.1),
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 0.6,
			VerticalFlex = Enum.UIFlexAlignment.None,
			Padding = { All = UDim.new(0, 10) },
			Spacing = UDim.new(0, 8),
			ZIndex = 5,
		}, {
			e("UICorner", { CornerRadius = UDim.new(0, 8) }),
			Header = e(SmallText, {
				Text = `<font size="20"><b>{selectedConfig.DisplayName}</b></font>\n<font color="rgb(180,180,180)">{selectedConfig.Category}</font>`,
				RichText = true,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				AutomaticSize = Enum.AutomaticSize.XY,
			}),
			image = e("Frame", {
				BackgroundTransparency = 0.2,
				BackgroundColor3 = Color3.new(1, 1, 1),
				Size = UDim2.new(1, 0, 0, mobile and 100 or 200),
			}, {
				itemmodelviewport = e(ItemModelViewport, { config = selectedConfig }),
			}),
			Stats = e(SmallText, {
				Text = `<b>Price:</b> ${selectedConfig.Price}\n<b>Unlock Level:</b> {selectedConfig.UnlockLevel}\n<b>Owned:</b> {totalOwned} / {selectedConfig.MaxAllowed == math.huge and "∞" or selectedConfig.MaxAllowed}`,
				RichText = true,
				TextWrapped = false,
				Size = UDim2.new(1, 0, 0, 0),
				BackgroundColor3 = Color3.new(0.3, 0.3, 0.3),
				AutomaticSize = Enum.AutomaticSize.XY,
				LayoutOrder = 3,
			}, {
				padding = e(Padding),
			}),
			e(HStack, {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				LayoutOrder = 4,
				HorizontalFlex = "Fill",
				Spacing = UDim.new(0, 8),
			}, {
				BuyButton = e(SmallButton, {
					Size = UDim2.new(1, 0, 0, mobile and 40 or 60),
					AutomaticSize = Enum.AutomaticSize.None,
					BackgroundColor3 = btnColor,
					LayoutOrder = 4,
					[React.Event.Activated] = function()
						if canBuy then
							Remotes.BuyItem:FireServer({ itemId = selectedConfig.Id, amount = 1 })
						end
					end,
				}, {
					e("UIStroke", { Thickness = 2 }),
					e(SmallText, {
						Text = btnText,
						Size = UDim2.new(1, 0, 1, 0),
						AutomaticSize = Enum.AutomaticSize.None,
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Center,
						TextYAlignment = Enum.TextYAlignment.Center,
						TextSize = btnTextSize,
					}),
				}),
				CloseButton = e(SmallButton, {
					Size = UDim2.new(1, 0, 0, mobile and 40 or 60),
					AutomaticSize = Enum.AutomaticSize.None,
					BackgroundColor3 = Color3.new(0.8, 0.2, 0.2),
					BackgroundTransparency = 0.5,
					LayoutOrder = 5,
					[React.Event.Activated] = function()
						setSelectedItem(nil)
					end,
				}, {
					e(Padding),
					e("ImageLabel", {
						Image = "rbxassetid://17368177673",
						Size = UDim2.new(1, 0, 1, 0),
						SizeConstraint = Enum.SizeConstraint.RelativeYY,
						BackgroundTransparency = 1,
						Position = UDim2.new(0.5, 0, 0.5, 0),
						AnchorPoint = Vector2.new(0.5, 0.5),
					}),
				}),
			}),
		})
	end

	-- Plot Expansion Button
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
		local statusText = `(${nextTier.Cost})`
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
			Visible = tab == "expansion",
		}, {
			e("UIStroke", { Thickness = 2, Color = Color3.new(1, 0.8, 0) }),
			e(SmallText, {
				Text = `⭐️ Expand Cafe to {nextTier.Size}x{nextTier.Size} ⭐️\n{statusText}`,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),
		})
	end
	
	-- NEW: Hire Worker Button logic
	local workerCount = playerWorkers and #playerWorkers or 0
	local nextWorkerTier = WorkersConfig[workerCount + 1]

	if tab == "staff" then
		if nextWorkerTier then
			local canAfford = playerStats.Cash >= nextWorkerTier.Cost
			local levelMet = playerStats.Level >= nextWorkerTier.UnlockLevel
			local statusText = `(💲{nextWorkerTier.Cost})`
			local bgColor = Color3.new(0.2, 0.5, 0.8)

			if not levelMet then
				statusText = `(Unlocks Lvl {nextWorkerTier.UnlockLevel})`
				bgColor = Color3.new(0.4, 0.4, 0.4)
			elseif not canAfford then
				statusText = `(TOO EXPENSIVE)`
				bgColor = Color3.new(0.6, 0.2, 0.2)
			end

			itemButtons["HIRE_WORKER"] = e(SmallButton, {
				Size = UDim2.new(1, -8, 0, 80),
				BackgroundColor3 = bgColor,
				LayoutOrder = -1,
				[React.Event.Activated] = function()
					if canAfford and levelMet then
						Remotes.HireWorker:FireServer()
					end
				end,
				Visible = tab == "staff",
			}, {
				e("UIStroke", { Thickness = 2, Color = Color3.new(0.5, 0.8, 1) }),
				e(SmallText, {
					Text = `👨‍🍳 Hire {nextWorkerTier.Title} 👨‍🍳\n{statusText}\n<font size="12">Current Staff: {workerCount}</font>`,
					RichText = true,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
				}),
			})
		else
			itemButtons["MAX_WORKERS"] = e(SmallButton, {
				Size = UDim2.new(1, -8, 0, 80),
				BackgroundColor3 = Color3.new(0.4, 0.4, 0.4),
				LayoutOrder = -1,
				Visible = tab == "staff",
			}, {
				e("UIStroke", { Thickness = 2, Color = Color3.new(0.8, 0.8, 0.8) }),
				e(SmallText, {
					Text = `👨‍🍳 Maximum Staff Reached! 👨‍🍳\n<font size="12">Current Staff: {workerCount}</font>`,
					RichText = true,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
				}),
			})
		end
	end

	-- Regular Catalog Items
	for _, config in ipairs(PlaceablesModule.Array) do
		local isLocked = playerStats.Level < config.UnlockLevel
		
		itemButtons[config.Id] = e(ItemButton, {
			config = config,
			Visible = tab == "item" and ((category == nil) or (category == config.Category)) or false,
			isSelected = selectedItem == config.Id,
			isLocked = isLocked,
			mobile = mobile,
			cleared = not unackedUnlocks[config.Id],
			[React.Event.Activated] = function()
				setSelectedItem(config.Id)
				if unackedUnlocks[config.Id] then
					setUnackedUnlocks(function(prevMap)
						local nextMap = table.clone(prevMap)
						nextMap[config.Id] = nil
						return nextMap
					end)
				end
			end,
			selectingCategory = selectingCategory,
		})
	end

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
		SidePanelContainer = e("Frame", {
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
			DetailsOverlay = detailsOverlay,
		}),

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
				Text = `Shop `,
				RichText = true,
				AutomaticSize = Enum.AutomaticSize.XY,
				LayoutOrder = 1,
			}, {
				padding = e(Padding),
			}),
			Tabs = e(ShopTabs, {
				mobile = mobile,
				LayoutOrder = 2,
				setTab = setTab,
			}),
			Categories = e(CategoryRow, {
				mobile = mobile,
				Visible = tab == "item",
				setCategory = setCategory,
				onSelecting = setSelectingCategory,
				LayoutOrder = 3,
			}),
			ScrollingFrame = e("ScrollingFrame", {
				Size = UDim2.new(1, 0, 1, 0),
				Selectable = false,
				AutomaticCanvasSize = Enum.AutomaticSize.XY,
				CanvasSize = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 1,
				ScrollBarThickness = 4,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				LayoutOrder = 4,
			}, {
				e(Padding),
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