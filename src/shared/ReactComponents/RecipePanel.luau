local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local useSpring = ReactFlow.useSpring
local CoffeeConfigArray = require(ReplicatedStorage.Shared.Configs.CoffeeConfig)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
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
local PANEL_BG = Color3.fromRGB(35, 35, 42)
local ITEM_BG = Color3.fromRGB(45, 45, 55)
local ITEM_SELECTED_BG = Color3.fromRGB(80, 60, 40)
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

	local bg = if props.isSelected then ITEM_SELECTED_BG elseif hovered then Color3.fromRGB(60, 60, 75) else ITEM_BG

	return e("TextButton", {
		Size = UDim2.new(0, 90, 0, 110),
		BackgroundColor3 = bg,
		BorderSizePixel = 0,
		Text = "",
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
			PaddingBottom = UDim.new(0, 6),
		}),
		Image = e("ImageLabel", {
			Size = UDim2.new(1, 0, 0, 70),
			BackgroundColor3 = Color3.fromRGB(30, 30, 38),
			BorderSizePixel = 0,
			Image = props.config.Image or "",
			ScaleType = Enum.ScaleType.Fit,
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
		}),
		Label = e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 28),
			Position = UDim2.new(0, 0, 1, -28),
			BackgroundTransparency = 1,
			Text = props.config.DisplayName,
			TextColor3 = if props.isSelected then ACCENT else TEXT,
			TextSize = 11,
			Font = Enum.Font.FredokaOne,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextWrapped = true,
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

local function RecipeDetail(props: { config: any, onNext: () -> (), onPrev: () -> () })
	local config = props.config

	-- Build ingredient display names
	local ingredientNames = {}
	for i, id in ipairs(config.RecipePath or {}) do
		local ing = CoffeeConfig[id]
		ingredientNames[i] = ing and ing.DisplayName or id
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
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			UIPadding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 16),
				PaddingTop = UDim.new(0, 16),
			}),
			Title = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundTransparency = 1,
				Text = config.DisplayName,
				TextColor3 = ACCENT,
				TextSize = 22,
				TextStrokeTransparency = 0,
				Font = Enum.Font.SpecialElite,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 1,
			}),
			InstructionLabel = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
				Text = config.Instruction and "How to make:" or "",
				TextColor3 = SUBTEXT,
				TextSize = 13,
				Font = Enum.Font.FredokaOne,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 2,
			}),
			ItemTip = config.ItemTip and e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Text = config.ItemTip,
				TextColor3 = SUBTEXT,
				TextSize = 14,
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
				PrevButton = e("TextButton", {
					Size = UDim2.new(0, 70, 0, 70),
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
					Size = UDim2.new(0, 70, 0, 70),
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
	visible: boolean,
	onClose: () -> (),
})
	local selected, setSelected = useState(RECIPES[1])
	local clonedModelRef = useRef(nil)
	local detailPanelRef = useRef(nil) -- Add this new reference

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
		if props.visible then
			setPosition({
				target = 0,
				speed = 10,
				damper = 1,
			})
		else
			setPosition({
				target = -1,
				speed = 10,
				damper = 1,
			})
		end
	end, { props.visible })

	-- Camera control effect
	-- useEffect(function()
	-- 	if not props.visible then
	-- 		return
	-- 	end

	-- 	local camera = workspace.CurrentCamera
	-- 	local initialCFrame = camera.CFrame
	-- 	local cameraPart = workspace:FindFirstChild("cameraPart")

	-- 	camera.CameraType = Enum.CameraType.Scriptable

	-- 	if cameraPart then
	-- 		camera.CFrame = cameraPart:GetPivot()
	-- 		-- local cf, s = workspace.zoomtoextent:GetBoundingBox()
	-- 		-- if cf then
	-- 		-- 	camera:ZoomToExtents(cf, s)
	-- 		-- end
	-- 	end

	-- 	return function()
	-- 		camera.CFrame = initialCFrame
	-- 		-- camera.CameraType = Enum.CameraType.Custom
	-- 	end
	-- end, { props.visible })

	-- -- Model preview effect
	-- useEffect(function()
	-- 	if not props.visible or not selected then
	-- 		return
	-- 	end

	-- 	-- Clean up previous model
	-- 	if clonedModelRef.current then
	-- 		clonedModelRef.current:Destroy()
	-- 		clonedModelRef.current = nil
	-- 	end

	-- 	local model = ReplicatedStorage.Shared.Models:FindFirstChild(selected.Id)
	-- 	local cupPart = workspace:FindFirstChild("cupPart")

	-- 	if model and cupPart then
	-- 		local clone = model:Clone()
	-- 		clone.Parent = workspace
	-- 		clone:PivotTo(cupPart:GetPivot())
	-- 		-- local
	-- 		clonedModelRef.current = clone
	-- 	end

	-- 	return function()
	-- 		if clonedModelRef.current then
	-- 			clonedModelRef.current:Destroy()
	-- 			clonedModelRef.current = nil
	-- 		end
	-- 	end
	-- end, { props.visible, selected })

	local gridItems = {
		UIGridLayout = e("UIGridLayout", {
			CellSize = UDim2.new(0, 90, 0, 110),
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
	for i, config in ipairs(RECIPES) do
		gridItems["item_" .. config.Id] = e(RecipeGridItem, {
			config = config,
			isSelected = selected and selected.Id == config.Id,
			onSelect = function()
				setSelected(config)
			end,
			layoutOrder = i,
		})
	end

	return e("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		Position = position:map(function(n)
			return UDim2.new(n, 0, 0, 0)
		end),
		BorderSizePixel = 0,
		ZIndex = 20,
	}, {
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
					Text = "Recipe Book",
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
					Text = "Close",
					TextColor3 = Color3.fromRGB(255, 120, 120),
					TextSize = 16,
					Font = Enum.Font.FredokaOne,
					[React.Event.MouseButton1Click] = props.onClose,
				}, {
					UICorner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
				}),
			}),

			-- Body
			Body = e("Frame", {
				Size = UDim2.new(1, 0, 1, -48),
				Position = UDim2.new(0, 0, 0, 48),
				BackgroundTransparency = 1,
			}, {
				-- Left grid
				GridPanel = e("Frame", {
					Size = UDim2.new(0, 320, 1, 0),
					BackgroundColor3 = PANEL_BG,
					BorderSizePixel = 0,
					BackgroundTransparency = 1,
				}, {
					UICorner = e("UICorner", { CornerRadius = UDim.new(0, 10) }),
					-- Top fill for flat top
					TopFill = e("Frame", {
						Size = UDim2.new(1, 0, 0, 10),
						BackgroundColor3 = PANEL_BG,
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
					}),
					ScrollFrame = e("ScrollingFrame", {
						Size = UDim2.new(1, -8, 1, -12),
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
				DetailPanel = e("Frame", {
					Size = UDim2.new(1, -328, 1, -8),
					Position = UDim2.new(0, 328, 0, 4),
					BackgroundTransparency = 1,
				}, {
					if selected
						then e(RecipeDetail, {
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
