-- Shared/ReactComponents/IngredientShopPanel.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
local Toasts = require(ReplicatedStorage.Shared.ReactComponents.Toasts)
local useToast = Toasts.useToast
local e = React.createElement
local useState = React.useState
local useBinding = React.useBinding
local useRef = React.useRef
local useEffect = React.useEffect
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local LevelConfig = require(ReplicatedStorage.Shared.Configs.LevelConfig)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local ShopCycle = require(ReplicatedStorage.Shared.ShopCycle)

local ROBUX =
	[[<font family="rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json">robux</font>]]

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local DefaultPanel = require(script.Parent.DefaultPanel)
local DefaultScrollFrame = require(script.Parent.DefaultScrollFrame)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)

local player = game.Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""
local function IngredientShopPanel(props: {
	OnClose: () -> (),
})
	--listen to active panel
	local panelOpen, setPanelOpen = useState((not player) or false)
	local toast = useToast()

	local time, setTime = React.useBinding("")
	useEffect(function()
		local t = task.spawn(function()
			while task.wait(0.5) do
				setTime(workspace:GetServerTimeNow())
			end
		end)
		return function()
			task.cancel(t)
		end
	end, {})
	useEffect(function()
		local unsub = UIState:subscribe(function(state: UIState.UIState)
			setPanelOpen(state.panel == "ingredientShop")
		end)
		return unsub
	end, {})

	local shopItems = {}
	local selected, setSelected = useBinding(nil)
	local shop, setShop = useState((not player) and {
		shops = {
			["1"] = {
				espresso = 10,
			},
		},
		currentSeed = "1",
	})
	local level, setLevel = useState(1)
	local prevSeedRef = useRef(nil)

	local seed = shop and shop.currentSeed

	useEffect(function()
		if not seed then
			return
		end
		if not prevSeedRef.current then
			prevSeedRef.current = seed
			return
		end
		if prevSeedRef.current ~= seed then
			SoundController.Sound("glass_004")
			toast.open("Ingredient Shop Restocked!")
		end
		return
	end, { seed })

	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.Shop[playerId]
		end, function(playersShop)
			setShop(playersShop)
		end)
		local state = GlobalState:getState()
		local playersShop = state.Shop[playerId]
		if playersShop then
			setShop(playersShop)
		end
		return unsub
	end, {})
	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.Stats[playerId]
		end, function(playersStats)
			if playersStats and playersStats.Level then
				setLevel(playersStats.Level)
			end
		end)
		local state = GlobalState:getState()
		local playersStats = state.Stats[playerId]
		if playersStats and playersStats.Level then
			setLevel(playersStats.Level)
		end
		return unsub
	end, {})

	useEffect(function()
		setSelected(nil)
	end, { panelOpen })

	for i, config in pairs(CoffeeModule.IngredientConfigs) do
		local id = config.Id

		local shops = shop and shop.shops
		local seed = tostring(shop and shop.currentSeed)
		local currentShop = shops and shops[seed]
		local amount = currentShop and currentShop[config.Id] or 0

		local locked = not LevelConfig[level].Ingredients[config.Id]

		shopItems[id] = e("ImageButton", {
			AutomaticSize = Enum.AutomaticSize.XY,
			[React.Event.Activated] = function()
				local selectedId = selected:getValue()

				setSelected(selectedId ~= id and id or nil)
			end,
			Image = "rbxassetid://127657596958436",
			SliceCenter = Rect.new(8, 8, 92, 92),
			ScaleType = Enum.ScaleType.Slice,
			-- Image = "rbxassetid://135201205917919",
			LayoutOrder = i,
			ImageColor3 = Color3.new(0.658823, 0.164705, 0.164705),
			BackgroundTransparency = 1,
		}, {
			Content = e(VStack, {
				Spacing = UDim.new(0, 4),
				HorizontalFlex = Enum.UIFlexAlignment.Fill,
				VerticalFlex = Enum.UIFlexAlignment.Fill,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				AutomaticSize = Enum.AutomaticSize.XY,
				Padding = { All = UDim.new(0, 12) },
			}, {
				Content = e(HStack, {
					Spacing = UDim.new(0, 4),
					HorizontalFlex = Enum.UIFlexAlignment.Fill,
					VerticalFlex = Enum.UIFlexAlignment.Fill,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					AutomaticSize = Enum.AutomaticSize.XY,
					Padding = { All = UDim.new(0, 12) },
				}, {
					Left = e(VStack, {
						Size = UDim2.new(0, 100, 0, 100),
						AutomaticSize = Enum.AutomaticSize.XY,
						HorizontalFlex = Enum.UIFlexAlignment.None,
						VerticalFlex = Enum.UIFlexAlignment.None,
						LayoutOrder = 1,
						BackgroundTransparency = 1,
						BackgroundImage = "rbxassetid://127657596958436",
						SliceCenter = Rect.new(8, 8, 92, 92),
						BackgroundImageColor3 = Color3.new(0.854901, 0.741176, 0.741176),
						ScaleType = Enum.ScaleType.Slice,
					}, {
						Icon = e("ImageLabel", {
							Size = UDim2.new(0, 100, 0, 100),
							Image = config.Image,
							BackgroundTransparency = 1,
							ImageColor3 = locked and Color3.new() or nil,
							ImageTransparency = locked and 0.5 or nil,
							LayoutOrder = 1,
						}),
					}),
					Right = e(VStack, {
						Spacing = UDim.new(0, 12),
						Size = UDim2.new(0, 200, 0, 100),
						AutomaticSize = Enum.AutomaticSize.None,
						VerticalFlex = Enum.UIFlexAlignment.None,
						HorizontalFlex = Enum.UIFlexAlignment.Fill,
						Padding = { All = UDim.new(0, 12) },
						VerticalAlignment = Enum.VerticalAlignment.Top,
						LayoutOrder = 2,
					}, {
						Label = e(SmallText, {
							Text = `{config.DisplayName}`,
							-- Text = `{locked and "???" or config.DisplayName}`,
							Size = UDim2.new(0, 200, 0, 0),
							LayoutOrder = 1,
							TextSize = 20,
							TextWrapped = true,
							TextXAlignment = Enum.TextXAlignment.Left,
							TextTransparency = locked and 0.5 or nil,
						}),
						Stocks = e(SmallText, {
							Text = `Stocks: {amount} left`,
							Size = UDim2.new(0, 200, 0, 0),
							LayoutOrder = 2,
							TextSize = 16,
							TextWrapped = true,
							TextTransparency = locked and 0.5 or nil,
							TextXAlignment = Enum.TextXAlignment.Left,
						}),
					}),
				}),
				Under = e(HStack, {
					Size = UDim2.new(1, 0, 0, 0),
					Position = UDim2.new(0, 0, 1, 0),
					Visible = selected:map(function(selectedId)
						return selectedId == id
					end),
					AutomaticSize = Enum.AutomaticSize.XY,
					HorizontalFlex = Enum.UIFlexAlignment.Fill,
					Spacing = UDim.new(0, 8),
				}, {

					BuyBtn = e(SmallButton, {
						Text = locked and "Locked" or `Buy {config.Cost}$`,
						TextSize = 24,
						Size = UDim2.new(1, 0, 0, 0),
						TextColor3 = locked and Color3.new(0.5, 0.5, 0.5) or nil,
						LayoutOrder = 3,
						BackgroundColor3 = Color3.new(0.5, 1, 0.5),
						[React.Event.Activated] = function()
							Remotes.BuyIngredient:FireServer(id)
						end,
						Visible = selected:map(function(selectedId)
							return selectedId == id or false
						end),
					}),
					BuyRbx = e(SmallButton, {
						RichText = true,
						Text = ` {ROBUX} Buy 1x`,
						TextSize = 24,
						Size = UDim2.new(0, 180, 0, 0),
						TextWrapped = false,
						LayoutOrder = 3,
						BackgroundColor3 = Color3.new(0.5, 1, 0.5),
						[React.Event.Activated] = function()
							Remotes.BuyIngredient:FireServer(id)
						end,
						Visible = selected:map(function(selectedId)
							return selectedId == id or false
						end),
					}),
					BuyRbx10 = e(SmallButton, {
						RichText = true,
						Text = ` {ROBUX} Buy 10x`,
						TextSize = 24,
						Size = UDim2.new(0, 180, 0, 0),
						TextWrapped = false,
						LayoutOrder = 3,
						BackgroundColor3 = Color3.new(0.5, 1, 0.5),
						[React.Event.Activated] = function()
							Remotes.BuyIngredient:FireServer(id)
						end,
						Visible = selected:map(function(selectedId)
							return selectedId == id or false
						end),
					}),
				}),
			}),
		})
	end

	return e(DefaultPanel, {
		Title = "Ingredient Shop",
		Size = UDim2.new(0.5, 0, 1, 0),
		-- MinSize = Vector2.new(500, 320),
		MaxSize = Vector2.new(500, 500),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		OnClose = props.OnClose,
		BackgroundImageTransparency = 0,
		-- BackgroundImage = "",
		-- BackgroundTransparency = 0,
		Open = panelOpen,
	}, {
		e("Frame", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
		}, {
			e("Frame", {
				Size = time:map(function()
					local cycle = ShopCycle.getCurrentState()
					-- local text = `Shop refreshes in: {cycle.timeLeft // 60}m {cycle.timeLeft // 1 % 60}s`
					return UDim2.new((cycle.timeLeft // 1 % (60 * 5)) / 60 / 5, 0, 0, 30)
				end),
				ZIndex = 1,
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0, 12),
				}),
			}),
			e(SmallText, {
				Text = time:map(function()
					local cycle = ShopCycle.getCurrentState()
					local text = `Shop refreshes in: {cycle.timeLeft // 60}m {cycle.timeLeft // 1 % 60}s`
					return text
				end),
				Size = UDim2.new(1, 0, 0, 0),
				ZIndex = 2,
			}),
		}),
		DefaultScrollFrame = e(DefaultScrollFrame, {
			Size = UDim2.new(1, 0, 1, 0),
		}, {
			Grid = e(VStack, {
				-- CellSize = UDim2.new(1, -20, 0, 150),
				Spacing = UDim.new(0, 4),
				Size = UDim2.new(1, 0, 1, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				VerticalFlex = Enum.UIFlexAlignment.None,
			}, shopItems),
		}),
	})
end

return IngredientShopPanel
