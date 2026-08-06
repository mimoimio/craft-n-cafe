-- DailyService.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local ShopCycle = require(ReplicatedStorage.Shared.ShopCycle)
local DailyConfig = require(ReplicatedStorage.Shared.Configs.DailyConfig)

local DailyService = {}

function DailyService.ClaimDaily(player: Player)
	local playerId = tostring(player.UserId)
	local state = GlobalState:getState()
	local daily = state.Daily[playerId]
	if not daily then
		return
	end
	local currentShop = ShopCycle.getCurrentState()
	if daily.lastClaimedDaily and daily.lastClaimedDaily >= currentShop.today then
		print("already claimed today")
		return
	end
	local day = daily.day
	local lastClaimed = currentShop.today
	local rewardIngredients = DailyConfig[day] or {}
	if type(rewardIngredients) ~= "table" then
		rewardIngredients = {}
	end

	GlobalState.claimDailyReward(playerId, {
		nextDay = day + 1,
		lastClaimedDaily = lastClaimed,
		ingredients = rewardIngredients,
	})
end

function DailyService.initialize()
	Remotes.ClaimDaily.OnServerEvent:Connect(DailyService.ClaimDaily)

	-- Spin up a background thread to watch for day changes!
	task.spawn(function()
		local currentDay = nil

		while true do
			local activeCycle = ShopCycle.getCurrentState()
			local newDay = activeCycle.today

			if currentDay ~= newDay then
				if currentDay ~= nil then
					-- The day has changed! Let's update all active players
					print(`Day cycle advanced! Pushing new day ({newDay}) to daily slices.`)

					local state = GlobalState:getState()

					for playerId, _ in state.Daily do
						GlobalState.updateDailyDay(playerId, newDay)
					end
				end

				-- Update our tracker
				currentDay = newDay
			end

			-- Check every second
			task.wait(1)
		end
	end)
end

return DailyService
