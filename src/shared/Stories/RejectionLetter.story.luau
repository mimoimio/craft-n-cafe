local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local DefaultScrollFrame = require(ReplicatedStorage.Shared.ReactComponents.DefaultScrollFrame)
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local RejectionLetter = require(ReplicatedStorage.Shared.ReactComponents.RejectionLetter)

local function story(frame: Frame)
	local root = ReactRoblox.createRoot(frame)
	root:render(e(RejectionLetter))
	UIState.toggle("rejectionletter")

	return function()
		root:unmount()
	end
end

return story
