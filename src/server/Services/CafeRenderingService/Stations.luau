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
local CafeTypes = require(script.Parent.CafeTypes)

local function Stations(props: {
	BaseModel: CafeTypes.CafeBase,
	PlayerId: string,
	Stats: GlobalState.Stats,
})
	useEffect(function()
		return
	end, {})
	local children = {}
	return e(React.Fragment, nil, children)
end
return Stations
