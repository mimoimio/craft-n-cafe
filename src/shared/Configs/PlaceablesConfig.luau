-- Shared/Configs/PlaceablesConfig.luau
return {
	-- [[ INFRASTRUCTURE ]]
	{
		Id = "Wall_Brick",
		DisplayName = "Brick Wall",
		Category = "Architecture",
		Price = 25,
		UnlockLevel = 1,
		MaxAllowed = math.huge,
	},
	{
		Id = "Counter_Wood",
		DisplayName = "Wooden Counter",
		Category = "Surface",
		Price = 100,
		UnlockLevel = 1,
		MaxAllowed = math.huge,
	},

	-- [[ FUNCTIONAL ]]
	{
		Id = "Cashier_Basic",
		DisplayName = "Basic Register",
		Category = "Cashier",
		Price = 250,
		UnlockLevel = 1,
		MaxAllowed = 1, -- Limit 1 at Level 1
	},

	-- [[ STATIONS ]]
	{
		Id = "cup_station",
		DisplayName = "Cup Stack",
		Category = "Station",
		Price = 0,
		UnlockLevel = 1,
		MaxAllowed = 1,
	},
	{
		Id = "trash_station",
		DisplayName = "Trash Bin",
		Category = "Station",
		Price = 0,
		UnlockLevel = 1,
		MaxAllowed = 1,
	},
	{
		Id = "espresso_station",
		DisplayName = "Espresso Machine",
		Category = "Station",
		Price = 500,
		UnlockLevel = 1,
		MaxAllowed = 1,
	},
	{
		Id = "water_station",
		DisplayName = "Hot Water Dispenser",
		Category = "Station",
		Price = 600,
		UnlockLevel = 1,
		MaxAllowed = 1,
	},
	{
		Id = "milk_station",
		DisplayName = "Milk Pitcher",
		Category = "Station",
		Price = 1200,
		UnlockLevel = 2, -- Unlocks at Level 2!
		MaxAllowed = 1,
	},
	{
		Id = "ice_station",
		DisplayName = "Ice Bin",
		Category = "Station",
		Price = 2500,
		UnlockLevel = 3,
		MaxAllowed = 1,
	},
}
