-- Shared/ReactComponents/Main.luau
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local HStack = require(Primitives.HStack)
local SmallButton = require(Primitives.SmallButton)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local CashHud = require(script.Parent.CashHud)
local MixerPanel = require(script.Parent.MixerPanel)
local IngredientShopPanel = require(script.Parent.IngredientShopPanel)
local CustomersPanel = require(script.Parent.CustomersPanel)
local CoinVFXContainer = require(script.Parent.CoinVFXContainer)
local RecipePanel = require(script.Parent.RecipePanel)
local CafePanel = require(script.Parent.CafePanel)
local MixerManager = require(script.Parent.MixerManager) -- Injected manager
local CustomerManager = require(script.Parent.CustomerManager) -- Injected manager
local TableManager = require(script.Parent.TableManager) -- Injected manager

local getStats = function(state: GlobalState.GlobalState): {}?
	if not state then
		return
	end
	local stats = state.Stats
	local player = game.Players.LocalPlayer
	local playerId = player and tostring(player.UserId)
	return stats[playerId]
end

local function Main(props)
	local state, setState = useState(nil)
	local activePanel, setActivePanel = useState(nil) -- "Shop", "Customers", or nil
	local activeMixerId, setActiveMixerId = useState(nil)
	local activeCoins, setActiveCoins = useState({})
	local coins, setCoins = useState(0)

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

	local toggle = React.useCallback(function(panel: string)
		setActivePanel(function(prev)
			if prev == panel then
				return "none"
			end
			return panel
		end)
	end, {})
	local closeAllPanels = React.useCallback(function()
		setActivePanel("none")
		setActiveMixerId(nil)
	end, {})
	local toggleMixerInteract = React.useCallback(function(mixerName)
		setActivePanel("mixer")
		setActiveMixerId(mixerName)
	end, {})
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
				Open = activePanel == "Shop",
				OnClose = closeAllPanels,
			}),
			Customers = e(CustomersPanel, {
				Open = activePanel == "Customers",
				OnClose = closeAllPanels,
			}),
			Mixer = e(MixerPanel, {
				Open = activePanel == "mixer",
				MixerId = activeMixerId,
				Ingredients = state and state.Ingredients,
				OnClose = closeAllPanels,
			}),
			Recipes = e(RecipePanel, {
				visible = activePanel == "recipe",
				OnClose = closeAllPanels,
			}),
			CafePanel = e(CafePanel, {
				Open = activePanel == "cafe",
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

		HUD = e(HStack, {
			Size = UDim2.new(1, -40, 0, 60),
			Position = UDim2.new(0, 20, 1, -80),
			HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween,
			VerticalFlex = Enum.UIFlexAlignment.Fill,
		}, {
			CustomersButton = e(SmallButton, {
				Text = "Customers",
				Size = UDim2.new(0, 150, 0, 50),
				[React.Event.Activated] = function()
					toggle("Customers")
				end,
				LayoutOrder = 1,
			}),
			ShopButton = e(SmallButton, {
				Text = "Ingredient Shop",
				Size = UDim2.new(0, 150, 0, 50),
				[React.Event.Activated] = function()
					toggle("Shop")
				end,
				LayoutOrder = 2,
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
		}),

		e(SmallButton, {
			Text = "Cafe",
			[React.Event.Activated] = function()
				toggle("cafe")
			end,
		}),
		-- e(require(script.Parent.ConsoleApp), { state = state }),
	})
end

return Main
