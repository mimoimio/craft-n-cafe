-- Shared/Types.luau
--v1

export type PlacedItem = {
	id: string,
	itemType: string, -- "Solid", "Wall_V", or "Wall_H"
	x: number,
	z: number,
	w: number,
	l: number,
	r: number,
}
export type PlotState = {
	grid: { [string]: string }, -- UNIFIED MATRIX
	placedItems: { [string]: PlacedItem },
	nextId: number,
}
export type PlaceItemPayload = {
	itemId: string,
	itemType: string,
	startX: number,
	startZ: number,
	width: number,
	length: number,
	rotation: number,
}

export type DestroyItemPayload = {
	uuid: string,
}
export type PlayerData = {
	Stats: StatsEntity,
	Ingredients: { [string]: number },
	Customers: { CustomerEntity },
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

export type CupsState = {
	[PlayerId]: {
		[string]: CupEntity?,
	},
}

export type CupEntity = {
	drinkId: string,
	score: number,
}

export type IngredientsState = {
	[PlayerId]: {
		[string]: number,
	},
}
export type CustomerEntity = {
	id: string,
	customerId: string?,
	order: string?,
	spot: number?,
	customerAction: "entering" | "walking" | "queuing" | "waiting" | "sitting" | "leaving",
	servedBy: ("player" | string)?,
	actionStartTime: number,
}
export type CustomersState = {
	[PlayerId]: {
		[string]: CustomerEntity,
	},
}

-- action payloads
export type AddIngredientPayload = {
	workerUid: string,
	ingredient: string,
	newDrinkId: string,
	score: number,
}
export type SpawnCustomerPayload = {
	spot: number,
	customerUid: string,
	customerId: string,
	order: string,
	timestamp: number,
}
export type WrongOrderPayload = {
	customerUid: string,
	workerUid: string,
	customerId: string,
	timestamp: number,
}
export type ServeCustomerPayload = {
	customerUid: string,
	cash: number,
	workerUid: string,
	customerId: string,
	timestamp: number,
}
export type TrashCupPayload = {
	workerUid: string,
}
export type TakeCustomerOrderPayload = {
	customerUid: string,
	workerUid: string,
	order: string,
	timestamp: number,
}

export type StartPlayerSessionPayload = {}
export type CombinedActions = {
	startPlayerSession: (playerId: PlayerId, data: PlayerData, payload: StartPlayerSessionPayload) -> (),
	endPlayerSession: (playerId: PlayerId) -> (),
	levelUp: (playerId: PlayerId, payload: {
		Level: number,
	}) -> (),

	toggleCafeOpen: (playerId: PlayerId) -> (),
	toggleMusic: (playerId: PlayerId) -> (),
	toggleSfx: (playerId: PlayerId) -> (),
	toggleParticle: (playerId: PlayerId) -> (),
	setSfxVolume: (playerId: PlayerId, volume: number) -> (),
	setMusicVolume: (playerId: PlayerId, volume: number) -> (),

	addIngredient: (playerId: PlayerId, payload: AddIngredientPayload) -> (),
	spawnCustomer: (playerId: PlayerId, payload: SpawnCustomerPayload) -> (),
	removeCustomer: (playerId: PlayerId, uid: string) -> (),
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
