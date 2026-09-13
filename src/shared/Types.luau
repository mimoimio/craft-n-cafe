-- Shared/Types.luau
--v1

export type GridStud = number
export type HalfGridStud = number
export type PlacedItem = {
	id: string,
	itemType: string, -- "Solid", "Wall_V", or "Wall_H"
	x: GridStud,
	z: GridStud,
	w: GridStud,
	l: GridStud,
	r: number,
}
export type PlotState = {
	grid: { [string]: string }, -- The Half-Grid matrix for structural stuff
	placedItems: { [string]: PlacedItem }, -- Grid-based items (Tables, Walls)
	spatialItems: { [string]: SpatialItem }, -- NEW: Free-placed items (Decorations, Cups)
	nextId: number,
	plotSize: number,
}

export type SpatialItem = {
	id: string,
	parentUuid: string,
	cframe: { number }, -- FIX: Array of 12 numbers for DataStore serialization
}

export type GridPlacementPayload = {
	itemId: string,
	placementType: "Grid",
	itemType: string,
	startX: GridStud,
	startZ: GridStud,
	width: GridStud,
	length: GridStud,
	rotation: number,
}
export type GridPlacementRemotePayload = {
	itemId: string,
	-- placementType: "Grid",
	-- itemType: string,
	startX: GridStud,
	startZ: GridStud,
	width: GridStud,
	length: GridStud,
	rotation: number,
}

export type FreePlacementStatePayload = {
	itemId: string,
	placementType: "Free",
	cframe: { number },
	parentUuid: string,
}
export type ExpandPlotPayload = {
	newSize: number,
}
export type FreePlacementRemotePayload = {
	itemId: string,
	placementType: "Free",
	cframe: CFrame,
	parentUuid: string,
}

export type PlaceItemPayload = GridPlacementPayload | FreePlacementStatePayload
export type PlaceItemRemotePayload = GridPlacementRemotePayload | FreePlacementRemotePayload
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
	targetCounterUuid: string?, -- NEW: Explicitly links customer to a specific counter
	customerAction: "entering" | "walking" | "queuing" | "waiting" | "sitting" | "leaving",
	servedBy: ("player" | string)?,
	actionStartTime: number,
}

export type SpawnCustomerPayload = {
	targetCounterUuid: string, -- NEW
	customerUid: string,
	customerId: string,
	order: string?,
	timestamp: number,
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

	destroyItem: (playerId: string, payload: DestroyItemPayload) -> (),
	placeItem: (playerId: string, payload: PlaceItemPayload) -> (),
	toggleCafeOpen: (playerId: PlayerId) -> (),
	toggleMusic: (playerId: PlayerId) -> (),
	toggleSfx: (playerId: PlayerId) -> (),
	toggleParticle: (playerId: PlayerId) -> (),
	setSfxVolume: (playerId: PlayerId, volume: number) -> (),
	setMusicVolume: (playerId: PlayerId, volume: number) -> (),
	expandPlot: (playerId: PlayerId, payload: ExpandPlotPayload) -> (),
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

	Craft: (ingredients: { string }) -> CoffeeConfigType?,
	GetId: (ingredients: { string }) -> string,
}

export type CoffeeConfigType = {
	Id: string,
	DisplayName: string,
	Ingredients: { string }?,
	Instruction: string?, -- Flat hint list (e.g. "Espresso + Milk")
	Image: string?,
	Price: number, -- Automatically calculated as sum of ingredient prices
}

export type IngredientConfig = {
	Id: string,
	DisplayName: string,
	Price: number,
	ItemTip: string?,
	Image: string?,
}
-- Placeables Modules
export type PlaceableCategory = "Architecture" | "Surface" | "Cashier" | "Station" | "Furniture" | "Decoration"

export type PlaceableConfig = {
	Id: string,
	DisplayName: string,
	Category: PlaceableCategory,
	Price: number,
	UnlockLevel: number,
	MaxAllowed: number, -- Use math.huge for infinite
	Image: string?,
}

export type PlaceablesModule = {
	Config: { [string]: PlaceableConfig },
	Array: { PlaceableConfig },

	GetConfig: (id: string) -> PlaceableConfig?,
	GetUnlockedItems: (level: number) -> { PlaceableConfig },
}
return {}
