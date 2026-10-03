-- Shared/Types.luau
--v2

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
    [PlayerId]: {
        grid: { [string]: string }, -- The Half-Grid matrix for structural stuff
        placedItems: { [string]: PlacedItem }, -- Grid-based items (Tables, Walls)
        spatialItems: { [string]: SpatialItem }, -- Free-placed items (Decorations, Cups)
        nextId: number,
        plotSize: number,
    },
}

export type SpatialItem = {
    id: string,
    parentUuid: string,
    cframe: { number }, -- Array of 12 numbers for DataStore serialization
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
    cost: number,
}
export type ExpandPlotRemotePayload = {} -- Empty because the server calculates the next tier securely!
export type FreePlacementRemotePayload = {
    itemId: string,
    placementType: "Free",
    cframe: CFrame,
    parentUuid: string,
}
export type BuyItemRemotePayload = {
    itemId: string,
    amount: number,
}
export type PlaceItemPayload = GridPlacementPayload | FreePlacementStatePayload
export type PlaceItemRemotePayload = GridPlacementRemotePayload | FreePlacementRemotePayload
export type DestroyItemPayload = {
    uuid: string,
    itemId: string,
}
export type PlayerData = {
    Stats: StatsEntity,
    Inventory: { [string]: number }, 
    Ingredients: { [string]: number },
    Customers: { CustomerEntity },
    Plot: {},
    Workers: { WorkerEntity },
}
export type PlayerId = string
export type VariationId = string
export type DrinkId = string
export type InventoryState = {
    [PlayerId]: {
        [string]: number, -- e.g. ["Wall_Brick"] = 15
    },
}
export type PlayerPhase = "mainMenu" | "playing"
-- Stats
export type StatsEntity = {
    Cash: number,
    EXP: number,
    PlayerPhase: PlayerPhase,

    SfxVolume: number,
    SfxOn: boolean,
    MusicVolume: number,
    MusicOn: boolean,
    ParticleOn: boolean,
    CafeOpen: boolean,
    TutorialCompleted: boolean,
    CustomersServed: number,
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
    status: number,
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
    targetCounterUuid: string?, 
    customerAction: "entering" | "walking" | "queuing" | "waiting" | "sitting" | "leaving" | "paid" | "emptyHanded",
    servedBy: ("player" | string)?,
    actionStartTime: number,
    secondsWaited: number,
}

export type SpawnCustomerPayload = {
    targetCounterUuid: string,
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
    workerUid: string?,
    ingredient: string,
    newDrinkId: string,
    score: number,
}
export type WrongOrderPayload = {
    customerUid: string,
    workerUid: string?,
    customerId: string?,
    timestamp: number,
}
export type ServeCustomerPayload = {
    customerUid: string,
    cash: number,
    workerUid: string?,
    customerId: string?,
    timestamp: number,
    level: number,
    EXP: number,
}
export type TrashCupPayload = {
    workerUid: string?,
}
export type TakeCustomerOrderPayload = {
    customerUid: string,
    workerUid: string?,
    order: string,
    timestamp: number,
}
export type QueueCustomerPayload = {
    customerUid: string,
    timestamp: number,
}
export type BuyIngredientPayload = {
    ingredientId: string,
    amount: number,
    cost: number,
}
export type PlayerReceivePaymentPayload = {
    customerUid: string,
    Cash: number,
}
export type BuyItemPayload = {
    itemId: string,
    amount: number,
    totalCost: number,
}

export type StartPlayerSessionPayload = {}

export type CombinedActions = {
    -- Session & Stats Core
    setPlayerPhase: (playerId: string, playerPhase: PlayerPhase) -> (),
    startPlayerSession: (playerId: PlayerId, data: PlayerData, payload: StartPlayerSessionPayload) -> (),
    endPlayerSession: (playerId: PlayerId) -> (),
    levelUp: (playerId: PlayerId, payload: { Level: number }) -> (),
    Add500: (playerId: string) -> (),
    _addExp: (playerId: string, exp: number, lvl: number) -> (),

    -- Toggles & Settings
    toggleCafeOpen: (playerId: PlayerId) -> (),
    toggleMusic: (playerId: PlayerId) -> (),
    toggleSfx: (playerId: PlayerId) -> (),
    toggleParticle: (playerId: PlayerId) -> (),
    setSfxVolume: (playerId: PlayerId, volume: number) -> (),
    setMusicVolume: (playerId: PlayerId, volume: number) -> (),
    completeTutorial: (playerId: PlayerId) -> (),

    -- Economy
    buyItem: (playerId: PlayerId, payload: BuyItemPayload) -> (),
    buyIngredient: (playerId: PlayerId, payload: BuyIngredientPayload) -> (),
    playerReceivePayment: (playerId: PlayerId, payload: PlayerReceivePaymentPayload) -> (),

    -- Plot Building
    placeItem: (playerId: string, payload: PlaceItemPayload) -> (),
    destroyItem: (playerId: string, payload: DestroyItemPayload) -> (),
    expandPlot: (playerId: PlayerId, payload: ExpandPlotPayload) -> (),

    -- Cups & Ingredients
    getCup: (playerId: PlayerId, workerUid: string?) -> (),
    addIngredient: (playerId: PlayerId, payload: AddIngredientPayload) -> (),
    trashCup: (playerId: string, payload: TrashCupPayload) -> (),

    -- Customers
    spawnCustomer: (playerId: PlayerId, payload: SpawnCustomerPayload) -> (),
    queueCustomer: (playerId: PlayerId, payload: QueueCustomerPayload) -> (),
    takeCustomerOrder: (playerId: PlayerId, payload: TakeCustomerOrderPayload) -> (),
    serveCustomer: (playerId: PlayerId, payload: ServeCustomerPayload) -> (),
    wrongOrder: (playerId: PlayerId, payload: WrongOrderPayload) -> (),
    timeOut: (playerId: PlayerId, payload: { customerUid: string, timestamp: number }) -> (),
    removeCustomer: (playerId: PlayerId, uid: string) -> (),
    tickCustomer: (playerId: PlayerId) -> (),			
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