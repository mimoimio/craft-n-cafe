-- Shared/ReactComponents/ShopPanel/ShopTabConfig.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)

local ShopTabConfig = {}

ShopTabConfig.Tabs = {
	{ id = "item", label = "Items", level = 1 },
	{ id = "upgrade", label = "Upgrades", level = 4 },
	{ id = "staff", label = "Workers", level = 4 },
	{ id = "premium", label = "Premium", level = 1 },
}

-- The item tab's sub-tabs map one-to-one to raw placeable categories.
-- Order is fixed for stations then registers; the rest keep a stable order too.
ShopTabConfig.ItemSubTabs = {
	"Station",
	"Cashier",
	"Furniture",
	"Seat",
	"Wall",
	"Architecture",
	"Decoration",
}

ShopTabConfig.CategoryLabels = {
	Station = "Stations",
	Cashier = "Registers",
	Furniture = "Furniture",
	Seat = "Seats",
	Wall = "Walls",
	Architecture = "Architecture",
	Decoration = "Decor",
}

-- Kept for compatibility with any other callers. The item tab now exposes
-- every raw category through ShopTabConfig.ItemSubTabs instead.
ShopTabConfig.Categories = {
	item = {
		Station = true,
		Cashier = true,
		Furniture = true,
		Seat = true,
		Wall = true,
		Architecture = true,
		Decoration = true,
	},
}

ShopTabConfig.ItemTabs = {
	item = true,
}

function ShopTabConfig.isItemTab(tab: string): boolean
	return ShopTabConfig.ItemTabs[tab] == true
end

function ShopTabConfig.getCategoryLabel(category: string): string
	return ShopTabConfig.CategoryLabels[category] or category
end

function ShopTabConfig.getItemSubTabs(): { string }
	return ShopTabConfig.ItemSubTabs
end

function ShopTabConfig.getDefaultItemSubTab(): string
	return ShopTabConfig.ItemSubTabs[1]
end

function ShopTabConfig.getCategoriesForTab(tab: string): { string }
	local allowed = ShopTabConfig.Categories[tab] or {}
	local categories = {}

	for category in pairs(PlaceablesModule.Categories) do
		if allowed[category] then
			table.insert(categories, category)
		end
	end

	table.sort(categories)
	return categories
end

return ShopTabConfig
