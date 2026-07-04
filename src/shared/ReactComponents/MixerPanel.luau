-- Shared/ReactComponents/MixerPanel.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local DefaultPanel = require(script.Parent.DefaultPanel)
local DefaultScrollFrame = require(script.Parent.DefaultScrollFrame)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local Grid = require(Primitives.Grid)
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)

local player = game.Players.LocalPlayer
local playerId: string? = player and tostring(player.UserId)

local function MixerPanel(props: {
	State: GlobalState.GlobalState,
	MixerId: string,
	OnClose: () -> (),
})
	local currentIngredients, setCurrentIngredients = useState({})
	local state = props.State or {}
	local ing = state.Ingredients or {}
	local ingredients = ing[playerId] or {}

	local function removeIngredientAtIndex(index: number)
		setCurrentIngredients(function(prev)
			local nextState = table.clone(prev)
			table.remove(nextState, index)
			return nextState
		end)
	end

	-- Dynamically fetch the recipe result when state changes
	local resultConfig = CoffeeModule.Craft(currentIngredients)

	-- Calculate how many of each ingredient are currently in the mixer
	local usedIngredients = {}
	for _, id in ipairs(currentIngredients) do
		usedIngredients[id] = (usedIngredients[id] or 0) + 1
	end

	local ingredientElements = {}
	-- ingredients.espresso = 1
	for id, config in pairs(CoffeeModule.IngredientsConfig) do
		local totalAvailable = ingredients[id] or 0
		local amountUsed = usedIngredients[id] or 0
		local amountLeft = totalAvailable - amountUsed

		-- Update transparency based on the remaining amount instead of total amount
		local transparency = amountLeft <= 0 and 0.4 or 0

		ingredientElements[id] = e(SmallButton, {
			OverlayText = config.DisplayName,
			OverlayTextSize = 10,
			OverlayTextWrapped = true,
			ButtonClass = "ImageButton",
			Image = config.Image,
			OverlayTextTransparency = transparency,
			BackgroundTransparency = transparency,
			LayoutOrder = config.Price,
			ImageTransparency = transparency,
			Padding = { All = UDim.new(0, 4) },
			[React.Event.Activated] = function()
				-- Prevent adding if the player has used up their available amount
				if amountLeft > 0 then
					setCurrentIngredients(function(prev)
						local nextState = table.clone(prev)
						table.insert(nextState, id)
						return nextState
					end)
				end
			end,
		}, {
			Count = e(SmallText, {
				Size = UDim2.new(0, 20, 0, 20),
				AnchorPoint = Vector2.new(0.25, 0.25),
				Text = amountLeft, -- Display the dynamically calculated remaining amount
				TextTransparency = transparency,
				BackgroundTransparency = transparency,
				TextXAlignment = Enum.TextXAlignment.Center,
				BackgroundColor3 = Color3.new(1, 0, 0),
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}),
			}),
		})
	end

	local selectedIngredientElements = {}
	for index, id in ipairs(currentIngredients) do
		local ingredientIndex = index
		local config = CoffeeModule.Config[id]
		selectedIngredientElements[index] = e(SmallButton, {
			OverlayText = config.DisplayName,
			OverlayTextSize = 12,
			LayoutOrder = config.Price,
			OverlayTextWrapped = true,
			ButtonClass = "ImageButton",
			Image = config.Image,
			Size = UDim2.new(0, 60, 0, 60),
			Padding = { All = UDim.new(0, 4) },
			BackgroundColor3 = Color3.fromRGB(84, 52, 52),
			[React.Event.Activated] = function()
				removeIngredientAtIndex(ingredientIndex)
			end,
		})
	end

	local selectionDisplay = table.concat(currentIngredients, " + ")

	return e("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
	}, {

		Padding = e("UIPadding", {
			PaddingTop = UDim.new(0, 20),
			-- PaddingBottom = UDim.new(0, 20),
			-- PaddingLeft = UDim.new(0, 0),
			PaddingRight = UDim.new(0, 20),
		}),
		Left = e(VStack, {
			Size = UDim2.new(0.7, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Spacing = UDim.new(0, 10),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			VerticalFlex = Enum.UIFlexAlignment.None,
		}, {
			Header = e(SmallText, {
				Text = "Added Ingredients",
				Size = UDim2.new(1, 0, 0, 30),
				LayoutOrder = 1,
				TextXAlignment = Enum.TextXAlignment.Center,
			}),

			Divider = e("Frame", {
				Size = UDim2.new(1, 0, 0, 2),
				AutomaticSize = Enum.AutomaticSize.None,
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.5,
				LayoutOrder = 2,
			}),

			IngredientList = e(HStack, {
				Size = UDim2.new(1, 0, 0.5, -40),
				VerticalFlex = Enum.UIFlexAlignment.None,
				HorizontalFlex = Enum.UIFlexAlignment.None,
				-- BackgroundTransparency = 0,
				LayoutOrder = 3,
				Spacing = UDim.new(0, 10),
			}, {
				EmptyState = #selectedIngredientElements == 0 and e(SmallText, {
					Text = "No ingredients added",
					Size = UDim2.new(1, 0, 0, 30),
					TextXAlignment = Enum.TextXAlignment.Center,
				}) or nil,
				Ingredients = e(React.Fragment, {}, selectedIngredientElements),
			}),

			Controls = e(HStack, {
				Size = UDim2.new(1, 0, 0.5, -40),
				Spacing = UDim.new(0, 10),
				-- BackgroundTransparency = 0,
				LayoutOrder = 4,
				AutomaticSize = Enum.AutomaticSize.XY,
				HorizontalFlex = Enum.UIFlexAlignment.None,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}, {
				CraftButton = e(SmallButton, {
					Text = "Craft",
					Size = UDim2.new(0, 100, 0, 40),
					[React.Event.Activated] = function()
						if resultConfig and props.MixerId then
							Remotes.MixDrink:FireServer(resultConfig.Id, props.MixerId)
							setCurrentIngredients({})
							if props.OnClose then
								props.OnClose()
							end
						end
					end,
				}),
				PickUpButton = e(SmallButton, {
					Text = "PickUp",
					Size = UDim2.new(0, 100, 0, 40),
					[React.Event.Activated] = function()
						if props.MixerId then -- Ensure Remotes.PickUpDrink is defined in your Remotes module
							Remotes.PickUpDrink:FireServer(props.MixerId)
							if props.OnClose then
								props.OnClose()
							end
						end
					end,
				}),
				ClearButton = e(SmallButton, {
					Text = "Clear",
					Size = UDim2.new(0, 100, 0, 40),
					[React.Event.Activated] = function()
						setCurrentIngredients({})
					end,
				}),
			}),
		}),
		Right = e(DefaultPanel, {
			Title = "Mixer: " .. tostring(props.MixerId),
			Size = UDim2.new(0.3, -20, 1, -40),
			MinSize = Vector2.new(350, 300),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			BackgroundImageTransparency = 0.9,
			OnClose = props.OnClose,
		}, {
			Content = e(VStack, { Spacing = UDim.new(0, 10) }, {
				-- Ingredients Grid
				DefaultScrollFrame = e(DefaultScrollFrame, {
					LayoutOrder = 1,
					AutomaticSize = Enum.AutomaticSize.XY,
				}, {
					Grid = e(Grid, {
						Size = UDim2.new(1, 0, 0, 200),
						CellSize = UDim2.new(0, 60, 0, 150),
						Padding = { All = UDim.new(0, 4) },
						AutomaticSize = Enum.AutomaticSize.XY,
					}, ingredientElements),
				}),

				Divider = e("Frame", {
					Size = UDim2.new(1, 0, 0, 2),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 0.5,
				}),

				-- Status/Selection Text outputs
				SelectionText = e(SmallText, {
					Text = "Selection: " .. (selectionDisplay ~= "" and selectionDisplay or "None"),
					Size = UDim2.new(1, 0, 0, 30),
				}),

				ResultText = e(SmallText, {
					Text = "Preview: " .. (resultConfig and resultConfig.DisplayName or "Unknown Recipe"),
					Size = UDim2.new(1, 0, 0, 30),
				}),
			}),
		}),
	})
end

return MixerPanel
