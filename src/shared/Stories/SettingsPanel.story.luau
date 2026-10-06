-- SettingsPanel.story.luau
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local Grid = require(ReplicatedStorage.Shared.Grid)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)
local ViewportController = require(ReplicatedStorage.Shared.Controllers.ViewportController)
local Main = require(ReplicatedStorage.Shared.ReactComponents.Main)
local App = require(ReplicatedStorage.Shared.ReactComponents.App)
local PlotConfig = require(ReplicatedStorage.Shared.Configs.PlotConfig:Clone())

local InputAdapter = require(ReplicatedStorage.Shared.Controllers.InputAdapter)

local CafeRenderingService = require(ServerScriptService.Server.Services.CafeRenderingService)

local function getPlot()
	PlotConfig.FirstPlot.plotSize = 32
	return PlotConfig.FirstPlot
end

local function StoryApp(props: {})
	local textBox: TextBox, setTextBox = useState(nil)
	useEffect(function()
		if not textBox then
			return
		end
		local conn = textBox:GetPropertyChangedSignal("Text"):Connect(function()
			local value = textBox.Text
			local numberValue: number = tonumber(value)
			if not numberValue then
				return
			end
			GlobalState._addExp("MockUser", 0, numberValue)
		end)

		return function()
			conn:Disconnect()
		end
	end, { textBox })
	return e(React.Fragment, nil, {
		ShopPanel = e(
			require(ReplicatedStorage.Shared.ReactComponents.RedDot).RedDotProvider,
			nil,
			{ e(require(ReplicatedStorage.Shared.ReactComponents.SettingsPanel)) }
		),
		LevelSetter = e("TextBox", {
			Text = "5",
			Size = UDim2.new(0, 200, 0, 50),
			ref = setTextBox,
		}),
	})
end
local function story(frame: Frame)
	local inventory = {}
	for i, config in PlaceablesModule.Array do
		inventory[config.Id] = math.min(32, config.MaxAllowed)
	end
	UIState.toggle("settings")
	GlobalState.startPlayerSession("MockUser", {
		Plot = getPlot(),
		Stats = {
			EXP = 100,
			Level = 5,
			Cash = 500000,
		},
		Inventory = inventory,
		SfxVolume = 0.5,
		SfxOn = true,
		MusicVolume = 0.5,
		MusicOn = true,

		Ingredients = {},
		Customers = {},
		Workers = {},
		Cups = {},
	})

	local root = ReactRoblox.createRoot(frame)
	root:render(e(StoryApp))
	ViewportController.initialize()

	return function()
		root:unmount()
		ViewportController.cleanup()
		GlobalState:resetState()
		UIState:resetState()
	end
end

return story
