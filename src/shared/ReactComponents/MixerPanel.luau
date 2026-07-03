-- Shared/ReactComponents/MixerPanel.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local DefaultPanel = require(script.Parent.DefaultPanel)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local Grid = require(Primitives.Grid)
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)

local function MixerPanel(props: {
	MixerId: string,
	OnClose: () -> (),
})
	local currentIngredients, setCurrentIngredients = useState({})

	-- Dynamically fetch the recipe result when state changes
	local resultConfig = CoffeeModule.Craft(currentIngredients)

	local ingredientElements = {}
	for id, config in pairs(CoffeeModule.IngredientsConfig) do
		ingredientElements[id] = e(SmallButton, {
			Text = config.DisplayName,
			[React.Event.Activated] = function()
				setCurrentIngredients(function(prev)
					local nextState = table.clone(prev)
					table.insert(nextState, id)
					return nextState
				end)
			end,
		})
	end

	local selectionDisplay = table.concat(currentIngredients, " + ")

	return e(DefaultPanel, {
		Title = "Mixer: " .. tostring(props.MixerId),
		Size = UDim2.new(0, 450, 0, 500),
		OnClose = props.OnClose,
	}, {
		Content = e(VStack, { Spacing = UDim.new(0, 10) }, {
			-- Ingredients Grid
			GridArea = e(Grid, {
				CellSize = UDim2.new(0, 120, 0, 40),
				Size = UDim2.new(1, 0, 0, 200),
			}, ingredientElements),

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

			-- Controls
			Controls = e(HStack, { Spacing = UDim.new(0, 10) }, {
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
						if props.MixerId then
							-- Ensure Remotes.PickUpDrink is defined in your Remotes module
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
	})
end

return MixerPanel
