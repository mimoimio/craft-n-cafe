-- Shared/ReactComponents/IngredientShopPanel.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useBinding = React.useBinding
local useRef = React.useRef
local useEffect = React.useEffect
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local DefaultPanel = require(script.Parent.DefaultPanel)
local DefaultScrollFrame = require(script.Parent.DefaultScrollFrame)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)

local player = game.Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""
local function IngredientShopPanel(props: {})
	local shopItems = {}
	local selected, setSelected = useBinding(nil)
	local discoveredDrinks, setDiscoveredDrinks = useState((not player) and {})
	local activeDrinks, setActiveDrinks = useState({})
	local t, setT = useBinding(tick())

	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.DiscoveredDrinks[playerId]
		end, function(dd)
			setDiscoveredDrinks(dd)
		end)
		local state = GlobalState:getState()
		local dd = state.DiscoveredDrinks[playerId]
		setDiscoveredDrinks(dd or {})
		if not player then
			task.delay(1, function()
				setDiscoveredDrinks(function(prev)
					local clone = table.clone(prev)
					clone.americano = true
					clone.icedamericano = true
					return clone
				end)
				task.delay(1, function()
					setDiscoveredDrinks(function(prev)
						local clone = table.clone(prev)
						clone.latte = true
						clone.icedlatte = true
						return clone
					end)
				end)
			end)
		end

		local timer = task.spawn(function()
			while task.wait() do
				setT(tick())
			end
		end)
		return function()
			unsub()
			task.cancel(timer)
		end
	end, {})

	local prevDrinkRef = useRef(nil)
	useEffect(function()
		if not discoveredDrinks then
			return
		end
		if not prevDrinkRef.current then
			prevDrinkRef.current = discoveredDrinks
			return
		end
		for drinkId, _ in discoveredDrinks do
			if prevDrinkRef.current[drinkId] then
				continue
			end
			prevDrinkRef.current[drinkId] = true
			local id = (tick())
			setActiveDrinks(function(prev)
				local clone = table.clone(prev)
				table.insert(clone, {
					id = tostring(id),
					drinkId = drinkId,
					StartTime = id,
				})
				return { {
					id = tostring(id),
					drinkId = drinkId,
					StartTime = id,
				} }
			end)
		end
		return
	end, { discoveredDrinks })

	local children = {}
	for i, drink in activeDrinks do
		local config = CoffeeModule.Config[drink.drinkId]

		children[drink.id] = e("ImageButton", {
			AutomaticSize = Enum.AutomaticSize.None,
			[React.Event.Activated] = function()
				task.spawn(function()
					setActiveDrinks(function(prev)
						local clone = table.clone(prev)
						index = i
						for i, activeDrink in clone do
							if activeDrink.id ~= drink.id then
								continue
							end
							index = i
						end
						if not index then
							return prev
						end
						table.remove(clone, index)
						return clone
					end)
					if true then
						return -- just remove immediately
					end
					if drink.EndTime then
						return
					end
					setActiveDrinks(function(prev)
						local clone = table.clone(prev)
						index = i
						for i, activeDrink in clone do
							warn("son")
							if activeDrink.id ~= drink.id then
								continue
							end
							index = i
						end
						if not index then
							return prev
						end
						clone[index].EndTime = tick()
						return clone
					end)
					task.wait(1)
					setActiveDrinks(function(prev)
						local clone = table.clone(prev)
						index = i
						for i, activeDrink in clone do
							if activeDrink.id ~= drink.id then
								continue
							end
							index = i
						end
						if not index then
							return prev
						end
						table.remove(clone, index)
						return clone
					end)
				end)
			end,
			Image = config.Image,
			LayoutOrder = i,
			BackgroundTransparency = 0.9,
			Size = t:map(function(n)
				local start = math.min(1, (n - drink.StartTime))
				local End = drink.EndTime and math.min(1, (drink.EndTime - n + 1))
				return drink.EndTime and UDim2.new(0, End * 200, 0, End * 200)
					or UDim2.new(0, start * 200, 0, start * 200)
			end),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			-- ImageColor3 = Color3.new(1, 0, 0),
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
			e("ImageLabel", {
				Image = "rbxassetid://12386383371",

				Size = t:map(function(n)
					-- local start = (n - drink.StartTime)
					-- local End = drink.EndTime and math.min(1, (drink.EndTime - n + 1))
					-- return drink.EndTime and UDim2.new(0, End * 400, 0, End * 400)
					-- 	or UDim2.new(0, start * 400, 0, start * 400)
					local s = math.max(0, math.tan(5 / 4 * n + 1))
					return UDim2.new(0, s * 400, 0, s * 400)
				end),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Active = false,
				BackgroundTransparency = 1,
				Rotation = t:map(function(n)
					return (n * 90) % 360
				end),
				ImageTransparency = t:map(function(n)
					return math.cos(5 * n + 1)
				end),
			}),
			e("ImageLabel", {
				Image = "rbxassetid://12386383371",

				Size = t:map(function(n)
					-- local start = (n - drink.StartTime)
					-- local End = drink.EndTime and math.min(1, (drink.EndTime - n + 1))
					-- return drink.EndTime and UDim2.new(0, End * 400, 0, End * 400)
					-- 	or UDim2.new(0, start * 400, 0, start * 400)
					local s = math.max(0, math.tan(5 / 4 * n + 1 + math.pi / 4))
					return UDim2.new(0, s * 400, 0, s * 400)
				end),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Active = false,
				BackgroundTransparency = 1,
				Rotation = t:map(function(n)
					return (n * 90) % 360
				end),
				ImageTransparency = t:map(function(n)
					return math.cos(5 * n + 1 + math.pi / 4)
				end),
			}),
			e(SmallText, {
				Text = `<font size="32">{CoffeeModule.Config[drink.drinkId].DisplayName}</font>`,
				MaxTextSize = 32,
				MinTextSize = 18,
				RichText = true,
				TextTransparency = t:map(function(n)
					local start = math.min(1, (n - drink.StartTime))
					local End = drink.EndTime and math.min(1, (drink.EndTime - n + 1))
					return drink.EndTime and start or End
				end),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
			}),
		})
	end
	local isactive = activeDrinks and type(activeDrinks) == "table" and #activeDrinks > 0
	return isactive
		and e("ScreenGui", {
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			DisplayOrder = 100,
		}, {
			e("TextButton", {
				Size = UDim2.new(1, 0, 1, 0),
				Text = "",
				BackgroundTransparency = 0.6,
				BackgroundColor3 = Color3.new(0, 0, 0),
				[React.Event.Activated] = function()
					setActiveDrinks(function(prev)
						local clone = table.clone(prev)
						table.remove(clone, 1)
						return clone
					end)
				end,
			}, {
				e(SmallText, {
					Text = "You Discovered a New Drink Variation!",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, -150),
				}),
				e(HStack, {
					Size = UDim2.new(0.5, 0, 0.5, 0),
					-- MinSize = Vector2.new(500, 320),
					-- MaxSize = Vector2.new(500, 500),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					-- OnClose = props.OnClose,
					BackgroundTransparency = 1,
					VerticalFlex = Enum.UIFlexAlignment.None,
					HorizontalFlex = Enum.UIFlexAlignment.None,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					-- BackgroundImage = "",
					-- BackgroundTransparency = 0,
				}, children),
			}),
		})
end

return IngredientShopPanel
