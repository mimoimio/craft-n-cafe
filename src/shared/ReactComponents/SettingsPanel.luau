-- Shared/ReactComponents/IngredientShopPanel.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useBinding = React.useBinding
local useEffect = React.useEffect
local useRef = React.useRef
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local LevelConfig = require(ReplicatedStorage.Shared.Configs.LevelConfig)
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

local player = game.Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""
local function IngredientShopPanel(props: {
	OnClose: () -> (),
})
	local toast = useToast()
	--listen to active panel
	local panelOpen, setPanelOpen = useState((not player) or false)
	useEffect(function()
		local unsub = UIState:subscribe(function(state: UIState.UIState)
			setPanelOpen(state.panel == "settings")
		end)
		return unsub
	end, {})

	local stats, setStats = useState((not player) and {
		Sfx = 0.5,
		Music = 0.5,
		SecondsPlayed = 0,
		Cash = 100,
		Level = 1,
		CafeOpen = false,
	} or nil)

	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.Stats[playerId]
		end, function(playersStats)
			setStats(playersStats)
		end)
		local state = GlobalState:getState()
		local playersStats = state.Stats[playerId]
		if playersStats then
			setStats(playersStats)
		end
		return unsub
	end, {})
	useEffect(function() end, { panelOpen })

	local prevCafeOpenRef = useRef(nil)
	useEffect(function()
		if not (stats ~= nil and stats.CafeOpen ~= nil) then
			return
		end
		if prevCafeOpenRef.current == nil then
			prevCafeOpenRef.current = stats.CafeOpen
			return
		end
		if prevCafeOpenRef.current ~= stats.CafeOpen then
			toast.open(prevCafeOpenRef.current and "Cafe Closed!" or "Cafe Opened!")
			prevCafeOpenRef.current = stats.CafeOpen
		end

		return
	end, { stats and stats.CafeOpen })

	return e(DefaultPanel, {
		Title = "Settings",
		Size = UDim2.new(0.5, 0, 1, 0),
		-- MinSize = Vector2.new(500, 320),
		MaxSize = Vector2.new(500, 500),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		OnClose = props.OnClose,
		BackgroundImageTransparency = 0,
		Open = panelOpen,
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
			}, {
				e(SmallButton, {
					Text = stats
							and stats.CafeOpen
							and `Your Cafe is Open!\n<font size="12">Click to close cafe</font>`
						or `Your Cafe is Closed!\n<font size="12">Click to open cafe</font>`,
					[React.Event.Activated] = function()
						Remotes.ToggleCafeOpen:FireServer()
					end,
					RichText = true,
					MinTextSize = 14,
				}),
			}),
		}),
	})
end

return IngredientShopPanel
