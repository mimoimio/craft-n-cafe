local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local LeaderboardConfig = require(ReplicatedStorage.Shared.Configs.LeaderboardConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local LeaderboardService = {}
LeaderboardService._connections = {}
LeaderboardService._threads = {}
LeaderboardService._cache = {}
LeaderboardService._nameCache = {}
LeaderboardService._warned = {}

local function warnOnce(key: string, message: string)
	if LeaderboardService._warned[key] then
		return
	end
	LeaderboardService._warned[key] = true
	warn(`[LeaderboardService] {message}`)
end

local function getStats(playerId: string)
	local state = GlobalState:getState()
	return state.Stats and state.Stats[playerId]
end

local function getStore(board): OrderedDataStore?
	local ok, store = pcall(function()
		if board.Daily then
			return DataStoreService:GetOrderedDataStore(`{board.StoreBase}_{LeaderboardConfig.GetDayKey()}`)
		end
		return DataStoreService:GetOrderedDataStore(board.StoreBase)
	end)

	if not ok then
		warnOnce(`store:{board.StoreBase}`, `failed to open store {board.StoreBase}: {store}`)
		return nil
	end

	return store
end

local function getDisplayName(userId: string): string
	local cached = LeaderboardService._nameCache[userId]
	if cached then
		return cached
	end

	local player = Players:GetPlayerByUserId(tonumber(userId) or 0)
	if player then
		LeaderboardService._nameCache[userId] = player.DisplayName
		return player.DisplayName
	end

	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(tonumber(userId) or 0)
	end)

	if ok and name then
		LeaderboardService._nameCache[userId] = name
		return name
	end

	local fallback = `Player {userId}`
	LeaderboardService._nameCache[userId] = fallback
	return fallback
end

local function getEntryUserId(board, key: string): string?
	if board.KeyPrefix then
		if string.sub(key, 1, #board.KeyPrefix) ~= board.KeyPrefix then
			return nil
		end
		return string.sub(key, #board.KeyPrefix + 1)
	end

	return key
end

local function buildEntries(board, page): { any }
	local entries = {}

	for rank, data in ipairs(page) do
		local userId = getEntryUserId(board, tostring(data.key))
		if userId and tonumber(userId) then
			table.insert(entries, {
				Rank = rank,
				UserId = userId,
				Value = math.floor(tonumber(data.value) or 0),
			})
		end
	end

	return entries
end

local function decorateEntries(entries: { any }): { any }
	local decorated = {}

	for index, entry in ipairs(entries) do
		if index > LeaderboardConfig.DisplayCount then
			break
		end

		table.insert(decorated, {
			Rank = entry.Rank,
			UserId = entry.UserId,
			Name = getDisplayName(entry.UserId),
			Value = entry.Value,
		})
	end

	return decorated
end

local function findYou(entries, playerId: string, fallbackValue: number)
	for _, entry in ipairs(entries) do
		if entry.UserId == playerId then
			return {
				Value = entry.Value,
				Rank = entry.Rank,
			}
		end
	end

	return {
		Value = fallbackValue,
		Rank = nil,
	}
end

function LeaderboardService.SyncDailyPlayer(player: Player)
	local playerId = tostring(player.UserId)
	local stats = getStats(playerId)
	if not stats then
		return
	end

	local todayKey = LeaderboardConfig.GetDayKey()
	if stats.DailyKey ~= todayKey then
		return
	end

	for boardId, board in pairs(LeaderboardConfig.Boards) do
		if not board.Daily or not board.StatKey then
			continue
		end

		local value = math.floor(stats[board.StatKey] or 0)
		if value <= 0 then
			continue
		end

		local store = getStore(board)
		if not store then
			continue
		end

		local ok, err = pcall(function()
			store:SetAsync(playerId, value)
		end)

		if not ok then
			warnOnce(`sync:{boardId}`, `failed to sync {boardId} for {playerId}: {err}`)
		end
	end
end

function LeaderboardService.FetchBoard(player: Player, boardId: string)
	local board = LeaderboardConfig.GetBoard(boardId)
	if not board then
		return {
			BoardId = boardId,
			DisplayName = "Unknown",
			Available = false,
			Entries = {},
			You = nil,
		}
	end

	local playerId = tostring(player.UserId)
	local stats = getStats(playerId) or {}
	local todayKey = LeaderboardConfig.GetDayKey()
	local cacheKey = if board.Daily then `{boardId}:{todayKey}` else boardId
	local cache = LeaderboardService._cache[cacheKey]
	local entries = cache and cache.Entries or nil

	if not entries or workspace:GetServerTimeNow() - cache.At > LeaderboardConfig.CacheSeconds then
		local store = getStore(board)
		local ok = false

		if store then
			ok, entries = pcall(function()
				local page = store:GetSortedAsync(false, LeaderboardConfig.PageSize):GetCurrentPage()
				return buildEntries(board, page)
			end)
		end

		if not ok or not entries then
			warnOnce(`fetch:{boardId}`, `failed to fetch {boardId}`)
			return {
				BoardId = boardId,
				DisplayName = board.DisplayName,
				Daily = board.Daily,
				Available = false,
				Entries = {},
				You = nil,
			}
		end

		LeaderboardService._cache[cacheKey] = {
			At = workspace:GetServerTimeNow(),
			Entries = entries,
		}
	end

	local fallbackValue = 0
	if board.StatKey then
		fallbackValue = math.floor(stats[board.StatKey] or 0)
	end

	local you = findYou(entries, playerId, fallbackValue)
	if you.Rank == nil and board.KeyPrefix then
		local store = getStore(board)
		if store then
			local ok, value = pcall(function()
				return store:GetAsync(board.KeyPrefix .. playerId)
			end)
			if ok and tonumber(value) then
				you.Value = math.floor(tonumber(value))
			end
		end
	end

	return {
		BoardId = boardId,
		DisplayName = board.DisplayName,
		Daily = board.Daily,
		Available = true,
		Entries = decorateEntries(entries),
		You = you,
	}
end

function LeaderboardService.initialize()
	table.insert(
		LeaderboardService._connections,
		Players.PlayerRemoving:Connect(function(player)
			LeaderboardService.SyncDailyPlayer(player)
		end)
	)

	table.insert(
		LeaderboardService._connections,
		Players.PlayerAdded:Connect(function(player)
			task.delay(30, function()
				if player.Parent then
					LeaderboardService.SyncDailyPlayer(player)
				end
			end)
		end)
	)

	table.insert(
		LeaderboardService._threads,
		task.spawn(function()
			while true do
				task.wait(LeaderboardConfig.RefreshSeconds)
				for _, player in ipairs(Players:GetPlayers()) do
					LeaderboardService.SyncDailyPlayer(player)
				end
			end
		end)
	)

	Remotes.FetchLeaderboard.OnServerInvoke = function(player: Player, boardId: string)
		return LeaderboardService.FetchBoard(player, boardId)
	end
end

function LeaderboardService.cleanup()
	for _, connection in ipairs(LeaderboardService._connections) do
		connection:Disconnect()
	end
	for _, thread in ipairs(LeaderboardService._threads) do
		pcall(task.cancel, thread)
	end
	table.clear(LeaderboardService._connections)
	table.clear(LeaderboardService._threads)
	table.clear(LeaderboardService._cache)
	table.clear(LeaderboardService._nameCache)
	table.clear(LeaderboardService._warned)
end

return LeaderboardService
