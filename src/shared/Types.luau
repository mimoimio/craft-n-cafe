-- Shared/Types.luau
--v1
export type PlayerData = {
	Stats: StatsEntity,
	Tables: { [string]: TableEntity },
	Drinks: { DrinkEntity },
	Mixers: { [string]: MixerEntity },
	Ingredients: { [string]: number },
	Customers: { CustomerEntity },
	Shelves: { [string]: ShelfEntity },
	DiscoveredDrinks: {
		[VariationId]: {
			[DrinkId]: true,
		},
	},
	Shop: {},
	Daily: {},
	Spawner: {
		TimePulled: number,
		IngredientId: string,
	},
}
export type PlayerId = string
export type VariationId = string
export type DrinkId = string

-- Shelves
export type DisplayDrink = {
	drinkId: string,
	variationId: string,
	size: number,
	lastClaimTime: number, -- NEW: Each slot tracks its own time!
}
export type ShelfEntity = {
	ShelfId: string,
	Slots: {
		[string]: DisplayDrink | "none",
	},
}
export type ShelvesState = {
	[PlayerId]: {
		[string]: ShelfEntity,
	},
}

-- Spawner
export type SpawnerState = {
	[string]: {
		TimePulled: number?,
		IngredientIds: { string }?,
	},
}

-- Stats
export type StatsEntity = {
	Cash: number,
	Sfx: number,
	TutorialCompleted: boolean,
	Music: number,
	SecondsPlayed: number,
	Level: number,
	CafeOpen: boolean,
	UnlockedIngredients: { string },
	DiscoveredDrinks: {
		[VariationId]: {
			[DrinkId]: true,
		},
	},
	RollCooldown: number,
	MaxDrinksPerCustomer: number,
	MaxCustomersAtOnce: number,
	Luck: number,
	CafeCapacity: number,
	PendingSkipMixer: string?,
	SkipTickets: number,
	OwnedGamePasses: { [string]: boolean },
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
	size: number,
	stock: number,
	drinkId: string,
	variationId: string?,
}
export type DrinksState = { [string]: { DrinkEntity } }

-- Unlocked Ingredients
export type UnlockedIngredientsState = {
	[PlayerId]: { string },
}

-- Shop
export type ShopCycle = {
	seed: number,
	today: day,
	position: number,
	isSpecial: boolean,
	timeLeft: number,
	timeToSpecial: number,
}
export type Seed = string
export type ShopEntity = {
	[string]: number,
}
export type ShopState = {
	[PlayerId]: {
		variationEvent: string?,
		currentSeed: number,
		shops: {
			[Seed]: ShopEntity,
		},
	},
}

-- DailyState
export type DailyState = {
	[PlayerId]: DailyEntity,
}
export type day = number
export type DailyEntity = {
	lastClaimedDaily: day?,
	lastClaimedRoulette: number?,
	lastClaimedShop: number?,
	day: day,
	today: day?,
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
	variationId: string?,
	size: number?,
}
export type MixersState = {
	[PlayerId]: {
		[string]: MixerEntity,
	},
}

-- Customers
export type CustomerDrink = {
	drinkId: string,
	variationId: string?,
	size: number,
}
export type CustomerEntity = {
	id: string,
	customerId: string?,
	drinkEntities: { CustomerDrink }?,
	customerAction: string,
	actionStartTime: number,
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
	size: number,
	ingredients: { string },
	mixer: string,
	startTime: number,
	variationId: string,
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
	variationId: string,
	stock: number,
	size: number,
	mixer: string,
	timestamp: number, -- NEW: Syncs the exact pickup time
}
export type CustomerItemPayload = {
	customerUid: string,
	drinksDeducted: {
		[string]: number,
	},
	drinkEntities: { CustomerDrink },
	depletedDrinks: { [string]: boolean },
	timestamp: number,
}
export type SpawnCustomerPayload = {
	customerUid: string,
	customerId: string,
	timestamp: number,
}
export type PlaceDrinkPayload = {
	tableUid: string,
	slot: string,
	drinkUid: string,
}
export type StartPlayerSessionPayload = {
	variationEvent: string?,
	newestShop: ShopEntity,
	newestSeed: number,
}
export type RefreshShopPayload = {
	variationEvent: string?,
	newestShop: ShopEntity,
	newestSeed: number,
}
export type BuyIngredientPayload = {
	ingredientId: string,
	amount: number,
	cost: number,
	seed: number,
}
export type DailyClaimPayload = {
	lastClaimedDaily: day,
	nextDay: number,
	ingredients: {
		[string]: number,
	},
}
export type RestockDrinksPayload = {
	stockToAdd: { [string]: number },
	drinksToRemove: { [string]: boolean },
}
export type RollIngredientPayload = {
	ingredientIds: { string },
	timePulled: number,
}
export type BuyIngredientFromSpawnerPayload = {
	ingredientIds: { string },
	cost: number,
	timePulled: number,
}
export type BuyMixerPayload = {
	mixerId: string,
	cost: number,
}
export type UpgradeLuckPayload = {
	increment: number,
	cost: number,
}
export type UpgradeCafeCapacityPayload = {
	increment: number,
	cost: number,
}
export type UpgradeMaxCustomerAtOnce = {
	increment: number,
	cost: number,
}
export type ClaimShelfCollectorPayload = {
	timestamp: number,
}
export type SetPendingSkipMixerPayload = {
	mixer: string?,
}
export type AddSkipTicketsPayload = {
	amount: number,
}
export type SetGamePassesPayload = {
	passes: { [string]: boolean },
}
export type GrantGamePassPayload = {
	passId: string,
}
export type CombinedActions = {
	startPlayerSession: (playerId: PlayerId, data: PlayerData, payload: StartPlayerSessionPayload) -> (),
	endPlayerSession: (playerId: PlayerId) -> (),
	mixDrink: (playerId: PlayerId, payload: MixDrinkPayload) -> (),
	buyIngredient: (playerId: PlayerId, payload: BuyIngredientPayload) -> (),
	buyIngredientBulk: (playerId: PlayerId, payload: BuyIngredientBulkPayload) -> (),
	refreshShop: (playerId: PlayerId, payload: RefreshShopPayload) -> (),
	pickUpDrinkFromMixer: (playerId: PlayerId, payload: PickUpPayload) -> (),
	restockDrinks: (playerId: PlayerId, payload: RestockDrinksPayload) -> (),
	buyMixer: (playerId: PlayerId, payload: BuyMixerPayload) -> (),
	upgradeLuck: (playerId: PlayerId, payload: UpgradeLuckPayload) -> (),
	upgradeCafeCapacity: (playerId: PlayerId, payload: UpgradeCafeCapacityPayload) -> (),
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

	toggleCafeOpen: (playerId: PlayerId) -> (),

	spawnCustomer: (playerId: PlayerId, payload: SpawnCustomerPayload) -> (),
	customerTakeItems: (playerId: PlayerId, payload: CustomerItemPayload) -> (),
	claimShelfCollector: (playerId: PlayerId, payload: ClaimShelfCollectorPayload) -> (),
	playerReceivePayment: (
		playerId: PlayerId,
		payload: {
			customerUid: string,
			Cash: number,
			timestamp: number,
		}
	) -> (),
	customerLeaveEmptyHanded: (
		playerId: PlayerId,
		payload: {
			customerUid: string,
			timestamp: number,
		}
	) -> (),

	buyIngredientFromSpawner: (playerId: PlayerId, payload: BuyIngredientFromSpawnerPayload) -> (),
	rollIngredient: (playerId: PlayerId, payload: RollIngredientPayload) -> (),
	removeCustomer: (playerId: PlayerId, uid: string) -> (),
	claimDailyReward: (playerId: PlayerId, DailyClaimPayload) -> (),
	completeTutorial: (playerId: PlayerId) -> (),
}

--Coffee Modules
export type CoffeeModule = {
	IngredientLookup: { [string]: IngredientConfig },
	IngredientConfigs: { IngredientConfig },
	Config: { [string]: CoffeeConfigType },
	Array: { CoffeeConfigType },
	SortedArray: { CoffeeConfigType },

	Craft: ({ string }) -> CoffeeConfigType?,
	GetId: ({ string }) -> string,
}
export type CoffeeConfigType = {
	Id: string,
	DisplayName: string,
	Cost: number,
	Ingredients: { string }?,
	RecipePath: { string }?,
	Rate: number,
	Instruction: string?,
	Image: string?,
	Price: number,
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
export type VariationConfig = {
	VariationId: "none" | "copper" | "silver" | "gold" | "diamond" | "starlight" | "hexed",
	DisplayName: string,
	Multiplier: number,
	ColorPrimary: Color3,
	ColorSecondary: Color3?,
	Weight: number,
	Image: number?,
}

return {}
