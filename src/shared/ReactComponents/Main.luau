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

local function Main(props)
	local state, setState = useState(nil)
	useEffect(function()
		local unsub = GlobalState:subscribe(function(state)
			setState(state)
		end)
		return function() end
	end)
	return e(ConsoleApp, { state = state })
end

return Main
