-- Shared/Types.luau
--v1
export type PlayerData = {
	Stats: StatsEntity,
	Tables: { [string]: TableEntity },
	Drinks: { DrinkEntity },
	Mixers: { [string]: MixerEntity },
	Ingredients: { [string]: number },
	Customers: { CustomerEntity },
}
export type PlayerId = string
-- Stats
export type StatsEntity = {
	Cash: number,
	Sfx: number,
	Music: number,
	SecondsPlayed: number,
	Level: number,
	CustomerSpawningEnabled: boolean, -- New Toggle for Tutorial
	UnlockedIngredients: { string },
	DiscoveredDrinks: { [string]: string },
}

-- Tables
export type TableEntity = {
	TableId: string,
	Slots: {
		Slot1: string,
		Slot2: string,
		Slot3: string,
		Slot4: string,
	},
}

-- Drinks
export type DrinkEntity = {
	id: string,
	stock: number,
	drinkId: string,
}
export type DrinksState = { [string]: { DrinkEntity } }

-- Unlocked Ingredients
export type UnlockedIngredientsState = {
	[PlayerId]: { string },
}

-- Shop
export type ShopCycle = {
	seed: string,
	position: string,
	isSpecial: string,
	timeLeft: string,
	timeToSpecial: string,
}
export type Seed = string
export type ShopEntity = {
	[string]: number,
}
export type ShopState = {
	[PlayerId]: {
		currentSeed: string,
		shops: {
			[Seed]: ShopEntity,
		},
	},
}

-- DiscoveredDrinksState
export type DiscoveredDrinksState = {
	[PlayerId]: {
		[string]: true,
	},
}
-- Ingredients
export type IngredientsState = {
	[PlayerId]: {
		[string]: number,
	},
}

-- Mixers
export type MixerEntity = {
	drinkId: string,
	startTime: number?,
}
export type MixersState = {
	[PlayerId]: {
		[string]: MixerEntity,
	},
}

-- Customers
export type CustomerEntity = {
	id: string,
	customerId: string?,
	drinkIds: { string }?,
	customerAction: string,
	actionStartTime: number, -- FSM Timestamp tracker
}
export type CustomersState = {
	[PlayerId]: {
		[string]: CustomerEntity,
	},
}

-- action payloads
export type AddIngredientPayload = {
	ingredientId: string,
	score: number,
}
export type MixDrinkPayload = {
	drinkId: string,
	ingredients: { string },
	mixer: string,
	startTime: number,
}
export type LevelUpPayload = {
	level: number,
	cost: number,
	unlockedTables: { string },
	unlockedIngredients: { string },
	unlockedMixers: { string },
}
export type BuyIngredientBulkPayload = {
	ingredients: { [string]: number },
	price: number,
}
export type PickUpPayload = {
	id: string,
	drinkId: string,
	stock: number,
	mixer: string,
}
export type CustomerItemPayload = {
	customerUid: string,
	drinksDeducted: {
		[string]: number,
	},
	drinkIds: { string },
	depletedDrinks: { [string]: boolean },
	timestamp: number, -- Added to pass workspace:GetServerTimeNow() purely
}
export type SpawnCustomerPayload = {
	customerUid: string,
	customerId: string,
	timestamp: number, -- Added
}
export type PlaceDrinkPayload = {
	tableUid: string,
	slot: string,
	drinkUid: string,
}
export type StartPlayerSessionPayload = {
	newestShop: ShopEntity,
	newestSeed: string,
}
export type RefreshShopPayload = {
	newestShop: ShopEntity,
	newestSeed: string,
}
export type BuyIngredientPayload = {
	ingredientId: string,
	amount: number,
	cost: number,
	seed: string,
}
export type CombinedActions = {
	startPlayerSession: (playerId: PlayerId, data: PlayerData, payload: StartPlayerSessionPayload) -> (),
	endPlayerSession: (playerId: PlayerId) -> (),
	mixDrink: (playerId: PlayerId, payload: MixDrinkPayload) -> (),
	buyIngredient: (playerId: PlayerId, payload: BuyIngredientPayload) -> (),
	buyIngredientBulk: (playerId: PlayerId, payload: BuyIngredientBulkPayload) -> (),
	refreshShop: (playerId: PlayerId, payload: RefreshShopPayload) -> (),
	pickUpDrinkFromMixer: (playerId: PlayerId, payload: PickUpPayload) -> (),

	placeDrinkToTableSlot: (
		playerId: PlayerId,
		payload: {
			drinkUid: string?,
			table: string,
			slot: string,
		}
	) -> (),

	levelUp: (playerId: PlayerId, payload: {
		Level: number,
	}) -> (),

	-- Added toggle action for your tutorial
	toggleCustomerSpawning: (playerId: PlayerId, enabled: boolean) -> (),

	spawnCustomer: (playerId: PlayerId, payload: SpawnCustomerPayload) -> (),
	customerTakeItems: (playerId: PlayerId, payload: CustomerItemPayload) -> (),

	playerReceivePayment: (
		playerId: PlayerId,
		payload: {
			customerUid: string,
			Cash: number,
			timestamp: number, -- Added
		}
	) -> (),

	removeCustomer: (playerId: PlayerId, uid: string) -> (),
}

--Coffee Modules
export type CoffeeModule = {
	IngredientLookup: { [string]: IngredientConfig },
	IngredientConfigs: { IngredientConfig },
	Config: { [string]: CoffeeConfigType },
	Array: { CoffeeConfigType },

	Craft: ({ string }) -> CoffeeConfigType?,
	GetId: ({ string }) -> string,
}
export type CoffeeConfigType = {
	Id: string,
	DisplayName: string,
	Cost: number, -- to buy the ingredient
	Ingredients: { string }?,
	RecipePath: { string }?, -- sorted at config initialization
	Instruction: string?, -- Readable
	Image: string?,
	Price: number, -- when selling
	Duration: number,
	InitialStock: number,
}
export type IngredientConfig = {
	Id: string,
	DisplayName: string,
	Cost: number,
	ItemTip: string,
	Image: string?,
}

return {}
