local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local DefaultScrollFrame = require(script.Parent.DefaultScrollFrame)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local Grid = require(Primitives.Grid)
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)

-- Point this to your new VFX setup
local IngredientVFXContainer = require(script.Parent.IngredientVFXContainer)

local player = game.Players.LocalPlayer
local playerId: string? = player and tostring(player.UserId) or "0"

local function MixerPanel(props: {
	Ingredients: { [string]: number },
	MixerId: string,
	Open: boolean,
	OnClose: () -> (),
})
	local currentIngredients, setCurrentIngredients = useState({})

	-- NEW: Track ingredients currently flying through the air
	local pendingIngredients, setPendingIngredients = useState({})
	local activeTrails, setActiveTrails = useState({})

	-- Reference to the selected ingredients UI to act as the target position
	local targetRef = React.useRef(nil)

	local ing = props.Ingredients or {}
	local ingredients = ing[playerId] or {}

	local function removeIngredientAtIndex(index: number)
		setCurrentIngredients(function(prev)
			local nextState = table.clone(prev)
			table.remove(nextState, index)
			return nextState
		end)
	end

	local resultConfig = CoffeeModule.Craft(currentIngredients)

	-- MODIFIED: Calculate used ingredients based on BOTH current AND pending
	local usedIngredients = {}
	for _, id in ipairs(currentIngredients) do
		usedIngredients[id] = (usedIngredients[id] or 0) + 1
	end
	for id, count in pairs(pendingIngredients) do
		usedIngredients[id] = (usedIngredients[id] or 0) + count
	end

	React.useEffect(function() end, {})

	local ingredientElements = {}
	for i, config in ipairs(CoffeeModule.IngredientConfigs) do
		local id = config.Id
		local totalAvailable = ingredients[id] or 0
		local amountUsed = usedIngredients[id] or 0
		local amountLeft = totalAvailable - amountUsed

		local transparency = amountLeft <= 0 and 0.4 or 0

		ingredientElements[id] = e(SmallButton, {
			OverlayText = config.DisplayName,
			OverlayTextSize = 10,
			OverlayTextWrapped = true,
			ButtonClass = "ImageButton",
			Image = config.Image,
			OverlayTextTransparency = transparency,
			BackgroundTransparency = transparency,
			LayoutOrder = i,
			ImageTransparency = transparency,
			Padding = { All = UDim.new(0, 4) },

			-- MODIFIED: Capture AbsolutePosition and initiate the trail
			[React.Event.Activated] = function(rbx)
				if amountLeft > 0 and not (table.find(currentIngredients, id) or pendingIngredients[id]) then
					local inset = GuiService:GetGuiInset()

					-- Capture start position directly from the clicked button
					local startPos = rbx.AbsolutePosition + (rbx.AbsoluteSize / 2) + inset

					-- Fallback to center screen if ref hasn't mounted
					local targetPos = targetRef.current
							and (targetRef.current.AbsolutePosition + (targetRef.current.AbsoluteSize / 2) + inset)
						or (workspace.CurrentCamera.ViewportSize / 2)

					local uniqueId = tostring(tick()) .. "_" .. id .. "_" .. amountLeft

					-- 1. Add to pending so UI immediately deducts
					setPendingIngredients(function(prev)
						local next = table.clone(prev)
						next[id] = (next[id] or 0) + 1
						return next
					end)

					-- 2. Launch the particle (passing image so VFX is decoupled from CoffeeModule)
					setActiveTrails(function(prev)
						local next = table.clone(prev)
						next[uniqueId] = {
							id = uniqueId,
							ingredientId = id,
							image = config.Image,
							startPos = startPos,
							targetPos = targetPos,
						}
						return next
					end)
				end
			end,
		}, {
			Count = e(SmallText, {
				Size = UDim2.new(0, 20, 0, 20),
				AnchorPoint = Vector2.new(0.25, 0.25),
				Text = amountLeft,
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
	for i = 1, 9 do -- set limit to 9 ingredients later
		local id = currentIngredients[i]
		local config = CoffeeModule.IngredientLookup[id] -- Adjusted to grab from Config
		selectedIngredientElements[i] = e(SmallButton, {
			OverlayText = config and config.DisplayName,
			OverlayTextSize = 12,
			-- LayoutOrder = config and config.Price,
			LayoutOrder = i,
			OverlayTextWrapped = true,
			ButtonClass = "ImageButton",
			AutomaticSize = Enum.AutomaticSize.None,
			Image = config and config.Image,
			Size = UDim2.new(0, 50, 0, 50),
			Padding = { All = UDim.new(0, 4) },
			BackgroundColor3 = Color3.fromRGB(84, 52, 52),
			[React.Event.Activated] = function()
				removeIngredientAtIndex(i)
			end,
		})
	end

	React.useEffect(function()
		setCurrentIngredients({})
		setPendingIngredients({}) -- Safety clear
	end, { props.Open })

	return e("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible = props.Open or false,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
	}, {
		UISizeConstraint = e("UISizeConstraint", {
			MinSize = Vector2.new(300, 200),
			MaxSize = Vector2.new(500, 500),
		}),
		e(SmallButton, {
			Text = "X",
			[React.Event.Activated] = props.OnClose,
		}),
		e(VStack, {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 0.8,
			Padding = {
				Top = UDim.new(0, 12),
				Right = UDim.new(0, 12),
				Left = UDim.new(0, 12),
				Bottom = UDim.new(0, 12),
			},
		}, {
			-- NEW: Top Level VFX Container for flying ingredients
			IngredientVFX = e(IngredientVFXContainer, {
				activeTrails = activeTrails,
				onTrailComplete = function(uniqueId, ingredientId)
					-- Clean up trail
					setActiveTrails(function(prev)
						local next = table.clone(prev)
						next[uniqueId] = nil
						return next
					end)

					-- Remove from pending
					setPendingIngredients(function(prev)
						local next = table.clone(prev)
						if next[ingredientId] and next[ingredientId] > 0 then
							next[ingredientId] -= 1
							if next[ingredientId] <= 0 then
								next[ingredientId] = nil
							end
						end
						return next
					end)

					-- Officially insert into selected ingredients
					setCurrentIngredients(function(prev)
						local next = table.clone(prev)
						table.insert(next, ingredientId)
						return next
					end)
				end,
			}),

			Left = e(HStack, {
				Size = UDim2.new(0.3, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Spacing = UDim.new(0, 0),
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				MinSize = Vector2.new(350, 300),
				BackgroundTransparency = 1,

				VerticalFlex = Enum.UIFlexAlignment.Fill,
				HorizontalFlex = Enum.UIFlexAlignment.Fill,
				LayoutOrder = 1,
			}, {
				IngredientList = e(HStack, {
					OnMount = targetRef, -- BIND REF HERE TO ACT AS TARGET POS
					VerticalFlex = Enum.UIFlexAlignment.None,
					VeticalAlignment = Enum.VerticalAlignment.Center,
					HorizontalFlex = Enum.UIFlexAlignment.None,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					AutomaticSize = Enum.AutomaticSize.None,
					LayoutOrder = 3,
				}, {
					e(VStack, {
						Size = UDim2.new(1, 0, 0, 0),
						VerticalFlex = Enum.UIFlexAlignment.None,
						VeticalAlignment = Enum.VerticalAlignment.Bottom,
						HorizontalFlex = Enum.UIFlexAlignment.None,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						AutomaticSize = Enum.AutomaticSize.Y,
						LayoutOrder = 3,
						Spacing = UDim.new(0, 2),
					}, {
						e(HStack, {
							HorizontalFlex = Enum.UIFlexAlignment.None,
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
							Size = UDim2.new(1, 0, 0, 50),
							AutomaticSize = Enum.AutomaticSize.None,
							LayoutOrder = 3,
							Spacing = UDim.new(0, 2),
						}, {
							Ingredients = e(React.Fragment, {}, {
								selectedIngredientElements[1],
								selectedIngredientElements[2],
								selectedIngredientElements[3],
							}),
						}),
						e(HStack, {
							HorizontalFlex = Enum.UIFlexAlignment.None,
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
							Size = UDim2.new(1, 0, 0, 50),
							AutomaticSize = Enum.AutomaticSize.None,
							LayoutOrder = 3,
							Spacing = UDim.new(0, 2),
						}, {
							Ingredients = e(React.Fragment, {}, {
								selectedIngredientElements[4],
								selectedIngredientElements[5],
								selectedIngredientElements[6],
							}),
						}),
						e(HStack, {
							Size = UDim2.new(1, 0, 0, 50),
							AutomaticSize = Enum.AutomaticSize.None,
							HorizontalFlex = Enum.UIFlexAlignment.None,
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
							LayoutOrder = 3,
							Spacing = UDim.new(0, 2),
						}, {
							Ingredients = e(React.Fragment, {}, {
								selectedIngredientElements[7],
								selectedIngredientElements[8],
								selectedIngredientElements[9],
							}),
						}),
					}),
				}),
				-- }),

				Controls = e(VStack, {
					Size = UDim2.new(1, 0, 1, 0),
					Spacing = UDim.new(0, 10),
					LayoutOrder = 4,
					AutomaticSize = Enum.AutomaticSize.None,
					HorizontalFlex = Enum.UIFlexAlignment.None,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					-- BackgroundTransparency = 0,
				}, {
					Controls = e(HStack, {
						Size = UDim2.new(0, 0, 0, 0),
						Spacing = UDim.new(0, 10),
						LayoutOrder = 4,
						AutomaticSize = Enum.AutomaticSize.XY,
						VerticalFlex = Enum.UIFlexAlignment.None,
						HorizontalFlex = Enum.UIFlexAlignment.None,
						-- BackgroundTransparency = 0,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
					}, {
						CraftButton = e(SmallButton, {
							Text = "Craft!",
							Size = UDim2.new(0, 80, 0, 40),
							BackgroundColor3 = resultConfig and Color3.new(0.5, 1, 0) or nil,
							[React.Event.Activated] = function()
								if resultConfig and props.MixerId then
									Remotes.MixDrink:FireServer(resultConfig.Id, props.MixerId)
									setCurrentIngredients({})
									setPendingIngredients({}) -- Safety clear
									if props.OnClose then
										props.OnClose()
									end
								end
							end,
							LayoutOrder = 2,
						}),
						ClearButton = e(SmallButton, {
							Text = "Clear",
							Size = UDim2.new(0, 60, 0, 30),
							[React.Event.Activated] = function()
								setCurrentIngredients({})
							end,
							LayoutOrder = 1,
						}),
					}),

					ResultFrame = e("Frame", {
						Size = UDim2.new(1, 0, 0, 100),
						LayoutOrder = 1,
						BackgroundTransparency = 1,
					}, {
						config = e("ImageLabel", {
							Size = UDim2.new(0, 100, 0, 100),
							Position = UDim2.new(0.5, 0, 0, 0),
							BackgroundTransparency = 1,
							AnchorPoint = Vector2.new(0.5, 0),
							Image = resultConfig and resultConfig.Image,
						}, {
							Duration = resultConfig and e(SmallText, {
								Text = string.format(
									"Duration: (%dm %ds)\nInitialStock: (%d)",
									resultConfig.Duration // 60,
									resultConfig.Duration % 60,
									resultConfig.InitialStock
								),
								Size = UDim2.new(1, 0, 0, 50),
								Position = UDim2.new(0, 0, 1, 0),
								AnchorPoint = Vector2.new(0, 0),
								LayoutOrder = 1,
							}),

							Count = e(SmallText, {
								Visible = resultConfig and true or false,
								Size = UDim2.new(0, 30, 0, 30),
								AnchorPoint = Vector2.new(0.25, 0.25),
								Text = resultConfig and `{resultConfig.InitialStock}x` or "",
								-- TextTransparency = transparency,
								BackgroundTransparency = 0,
								TextXAlignment = Enum.TextXAlignment.Center,
								BackgroundColor3 = Color3.new(1, 0, 0),
							}, {
								UICorner = e("UICorner", {
									CornerRadius = UDim.new(0, 4),
								}),
							}),
						}),
					}),
				}),
			}),
			Right = e("Frame", {
				Size = UDim2.new(1, -20, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, {
				Content = e(VStack, { Spacing = UDim.new(0, 10) }, {
					DefaultScrollFrame = e(DefaultScrollFrame, {
						LayoutOrder = 1,
						AutomaticSize = Enum.AutomaticSize.XY,
					}, {
						Grid = e(Grid, {
							Size = UDim2.new(1, 0, 0, 200),
							CellSize = UDim2.new(0, 80, 0, 80), -- cellsize mandatory or will not work
							Padding = { All = UDim.new(0, 4) },
							CellPadding = UDim2.new(0, 2, 0, 2),
							AutomaticSize = Enum.AutomaticSize.XY,
						}, ingredientElements),
					}),

					SelectionText = e(SmallText, {
						Text = "Ingredients",
						Size = UDim2.new(1, 0, 0, 30),
					}),
				}),
			}),
		}),
	})
end

return MixerPanel
