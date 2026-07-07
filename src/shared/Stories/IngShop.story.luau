local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local ConsoleApp = require(game.ReplicatedStorage.Shared.ReactComponents.ConsoleApp)
-- local Main = require(game.ReplicatedStorage.Shared.ReactComponents.Main)
local DrinksPanel = require(game.ReplicatedStorage.Shared.ReactComponents.DrinksPanel)
local IngredientShopPanel = require(game.ReplicatedStorage.Shared.ReactComponents.IngredientShopPanel)
local CustomersPanel = require(game.ReplicatedStorage.Shared.ReactComponents.CustomersPanel)
local function App(props)
	local drinks, setDrinks = useState({
		{
			id = "abc",
			drinkId = "americano",
			stock = 5,
		},
		{
			id = "bcd",
			drinkId = "latte",
			stock = 5,
		},
	})
	return e(DrinksPanel, {
		Drinks = drinks,
	})
end

local function story(frame: Frame)
	local root = ReactRoblox.createRoot(frame)
	root:render(e(IngredientShopPanel))
	return function()
		root:unmount()
	end
end

return story
