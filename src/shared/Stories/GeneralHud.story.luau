local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local DefaultScrollFrame = require(ReplicatedStorage.Shared.ReactComponents.DefaultScrollFrame)
local ViewportController = require(ReplicatedStorage.Shared.Controllers.ViewportController)
local Main = require(ReplicatedStorage.Shared.ReactComponents.Main)
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local SmallButton = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallButton)
local Grid = require(ReplicatedStorage.Shared.ReactComponents.ui.Grid)
local VStack = require(ReplicatedStorage.Shared.ReactComponents.ui.VStack)
local HStack = require(ReplicatedStorage.Shared.ReactComponents.ui.HStack)

local function story(frame: Frame)
	local root = ReactRoblox.createRoot(frame)
	root:render(e(Main))

	ViewportController.initialize()
	return function()
		root:unmount()
		ViewportController.cleanup()
		GlobalState:resetState()
		UIState:resetState()
	end
end

return story
