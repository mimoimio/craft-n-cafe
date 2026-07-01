--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Types = require(ReplicatedStorage.Shared.Types)

local statsSlice = require(script.statsSlice)
local tablesSlice = require(script.tablesSlice)
local drinksSlice = require(script.drinksSlice)

export type CombinedActions = Types.CombinedActions

export type GlobalState = {
	Stats: statsSlice.StatsState,
	Tables: tablesSlice.TablesState,
	Drinks: drinksSlice.DrinksState,
}

export type Stats = statsSlice.StatsState

export type PlayerData = {
	Stats: statsSlice.StatsEntity,
	Tables: { [string]: Types.TableEntity },
	Drinks: { Types.DrinkEntity },
}

local producer = Reflex.combineProducers({
	Stats = statsSlice,
	Tables = tablesSlice,
	Drinks = drinksSlice,
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
			-- player contains an array of mixers
			[1] = {
				drinkId = "americano",
				stock = 5,
				startTime = 100,
			},
		},
	},
	Drinks = {
		mimoimior = { -- The entity is an array of all drink objects player crafted (mixed)
			-- player contains an array of crafted drinks
			[1] = {
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
			level1 = Table1 only
			level2 = ...Table2
			level3 = ...Table4
			level4 = ...Table6
			level5 = ...Table8
			level6 = ...Table10
			level7 = ...Table12
			level8 = ...Table15
			level9 = ...Table18

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
