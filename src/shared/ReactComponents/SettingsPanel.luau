-- SettingsPanel.luau
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
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)

-- Require the controllers so UI can update them directly
local MusicController = require(ReplicatedStorage.Shared.Controllers.MusicController)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local DefaultScrollFrame = require(script.Parent.DefaultScrollFrame)
local Toasts = require(script.Parent.Toasts)
local useToast = Toasts.useToast
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)
local Slider = require(Primitives.Slider)

local player = game:GetService("Players").LocalPlayer
local playerId = player and tostring(player.UserId) or ""

local function SettingsPanel(props: {
	OnClose: () -> (),
})
	local toast = useToast()
	local panelOpen, setPanelOpen = useState(false)

	useEffect(function()
		local unsub = UIState:subscribe(function(state: UIState.UIState)
			setPanelOpen(state.panel == "settings")
		end)
		setPanelOpen(UIState:getState().panel == "settings")
		return unsub
	end, {})

	local stats, setStats = useState((not player) and {
		SfxVolume = 0.5,
		MusicVolume = 0.5,
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
	end, { stats and stats.CafeOpen })

	local position, setPosition = useSpring({
		start = -1,
		target = -1,
		speed = 1,
		damper = 1,
	})

	useEffect(function()
		if panelOpen then
			setPosition({ target = 0, speed = 30, damper = 0.6 })
		else
			setPosition({ target = -1, speed = 30, damper = 0.6 })
		end
	end, { panelOpen })

	return e("Frame", {
		Size = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position:map(function(n)
			return UDim2.new(0.5, 0, 0.5 - 2 * n, 0)
		end),
		BackgroundTransparency = 0.9,
	}, {
		DefaultScrollFrame = e(DefaultScrollFrame, {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Padding = { All = UDim.new(0, 8) },
		}, {
			Grid = e(VStack, {
				Spacing = UDim.new(0, 12),
				Size = UDim2.new(1, 0, 1, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				VerticalFlex = Enum.UIFlexAlignment.None,
			}, {
				cafetoggle = e(SmallButton, {
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

				-- Music Slider
				MusicSlider = stats and stats.MusicVolume ~= nil and e(Slider, {
					Label = "Music Volume",
					Value = stats.MusicVolume,
					OnDrag = function(newValue)
						MusicController.setVolume(newValue) -- Client updates locally immediately
					end,
					OnChange = function(newValue)
						MusicController.setVolume(newValue) -- Ensure state holds on release
						Remotes.SetMusicVolume:FireServer(newValue) -- Tell server to save it silently
					end,
				}),

				-- SFX Slider
				SfxSlider = stats and stats.SfxVolume ~= nil and e(Slider, {
					Label = "SFX Volume",
					Value = stats.SfxVolume,
					OnDrag = function(newValue)
						SoundController.setVolume(newValue)
					end,
					OnChange = function(newValue)
						SoundController.setVolume(newValue)
						Remotes.SetSfxVolume:FireServer(newValue)
					end,
				}),
			}),
		}),
	})
end

return SettingsPanel
