-- Shared/Types.luau
--v1
export type PlayerData = {
	Stats: StatsEntity,
	Tables: { [string]: TableEntity },
	Drinks: { DrinkEntity },
	Mixers: { [string]: MixerEntity },
	Ingredients: { [string]: number },
	Customers: { CustomerEntity },
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

-- Spawner
export type SpawnerState = {
	[string]: {
		TimePulled: number?,
		IngredientId: string?,
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
	CafeOpen: boolean, -- New Toggle for Tutorial
	UnlockedIngredients: { string },
	DiscoveredDrinks: {
		[VariationId]: {
			[DrinkId]: true,
		},
	},
	RollCooldown: number,
	-- for the future
	MaxDrinksPerCustomer: number,
	MaxCustomersAtOnce: number,
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
	today: day?, -- Added to track current server day!
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

	-- for the future
	mixerLevel: number,
	additionalStocks: number,
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
	drinkEntities: {
		drinkId: string,
		variationId: string?,
	}?,
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
	mixer: string,
}
export type CustomerItemPayload = {
	customerUid: string,
	drinksDeducted: {
		[string]: number,
	},
	drinkEntities: {
		drinkId: string,
		variationId: string?,
	},
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
	ingredientId: string,
	timePulled: number,
}
export type BuyIngredientFromSpawnerPayload = {
	ingredientId: string,
	cost: number,
	timePulled: number,
}
export type BuyMixerPayload = {
	mixerId: string,
	cost: number,
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
	toggleCafeOpen: (playerId: PlayerId) -> (),

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
	customerLeaveEmptyHanded: (
		playerId: PlayerId,
		payload: {
			customerUid: string,
			timestamp: number, -- Added
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
export type VariationConfig = {
	VariationId: "none" | "copper" | "silver" | "gold" | "diamond",
	DisplayName: "" | "Copper" | "Silver" | "Gold" | "Diamond",
	Multiplier: number,
	ColorPrimary: Color3,
	ColorSecondary: Color3?,
	Weight: number,
	Image: number?,
}

return {}
