local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local ConsoleApp = require(game.ReplicatedStorage.Shared.ReactComponents.ConsoleApp)
-- local Main = require(game.ReplicatedStorage.Shared.ReactComponents.Main)
local DrinksPanel = require(game.ReplicatedStorage.Shared.ReactComponents.DrinksPanel)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local IngredientShopPanel = require(game.ReplicatedStorage.Shared.ReactComponents.IngredientShopPanel)
local function story(frame: Frame)
	local root = ReactRoblox.createRoot(frame)
	root:render(e(IngredientShopPanel))
	UIState.toggle("ingredientShop")
	return function()
		root:unmount()
	end
end

return story
