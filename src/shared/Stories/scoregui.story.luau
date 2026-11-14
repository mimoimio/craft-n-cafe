-- GeneralHud.story.luau
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local Grid = require(ReplicatedStorage.Shared.Grid)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ViewportController = require(ReplicatedStorage.Shared.Controllers.ViewportController)
local Main = require(ReplicatedStorage.Shared.ReactComponents.Main)
local scoregui = require(ReplicatedStorage.Shared.ReactComponents.scoregui)
local App = require(ReplicatedStorage.Shared.ReactComponents.App)
local PlotConfig = require(ReplicatedStorage.Shared.Configs.PlotConfig:Clone())

local InputAdapter = require(ReplicatedStorage.Shared.Controllers.InputAdapter)

local function story(frame: Frame)
	local root = ReactRoblox.createRoot(frame)
	root:render(e("Frame", {
		Size = UDim2.new(0, 200, 0, 40),
		BackgroundTransparency = 1,
	}, {
		e(function()
			local cup, setCup = React.useState({
				drinkId = "espresso",
				status = 3,
			})
			React.useEffect(function()
				task.delay(1, function()
					setCup({
						drinkId = "espresso",
						status = 2,
					})
					task.wait(1)

					setCup({
						drinkId = "espresso",
						status = 1,
					})
				end)
			end, {})
			return e(scoregui, {
				cup = cup,
			})
		end),
	}))
	ViewportController.initialize()

	return function()
		root:unmount()
		ViewportController.cleanup()
		GlobalState:resetState()
		UIState:resetState()
	end
end

return story
