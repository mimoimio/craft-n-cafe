-- Shared/CafeTypes.luau

export type CafeBase = Model & {
	Cafe: Cafe?,
	Part: Part, -- the primary part to pivot the cafe at
	Entrance: Part, -- the platform npc spawns in
}
export type IngredientId = string
export type Cafe = Model & {
	Tables: Model & {
		Table1: Table,
		-- Table2 on Level 2, ... Table18 on Level 8
	},
	Stations: Model & { [IngredientId]: Station },
	Mixers: Model & { [string]: Mixer },
	Cashier: Model & {
		Part: Part,
	},
}

--Tables
export type Table = Model & {
	Slots: Slots,
	PlacePart: Part, -- the PrimaryPart
	TableModel: Model, -- the cloned table from ReplicatedStorage.Shared.Models for dynamic table models
	StandSpots: { Part },
}
export type Slots = Model & {
	PlacePart: Part,
	Slot1: Slot,
	Slot2: Slot,
	Slot3: Slot,
	Slot4: Slot,
	Parent: Table, 
}
export type Slot = Model & {
	PlacePart: Part & {
		TriggerPrompt: ProximityPrompt,
	},
	PlacedItem: Model?, -- the cloned drinks from ReplicatedStorage.Shared.Models
	Parent: Slots,
}

-- Stations -- will probably be dynamic too
export type Station = Model & {
	StationModel: Model, -- the cloned drinks from ReplicatedStorage.Shared.Models
	Part: Part & { -- the PrimaryPart
		TriggerPrompt: ProximityPrompt,
	},
}

-- Mixers -- will probably be dynamic too
export type Mixer = Model & {
	-- MixerModel: Model,
	Part: Part & { -- the PrimaryPart
		TriggerPrompt: ProximityPrompt,
	},
}

export type CustomerRig = Model & {
	TriggerPrompt: ProximityPrompt,
}

return {}
