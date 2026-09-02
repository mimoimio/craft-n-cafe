-- Shared/Types.luau
--v1
export type PlayerData = {
	Stats: StatsEntity,
	Ingredients: { [string]: number },
	Customers: { CustomerEntity },
	Daily: {},
	Workers: { WorkerEntity },
}
export type PlayerId = string
export type VariationId = string
export type DrinkId = string

-- Stats
export type StatsEntity = {
	Cash: number,

	SfxVolume: number,
	SfxOn: boolean,
	MusicVolume: number,
	MusicOn: boolean,
	ParticleOn: boolean,
	CafeOpen: boolean,

	TutorialCompleted: boolean,

	Level: number,
	RollCooldown: number,

	Luck: number,
	CafeCapacity: number,

	PendingSkipMixer: string?,
	SkipTickets: number,
	OwnedGamePasses: { [string]: boolean },
}
export type Seed = string

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

-- Ingredients
export type IngredientsState = {
	[PlayerId]: {
		[string]: number,
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
	scannedAmount: number?,
	total: number?,
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
export type HireCashierPayload = {
	id: string,
	cost: number,
}
export type FireCashierPayload = {
	cashierUid: string,
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
export type StartPlayerSessionPayload = {}
export type DailyClaimPayload = {
	lastClaimedDaily: day,
	nextDay: number,
	ingredients: {
		[string]: number,
	},
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
	levelUp: (playerId: PlayerId, payload: {
		Level: number,
	}) -> (),

	toggleCafeOpen: (playerId: PlayerId) -> (),
	toggleMusic: (playerId: PlayerId) -> (),
	toggleSfx: (playerId: PlayerId) -> (),
	toggleParticle: (playerId: PlayerId) -> (),
	setSfxVolume: (playerId: PlayerId, volume: number) -> (),
	setMusicVolume: (playerId: PlayerId, volume: number) -> (),

	spawnCustomer: (playerId: PlayerId, payload: SpawnCustomerPayload) -> (),
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

return {}
