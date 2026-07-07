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

type PlayerId = string
export type TablesState = {
	[PlayerId]: { [string]: TableEntity },
}

export type StatsActions = {}

local log = function(message: string)
	warn(`[tablesSlice]: {message}`)
end

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
	placeDrinkToTableSlot = function(state: TablesState, playerId: string, payload: Types.PlaceDrinkPayload)
		local playerTables = state[playerId]
		if not playerTables then
			log(`player {playerId}'s tables not found`)
			return state
		end
		local targetTable = playerTables[payload.tableUid]
		if not targetTable then
			log(`player's table with uid {payload.tableUid} not found`)
			return state
		end
		payload.drinkUid = payload.drinkUid or "none"
		if payload.drinkUid ~= "none" then
			for tableUid, table in playerTables do
				for slotName, drinkUid in table.Slots do
					if drinkUid == payload.drinkUid then
						playerTables[tableUid].Slots[slotName] = "none"
					end
				end
			end
		end

		local newTable = Set(targetTable.Slots, payload.slot, payload.drinkUid)
		local newSlots = Set(targetTable, "Slots", newTable)
		local newTables = Set(playerTables, payload.tableUid, newSlots)
		return Set(state, playerId, newTables)
	end,
	customerTakeItems = function(state: TablesState, playerId: string, payload: Types.CustomerItemPayload)
		local playerTables = state[playerId]
		if not playerTables then
			return state
		end

		-- If no drinks were depleted, we don't need to change the table state
		if not payload.depletedDrinks or not next(payload.depletedDrinks) then
			return state
		end

		local newPlayerTables = table.clone(playerTables)
		local hasChanges = false

		for tableUid, targetTable in playerTables do
			local tableChanged = false
			local newSlots = table.clone(targetTable.Slots)

			-- Check each slot to see if its drink was fully depleted
			for slotName, drinkUid in newSlots do
				if payload.depletedDrinks[drinkUid] then
					newSlots[slotName] = "none"
					tableChanged = true
					hasChanges = true
				end
			end

			-- Only merge updates if this specific table was modified
			if tableChanged then
				newPlayerTables[tableUid] = Set(targetTable, "Slots", newSlots)
			end
		end

		-- Only return a new state reference if a slot actually changed
		if hasChanges then
			return Set(state, playerId, newPlayerTables)
		end

		return state
	end,
	levelUp = function(state: TablesState, playerId: string, payload: Types.LevelUpPayload)
		--[[
		in this implementation, I made it mandatory for all levels,
		all level progressions are mandatory.
		if not, they might miss a table, and it could break the game,
		not letting the player use a table that is rendered on their cafe.
		by making the implementation this way, it is static, and the
		business logic is validated in the services, levelUp action
		
		though, it leaves a worry that one might miss a level and therefore
		making it broken
		]]
		local playerTables = state[playerId]
		if not playerTables then
			log(`player {playerId}'s tables not found`)
			return state
		end

		local newTables = {}
		for i, table: string in payload.unlockedTables do
			newTables[table] = {
				TableId = "woodentable",
				Slots = {
					Slot1 = "none",
					Slot2 = "none",
					Slot3 = "none",
					Slot4 = "none",
				},
			}
		end

		return Set(state, playerId, Merge(playerTables, newTables))
	end,
}

return Reflex.createProducer(initialState, actions)
