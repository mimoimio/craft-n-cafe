-- Shared/Utils/DrinkValue.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local MonetizationConfig = require(ReplicatedStorage.Shared.Configs.MonetizationConfig)
local UpgradesConfig = require(ReplicatedStorage.Shared.Configs.UpgradesConfig)

local DrinkValue = {}

export type DrinkValueResult = {
	Cash: number,
	EXP: number,
	BaseCash: number,
	Complexity: number,
	CashMultiplier: number,
	Quality: number,
	IngredientCount: number,
	DrinkConfig: any?,
}

function DrinkValue.Calculate(
	cup: { drinkId: string?, score: number?, status: number? }?,
	upgrades: { [string]: number }?,
	ownedPasses: { [string]: boolean }?
): DrinkValueResult
	local drinkId = cup and cup.drinkId
	local drinkConfig = drinkId and drinkId ~= "none" and CoffeeModule.Config[drinkId] or nil

	if not drinkConfig then
		return {
			Cash = 0,
			EXP = 0,
			BaseCash = 0,
			Complexity = 1,
			CashMultiplier = 1,
			Quality = 1,
			IngredientCount = 1,
			DrinkConfig = nil,
		}
	end

	local ingredientCount = math.max(1, #(drinkConfig.Ingredients or {}))
	local complexity = math.min(1.5, 1 + 0.1 * (ingredientCount - 1))
	local boostedPrice = UpgradesConfig.CalculateDrinkPrice(drinkId, upgrades)
	local baseCash = boostedPrice * (cup.score or 0) // ingredientCount
	local cashMultiplier = MonetizationConfig.GetCashMultiplier(ownedPasses)
	local cash = math.floor(baseCash * complexity * cashMultiplier)
	local quality = cup.status or 1
	local exp = math.max(1, math.floor(quality * complexity))

	return {
		Cash = cash,
		EXP = exp,
		BaseCash = baseCash,
		Complexity = complexity,
		CashMultiplier = cashMultiplier,
		Quality = quality,
		IngredientCount = ingredientCount,
		DrinkConfig = drinkConfig,
	}
end

return DrinkValue
