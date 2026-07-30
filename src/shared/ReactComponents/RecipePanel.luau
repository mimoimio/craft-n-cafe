local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local useSpring = ReactFlow.useSpring
local CoffeeConfigArray = require(ReplicatedStorage.Shared.Configs.CoffeeConfig)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local HStack = require(ReplicatedStorage.Shared.ReactComponents.ui.HStack)
local VStack = require(ReplicatedStorage.Shared.ReactComponents.ui.VStack)
local SmallButton = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallButton)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local player = game.Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""
-- CoffeeModule.Config is the keyed lookup (by Id)
local CoffeeConfig = CoffeeModule.Config

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef

-- Build sorted list of craftable recipes (those with Ingredients)
local function getSortedRecipes()
	local list = {}
	for _, config in ipairs(CoffeeConfigArray) do
		if config.Ingredients then
			table.insert(list, config)
		end
	end
	table.sort(list, function(a, b)
		return a.DisplayName < b.DisplayName
	end)
	return list
end

-- local RECIPES = getSortedRecipes()
local RECIPES = CoffeeModule.Array

local BG = Color3.fromRGB(25, 25, 30)
local PANEL_BG = Color3.fromRGB(37, 37, 88)
local ITEM_BG = Color3.fromRGB(255, 201, 150)
local ITEM_SELECTED_BG = Color3.fromRGB(255, 252, 208)
local ITEM_BG_LOCKED = Color3.fromRGB(148, 56, 33)
local ITEM_BG_LOCKED_SELECTED = Color3.fromRGB(122, 87, 40)
local ACCENT = Color3.fromRGB(255, 200, 80)
local TEXT = Color3.fromRGB(230, 230, 230)
local SUBTEXT = Color3.fromRGB(160, 160, 180)

local function RecipeGridItem(props: {
	config: any,
	isSelected: boolean,
	onSelect: () -> (),
	layoutOrder: number,
})
	local hovered, setHovered = useState(false)
	local locked = not props.discovered

	local bg = if props.isSelected
		then (if locked then ITEM_BG_LOCKED_SELECTED else ITEM_SELECTED_BG)
		elseif hovered then (if locked then Color3.new(0.5, 0.5, 0.5) else Color3.new(1, 0.956862, 0.901960))
		else (if locked then ITEM_BG_LOCKED else ITEM_BG)
	return e("ImageButton", {
		Size = UDim2.new(0, 90, 0, 110),
		BackgroundColor3 = bg,
		BorderSizePixel = 0,
		Image = "rbxassetid://103478691850846",
		AutoButtonColor = true,
		-- Text = "",
		ImageColor3 = bg,
		LayoutOrder = props.layoutOrder,
		[React.Event.MouseEnter] = function()
			setHovered(true)
		end,
		[React.Event.MouseLeave] = function()
			setHovered(false)
		end,
		[React.Event.MouseButton1Click] = props.onSelect,
	}, {
		UICorner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
		UIPadding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 12),
		}),
		Image = e("ImageLabel", {
			Size = UDim2.new(0, 70, 0, 70),
			BackgroundColor3 = Color3.fromRGB(30, 30, 38),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = props.config.Image or "",
			ImageColor3 = bg,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 10,
			Position = UDim2.new(0.5, 0, 0, 0),
			AnchorPoint = Vector2.new(0.5, 0),
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
			-- UIStroke = e("UIStroke", {
			-- 	Color = bg,
			-- 	Thickness = 4,
			-- }),
		}),
		-- Flare = e("ImageLabel", {
		-- 	Size = UDim2.new(0, 70, 0, 70),
		-- 	-- Size = UDim2.new(1, 0, 0, 70),
		-- 	BackgroundColor3 = Color3.fromRGB(30, 30, 38),
		-- 	BackgroundTransparency = 1,
		-- 	BorderSizePixel = 0,
		-- 	Position = UDim2.new(0.5, 0, 0, 0),
		-- 	AnchorPoint = Vector2.new(0.5, 0),
		-- 	Image = "rbxassetid://126550182137995",
		-- 	ScaleType = Enum.ScaleType.Fit,
		-- 	ZIndex = 5,
		-- 	ImageColor3 = bg,
		-- }, {
		-- 	UICorner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
		-- }),
		Label = e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 28),
			Position = UDim2.new(0, 0, 1, -28),
			BackgroundTransparency = 1,
			Text = locked and "???" or props.config.DisplayName,
			TextColor3 = if props.isSelected then ACCENT else TEXT,
			TextSize = 12,
			TextStrokeTransparency = 0,
			Font = Enum.Font.FredokaOne,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextWrapped = true,
		}, {
			UITextSizeConstraint = e("UITextSizeConstraint", {
				MinTextSize = 11,
				MaxTextSize = 12,
			}),
		}),
	})
end

local function IngredientChip(props: { name: string, layoutOrder: number })
	return e("Frame", {
		Size = UDim2.new(0, 0, 0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = props.type and 1 or 0,
		BackgroundColor3 = Color3.fromRGB(55, 55, 68),
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
	}, {
		UICorner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
		UIPadding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}),
		Label = e("TextLabel", {
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Text = props.name,
			TextColor3 = SUBTEXT,
			TextSize = 13,
			Font = Enum.Font.FredokaOne,
		}),
	})
end

local function RecipeDetail(props: {
	config: any,
	onNext: () -> (),
	onPrev: () -> (),
	locked: boolean,
})
	local config = props.config

	-- Build ingredient display names
	local ingredientNames = {}
	for i, id in ipairs(config.RecipePath or {}) do
		local ing = CoffeeConfig[id]
		ingredientNames[i] = props.locked and "???" or (ing and ing.DisplayName or id)
	end

	local chips = {

		UIListLayout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			Wraps = true,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	for i, name in ipairs(ingredientNames) do
		chips["chip_" .. i * 2] = e(IngredientChip, { name = name, layoutOrder = i * 2 })
		chips["chip_" .. (i * 2 + 1)] = (i < #(ingredientNames or {}))
			and e(IngredientChip, { name = "->", layoutOrder = i * 2 + 1, type = "arrow" })
	end

	return e("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
	}, {
		SurfaceGui = e("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			-- PixelsPerStud = 45,
			-- Face = "Right",
			-- SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
			-- Adornee = workspace:FindFirstChild("detailsurface") or nil,
			-- Brightness = 2,
			-- LightInfluence = 0,
		}, {
			UIListLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, 2),
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalFlex = Enum.UIFlexAlignment.Fill,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),
			UIPadding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 16),
				PaddingTop = UDim.new(0, 16),
			}),
			Title = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundTransparency = 1,
				Text = props.locked and "???" or config.DisplayName,
				TextColor3 = ACCENT,
				TextSize = 22,
				TextStrokeTransparency = 0,
				Font = Enum.Font.SpecialElite,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 1,
			}),
			Flare = e("ImageLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundColor3 = Color3.fromRGB(30, 30, 38),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Image = "rbxassetid://126550182137995",
				ImageColor3 = props.locked and Color3.new(0.5, 0.5, 0.5) or Color3.new(1, 1, 1),
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 10,
				Position = UDim2.new(0.5, 0, 0, 0),
				AnchorPoint = Vector2.new(0.5, 0),
				LayoutOrder = 2,
			}, {
				UICorner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),

				UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
					AspectRatio = 1,
				}),
				UISizeConstraint = e("UISizeConstraint", {
					MaxSize = Vector2.new(100, 100),
				}),
				Image = e("ImageLabel", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Image = props.config.Image or "",
					ImageColor3 = props.locked and Color3.new(0.5, 0.5, 0.5) or nil,
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 10,
					Position = UDim2.new(0.5, 0, 0, 0),
					AnchorPoint = Vector2.new(0.5, 0),
					LayoutOrder = 2,
				}, {}),
				PrevButton = e("TextButton", {
					Size = UDim2.new(0, 50, 0, 50),
					Position = UDim2.new(0, 0, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Color3.fromRGB(50, 50, 65),
					BorderSizePixel = 0,
					Text = "<",
					TextColor3 = TEXT,
					TextSize = 24,
					Font = Enum.Font.FredokaOne,
					LayoutOrder = 1,
					[React.Event.Activated] = props.onPrev,
				}, {
					UICorner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
				}),
				NextButton = e("TextButton", {
					Size = UDim2.new(0, 50, 0, 50),
					Position = UDim2.new(1, 0, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Color3.fromRGB(50, 50, 65),
					BorderSizePixel = 0,
					Text = ">",
					TextColor3 = TEXT,
					TextSize = 24,
					Font = Enum.Font.FredokaOne,
					LayoutOrder = 2,
					[React.Event.Activated] = props.onNext,
				}, {
					UICorner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
				}),
			}),

			InstructionLabel = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
				Text = config.Instruction and "How to make:" or "",
				TextColor3 = SUBTEXT,
				TextSize = 13,
				Font = Enum.Font.FredokaOne,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 3,
			}),
			ItemTip = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				-- Text = props.locked and "" or config.ItemTip,
				Text = `{config.ItemTip or ""}\nPrice: {config.Price}\nMixing Duration: {config.Duration}`,
				TextColor3 = SUBTEXT,
				TextSize = 14,
				TextStrokeTransparency = 0,
				Font = Enum.Font.FredokaOne,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				LayoutOrder = 4,
			}) or nil,
			Divider = e("Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = Color3.fromRGB(60, 60, 75),
				BorderSizePixel = 0,
				LayoutOrder = 5,
			}),
			Controls = e("Frame", {
				Size = UDim2.new(1, 0, 0, 50),
				BackgroundTransparency = 1,
				LayoutOrder = 6,
			}, {
				UIListLayout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					Padding = UDim.new(0, 10),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			}),
			Chips = e("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 3,
			}, chips),
		}),
	})
end

local function RecipePanel(props: {
	onClose: () -> (),
})
	local selected, setSelected = useState(RECIPES[1])
	local visible, setVisible = useState(false)
	local variationId, setVariationId = useState("none")
	local discoveredDrinks, setDiscoveredDrinks = useState(not player and { none = { espresso = true } } or nil)
	local drinksOfVariation: { [string]: true } = discoveredDrinks and discoveredDrinks[variationId] or {}

	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.DiscoveredDrinks[playerId]
		end, function(dd)
			setDiscoveredDrinks(dd)
		end)

		local state = GlobalState:getState()
		local dd = state.DiscoveredDrinks[playerId]
		if dd then
			setDiscoveredDrinks(dd or {})
		end
		return unsub
	end, {})
	-- listen to panel
	useEffect(function()
		local unsub = UIState:subscribe(function(state: UIState.UIState)
			setVisible(state.panel == "recipe")
		end)
		local panel = UIState:getState().panel
		if panel then
			setVisible(panel == "recipe")
		end
		return unsub
	end, {})
	local function navigateRecipe(direction: number)
		local currentIndex = 1
		for i, recipe in ipairs(RECIPES) do
			if selected and recipe.Id == selected.Id then
				currentIndex = i
				break
			end
		end

		local newIndex = currentIndex + direction
		if newIndex > #RECIPES then
			newIndex = 1
		elseif newIndex < 1 then
			newIndex = #RECIPES
		end

		setSelected(RECIPES[newIndex])
	end

	local position, setPosition = useSpring({
		start = -1,
		target = -1,
		speed = 1,
		damper = 1,
	})
	useEffect(function()
		if visible then
			setPosition({
				target = 0,
				speed = 30,
				damper = 0.6,
			})
		else
			setPosition({
				target = -1,
				speed = 30,
				damper = 0.6,
			})
		end
	end, { visible })

	local gridItems = {
		UIGridLayout = e("UIGridLayout", {
			CellSize = UDim2.new(0, 70, 0, 120),
			CellPadding = UDim2.new(0, 8, 0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		UIPadding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		}),
	}
	local count = 0
	for drinkId, _ in drinksOfVariation do
		count += 1
	end
	local varCount = 5
	local total = varCount * #RECIPES
	local locked = player and not (drinksOfVariation and drinksOfVariation[selected and selected.Id]) or false

	for i, config in ipairs(RECIPES) do
		gridItems["item_" .. config.Id] = e(RecipeGridItem, {
			config = config,
			isSelected = selected and selected.Id == config.Id,
			onSelect = function()
				setSelected(config)
			end,
			layoutOrder = i,
			discovered = (not player) or drinksOfVariation and drinksOfVariation[config.Id] or false,
		})
	end

	local bg = (if locked then ITEM_BG_LOCKED else Color3.new(0.980392, 0.341176, 0.145098))

	local buttons = {}
	for variationId, variation in VariationsConfig do
		buttons[variationId] = e(SmallButton, {
			LayoutOrder = variation.Multiplier,
			OverlayText = variation.DisplayName,
			BackgroundColor3 = variationId ~= "none" and variation.ColorPrimary
				or Color3.new(0.768627, 0.549019, 0.549019),
			Image = variation.Image,
			[React.Event.Activated] = function()
				setVariationId(variationId)
			end,
		})
	end
	local variation = VariationsConfig[variationId]

	return e("ImageLabel", {
		Size = UDim2.new(0.8, -48, 1, -48),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position:map(function(n)
			return UDim2.new(0.5 + n, 0, 0.5 + 0, 0)
		end),
		ZIndex = 20,

		BackgroundColor3 = PANEL_BG,
		BackgroundTransparency = 1,
		Image = "rbxassetid://127657596958436",
		ImageColor3 = variation and variation.VariationId ~= "none" and variation.ColorPrimary
			or Color3.new(0.768627, 0.549019, 0.549019),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(8, 8, 92, 92),
		BorderSizePixel = 0,
	}, {
		UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
			AspectRatio = 1.5,
		}),
		UISizeConstraint = e("UISizeConstraint", {
			MaxSize = Vector2.new(1000, 1000),
		}),
		buttons = e(VStack, {
			AutomaticSize = Enum.AutomaticSize.XY,
			AnchorPoint = Vector2.new(1, 0),
			Spacing = UDim.new(0, 8),
			Size = UDim2.new(0, 80, 0, 0),
		}, buttons),
		-- Centered container
		Container = e("Frame", {
			Size = UDim2.new(1, -20, 1, -20),
			-- Size = UDim2.new(0, 720, 0, 440),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundColor3 = BG,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0, 12) }),

			-- Header
			Header = e("Frame", {
				Size = UDim2.new(1, 0, 0, 48),
				BackgroundColor3 = PANEL_BG,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 2,
			}, {
				UICorner = e("UICorner", { CornerRadius = UDim.new(0, 12) }),
				-- Bottom fill to hide bottom corner rounding
				BottomFill = e("Frame", {
					Size = UDim2.new(1, 0, 0, 12),
					Position = UDim2.new(0, 0, 1, -12),
					BackgroundColor3 = PANEL_BG,
					BorderSizePixel = 0,
					BackgroundTransparency = 1,
				}),
				Title = e("TextLabel", {
					Size = UDim2.new(1, -56, 1, 0),
					Position = UDim2.new(0, 16, 0, 0),
					BackgroundTransparency = 1,
					Text = `Recipe Mastery Book ({count}/{#RECIPES})`,
					TextColor3 = ACCENT,
					TextSize = 20,
					Font = Enum.Font.FredokaOne,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				CloseBtn = e("TextButton", {
					Size = UDim2.new(0, 32, 0, 32),
					Position = UDim2.new(1, -40, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Color3.fromRGB(80, 40, 40),
					BorderSizePixel = 0,
					Text = "X",
					TextColor3 = Color3.fromRGB(255, 120, 120),
					TextSize = 16,
					Font = Enum.Font.FredokaOne,
					[React.Event.MouseButton1Click] = props.OnClose,
				}, {
					UICorner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
				}),
			}),

			-- Body
			Body = e(HStack, {
				Size = UDim2.new(1, 0, 1, -48),
				Position = UDim2.new(0, 0, 0, 48),
				BackgroundTransparency = 1,
			}, {
				-- Left grid
				GridPanel = e("ImageLabel", {
					Size = UDim2.new(0.5, 0, 1, 0),
					-- Size = UDim2.new(1, 0, 1, 0),
					BackgroundColor3 = PANEL_BG,
					BackgroundTransparency = 1,
					-- Image = "rbxassetid://127657596958436",
					-- ImageColor3 = Color3.new(0.768627, 0.549019, 0.549019),
					-- ImageColor3 = PANEL_BG,
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(8, 8, 92, 92),
					BorderSizePixel = 0,
				}, {
					-- UICorner = e("UICorner", { CornerRadius = UDim.new(0, 10) }),
					-- Top fill for flat top
					TopFill = e("Frame", {
						Size = UDim2.new(1, 0, 0, 10),
						BackgroundColor3 = PANEL_BG,
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
					}),
					ScrollFrame = e("ScrollingFrame", {
						Size = UDim2.new(1, -8, 1, -8),
						Position = UDim2.new(0, 4, 0, 8),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						ScrollBarThickness = 4,
						ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100),
						CanvasSize = UDim2.new(0, 0, 0, 0),
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
					}, gridItems),
				}),

				-- Right detail
				DetailPanel = e("ImageLabel", {
					Size = UDim2.new(0.5, 0, 1, 0),
					Position = UDim2.new(0, 328, 0, 0),
					BackgroundTransparency = 1,

					BackgroundColor3 = PANEL_BG,
					Image = "rbxassetid://127657596958436",
					ImageColor3 = bg, --Color3.new(0.505882, 0.254901, 0.254901),
					-- ImageColor3 = PANEL_BG,
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(8, 8, 92, 92),
					BorderSizePixel = 0,
				}, {
					if selected
						then e(RecipeDetail, {
							locked = locked,
							config = selected,
							onNext = function()
								navigateRecipe(1)
							end,
							onPrev = function()
								navigateRecipe(-1)
							end,
						})
						else nil,
				}),
			}),
		}),
	})
end

return RecipePanel
