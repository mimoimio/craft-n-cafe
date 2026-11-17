local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
local Toasts = require(script.Parent.Toasts)
local SmallText = require(script.Parent.ui.SmallText)

local e = React.createElement
local useEffect = React.useEffect
local useRef = React.useRef
local useState = React.useState

local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or "MockUser"

local function DailyStatsHud(props)
	local toast = Toasts.useToast()
	local stats, setStats = useState(nil)
	local previousPerfect = useRef(nil)
	local previousKey = useRef(nil)

	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.Stats[playerId]
		end, setStats)

		setStats(GlobalState:getState().Stats[playerId])
		return unsub
	end, {})

	useEffect(function()
		if not stats then
			return
		end

		local dayKey = stats.DailyKey or ""
		local perfect = stats.DailyPerfectCups or 0
		local changedDay = previousKey.current ~= nil and previousKey.current ~= dayKey
		local tutorialComplete = stats.TutorialCompleted == true

		if
			tutorialComplete
			and not changedDay
			and previousPerfect.current ~= nil
			and perfect > previousPerfect.current
		then
			if toast then
				toast.open(`Perfect Cup! Today: {perfect}`, 2.5, Color3.fromRGB(255, 211, 110))
			end
			task.spawn(function()
				SoundController.Sound("powerUp7")
			end)
		end

		previousKey.current = dayKey
		previousPerfect.current = perfect
	end, { stats and stats.DailyKey, stats and stats.DailyPerfectCups })

	if not stats or stats.TutorialCompleted ~= true then
		return nil
	end

	return e(SmallText, {
		Text = `Today: <font color="#FFD36E">{stats.DailyPerfectCups or 0} perfect</font> | <font color="#9BE28B">{stats.DailyPlayerCustomers or 0} served</font>`,
		RichText = true,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(235, 235, 235),
		TextStrokeTransparency = 0.35,
		TextXAlignment = Enum.TextXAlignment.Center,
		AutomaticSize = Enum.AutomaticSize.XY,
		LayoutOrder = props.LayoutOrder,
	})
end

return DailyStatsHud
