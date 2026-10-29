local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)

local ReportsDataStore = DataStoreService:GetDataStore("Moderation_Reports_Data_v1")
local ReportsIndexQueue = DataStoreService:GetOrderedDataStore("Moderation_Queue_Index_v1")

local ModerationService = {}
local cooldowns = {}
local REPORT_COOLDOWN = 60

-- REQUIRED: Replace with your actual Admin/Mod UserIds or Group Rank checks!
local MODERATOR_USER_IDS = {
	["MockUser"] = true,
	-- ["12345678"] = true,
}

function ModerationService.initialize()
	-- [[ EXISTING SUBMIT CODE ]]
	Remotes.SubmitReport.OnServerEvent:Connect(function(reporter, reportedUserId, reason, comment)
		local reporterId = tostring(reporter.UserId)
		local lastReportTime = cooldowns[reporterId] or 0
		if os.time() - lastReportTime < REPORT_COOLDOWN then
			warn(`[Moderation] {reporter.Name} is submitting reports too quickly.`)
			return
		end
		cooldowns[reporterId] = os.time()

		local currentState = GlobalState:getState()
		local reportedPlotState = currentState.Plot[reportedUserId]

		if not reportedPlotState then
			warn(`[Moderation] Failed to capture plot state for user {reportedUserId}.`)
			return
		end

		local reportId = HttpService:GenerateGUID(false)
		local timestamp = os.time()

		local reportPayload = {
			ReportId = reportId,
			ReporterId = reporterId,
			ReportedId = reportedUserId,
			Reason = reason or "Inappropriate Build",
			Comment = comment or "",
			Timestamp = timestamp,
			PlotSnapshot = {
				grid = reportedPlotState.grid,
				placedItems = reportedPlotState.placedItems,
				spatialItems = reportedPlotState.spatialItems,
			},
		}

		task.spawn(function()
			local success, err = pcall(function()
				ReportsDataStore:SetAsync("Report_" .. reportId, reportPayload)
				ReportsIndexQueue:SetAsync("Report_" .. reportId, timestamp)
			end)
			if success then
				print(`[Moderation] Successfully saved report {reportId} against {reportedUserId}`)
			else
				warn(`[Moderation] Failed to save report {reportId}: {err}`)
			end
		end)
	end)

	-- [[ NEW FETCH CODE FOR MODERATORS ]]
	Remotes.FetchReports.OnServerInvoke = function(player, limit)
		-- Security Check
		if not MODERATOR_USER_IDS[tostring(player.UserId)] then
			warn(`[Moderation] Unauthorized access attempt by {player.Name}`)
			return {}
		end

		local count = math.clamp(limit or 20, 1, 50)
		local reports = {}

		local success, pages = pcall(function()
			-- false = descending (newest first)
			return ReportsIndexQueue:GetSortedAsync(false, count)
		end)

		if not success or not pages then
			warn("[Moderation] Failed to fetch report index.")
			return {}
		end

		local currentPage = pages:GetCurrentPage()
		for _, entry in ipairs(currentPage) do
			local reportKey = entry.key

			-- Fetch the actual heavy payload
			local payloadSuccess, payload = pcall(function()
				return ReportsDataStore:GetAsync(reportKey)
			end)

			if payloadSuccess and payload then
				table.insert(reports, payload)
			end
		end

		return reports
	end

	Players.PlayerRemoving:Connect(function(player)
		cooldowns[tostring(player.UserId)] = nil
	end)
end

return ModerationService
