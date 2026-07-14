-- Shared/ReactComponents/Main.luau
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local ShopCycle = require(ReplicatedStorage.Shared.ShopCycle)
local HStack = require(Primitives.HStack)
local SmallButton = require(Primitives.SmallButton)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

-- UIState actions
local toggle = UIState.toggle
local toggleMixerInteract = UIState.toggleMixerInteract

local CashHud = require(script.Parent.CashHud)
local MixerPanel = require(script.Parent.MixerPanel)
local IngredientShopPanel = require(script.Parent.IngredientShopPanel)
local SettingsPanel = require(script.Parent.SettingsPanel)
local CustomersPanel = require(script.Parent.CustomersPanel)
local CoinVFXContainer = require(script.Parent.CoinVFXContainer)
local RecipePanel = require(script.Parent.RecipePanel)
local CafePanel = require(script.Parent.CafePanel)
local MixerManager = require(script.Parent.MixerManager) -- Injected manager
local CustomerManager = require(script.Parent.CustomerManager) -- Injected manager
local TableManager = require(script.Parent.TableManager) -- Injected manager
local VStack = require(script.Parent.ui.VStack)

local player = game.Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""
local getStats = function(state: GlobalState.GlobalState): {}?
	if not state then
		return
	end
	local stats = state.Stats
	return stats[playerId]
end

local function Main(props)
	local state, setState = useState(nil)
	local activePanel, setActivePanel = useState(nil) -- "Shop", "Customers", or nil
	local activeCoins, setActiveCoins = useState({})
	local coins, setCoins = useState(nil)
	local admin, setAdmin = useState(false)

	local textRef = React.useRef(nil)
	local cashRef = React.useRef(nil)

	local stats = getStats(state)

	-- Keep global state in sync
	useEffect(function()
		local unsub = GlobalState:subscribe(function(newState)
			setState(newState)
		end)

		setState(GlobalState:getState())

		return function()
			unsub()
		end
	end, {})

	--listen to UIState's panel
	useEffect(function()
		local unsub = UIState:subscribe(function(newState: UIState.UIState)
			setActivePanel(newState.panel)
		end)
		local state = UIState:getState()
		if state.panel then
			setActivePanel(state.panel)
		end
		return function()
			unsub()
		end
	end, {})

	-- Handle Cash & VFX updates
	useEffect(function()
		if not (stats and stats.Cash) then
			return
		end

		if not cashRef.current then
			cashRef.current = stats.Cash
			setCoins(stats.Cash)
			return
		end

		local id = tostring(tick())
		local diff = stats.Cash - cashRef.current

		if diff <= 0 then
			setCoins(stats.Cash)
			cashRef.current = stats.Cash
			return
		end

		setActiveCoins(function(prevCoins)
			local nextCoins = table.clone(prevCoins)
			local done
			for i = 1, 2 do
				nextCoins[id .. i] = {
					id = id .. i,
					amount = (not done) and (stats.Cash - cashRef.current) or nil,
					startPos = workspace.CurrentCamera.ViewportSize / 2,
					hudPos = textRef.current
							and textRef.current.AbsolutePosition + textRef.current.AbsoluteSize / 2 + GuiService:GetGuiInset()
						or nil,
				}
				done = true
			end

			cashRef.current = stats.Cash
			return nextCoins
		end)
	end, { stats and stats.Cash })

	local closeAllPanels = React.useCallback(function()
		toggle("none")
	end, {})

	local time, setTime = React.useBinding("")
	useEffect(function()
		local t = task.spawn(function()
			while task.wait(0.5) do
				local cycle = ShopCycle.getCurrentState()
				setTime(
					-- `seed({cycle.seed}), timeLeft({cycle.timeLeft // 1}), timeToSpecial({cycle.timeToSpecial // 1})`
					`Shop refreshes in: {cycle.timeLeft // 60}m {cycle.timeLeft // 1 % 60}s\nSpecial Event in: {cycle.timeToSpecial // 60}m {cycle.timeToSpecial // 1 % 60}s`
				)
			end
		end)
		return function()
			task.cancel(t)
		end
	end, {})

	local timehud = e(require(script.Parent.ui.SmallText), {
		Text = time,
		AutomaticSize = Enum.AutomaticSize.XY,
		Position = UDim2.new(0.5, 0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 1),
	})

	return e("Frame", {
		Transparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
	}, {
		-- Background Manager mapping to the 3D world (Invisible)
		MixerManager = e(MixerManager, {
			onInteract = toggleMixerInteract,
		}),

		CustomerManager = e(CustomerManager),

		-- Active Panel Overlay
		ActiveOverlay = e("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		}, {
			Shop = e(IngredientShopPanel, {
				OnClose = closeAllPanels,
			}),
			Settings = e(SettingsPanel, {
				OnClose = closeAllPanels,
			}),
			Mixer = e(MixerPanel, {
				OnClose = closeAllPanels,
			}),
			-- Recipes = e(RecipePanel, {
			-- 	visible = activePanel == "recipe",
			-- 	OnClose = closeAllPanels,
			-- }),
			CafePanel = e(CafePanel, {
				OnClose = closeAllPanels,
			}),
		}),

		Tables = e(TableManager),
		-- HUD Elements
		Cash = e(CashHud, {
			OnMount = function(rbx)
				textRef.current = rbx
			end,
			coins = coins,
		}),
		timehud = timehud,

		Left = e(VStack, {
			VerticalFlex = Enum.UIFlexAlignment.None,
			HorizontalFlex = Enum.UIFlexAlignment.None,
			-- BackgroundColor3 = Color3.new(1, 0, 0),
			-- BackgroundTransparency = 0,
			Spacing = UDim.new(0, 8),
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.new(0, 0, 0, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
		}, {
			CafeButton = e(SmallButton, {
				LayoutOrder = 1,
				BackgroundTransparency = 1,
				TextSize = 32,
				Image = "rbxassetid://122526927441389",
				Size = UDim2.new(0, 50, 0, 50),
				[React.Event.Activated] = function()
					toggle("cafe")
				end,
			}),
			SettingsButton = e(SmallButton, {
				LayoutOrder = 2,
				BackgroundTransparency = 1,
				Image = "rbxassetid://135990132441809",
				TextSize = 32,
				Size = UDim2.new(0, 50, 0, 50),
				[React.Event.Activated] = function()
					toggle("settings")
				end,
			}),
			e(SmallButton, {
				LayoutOrder = 3,
				Image = "rbxassetid://112161362547076",
				BackgroundTransparency = 1,
				TextSize = 32,
				Size = UDim2.new(0, 50, 0, 50),
				[React.Event.Activated] = function()
					toggle("ingredientShop")
				end,
			}),
		}),
		CoinVFXContainer = e(CoinVFXContainer, {
			activeCoins = activeCoins,
			hudPos = Vector2.new(100, 50),
			onCoinComplete = function(completedId)
				setActiveCoins(function(prevCoins)
					local nextCoins = table.clone(prevCoins)
					local coin = nextCoins[completedId]
					if not coin then
						return prevCoins
					end

					setCoins(function(prev)
						SoundController.Sound("handleCoins")
						return prev + (coin.amount or 0)
					end)

					nextCoins[completedId] = nil
					-- SoundController
					return nextCoins
				end)
			end,
		}),
		e(SmallButton, {
			RichText = true,
			Text = `<font size="12">console\n(playtest)</font>`,
			Position = UDim2.new(1, 0, 0, 0),
			AnchorPoint = Vector2.new(1, 1),
			[React.Event.Activated] = function()
				setAdmin(function(prev)
					return not prev
				end)
			end,
			MinTextSize = 8,
		}),
		admin = admin and e(require(script.Parent.ConsoleApp), { state = state }),
		e(require(script.Parent.DiscoveredDrink), { state = state }),
		e(require(script.Parent.LevelUp), { state = state }),
		e(require(script.Parent.Tutorial)),
	})
end

return Main
