local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local DefaultScrollFrame = require(ReplicatedStorage.Shared.ReactComponents.DefaultScrollFrame)
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local Grid = require(ReplicatedStorage.Shared.ReactComponents.ui.Grid)
local CashiersPanel = require(ReplicatedStorage.Shared.ReactComponents.CashiersPanel)

local function App(props: { module: {} }) end

local function story(frame: Frame)
	local root = ReactRoblox.createRoot(frame)
	root:render(e(CashiersPanel))

	UIState.toggle("settings")
	return function()
		root:unmount()
	end
end

return story
