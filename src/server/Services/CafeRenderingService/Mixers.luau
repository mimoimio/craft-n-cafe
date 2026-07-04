-- Server/Services/CafeRenderingService/Mixers.luau
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CafeTypes = require(game.ReplicatedStorage.Shared.CafeTypes)

local function Mixer(props: {
	PlayerId: string,
	Mixer: CafeTypes.Mixer,
	MixerName: string,
})
	useEffect(function()
		if not props.Mixer then
			return
		end

		-- Bind the exact tag dynamically for the client to hook into
		local tag = props.MixerName .. props.PlayerId
		CollectionService:AddTag(props.Mixer, tag)

		return function()
			CollectionService:RemoveTag(props.Mixer, tag)
		end
	end, { props.Mixer, props.PlayerId, props.MixerName })

	return e(React.Fragment)
end

local function Mixers(props: {
	CafeModel: CafeTypes.Cafe,
	PlayerId: string,
})
	local mixersState, setMixersState = useState({})

	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.Mixers[props.PlayerId]
		end, function(newMixersState)
			setMixersState(newMixersState or {})
		end)

		local state = GlobalState:getState()
		if state.Mixers[props.PlayerId] then
			setMixersState(state.Mixers[props.PlayerId])
		end

		return unsub
	end, { props.PlayerId })

	local children = {}
	local mixersFolder = props.CafeModel:FindFirstChild("Mixers")

	if mixersFolder then
		for mixerName, mixerData in pairs(mixersState) do
			local mixerAnchor = mixersFolder:FindFirstChild(mixerName)

			if mixerAnchor then
				children[mixerName] = e(Mixer, {
					PlayerId = props.PlayerId,
					Mixer = mixerAnchor,
					MixerName = mixerName,
					-- later change instead of using mixerUids just
					-- use "Mixer", general, then client can listen
					-- not needing to listen to all mixeruids, cuz
					-- uid is unique, no need. And they can discern
					-- the model's name, which is Uids.
				})
			end
		end
	end

	return e(React.Fragment, nil, children)
end

return Mixers
