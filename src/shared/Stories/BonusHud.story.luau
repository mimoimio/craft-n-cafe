local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local DefaultScrollFrame = require(ReplicatedStorage.Shared.ReactComponents.DefaultScrollFrame)
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local MixerProgressBar = require(ReplicatedStorage.Shared.ReactComponents.MixerProgressBar)
local BonusHud = require(ReplicatedStorage.Shared.ReactComponents.BonusHud)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local function story(frame: Frame)
	local root = ReactRoblox.createRoot(frame)
	root:render(e(BonusHud))

	return function()
		root:unmount()
	end
end

return story
