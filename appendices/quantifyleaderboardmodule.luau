local Useful = require(game.ReplicatedStorage.Shared.Useful)
local HumanoidHandler = require(game.ServerScriptService.Server.Modules.HumanoidHandler)
local DataModule = require(game.ServerScriptService.Server.Modules.Data)

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local module = {}
module.Leaderboards = {}
module.LeaderboardsDaily = {}
module.ValuePrefixes = {
	Donations = "R$ ",
	CashGenerated = "$ ",
	HighestRound = "Round ",

	HighestRoundDaily = "Round ",
	CashGeneratedDaily = "$ ",
}
module.ValueProfixes = {
	Wins = " Wins",
	WinsDaily = " Wins",
}

for _, v in pairs(workspace.Leaderboards:GetChildren()) do
	if v:IsA("Model") then
		module.Leaderboards[v.Name] = DataStoreService:GetOrderedDataStore(v.Name)
	end
end

local bodyDefaults = {
	BodyDepthScale = 1,
	BodyHeightScale = 1,
	BodyProportionScale = 0.5,
	BodyTypeScale = 0,
	BodyWidthScale = 1,
	HeadScale = 1,
}

local function updateLeaderboard(leaderboard, updatePodium)
	local success, err = pcall(function()
		--warn('updateLeaderboard', leaderboard)
		local actualName
		local LB = DataStoreService:GetOrderedDataStore(leaderboard)
		local LBfolder
		if not string.find(leaderboard, "_") then
			actualName = leaderboard
			LBfolder = workspace.Leaderboards:WaitForChild(actualName)
		else
			actualName = string.split(leaderboard, "_")[1]
			LBfolder = workspace.LeaderboardsDaily:WaitForChild(actualName)
		end

		local Data = LB:GetSortedAsync(false, 50)
		local page = Data:GetCurrentPage()

		local model = LBfolder:WaitForChild("Leaderboard")
		local podium = LBfolder:WaitForChild("Podium")

		local ui = model.Main.SurfaceGui
		for _, frame in pairs(ui.Holder:GetChildren()) do
			if frame:IsA("Frame") then
				frame:Destroy()
			end
		end

		task.wait(5)

		--warn('page', page)

		for rank, data in ipairs(page) do
			local username = game.Players:GetNameFromUserIdAsync(tonumber(data.key))
			local value = data.value

			local temp = workspace.Leaderboards.Template:Clone()
			temp.Parent = LBfolder.Leaderboard.Main.SurfaceGui.Holder
			temp.Rank.Text = rank
			temp.Username.Text = username
			temp.Val.Text = Useful.formatNumber(value)
			if module.ValuePrefixes[actualName] then
				temp.Val.Text = module.ValuePrefixes[actualName] .. temp.Val.Text
			end
			if module.ValueProfixes[actualName] then
				temp.Val.Text = temp.Val.Text .. module.ValueProfixes[actualName]
			end

			local thumbnailType = Enum.ThumbnailType.HeadShot -- or AvatarBust, AvatarThumbnail
			local thumbnailSize = Enum.ThumbnailSize.Size420x420

			local thumbnailUrl = Players:GetUserThumbnailAsync(data.key, thumbnailType, thumbnailSize)
			temp.ImageLabel.Image = thumbnailUrl
			task.wait()
		end

		if updatePodium then
			local currentPage = LB:GetSortedAsync(false, 1):GetCurrentPage()
			if currentPage[1] then
				local id = currentPage[1].key
				local dummy = podium:WaitForChild("Dummy")
				dummy.Humanoid:ApplyDescription(game.Players:GetHumanoidDescriptionFromUserId(id))
				dummy.Humanoid.DisplayName = game.Players:GetNameFromUserIdAsync(id)

				for x, y in pairs(bodyDefaults) do
					dummy.Humanoid[x].Value = y
				end
			end
		end
	end)

	if not success then
		warn(err)
	end
end

task.spawn(function()
	warn("running leaderboard")
	task.wait(5)

	local UPDATE_INTERVAL = 300 -- Update every 5 minutes (300 seconds)

	while true do
		warn("Updating leaderboards...")

		-- Update regular leaderboards
		for leaderboardName, _ in pairs(module.Leaderboards) do
			task.spawn(function()
				updateLeaderboard(leaderboardName, true)
			end)
		end

		-- Update daily leaderboards
		local LBs = { "HighestRound", "CashGenerated", "Wins" }
		for _, leaderboardName in pairs(LBs) do
			task.spawn(function()
				local key = DataModule.GetTodayKey(leaderboardName)
				warn("Updating daily leaderboard:", key)
				updateLeaderboard(key, true)
			end)
		end

		task.wait(UPDATE_INTERVAL)
	end
end)

return module
