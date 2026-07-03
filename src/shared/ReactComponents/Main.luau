-- Shared/ReactComponents/Main.luau
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local React = require(ReplicatedStorage.Packages.React)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local ConsoleApp = require(script.Parent.ConsoleApp)
local DefaultPanel = require(script.Parent.DefaultPanel)
local MixerPanel = require(script.Parent.MixerPanel)
local IngredientShopPanel = require(script.Parent.IngredientShopPanel)
local CustomersPanel = require(script.Parent.CustomersPanel)

local function DrinksPanel(props)
	return e(DefaultPanel, {}, {})
end

local function Main(props)
	local state, setState = useState(nil)
	local activePanel, setActivePanel = useState(nil) -- "Mixer", "Shop", or nil
	local activeMixerId, setActiveMixerId = useState(nil) -- Tracks the specific Mixer string
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
				OnClose = function()
					setActiveMixerId(nil)
				end,
			}),
		}),
		-- HUD Buttons
		HUD = e(HStack, {
			Size = UDim2.new(1, -40, 0, 60),
			Position = UDim2.new(0, 20, 1, -80),
			HorizontalFlex = Enum.UIFlexAlignment.Fill,
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
		}),
		e(ConsoleApp, { state = state }),
	})
end

return Main
