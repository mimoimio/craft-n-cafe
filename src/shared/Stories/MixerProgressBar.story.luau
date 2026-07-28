local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local DefaultScrollFrame = require(ReplicatedStorage.Shared.ReactComponents.DefaultScrollFrame)
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local MixerProgressBar = require(ReplicatedStorage.Shared.ReactComponents.MixerProgressBar)
local MixerNode = require(ReplicatedStorage.Shared.ReactComponents.MixerNode)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local App = function()
	local Config = CoffeeModule.Config.sundae
	local mixer, setMixer = useState({ drinkId = "none" })
	useEffect(function()
		task.defer(function()
			task.wait(2)
			setMixer({
				startTime = workspace:GetServerTimeNow(),
				drinkId = "espresso",
				variationId = "starlight",
			})
		end)
		return
	end, {})
	return e(MixerNode, {
		MixerName = "Mixer1",
		MixerData = mixer,
		Instance = workspace.Adornee, -- Inject the physical instance
	})
end
local function story(frame: Frame)
	local root = ReactRoblox.createRoot(frame)
	root:render(e(App))

	return function()
		root:unmount()
	end
end

return story
