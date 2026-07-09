-- Shared/ReactComponents/IngredientShopPanel.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useBinding = React.useBinding
local useEffect = React.useEffect
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local DefaultPanel = require(script.Parent.DefaultPanel)
local DefaultScrollFrame = require(script.Parent.DefaultScrollFrame)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)

local function IngredientShopPanel(props: {
	Open: boolean,
	OnClose: () -> (),
})
	local shopItems = {}
	local selected, setSelected = useBinding(nil)
	useEffect(function()
		setSelected(nil)
	end, { props.Open })

	for i, config in pairs(CoffeeModule.IngredientConfigs) do
		local id = config.Id
		shopItems[id] = e("ImageButton", {
			AutomaticSize = Enum.AutomaticSize.XY,
			[React.Event.Activated] = function()
				setSelected(id)
			end,
			Image = "rbxassetid://135201205917919",
			LayoutOrder = i,
			ImageColor3 = Color3.new(1, 0, 0),
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(0, 12),
			}),
			Content = e(HStack, {
				Spacing = UDim.new(0, 4),
				HorizontalFlex = Enum.UIFlexAlignment.Fill,
				VerticalFlex = Enum.UIFlexAlignment.Fill,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				AutomaticSize = Enum.AutomaticSize.XY,
				-- BackgroundTransparency = 1,
				-- BackgroundColor3 = Color3.new(1, 0, 0),
				Padding = { All = UDim.new(0, 12) },
			}, {
				Left = e(VStack, {
					Size = UDim2.new(0, 100, 0, 100),
					-- Size = UDim2.new(1, 0, 1, 0),
					-- AutomaticSize = Enum.AutomaticSize.None,
					AutomaticSize = Enum.AutomaticSize.XY,
					-- Padding = { All = UDim.new(0, 8) },
					HorizontalFlex = Enum.UIFlexAlignment.None,
					VerticalFlex = Enum.UIFlexAlignment.None,
					LayoutOrder = 1,
					BackgroundTransparency = 1,
					-- BackgroundTransparency = 0.6,
					-- BackgroundColor3 = Color3.new(1, 0, 0),
				}, {
					Icon = e("ImageLabel", {
						Size = UDim2.new(0, 100, 0, 100),
						Image = config.Image,
						BackgroundTransparency = 1,
						-- BackgroundTransparency = 0.6,
						-- BackgroundColor3 = Color3.new(1, 0, 0),
						LayoutOrder = 1,
						-- ref = function()
						-- 	warn(`DisplayName({config.DisplayName}), Price({config.Price})`)
						-- end,
					}),
					-- Label = e(SmallText, {
					-- 	Text = `{config.DisplayName}`,
					-- 	Size = UDim2.new(0, 0, 0, 40),
					-- 	LayoutOrder = 2,
					-- 	TextSize = 16,
					-- 	TextWrapped = true,
					-- 	TextXAlignment = Enum.TextXAlignment.Left,
					-- }),
				}),
				Right = e(VStack, {
					Spacing = UDim.new(0, 12),
					Size = UDim2.new(0, 200, 0, 100),
					AutomaticSize = Enum.AutomaticSize.None,
					VerticalFlex = Enum.UIFlexAlignment.None,
					HorizontalFlex = Enum.UIFlexAlignment.Fill,
					Padding = { All = UDim.new(0, 12) },
					VerticalAlignment = Enum.VerticalAlignment.Top,
					-- BackgroundColor3 = Color3.new(0.5, 1, 0.5),
					-- BackgroundTransparency = 0,
					LayoutOrder = 2,
				}, {
					Label = e(SmallText, {
						Text = `{config.DisplayName}`,
						Size = UDim2.new(0, 200, 0, 0),
						LayoutOrder = 2,
						TextSize = 12,
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
					Price = e(SmallText, {
						Text = `({config.Cost} $)`,
						Size = UDim2.new(0, 200, 0, 0),
						LayoutOrder = 2,
						TextSize = 16,
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
					BuyBtn = e(SmallButton, {
						Text = "Buy",
						Size = UDim2.new(0, 0, 0, 30),
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
		Open = props.Open,
	}, {
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
