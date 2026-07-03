--#region server/Services/PlayerDataService.luau
local PROFILE_TEMPLATE: PlayerData = {
	Stats = {
		Sfx = 0.5,
		Music = 0.5,
		SecondsPlayed = 0,
		Cash = 100,
		Level = 1,
	},
	Tables = {
		Table1 = {
			TableId = "woodentable",
			Slots = {
				Slot1 = "none",
				Slot2 = "none",
				Slot3 = "none",
				Slot4 = "none",
			},
		},
	},
	Drinks = {},
	Mixers = {
		Mixer1 = {
			drinkId = "none",
		},
	},
	Ingredients = {},
	Cup = {},
	Customers = {},
}
--#end

--#region shared/producers/GlobalState/init.luau
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Types = require(ReplicatedStorage.Shared.Types)

local statsSlice = require(script.statsSlice)
local tablesSlice = require(script.tablesSlice)
local drinksSlice = require(script.drinksSlice)
local ingredientsSlice = require(script.ingredientsSlice)
local mixersSlice = require(script.mixersSlice)

export type CombinedActions = Types.CombinedActions

export type GlobalState = {
	Stats: statsSlice.StatsState,
	Tables: tablesSlice.TablesState,
	Drinks: drinksSlice.DrinksState,
	Ingredients: ingredientsSlice.IngredientsState,
	Mixers: mixersSlice.MixersState,
}

export type Stats = statsSlice.StatsState

export type PlayerData = Types.PlayerData

local producer = Reflex.combineProducers({
	Stats = statsSlice,
	Tables = tablesSlice,
	Drinks = drinksSlice,
	Ingredients = ingredientsSlice,
	Mixers = mixersSlice,
}) :: Reflex.Producer<GlobalState, CombinedActions>

local globalstate = {
	Stats = { -- general player data
		mimoimior = { -- The entity is a dictionary of general player stats
			Cash = 100,
			Sfx = 0.3,
			Music = 0.5,
			SecondsPlayed = 0,
		},
	},
	Cup = {
		mimoimior = { -- The entity is an array of string of ingredients
			"coffeebeans",
			"milk",
			"chocopowder",
		},
	},
	Ingredients = {
		mimoimior = { -- The entity is a dictionary, ingredientid as key, value:number of amount
			coffeebeans = 1,
			milk = 1,
			water = 1,
			foam = 1,
			chocopowder = 1,
		},
	},
	Mixers = {
		mimoimior = { -- The entity is a dictionary of mixer objects
			Mixer1 = {
				drinkId = "americano",
				startTime = 100,
			},
		},
	},
	Drinks = {
		mimoimior = { -- The entity is an array of all drink objects player crafted (mixed)
			-- player contains an array of crafted drinks
			{
				-- a drink is picked up from the mixer when its
				-- finished. Clear the mixer and add this drink
				-- object to this slice. This object will be refered
				-- from racks
				id = "abc",
				drinkId = "latte",
				stock = 5,
			},
		},
	},
	Tables = {
		mimoimior = { -- The entity is a dictionary of Tables, containing table objects
			Table1 = {
				TableId = "woodentable",
				Slots = {
					Slot1 = "abc",
					Slot2 = "none",
					Slot3 = "none",
					Slot4 = "none",
				},
			},
			-- Table2 ... TableN
			--[[
			Level1 = Table1 only
			Level2 = ...Table2
			Level3 = ...Table4
			Level4 = ...Table6
			Level5 = ...Table8
			Level6 = ...Table10
			Level7 = ...Table12
			Level8 = ...Table15
			Level9 = ...Table18

			]]
		},
	},
	Customers = {
		mimoimior = { -- The entity is a an array of customers buying drinks
			{
				id = "def",
				customerId = "",
				drinkIds = {
					-- customer pick up a drink. the server deducts
					-- the stock under drinks slice. and update
					-- this slice to add drink.
					"latte",
					"latte",
					"americano",
				},
			},
		},
	},
}

return producer

--#endregion

--#region shared/Types.luau
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
	sfx: number,
	music: number,
	SecondsPlayed: number,
	Level: number,
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

-- Tables
export type DrinkEntity = {
	id: string,
	stock: number,
	drinkId: string,
}

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
	drinkIds: { string },
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
	customerUid: string, --uid
	drinksDeducted: {
		[string]: number,
		--[drink uid]: stock
	},
	drinkIds: { string },
}
export type SpawnCustomerPayload = {
	customerUid: string, -- uid
	customerId: string,
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

	LevelUp: (playerId: string, payload: {
		Level: number,
	}) -> (),

	spawnCustomer: (playerId: string, payload: SpawnCustomerPayload) -> (),
	-- set the customer's items to buy
	customerTakeItems: (playerId: string, payload: CustomerItemPayload) -> (),

	playerReceivePayment: (playerId: string, payload: {
		customerUid: string,
		Cash: number,
	}) -> (),

	removeCustomer: (
		playerId: string,
		payload: { -- when customer has walked out the store
			uid: string,
		}
	) -> (),
}

return {}

--#endregion

--#region shared/producers/GlobalState/statsSlice.luau
--!strict
-- playersSlice.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Types = require(ReplicatedStorage.Shared.Types)

local Dictionary = Sift.Dictionary
local Merge = Dictionary.merge
local Set = Dictionary.set
local RemoveKey = Dictionary.removeKey

-- /// TYPES ///
type PlayerData = Types.PlayerData
export type StatsEntity = Types.StatsEntity

export type StatsState = {
	[string]: StatsEntity,
}

export type StatsActions = {}

-- /// INITIALIZATION ///
local initialState: StatsState = {}

-- /// REDUCERS ///
local actions = {
	startPlayerSession = function(state: StatsState, playerId: string, data: PlayerData)
		return Set(state, playerId, data.Stats)
	end,
	endPlayerSession = function(state: StatsState, playerId: string, data: PlayerData)
		return RemoveKey(state, playerId)
	end,
	levelUp = function(state: StatsState, playerId: string, payload: Types.LevelUpPayload)
		local playerStats = state[playerId]
		local Level = state[playerId].Level
		return Set(
			state,
			playerId,
			Merge(playerStats, {
				Level = Level + 1,
			})
		)
	end,
	buyIngredient = function(state: StatsState, playerId: string, ingredientId: string, amount: number, cost: number)
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end

		return Set(state, playerId, Set(playersStats, "Cash", playersStats.Cash - cost))
	end,
}

return Reflex.createProducer(initialState, actions)

--#endregion

--#region shared/producers/GlobalState/drinksSlice.luau
--!strict
-- drinksSlice.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Types = require(ReplicatedStorage.Shared.Types)

local Array = Sift.Array
local Update = Array.update
local Insert = Array.insert
local Dictionary = Sift.Dictionary
local Merge = Dictionary.merge
local Set = Dictionary.set
local RemoveKey = Dictionary.removeKey

-- /// TYPES ///
type PlayerData = Types.PlayerData
export type DrinkEntity = Types.DrinkEntity
export type DrinksState = Types.DrinksState

export type StatsActions = {}

-- /// INITIALIZATION ///
local initialState: DrinksState = {}

-- /// REDUCERS ///
local actions = {
	startPlayerSession = function(state: DrinksState, playerId: string, data: PlayerData)
		return Set(state, playerId, data.Drinks)
	end,
	endPlayerSession = function(state: DrinksState, playerId: string, data: PlayerData)
		return RemoveKey(state, playerId)
	end,

	pickUpDrinkFromMixer = function(state: DrinksState, playerId: string, payload: Types.PickUpPayload)
		local playersDrinks = state[playerId]
		if not playersDrinks then
			return state
		end
		local newDrinks = table.clone(playersDrinks)
		table.insert(newDrinks, {
			id = payload.id,
			drinkId = payload.drinkId,
			stock = payload.stock,
		})
		return Set(state, playerId, newDrinks)
	end,
	customerTakeItems = function(state: DrinksState, playerId: string, payload: Types.CustomerItemPayload)
		local playersDrinks = state[playerId]
		if not playersDrinks then
			return state
		end

		local newDrinks = table.clone(playersDrinks)

		local indexesToRemove = {}
		for i, drink in newDrinks do
			local deduct = payload.drinksDeducted[drink.id]
			if deduct then
				local total = drink.stock - deduct
				if total > 0 then
					newDrinks[i] = Set(drink, "stock", {
						total,
					})
				else
					table.insert(indexesToRemove, i)
				end
			end
		end
		Array.removeIndices(newDrinks, table.unpack(indexesToRemove))
		return Set(state, playerId, newDrinks)
	end,
}

return Reflex.createProducer(initialState, actions)

--#endregion

--#region shared/producers/GlobalState/ingredientsSlice.luau
--!strict
-- ingredientsSlice.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Types = require(ReplicatedStorage.Shared.Types)

local Dictionary = Sift.Dictionary
local Merge = Dictionary.merge
local Set = Dictionary.set
local RemoveKey = Dictionary.removeKey

-- /// TYPES ///
type PlayerData = Types.PlayerData

export type IngredientsState = Types.IngredientsState

-- /// INITIALIZATION ///
local initialState: IngredientsState = {}

-- /// REDUCERS ///
local actions = {
	startPlayerSession = function(state: IngredientsState, playerId: string, data: PlayerData)
		return Set(state, playerId, data.Ingredients)
	end,
	endPlayerSession = function(state: IngredientsState, playerId: string, data: PlayerData)
		return RemoveKey(state, playerId)
	end,
	mixDrink = function(state: IngredientsState, playerId: string, payload: Types.MixDrinkPayload)
		local playersIngredients = state[playerId]
		if not playersIngredients then
			warn(`ingredientsSlice player({playerId}) not found`)
			return state
		end
		for i, ingredientId: string in payload.ingredients do
			playersIngredients[ingredientId] = (playersIngredients[ingredientId] or 0) - 1
		end

		return Set(state, playerId, playersIngredients)
	end,
	buyIngredient = function(
		state: IngredientsState,
		playerId: string,
		ingredientId: string,
		amount: number,
		cost: number
	)
		local playersIngredients = state[playerId]
		if not playersIngredients then
			warn(`ingredientsSlice player({playerId}) not found`)
			return state
		end

		return Set(
			state,
			playerId,
			Set(playersIngredients, ingredientId, (playersIngredients[ingredientId] or 0) + amount)
		)
	end,
}

return Reflex.createProducer(initialState, actions)


--#endregion

--#region shared/producers/GlobalState/mixersSlice.luau
--!strict
-- mixersSlice.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Types = require(ReplicatedStorage.Shared.Types)

local Dictionary = Sift.Dictionary
local Merge = Dictionary.merge
local Set = Dictionary.set
local RemoveKey = Dictionary.removeKey

-- /// TYPES ///
type PlayerData = Types.PlayerData

export type MixersState = Types.MixersState

-- /// INITIALIZATION ///
local initialState: MixersState = {}

-- /// REDUCERS ///
local actions = {
	startPlayerSession = function(state: MixersState, playerId: string, data: PlayerData)
		return Set(state, playerId, data.Mixers)
	end,
	endPlayerSession = function(state: MixersState, playerId: string, data: PlayerData)
		return RemoveKey(state, playerId)
	end,
	mixDrink = function(state: MixersState, playerId: string, payload: Types.MixDrinkPayload)
		local playersMixers = state[playerId]
		if not playersMixers then
			return state
		end
		local mixerId: string = payload.mixer
		local mixer = playersMixers[mixerId]

		mixer.drinkId = payload.drinkId
		mixer.startTime = payload.startTime

		return Set(state, playerId, Set(playersMixers, mixerId, mixer))
	end,
	pickUpDrinkFromMixer = function(state: MixersState, playerId: string, payload: Types.PickUpPayload)
		local playersMixers = state[playerId]
		if not playersMixers then
			return state
		end
		local mixerId: string = payload.mixer
		local newMixer = Merge(playersMixers[mixerId], {
			drinkId = "none",
		})
		newMixer.startTime = nil
		return Set(state, playerId, Set(playersMixers, mixerId, newMixer))
	end,
}

return Reflex.createProducer(initialState, actions)

--#endregion

--#region shared/producers/GlobalState/tablesSlice.luau
--!strict
-- tablesSlice.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Types = require(ReplicatedStorage.Shared.Types)

local Dictionary = Sift.Dictionary
local Merge = Dictionary.merge
local Set = Dictionary.set
local RemoveKey = Dictionary.removeKey

-- /// TYPES ///
type PlayerData = Types.PlayerData
export type TableEntity = Types.TableEntity

export type TablesState = {
	[string]: TableEntity,
}

export type StatsActions = {}

-- /// INITIALIZATION ///
local initialState: TablesState = {}

-- /// REDUCERS ///
local actions = {
	startPlayerSession = function(state: TablesState, playerId: string, data: PlayerData)
		return Set(state, playerId, data.Tables)
	end,
	endPlayerSession = function(state: TablesState, playerId: string, data: PlayerData)
		return RemoveKey(state, playerId)
	end,
	setDrink = function(state: TablesState, playerId)
		local new = table.clone(state[playerId])
		return Set(state, playerId, Set(new, "Table1", Set(new.Table1, "Slots", Set(new.Table1.Slots, "Slot1", "abc"))))
	end,
}

return Reflex.createProducer(initialState, actions)

--#endregion

--#region shared/producers/GlobalState/customersSlice.luau
--!strict
-- customersSlice.luau
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Types = require(ReplicatedStorage.Shared.Types)

local Dictionary = Sift.Dictionary
local Array = Sift.Array
local Update = Array.update
local Insert = Array.insert
local Merge = Dictionary.merge
local Set = Dictionary.set
local RemoveKey = Dictionary.removeKey

-- /// TYPES ///
type PlayerData = Types.PlayerData
export type CustomerEntity = Types.CustomerEntity
export type CustomersState = Types.CustomersState

export type StatsActions = {}

-- /// INITIALIZATION ///
local initialState: CustomersState = {}

-- /// REDUCERS ///
local actions = {
	startPlayerSession = function(state: CustomersState, playerId: string, data: PlayerData)
		return Set(state, playerId, data.Drinks)
	end,
	endPlayerSession = function(state: CustomersState, playerId: string, data: PlayerData)
		return RemoveKey(state, playerId)
	end,
	spawnCustomer = function(state: CustomersState, playerId: string, payload: Types.SpawnCustomerPayload)
		local playersCustomers = state[playerId]
		if not playersCustomers then
			return state
		end

		return Set(
			state,
			playerId,
			Insert(playersCustomers, #playersCustomers + 1, {
				id = payload.customerUid,
				customerId = payload.customerId,
			})
		)
	end,
	customerTakeItems = function(state: CustomersState, playerId: string, payload: Types.CustomerItemPayload)
		local playersCustomers = state[playerId]
		if not playersCustomers then
			return state
		end

		local index
		for i, customer in playersCustomers do
			if customer.id == payload.customerUid then
				index = i
				break
			end
		end
		return Set(
			state,
			playerId,
			Update(playersCustomers, index, function(customer: Types.CustomerEntity, i)
				local new = table.clone(customer)
				new.drinkIds = payload.drinkIds
				return new
			end)
		)
	end,
}

return Reflex.createProducer(initialState, actions)

--#endregion

--#region shared/producers/GlobalState/mixersSlice.luau
--#endregion

--#region shared/producers/GlobalState/mixersSlice.luau
--#endregion

--#region shared/producers/GlobalState/mixersSlice.luau
--#endregion

--#region shared/producers/GlobalState/mixersSlice.luau
--#endregion

--#region shared/producers/GlobalState/mixersSlice.luau
--#endregion

I decide to not do cup yet.

--#region server/Services/CustomerService.luau
-- CustomersService.luau
local CustomersService = {}
function CustomersService.SpawnCustomer() end
function CustomersService.CustomerTakeItems() end
function CustomersService.TendCustomer(player: Player) end
function CustomersService.initialize() end

-- a simple spawn loop would be a while tru loop
-- active all the time. But for tutorial i probably
-- want a time they didnt spawn at first. for that
-- to work, for me the easiest is using react and
-- useEffects to listen to GlobalState producer.

-- spawned customers will take some time before it
-- take items from the Tables. If there was none,
-- they'd leave.

-- i think for rendering customer models too, but not here.
-- maybe CafeRenderingService could do that.
-- and control walkto and animations and stuffs. If
-- using the roblox's Humanoid native walk methods,
-- they could get stuck if not proper
-- the laziest I could think of is turning cancollide
-- off on everything inside the cafe

return CustomersService

--#endregion

--#region server/Services/CafeRenderingService/init.luau
-- CafeRenderingService.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RENDERTAG = "RENDEREDOBJECT"
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CafeTypes = require(game.ReplicatedStorage.Shared.CafeTypes) -- = require(script.CafeTypes)
local Cafe = require(script.Cafe)

local CafeRenderingService = {}

local function selectPlayerStatsById(state: GlobalState.GlobalState)
	return state.Stats -- Capitalized to match GlobalState definition
end

local function getPlayerId(stats, playerId: string)
	return playerId
end

local function BasesManager()
	local bases, setBases = useState({})

	useEffect(function()
		local unsub = GlobalState:observe(selectPlayerStatsById, getPlayerId, function(stats, playerId)
			-- Mount/Update logic
			setBases(function(prev)
				local new = table.clone(prev)
				local baseModels = workspace.Bases:GetChildren()

				for _, base in baseModels do
					local taken = new[base]
					if taken then
						continue
					end
					new[base] = playerId
					-- break -- Assigns only one base per player observed
					return new
				end

				local newBases = {}
				for base, pId in new do
					table.insert(newBases, "" .. #newBases .. ")" .. pId)
				end

				warn("[CafeRenderingService] NO BASES LEFT", table.concat(newBases, "\n"))
				return new
			end)

			-- Cleanup logic when the observed state changes/disconnects
			return function()
				setBases(function(prev)
					local new = table.clone(prev)
					-- Remove the base assigned to this specific player
					for base, prevPlayerId in new do
						if prevPlayerId == playerId then
							new[base] = nil
						end
					end
					return new
				end)
			end
		end)

		return function()
			unsub()
		end
	end, {})

	local children = {}
	for base, playerId in bases do
		children[playerId] = e(Cafe, {
			BaseModel = base,
			PlayerId = playerId,
		})
	end

	return e(React.Fragment, nil, children) -- Ensure children are rendered in a Fragment
end

function CafeRenderingService.initialize()
	local rootValue = Instance.new("StringValue", workspace)
	rootValue.Name = "root"

	local root = ReactRoblox.createRoot(rootValue)
	root:render(e(BasesManager))
end

return CafeRenderingService

--#endregion

--#region server/Services/DrinksService.luau
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)

local un

local DrinksService = {}

function DrinksService.MixDrink(player: Player, drinkId: string, mixer: string)
	if not (drinkId and mixer) then
		warn(`MixDrink Failed: drinkId({tostring(drinkId)}) or mixer({tostring(mixer)}) is nil`)
		return
	end

	local playerId = tostring(player.UserId)
	local config = CoffeeModule.Config[drinkId]
	if not config then
		warn(`MixDrink Failed: {drinkId} is not a valid drink`)
		return
	end

	-- ensure player
	local state = GlobalState:getState()
	local playersIngredients = state.Ingredients[playerId]
	local playersMixers = state.Mixers[playerId]

	if not playersIngredients then
		warn(`MixDrink Failed: player({playerId})'s ingredients not found`)
		return
	end
	if not playersMixers or not playersMixers[mixer] then
		warn(`MixDrink Failed: player({playerId})'s mixers not found`)
		return
	end

	-- ensuring mixer is empty
	local mixerDrink = playersMixers[mixer].drinkId
	local occupied = mixerDrink and mixerDrink ~= "none"
	if occupied then
		warn(`MixDrink Failed: {mixer} occupied`)
		return
	end

	-- ensuring player has enough ingredients
	local ingredients = config.Ingredients
	for i, ingredientId in ingredients do
		local ingredient = playersIngredients[ingredientId]
		if not ingredient or ingredient <= 0 then
			warn(`MixDrink Failed: not enough {ingredientId}({tostring(ingredient)})`)
			return
		end
	end

	GlobalState.mixDrink(playerId, {
		drinkId = drinkId,
		ingredients = ingredients,
		mixer = mixer,
		startTime = tick(),
	})
end
function DrinksService.PickUpDrink(player: Player, mixer: string)
	if not mixer then
		warn(`PickUpDrink Failed: mixer({tostring(mixer)}) is nil`)
		return
	end

	local playerId = tostring(player.UserId)

	-- ensure player
	local state = GlobalState:getState()
	local playersDrinks = state.Drinks[playerId]
	local playersMixers = state.Mixers[playerId]

	if not playersDrinks then
		warn(`PickUpDrink Failed: player({playerId})'s drinks not found`)
		return
	end
	if not playersMixers or not playersMixers[mixer] then
		warn(`PickUpDrink Failed: player({playerId})'s mixers not found`)
		return
	end

	-- ensuring mixer is not empty
	local mixerDrink = playersMixers[mixer].drinkId
	local occupied = mixerDrink and mixerDrink ~= "none"
	if not occupied then
		warn(`PickUpDrink Failed: {mixer} is not occupied`)
		return
	end

	GlobalState.pickUpDrinkFromMixer(playerId, {
		id = HttpService:GenerateGUID(),
		drinkId = mixerDrink,
		stock = 5,
		mixer = mixer,
	})
end

function DrinksService.initialize()
	Remotes.MixDrink.OnServerEvent:Connect(DrinksService.MixDrink)
	Remotes.PickUpDrink.OnServerEvent:Connect(DrinksService.PickUpDrink)
end
return DrinksService

--#endregion

--#region server/Services/ShopService.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)

local ShopService = {}

function ShopService.BuyIngredient(player: Player, ingredientId: string)
	if not ingredientId then
		warn(`BuyIngredient Failed: ingredientId is nil`)
		return
	end

	-- ensure ingredient
	local playerId = tostring(player.UserId)
	local config = CoffeeModule.Config[ingredientId]
	if not config then
		warn(`BuyIngredient Failed: {ingredientId} is not a valid drink`)
		return
	end
	if config.Ingredients and #config.Ingredients > 1 then
		return
	end

	-- ensure player
	local state = GlobalState:getState()
	local playersIngredients = state.Ingredients[playerId]
	if not playersIngredients then
		warn(`BuyIngredient Failed: player({playerId})'s ingredients not found`)
		return
	end

	-- local cost = config.Price -- no price rn, later config price
	local cost = 2

	GlobalState.buyIngredient(playerId, ingredientId, 1, cost)
end

function ShopService.initialize()
	Remotes.BuyIngredient.OnServerEvent:Connect(ShopService.BuyIngredient)
end
return ShopService

--#endregion

--#region server/Services/CustomerService.luau
--#endregion

--#region server/Services/CustomerService.luau
--#endregion

--#region server/Services/CustomerService.luau
--#endregion

--#region server/Services/CustomerService.luau
--#endregion

--#region server/Services/CustomerService.luau
--#endregion

--#region server/Services/CustomerService.luau
--#endregion

--#region server/Services/CustomerService.luau
--#endregion