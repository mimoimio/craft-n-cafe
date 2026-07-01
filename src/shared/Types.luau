--!strict
--v1
export type PlayerData = {
	Stats: StatsEntity,
	Tables: { [string]: TableEntity },
	Drinks: { DrinkEntity },
	Mixers: {},
	Ingredients: {},
	Cup: { string },
	Customers: {},
}

-- Stats
export type StatsEntity = {
	gold: number,
	sfx: number,
	music: number,
	secondsPlayed: number,
	level: number,
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
export type CupState = { "string" }

-- action payloads
export type AddIngredientPayload = {
	ingredientId: string,
	score: number,
}

export type LevelUpPayload = {}

export type CombinedActions = {
	startPlayerSession: (playerId: string, data: PlayerData) -> (),
	endPlayerSession: (playerId: string) -> (),
	addIngredient: (playerId: string, payload: AddIngredientPayload) -> (),
	pickUpDrinkFromMixer: (playerId: string, payload: {
		id: string,
		drinkId: string,
		stock: number,
	}) -> (),
	placeDrinkToTableSlot: (
		playerId: string,
		payload: {
			drinkUid: string?,
			table: string,
			slot: string,
		}
	) -> (),
	mixDrink: (playerId: string, payload: {
		drinkId: string,
		mixer: string,
	}) -> (),
	levelUp: (playerId: string, payload: {
		level: number,
	}) -> (),
}

return {}
