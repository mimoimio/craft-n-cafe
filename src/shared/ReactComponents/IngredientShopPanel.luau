-- Shared/ReactComponents/IngredientShopPanel.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local DefaultPanel = require(script.Parent.DefaultPanel)
local DefaultScrollFrame = require(script.Parent.DefaultScrollFrame)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local Grid = require(Primitives.Grid)
local VStack = require(Primitives.VStack)

local function IngredientShopPanel(props)
	local shopItems = {}

	for id, config in pairs(CoffeeModule.IngredientsConfig) do
		shopItems[id] = e(VStack, {
			Spacing = UDim.new(0, 4),
			HorizontalFlex = Enum.UIFlexAlignment.None,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			BackgroundTransparency = 0,
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
			Icon = config.Image and e("ImageLabel", {
				Size = UDim2.new(0, 50, 0, 50),
				Image = config.Image,
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}),
			Label = e(SmallText, {
				Text = config.DisplayName,
				Size = UDim2.new(1, 0, 0, 40),
				LayoutOrder = 2,
				TextSize = 12,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Center,
			}),
			BuyBtn = e(SmallButton, {
				Text = "Buy",
				Size = UDim2.new(1, 0, 0, 30),
				LayoutOrder = 3,
				BackgroundColor3 = Color3.new(0.5, 1, 0.5),
				[React.Event.Activated] = function()
					Remotes.BuyIngredient:FireServer(id)
				end,
			}),
		})
	end

	return e(DefaultPanel, {
		Title = "Ingredient Shop",
		Size = UDim2.new(0.5, 0, 0.5, 0),
		MinSize = Vector2.new(500, 320),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		OnClose = props.OnClose,
		BackgroundImageTransparency = 0.9,
	}, {
		DefaultScrollFrame = e(DefaultScrollFrame, {
			Size = UDim2.new(1, 0, 1, 0),
		}, {
			Grid = e(Grid, {
				CellSize = UDim2.new(0, 80, 0, 150),
				AutomaticSize = Enum.AutomaticSize.XY,
			}, shopItems),
		}),
	})
end

return IngredientShopPanel
