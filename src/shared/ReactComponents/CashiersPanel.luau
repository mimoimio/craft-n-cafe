-- Shared/ReactComponents/CashiersPanel.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local e = React.createElement
local useState = React.useState
local useSpring = ReactFlow.useSpring

local useBinding = React.useBinding
local useEffect = React.useEffect
local useRef = React.useRef
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
-- local LevelConfig = require(ReplicatedStorage.Shared.Configs.LevelConfig)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local DefaultPanel = require(script.Parent.DefaultPanel)
local DefaultScrollFrame = require(script.Parent.DefaultScrollFrame)
local Toasts = require(script.Parent.Toasts)
local useToast = Toasts.useToast
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)

local player = game:GetService("Players").LocalPlayer
local playerId = player and tostring(player.UserId) or ""

local function HireCashierButton()
	return e(SmallButton, {
		Text = `Hire Cashier: $10k (Max 3)`,
		[React.Event.Activated] = function()
			Remotes.HireCashier:FireServer()
		end,
		RichText = true,
		MinTextSize = 14,
	})
end

local function CashiersPanel(props: {
	OnClose: () -> (),
})
	local toast = useToast()
	--listen to active panel
	local panelOpen, setPanelOpen = useState((not player) or false)
	local cashiers, setCashiers = useState((not player) and {
		[1] = {
			lastTend = workspace:GetServerTimeNow(),
			id = "son",
		},
	} or nil)
	useEffect(function()
		local unsub = UIState:subscribe(function(state: UIState.UIState)
			setPanelOpen(state.panel == "cashiers")
		end)
		return unsub
	end, {})
	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			local cashiers = state.Cashiers[playerId]
			if cashiers then
				setCashiers(cashiers)
			end
		end)
		local state = GlobalState:getState()
		local cashiers = state.Cashiers[playerId]
		if cashiers then
			setCashiers(cashiers)
		end
		return unsub
	end, {})

	-- useEffect(function() end, { panelOpen })

	local position, setPosition = useSpring({
		start = -1,
		target = -1,
		speed = 1,
		damper = 1,
	})
	useEffect(function()
		if panelOpen then
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
	end, { panelOpen })

	local children = {
		e(HireCashierButton),
	}

	for i, cashier in cashiers or {} do
		table.insert(
			children,
			e(SmallButton, {
				Size = UDim2.fromScale(1, 1),
				Text = `Cashier ({i})`,
				-- [React.Event.Activated] = function()
				-- 	Remotes.ToggleCafeOpen:FireServer()
				-- end,
				RichText = true,
				MinTextSize = 14,
				Active = false,
			}, {
				e(SmallButton, {
					Text = `Fire ({i})`,
					[React.Event.Activated] = function()
						Remotes.FireCashier:FireServer(cashier.id)
					end,
					RichText = true,
					MinTextSize = 14,
				}),
			})
		)
	end
	return e(DefaultPanel, {
		Title = "Cashiers",
		Size = UDim2.new(0.5, 0, 1, 0),
		-- MinSize = Vector2.new(500, 320),
		MaxSize = Vector2.new(500, 500),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position:map(function(n)
			return UDim2.new(0.5, 0, 0.5 - 2 * n, 0)
		end),
		OnClose = function()
			UIState.toggle("none")
		end,
		BackgroundImageTransparency = 0,
		-- Open = panelOpen,
	}, {
		DefaultScrollFrame = e(DefaultScrollFrame, {
			Size = UDim2.new(1, 0, 1, 0),
		}, {
			Grid = e(VStack, {
				-- CellSize = UDim2.new(1, -20, 0, 150),
				Spacing = UDim.new(0, 4),
				Size = UDim2.new(1, 0, 1, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				VerticalFlex = Enum.UIFlexAlignment.None,
			}, children),
		}),
	})
end

return CashiersPanel
