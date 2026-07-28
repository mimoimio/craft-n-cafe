local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local ConsoleApp = require(game.ReplicatedStorage.Shared.ReactComponents.ConsoleApp)
-- local Main = require(game.ReplicatedStorage.Shared.ReactComponents.Main)
local DrinksPanel = require(game.ReplicatedStorage.Shared.ReactComponents.DrinksPanel)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local Spawner = require(game.ReplicatedStorage.Shared.ReactComponents.Spawner)

local function story(frame: Frame)
	local root = ReactRoblox.createRoot(frame)
	local spawnerservice = require(ServerScriptService.Server.Services.SpawnerService)
	root:render(e(Spawner))
	-- UIState.toggle("ingredientShop")
	return function()
		root:unmount()
	end
end

return story
