-- CafeRenderingService/Stations.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RENDERTAG = "RENDEREDOBJECT"
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes) -- = require(script.Parent.CafeTypes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule) -- = require(script.Parent.CafeTypes)
local DrinksService = require(ServerScriptService.Server.Services.DrinksService) -- = require(script.Parent.CafeTypes)

local function Station(props: {
	StationModel: CafeTypes.Station,
	PlayerId: string,
})
	local children = {}
	useEffect(function()
		if not props.StationModel then
			return
		end
		local stationName = props.StationModel.Name
		local config = CoffeeModule.IngredientLookup[stationName]
		props.StationModel.ProximityPrompt.ActionText = stationName == "cup" and "Get a cup"
			or stationName == "trash" and "Trash current cup"
			or config and `Add {config.DisplayName}`
			or "???"
		props.StationModel.ProximityPrompt.ObjectText = stationName == "cup" and "Cup"
			or stationName == "trash" and "Trash bin"
			or config and `{config.DisplayName}`
			or "???"
		local conn = props.StationModel.ProximityPrompt.Triggered:Connect(function(player: Player)
			local playerId = tostring(player.UserId)
			if playerId ~= props.PlayerId then
				print("not playerId")
				return
			end
			if stationName == "cup" then
				DrinksService.GetCup(player)
			elseif stationName == "trash" then
				DrinksService.TrashCup(player)
			else
				DrinksService.AddIngredient(player, stationName)
			end
		end)
		return function()
			if conn then
				conn:Disconnect()
			end
			if not (props.StationModel and props.StationModel.Parent) then
				return
			end
			-- props.StationModel.Part.TriggerPrompt.
		end
	end, { props.StationModel })

	return e(React.Fragment, nil, children)
end

local function Stations(props: {
	CafeModel: CafeTypes.Cafe,
	PlayerId: string,
})
	useEffect(function()
		if not props.CafeModel then
			return
		end
		return function() end
	end, { props.CafeModel })

	local children = {}
	if props.CafeModel and props.CafeModel.Stations then
		local stations: { CafeTypes.Station } = props.CafeModel and props.CafeModel.Stations:GetChildren()
		for i, station in stations do
			children[station.Name] = e(Station, {
				StationModel = station,
				PlayerId = props.PlayerId,
			})
		end
	end

	return e(React.Fragment, nil, children)
end
return Stations
