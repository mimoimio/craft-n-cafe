local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useRef = React.useRef
local useEffect = React.useEffect
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local DefaultScrollFrame = require(script.Parent.DefaultScrollFrame)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local Grid = require(Primitives.Grid)
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)

-- Point this to your new VFX setup
local IngredientVFXContainer = require(script.Parent.IngredientVFXContainer)

local BuildersIcon = require(ReplicatedStorage.Shared.Utils.BuildersIcon)
local CLOCK = BuildersIcon.clock
local STOCK = BuildersIcon["three-stacked-squares-tilted"]

local player = game.Players.LocalPlayer
local playerId: string? = player and tostring(player.UserId) or "0"
local layoutOrders = {}
for i, config in CoffeeModule.IngredientConfigs do
	layoutOrders[config.Id] = i
end

local TEST_INGREDIENTS = {
	espresso = 1,
	water = 1,
	milk = 1,
	ice = 1,
	foam = 1,
	chocolate = 1,
	teabag = 1,
	icecream = 1,
	matchapowder = 1,
	lemon = 1,
	boba = 1,
	carbonator = 1,
	cookies = 1,
	daybloom = 1,
	blinkroot = 1,
	luckyclover = 1,
	moonglow = 1,
	glowshroom = 1,
	bloodthorn = 1,
	waterberry = 1,
	fireblossom = 1,
}
local function MixerPanel(props: {
	OnClose: () -> (),
})
	local currentIngredients, setCurrentIngredients = useState({})
	local pendingIngredients, setPendingIngredients = useState({})
	local activeTrails, setActiveTrails = useState({})
	local panelOpen, setPanelOpen = useState((not player) and true or false)
	local activeMixerId, setMixerId = useState(nil)

	-- Reference to the selected ingredients UI to act as the target position
	local targetRef = React.useRef(nil)
	local ingredients, setIngredients = useState((not player) and TEST_INGREDIENTS or {})
	local discoveredDrinks, setDiscoveredDrinks = useState((not player) and { starlight = { espresso = true } } or {})

	--  listen to discoveredDrinks
	useEffect(function()
		local unsub = GlobalState:subscribe(function(newState)
			if not (newState.Ingredients and newState.DiscoveredDrinks[playerId]) then
				return
			end
			setDiscoveredDrinks(newState.DiscoveredDrinks[playerId])
		end)
		local state = GlobalState:getState()
		if state.DiscoveredDrinks and state.DiscoveredDrinks[playerId] then
			setDiscoveredDrinks(state.DiscoveredDrinks[playerId])
		end
		return unsub
	end, {})
	--  listen to ingredients
	useEffect(function()
		local unsub = GlobalState:subscribe(function(newState)
			if not (newState.Ingredients and newState.Ingredients[playerId]) then
				return
			end
			setIngredients(newState.Ingredients[playerId])
		end)
		local state = GlobalState:getState()
		if state.Ingredients and state.Ingredients[playerId] then
			setIngredients(state.Ingredients[playerId])
		end
		return unsub
	end, {})

	--  listen to activeMixerId
	useEffect(function()
		local unsub = UIState:subscribe(function(newState)
			if not newState.activeMixerId then
				return
			end
			setMixerId(newState.activeMixerId)
		end)
		local state = UIState:getState()
		local activeMixerId = state.activeMixerId
		if activeMixerId then
			setMixerId(activeMixerId)
		end
		return unsub
	end, {})

	-- listen to panel
	local panelRef = useRef(nil)
	useEffect(function()
		local unsub = UIState:subscribe(function(state: UIState.UIState)
			local isOpen = state.panel == "mixer"
			return isOpen
		end, function(isOpen)
			-- this is important, if just doing it at top, it will enable gamepadcursor everytime any under UIState changes
			if isOpen and panelRef.current then
				game:GetService("GamepadService"):EnableGamepadCursor(panelRef.current)
			else
				game:GetService("GamepadService"):DisableGamepadCursor()
			end
			setPanelOpen(isOpen)
		end)
		return unsub
	end, {})

	React.useEffect(function()
		setCurrentIngredients({})
		setPendingIngredients({}) -- Safety clear
	end, { panelOpen })
	React.useEffect(function()
		return function()
			-- Clean up refs when the MixerPanel is destroyed/unmounted
			UIState.setEspressoButton(nil)
			UIState.setMilkButton(nil)
			UIState.setCraftButton(nil)
		end
	end, {})

	React.useEffect(function()
		if not currentIngredients then
			return
		end
		local hasEspresso = table.find(currentIngredients, "espresso") ~= nil
		local hasMilk = table.find(currentIngredients, "milk") ~= nil

		UIState.setIsEspressoInserted(hasEspresso)
		UIState.setIsMilkInserted(hasMilk) -- ADD THIS
	end, { currentIngredients })

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

	local ingredientElements = {}
	for id, amount in ingredients do
		local config = CoffeeModule.IngredientLookup[id]
		local totalAvailable = ingredients[id] or 0
		local amountUsed = usedIngredients[id] or 0
		local amountLeft = totalAvailable - amountUsed

		local transparency = amountLeft <= 0 and 0.4 or 0

		ingredientElements[id] = e(SmallButton, {
			OverlayText = config.DisplayName,
			OnMount = function(rbx)
				if id == "espresso" then
					UIState.setEspressoButton(rbx)
				elseif id == "milk" then
					UIState.setMilkButton(rbx)
				end
			end,
			OverlayTextSize = 10,
			OverlayTextWrapped = true,
			ButtonClass = "ImageButton",
			Image = config.Image,
			OverlayTextTransparency = transparency,
			BackgroundTransparency = transparency,
			LayoutOrder = layoutOrders[id],
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

					local isFull
					-- 1. Add to pending so UI immediately deducts
					setPendingIngredients(function(prev)
						local pendingAmount = 0
						for i, amt in prev do
							pendingAmount += 1
						end
						if #currentIngredients >= 6 or #currentIngredients + pendingAmount >= 6 then
							isFull = true
							return prev
						end
						local next = table.clone(prev)
						next[id] = (next[id] or 0) + 1
						return next
					end)

					if isFull then
						return
					end

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
	for i = 1, 6 do
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

	local min = resultConfig and resultConfig.Duration // 60 or nil
	local sec = resultConfig and resultConfig.Duration % 60 or nil
	local stocks = resultConfig and resultConfig.InitialStock
	local durationText = resultConfig
			and `<font size="14">$$$</font><font size="18">: {resultConfig.Price} $\n{CLOCK}: {min > 0 and `{min} min ` or ""}{sec} sec </font>\n<font size="18">{STOCK}: {stocks}x</font>`
		or ""

	-- new until discovered
	-- when in studio edit, always discovered
	local new = player and true or false
	for variationId, drinksOfVariation in discoveredDrinks do
		if not new then
			break
		end
		if drinksOfVariation[resultConfig and resultConfig.Id] then
			new = false
			break
		end
	end
	local resultLabelText = resultConfig and (not new and resultConfig.DisplayName or "???") or ""

	return e("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible = panelOpen or false,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Image = "rbxassetid://127657596958436",
		ImageTransparency = 0.6,
		ImageColor3 = Color3.new(0.768627, 0.549019, 0.549019),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(8, 8, 92, 92),
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
			BackgroundTransparency = 1,
			OnMount = panelRef,
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
					Spacing = UDim.new(0, 2),
					LayoutOrder = 4,
					AutomaticSize = Enum.AutomaticSize.None,
					HorizontalFlex = Enum.UIFlexAlignment.None,
					VerticalFlex = Enum.UIFlexAlignment.SpaceBetween,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = { All = UDim.new() },
					-- BackgroundTransparency = 0,
				}, {
					Controls = e(HStack, {
						Size = UDim2.new(0, 0, 0, 0),
						Spacing = UDim.new(0, 8),
						LayoutOrder = 4,
						AutomaticSize = Enum.AutomaticSize.XY,
						VerticalFlex = Enum.UIFlexAlignment.None,
						HorizontalFlex = Enum.UIFlexAlignment.None,
						BackgroundTransparency = 1,
						Padding = { All = UDim.new() },
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Bottom,
					}, {
						CraftButton = e(SmallButton, {
							Text = "Craft!",
							Size = UDim2.new(0, 60, 0, 30),
							BackgroundColor3 = resultConfig and Color3.new(0.5, 1, 0) or nil,
							[React.Event.Activated] = function()
								if resultConfig and activeMixerId then
									Remotes.MixDrink:FireServer(resultConfig.Id, activeMixerId)
									setCurrentIngredients({})
									setPendingIngredients({}) -- Safety clear
									if props.OnClose then
										props.OnClose()
									end
								end
							end,
							TextTransparency = resultConfig and 0 or 0.8,
							TextThickness = resultConfig and 1 or 0.6,
							LayoutOrder = 2,
							OnMount = UIState.setCraftButton,
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

					ResultFrame = e("ImageLabel", {
						Size = UDim2.new(1, 0, 0, 100),
						LayoutOrder = 1,
						BackgroundTransparency = 1,
					}, {
						ResultImageFrame = e("Frame", {
							Size = UDim2.new(0, 100, 0, 100),
							Position = UDim2.new(0.5, 0, 0, 0),
							BackgroundTransparency = 1,
							AnchorPoint = Vector2.new(0.5, 0),
						}, {
							Background = e("ImageLabel", {
								Size = UDim2.new(0, 100, 0, 100),
								Position = UDim2.new(0.5, 0, 0, 0),
								BackgroundTransparency = 1,
								AnchorPoint = Vector2.new(0.5, 0),
								Image = "rbxassetid://127657596958436",
								ImageColor3 = Color3.new(0.768627, 0.549019, 0.549019),
								ScaleType = Enum.ScaleType.Slice,
								SliceCenter = Rect.new(8, 8, 92, 92),
								ZIndex = 1,
							}, {}),
							ResultLabel = resultConfig and e(SmallText, {
								Text = resultLabelText,
								Size = UDim2.new(1, 0, 0, 0),
								TextSize = 16,
								Position = UDim2.new(0.5, 0, 1, -8),
								AnchorPoint = Vector2.new(0.5, 1),
								RichText = true,
								TextXAlignment = Enum.TextXAlignment.Center,
								ZIndex = 8,
							}),
							Duration = resultConfig and e(SmallText, {
								Text = durationText,
								MinTextSize = 14,
								-- MaxTextSize = 32,
								TextSize = 18,
								Size = UDim2.new(1, 0, 0, 0),
								Position = UDim2.new(0.5, 0, 1, 0),
								AnchorPoint = Vector2.new(0.5, 0),
								RichText = true,
								TextXAlignment = Enum.TextXAlignment.Left,
								ZIndex = 2,
							}),
							ResultImage = e("ImageLabel", {
								Size = UDim2.new(0, 100, 0, 100),
								Position = UDim2.new(0.5, 0, 0, 0),
								BackgroundTransparency = 1,
								AnchorPoint = Vector2.new(0.5, 0),
								Image = resultConfig and resultConfig.Image,
								ZIndex = 3,
							}, {}),

							-- Count = e(SmallText, {
							-- 	Visible = resultConfig and true or false,
							-- 	Size = UDim2.new(0, 30, 0, 30),
							-- 	AnchorPoint = Vector2.new(0.25, 0.25),
							-- 	Text = `Price: ${resultConfig and resultConfig.Price} `,
							-- 	-- TextTransparency = transparency,
							-- 	BackgroundTransparency = 1,
							-- 	TextXAlignment = Enum.TextXAlignment.Center,
							-- 	-- BackgroundColor3 = Color3.new(1, 0, 0),
							-- 	ZIndex = 4,
							-- }, {
							-- 	UICorner = e("UICorner", {
							-- 		CornerRadius = UDim.new(0, 4),
							-- 	}),
							-- }),
							New = new and e(SmallText, {
								Visible = resultConfig and true or false,
								Size = UDim2.new(0, 30, 0, 30),
								AnchorPoint = Vector2.new(0.75, 0.25),
								Text = "NEW!",
								Position = UDim2.new(1, 0, 0, 0),
								TextXAlignment = Enum.TextXAlignment.Center,
								-- BackgroundColor3 = Color3.new(0.152941, 0.788235, 0.184313),
								TextColor3 = Color3.new(0.152941, 0.788235, 0.184313),
								TextStrokeColor3 = Color3.new(1, 1, 1),
								ZIndex = 5,
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
