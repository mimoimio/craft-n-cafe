-- Shared/CafeTypes.luau

export type CafeBase = Model & {
	Cafe: Cafe?, -- the main cafe building, rendered in Services/CafeRenderingService
	Part: Part, -- part acting as the base
	Entrance: Part, -- PrimaryPart. Also the part npc spawns on.
	Mailbox: Model & {
		Mailbox: Part & {
			TriggerPrompt: ProximityPrompt,
		},
	},
	GetAttribute: (self: CafeBase, attribute: string & "OwnerId") -> string,
}
export type IngredientId = string
export type Cafe = Model & {
	Stations: Model & { [IngredientId]: Station },
	Mixers: Model & { [string]: Mixer },
	Cashier: Model & {
		Part: Part,
	},
	FeedbackPrompt: Part & {
		ProximityPrompt: ProximityPrompt,
	},
	StandSpots: Model & { Part },
}

--Shelves
export type Shelf = Model & {
	ShelfSlots: ShelfSlots,
}
export type ShelfSlots = Model & {
	Slot1: ShelfSlot,
	Slot2: ShelfSlot,
	Slot3: ShelfSlot,
	Slot4: ShelfSlot,
	Slot5: ShelfSlot,
	-- ... Slot20
}
export type ShelfSlot = Part & {
	DisplayPart: Part,
}

--Tables
export type Table = Model & {
	Slots: Slots,
	PlacePart: Part, -- the PrimaryPart
	TableModel: Model, -- the cloned table from ReplicatedStorage.Shared.Models for dynamic table models
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

export type Mixer = Model & {
	MixerModel: Model?, -- the cloned model
	Part: Part & { -- the PrimaryPart
		TriggerPrompt: ProximityPrompt,
	},
}

export type CustomerRig = Model & {
	TriggerPrompt: ProximityPrompt,
}

export type Shop = {
	Building: Model,
	Part: Part & {
		TriggerPrompt: ProximityPrompt,
	},
}
return {}
