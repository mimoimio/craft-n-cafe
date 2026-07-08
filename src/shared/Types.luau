-- Shared/Types.luau
--v1
export type PlayerData = {
	Stats: StatsEntity,
	Tables: { [string]: TableEntity },
	Drinks: { DrinkEntity },
	Mixers: { [string]: MixerEntity },
	Ingredients: {},
	Cup: { string },
	Customers: {},
}

-- Stats
export type StatsEntity = {
	Cash: number,
	Sfx: number,
	Music: number,
	SecondsPlayed: number,
	Level: number,
	CustomerSpawningEnabled: boolean, -- New Toggle for Tutorial
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

-- Cup
export type CupState = { string }

-- Ingredients
export type IngredientsState = {
	[string]: {
		[string]: number,
	},
}

-- Mixers
export type MixerEntity = {
	drinkId: string,
	startTime: number?,
}
export type MixersState = {
	[string]: {
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
	[string]: {
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
	unlockedIngredients: { number },
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

export type CombinedActions = {
	startPlayerSession: (playerId: string, data: PlayerData) -> (),
	endPlayerSession: (playerId: string) -> (),
	mixDrink: (playerId: string, payload: MixDrinkPayload) -> (),
	buyIngredient: (playerId: string, ingredientId: string, amount: number, cost: number) -> (),
	buyIngredientBulk: (playerId: string, payload: BuyIngredientBulkPayload) -> (),

	pickUpDrinkFromMixer: (playerId: string, payload: PickUpPayload) -> (),

	placeDrinkToTableSlot: (
		playerId: string,
		payload: {
			drinkUid: string?,
			table: string,
			slot: string,
		}
	) -> (),

	levelUp: (playerId: string, payload: {
		Level: number,
	}) -> (),

	-- Added toggle action for your tutorial
	toggleCustomerSpawning: (playerId: string, enabled: boolean) -> (),

	spawnCustomer: (playerId: string, payload: SpawnCustomerPayload) -> (),
	customerTakeItems: (playerId: string, payload: CustomerItemPayload) -> (),

	playerReceivePayment: (
		playerId: string,
		payload: {
			customerUid: string,
			Cash: number,
			timestamp: number, -- Added
		}
	) -> (),

	removeCustomer: (playerId: string, uid: string) -> (),
}

--Coffee Modules
export type CoffeeModule = {
	IngredientsConfig: { [string]: CoffeeConfigType },
	Config: { [string]: CoffeeConfigType },
	Array: { CoffeeConfigType },
	Craft: ({ string }) -> CoffeeConfigType,
	GetId: ({ string }) -> string,
}
export type CoffeeConfigType = {
	Id: string,
	DisplayName: string,
	Ingredients: { string }?,
	RecipePath: { string }?, -- sorted at config initialization
	Instruction: string?, -- Readable
	Image: string?,
	Price: number,
	Duration: number,
}

return {}
