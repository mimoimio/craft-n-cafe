-- Shared/Configs/UpgradesConfig.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)

export type UpgradeEntry = {
	Id: string,
	Category: "Global" | "Ingredient",
	DisplayName: string,
	Description: (level: number) -> string,
	MaxLevel: number,
	UnlockLevel: number,
	IngredientId: string?,
	GetCost: (nextLevel: number) -> number,
	GetBonus: (level: number) -> number,
}

local UpgradesConfig = {}
UpgradesConfig.Config = {} :: { [string]: UpgradeEntry }
UpgradesConfig.Array = {} :: { UpgradeEntry }

-- 1. Generic Price Multiplier (+15% total drink value per level)
local genericPriceUpgrade: UpgradeEntry = {
	Id = "generic_price",
	Category = "Global",
	DisplayName = "Brand Prestige",
	MaxLevel = 10,
	UnlockLevel = 4,
	Description = function(level: number)
		local pct = level * 50
		return `Sale bonus +{pct}%`
	end,
	GetCost = function(nextLevel: number)
		return math.floor(400 * (1.1 ^ (nextLevel - 1)))
	end,
	GetBonus = function(level: number)
		return 1 + (level * 0.50) -- Multiplier: 1.00, 1.15, 1.30...
	end,
}

UpgradesConfig.Config[genericPriceUpgrade.Id] = genericPriceUpgrade
table.insert(UpgradesConfig.Array, genericPriceUpgrade)

-- 2. Ingredient Value Upgrades (Generated automatically for each ingredient in CoffeeModule)
for _, ingConfig in ipairs(CoffeeModule.IngredientConfigs or {}) do
	local upgradeId = "ingredient_" .. ingConfig.Id
	local basePrice = math.max(ingConfig.Price or 5, 1)
	local bonusPerLevel = math.max(math.ceil(basePrice * 0.25), 2)

	local ingUpgrade: UpgradeEntry = {
		Id = upgradeId,
		Category = "Ingredient",
		IngredientId = ingConfig.Id,
		DisplayName = `{ingConfig.DisplayName}`,
		MaxLevel = 5,
		UnlockLevel = 4,
		Description = function(level: number)
			local totalBonus = level * bonusPerLevel
			-- return `+${totalBonus} value per {ingConfig.DisplayName} used (Base: ${basePrice})`
			return `{ingConfig.DisplayName} lvl {level}`
		end,
		GetCost = function(nextLevel: number)
			return math.floor((basePrice * 50) * (1.7 ^ (nextLevel - 1)))
		end,
		GetBonus = function(level: number)
			return level * bonusPerLevel
		end,
	}

	UpgradesConfig.Config[upgradeId] = ingUpgrade
	table.insert(UpgradesConfig.Array, ingUpgrade)
end

function UpgradesConfig.GetConfig(upgradeId: string): UpgradeEntry?
	return UpgradesConfig.Config[upgradeId]
end

-- Calculates the total price of a drink factoring in Ingredient Upgrades and Brand Prestige
function UpgradesConfig.CalculateDrinkPrice(drinkId: string, upgrades: { [string]: number }?): number
	local drinkConfig = CoffeeModule.Config[drinkId]
	if not drinkConfig then
		return 0
	end

	local upg = upgrades or {}
	local totalPrice = drinkConfig.Price or 0

	if drinkConfig.Ingredients then
		for _, ingId in ipairs(drinkConfig.Ingredients) do
			local upgradeId = "ingredient_" .. ingId
			local lvl = upg[upgradeId] or 0
			if lvl > 0 then
				local cfg = UpgradesConfig.Config[upgradeId]
				if cfg then
					totalPrice += cfg.GetBonus(lvl)
				end
			end
		end
	end

	local genericLvl = upg["generic_price"] or 0
	if genericLvl > 0 then
		local genericCfg = UpgradesConfig.Config["generic_price"]
		if genericCfg then
			totalPrice = math.floor(totalPrice * genericCfg.GetBonus(genericLvl))
		end
	end

	return totalPrice
end

return UpgradesConfig
