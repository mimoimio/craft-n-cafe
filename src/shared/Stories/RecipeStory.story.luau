local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local RecipePanel = require(ReplicatedStorage.Shared.ReactComponents.RecipePanel)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local ViewportController = require(ReplicatedStorage.Shared.Controllers.ViewportController)

local function story(frame: Frame)
	local root = ReactRoblox.createRoot(frame)
	ViewportController.initialize()
	UIState.toggle("recipe")
	root:render(e(RecipePanel))
	return function()
		ViewportController.cleanup()
		root:unmount()
	end
end

return story
