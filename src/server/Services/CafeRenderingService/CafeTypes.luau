-- CafeRenderingService/CafeTypes.luau

export type CafeBase = Model | {
	Cafe: Cafe?,
	Part: Part, -- the primary part to pivot the cafe at
}
export type Cafe = Model | {
	Tables: Model | {
		Table1: Table,
		-- Table2 on level 2, ... Table18 on level 8
	},
	Stations: Model | { [string]: Station },
	Mixers: Model | { [string]: Mixer },
}

--Tables
export type Table = Model | {
	Slots: Model | {
		PlacePart: Part,
		Slot1: Slot,
		Slot2: Slot,
		Slot3: Slot,
		Slot4: Slot,
	},
	PlacePart: Part, -- the PrimaryPart
	TableModel: Model, -- the cloned table from ReplicatedStorage.Shared.Models for dynamic table models
}
export type Slot = Model | {
	PlacePart: Part,
	PlacedItem: Model?, -- the cloned drinks from ReplicatedStorage.Shared.Models
}

-- Stations -- will probably be dynamic too
export type Station = Model | {
	TriggerPrompt: ProximityPrompt,
	StationModel: Model, -- the cloned drinks from ReplicatedStorage.Shared.Models
	Part: Part, -- the PrimaryPart
}

-- Mixers -- will probably be dynamic too
export type Mixer = Model | {
	TriggerPrompt: ProximityPrompt,
	MixerModel: Model,
	Part: Part, -- the PrimaryPart
}

return {}
