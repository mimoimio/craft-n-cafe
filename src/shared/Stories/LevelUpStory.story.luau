local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local DefaultScrollFrame = require(ReplicatedStorage.Shared.ReactComponents.DefaultScrollFrame)
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local Grid = require(ReplicatedStorage.Shared.ReactComponents.ui.Grid)
local LevelUp = require(ReplicatedStorage.Shared.ReactComponents.LevelUp)

local function story(frame: Frame)
	local root = ReactRoblox.createRoot(frame)
	root:render(e(LevelUp))

	return function()
		root:unmount()
	end
end

return story
