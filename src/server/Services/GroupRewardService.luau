local AnalyticsService = game:GetService("AnalyticsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local GroupRewardConfig = require(ReplicatedStorage.Shared.Configs.GroupRewardConfig)
local PlayerDataService = require(script.Parent.PlayerDataService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local GroupRewardService = {}
GroupRewardService._connections = {}

local function claimReward(player: Player): boolean
	local playerId = tostring(player.UserId)
	local profile = PlayerDataService:GetProfile(player)
	if not profile then
		return false
	end

	if profile.Data.Stats and profile.Data.Stats.GroupRewardClaimed then
		return false
	end

	local isInGroup = false
	for _ = 1, 5 do
		local ok, result = pcall(function()
			return player:IsInGroupAsync(GroupRewardConfig.GroupId)
		end)

		if ok and result then
			isInGroup = true
			break
		end

		task.wait(0.5)
	end

	if not isInGroup then
		return false
	end

	profile.Data.Stats.GroupRewardClaimed = true
	profile.Data.Stats.Cash = (profile.Data.Stats.Cash or 0) + GroupRewardConfig.Cash
	GlobalState.markGroupRewardClaimed(playerId)
	GlobalState.grantCash(playerId, {
		Cash = GroupRewardConfig.Cash,
		Source = "GroupReward",
	})

	pcall(function()
		profile:Save()
	end)

	pcall(function()
		AnalyticsService:LogCustomEvent(player, "GroupRewardClaimed", 1, {
			Cash = tostring(GroupRewardConfig.Cash),
		})
	end)

	return true
end

function GroupRewardService.initialize()
	Remotes.ClaimGroupReward.OnServerInvoke = claimReward
end

function GroupRewardService.cleanup()
	for _, connection in ipairs(GroupRewardService._connections) do
		connection:Disconnect()
	end
	table.clear(GroupRewardService._connections)
end

return GroupRewardService
