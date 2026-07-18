-- Shared/ReactComponents/MixerManager.luau
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)

local MixerNode = require(script.Parent.MixerNode)
local e = React.createElement

local player = game.Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""

local function MixerManager(props)
	local mixersState, setMixersState = React.useState({})
	local mixerInstances, setMixerInstances = React.useState({})

	-- 1. Subscribe to State
	React.useEffect(function()
		local unsub = GlobalState:subscribe(function(state)
			return state.Mixers[playerId]
		end, function(newMixers)
			setMixersState(newMixers or {})
		end)

		local state = GlobalState:getState()
		if state.Mixers and state.Mixers[playerId] then
			setMixersState(state.Mixers[playerId])
		end

		return unsub
	end, { playerId })

	-- 2. Subscribe to the generic CollectionService tag
	React.useEffect(function()
		local tag = "Mixer" .. playerId

		local function syncInstances()
			local currentInstances = {}
			for _, inst in ipairs(CollectionService:GetTagged(tag)) do
				-- Discern the specific mixer via its Name property
				currentInstances[inst.Name] = inst
			end
			setMixerInstances(currentInstances)
		end

		-- Initial sync
		syncInstances()

		-- Listen for chunks streaming in/out
		local connAdd = CollectionService:GetInstanceAddedSignal(tag):Connect(syncInstances)
		local connRem = CollectionService:GetInstanceRemovedSignal(tag):Connect(syncInstances)

		return function()
			connAdd:Disconnect()
			connRem:Disconnect()
		end
	end, { playerId })

	local children = {}

	for mixerName, mixerData in pairs(mixersState) do
		children[mixerName] = e(MixerNode, {
			MixerName = mixerName,
			MixerData = mixerData,
			Instance = mixerInstances[mixerName], -- Inject the physical instance
		})
	end

	return e(React.Fragment, nil, children)
end

return MixerManager
