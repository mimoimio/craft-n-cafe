local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)

local useToast = require(script.Parent.Toasts).useToast

local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""

local function SpecialEvent()
	local toast = useToast()
	local event: string?, setEvent = useState(nil)
	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			local playersShop = state.Shop[playerId]
			if playersShop and playersShop.variationEvent and playersShop.variationEvent ~= nil then
				return playersShop.variationEvent
			end
			return nil
		end, function(variationId)
			setEvent(variationId)
		end)

		local playersShop = GlobalState:getState().Shop[playerId]
		if playersShop then
			setEvent(playersShop.variationEvent)
		end

		return unsub
	end, {})
	useEffect(function()
		if not event then
			return
		end
		toast.open(`Event {VariationsConfig[event] and VariationsConfig[event].DisplayName}`)
	end, { event })
	return nil
end
return SpecialEvent
