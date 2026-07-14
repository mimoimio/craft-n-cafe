-- Shared/ReactComponents/LevelUp.luau
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

local function LevelUp(props: {})
	local playersLevel, setPlayersLevel = useState(1)
	local isActive, setIsActive = useState(nil)
	local t, setT = useBinding(tick())

	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.Stats[playerId]
		end, function(_playersStats)
			if not (_playersStats and _playersStats.Level) then
				return
			end
			setPlayersLevel(_playersStats.Level)
		end)
		local state = GlobalState:getState()
		local _playersStats = state.Stats[playerId]
		setPlayersLevel(_playersStats and _playersStats.Level or 1)
		if not player then
			task.delay(1, function()
				setPlayersLevel(2)
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

	local prevLevelRef = useRef(nil)
	useEffect(function()
		if not playersLevel then
			return
		end
		if not prevLevelRef.current then
			prevLevelRef.current = playersLevel
			return
		end
	end, { playersLevel })

	if prevLevelRef.current and playersLevel and prevLevelRef.current < playersLevel then
		return e("ScreenGui", {
			IgnoreGuiInset = true,
		}, {
			e(SmallButton, {
				Text = "You've leveled up!!!!!11!!",
				[React.Event.Activated] = function()
					prevLevelRef.current = playersLevel
					setIsActive(function(prev)
						return not prev
					end)
				end,
				BackgroundColor3 = Color3.new(),
				Size = UDim2.new(1, 0, 1, 0),
			}),
		})
	end
	return nil
end

return LevelUp
