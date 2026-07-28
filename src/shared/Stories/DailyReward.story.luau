local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local DefaultScrollFrame = require(ReplicatedStorage.Shared.ReactComponents.DefaultScrollFrame)
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local MixerProgressBar = require(ReplicatedStorage.Shared.ReactComponents.MixerProgressBar)
local DailyPanel = require(ReplicatedStorage.Shared.ReactComponents.DailyPanel)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local App = function()
	local mixer, setMixer = useState({ drinkId = "none" })
	useEffect(function() end, {})
	return
end
local function story(frame: Frame)
	local root = ReactRoblox.createRoot(frame)
	root:render(e(DailyPanel, {}))
	UIState.toggle("daily")
	return function()
		root:unmount()
	end
end

return story
