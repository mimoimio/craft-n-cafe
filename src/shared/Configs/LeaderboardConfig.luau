local LeaderboardConfig = {}

LeaderboardConfig.RefreshSeconds = 60
LeaderboardConfig.CacheSeconds = 60
LeaderboardConfig.PageSize = 100
LeaderboardConfig.DisplayCount = 10

LeaderboardConfig.Boards = {
	PerfectCups = {
		DisplayName = "Perfect Cups",
		Daily = true,
		StoreBase = "DailyPerfectCups",
		StatKey = "DailyPerfectCups",
		ValueSuffix = " perfect",
	},
	Customers = {
		DisplayName = "Customers Served",
		Daily = true,
		StoreBase = "DailyCustomers",
		StatKey = "DailyPlayerCustomers",
		ValueSuffix = " served",
	},
	TimePlayed = {
		DisplayName = "Time Played",
		Daily = false,
		StoreBase = "TopTimePlayed",
		KeyPrefix = "TimePlayed",
		ValueSuffix = " min",
	},
}

LeaderboardConfig.Order = { "PerfectCups", "Customers", "TimePlayed" }

function LeaderboardConfig.GetDayKey(): string
	return os.date("!%Y-%m-%d")
end

function LeaderboardConfig.GetBoard(boardId: string)
	return LeaderboardConfig.Boards[boardId]
end

return LeaderboardConfig
