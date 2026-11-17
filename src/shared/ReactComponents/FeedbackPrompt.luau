local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local FeedbackPromptConfig = require(ReplicatedStorage.Shared.Configs.FeedbackPromptConfig)
local FeedbackPromptController = require(ReplicatedStorage.Shared.Controllers.FeedbackPromptController)

local useEffect = React.useEffect
local useState = React.useState

local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or "MockUser"

local function hasActiveCustomer(customers): boolean
	for _, customer in pairs(customers or {}) do
		if customer.customerAction == "queuing" or customer.customerAction == "waiting" then
			return true
		end
	end
	return false
end

local function FeedbackPrompt()
	local stats, setStats = useState(nil)

	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.Stats[playerId]
		end, setStats)

		setStats(GlobalState:getState().Stats[playerId])
		return unsub
	end, {})

	useEffect(function()
		if not FeedbackPromptController.canAutoPrompt(stats) then
			return
		end

		local cancelled = false

		task.spawn(function()
			task.wait(FeedbackPromptConfig.DelaySeconds)

			for _ = 1, 6 do
				if cancelled then
					return
				end

				local currentStats = GlobalState:getState().Stats[playerId]
				if not FeedbackPromptController.canAutoPrompt(currentStats) then
					return
				end

				local busy = false
				if FeedbackPromptConfig.DeferWhileBusy then
					local state = GlobalState:getState()
					busy = UIState:getState().panel ~= "none" or hasActiveCustomer(state.Customers[playerId])
				end

				if not busy then
					FeedbackPromptController.request()
					return
				end

				task.wait(10)
			end
		end)

		return function()
			cancelled = true
		end
	end, { stats and stats.Level, stats and stats.TutorialCompleted, stats and stats.FeedbackPromptedAt })

	return nil
end

return FeedbackPrompt
