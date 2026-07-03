local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local React = require(ReplicatedStorage.Packages.React)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local VStack = require(Primitives.VStack)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local ConsoleApp = require(script.Parent.ConsoleApp)
local DefaultPanel = require(script.Parent.DefaultPanel)
local DefaultScrollFrame = require(script.Parent.DefaultScrollFrame)
local function DrinksPanel(props: {
	Drinks: {},
})
	local drinks = props.Drinks
	local children = {}
	for i, drink in drinks do
		children[drink.id] = e("TextButton", {
			Text = drink.drinkId,
			Size = UDim2.new(0, 50, 0, 50),
		})
	end
	return e(DefaultPanel, {
		MinSize = Vector2.new(600, 300),
		ScaleType = Enum.ScaleType.Stretch,
		BackgroundImage = "rbxassetid://16400932136",
	}, {
		e(DefaultScrollFrame, {
			Size = UDim2.new(1, 0, 1, 0),
		}, children),
	})
end

return DrinksPanel
