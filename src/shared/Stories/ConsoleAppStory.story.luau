local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local ConsoleApp = require(game.ReplicatedStorage.Shared.ReactComponents.ConsoleApp)
local Main = require(game.ReplicatedStorage.Shared.ReactComponents.Main)

local function story(frame: Frame)
	local root = ReactRoblox.createRoot(frame)
	root:render(e(Main))
	return function()
		root:unmount()
	end
end
return story
