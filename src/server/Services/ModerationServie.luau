local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)

-- Dual DataStore Setup
-- 1. Stores the heavy snapshot data
local ReportsDataStore = DataStoreService:GetDataStore("Moderation_Reports_Data_v1")
-- 2. Stores just the timestamp to allow fetching the "latest 50 reports"
local ReportsIndexQueue = DataStoreService:GetOrderedDataStore("Moderation_Queue_Index_v1")

local ModerationService = {}

-- Anti-spam dictionary (UserIds mapped to last report timestamp)
local cooldowns = {}
local REPORT_COOLDOWN = 60 -- 1 minute between reports

function ModerationService.initialize()
	Remotes.SubmitReport.OnServerEvent:Connect(function(reporter, reportedUserId, reason, comment)
		local reporterId = tostring(reporter.UserId)

		-- 1. Anti-Spam Check
		local lastReportTime = cooldowns[reporterId] or 0
		if os.time() - lastReportTime < REPORT_COOLDOWN then
			warn(`[Moderation] {reporter.Name} is submitting reports too quickly.`)
			return
		end
		cooldowns[reporterId] = os.time()

		-- 2. Fetch the Plot Snapshot from Reflex State
		local currentState = GlobalState:getState()
		local reportedPlotState = currentState.Plot[reportedUserId]

		if not reportedPlotState then
			warn(`[Moderation] Failed to capture plot state for user {reportedUserId}.`)
			return
		end

		-- 3. Construct the Payload
		local reportId = HttpService:GenerateGUID(false)
		local timestamp = os.time()

		local reportPayload = {
			ReportId = reportId,
			ReporterId = reporterId,
			ReportedId = reportedUserId,
			Reason = reason or "Inappropriate Build",
			Comment = comment or "",
			Timestamp = timestamp,

			-- The snapshot: A pure data representation of their plot at this exact moment
			PlotSnapshot = {
				grid = reportedPlotState.grid,
				placedItems = reportedPlotState.placedItems,
				spatialItems = reportedPlotState.spatialItems,
			},
		}

		-- 4. Save to DataStores (Wrapped in xpcall/pcall for safety)
		task.spawn(function()
			local success, err = pcall(function()
				-- Save the heavy payload
				ReportsDataStore:SetAsync("Report_" .. reportId, reportPayload)

				-- Save the timestamp to the OrderedDataStore for easy queuing
				ReportsIndexQueue:SetAsync("Report_" .. reportId, timestamp)
			end)

			if success then
				print(`[Moderation] Successfully saved report {reportId} against {reportedUserId}`)
			else
				warn(`[Moderation] Failed to save report {reportId}: {err}`)
			end
		end)
	end)

	-- Cleanup cooldowns when players leave
	Players.PlayerRemoving:Connect(function(player)
		cooldowns[tostring(player.UserId)] = nil
	end)
end

return ModerationService
