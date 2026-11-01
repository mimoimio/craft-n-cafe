-- Shared/ReactComponents/StorePanel.luau
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local MonetizationConfig = require(ReplicatedStorage.Shared.Configs.MonetizationConfig)
local PaintConfig = require(ReplicatedStorage.Shared.Configs.PaintConfig)
local useBreakpoint = require(ReplicatedStorage.Shared.Hooks.useBreakpoint)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local Grid = require(Primitives.Grid)
local HStack = require(Primitives.HStack)
local Panel = require(Primitives.Panel)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local VStack = require(Primitives.VStack)

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState

local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or "MockUser"

local function formatPrice(price: number?): string
	if type(price) ~= "number" then
		return "Buy"
	end
	return `R$ {price}`
end

local function getProductPrice(productId: number, infoType, fallback: number): string
	if not MonetizationConfig.IsConfigured(productId) then
		return "Setup required"
	end

	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(productId, infoType)
	end)

	if ok and info and info.PriceInRobux then
		return formatPrice(info.PriceInRobux)
	end

	return formatPrice(fallback)
end

local function StoreCard(props: {
	Title: string,
	Description: string,
	PriceText: string,
	ActionText: string,
	ActionDisabled: boolean?,
	AccentColor: Color3?,
	LayoutOrder: number,
	OnAction: (() -> ())?,
	children: { [string]: any }?,
})
	local cardChildren = {
		UICorner = e("UICorner", { CornerRadius = UDim.new(0, 10) }),
		Title = e(SmallText, {
			Text = props.Title,
			TextSize = 20,
			TextColor3 = props.AccentColor or Color3.fromRGB(255, 222, 150),
			LayoutOrder = 1,
		}),
		Description = e(SmallText, {
			Text = props.Description,
			TextSize = 14,
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			TextColor3 = Color3.fromRGB(200, 200, 210),
			LayoutOrder = 2,
		}),
		Action = e(HStack, {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			HorizontalFlex = "SpaceBetween",
			VerticalFlex = "None",
			Spacing = UDim.new(0, 8),
			LayoutOrder = 10,
		}, {
			Price = e(SmallText, {
				Text = props.PriceText,
				TextSize = 16,
				TextColor3 = Color3.fromRGB(255, 222, 150),
				LayoutOrder = 1,
			}),
			Action = e(SmallButton, {
				Text = props.ActionText,
				Size = UDim2.fromOffset(150, 40),
				AutomaticSize = Enum.AutomaticSize.None,
				BackgroundColor3 = props.ActionDisabled and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(40, 150, 90),
				LayoutOrder = 2,
				[React.Event.Activated] = if props.ActionDisabled then nil else props.OnAction,
			}),
		}),
	}

	if props.children then
		for key, value in pairs(props.children) do
			cardChildren[key] = value
		end
	end

	return e(VStack, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		HorizontalFlex = "None",
		VerticalFlex = "None",
		Spacing = UDim.new(0, 6),
		Padding = { All = UDim.new(0, 12) },
		BackgroundColor3 = Color3.fromRGB(30, 28, 34),
		BackgroundTransparency = 0.15,
		LayoutOrder = props.LayoutOrder,
	}, cardChildren)
end

local function StorePanel()
	local xs, sm, md = useBreakpoint()
	local mobile = xs or sm or md
	local isOpen, setIsOpen = useState(false)
	local tab, setTab = useState("cash")
	local stats, setStats = useState(nil)
	local prices, setPrices = useState({})

	useEffect(function()
		local unsub = UIState:subscribe(function(state)
			return state.panel == "store"
		end, setIsOpen)

		setIsOpen(UIState:getState().panel == "store")
		return unsub
	end, {})

	useEffect(function()
		if isOpen then
			UIState.setPanelCleared("store", true)
		end
	end, { isOpen })

	useEffect(function()
		local unsub = GlobalState:subscribe(function(state)
			return state.Stats[playerId]
		end, setStats)

		setStats(GlobalState:getState().Stats[playerId])
		return unsub
	end, {})

	useEffect(function()
		local running = true

		task.spawn(function()
			local fetched = {}
			local infoTypeProduct = Enum.InfoType.Product
			local infoTypeGamePass = Enum.InfoType.GamePass

			for _, product in ipairs(MonetizationConfig.CashProducts) do
				if running then
					fetched[product.Key] = getProductPrice(product.ProductId, infoTypeProduct, product.PriceHint)
				end
			end

			local starter = MonetizationConfig.StarterProduct
			if running then
				fetched[starter.Key] = getProductPrice(starter.ProductId, infoTypeProduct, starter.PriceHint)
			end

			for _, pass in pairs(MonetizationConfig.GamePasses) do
				if running then
					fetched[pass.Key] = getProductPrice(pass.PassId, infoTypeGamePass, pass.PriceHint)
				end
			end

			if running then
				setPrices(fetched)
			end
		end)

		return function()
			running = false
		end
	end, {})

	local ownedPasses = stats and stats.OwnedGamePasses or {}
	local purchasedProducts = stats and stats.PurchasedProducts or {}
	local cash = stats and stats.Cash or 0
	local starterOwned = purchasedProducts[MonetizationConfig.StarterProduct.Key] == true

	local function promptProduct(productId: number)
		if not player or not MonetizationConfig.IsConfigured(productId) then
			return
		end
		MarketplaceService:PromptProductPurchase(player, productId)
	end

	local function promptPass(passId: number)
		if not player or not MonetizationConfig.IsConfigured(passId) then
			return
		end
		MarketplaceService:PromptGamePassPurchase(player, passId)
	end

	local cashTabChildren = {}
	local order = 1

	if not starterOwned then
		local starter = MonetizationConfig.StarterProduct
		table.insert(
			cashTabChildren,
			e(StoreCard, {
				Title = starter.DisplayName,
				Description = starter.Description .. ` Includes {starter.Cash} cash.`,
				PriceText = prices[starter.Key] or "Loading...",
				ActionText = MonetizationConfig.IsConfigured(starter.ProductId) and "Get Pack" or "Setup required",
				ActionDisabled = not MonetizationConfig.IsConfigured(starter.ProductId),
				AccentColor = Color3.fromRGB(255, 190, 80),
				LayoutOrder = order,
				OnAction = function()
					promptProduct(starter.ProductId)
				end,
			})
		)
		order += 1
	end

	for _, product in ipairs(MonetizationConfig.CashProducts) do
		table.insert(
			cashTabChildren,
			e(StoreCard, {
				Title = product.DisplayName,
				Description = `{product.Cash} cash. {product.BestValue and "Best value." or ""}`,
				PriceText = prices[product.Key] or "Loading...",
				ActionText = MonetizationConfig.IsConfigured(product.ProductId) and "Buy" or "Setup required",
				ActionDisabled = not MonetizationConfig.IsConfigured(product.ProductId),
				LayoutOrder = order,
				OnAction = function()
					promptProduct(product.ProductId)
				end,
			})
		)
		order += 1
	end

	local doubleCash = MonetizationConfig.GamePasses.DoubleCash
	local doubleCashOwned = ownedPasses[doubleCash.Key] == true
	local premiumPaint = MonetizationConfig.GamePasses.PremiumPaint
	local premiumPaintOwned = ownedPasses[premiumPaint.Key] == true

	local perksTabChildren = {
		e(StoreCard, {
			Title = doubleCash.DisplayName,
			Description = doubleCash.Description,
			PriceText = doubleCashOwned and "Active" or (prices[doubleCash.Key] or "Loading..."),
			ActionText = doubleCashOwned and "Owned"
				or (MonetizationConfig.IsConfigured(doubleCash.PassId) and "Unlock" or "Setup required"),
			ActionDisabled = doubleCashOwned or not MonetizationConfig.IsConfigured(doubleCash.PassId),
			AccentColor = Color3.fromRGB(120, 220, 150),
			LayoutOrder = 1,
			OnAction = function()
				promptPass(doubleCash.PassId)
			end,
		}),
	}

	local swatchCells = {}
	for index, swatch in ipairs(PaintConfig.SwatchList) do
		local locked = swatch.Premium and not premiumPaintOwned
		swatchCells[swatch.Name] = e("Frame", {
			Size = UDim2.fromOffset(mobile and 24 or 30, mobile and 24 or 30),
			BackgroundColor3 = swatch.Color,
			BackgroundTransparency = locked and 0.35 or 0,
			LayoutOrder = index,
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
			locked and e(SmallText, {
				Text = "•",
				TextSize = 10,
				Size = UDim2.fromScale(1, 1),
				AutomaticSize = Enum.AutomaticSize.None,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextColor3 = Color3.new(1, 1, 1),
			}) or nil,
		})
	end

	local styleTabChildren = {
		e(StoreCard, {
			Title = premiumPaint.DisplayName,
			Description = premiumPaint.Description,
			PriceText = premiumPaintOwned and "Active" or (prices[premiumPaint.Key] or "Loading..."),
			ActionText = premiumPaintOwned and "Owned"
				or (MonetizationConfig.IsConfigured(premiumPaint.PassId) and "Unlock" or "Setup required"),
			ActionDisabled = premiumPaintOwned or not MonetizationConfig.IsConfigured(premiumPaint.PassId),
			AccentColor = Color3.fromRGB(220, 160, 255),
			LayoutOrder = 1,
			OnAction = function()
				promptPass(premiumPaint.PassId)
			end,
		}, {
			Swatches = e(Grid, {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				CellSize = UDim2.fromOffset(mobile and 24 or 30, mobile and 24 or 30),
				CellPadding = UDim2.fromOffset(6, 6),
				FillDirectionMaxCells = mobile and 8 or 10,
				LayoutOrder = 5,
			}, swatchCells),
		}),
	}

	local tabContent = if tab == "cash"
		then cashTabChildren
		elseif tab == "perks" then perksTabChildren
		else styleTabChildren

	return e(Panel, {
		Title = "Cafe Store",
		Open = isOpen,
		Size = mobile and UDim2.fromScale(0.82, 0.78) or UDim2.fromScale(0.55, 0.72),
		Spacing = UDim.new(0, 10),
		Padding = { All = UDim.new(0, 12) },
		BackgroundImage = "rbxassetid://103478691850846",
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(8, 8, 92, 92),
		BackgroundImageColor3 = Color3.fromRGB(180, 170, 160),
		OpenPosition = UDim2.fromScale(0.5, 0.5),
		HiddenPosition = UDim2.fromScale(0.5, 1.5),
		BackgroundImageTransparency = 0.15,
		OnClose = function()
			UIState.toggle("none")
		end,
	}, {
		ContentRoot = e(VStack, {
			Size = UDim2.fromScale(1, 1),
			AutomaticSize = Enum.AutomaticSize.None,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			HorizontalFlex = "Fill",
			VerticalFlex = "None",
			Spacing = UDim.new(0, 10),
			LayoutOrder = 1,
		}, {
			Tabs = e(HStack, {
				Size = UDim2.new(1, 0, 0, 40),
				AutomaticSize = Enum.AutomaticSize.None,
				HorizontalFlex = "Fill",
				Spacing = UDim.new(0, 8),
				LayoutOrder = 1,
			}, {
				Cash = e(SmallButton, {
					Text = "Cash",
					Size = UDim2.new(0, 0, 1, 0),
					AutomaticSize = Enum.AutomaticSize.None,
					BackgroundTransparency = tab == "cash" and 0 or 0.55,
					LayoutOrder = 1,
					[React.Event.Activated] = function()
						setTab("cash")
					end,
				}),
				Perks = e(SmallButton, {
					Text = "Perks",
					Size = UDim2.new(0, 0, 1, 0),
					AutomaticSize = Enum.AutomaticSize.None,
					BackgroundTransparency = tab == "perks" and 0 or 0.55,
					LayoutOrder = 2,
					[React.Event.Activated] = function()
						setTab("perks")
					end,
				}),
				Style = e(SmallButton, {
					Text = "Style",
					Size = UDim2.new(0, 0, 1, 0),
					AutomaticSize = Enum.AutomaticSize.None,
					BackgroundTransparency = tab == "style" and 0 or 0.55,
					LayoutOrder = 3,
					[React.Event.Activated] = function()
						setTab("style")
					end,
				}),
			}),
			Balance = e(SmallText, {
				Text = `Your cash: {cash}`,
				TextSize = 14,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				TextColor3 = Color3.fromRGB(200, 200, 210),
				LayoutOrder = 2,
			}),
			Content = e("ScrollingFrame", {
				Size = UDim2.new(1, 0, 1, -80),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 8,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				ScrollingDirection = Enum.ScrollingDirection.Y,
				LayoutOrder = 3,
			}, {
				List = e(VStack, {
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					HorizontalFlex = "None",
					VerticalFlex = "None",
					Spacing = UDim.new(0, 8),
				}, tabContent),
			}),
		}),
	})
end

return StorePanel
