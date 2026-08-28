-- Server/Services/CafeRenderingService/Spawners.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CafeTypes = require(game.ReplicatedStorage.Shared.CafeTypes) -- = require(script.Parent.CafeTypes)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)

local function Spawner(props: {
	CafeModel: CafeTypes.Cafe,
	PlayerId: string,
	Stats: any,
})
	local tablesState, setTablesState = useState({})

	-- Subscribe strictly to this player's Tables slice
	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.Tables[props.PlayerId]
		end, function(newTablesState)
			setTablesState(newTablesState or {})
		end)

		-- Initial fetch
		local state = GlobalState:getState()
		if state.Tables[props.PlayerId] then
			setTablesState(state.Tables[props.PlayerId])
		end

		return unsub
	end, { props.PlayerId })

	local children = {}
	local spawner = props.CafeModel and props.CafeModel:FindFirstChild("Spawner") or nil
	local buyPad = props.CafeModel and props.CafeModel:FindFirstChild("BuyPad") or nil

	useEffect(function()
		if not spawner then
			return
		end
		spawner:AddTag(props.PlayerId .. "Spawner")
		return
	end, { spawner })
	useEffect(function()
		if not buyPad then
			return
		end
		buyPad:AddTag(props.PlayerId .. "BuyPad")
		return
	end, { buyPad })

	return e(React.Fragment, nil, children)
end

return Spawner
