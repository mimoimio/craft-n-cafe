-- Shared/ReactComponents/Main.luau
local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local COINICON = "robux"
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local React = require(ReplicatedStorage.Packages.React)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)

local e = React.createElement
local useState = React.useState
local useSpring = ReactFlow.useSpring
local useEffect = React.useEffect

local ConsoleApp = require(script.Parent.ConsoleApp)
local DefaultPanel = require(script.Parent.DefaultPanel)
local MixerPanel = require(script.Parent.MixerPanel)
local IngredientShopPanel = require(script.Parent.IngredientShopPanel)
local CustomersPanel = require(script.Parent.CustomersPanel)
local CoinVFXContainer = require(script.Parent.CoinVFXContainer)

local function DrinksPanel(props)
	return e(DefaultPanel, {}, {})
end

local getStats = function(state: GlobalState.GlobalState): {}?
	if not state then
		return
	end
	local stats = state.Stats
	local player = game.Players.LocalPlayer
	local playerId = player and tostring(player.UserId)
	local playersStats = stats[playerId]
	return playersStats
end

local function Main(props)
	local state, setState = useState(nil)
	local activePanel, setActivePanel = useState(nil) -- "Mixer", "Shop", or nil
	local activeMixerId, setActiveMixerId = useState(nil) -- Tracks the specific Mixer string
	local activeCoins, setActiveCoins = React.useState({})
	local coins, setCoins = useState(0)
	local textRef = React.useRef(nil)
	local coinsRef = React.useRef(0)

	local hudRot, setHudRot = useSpring({
		target = 0,
		start = 0,
		speed = 0,
		damper = 0.6,
	})

	useEffect(function()
		coinsRef.current = coins
		setHudRot({
			target = 0,
			start = 10,
			speed = 10,
			damper = 0.6,
		})
	end, { coins })

	local stats: { cash: number }? = getStats(state)

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

	-- CollectionService triggers for Mixers
	useEffect(function()
		if not state then
			return
		end

		local playerId = tostring(Players.LocalPlayer.UserId)
		local connections = {}

		local function bindMixerPrompt(mixerInstance, mixerName)
			local prompt = mixerInstance:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt then
				local conn = prompt.Triggered:Connect(function(player)
					if player == Players.LocalPlayer then
						setActiveMixerId(function(prev)
							-- Toggle off if clicking the same mixer, otherwise open this mixer
							return prev == mixerName and nil or mixerName
						end)
						setActivePanel(nil) -- Close shop if it was open
					end
				end)
				table.insert(connections, conn)
			end
		end

		local mixersData = state.Mixers and state.Mixers[playerId] or {}

		for mixerName, _ in pairs(mixersData) do
			local tag = mixerName .. playerId

			for _, inst in ipairs(CollectionService:GetTagged(tag)) do
				bindMixerPrompt(inst, mixerName) -- Pass mixerName here
			end

			local addedConn = CollectionService:GetInstanceAddedSignal(tag):Connect(function(inst)
				bindMixerPrompt(inst, mixerName)
			end)
			table.insert(connections, addedConn)
		end

		return function()
			for _, conn in ipairs(connections) do
				conn:Disconnect()
			end
		end
	end, { state })

	local function toggleShop()
		setActivePanel(activePanel == "Shop" and nil or "Shop")
		setActiveMixerId(nil) -- Ensure mixer closes when opening shop
	end
	local function toggleCustomers()
		setActivePanel(activePanel == "Customers" and nil or "Customers")
		setActiveMixerId(nil)
	end
	local function closePanel()
		setActivePanel(nil)
	end
	local cashRef: { current: number? } = React.useRef(nil)
	useEffect(function()
		if not (stats and stats.Cash) then
			warn(`failed: stats({stats}), stats.Cash({stats and stats.Cash})`)
			return
		end
		if not cashRef.current then
			warn(`initializing: stats({stats}), stats.Cash({stats and stats.Cash})`)
			cashRef.current = stats.Cash
			setCoins(stats.Cash)
			return
		end
		local id = tostring(tick())
		local diff = stats.Cash - cashRef.current

		-- if negative then no need for coin vfx
		if diff <= 0 then
			setCoins(stats.Cash)
			cashRef.current = stats.Cash
			return
		end

		-- coin vfx
		setActiveCoins(function(prevCoins)
			local nextCoins = table.clone(prevCoins)
			nextCoins[id] = {
				id = id,
				amount = stats.Cash - cashRef.current,
				startPos = workspace.CurrentCamera.ViewportSize / 2,
				hudPos = textRef.current
						and textRef.current.AbsolutePosition + textRef.current.AbsoluteSize / 2 + GuiService:GetGuiInset()
					or nil,
			}
			warn(`stats.Cash ({stats.Cash}) - cashRef.current ({cashRef.current}) = {stats.Cash - cashRef.current}`)
			cashRef.current = stats.Cash
			return nextCoins
		end)
		return
	end, { stats and stats.Cash })

	useEffect(function()
		warn(activePanel)
	end, { activePanel })

	return e("Frame", {
		Transparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
	}, {
		-- Active Panel Overlay
		ActiveOverlay = (activePanel or activeMixerId) and e("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		}, {
			Shop = activePanel == "Shop" and e(IngredientShopPanel, {
				OnClose = function()
					setActivePanel(nil)
				end,
			}),
			Customers = activePanel == "Customers" and e(CustomersPanel, {
				OnClose = function()
					setActivePanel(nil)
				end,
			}),
			Mixer = activeMixerId and e(MixerPanel, {
				MixerId = activeMixerId,
				State = state,
				OnClose = function()
					setActiveMixerId(nil)
				end,
			}),
		}),
		-- HUD Buttons
		HUD = e(HStack, {
			Size = UDim2.new(1, -40, 0, 60),
			Position = UDim2.new(0, 20, 1, -80),
			HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween,
			VerticalFlex = Enum.UIFlexAlignment.Fill,
		}, {
			CustomersButton = e(SmallButton, {
				Text = "Customers",
				Size = UDim2.new(0, 150, 0, 50),
				[React.Event.Activated] = toggleCustomers,
				LayoutOrder = 1,
			}),
			ShopButton = e(SmallButton, {
				Text = "Ingredient Shop",
				Size = UDim2.new(0, 150, 0, 50),
				[React.Event.Activated] = toggleShop,
			}),
			Cash = e(SmallText, {
				Text = (
					([[<font family="rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json">%s</font>]]):format(
						COINICON
					) .. [[%s]]
				):format(coins),
				RichText = true,
				TextSize = 42,
				TextColor3 = Color3.new(1, 1, 0),
				Position = UDim2.new(0.5, 0, 0, 0),
				AnchorPoint = Vector2.new(0.5, 0),
				OnMount = function(rbx: TextLabel)
					textRef.current = rbx
					if not rbx then
						return
					end
				end,
				AutomaticSize = Enum.AutomaticSize.XY,
				Rotation = hudRot,
			}),
			CoinVFXContainer = e(CoinVFXContainer, {
				activeCoins = activeCoins,
				hudPos = Vector2.new(100, 50),
				onCoinComplete = function(completedId)
					-- Clean up the state when the particle finishes its animation
					setActiveCoins(function(prevCoins)
						local nextCoins = table.clone(prevCoins)
						local coin = nextCoins[completedId]
						if not coin then
							return prevCoins
						end
						setCoins(function(prev)
							return prev + coin.amount
						end)
						nextCoins[completedId] = nil
						return nextCoins
					end)
					-- SoundController.Sound("Chik")
				end,
			}),
		}),
		-- e(ConsoleApp, { state = state }),
	})
end

return Main
