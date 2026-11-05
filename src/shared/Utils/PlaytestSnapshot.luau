-- Shared/Utils/PlaytestSnapshot.luau
-- Lightweight progression snapshot for playtest CSV logging.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IngredientsConfig = require(ReplicatedStorage.Shared.Configs.IngredientsConfig)
local LevelConfig = require(ReplicatedStorage.Shared.Configs.LevelConfig)
local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)

local PlaytestSnapshot = {}

local INGREDIENT_INDEX = {}
for index, ingredient in ipairs(IngredientsConfig) do
	INGREDIENT_INDEX[ingredient.Id] = index
end

local COLUMNS = {
	"session_id",
	"timestamp",
	"elapsed_s",
	"player_id",
	"variant",
	"cash",
	"lifetime_cash",
	"income_delta",
	"spend_delta",
	"cash_delta",
	"cash_per_s",
	"cash_per_min",
	"exp",
	"level",
	"exp_delta",
	"exp_per_s",
	"exp_to_next_level",
	"customers_served",
	"tutorial_completed",
	"plot_size",
	"cashier_count",
	"station_total_placed",
	"station_total_inventory",
	"ingredient_progress_index",
	"worker_count",
	"workers",
	"upgrades",
	"owned_passes",
	"purchased_products",
	"has_double_cash",
	"has_premium_paint",
}

local function round(value: number, places: number): number
	local factor = 10 ^ places
	return math.floor(value * factor + 0.5) / factor
end

local function sortedKeys(map: { [string]: any }?): { string }
	local keys = {}
	for key in pairs(map or {}) do
		table.insert(keys, key)
	end
	table.sort(keys)
	return keys
end

local function joinKeys(map: { [string]: boolean }?): string
	local keys = {}
	for key, enabled in pairs(map or {}) do
		if enabled then
			table.insert(keys, key)
		end
	end
	table.sort(keys)
	return table.concat(keys, ";")
end

local function getIngredientStationIndex(itemId: string?): number?
	local ingredientId = string.match(itemId or "", "^(.+)_station$")
	if ingredientId then
		return INGREDIENT_INDEX[ingredientId]
	end
	return nil
end

local function isStation(itemId: string): boolean
	local config = PlaceablesModule.GetConfig(itemId)
	return config and config.Category == "Station" or false
end

local function isCashier(itemId: string): boolean
	local config = PlaceablesModule.GetConfig(itemId)
	return config and config.Category == "Cashier" or false
end

local function getWorkersString(workers: { any }?): string
	local entries = {}

	for _, worker in ipairs(workers or {}) do
		table.insert(
			entries,
			table.concat({
				tostring(worker.id or "?"),
				tostring(worker.action or "idle"),
				`{worker.walkSpeedLevel or 1}/{worker.craftSpeedLevel or 1}/{worker.qualityLevel or 1}`,
				tostring(worker.assignedCustomerUid or ""),
			}, "|")
		)
	end

	return table.concat(entries, ";")
end

local function getUpgradesString(upgrades: { [string]: number }?): string
	local entries = {}
	for _, upgradeId in ipairs(sortedKeys(upgrades)) do
		local level = upgrades[upgradeId] or 0
		if level > 0 then
			table.insert(entries, `{upgradeId}={level}`)
		end
	end
	return table.concat(entries, ";")
end

local function csvValue(value: any): string
	if type(value) == "number" then
		return tostring(value)
	end
	if type(value) == "boolean" then
		return value and "true" or "false"
	end

	local text = tostring(value or "")
	if text:find('[,"\r\n]') then
		return `"{text:gsub('"', '""')}"`
	end
	return text
end

function PlaytestSnapshot.GetHeader(): string
	return table.concat(COLUMNS, ",")
end

function PlaytestSnapshot.BuildRow(
	state: any,
	playerId: string,
	sessionId: string,
	variant: string,
	startedAt: number,
	previousRow: any?
): { [string]: any }
	local stats = state.Stats and state.Stats[playerId] or {}
	local plot = state.Plot and state.Plot[playerId] or {}
	local inventory = state.Inventory and state.Inventory[playerId] or {}
	local workers = state.Workers and state.Workers[playerId] or {}
	local upgrades = stats.Upgrades or {}
	local ownedPasses = stats.OwnedGamePasses or {}
	local purchasedProducts = stats.PurchasedProducts or {}

	local stationTotalPlaced = 0
	local stationTotalInventory = 0
	local cashierCount = 0
	local ingredientProgressIndex = 0

	for itemId, count in pairs(inventory) do
		if count > 0 and isStation(itemId) then
			stationTotalInventory += count
			ingredientProgressIndex = math.max(ingredientProgressIndex, getIngredientStationIndex(itemId) or 0)
		end
	end

	local function countPlacedItem(itemId: string?)
		if not itemId then
			return
		end
		if isStation(itemId) then
			stationTotalPlaced += 1
			ingredientProgressIndex = math.max(ingredientProgressIndex, getIngredientStationIndex(itemId) or 0)
		end
		if isCashier(itemId) then
			cashierCount += 1
		end
	end

	for _, item in pairs(plot.placedItems or {}) do
		countPlacedItem(item.id)
	end
	for _, item in pairs(plot.spatialItems or {}) do
		countPlacedItem(item.id)
	end

	local cash = stats.Cash or 0
	local lifetimeCash = stats.LifetimeCash or 0
	local exp = stats.EXP or 0
	local level = stats.Level or 1
	local elapsed = workspace:GetServerTimeNow() - startedAt
	local cashDelta = if previousRow then cash - (previousRow.cash or 0) else 0
	local incomeDelta = if previousRow then lifetimeCash - (previousRow.lifetime_cash or 0) else 0
	local spendDelta = incomeDelta - cashDelta
	local expDelta = if previousRow then exp - (previousRow.exp or 0) else 0
	local seconds = if previousRow then elapsed - (previousRow.elapsed_s or elapsed) else 0
	local expToNext = math.max(0, LevelConfig.GetExpOnLevel(level) - exp)

	return {
		session_id = sessionId,
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", os.time()),
		elapsed_s = round(elapsed, 2),
		player_id = playerId,
		variant = variant,

		cash = cash,
		lifetime_cash = lifetimeCash,
		income_delta = incomeDelta,
		spend_delta = spendDelta,
		cash_delta = cashDelta,
		cash_per_s = seconds > 0 and round(cashDelta / seconds, 3) or 0,
		cash_per_min = elapsed > 0 and round(lifetimeCash / (elapsed / 60), 1) or 0,
		exp = exp,
		level = level,
		exp_delta = expDelta,
		exp_per_s = seconds > 0 and round(expDelta / seconds, 3) or 0,
		exp_to_next_level = expToNext,
		customers_served = stats.CustomersServed or 0,
		tutorial_completed = stats.TutorialCompleted == true,

		plot_size = plot.plotSize or 0,
		cashier_count = cashierCount,
		station_total_placed = stationTotalPlaced,
		station_total_inventory = stationTotalInventory,
		ingredient_progress_index = ingredientProgressIndex,

		worker_count = #workers,
		workers = getWorkersString(workers),
		upgrades = getUpgradesString(upgrades),
		owned_passes = joinKeys(ownedPasses),
		purchased_products = joinKeys(purchasedProducts),
		has_double_cash = ownedPasses.DoubleCash == true,
		has_premium_paint = ownedPasses.PremiumPaint == true,
	}
end

function PlaytestSnapshot.ToCsv(rows: { { [string]: any } }): string
	local lines = { PlaytestSnapshot.GetHeader() }

	for _, row in ipairs(rows) do
		local values = {}
		for index, column in ipairs(COLUMNS) do
			values[index] = csvValue(row[column])
		end
		table.insert(lines, table.concat(values, ","))
	end

	return table.concat(lines, "\n")
end

return PlaytestSnapshot
