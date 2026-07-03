-- Shared/ReactComponents/IngredientShopPanel.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local DefaultPanel = require(script.Parent.DefaultPanel)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local Grid = require(Primitives.Grid)
local VStack = require(Primitives.VStack)

local function IngredientShopPanel(props)
	local shopItems = {}

	for id, config in pairs(CoffeeModule.IngredientsConfig) do
		shopItems[id] = e(VStack, { Spacing = UDim.new(0, 4) }, {
			Icon = config.Image and e("ImageLabel", {
				Size = UDim2.new(0, 50, 0, 50),
				Image = config.Image,
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}),
			Label = e(SmallText, {
				Text = config.DisplayName,
				Size = UDim2.new(1, 0, 0, 20),
				LayoutOrder = 2,
			}),
			BuyBtn = e(SmallButton, {
				Text = "Buy",
				Size = UDim2.new(1, 0, 0, 30),
				LayoutOrder = 3,
				[React.Event.Activated] = function()
					Remotes.BuyIngredient:FireServer(id)
				end,
			}),
		})
	end

	return e(DefaultPanel, {
		Title = "Ingredient Shop",
		Size = UDim2.new(0, 400, 0, 400),
		OnClose = props.OnClose,
	}, {
		Grid = e(Grid, {
			CellSize = UDim2.new(0, 100, 0, 120),
		}, shopItems),
	})
end

return IngredientShopPanel
