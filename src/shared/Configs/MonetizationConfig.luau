-- Shared/Configs/MonetizationConfig.luau
-- All Robux product IDs live here. Fill the placeholder 0s after creating the
-- passes/products on the Roblox Creator Dashboard.

export type GamePassConfig = {
	Key: string,
	DisplayName: string,
	Description: string,
	PassId: number,
	PriceHint: number,
	Icon: string?,
}

export type CashProductConfig = {
	Key: string,
	DisplayName: string,
	Description: string,
	ProductId: number,
	Cash: number,
	PriceHint: number,
	Icon: string?,
	BestValue: boolean?,
}

export type StarterProductConfig = {
	Key: string,
	DisplayName: string,
	Description: string,
	ProductId: number,
	Cash: number,
	Items: { string },
	PriceHint: number,
	Icon: string?,
}

local MonetizationConfig = {}

MonetizationConfig.Enabled = true

MonetizationConfig.GamePasses = {
	DoubleCash = {
		Key = "DoubleCash",
		DisplayName = "2x Cash",
		Description = "Earn double cash from every customer, forever.",
		PassId = 0,
		PriceHint = 299,
		Icon = "rbxassetid://15402844695",
	},
	PremiumPaint = {
		Key = "PremiumPaint",
		DisplayName = "Premium Paint",
		Description = "Unlock the full paint palette for your cafe.",
		PassId = 0,
		PriceHint = 99,
		Icon = "rbxassetid://103478691850846",
	},
} :: { [string]: GamePassConfig }

MonetizationConfig.CashProducts = {
	{
		Key = "PocketChange",
		DisplayName = "Pocket Change",
		Description = "A small boost for the next upgrade.",
		ProductId = 0,
		Cash = 2000,
		PriceHint = 49,
	},
	{
		Key = "CafeFund",
		DisplayName = "Cafe Fund",
		Description = "Enough to hire help or expand your menu.",
		ProductId = 0,
		Cash = 10000,
		PriceHint = 199,
		BestValue = true,
	},
	{
		Key = "Investor",
		DisplayName = "Investor",
		Description = "A serious boost for a growing cafe.",
		ProductId = 0,
		Cash = 50000,
		PriceHint = 699,
	},
} :: { CashProductConfig }

MonetizationConfig.StarterProduct = {
	Key = "OpeningDayPack",
	DisplayName = "Opening Day Pack",
	Description = "Cash plus the starter stations and register for a head start.",
	ProductId = 0,
	Cash = 8000,
	Items = {
		"cup_station",
		"water_station",
		"espresso_station",
		"milk_station",
		"trash_station",
		"Cashier",
	},
	PriceHint = 199,
	Icon = "rbxassetid://15402844695",
} :: StarterProductConfig

function MonetizationConfig.IsConfigured(id: number?): boolean
	return type(id) == "number" and id > 0
end

function MonetizationConfig.GetGamePass(key: string): GamePassConfig?
	return MonetizationConfig.GamePasses[key]
end

function MonetizationConfig.GetGamePassByProductId(passId: number): GamePassConfig?
	if not MonetizationConfig.IsConfigured(passId) then
		return nil
	end
	for _, pass in pairs(MonetizationConfig.GamePasses) do
		if pass.PassId == passId then
			return pass
		end
	end
	return nil
end

function MonetizationConfig.GetCashProductByProductId(productId: number): CashProductConfig?
	if not MonetizationConfig.IsConfigured(productId) then
		return nil
	end
	for _, product in ipairs(MonetizationConfig.CashProducts) do
		if product.ProductId == productId then
			return product
		end
	end
	return nil
end

function MonetizationConfig.IsStarterProduct(productId: number): boolean
	return MonetizationConfig.IsConfigured(MonetizationConfig.StarterProduct.ProductId)
		and MonetizationConfig.StarterProduct.ProductId == productId
end

function MonetizationConfig.GetCashMultiplier(ownedPasses: { [string]: boolean }?): number
	local passes = ownedPasses or {}
	return passes.DoubleCash and 2 or 1
end

return MonetizationConfig
