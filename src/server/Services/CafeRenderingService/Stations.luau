-- CafeRenderingService/Stations.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RENDERTAG = "RENDEREDOBJECT"
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CafeTypes = require(game.ReplicatedStorage.Shared.CafeTypes) -- = require(script.Parent.CafeTypes)

local function Station(props: {
	StationModel: CafeTypes.Station,
	PlayerId: string,
})
	local children = {}
	useEffect(function()
		if not props.StationModel then
			return
		end
		local conn = props.StationModel.Part.TriggerPrompt.Triggered:Connect(function(player: Player)
			local playerId = tostring(player.UserId)
			if playerId ~= props.PlayerId then
				print("not playerId")
				return
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

	local stations: { CafeTypes.Station } = props.CafeModel and props.CafeModel.Stations:GetChildren()

	local children = {}
	-- for i, station in stations do
	-- 	children[station.Name] = e(Station, {
	-- 		StationModel = station,
	-- 		PlayerId = props.PlayerId,
	-- 	})
	-- end

	return e(React.Fragment, nil, children)
end
return Stations
